import XCTest
@testable import VSpace

final class CaptureStorageManagerTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func test_setup_createsImagesAndCheckpointDirectories() throws {
        let sut = CaptureStorageManager(baseDirectory: tempDirectory)

        try sut.setup()

        XCTAssertTrue(FileManager.default.fileExists(atPath: sut.imagesDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sut.checkpointDirectory.path))
    }

    func test_cleanup_removesEntireCaptureDirectory() throws {
        let sut = CaptureStorageManager(baseDirectory: tempDirectory)
        try sut.setup()
        try Data("dummy".utf8).write(to: sut.imagesDirectory.appendingPathComponent("photo.heic"))

        sut.cleanup()

        XCTAssertFalse(FileManager.default.fileExists(atPath: sut.imagesDirectory.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: sut.checkpointDirectory.path))
    }

    func test_init_sweepsPreviousSessionLeftoverFiles() throws {
        let previousSession = CaptureStorageManager(baseDirectory: tempDirectory)
        try previousSession.setup()
        try Data("dummy".utf8).write(to: previousSession.imagesDirectory.appendingPathComponent("leftover.heic"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: previousSession.imagesDirectory.path))

        _ = CaptureStorageManager(baseDirectory: tempDirectory)

        XCTAssertFalse(FileManager.default.fileExists(atPath: previousSession.imagesDirectory.path))
    }
}
