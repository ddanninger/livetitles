import XCTest
@testable import LiveTitles

final class NameExtractorTests: XCTestCase {
    let extractor = NameExtractor()

    func testImContraction() {
        XCTAssertEqual(extractor.extractName(from: "Hi I'm Sarah"), "Sarah")
    }

    func testIAm() {
        XCTAssertEqual(extractor.extractName(from: "Hello I am Tom"), "Tom")
    }

    func testMyNameIs() {
        XCTAssertEqual(extractor.extractName(from: "My name is Maria"), "Maria")
    }

    func testCallMe() {
        XCTAssertEqual(extractor.extractName(from: "Just call me Alex"), "Alex")
    }

    func testThisIs() {
        XCTAssertEqual(extractor.extractName(from: "Hey this is David"), "David")
    }

    func testHere() {
        XCTAssertEqual(extractor.extractName(from: "Hi, James here"), "James")
    }

    func testNoName() {
        XCTAssertNil(extractor.extractName(from: "Let me share my screen"))
    }

    func testFiltersCommonWords() {
        XCTAssertNil(extractor.extractName(from: "I'm Sure about that"))
    }
}
