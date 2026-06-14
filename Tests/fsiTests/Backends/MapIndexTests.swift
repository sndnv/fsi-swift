@testable import fsi
import Testing

@Suite("MapIndex (backend-specific)")
struct MapIndexTests {
    @Test("copies are isolated under mutation")
    func valueSemantics() {
        var original = MapIndex<Int>()
        original.put("/a/b/c", 1)

        var copy = original
        copy.put("/a/b/d", 2)

        #expect(original.size == 1)
        #expect(original.get("/a/b/d") == nil)
        #expect(copy.size == 2)
        #expect(copy.get("/a/b/c") == 1)
        #expect(copy.get("/a/b/d") == 2)
    }

    @Test("is Sendable when Value is Sendable")
    func sendableConformance() async {
        var index = MapIndex<Int>()
        index.put("/a/b/c", 42)

        let task = Task { index.get("/a/b/c") }
        #expect(await task.value == 42)
    }

    @Test("initializes from an existing dictionary")
    func initFromDictionary() {
        let entries = ["/a/b/c": 1, "/a/b/d": 2]
        let index = MapIndex<Int>(entries)

        #expect(index.size == 2)
        #expect(index.get("/a/b/c") == 1)
        #expect(index.get("/a/b/d") == 2)
    }

    @Test("stores path-like strings without normalization by default")
    func noNormalizationByDefault() {
        var index = MapIndex<Int>()
        index.put("/a/b", 1)
        index.put("a/b", 2)
        index.put("//a//b//", 3)
        index.put("photos:/a/b", 4)
        index.put("fs:/a/b", 5)

        #expect(index.size == 5)
        #expect(index.keys == ["/a/b", "a/b", "//a//b//", "photos:/a/b", "fs:/a/b"])
    }

    @Test("initializes from a dictionary using a custom scheme mapper")
    func initFromDictionaryWithMapper() {
        let index = MapIndex<Int>(["/a/b": 1, "photos:/a/b": 2], schemeMapper: Schemes.aliases("fs", "file"))

        #expect(index.size == 2)
        #expect(index.get("fs:/a/b") == 1)
        #expect(index.get("file:/a/b") == 1)
        #expect(index.get("/a/b") == 1)
        #expect(index.get("photos:/a/b") == 2)
        #expect(index.keys == ["/a/b", "photos:/a/b"])
    }

    @Test("applies a custom scheme mapper to keys")
    func customSchemeMapper() {
        var index = MapIndex<Int>(schemeMapper: Schemes.aliases("fs", "file"))
        index.put("fs:/a/b", 1)
        index.put("file:/a/b", 2)
        index.put("photos:/a/b", 3)

        #expect(index.size == 2)
        #expect(index.get("/a/b") == 2)
        #expect(index.keys == ["/a/b", "photos:/a/b"])
    }
}
