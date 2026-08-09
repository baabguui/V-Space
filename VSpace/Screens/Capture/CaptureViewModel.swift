//
//  CaptureViewModel.swift
//  VSpace
//
//  ObjectCaptureSession 관리 + RxSwift 상태 관리
//
//  상태 관찰: session.stateUpdates (AsyncSequence) — onChange 불필요
//

import UIKit
import Foundation
import RealmSwift
import _RealityKit_SwiftUI
import RxRelay

@available(iOS 17.0, *)
final class CaptureViewModel {

    // MARK: - App State

    enum AppState {
        case loading
        case ready
        case detecting
        case capturing
        case finishing
        case completed(URL)
        case failed(Error)
        case cancelled
        case saved(keepsakeId: ObjectId)
    }

    // MARK: - Output (RxSwift)

    let appState = BehaviorRelay<AppState>(value: .loading)

    // MARK: - Session

    private(set) var session: ObjectCaptureSession

    // MARK: - Private

    private let directoryManager: CaptureStorageManaging
    private let mediaStorage: MediaStorageManaging
    private let db: KeepsakeDatabaseManaging

    // MARK: - Init

    init(
        directoryManager: CaptureStorageManaging = CaptureStorageManager(),
        mediaStorage: MediaStorageManaging = MediaStorageManager.shared,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager()
    ) {
        self.directoryManager = directoryManager
        self.mediaStorage = mediaStorage
        self.db = db
        try? directoryManager.setup()
        session = ObjectCaptureSession()
        startSession(session)
    }

    // MARK: - Public

    func startDetecting() {
        let _ = session.startDetecting()
    }

    func startCapturing() {
        session.startCapturing()
    }

    func cancelCapture() {
        session.cancel()
        // cleanup()은 여기서 즉시 호출하지 않음 — cancel() 후에도 세션 내부 스레드가
        // Checkpoints에 비동기로 접근 중일 수 있음. 세션이 완전히 멈췄다는 신호인
        // .failed 상태가 handleSessionState에 도달했을 때 정리한다.
        appState.accept(.cancelled)
    }

    /// 완료 버튼: session.finish() 없이 현재 이미지로 USDZ 생성 시작
    /// 세션은 .capturing 상태를 유지하므로 뷰어에서 돌아와 추가 스캔 가능
    func finishCapture() { startGenerating() }

    /// USDZ 생성 실패 후 재시도
    func retryUSDZ() { startGenerating() }

    var canResumeCapturing: Bool {
        if case .capturing = session.state { return true }
        return false
    }

    /// 뷰어에서 돌아와 캡쳐 계속하기 (세션은 살아있음)
    func resumeCapturing() {
        appState.accept(.capturing)
    }

    /// 저장 확정 시 세션 취소 후 파일 복사 + Keepsake 초기 레코드 생성
    /// finish() 대신 cancel()을 사용해 세션의 내부 파일 접근을 막음
    /// cleanup()은 여기서 호출하지 않음 — cancel() 후 C++ 내부 스레드가 Checkpoints에
    /// 비동기로 접근 중인 상태에서 삭제하면 filesystem_error 크래시 발생.
    /// 세션이 완전히 멈춰 .failed 상태가 handleSessionState에 도달하면 그때 정리된다.
    func saveModel(thumbnail: UIImage) {
        session.cancel()
        do {
            let dest = try mediaStorage.saveModel(from: directoryManager.outputURL)
            let thumbFileName = try mediaStorage.saveThumbnail(thumbnail)
            let keepsake = Keepsake()
            keepsake.resourceFileName = dest.lastPathComponent
            keepsake.thumbnailFileName = thumbFileName
            keepsake.recordType = .threeD
            keepsake.disposalDate = .distantFuture
            keepsake.status = .inProgress
            keepsake.progressStep = 1
            try db.saveKeepsake(keepsake)
            appState.accept(.saved(keepsakeId: keepsake.id))
        } catch {
            appState.accept(.failed(error))
        }
    }

    // MARK: - Private

    private func startGenerating() {
        appState.accept(.finishing)
        Task { await generateUSDZ() }
    }

    private func startSession(_ captureSession: ObjectCaptureSession) {
        var config = ObjectCaptureSession.Configuration()
        config.checkpointDirectory = directoryManager.checkpointDirectory
        config.isOverCaptureEnabled = true
        captureSession.start(imagesDirectory: directoryManager.imagesDirectory, configuration: config)

        Task { @MainActor [weak self] in
            guard let self else { return }
            for await state in captureSession.stateUpdates {
                self.handleSessionState(state)
            }
        }
    }

    private func handleSessionState(_ state: ObjectCaptureSession.CaptureState) {
        switch state {
        case .initializing:
            appState.accept(.loading)
        case .ready:
            appState.accept(.ready)
        case .detecting:
            appState.accept(.detecting)
        case .capturing:
            appState.accept(.capturing)
        case .finishing:
            switch appState.value {
            case .cancelled, .completed, .saved(_):
                break  // 취소됐거나 이미 완료(저장 시 finish 호출)된 경우 무시
            default:
                appState.accept(.finishing)
                Task { await generateUSDZ() }
            }
        case .failed(let error):
            switch appState.value {
            case .cancelled, .saved(_):
                // cancel() 이후 세션이 완전히 정지했다는 신호 — 이제 임시 디렉토리를 안전하게 정리 가능
                directoryManager.cleanup()
            case .completed:
                break  // 아직 저장/취소 전이라 재촬영 가능성이 있으므로 정리하지 않음
            default:
                appState.accept(.failed(error))
            }
        default:
            break
        }
    }

    private func generateUSDZ() async {
        try? FileManager.default.removeItem(at: directoryManager.outputURL)
        do {
            let photogrammetrySession = try PhotogrammetrySession(input: directoryManager.imagesDirectory)
            let request = PhotogrammetrySession.Request.modelFile(url: directoryManager.outputURL, detail: .reduced)
            
            try photogrammetrySession.process(requests: [request])
            
            for try await output in photogrammetrySession.outputs {
                switch output {
                case .requestComplete(_, .modelFile(let url)):
                    appState.accept(.completed(url))
                case .requestError(_, let error):
                    appState.accept(.failed(error))
                default:
                    break
                }
            }
        } catch {
            appState.accept(.failed(error))
        }
    }
}
