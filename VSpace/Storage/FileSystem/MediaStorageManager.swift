//
//  MediaStorageManager.swift
//  VSpace
//
//  앱 영구 저장소 관리 — 모델, 썸네일, 인증서 등 앱 미디어 파일 담당
//
//  저장 구조:
//  Documents/
//  ├── .Objects/
//  │   ├── Models/          → USDZ 모델 (obj_{uuid}.usdz)
//  │   └── Images/          → 사진 원본 (img_{uuid}.jpg)
//  ├── .Thumbnails/         → 썸네일 이미지 (예정)
//  └── .Certs/              → 의식 결과 이미지 (예정)
//

import UIKit

// MARK: - Protocol

protocol MediaStorageManaging {
    @discardableResult func saveModel(from sourceURL: URL) throws -> URL
    @discardableResult func savePhoto(_ image: UIImage) throws -> String
    @discardableResult func saveThumbnail(_ image: UIImage) throws -> String
    func loadThumbnail(_ fileName: String) -> UIImage?
    func loadPhoto(_ fileName: String) -> UIImage?
    func modelURL(for fileName: String) -> URL?
}

// MARK: - MediaStorageManager

final class MediaStorageManager: MediaStorageManaging {

    static let shared = MediaStorageManager()

    private let modelsDirectory: URL
    private let imagesDirectory: URL
    private let thumbnailsDirectory: URL
    private let certsDirectory: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        modelsDirectory    = docs.appendingPathComponent(".Objects/Models")
        imagesDirectory    = docs.appendingPathComponent(".Objects/Images")
        thumbnailsDirectory = docs.appendingPathComponent(".Thumbnails")
        certsDirectory     = docs.appendingPathComponent(".Certs")
        createDirectoriesIfNeeded()
    }

    // MARK: - saveModel

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

    // MARK: - savePhoto

    /// 선택된 원본 이미지를 Documents/.Objects/Images/ 에 저장하고 파일명을 반환
    /// 긴 변이 2048px 초과 시 다운샘플링 후 PNG 저장 (누끼 후처리용 투명도 보존)
    @discardableResult
    func savePhoto(_ image: UIImage) throws -> String {
        let resized = image.downsampledIfNeeded(maxDimension: 2048)
        guard let data = resized.pngData() else {
            throw MediaStorageError.pngConversionFailed
        }
        let fileName = "img_\(UUID().uuidString).png"
        let dest = imagesDirectory.appendingPathComponent(fileName)
        try data.write(to: dest)
        return fileName
    }

    // MARK: - saveThumbnail

    /// CircularCropViewController에서 렌더링된 300×300 원형 PNG를 .Thumbnails/ 에 저장
    @discardableResult
    func saveThumbnail(_ image: UIImage) throws -> String {
        guard let data = image.pngData() else {
            throw MediaStorageError.pngConversionFailed
        }
        let fileName = "thumb_\(UUID().uuidString).png"
        let dest = thumbnailsDirectory.appendingPathComponent(fileName)
        try data.write(to: dest)
        return fileName
    }

    // MARK: - loadThumbnail

    func loadThumbnail(_ fileName: String) -> UIImage? {
        let url = thumbnailsDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }

    // MARK: - loadPhoto

    func loadPhoto(_ fileName: String) -> UIImage? {
        let url = imagesDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }

    // MARK: - modelURL

    func modelURL(for fileName: String) -> URL? {
        let url = modelsDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Private

    private func createDirectoriesIfNeeded() {
        [modelsDirectory, imagesDirectory, thumbnailsDirectory, certsDirectory].forEach { url in
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Error

// MARK: - UIImage Downsampling

private extension UIImage {
    /// 긴 변이 maxDimension을 초과하면 비율을 유지하며 리사이징
    func downsampledIfNeeded(maxDimension: CGFloat) -> UIImage {
        let longer = max(size.width, size.height)
        guard longer > maxDimension else { return self }
        let scale = maxDimension / longer
        let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Error

enum MediaStorageError: LocalizedError {
    case verificationFailed(URL)
    case pngConversionFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed(let url):
            return String(format: NSLocalizedString("error.file.verification", comment: ""), url.lastPathComponent)
        case .pngConversionFailed:
            return NSLocalizedString("error.photo.png.conversion", comment: "")
        }
    }
}
