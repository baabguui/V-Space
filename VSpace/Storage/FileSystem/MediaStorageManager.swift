//
//  MediaStorageManager.swift
//  VSpace
//
//  앱 영구 저장소 관리 — 모델, 썸네일, 인증서 등 앱 미디어 파일 담당
//
//  저장 구조:
//  Documents/
//  ├── .Objects/Models/     → USDZ 모델 (obj_{uuid}.usdz)
//  ├── .Thumbnails/         → 썸네일 이미지
//  └── .Certs/              → 의식 결과 이미지
//

import Foundation

// MARK: - Protocol

protocol MediaStorageManaging {
    @discardableResult func saveModel(from sourceURL: URL) throws -> URL
}

// MARK: - MediaStorageManager

final class MediaStorageManager: MediaStorageManaging {

    static let shared = MediaStorageManager()

    private let modelsDirectory: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        modelsDirectory = docs.appendingPathComponent(".Objects/Models")
    }

    @discardableResult
    func saveModel(from sourceURL: URL) throws -> URL {
        try FileManager.default.createDirectory(
            at: modelsDirectory,
            withIntermediateDirectories: true
        )

        let dest = modelsDirectory
            .appendingPathComponent("obj_\(UUID().uuidString).usdz")
        try FileManager.default.copyItem(at: sourceURL, to: dest)

        guard FileManager.default.fileExists(atPath: dest.path) else {
            throw MediaStorageError.verificationFailed(dest)
        }

        return dest
    }
}

// MARK: - Error

enum MediaStorageError: LocalizedError {
    case verificationFailed(URL)

    var errorDescription: String? {
        switch self {
        case .verificationFailed(let url):
            return String(format: NSLocalizedString("error.file.verification", comment: ""), url.lastPathComponent)
        }
    }
}
