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

    @Test("round-trips drive paths expressed with forward slashes")
    func roundTripsDrivePaths() {
        let cases: [(String, String)] = [
            ("C:/source", "C:/source"),
            ("C:/a/b/c.dat", "C:/a/b/c.dat"),
            ("C:/a//b/", "C:/a/b")
        ]

        for (input, expected) in cases {
            var index = TrieIndex<Int>()
            index.put(input, 1)
            #expect(index.size == 1, "input=[\(input)]")
            #expect(index.get(input) == 1, "input=[\(input)]")
            #expect(index.keys == [expected], "input=[\(input)]")
        }
    }

    @Test("does not treat single-character drive letters as schemes")
    func driveLettersAreNotSchemes() {
        var index = TrieIndex<Int>()
        index.put("C:/source", 1)
        index.put("photos:/source", 2)

        #expect(index.size == 2)
        #expect(index.keys == ["C:/source", "photos:/source"])
    }

    @Test("does not treat non-drive two-character prefixes as drive roots")
    func nonDrivePrefixesAreNotRoots() {
        var index = TrieIndex<Int>()
        index.put("5:/x", 1)
        index.put("ab/c", 2)

        #expect(index.size == 2)
        #expect(index.get("5:/x") == 1)
        #expect(index.get("ab/c") == 2)
        #expect(index.keys == ["5:/x", "ab/c"])
    }

    @Test("collapses a bare drive root")
    func collapsesBareDriveRoot() {
        let cases: [(String, String)] = [
            ("C:/", "C:"),
            ("C:", "C:")
        ]

        for (input, expected) in cases {
            var index = TrieIndex<Int>()
            index.put(input, 1)
            #expect(index.size == 1, "input=[\(input)]")
            #expect(index.get(input) == 1, "input=[\(input)]")
            #expect(index.keys == [expected], "input=[\(input)]")
        }
    }

    @Test("round-trips UNC paths")
    func roundTripsUNCPaths() {
        let cases: [(String, String)] = [
            ("//server/share", "//server/share"),
            ("//server/share/path", "//server/share/path"),
            ("//server//share//", "//server/share")
        ]

        for (input, expected) in cases {
            var index = TrieIndex<Int>()
            index.put(input, 1)
            #expect(index.size == 1, "input=[\(input)]")
            #expect(index.get(input) == 1, "input=[\(input)]")
            #expect(index.keys == [expected], "input=[\(input)]")
        }
    }

    @Test("keeps a UNC path distinct from a drive-letter head")
    func uncDistinctFromDriveHead() {
        var index = TrieIndex<Int>()
        index.put("C:/x", 1)
        index.put("//C:/x", 2)

        #expect(index.size == 2)
        #expect(index.get("C:/x") == 1)
        #expect(index.get("//C:/x") == 2)
        #expect(index.keys == ["C:/x", "//C:/x"])
    }

    @Test("merges a drive path with its redundantly-rooted form")
    func mergesRedundantlyRootedDrivePath() {
        var index = TrieIndex<Int>()
        index.put("C:/x", 1)
        index.put("/C:/x", 2)

        #expect(index.size == 1)
        #expect(index.get("C:/x") == 2)
        #expect(index.get("/C:/x") == 2)
        #expect(index.keys == ["C:/x"])
    }

    @Test("preserves drive roots under a scheme and rejects non-drive heads")
    func driveRootsUnderScheme() {
        let cases: [(String, String)] = [
            ("fs:a:/x", "fs:a:/x"),
            ("fs:z:/x", "fs:z:/x"),
            ("fs:A:/x", "fs:A:/x"),
            ("fs:Z:/x", "fs:Z:/x"),
            ("fs:5:/x", "fs:/5:/x"),
            ("fs:ab/x", "fs:/ab/x"),
            ("fs:a:b/x", "fs:/a:b/x")
        ]

        for (input, expected) in cases {
            var index = TrieIndex<Int>()
            index.put(input, 1)
            #expect(index.size == 1, "input=[\(input)]")
            #expect(index.get(input) == 1, "input=[\(input)]")
            #expect(index.keys == [expected], "input=[\(input)]")
        }
    }

    @Test("normalizes repeated and trailing separators while preserving rootedness")
    func normalizesSeparators() {
        let cases: [(String, String)] = [
            ("/a/b/c", "/a/b/c"),
            ("a/b/c", "a/b/c"),
            ("/a//b///c/", "/a/b/c"),
            ("////", "/"),
            ("", ""),
            ("/", "/")
        ]

        for (input, expected) in cases {
            var index = TrieIndex<Int>()
            index.put(input, 1)
            #expect(index.keys == [expected], "input=[\(input)]")
        }
    }

    @Test("preserves whitespace-only path segments")
    func preservesWhitespaceSegments() {
        var index = TrieIndex<Int>()
        index.put("/a/ /b", 1)
        index.put("/a/b", 2)

        #expect(index.size == 2)
        #expect(index.get("/a/ /b") == 1)
        #expect(index.get("/a/b") == 2)
        #expect(index.keys == ["/a/ /b", "/a/b"])
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

    @Test("treats differently-rooted paths as distinct entries")
    func distinctlyRootedPaths() {
        var index = TrieIndex<Int>()
        index.put("/a/b", 1)
        index.put("a/b", 2)
        index.put("//a/b", 3)

        #expect(index.size == 3)
        #expect(index.get("/a/b") == 1)
        #expect(index.get("a/b") == 2)
        #expect(index.get("//a/b") == 3)
        #expect(index.keys == ["/a/b", "a/b", "//a/b"])
    }

    @Test("collapses redundant interior and trailing separators within an entry")
    func collapsesRedundantSeparators() {
        var index = TrieIndex<Int>()
        index.put("/a/b", 1)
        index.put("/a//b", 2)
        index.put("/a/b//", 3)

        #expect(index.size == 1)
        #expect(index.get("/a/b") == 3)
        #expect(index.keys == ["/a/b"])
    }
}
