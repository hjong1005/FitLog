import UIKit
import Vision

enum WorkoutImageAnalyzer {

    struct Result {
        var workoutName: String
        var exercises: [DraftExercise]
    }

    static func analyze(image: UIImage) async -> Result {
        guard let cgImage = image.cgImage else {
            return Result(workoutName: "Workout", exercises: [DraftExercise()])
        }
        let orientation = cgOrientation(from: image.imageOrientation)

        let lines = await Task.detached {
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            try? handler.perform([request])
            return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        }.value

        let result = parseLines(lines)
        if result.exercises.isEmpty {
            return Result(workoutName: result.workoutName, exercises: [DraftExercise()])
        }
        return result
    }

    // MARK: - Orientation

    private static func cgOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up:            return .up
        case .down:          return .down
        case .left:          return .left
        case .right:         return .right
        case .upMirrored:    return .upMirrored
        case .downMirrored:  return .downMirrored
        case .leftMirrored:  return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default:    return .up
        }
    }

    // MARK: - Parsing

    private static let ignoredWords: Set<String> = ["dvsn"]

    static func parseLines(_ lines: [String]) -> Result {
        var workoutName: String?
        var exercises: [DraftExercise] = []
        var currentGroup: String?
        var pendingText: String?
        var pendingSets: [DraftSet] = []

        for line in lines {
            var trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if ignoredWords.contains(trimmed.lowercased()) { continue }

            // Strip superset prefixes: "S1:", "S2:", or OCR misreads like "51:"
            if let match = trimmed.firstMatch(of: /^[Ss]\d+\s*:\s*/) {
                trimmed = String(trimmed[match.range.upperBound...])
            } else if let match = trimmed.firstMatch(of: /^\d{1,2}\s*:\s*/) {
                let afterPrefix = String(trimmed[match.range.upperBound...])
                if afterPrefix.contains(where: \.isLetter) {
                    trimmed = afterPrefix
                }
            }

            // 1. Try inline exercise: "Exercise Name 4 X 5"
            if let inline = parseInline(trimmed) {
                resolvePending(&pendingText, &pendingSets, &workoutName, &currentGroup, &exercises)
                exercises.append(DraftExercise(
                    name: inline.name,
                    group: currentGroup ?? "",
                    hasGroup: currentGroup != nil,
                    sets: inline.sets
                ))
                continue
            }

            // 2. Try standalone set data: "10x60"
            let sets = extractStandaloneSets(from: trimmed)
            if !sets.isEmpty {
                if pendingText == nil { pendingText = "Exercise" }
                pendingSets.append(contentsOf: sets)
                continue
            }

            // 3. Text-only line
            resolvePending(&pendingText, &pendingSets, &workoutName, &currentGroup, &exercises)
            pendingText = trimmed
        }

        resolvePending(&pendingText, &pendingSets, &workoutName, &currentGroup, &exercises)

        return Result(
            workoutName: workoutName ?? "Workout",
            exercises: exercises
        )
    }

    private static func resolvePending(
        _ text: inout String?,
        _ sets: inout [DraftSet],
        _ workoutName: inout String?,
        _ group: inout String?,
        _ exercises: inout [DraftExercise]
    ) {
        guard let t = text else { return }

        if !sets.isEmpty {
            // Had set data → exercise name
            exercises.append(DraftExercise(
                name: t,
                group: group ?? "",
                hasGroup: group != nil,
                sets: sets
            ))
        } else {
            // No set data → header
            if workoutName == nil {
                workoutName = t
            } else {
                group = t
            }
        }

        text = nil
        sets = []
    }

    // MARK: - Inline: "Exercise Name Sets X Reps"

    private static func parseInline(_ text: String) -> (name: String, sets: [DraftSet])? {
        if let m = text.firstMatch(of: /^(.+?)\s+(\d+)\s*[xX×]\s*(\d+)/) {
            var name = String(m.1)
            guard name.contains(where: \.isLetter) else { return nil }
            let count = Int(m.2) ?? 1
            let reps = Int(m.3) ?? 0
            let afterMatch = String(text[m.range.upperBound...])

            // Range: "4 X 12 - 15" → append "12 - 15" to name, use lowest reps
            if let rangeMatch = afterMatch.firstMatch(of: /^\s*-\s*(\d+)/) {
                name += " \(reps) - \(String(rangeMatch.1))"
            }
            // Options: "3 X 10/12/14" → append "10/12/14" to name, use lowest reps
            else if let optMatch = afterMatch.firstMatch(of: /^(\/\d+(?:\/\d+)*)/) {
                name += " \(reps)\(String(optMatch.1))"
            }

            // Parenthesized info → append to name
            if let parens = afterMatch.firstMatch(of: /\(([^)]+)\)/) {
                name += " (\(String(parens.1)))"
            }

            return (name, (0..<count).map { _ in DraftSet(reps: reps, weight: 0) })
        }

        return nil
    }

    // MARK: - Standalone sets: "3x10x60" or "10x60"

    private static func extractStandaloneSets(from text: String) -> [DraftSet] {
        // Pattern: SxRxW e.g. "3x10x60"
        for match in text.matches(of: /(\d+)\s*[x×X]\s*(\d+)\s*[x×X]\s*([\d.]+)/) {
            let count = Int(match.1) ?? 1
            let reps = Int(match.2) ?? 0
            let weight = Double(match.3) ?? 0
            return (0..<count).map { _ in DraftSet(reps: reps, weight: weight) }
        }

        // Pattern: RxW e.g. "10x60"
        var sets: [DraftSet] = []
        for match in text.matches(of: /(\d+)\s*[x×X@]\s*([\d.]+)/) {
            let reps = Int(match.1) ?? 0
            let weight = Double(match.2) ?? 0
            sets.append(DraftSet(reps: reps, weight: weight))
        }

        return sets
    }
}
