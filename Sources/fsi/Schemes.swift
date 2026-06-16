import Foundation

/// A function for canonicalizing the scheme component of a path.
///
/// It receives the raw scheme parsed from a path (or `nil` if the path has no scheme) and returns
/// the scheme to actually store the path under (or `nil`/empty to store it as a plain, schemeless path).
///
/// The same mapper is applied by every ``Index`` implementation, so that indices configured with the same
/// mapper agree on path identity regardless of their backend.
///
/// - SeeAlso: ``Schemes``
public typealias SchemeMapper = @Sendable (String?) -> String?

/// Helpers for parsing and canonicalizing path schemes.
///
/// A scheme-qualified path has the form `scheme:rest`, for example `photos:/a/b/c`. The scheme is everything
/// before the first ``Delimiter`` and must start with a letter and be at least two characters long, so that
/// single-character prefixes (`c:/x`), numeric prefixes (`12:30`) and absolute local paths (`/a/b`) are *not*
/// treated as schemes. Scheme detection is independent of the path separator, so every ``Index`` backend
/// recognizes schemes identically.
///
/// Schemes are preserved by default; a custom ``SchemeMapper`` can be provided to canonicalize them
/// (for example, to treat `fs` and `file` as the local/schemeless filesystem - see ``aliases(_:)``).
public enum Schemes {
    /// The character separating a scheme from the rest of a path.
    public static let Delimiter: String = ":"

    /// A ``SchemeMapper`` that preserves every scheme (the default behavior).
    public static let Identity: SchemeMapper = { $0 }

    /// A ``SchemeMapper`` that lower-cases schemes.
    public static let Lowercase: SchemeMapper = { $0?.lowercased() }

    /// A ``SchemeMapper`` that upper-cases schemes.
    public static let Uppercase: SchemeMapper = { $0?.uppercased() }

    /// Creates a ``SchemeMapper`` that treats the provided `names` (case-insensitively) as the local/schemeless
    /// filesystem, mapping them to `nil` so that, for example, `fs:/a/b/c` and `/a/b/c` become the same path.
    ///
    /// - Parameter names: scheme names to treat as local.
    public static func aliases(_ names: String...) -> SchemeMapper {
        let local = Set(names.map { $0.lowercased() })
        return { scheme in
            if let scheme, local.contains(scheme.lowercased()) {
                return nil
            }
            return scheme
        }
    }

    // swiftlint:disable:next force_try
    private static let pattern = try! NSRegularExpression(pattern: "^([A-Za-z][A-Za-z0-9+.-]+)\(Delimiter)")

    /// Splits the provided `path` into its scheme (or `nil` if it has none) and the remainder of the
    /// path (everything after the scheme's ``Delimiter``, or the whole `path` when there is no scheme).
    public static func extract(_ path: String) -> (scheme: String?, rest: String) {
        let range = NSRange(path.startIndex..<path.endIndex, in: path)
        guard let match = pattern.firstMatch(in: path, options: [], range: range),
              let schemeRange = Range(match.range(at: 1), in: path),
              let matchRange = Range(match.range, in: path) else {
            return (nil, path)
        }
        return (String(path[schemeRange]), String(path[matchRange.upperBound...]))
    }
}
