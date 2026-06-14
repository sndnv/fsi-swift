import Foundation

/// An ``Index`` implementation that uses a Swift `Dictionary` for its underlying storage.
///
/// Example:
/// ```swift
/// var index = MapIndex<Int>()
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
/// let decoded = try JSONDecoder().decode(MapIndex<Int>.self, from: data)
/// ```
///
/// - Note: Keys are stored unchanged - unlike ``TrieIndex``, a `MapIndex` has no separator and does not
///         normalize paths, so `a/b/c` and `/a/b/c` are distinct keys. A ``SchemeMapper`` only canonicalizes
///         the scheme component; it does not normalize the rest of the path.
///
/// - SeeAlso: ``TrieIndex``
public struct MapIndex<Value: Sendable>: Index {
    private var underlying: [String: Value]
    private let schemeMapper: SchemeMapper?

    /// Creates an empty `MapIndex` that preserves path schemes.
    public init() {
        self.init([:], carrying: nil)
    }

    /// Creates an empty `MapIndex` using the provided `schemeMapper` (see ``Schemes``).
    ///
    /// - Parameter schemeMapper: function for canonicalizing path schemes.
    public init(schemeMapper: @escaping SchemeMapper) {
        self.init([:], carrying: schemeMapper)
    }

    /// Creates a `MapIndex` populated with the provided `entries`, preserving path schemes.
    ///
    /// - Parameter entries: initial path/value pairs.
    public init(_ entries: [String: Value]) {
        self.init(entries, carrying: nil)
    }

    /// Creates a `MapIndex` populated with the provided `entries` and using the provided `schemeMapper`
    /// (see ``Schemes``).
    ///
    /// - Note: The provided `entries` are stored as-is; the `schemeMapper` is applied to keys of subsequent
    ///         operations only.
    ///
    /// - Parameters:
    ///   - entries: initial path/value pairs.
    ///   - schemeMapper: function for canonicalizing path schemes.
    public init(_ entries: [String: Value], schemeMapper: @escaping SchemeMapper) {
        self.init(entries, carrying: schemeMapper)
    }

    private init(_ entries: [String: Value], carrying schemeMapper: SchemeMapper?) {
        self.underlying = entries
        self.schemeMapper = schemeMapper
    }

    private func normalize(_ path: String) -> String {
        guard let schemeMapper else { return path }
        let (rawScheme, rest) = Schemes.split(path)
        let scheme = schemeMapper(rawScheme)
        if let scheme, !scheme.isEmpty {
            return "\(scheme)\(Schemes.Delimiter)\(rest)"
        }
        return rest
    }

    public var size: Int { underlying.count }

    public var keys: Set<String> { Set(underlying.keys) }

    public func get(_ path: String) -> Value? {
        underlying[normalize(path)]
    }

    public func contains(_ path: String) -> Bool {
        underlying[normalize(path)] != nil
    }

    public subscript(path: String) -> Value? {
        underlying[normalize(path)]
    }

    public mutating func put(_ path: String, _ value: Value) {
        underlying[normalize(path)] = value
    }

    public mutating func put(_ path: String, _ value: Value, _ f: (String, Value?, Value) -> Value) {
        let key = normalize(path)
        underlying[key] = f(path, underlying[key], value)
    }

    public mutating func putAll(_ entries: [String: Value]) {
        for (path, value) in entries {
            underlying[normalize(path)] = value
        }
    }

    public mutating func putAll<S>(_ entries: [String: S], _ f: (String, Value?, S) -> Value) {
        for (path, value) in entries {
            let key = normalize(path)
            underlying[key] = f(path, underlying[key], value)
        }
    }

    public mutating func putAll(_ paths: [String], _ f: (String, Value?) -> Value) {
        for path in paths {
            let key = normalize(path)
            underlying[key] = f(path, underlying[key])
        }
    }

    public mutating func remove(_ path: String) {
        underlying.removeValue(forKey: normalize(path))
    }

    public mutating func clear() {
        underlying.removeAll()
    }

    public func forEach(_ f: (String, Value) -> Void) {
        for (path, value) in underlying {
            f(path, value)
        }
    }

    public func collect<S>(_ f: (String, Value) -> S?) -> [S] {
        underlying.compactMap { f($0.key, $0.value) }
    }

    public func filter(_ f: (String, Value) -> Bool) -> MapIndex<Value> {
        var result: [String: Value] = [:]
        for (path, value) in underlying where f(path, value) {
            result[path] = value
        }
        return MapIndex<Value>(result, carrying: schemeMapper)
    }

    public func search(_ expr: NSRegularExpression) -> [String: Value] {
        var result: [String: Value] = [:]
        for (path, value) in underlying {
            let range = NSRange(path.startIndex..<path.endIndex, in: path)
            if let match = expr.firstMatch(in: path, options: [], range: range), match.range == range {
                result[path] = value
            }
        }
        return result
    }

    /// Returns a new index with entries having the keys of this index and the values being the results of
    /// applying the provided function `f` to each entry in this index.
    ///
    /// Example:
    /// ```swift
    /// var original = MapIndex<Int>()
    /// let mapped: MapIndex<String> = original.mapValues { path, existing in
    ///     String(existing)
    /// }
    /// ```
    ///
    /// - Parameter f: mapping function.
    public func mapValues<S>(_ f: (String, Value) -> S) -> MapIndex<S> {
        var result: [String: S] = [:]
        for (path, value) in underlying {
            result[path] = f(path, value)
        }
        return MapIndex<S>(result, carrying: schemeMapper)
    }

    /// Returns a new index containing only non-nil results of applying the provided function `f` to each
    /// entry in this index.
    ///
    /// Example:
    /// ```swift
    /// var original = MapIndex<Int>()
    /// let mapped: MapIndex<String> = original.compactMapValues { path, existing in
    ///     path.hasPrefix("/a/b") ? String(existing) : nil
    /// }
    /// ```
    ///
    /// - Parameter f: mapping function.
    public func compactMapValues<S>(_ f: (String, Value) -> S?) -> MapIndex<S> {
        var result: [String: S] = [:]
        for (path, value) in underlying {
            if let mapped = f(path, value) {
                result[path] = mapped
            }
        }
        return MapIndex<S>(result, carrying: schemeMapper)
    }

    public mutating func replaceAll(_ f: (String, Value) -> Value) {
        for (path, value) in underlying {
            underlying[path] = f(path, value)
        }
    }

    public func toMap() -> [String: Value] {
        underlying
    }

    public func toList() -> [(String, Value)] {
        underlying.map { ($0.key, $0.value) }
    }

    public func estimatedSize(_ sizeOf: (Value) -> Int) -> Int {
        underlying.reduce(0) { acc, entry in
            acc + entry.key.utf8.count + sizeOf(entry.value)
        }
    }
}

/// JSON-compatible encoding/decoding for `MapIndex` when its `Value` is `Codable`.
///
/// The encoded form is a single JSON object mapping each path to its value.
extension MapIndex: Codable where Value: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.underlying = try container.decode([String: Value].self)
        self.schemeMapper = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(underlying)
    }
}

extension MapIndex: Equatable where Value: Equatable {
    public static func == (lhs: MapIndex<Value>, rhs: MapIndex<Value>) -> Bool {
        lhs.underlying == rhs.underlying
    }
}

extension MapIndex: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(underlying)
    }
}

extension MapIndex: CustomStringConvertible {
    public var description: String {
        let entries = underlying
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        return "{\(entries)}"
    }
}
