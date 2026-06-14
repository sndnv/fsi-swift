@testable import fsi
import Testing

@Suite("Schemes")
struct SchemesTests {
    @Test("provides the scheme delimiter")
    func delimiter() {
        #expect(Schemes.Delimiter == ":")
    }

    @Test("provides an identity scheme mapper")
    func identity() {
        #expect(Schemes.Identity(nil) == nil)
        #expect(Schemes.Identity("fs") == "fs")
        #expect(Schemes.Identity("photos") == "photos")
        #expect(Schemes.Identity("FS") == "FS")
    }

    @Test("provides a lower-casing scheme mapper")
    func lowercase() {
        #expect(Schemes.Lowercase(nil) == nil)
        #expect(Schemes.Lowercase("FS") == "fs")
        #expect(Schemes.Lowercase("Photos") == "photos")
        #expect(Schemes.Lowercase("music") == "music")
    }

    @Test("provides an upper-casing scheme mapper")
    func uppercase() {
        #expect(Schemes.Uppercase(nil) == nil)
        #expect(Schemes.Uppercase("FS") == "FS")
        #expect(Schemes.Uppercase("Photos") == "PHOTOS")
        #expect(Schemes.Uppercase("music") == "MUSIC")
    }

    @Test("provides an aliasing scheme mapper")
    func aliases() {
        let mapper = Schemes.aliases("fs", "file")

        #expect(mapper("fs") == nil)
        #expect(mapper("file") == nil)
        #expect(mapper("FS") == nil)
        #expect(mapper("File") == nil)

        #expect(mapper("photos") == "photos")
        #expect(mapper("Photos") == "Photos")
        #expect(mapper(nil) == nil)
    }

    @Test("treats alias names case-insensitively")
    func aliasesCaseInsensitive() {
        let mapper = Schemes.aliases("FS", "FILE")

        #expect(mapper("fs") == nil)
        #expect(mapper("file") == nil)
        #expect(mapper("photos") == "photos")
    }

    @Test("provides an aliasing mapper with no names that preserves every scheme")
    func aliasesEmpty() {
        let mapper = Schemes.aliases()

        #expect(mapper(nil) == nil)
        #expect(mapper("fs") == "fs")
        #expect(mapper("photos") == "photos")
    }

    @Test("splits paths into their scheme and remainder")
    func split() {
        // swiftlint:disable:next large_tuple
        let cases: [(String, String?, String)] = [
            ("/a/b/c", nil, "/a/b/c"),
            ("", nil, ""),
            ("/", nil, "/"),
            ("a", nil, "a"),
            ("photos:/a/b/c", "photos", "/a/b/c"),
            ("photos:/", "photos", "/"),
            ("photos:", "photos", ""),
            ("ab:x", "ab", "x"),
            ("mailto:foo", "mailto", "foo"),
            ("ab:c:d", "ab", "c:d"),
            ("x-y.z+1:/a", "x-y.z+1", "/a"),
            ("a1+.-x:/p", "a1+.-x", "/p"),
            ("FS:/a", "FS", "/a"),
            ("c:/x", nil, "c:/x"),
            ("a:", nil, "a:"),
            ("12:30", nil, "12:30"),
            ("/photos:/x", nil, "/photos:/x"),
            (":", nil, ":"),
            (":/x", nil, ":/x"),
            ("_x:/p", nil, "_x:/p"),
            (" fs:/a", nil, " fs:/a")
        ]

        for (input, expectedScheme, expectedRest) in cases {
            let (scheme, rest) = Schemes.split(input)
            #expect(scheme == expectedScheme, "input=[\(input)]")
            #expect(rest == expectedRest, "input=[\(input)]")
        }
    }
}
