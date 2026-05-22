@testable import fsi
import Testing

@Suite("TrieIndex (backend-specific)")
struct TrieIndexTests {
    @Test("initializes from an existing dictionary")
    func initFromDictionary() {
        let entries = ["/a/b/c": 1, "/a/b/d": 2]
        let index = TrieIndex<Int>(entries)

        #expect(index.size == 2)
        #expect(index.get("/a/b/c") == 1)
        #expect(index.get("/a/b/d") == 2)
    }

    @Test("copies are isolated under mutation (copy-on-write)")
    func copyOnWrite() {
        var original = TrieIndex<Int>()
        original.put("/a/b/c", 1)

        var copy = original
        copy.put("/a/b/d", 2)

        #expect(original.size == 1)
        #expect(original.get("/a/b/d") == nil)
        #expect(copy.size == 2)
        #expect(copy.get("/a/b/c") == 1)
        #expect(copy.get("/a/b/d") == 2)
    }
}
