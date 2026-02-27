import Foundation

/// LRU cache for repeated translations (common meeting phrases).
final class TranslationCache {
    private var cache: [String: CacheEntry] = [:]
    private let maxSize: Int

    struct CacheEntry {
        let translation: String
        var lastAccessed: Date
    }

    init(maxSize: Int = 200) {
        self.maxSize = maxSize
    }

    func get(text: String, targetLanguage: String) -> String? {
        let key = cacheKey(text: text, targetLanguage: targetLanguage)
        guard var entry = cache[key] else { return nil }
        entry.lastAccessed = .now
        cache[key] = entry
        return entry.translation
    }

    func set(text: String, targetLanguage: String, translation: String) {
        let key = cacheKey(text: text, targetLanguage: targetLanguage)
        cache[key] = CacheEntry(translation: translation, lastAccessed: .now)
        evictIfNeeded()
    }

    func clear() {
        cache.removeAll()
    }

    private func cacheKey(text: String, targetLanguage: String) -> String {
        "\(targetLanguage):\(text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    private func evictIfNeeded() {
        guard cache.count > maxSize else { return }
        let sortedKeys = cache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
        let toRemove = cache.count - maxSize
        for (key, _) in sortedKeys.prefix(toRemove) {
            cache.removeValue(forKey: key)
        }
    }
}
