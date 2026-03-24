//
//  CaptureViewModel.swift
//  VSpace
//
//  ObjectCaptureSession 관리 + RxSwift 상태 관리
//
//  상태 관찰: session.stateUpdates (AsyncSequence) — onChange 불필요
//

import Foundation
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
    }

    // MARK: - Output (RxSwift)

    let appState = BehaviorRelay<AppState>(value: .loading)

    // MARK: - Session

    private(set) var session: ObjectCaptureSession

    // MARK: - Private

    private let directoryManager: CaptureDirectoryManaging

    // MARK: - Init

    init(directoryManager: CaptureDirectoryManaging = CaptureDirectoryManager()) {
        self.directoryManager = directoryManager
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

    /// 기존 checkpoint + imagesDirectory를 재사용해 새 세션으로 캡쳐를 재개합니다.
    /// .finishing 후 USDZ 생성 실패 시 호출
    func resumeCapture() {
        session = ObjectCaptureSession()
        appState.accept(.loading)
        startSession(session)
    }

    func finishCapture() {
        session.finish()
        appState.accept(.finishing)
    }

    // MARK: - Private

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
            guard case .cancelled = appState.value else {
                appState.accept(.finishing)
                Task { await generateUSDZ() }
                return
            }
        case .failed(let error):
            guard case .cancelled = appState.value else {
                appState.accept(.failed(error))
                return
            }
        default:
            break
        }
    }

    private func generateUSDZ() async {
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
