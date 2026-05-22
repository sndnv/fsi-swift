enum Generators {
    static func generatePaths(
        directoryLevels: Int,
        entitiesPerDirectory: Int,
        separator: String = "/"
    ) -> [String] {
        let entities = entitiesPerDirectory / 2

        func generate(remaining: Int, generated: [String]) -> [String] {
            guard remaining > 0 else { return generated }

            let next = generated.flatMap { current -> [String] in
                if current.contains("file") {
                    return [current]
                }
                let files = (0..<entities).map { "\(current)\(separator)file_\($0)" }
                let directories = (0..<entities).map { "\(current)\(separator)directory_\($0)" }
                return files + directories
            }

            return generate(remaining: remaining - 1, generated: next)
        }

        return generate(remaining: directoryLevels, generated: [""])
    }
}
