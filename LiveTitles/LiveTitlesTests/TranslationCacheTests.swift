import XCTest
@testable import LiveTitles

final class TranslationCacheTests: XCTestCase {
    func testCacheHitAndMiss() {
        let cache = TranslationCache(maxSize: 10)

        XCTAssertNil(cache.get(text: "Hello", targetLanguage: "de"))

        cache.set(text: "Hello", targetLanguage: "de", translation: "Hallo")
        XCTAssertEqual(cache.get(text: "Hello", targetLanguage: "de"), "Hallo")
    }

    func testCaseInsensitiveKeys() {
        let cache = TranslationCache(maxSize: 10)
        cache.set(text: "Hello", targetLanguage: "de", translation: "Hallo")
        XCTAssertEqual(cache.get(text: "hello", targetLanguage: "de"), "Hallo")
    }

    func testDifferentLanguages() {
        let cache = TranslationCache(maxSize: 10)
        cache.set(text: "Hello", targetLanguage: "de", translation: "Hallo")
        cache.set(text: "Hello", targetLanguage: "fr", translation: "Bonjour")

        XCTAssertEqual(cache.get(text: "Hello", targetLanguage: "de"), "Hallo")
        XCTAssertEqual(cache.get(text: "Hello", targetLanguage: "fr"), "Bonjour")
    }

    func testEviction() {
        let cache = TranslationCache(maxSize: 3)
        cache.set(text: "A", targetLanguage: "de", translation: "A_de")
        cache.set(text: "B", targetLanguage: "de", translation: "B_de")
        cache.set(text: "C", targetLanguage: "de", translation: "C_de")
        cache.set(text: "D", targetLanguage: "de", translation: "D_de")

        // "A" should have been evicted (oldest)
        XCTAssertNil(cache.get(text: "A", targetLanguage: "de"))
        XCTAssertEqual(cache.get(text: "D", targetLanguage: "de"), "D_de")
    }
}
