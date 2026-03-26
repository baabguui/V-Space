//
//  CaptureViewModel.swift
//  VSpace
//
//  ObjectCaptureSession 관리 + RxSwift 상태 관리
//
//  상태 관찰: session.stateUpdates (AsyncSequence) — onChange 불필요
//

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
        directoryManager.cleanup()
        appState.accept(.cancelled)
    }

    /// 완료 버튼: session.finish() 없이 현재 이미지로 USDZ 생성 시작
    /// 세션은 .capturing 상태를 유지하므로 뷰어에서 돌아와 추가 스캔 가능
    func finishCapture() { startGenerating() }

    /// USDZ 생성 실패 후 재시도
    func retryUSDZ() { startGenerating() }

    /// 뷰어에서 돌아와 캡쳐 계속하기 (세션은 살아있음)
    func resumeCapturing() {
        appState.accept(.capturing)
    }

    /// 저장 확정 시 세션 취소 후 파일 복사 + Keepsake 초기 레코드 생성
    /// finish() 대신 cancel()을 사용해 세션의 내부 파일 접근을 막음
    func saveModel() {
        session.cancel()
        do {
            let dest = try mediaStorage.saveModel(from: directoryManager.outputURL)
            directoryManager.cleanup()
            let keepsake = Keepsake()
            keepsake.resourceFileName = dest.lastPathComponent
            keepsake.thumbnailFileName = ""
            keepsake.recordType = .threeD
            keepsake.disposalDate = Date()
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
            case .cancelled, .completed, .saved(_):
                break  // 저장/취소 이후 세션에서 올라오는 에러 무시
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
