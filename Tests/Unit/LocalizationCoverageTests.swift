import XCTest

/// Prüft, dass jeder im App-Code verwendete Lokalisierungsschlüssel
/// (`String(localized: "...")`) auch als Eintrag in
/// `Resources/Localizable.xcstrings` existiert.
///
/// Xcode-seitiges Pendant zu `scripts/check_localization.py` (dort läuft
/// dieselbe Prüfung eigenständig ohne Xcode/Compiler). In dieser Umgebung
/// steht kein macOS/Xcode zur Verfügung, daher konnte dieser Test nicht
/// kompiliert oder ausgeführt werden - siehe offene Punkte.
final class LocalizationCoverageTests: XCTestCase {

    /// Repo-Wurzel, relativ zu dieser Testdatei (`Tests/Unit/...swift`).
    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // LocalizationCoverageTests.swift
            .deletingLastPathComponent() // Unit
            .deletingLastPathComponent() // Tests
    }

    private let sourceDirectoryNames = ["App", "DesignSystem", "Illustration", "Games", "Progress", "Teepause", "Settings", "Garden"]

    func testAllUsedLocalizationKeysExistInCatalog() throws {
        let usedKeys = try sourceDirectoryNames
            .map { repoRoot.appendingPathComponent($0) }
            .flatMap(swiftFiles)
            .flatMap(localizationKeys)

        let catalogKeys = try availableKeys(
            in: repoRoot.appendingPathComponent("Resources/Localizable.xcstrings")
        )

        let missing = Set(usedKeys).subtracting(catalogKeys).sorted()
        XCTAssertTrue(
            missing.isEmpty,
            "Fehlende Schlüssel in Localizable.xcstrings: \(missing.joined(separator: ", "))"
        )
    }

    private func swiftFiles(under directory: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        return enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
    }

    private func localizationKeys(in file: URL) throws -> [String] {
        let content = try String(contentsOf: file, encoding: .utf8)
        let pattern = #"String\(localized:\s*"([^"]+)""#
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(content.startIndex..., in: content)
        return regex.matches(in: content, range: range).compactMap { match in
            guard let keyRange = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[keyRange])
        }
    }

    private func availableKeys(in catalog: URL) throws -> Set<String> {
        let data = try Data(contentsOf: catalog)
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let strings = object["strings"] as? [String: Any]
        else {
            return []
        }
        return Set(strings.keys)
    }
}
