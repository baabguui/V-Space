import XCTest
@testable import VSpace

final class MediaStorageManagerTests: XCTestCase {

    private var tempDirectory: URL!
    private var sut: MediaStorageManager!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        sut = MediaStorageManager(baseDirectory: tempDirectory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func test_savePhoto_thenLoadPhoto_returnsImage() throws {
        let fileName = try sut.savePhoto(makeTestImage())

        XCTAssertNotNil(sut.loadPhoto(fileName))
    }

    func test_deleteKeepsakeFiles_photoType_removesImageAndThumbnail() throws {
        let photoFileName = try sut.savePhoto(makeTestImage())
        let thumbFileName = try sut.saveThumbnail(makeTestImage())
        XCTAssertNotNil(sut.loadPhoto(photoFileName))
        XCTAssertNotNil(sut.loadThumbnail(thumbFileName))

        sut.deleteKeepsakeFiles(resourceFileName: photoFileName, thumbnailFileName: thumbFileName, recordType: .photo)

        XCTAssertNil(sut.loadPhoto(photoFileName))
        XCTAssertNil(sut.loadThumbnail(thumbFileName))
    }

    func test_deleteKeepsakeFiles_threeDType_removesModelAndThumbnail() throws {
        let sourceURL = tempDirectory.appendingPathComponent("source.usdz")
        try Data("dummy".utf8).write(to: sourceURL)
        let modelFileName = try sut.saveModel(from: sourceURL).lastPathComponent
        let thumbFileName = try sut.saveThumbnail(makeTestImage())
        XCTAssertNotNil(sut.modelURL(for: modelFileName))

        sut.deleteKeepsakeFiles(resourceFileName: modelFileName, thumbnailFileName: thumbFileName, recordType: .threeD)

        XCTAssertNil(sut.modelURL(for: modelFileName))
        XCTAssertNil(sut.loadThumbnail(thumbFileName))
    }

    func test_deleteKeepsakeFiles_whenFilesMissing_doesNotThrowOrCrash() {
        sut.deleteKeepsakeFiles(resourceFileName: "nonexistent.png", thumbnailFileName: "nonexistent-thumb.png", recordType: .photo)
    }

    func test_modelURL_withoutSaving_returnsNil() {
        XCTAssertNil(sut.modelURL(for: "obj_never-saved.usdz"))
    }

    func test_saveModel_withMissingSourceURL_throws() {
        let missingSourceURL = tempDirectory.appendingPathComponent("does-not-exist.usdz")

        XCTAssertThrowsError(try sut.saveModel(from: missingSourceURL))
    }

    func test_savePhoto_whenLongerSideExceedsMax_downsamplesToMaxDimension() throws {
        let fileName = try sut.savePhoto(makeTestImage(size: CGSize(width: 4096, height: 2048)))

        let loaded = try XCTUnwrap(sut.loadPhoto(fileName))

        XCTAssertEqual(max(loaded.size.width, loaded.size.height), 2048)
    }

    func test_savePhoto_whenWithinMaxDimension_keepsOriginalSize() throws {
        let fileName = try sut.savePhoto(makeTestImage(size: CGSize(width: 100, height: 50)))

        let loaded = try XCTUnwrap(sut.loadPhoto(fileName))

        XCTAssertEqual(loaded.size, CGSize(width: 100, height: 50))
    }

    private func makeTestImage(size: CGSize = CGSize(width: 10, height: 10)) -> UIImage {
        // scale 1.0 고정: 저장 후 재로드 시 size가 실제 피커 이미지(scale 1)와 동일하게 비교되도록 함
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            UIColor.red.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
        }
    }
}
