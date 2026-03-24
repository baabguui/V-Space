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
import RxSwift
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

    private(set) var session: ObjectCaptureSession?

    // MARK: - Private

    private let captureDirectory: URL
    private let imagesDirectory: URL
    private let checkpointDirectory: URL
    let outputURL: URL

    // MARK: - Init

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let captureID = UUID().uuidString
        captureDirectory    = docs.appendingPathComponent("Captures/\(captureID)")
        imagesDirectory     = captureDirectory.appendingPathComponent("Images")
        checkpointDirectory = captureDirectory.appendingPathComponent("Checkpoints")
        outputURL           = captureDirectory.appendingPathComponent("preview.usdz")
        createDirectories()
    }

    // MARK: - Public

    func createSession() -> ObjectCaptureSession {
        let captureSession = ObjectCaptureSession()
        self.session = captureSession

        var config = ObjectCaptureSession.Configuration()
        config.checkpointDirectory = checkpointDirectory
        config.isOverCaptureEnabled = true

        captureSession.start(imagesDirectory: imagesDirectory, configuration: config)

        // session.stateUpdates AsyncSequence로 상태 관찰
        Task { @MainActor [weak self] in
            guard let self else { return }
            for await state in captureSession.stateUpdates {
                self.handleSessionState(state, session: captureSession)
            }
        }

        return captureSession
    }
    
    func startDetecting() {
        let _ = session?.startDetecting()
    }
    
    func startCapturing() {
        session?.startCapturing()
    }

    func cancelCapture() {
        print("cancelled")
        session?.cancel()
        cleanupDirectories()
        appState.accept(.cancelled)
    }

    func finishCapture() {
        session?.finish()
        appState.accept(.finishing)
    }

    // MARK: - Private

    private func handleSessionState(_ state: ObjectCaptureSession.CaptureState,
                                    session: ObjectCaptureSession) {
        switch session.state {
        case .initializing:
            appState.accept(.loading)
        case .ready:
            appState.accept(.ready)
        case .detecting:
            appState.accept(.detecting)
        case .capturing:
            appState.accept(.capturing)
        case .finishing:
            appState.accept(.finishing)
            Task {
                await generateUSDZ()
            }
        case .failed(let error):
            appState.accept(.failed(error))
        @unknown default:
            break
        }
    }

    private func createDirectories() {
        [imagesDirectory, checkpointDirectory].forEach {
            try? FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true)
        }
    }

    private func cleanupDirectories() {
        try? FileManager.default.removeItem(at: captureDirectory)
    }
    
    private func generateUSDZ() async {
        do {
            let photogrammetrySession = try PhotogrammetrySession(input: imagesDirectory)
            
            let request = PhotogrammetrySession.Request.modelFile(url: outputURL, detail: .reduced)
            
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
