import Foundation

/// An ``Index`` implementation that uses a prefix tree (trie) for its underlying storage.
///
/// - Note: This implementation is not thread-safe. For shared mutable access across actors, wrap an index
///         in an `actor`. `TrieIndex` is a value type with copy-on-write semantics: copying the struct is
///         cheap and copies are isolated; mutations do not affect other copies.
///
/// Example:
/// ```swift
/// var index = TrieIndex<Int>()
/// let path = "/a/b/c"
///
/// // basic operations
/// index.size       // 0
/// index.get(path)  // nil
///
/// index.put(path, 42) // adds a new entry
/// index.size       // 1
/// index.get(path)  // 42
///
/// index.remove(path) // removes an existing entry
/// index.size       // 0
/// index.get(path)  // nil
///
/// // encoding and decoding
/// let data = try JSONEncoder().encode(index)
/// let decoded = try JSONDecoder().decode(TrieIndex<Int>.self, from: data)
/// ```
///
/// - Note: Paths are treated as absolute and normalized - redundant and trailing separators are collapsed
///         and a leading separator is always present, so `a/b/c`, `/a//b/c` and `/a/b/c/` all refer to `/a/b/c`.
///
/// - SeeAlso: ``MapIndex``
public struct TrieIndex<Value: Sendable>: @unchecked Sendable, Index {
    private var root: IndexNode<Value>
    private var actualSize: Int
    private let schemeMapper: SchemeMapper?

    /// Creates an empty `TrieIndex` that preserves path schemes.
    public init() {
        self.init(carrying: nil)
    }

    /// Creates an empty `TrieIndex` using the provided `schemeMapper` (see ``Schemes``).
    ///
    /// - Parameter schemeMapper: function for canonicalizing path schemes.
    public init(schemeMapper: @escaping SchemeMapper) {
        self.init(carrying: schemeMapper)
    }

    /// Creates a `TrieIndex` populated with the provided `entries`, preserving path schemes.
    ///
    /// - Parameter entries: initial path/value pairs.
    public init(_ entries: [String: Value]) {
        self.init(carrying: nil)
        self.putAll(entries)
    }

    /// Creates a `TrieIndex` populated with the provided `entries` and using the provided `schemeMapper`
    /// (see ``Schemes``).
    ///
    /// - Parameters:
    ///   - entries: initial path/value pairs.
    ///   - schemeMapper: function for canonicalizing path schemes.
    public init(_ entries: [String: Value], schemeMapper: @escaping SchemeMapper) {
        self.init(carrying: schemeMapper)
        self.putAll(entries)
    }

    private init(carrying schemeMapper: SchemeMapper?) {
        self.root = IndexNode<Value>()
        self.actualSize = 0
        self.schemeMapper = schemeMapper
    }

    public var size: Int { actualSize }

    public var keys: Set<String> {
        var result: Set<String> = []
        forEach { path, _ in result.insert(path) }
        return result
    }

    public func get(_ path: String) -> Value? {
        getNode(parts(path))?.value
    }

    public func contains(_ path: String) -> Bool {
        getNode(parts(path))?.value != nil
    }

    public subscript(path: String) -> Value? {
        self.get(path)
    }

    public mutating func put(_ path: String, _ value: Value) {
        put(path, value) { _, _, newValue in newValue }
    }

    public mutating func put(_ path: String, _ value: Value, _ f: (String, Value?, Value) -> Value) {
        ensureUniqueRoot()
        let node = getOrCreateNode(parts(path))
        if node.value == nil {
            actualSize += 1
        }
        node.value = f(path, node.value, value)
    }

    public mutating func putAll(_ entries: [String: Value]) {
        putAll(entries) { _, _, value in value }
    }

    public mutating func putAll<S>(_ entries: [String: S], _ f: (String, Value?, S) -> Value) {
        ensureUniqueRoot()
        for (path, value) in entries {
            let node = getOrCreateNode(parts(path))
            if node.value == nil {
                actualSize += 1
            }
            node.value = f(path, node.value, value)
        }
    }

    public mutating func putAll(_ paths: [String], _ f: (String, Value?) -> Value) {
        ensureUniqueRoot()
        for path in paths {
            let node = getOrCreateNode(parts(path))
            if node.value == nil {
                actualSize += 1
            }
            node.value = f(path, node.value)
        }
    }

    public mutating func remove(_ path: String) {
        ensureUniqueRoot()
        removeNode(parts(path))
    }

    public mutating func clear() {
        root = IndexNode<Value>()
        actualSize = 0
    }

    public func forEach(_ f: (String, Value) -> Void) {
        forEachNode { path, node in
            if let value = node.value {
                f(rebuild(path), value)
            }
        }
    }

    public func collect<S>(_ f: (String, Value) -> S?) -> [S] {
        var result: [S] = []
        forEachNode { path, node in
            if let value = node.value, let collected = f(rebuild(path), value) {
                result.append(collected)
            }
        }
        return result
    }

    public func filter(_ f: (String, Value) -> Bool) -> TrieIndex<Value> {
        compactMapValues { path, value in f(path, value) ? value : nil }
    }

    public func search(_ expr: NSRegularExpression) -> [String: Value] {
        var result: [String: Value] = [:]
        forEachNode { path, node in
            guard let value = node.value else { return }
            let actualPath = rebuild(path)
            let range = NSRange(actualPath.startIndex..<actualPath.endIndex, in: actualPath)
            if let match = expr.firstMatch(in: actualPath, options: [], range: range), match.range == range {
                result[actualPath] = value
            }
        }
        return result
    }

    /// Returns a new index with entries having the keys of this index and the values being the results of
    /// applying the provided function `f` to each entry in this index.
    ///
    /// Example:
    /// ```swift
    /// var original = TrieIndex<Int>()
    /// let mapped: TrieIndex<String> = original.mapValues { path, existing in
    ///     String(existing)
    /// }
    /// ```
    ///
    /// - Parameter f: mapping function.
    public func mapValues<S>(_ f: (String, Value) -> S) -> TrieIndex<S> {
        compactMapValues(f)
    }

    /// Returns a new index containing only non-nil results of applying the provided function `f` to each
    /// entry in this index.
    ///
    /// Example:
    /// ```swift
    /// var original = TrieIndex<Int>()
    /// let mapped: TrieIndex<String> = original.compactMapValues { path, existing in
    ///     path.hasPrefix("/a/b") ? String(existing) : nil
    /// }
    /// ```
    ///
    /// - Parameter f: mapping function.
    public func compactMapValues<S>(_ f: (String, Value) -> S?) -> TrieIndex<S> {
        var result = TrieIndex<S>(carrying: schemeMapper)
        forEach { path, value in
            if let mapped = f(path, value) {
                result.put(path, mapped)
            }
        }
        return result
    }

    public mutating func replaceAll(_ f: (String, Value) -> Value) {
        ensureUniqueRoot()
        forEachNode { path, node in
            if let value = node.value {
                node.value = f(rebuild(path), value)
            }
        }
    }

    public func toMap() -> [String: Value] {
        var result: [String: Value] = [:]
        forEach { path, value in result[path] = value }
        return result
    }

    public func toList() -> [(String, Value)] {
        var result: [(String, Value)] = []
        forEach { path, value in result.append((path, value)) }
        return result
    }

    public func estimatedSize(_ sizeOf: (Value) -> Int) -> Int {
        var estimate = 0
        var remaining: [IndexNode<Value>] = [root]
        while let current = remaining.popLast() {
            if let value = current.value {
                estimate += sizeOf(value)
            }
            for (part, child) in current.children {
                estimate += part.utf8.count
                remaining.append(child)
            }
        }
        return estimate
    }
}

extension TrieIndex {
    private mutating func ensureUniqueRoot() {
        if !isKnownUniquelyReferenced(&root) {
            root = root.deepCopy()
        }
    }

    private func parts(_ path: String) -> [String] {
        let (rawScheme, rest) = Schemes.extract(path)
        let scheme: String
        if let schemeMapper {
            scheme = schemeMapper(rawScheme) ?? ""
        } else {
            scheme = rawScheme ?? ""
        }
        let segments = rest.components(separatedBy: Path.separator).filter { !$0.isEmpty }
        return [scheme] + segments
    }

    private func rebuild(_ parts: [String]) -> String {
        guard let scheme = parts.first else { return Path.separator }
        let body = Path.separator + parts.dropFirst().joined(separator: Path.separator)
        return scheme.isEmpty ? body : "\(scheme)\(Schemes.Delimiter)\(body)"
    }

    private func getNode(_ path: [String]) -> IndexNode<Value>? {
        var last = root
        for part in path {
            guard let next = last.children[part] else { return nil }
            last = next
        }
        return last
    }

    private func getOrCreateNode(_ path: [String]) -> IndexNode<Value> {
        var last = root
        for part in path {
            if let existing = last.children[part] {
                last = existing
            } else {
                let new = IndexNode<Value>()
                last.children[part] = new
                last = new
            }
        }
        return last
    }

    private mutating func removeNode(_ path: [String]) {
        var last = root
        var pathNodes: [(IndexNode<Value>, String)] = []

        for part in path {
            guard let child = last.children[part] else { return }
            pathNodes.append((last, part))
            last = child
        }

        var removed = false

        if last.children.isEmpty {
            while let (parent, part) = pathNodes.popLast() {
                parent.children.removeValue(forKey: part)
                removed = true
                if parent.value != nil || !parent.children.isEmpty {
                    break
                }
            }
        } else if last.value != nil {
            last.value = nil
            removed = true
        }

        if removed {
            actualSize -= 1
        }
    }

    private func forEachNode(_ f: ([String], IndexNode<Value>) -> Void) {
        var remaining: [([String], IndexNode<Value>)] = [([], root)]
        var index = 0
        while index < remaining.count {
            let (currentPath, currentNode) = remaining[index]
            index += 1
            f(currentPath, currentNode)
            for (childPart, childNode) in currentNode.children {
                remaining.append((currentPath + [childPart], childNode))
            }
        }
    }
}

extension TrieIndex: Codable where Value: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let entries = try container.decode([String: Value].self)
        self.init(carrying: nil)
        self.putAll(entries)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(toMap())
    }
}

extension TrieIndex: Equatable where Value: Equatable {
    public static func == (lhs: TrieIndex<Value>, rhs: TrieIndex<Value>) -> Bool {
        lhs.actualSize == rhs.actualSize && lhs.toMap() == rhs.toMap()
    }
}

extension TrieIndex: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(toMap())
    }
}

extension TrieIndex: CustomStringConvertible {
    public var description: String {
        let entries = toMap()
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        return "{\(entries)}"
    }
}

private final class IndexNode<Value> {
    var children: [String: IndexNode<Value>]
    var value: Value?

    init(children: [String: IndexNode<Value>] = [:], value: Value? = nil) {
        self.children = children
        self.value = value
    }

    func deepCopy() -> IndexNode<Value> {
        let copy = IndexNode<Value>(value: value)
        for (part, child) in children {
            copy.children[part] = child.deepCopy()
        }
        return copy
    }
}
