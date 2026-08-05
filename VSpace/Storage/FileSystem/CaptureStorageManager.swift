//
//  CaptureStorageManager.swift
//  VSpace
//
//  캡쳐 세션에 필요한 임시 디렉토리 경로 관리 및 FileManager 작업 담당
//

import Foundation

// MARK: - Protocol

protocol CaptureStorageManaging {
    var imagesDirectory: URL { get }
    var checkpointDirectory: URL { get }
    var outputURL: URL { get }
    func setup() throws
    func cleanup()
}

// MARK: - CaptureStorageManager

final class CaptureStorageManager: CaptureStorageManaging {

    private let captureDirectory: URL
    let imagesDirectory: URL
    let checkpointDirectory: URL
    let outputURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let capturesRoot = docs.appendingPathComponent("Captures")

        // 이전 세션 잔여 파일 일괄 삭제 (강제 종료 등 비정상 종료 대비)
        try? FileManager.default.removeItem(at: capturesRoot)

        let id = UUID().uuidString
        captureDirectory    = capturesRoot.appendingPathComponent(id)
        imagesDirectory     = captureDirectory.appendingPathComponent("Images")
        checkpointDirectory = captureDirectory.appendingPathComponent("Checkpoints")
        outputURL           = captureDirectory.appendingPathComponent("preview.usdz")
    }

    func setup() throws {
        try [imagesDirectory, checkpointDirectory].forEach {
            try FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true)
        }
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: captureDirectory)
    }

    /// 강제 종료 등으로 정리되지 못한 이전 캡처 임시 디렉토리를 앱 시작 시 일괄 삭제
    static func sweepStaleDirectories() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? FileManager.default.removeItem(at: docs.appendingPathComponent("Captures"))
    }
}
