//
//  CaptureDirectoryManager.swift
//  VSpace
//
//  캡쳐 세션에 필요한 디렉토리 경로 관리 및 FileManager 작업 담당
//

import Foundation

// MARK: - Protocol

protocol CaptureDirectoryManaging {
    var imagesDirectory: URL { get }
    var checkpointDirectory: URL { get }
    var outputURL: URL { get }
    func setup() throws
    func cleanup()
}

// MARK: - CaptureDirectoryManager

final class CaptureDirectoryManager: CaptureDirectoryManaging {

    private let captureDirectory: URL
    let imagesDirectory: URL
    let checkpointDirectory: URL
    let outputURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let id = UUID().uuidString
        captureDirectory    = docs.appendingPathComponent("Captures/\(id)")
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
}
