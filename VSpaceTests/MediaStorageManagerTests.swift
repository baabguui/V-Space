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

    private func makeTestImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        return renderer.image { _ in
            UIColor.red.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }
}
