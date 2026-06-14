@testable import fsi
import Testing

@Suite("TrieIndex (backend-specific)")
struct TrieIndexTests {
    @Test("is Sendable when Value is Sendable")
    func sendableConformance() async {
        var index = TrieIndex<Int>()
        index.put("/a/b/c", 42)

        let task = Task { index.get("/a/b/c") }
        #expect(await task.value == 42)
    }

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

    @Test("initializes from a dictionary using a custom scheme mapper")
    func initFromDictionaryWithMapper() {
        let index = TrieIndex<Int>(["fs:/a/b": 1, "photos:/a/b": 2], schemeMapper: Schemes.aliases("fs", "file"))

        #expect(index.size == 2)
        #expect(index.get("/a/b") == 1)
        #expect(index.get("file:/a/b") == 1)
        #expect(index.get("photos:/a/b") == 2)
        #expect(index.keys == ["/a/b", "photos:/a/b"])
    }

    @Test("distinguishes a scheme-qualified path from a local path with a matching colon segment")
    func schemeVsLocalColonSegment() {
        var index = TrieIndex<Int>()
        index.put("photos:/x", 1)
        index.put("/photos:/x", 2)

        #expect(index.size == 2)
        #expect(index.get("photos:/x") == 1)
        #expect(index.get("/photos:/x") == 2)
        #expect(index.keys == ["photos:/x", "/photos:/x"])
    }

    @Test("normalizes repeated, trailing and missing leading separators")
    func normalizesSeparators() {
        let cases: [(String, String)] = [
            ("/a/b/c", "/a/b/c"),
            ("a/b/c", "/a/b/c"),
            ("/a//b///c/", "/a/b/c"),
            ("////", "/"),
            ("", "/"),
            ("/", "/")
        ]

        for (input, expected) in cases {
            var index = TrieIndex<Int>()
            index.put(input, 1)
            #expect(index.keys == [expected], "input=[\(input)]")
        }
    }

    @Test("normalizes malformed scheme-qualified paths")
    func normalizesMalformedSchemes() {
        let cases: [(String, String)] = [
            ("photos:/a/b", "photos:/a/b"),
            ("photos:/", "photos:/"),
            ("photos:", "photos:/"),
            ("photos://///", "photos:/"),
            ("photos://a//b/", "photos:/a/b")
        ]

        for (input, expected) in cases {
            var index = TrieIndex<Int>()
            index.put(input, 1)
            #expect(index.keys == [expected], "input=[\(input)]")
        }
    }

    @Test("treats equivalent local paths as the same entry")
    func equivalentLocalPaths() {
        var index = TrieIndex<Int>()
        index.put("/a/b", 1)
        index.put("a/b", 2)
        index.put("//a//b//", 3)

        #expect(index.size == 1)
        #expect(index.get("/a/b") == 3)
        #expect(index.keys == ["/a/b"])
    }
}
