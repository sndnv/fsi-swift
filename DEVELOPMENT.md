## Development

The code is [Swift](https://www.swift.org/) so a recent Swift toolchain (6.0+) needs to be available on your dev machine.

###### Downloads / Installation:

* [Swift](https://www.swift.org/install/)
* [Xcode](https://developer.apple.com/xcode/) (recommended on macOS)

### Getting Started

1) Clone or fork the repo
2) Install [SwiftLint](https://github.com/realm/SwiftLint) (e.g. `brew install swiftlint`)
3) Run `./qa.py`

### Benchmarks

Benchmarks use [swift-package-benchmark](https://github.com/ordo-one/benchmark) and require
[jemalloc](https://jemalloc.net/) for memory metrics:

```
brew install jemalloc
```

To run all benchmarks:

```
./bench.py
```

To run a subset:

```
./bench.py --filter "MapIndex.put"
```

### Current State

Actively maintained
