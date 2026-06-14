# fsi - File System Index

<img src="./assets/fsi.logo.svg" width="64px" alt="fsi Logo" align="right"/>

`fsi` is a Swift library providing simple data structures for efficiently associating information with file system paths.

It is a Swift port of [`fsi`](https://github.com/sndnv/fsi) (originally written in Kotlin).

## Setup

Add the package as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/sndnv/fsi-swift.git", from: "1.0.0")
]
```

then add `fsi` to the target dependencies that need it:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "fsi", package: "fsi-swift")
    ]
)
```

## Components

There are currently two implementations available:

* [`MapIndex`](./Sources/fsi/Backends/MapIndex.swift) - based on a dictionary
* [`TrieIndex`](./Sources/fsi/Backends/TrieIndex.swift) - based on a prefix tree (trie)

> The `SharedIndex` implementation from the original [Kotlin `fsi`](https://github.com/sndnv/fsi) library is not part of this port.

Both backends are value types with copy-on-write semantics: copying an index is cheap and copies are isolated under mutation. For shared mutable access across threads, wrap an index in an `actor`.

### `MapIndex` vs `TrieIndex`

The main difference between `MapIndex` and `TrieIndex` is their underlying storage - a dictionary in the case of `MapIndex`
and a prefix tree (trie) for `TrieIndex`. In theory, a `MapIndex` should have better performance
for basic operations (add, remove, retrieve) but it uses more memory to store the full paths;
versus a `TrieIndex` that has to traverse the tree to get to a node (which is slower) but stores
the parts of a path only once.

The benefits of `TrieIndex` over `MapIndex` are most visible when collecting information about
a large amount of files on a deeply nested file system.

To illustrate this, we can take the following setup:

```swift
// the value in the index is not relevant for this example
var map = MapIndex<Int>()
var trie = TrieIndex<Int>()

for i in 0..<5 {
    map.put("/a/b/c/\(i)", 0)
    trie.put("/a/b/c/\(i)", 0)
}
```

then data for the `map` index will be stored as:

```json
{
  "/a/b/c/0": 0,
  "/a/b/c/1": 0,
  "/a/b/c/2": 0,
  "/a/b/c/3": 0,
  "/a/b/c/4": 0
}
```

with each entry having a copy of `/a/b/c`, whereas in the `trie` index, it will be (essentially):

```json
{
  "a": {
    "b": {
      "c": {
        "0": 0,
        "1": 0,
        "2": 0,
        "3": 0,
        "4": 0
      }
    }
  }
}
```

with the parts of `/a/b/c` being stored only once.

## Path Schemes

Paths may be _scheme-qualified_, allowing a single index to hold both local file-system paths and logical
entities from non-file-system libraries:

```swift
var index = MapIndex<Int>() // or TrieIndex<Int>()

index.put("/a/b/c", 1)        // a local path
index.put("photos:/a/b/c", 2) // a logical "photos" entity
index.put("music:/a/b/c", 3)  // a logical "music" entity

index.get("/a/b/c")        // 1
index.get("photos:/a/b/c") // 2 - distinct from the local path
```

A scheme is the part before the first `:`; it must start with a letter and be at least two characters long.
This means single-character prefixes (`c:/x`), numeric prefixes (`12:30`) and absolute local paths (`/a/b`)
are **not** treated as schemes. Scheme detection does not depend on the path separator, so both index
implementations recognize schemes identically.

### Scheme mapping

By default, schemes are preserved - what you put is exactly what you get back. To canonicalize
schemes, provide a [`SchemeMapper`](./Sources/fsi/Schemes.swift) - a `(String?) -> String?`
function applied to the parsed scheme (with `nil` meaning "no scheme") - at construction:

```swift
// treat `fs` and `file` as the local/schemeless file system
var index = TrieIndex<Int>(schemeMapper: Schemes.aliases("fs", "file"))

index.put("fs:/a/b/c", 1)
index.get("/a/b/c")        // 1 - `fs:` was stripped
index.get("file:/a/b/c")   // 1 - `file:` maps to the same path
index.get("photos:/a/b/c") // nil - other schemes are still distinct
```

The mapper is configured per-index and applies consistently across both backends. A few mappers are provided
out of the box: `Schemes.Identity` (the default), `Schemes.aliases(...)`, `Schemes.Lowercase` and
`Schemes.Uppercase`.

> A `MapIndex` or `TrieIndex` decoded via `Codable` uses the identity mapper (schemes preserved). To restore a
> custom mapper after decoding, re-insert the entries into an index constructed with that mapper.

## Path normalization

Paths are treated as **absolute**. `TrieIndex` normalizes each path - redundant and trailing separators are
collapsed and a leading separator is always present - so, for example, `a/b/c`, `/a//b/c` and `/a/b/c/` all
refer to the same entry (`/a/b/c`):

```swift
var trie = TrieIndex<Int>()
trie.put("a/b/c", 1)
trie.keys // ["/a/b/c"]
```

`MapIndex` stores keys directly (it has no separator), so it does not perform this normalization - there,
`a/b/c` and `/a/b/c` are distinct keys. A scheme mapper only canonicalizes the scheme component, not the rest
of the path. If you need identical behavior across both backends, pass already normalized, absolute paths.

## Usage

Below are a few examples of how to use the `Index` API; for all available functionality, check
[`Index.swift`](./Sources/fsi/Index.swift) or the in-source documentation comments.

### Basic Operations

```swift
var index = MapIndex<Int>() // or TrieIndex<Int>()
let path = "/a/b/c"

// basic operations
index.size         // 0
index.get(path)    // nil

index.put(path, 42) // adds a new entry

index.size         // 1
index.get(path)    // 42

index.remove(path) // removes the existing entry
index.size         // 0
index.get(path)    // nil
```

### Encoding and Decoding

Both backends conform to `Codable` when their `Value` type does, so an index can be serialized using
any `Codable`-compatible encoder/decoder:

```swift
var index = MapIndex<Int>()
index.put("/a/b/c", 1)

let data = try JSONEncoder().encode(index)
let decoded = try JSONDecoder().decode(MapIndex<Int>.self, from: data)
```

To map values to a different type before serialization (for example, `Int` to `Int64`), use `mapValues`:

```swift
let encoded = index.mapValues { _, value in Int64(value) } // converting values from Int to Int64
let data = try JSONEncoder().encode(encoded)
```

The wire format is the same for `MapIndex` and `TrieIndex` (a flat `{path: value}` JSON object), so the
two backends are interchangeable on disk.

## Development

Refer to the [DEVELOPMENT.md](DEVELOPMENT.md) file for more details.

## Contributing

Contributions are always welcome!

Refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file for more details.

## Versioning

We use [SemVer](http://semver.org/) for versioning.

## License

This project is licensed under the Apache License, Version 2.0 - see the [LICENSE](LICENSE) file for details

> Copyright 2026 https://github.com/sndnv
>
> Licensed under the Apache License, Version 2.0 (the "License");
> you may not use this file except in compliance with the License.
> You may obtain a copy of the License at
>
> http://www.apache.org/licenses/LICENSE-2.0
>
> Unless required by applicable law or agreed to in writing, software
> distributed under the License is distributed on an "AS IS" BASIS,
> WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
> See the License for the specific language governing permissions and
> limitations under the License.
