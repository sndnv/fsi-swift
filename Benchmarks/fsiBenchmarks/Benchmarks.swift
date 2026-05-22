import Benchmark
import Foundation
import fsi

private let directoryLevels = 5
private let entitiesPerDirectory = 20

private let path1 = "/a/b/c"
private let path2 = "/directory_0/directory_1/file_1"
private let path3 = "/directory_0/directory_1/directory_2/file_0"
private let pathMap: [String: Int] = [path1: 1, path2: 2, path3: 3]
private let pathList: [String] = Array(pathMap.keys)

private let regexNonMatching: NSRegularExpression = try! NSRegularExpression(pattern: "a^")
private let regexMatching: NSRegularExpression = try! NSRegularExpression(pattern: ".")

private let paths: [String] = Generators.generatePaths(
    directoryLevels: directoryLevels,
    entitiesPerDirectory: entitiesPerDirectory
)

private func populate<Idx: Index>(_ index: inout Idx, value: Int) where Idx.Value == Int {
    for path in paths { index.put(path, value) }
}

private func registerProtocolBenchmarks<Idx: Index>(
    _ name: String,
    _ makeIndex: @escaping @Sendable () -> Idx
) where Idx.Value == Int, Idx: Hashable {
    Benchmark("\(name).keys") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.keys)
        }
    }

    Benchmark("\(name).get") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.get(path2))
        }
    }

    Benchmark("\(name).put") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            index.put(path1, 1)
        }
        blackHole(index)
    }

    Benchmark("\(name).putAndAccumulate") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            index.put(path2, 1) { _, _, _ in 1 }
        }
        blackHole(index)
    }

    Benchmark("\(name).putAll") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            index.putAll(pathMap)
        }
        blackHole(index)
    }

    Benchmark("\(name).putAllF") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            index.putAll(pathMap) { _, _, _ in 1 }
        }
        blackHole(index)
    }

    Benchmark("\(name).putAllKeysWithF") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            index.putAll(pathList) { _, _ in 1 }
        }
        blackHole(index)
    }

    Benchmark("\(name).remove") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            index.remove(path2)
        }
        blackHole(index)
    }

    Benchmark("\(name).contains") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.contains(path2))
        }
    }

    Benchmark("\(name).filterDropAll") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.filter { _, _ in false })
        }
    }

    Benchmark("\(name).filterKeepAll") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.filter { _, _ in true })
        }
    }

    Benchmark("\(name).searchNoMatch") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.search(regexNonMatching))
        }
    }

    Benchmark("\(name).searchMatch") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.search(regexMatching))
        }
    }

    Benchmark("\(name).collect") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.collect { _, _ in 1 })
        }
    }

    Benchmark("\(name).forEach") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var count = 0
            index.forEach { _, _ in count += 1 }
            blackHole(count)
        }
    }

    Benchmark("\(name).replaceAll") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var count = 0
            index.replaceAll { _, _ in count += 1; return count }
        }
        blackHole(index)
    }

    Benchmark("\(name).toMap") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.toMap())
        }
    }

    Benchmark("\(name).toList") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.toList())
        }
    }

    Benchmark("\(name).estimatedSize") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.estimatedSize { _ in 0 })
        }
    }

    Benchmark("\(name).equals") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        var other = makeIndex()
        populate(&other, value: 2)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index == other)
        }
    }

    Benchmark("\(name).hashValue") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.hashValue)
        }
    }

    Benchmark("\(name).sameElements") { benchmark in
        var index = makeIndex()
        populate(&index, value: 1)
        var other = makeIndex()
        populate(&other, value: 2)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.sameElements(other))
        }
    }
}

private func registerMapIndexBenchmarks() {
    Benchmark("MapIndex.mapValues") { benchmark in
        var index = MapIndex<Int>()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.mapValues { _, _ in 1 })
        }
    }

    Benchmark("MapIndex.compactMapValuesDropAll") { benchmark in
        var index = MapIndex<Int>()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.compactMapValues { _, _ -> Int? in nil })
        }
    }

    Benchmark("MapIndex.compactMapValuesKeepAll") { benchmark in
        var index = MapIndex<Int>()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.compactMapValues { _, _ -> Int? in 1 })
        }
    }

    Benchmark("MapIndex.encode") { benchmark in
        var index = MapIndex<Int>()
        populate(&index, value: 1)
        let encoder = JSONEncoder()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(try! encoder.encode(index))
        }
    }
}

private func registerTrieIndexBenchmarks() {
    Benchmark("TrieIndex.mapValues") { benchmark in
        var index = TrieIndex<Int>()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.mapValues { _, _ in 1 })
        }
    }

    Benchmark("TrieIndex.compactMapValuesDropAll") { benchmark in
        var index = TrieIndex<Int>()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.compactMapValues { _, _ -> Int? in nil })
        }
    }

    Benchmark("TrieIndex.compactMapValuesKeepAll") { benchmark in
        var index = TrieIndex<Int>()
        populate(&index, value: 1)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.compactMapValues { _, _ -> Int? in 1 })
        }
    }

    Benchmark("TrieIndex.encode") { benchmark in
        var index = TrieIndex<Int>()
        populate(&index, value: 1)
        let encoder = JSONEncoder()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(try! encoder.encode(index))
        }
    }
}

private func registerCrossBackendBenchmarks() {
    Benchmark("CrossBackend.sameElements(Map,Trie)") { benchmark in
        var index = MapIndex<Int>()
        populate(&index, value: 1)
        var other = TrieIndex<Int>()
        populate(&other, value: 2)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.sameElements(other))
        }
    }

    Benchmark("CrossBackend.sameElements(Trie,Map)") { benchmark in
        var index = TrieIndex<Int>()
        populate(&index, value: 1)
        var other = MapIndex<Int>()
        populate(&other, value: 2)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(index.sameElements(other))
        }
    }
}

let benchmarks: @Sendable () -> Void = {
    registerProtocolBenchmarks("MapIndex") { MapIndex<Int>() }
    registerProtocolBenchmarks("TrieIndex") { TrieIndex<Int>() }
    registerMapIndexBenchmarks()
    registerTrieIndexBenchmarks()
    registerCrossBackendBenchmarks()
}
