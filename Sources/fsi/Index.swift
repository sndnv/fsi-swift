import Foundation

/// An object for storing and retrieving arbitrary values related to file-system paths.
///
/// Conformers are `Sendable`, so an index can be passed across actor boundaries provided its `Value` is also `Sendable`.
///
/// - SeeAlso: ``MapIndex``, ``TrieIndex``
public protocol Index<Value>: Sendable {
    associatedtype Value: Sendable

    /// Returns the number of values in this index.
    var size: Int { get }

    /// Returns a set of all paths in this index.
    var keys: Set<String> { get }

    /// Returns the value associated with the provided `path`, or `nil` if no value is found.
    ///
    /// - Parameter path: path to retrieve.
    func get(_ path: String) -> Value?

    /// Checks if the provided `path` has a value in this index.
    func contains(_ path: String) -> Bool

    /// Returns the value associated with the provided `path`, or `nil` if no value is found.
    subscript(path: String) -> Value? { get }

    /// Inserts the provided `value` with the associated `path`.
    ///
    /// - Parameters:
    ///   - path: path to insert.
    ///   - value: value to insert for the provided path.
    mutating func put(_ path: String, _ value: Value)

    /// Inserts the provided `value` with the associated `path` by using `f` to determine the final value to be inserted.
    ///
    /// Example:
    /// ```swift
    /// var index = MapIndex<Int>()
    /// index.put("/a/b/c", 1) { path, existing, current in
    ///     if let existing = existing {
    ///         return existing + current
    ///     } else {
    ///         return current
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - path: path to insert.
    ///   - value: value to insert for the provided path.
    ///   - f: value accumulation function.
    mutating func put(_ path: String, _ value: Value, _ f: (String, Value?, Value) -> Value)

    /// Inserts all provided `entries`.
    ///
    /// - Note: If an entry is already in this index, its value will be replaced with the newly provided one.
    ///
    /// - Parameter entries: entries to insert.
    mutating func putAll(_ entries: [String: Value])

    /// Inserts all provided `entries` using the result of the specified function `f`.
    ///
    /// Example:
    /// ```swift
    /// var index = MapIndex<Int>()
    /// let entries: [String: Int] = [:]
    /// index.putAll(entries) { entryKey, existing, entryValue in
    ///     if let existing = existing {
    ///         return existing + entryValue
    ///     } else {
    ///         return entryValue
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - entries: entries to insert.
    ///   - f: value accumulation function.
    mutating func putAll<S>(_ entries: [String: S], _ f: (String, Value?, S) -> Value)

    /// Inserts all provided `paths` using the result of the specified function `f`.
    ///
    /// Example:
    /// ```swift
    /// var index = MapIndex<Int>()
    /// let paths: [String] = []
    /// index.putAll(paths) { entryKey, existing in
    ///     if let existing = existing {
    ///         return existing + 1
    ///     } else {
    ///         return 1
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - paths: paths to insert.
    ///   - f: value accumulation function.
    mutating func putAll(_ paths: [String], _ f: (String, Value?) -> Value)

    /// Removes the value associated with the provided `path` from this index, if a value exists.
    ///
    /// - Parameter path: path to remove.
    mutating func remove(_ path: String)

    /// Removes all elements from this index.
    mutating func clear()

    /// Calls the provided function `f` for each key/value pair in this index.
    ///
    /// Example:
    /// ```swift
    /// var index = MapIndex<Int>()
    /// var count = 0
    /// index.forEach { path, existing in
    ///     if existing > 9000 {
    ///         count += 1
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter f: action to perform for each entry.
    func forEach(_ f: (String, Value) -> Void)

    /// Creates a new array by applying the specified function `f` to all elements of
    /// this index and keeping only the non-nil values provided by the function.
    ///
    /// - Parameter f: collection function.
    func collect<S>(_ f: (String, Value) -> S?) -> [S]

    /// Returns a new index containing only entries matched by the provided function `f`.
    ///
    /// Example:
    /// ```swift
    /// var index = MapIndex<Int>()
    /// let filtered = index.filter { path, existing in
    ///     existing > 9000
    /// }
    /// ```
    ///
    /// - Parameter f: predicate.
    func filter(_ f: (String, Value) -> Bool) -> Self

    /// Returns a dictionary containing only entries with keys that fully match the provided regular expression `expr`.
    ///
    /// Example:
    /// ```swift
    /// var index = MapIndex<Int>()
    /// let regex = try NSRegularExpression(pattern: "^/a/b/.*")
    /// let result: [String: Int] = index.search(regex)
    /// ```
    ///
    /// - Parameter expr: regular expression.
    func search(_ expr: NSRegularExpression) -> [String: Value]

    /// Replaces the value of each entry with the result of applying the specified function `f` to that entry.
    ///
    /// - Parameter f: function to apply to each entry.
    mutating func replaceAll(_ f: (String, Value) -> Value)

    /// Returns a dictionary containing all key/value pairs from this index.
    func toMap() -> [String: Value]

    /// Returns an array containing all key/value pairs from this index.
    func toList() -> [(String, Value)]

    /// Returns the current storage size estimation for all keys and values, in bytes, using
    /// the provided `sizeOf` function to calculate the size of each value in the index.
    ///
    /// Keys are measured by their UTF-8 byte length.
    ///
    /// - Note: This operation may be very expensive, as it needs to iterate over all entries in the index.
    ///
    /// - Parameter sizeOf: value size calculation function.
    func estimatedSize(_ sizeOf: (Value) -> Int) -> Int
}

extension Index where Value: Equatable {
    /// Checks if this and the provided `other` index both contain the same elements.
    ///
    /// - Note: Care should be taken when comparing indices of different types
    ///         (Trie vs Map, for example), as intermediate collections may be created and
    ///         multiple iterations over the indices may be necessary.
    ///
    /// - Parameter other: index to compare.
    public func sameElements<Other: Index>(_ other: Other) -> Bool where Other.Value == Value {
        toMap() == other.toMap()
    }
}

/// Common file-system path constants.
public enum Path {
    /// The path component separator used by the library.
    public static let separator: String = "/"
}
