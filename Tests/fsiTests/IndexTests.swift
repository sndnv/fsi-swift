import Foundation
@testable import fsi
import Testing

private func runBasicOps<Idx: Index>(_ makeIndex: () -> Idx) where Idx.Value == Int {
    var index = makeIndex()

    #expect(index.size == 0)

    index.put("/a/b/c", 1)
    #expect(index.size == 1)
    #expect(index.get("/a/b/c") == 1)

    index.put("/a/b/c", 5) { _, existing, current in (existing ?? 0) + current }
    index.put("/a/b/d", 5) { _, existing, current in (existing ?? 0) + current }
    #expect(index.size == 2)
    #expect(index.get("/a/b/c") == 6)
    #expect(index.get("/a/b/d") == 5)

    index.putAll(["/a/b/c": 1, "/a/b/d": 1, "/a/b": 1])
    #expect(index.size == 3)
    #expect(index.get("/a/b/c") == 1)
    #expect(index.get("/a/b/d") == 1)
    #expect(index.get("/a/b") == 1)

    index.putAll(["/a/b/c": 1, "/a/b/e": 1, "/a/f": 1]) { _, existing, current in
        (existing ?? 0) + current
    }
    #expect(index.size == 5)
    #expect(index.get("/a/b/c") == 2)
    #expect(index.get("/a/b/d") == 1)
    #expect(index.get("/a/b/e") == 1)
    #expect(index.get("/a/b") == 1)
    #expect(index.get("/a/f") == 1)

    index.putAll(["/a/b/c", "/a/b/d", "/a/b/g"]) { path, existing in
        if path == "/a/b/c" || path == "/a/b/d" {
            (existing ?? 0) + 1
        } else {
            999
        }
    }
    #expect(index.size == 6)
    #expect(index.get("/a/b/c") == 3)
    #expect(index.get("/a/b/d") == 2)
    #expect(index.get("/a/b/e") == 1)
    #expect(index.get("/a/b/g") == 999)
    #expect(index.get("/a/b") == 1)
    #expect(index.get("/a/f") == 1)

    #expect(index.contains("/a/b/c"))
    #expect(index.contains("/a/b/d"))
    #expect(index.contains("/a/b/e"))
    #expect(index.contains("/a/b/g"))
    #expect(index.contains("/a/b"))
    #expect(index.contains("/a/f"))
    #expect(!index.contains("/a/x"))
    #expect(!index.contains("/a"))
    #expect(!index.contains("/"))
    #expect(!index.contains(""))

    index.remove("/a/b/d")
    #expect(index.size == 5)
    #expect(index.get("/a/b/c") == 3)
    #expect(index.get("/a/b/d") == nil)
    #expect(index.get("/a/b/e") == 1)
    #expect(index.get("/a/b/g") == 999)
    #expect(index.get("/a/b") == 1)
    #expect(index.get("/a/f") == 1)

    index.remove("/a/b")
    #expect(index.size == 4)
    #expect(index.get("/a/b/c") == 3)
    #expect(index.get("/a/b/d") == nil)
    #expect(index.get("/a/b/e") == 1)
    #expect(index.get("/a/b/g") == 999)
    #expect(index.get("/a/b") == nil)
    #expect(index.get("/a/f") == 1)

    index.remove("/a/b")
    #expect(index.size == 4)
    #expect(index.get("/a/b/c") == 3)
    #expect(index.get("/a/b/d") == nil)
    #expect(index.get("/a/b/e") == 1)
    #expect(index.get("/a/b/g") == 999)
    #expect(index.get("/a/b") == nil)
    #expect(index.get("/a/f") == 1)

    index.remove("/a/x")
    #expect(index.size == 4)
    #expect(index.get("/a/b/c") == 3)
    #expect(index.get("/a/b/d") == nil)
    #expect(index.get("/a/b/e") == 1)
    #expect(index.get("/a/b/g") == 999)
    #expect(index.get("/a/b") == nil)
    #expect(index.get("/a/f") == 1)

    index.remove("/a/b/g")
    #expect(index.size == 3)
    #expect(index.get("/a/b/c") == 3)
    #expect(index.get("/a/b/d") == nil)
    #expect(index.get("/a/b/e") == 1)
    #expect(index.get("/a/b/g") == nil)
    #expect(index.get("/a/b") == nil)
    #expect(index.get("/a/f") == 1)

    index.remove("/a/b/e")
    #expect(index.size == 2)
    #expect(index.get("/a/b/c") == 3)
    #expect(index.get("/a/b/d") == nil)
    #expect(index.get("/a/b/e") == nil)
    #expect(index.get("/a/b/g") == nil)
    #expect(index.get("/a/b") == nil)
    #expect(index.get("/a/f") == 1)

    index.remove("/a/b/c")
    #expect(index.size == 1)
    #expect(index.get("/a/b/c") == nil)
    #expect(index.get("/a/b/d") == nil)
    #expect(index.get("/a/b/e") == nil)
    #expect(index.get("/a/b/g") == nil)
    #expect(index.get("/a/b") == nil)
    #expect(index.get("/a/f") == 1)

    index.remove("/a/f")
    #expect(index.size == 0)
    #expect(index.get("/a/b/c") == nil)
    #expect(index.get("/a/b/d") == nil)
    #expect(index.get("/a/b/e") == nil)
    #expect(index.get("/a/b/g") == nil)
    #expect(index.get("/a/b") == nil)
    #expect(index.get("/a/f") == nil)

    index.putAll(["/a/b/c": 1, "/a/b/d": 1, "/a/b": 1, "/": 99])
    #expect(index.size == 4)

    var count = 0
    index.clear()
    #expect(index.size == 0)
    index.forEach { _, _ in count += 1 }
    #expect(count == 0)
    #expect(index.get("/") == nil)
}

private func runKeys<Idx: Index>(_ makeIndex: () -> Idx) where Idx.Value == Int {
    var index = makeIndex()
    let original = ["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3]
    index.putAll(original) { _, existing, current in (existing ?? 0) + current }

    #expect(index.size == 3)
    #expect(index.get("/a/b/c") == 1)
    #expect(index.get("/a/b/d") == 2)
    #expect(index.get("/a/b") == 3)

    #expect(index.keys == Set(original.keys))
}

private func runSubscript<Idx: Index>(_ makeIndex: () -> Idx) where Idx.Value == Int {
    var index = makeIndex()
    index.put("/a/b/c", 42)
    #expect(index["/a/b/c"] == 42)
    #expect(index["/missing"] == nil)
}

private func runFilterAndSearch<Idx: Index>(_ makeIndex: () -> Idx) throws where Idx.Value == Int {
    var index = makeIndex()
    index.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3]) { _, existing, current in
        (existing ?? 0) + current
    }

    #expect(index.size == 3)
    #expect(index.get("/a/b/c") == 1)
    #expect(index.get("/a/b/d") == 2)
    #expect(index.get("/a/b") == 3)

    let filtered = index.filter { _, value in value >= 2 }
    #expect(filtered.size == 2)
    #expect(filtered.get("/a/b/c") == nil)
    #expect(filtered.get("/a/b/d") == 2)
    #expect(filtered.get("/a/b") == 3)

    let regex = try NSRegularExpression(pattern: ".*[c|d]$")
    let searched = index.search(regex)
    #expect(searched.count == 2)
    #expect(searched["/a/b/c"] == 1)
    #expect(searched["/a/b/d"] == 2)
    #expect(searched["/a/b"] == nil)
}

private func runIteration<Idx: Index>(_ makeIndex: () -> Idx) where Idx.Value == Int {
    var index = makeIndex()
    index.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3]) { _, existing, current in
        (existing ?? 0) + current
    }

    #expect(index.size == 3)

    var collected: [String: Int] = [:]
    index.forEach { path, value in collected[path] = value }
    #expect(collected.count == 3)
    #expect(collected["/a/b/c"] == 1)
    #expect(collected["/a/b/d"] == 2)
    #expect(collected["/a/b"] == 3)
}

private func runConversion<Idx: Index>(_ makeIndex: () -> Idx) where Idx.Value == Int {
    var index = makeIndex()
    let original = ["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3]
    index.putAll(original) { _, existing, current in (existing ?? 0) + current }

    #expect(index.size == 3)
    #expect(index.get("/a/b/c") == 1)
    #expect(index.get("/a/b/d") == 2)
    #expect(index.get("/a/b") == 3)

    #expect(index.toMap() == original)
    let asMap = Dictionary(uniqueKeysWithValues: index.toList())
    #expect(asMap == original)
}

private func runStorageSize<Idx: Index>(_ makeIndex: () -> Idx, expectedKeysSize: Int) where Idx.Value == Int {
    var index = makeIndex()
    let entries = ["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3]
    let expectedValuesSize = MemoryLayout<Int64>.size * 3

    index.putAll(entries) { _, existing, current in (existing ?? 0) + current }
    #expect(index.size == 3)
    #expect(index.estimatedSize { _ in 0 } == expectedKeysSize)
    #expect(index.estimatedSize { _ in MemoryLayout<Int64>.size } == expectedKeysSize + expectedValuesSize)
}

private func runCodable<Idx: Codable & Index>(_ makeIndex: () -> Idx) throws where Idx.Value == Int {
    var original = makeIndex()
    original.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3])

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Idx.self, from: data)
    #expect(original.sameElements(decoded))
}

private func runDescription<Idx: CustomStringConvertible & Index>(_ makeIndex: () -> Idx) where Idx.Value == Int {
    var index = makeIndex()
    index.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3])

    #expect(index.size == 3)
    #expect(index.get("/a/b/c") == 1)
    #expect(index.get("/a/b/d") == 2)
    #expect(index.get("/a/b") == 3)

    #expect(index.description == "{/a/b=3, /a/b/c=1, /a/b/d=2}")
}

private func runEquality<Idx: Hashable & Index>(_ makeIndex: () -> Idx) where Idx.Value == Int {
    var original = makeIndex()
    original.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3])

    #expect(original.size == 3)
    #expect(original.get("/a/b/c") == 1)
    #expect(original.get("/a/b/d") == 2)
    #expect(original.get("/a/b") == 3)

    #expect(original == original)

    var same = makeIndex()
    same.putAll(Dictionary(uniqueKeysWithValues: original.toList()))

    #expect(same.size == 3)
    #expect(same.get("/a/b/c") == 1)
    #expect(same.get("/a/b/d") == 2)
    #expect(same.get("/a/b") == 3)

    #expect(same == same)
    #expect(original == same)
    #expect(original.hashValue == same.hashValue)

    var other1 = makeIndex()
    other1.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/e": 4])

    #expect(other1.size == 3)
    #expect(other1.get("/a/b/c") == 1)
    #expect(other1.get("/a/b/d") == 2)
    #expect(other1.get("/a/e") == 4)

    #expect(other1 == other1)
    #expect(other1 != original)
    #expect(other1 != same)
    #expect(other1.hashValue != original.hashValue)
    #expect(other1.hashValue != same.hashValue)

    var other2 = makeIndex()
    other2.putAll(["/a": 5])

    #expect(other2.size == 1)
    #expect(other2.get("/a") == 5)

    #expect(other2 == other2)
    #expect(other2 != original)
    #expect(other2 != same)
    #expect(other2.hashValue != original.hashValue)
    #expect(other2.hashValue != same.hashValue)

    var other3 = makeIndex()
    other3.putAll(["/x": 5])

    #expect(other3.size == 1)
    #expect(other3.get("/x") == 5)

    #expect(other3 == other3)
    #expect(other3 != original)
    #expect(other3 != same)
    #expect(other3.hashValue != original.hashValue)
    #expect(other3.hashValue != same.hashValue)

    #expect(other2 != other3)
}

private func runSameElements<Idx: Equatable & Index>(_ makeIndex: () -> Idx) where Idx.Value == Int {
    var original = makeIndex()
    original.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3])

    #expect(original.size == 3)
    #expect(original.get("/a/b/c") == 1)
    #expect(original.get("/a/b/d") == 2)
    #expect(original.get("/a/b") == 3)

    #expect(original.sameElements(original))

    var same = makeIndex()
    same.putAll(Dictionary(uniqueKeysWithValues: original.toList()))

    #expect(same.size == 3)
    #expect(same.get("/a/b/c") == 1)
    #expect(same.get("/a/b/d") == 2)
    #expect(same.get("/a/b") == 3)

    #expect(same.sameElements(same))
    #expect(original.sameElements(same))

    var other1 = makeIndex()
    other1.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/e": 4])

    #expect(other1.size == 3)
    #expect(other1.get("/a/b/c") == 1)
    #expect(other1.get("/a/b/d") == 2)
    #expect(other1.get("/a/e") == 4)

    #expect(other1.sameElements(other1))
    #expect(!other1.sameElements(original))
    #expect(!other1.sameElements(same))

    var other2 = makeIndex()
    other2.putAll(["/a": 5])

    #expect(other2.size == 1)
    #expect(other2.get("/a") == 5)

    #expect(other2.sameElements(other2))
    #expect(!other2.sameElements(original))
    #expect(!other2.sameElements(same))

    var other3 = makeIndex()
    other3.putAll(["/x": 5])

    #expect(other3.size == 1)
    #expect(other3.get("/x") == 5)

    #expect(other3.sameElements(other3))
    #expect(!other3.sameElements(original))
    #expect(!other3.sameElements(same))

    #expect(other2 != other3)

    var other4 = makeIndex()
    other4.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/b": 99])
    #expect(!other4.sameElements(original))
    #expect(!other4.sameElements(same))
    #expect(!other3.sameElements(other4))
}

private func runCrossBackendSameElements<Idx: Index, Other: Index>(
    _ makeIndex: () -> Idx,
    _ makeOther: () -> Other
) where Idx.Value == Int, Other.Value == Int {
    var index = makeIndex()
    index.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3])

    var other = makeOther()
    other.putAll(index.toMap())

    #expect(index.sameElements(other))
}

private func runSchemes<Idx: Index>(
    _ makeIndex: () -> Idx,
    aliased makeAliased: () -> Idx
) where Idx.Value == Int {
    var preserve = makeIndex()
    preserve.put("/a/b/c", 1)
    preserve.put("fs:/a/b/c", 2)
    preserve.put("photos:/a/b/c", 3)

    #expect(preserve.size == 3)
    #expect(preserve.get("/a/b/c") == 1)
    #expect(preserve.get("fs:/a/b/c") == 2)
    #expect(preserve.get("photos:/a/b/c") == 3)
    #expect(preserve.get("file:/a/b/c") == nil)
    #expect(preserve.keys == ["/a/b/c", "fs:/a/b/c", "photos:/a/b/c"])

    var isolate = makeIndex()
    isolate.put("photos:/a/b", 1)
    isolate.put("music:/a/b", 2)
    isolate.put("/a/b", 3)

    #expect(isolate.size == 3)

    isolate.put("photos:/a/b", 10) { _, existing, current in (existing ?? 0) + current }
    #expect(isolate.get("photos:/a/b") == 11)
    #expect(isolate.get("music:/a/b") == 2)
    #expect(isolate.get("/a/b") == 3)

    isolate.remove("photos:/a/b")
    #expect(isolate.size == 2)
    #expect(isolate.get("photos:/a/b") == nil)
    #expect(isolate.get("music:/a/b") == 2)
    #expect(isolate.get("/a/b") == 3)

    var roots = makeIndex()
    roots.put("photos:/", 1)
    roots.put("/", 2)

    #expect(roots.size == 2)
    #expect(roots.get("photos:/") == 1)
    #expect(roots.get("/") == 2)
    #expect(roots.keys == ["photos:/", "/"])

    var colons = makeIndex()
    colons.put("/a/b:c/d", 1)
    colons.put("photos:/a/b:c", 2)

    #expect(colons.size == 2)
    #expect(colons.get("/a/b:c/d") == 1)
    #expect(colons.get("photos:/a/b:c") == 2)
    #expect(colons.keys == ["/a/b:c/d", "photos:/a/b:c"])

    var prefixes = makeIndex()
    prefixes.put("ab:/x", 1)
    #expect(prefixes.get("ab:/x") == 1)
    #expect(prefixes.keys == ["ab:/x"])

    prefixes.put("c:/x", 2)
    prefixes.put("12:/x", 3)
    #expect(prefixes.size == 3)
    #expect(prefixes.get("c:/x") == 2)
    #expect(prefixes.get("12:/x") == 3)
    #expect(prefixes.contains("c:/x"))

    var deep = makeIndex()
    deep.put("photos:/a/b/c/d/e", 1)
    deep.put("photos:/a/b", 2)

    #expect(deep.size == 2)
    #expect(deep.get("photos:/a/b/c/d/e") == 1)
    #expect(deep.get("photos:/a/b") == 2)
    #expect(deep.contains("photos:/a/b/c/d/e"))
    #expect(!deep.contains("photos:/a/b/c"))

    var aliased = makeAliased()
    aliased.put("fs:/a/b/c", 1)
    #expect(aliased.size == 1)
    #expect(aliased.get("/a/b/c") == 1)
    #expect(aliased.get("file:/a/b/c") == 1)
    #expect(aliased.get("FS:/a/b/c") == 1)

    aliased.put("file:/a/b/c", 5) { _, existing, current in (existing ?? 0) + current }
    #expect(aliased.get("/a/b/c") == 6)
    #expect(aliased.size == 1)

    aliased.put("photos:/a/b/c", 2)
    #expect(aliased.size == 2)
    #expect(aliased.get("photos:/a/b/c") == 2)
    #expect(aliased.keys == ["/a/b/c", "photos:/a/b/c"])

    let paths = [
        "/", "/a", "/a/b/c", "/a/b/c/d/e/f/g/h/i/j",
        "C:\\Users\\foo", "C:/Users/foo", "C:foo", "\\\\server\\share\\file", "\\\\?\\C:\\very\\long",
        "photos:", "photos:/", "photos:/a", "photos:/a/b/c", "music:/x/y", "x-y.z+1:/a/b",
        "fs:C:\\Users\\foo", "file:\\a\\b\\c", "photos:C:/x/y", "fs:\\\\server\\share\\file",
        "", "//", "////", "///a///b///", "photos://///", "photos://a//b", "C://\\/\\", ":/a", "://x", "/a/b/",
        "/a b/c d", "/а/电/é", "/📁/x", "/a-b_c.d/e@f/g&h", "/a%20b/c(1)", "photos:/a b/π"
    ]

    for path in paths {
        var index = makeIndex()

        index.put(path, 1)
        #expect(index.get(path) == 1, "path=[\(path)]")
        #expect(index.contains(path), "path=[\(path)]")
        #expect(index.size == 1, "path=[\(path)]")

        index.remove(path)
        #expect(index.get(path) == nil, "path=[\(path)]")
        #expect(!index.contains(path), "path=[\(path)]")
        #expect(index.size == 0, "path=[\(path)]")
    }
}

private func runSchemeRoundTrip<Idx: Codable & Index>(_ makeIndex: () -> Idx) throws where Idx.Value == Int {
    var original = makeIndex()
    original.putAll(["photos:/a/b/c": 1, "music:/a/b/c": 2, "/a/b/c": 3])

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Idx.self, from: data)

    #expect(decoded.get("photos:/a/b/c") == 1)
    #expect(decoded.get("music:/a/b/c") == 2)
    #expect(decoded.get("/a/b/c") == 3)
    #expect(decoded.toMap() == original.toMap())
}

@Suite("MapIndex")
struct MapIndexIndexSpec {
    @Test func basicOps() { runBasicOps { MapIndex<Int>() } }
    @Test func keys() { runKeys { MapIndex<Int>() } }
    @Test func subscriptAccess() { runSubscript { MapIndex<Int>() } }
    @Test func filterAndSearch() throws { try runFilterAndSearch { MapIndex<Int>() } }
    @Test func iteration() { runIteration { MapIndex<Int>() } }
    @Test func conversion() { runConversion { MapIndex<Int>() } }
    @Test func storageSize() {
        let expectedKeysSize = ["/a/b/c", "/a/b/d", "/a/b"].map { $0.utf8.count }.reduce(0, +)
        runStorageSize({ MapIndex<Int>() }, expectedKeysSize: expectedKeysSize)
    }
    @Test func codable() throws { try runCodable { MapIndex<Int>() } }
    @Test func description() { runDescription { MapIndex<Int>() } }
    @Test func equality() { runEquality { MapIndex<Int>() } }
    @Test func sameElements() { runSameElements { MapIndex<Int>() } }
    @Test func crossBackendSameElements() {
        runCrossBackendSameElements({ MapIndex<Int>() }, { TrieIndex<Int>() })
    }
    @Test func schemes() {
        runSchemes({ MapIndex<Int>() }, aliased: { MapIndex<Int>(schemeMapper: Schemes.aliases("fs", "file")) })
    }
    @Test func schemeRoundTrip() throws { try runSchemeRoundTrip { MapIndex<Int>() } }

    @Test func transformation() {
        var index = MapIndex<Int>()
        index.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3]) { _, existing, current in
            (existing ?? 0) + current
        }

        #expect(index.size == 3)
        #expect(index.get("/a/b/c") == 1)
        #expect(index.get("/a/b/d") == 2)
        #expect(index.get("/a/b") == 3)

        // collect
        let collected: [(String, String)] = index.collect { path, value in
            path == "/a/b/d" ? nil : (path, "a_\(value)")
        }
        let collectedMap = Dictionary(uniqueKeysWithValues: collected)
        #expect(collectedMap.count == 2)
        #expect(collectedMap["/a/b/c"] == "a_1")
        #expect(collectedMap["/a/b"] == "a_3")

        // mapValues
        let mapped = index.mapValues { _, value in "b_\(value)" }
        #expect(mapped.size == 3)
        #expect(mapped.get("/a/b/c") == "b_1")
        #expect(mapped.get("/a/b/d") == "b_2")
        #expect(mapped.get("/a/b") == "b_3")

        // compactMapValues
        let mappedNotNull = index.compactMapValues { path, value in
            path == "/a/b/d" ? nil : "b_\(value)"
        }
        #expect(mappedNotNull.size == 2)
        #expect(mappedNotNull.get("/a/b/c") == "b_1")
        #expect(mappedNotNull.get("/a/b/d") == nil)
        #expect(mappedNotNull.get("/a/b") == "b_3")

        // replaceAll
        index.replaceAll { _, value in value * 2 }
        #expect(index.size == 3)
        #expect(index.get("/a/b/c") == 2)
        #expect(index.get("/a/b/d") == 4)
        #expect(index.get("/a/b") == 6)
    }

    @Test func separator() { #expect(Path.separator == "/") }
}

@Suite("TrieIndex")
struct TrieIndexIndexSpec {
    @Test func basicOps() { runBasicOps { TrieIndex<Int>() } }
    @Test func keys() { runKeys { TrieIndex<Int>() } }
    @Test func subscriptAccess() { runSubscript { TrieIndex<Int>() } }
    @Test func filterAndSearch() throws { try runFilterAndSearch { TrieIndex<Int>() } }
    @Test func iteration() { runIteration { TrieIndex<Int>() } }
    @Test func conversion() { runConversion { TrieIndex<Int>() } }
    @Test func storageSize() {
        runStorageSize({ TrieIndex<Int>() }, expectedKeysSize: 4)
    }
    @Test func codable() throws { try runCodable { TrieIndex<Int>() } }
    @Test func description() { runDescription { TrieIndex<Int>() } }
    @Test func equality() { runEquality { TrieIndex<Int>() } }
    @Test func sameElements() { runSameElements { TrieIndex<Int>() } }
    @Test func crossBackendSameElements() {
        runCrossBackendSameElements({ TrieIndex<Int>() }, { MapIndex<Int>() })
    }
    @Test func schemes() {
        runSchemes({ TrieIndex<Int>() }, aliased: { TrieIndex<Int>(schemeMapper: Schemes.aliases("fs", "file")) })
    }
    @Test func schemeRoundTrip() throws { try runSchemeRoundTrip { TrieIndex<Int>() } }

    @Test func transformation() {
        var index = TrieIndex<Int>()
        index.putAll(["/a/b/c": 1, "/a/b/d": 2, "/a/b": 3]) { _, existing, current in
            (existing ?? 0) + current
        }

        #expect(index.size == 3)
        #expect(index.get("/a/b/c") == 1)
        #expect(index.get("/a/b/d") == 2)
        #expect(index.get("/a/b") == 3)

        // collect
        let collected: [(String, String)] = index.collect { path, value in
            path == "/a/b/d" ? nil : (path, "a_\(value)")
        }
        let collectedMap = Dictionary(uniqueKeysWithValues: collected)
        #expect(collectedMap.count == 2)
        #expect(collectedMap["/a/b/c"] == "a_1")
        #expect(collectedMap["/a/b"] == "a_3")

        // mapValues
        let mapped = index.mapValues { _, value in "b_\(value)" }
        #expect(mapped.size == 3)
        #expect(mapped.get("/a/b/c") == "b_1")
        #expect(mapped.get("/a/b/d") == "b_2")
        #expect(mapped.get("/a/b") == "b_3")

        // compactMapValues
        let mappedNotNull = index.compactMapValues { path, value in
            path == "/a/b/d" ? nil : "b_\(value)"
        }
        #expect(mappedNotNull.size == 2)
        #expect(mappedNotNull.get("/a/b/c") == "b_1")
        #expect(mappedNotNull.get("/a/b/d") == nil)
        #expect(mappedNotNull.get("/a/b") == "b_3")

        // replaceAll
        index.replaceAll { _, value in value * 2 }
        #expect(index.size == 3)
        #expect(index.get("/a/b/c") == 2)
        #expect(index.get("/a/b/d") == 4)
        #expect(index.get("/a/b") == 6)
    }
}
