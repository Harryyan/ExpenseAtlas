import Foundation
import Observation

@Observable
final class CSVPreviewViewModel {
    private(set) var rows: [[String]] = []
    private(set) var loadError: String?

    private let url: URL?

    init(url: URL?) {
        self.url = url
    }

    func load() {
        guard let url else {
            loadError = "File not found"
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            rows = parseCSV(content)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func parseCSV(_ content: String) -> [[String]] {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        return lines.map { line in
            parseCSVLine(line)
        }
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }
}
