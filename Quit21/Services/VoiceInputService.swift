import Foundation
import Speech

// MARK: - Section 25/40: on-device speech recognition + deterministic
// keyword parsing into structured events. No cloud LLM, no transcript ever
// leaves the device — SFSpeechRecognizer is configured to prefer on-device
// recognition where the platform supports it.

struct ParsedVoiceEvent {
    enum Kind { case smokingEvent(quantity: Int, trigger: Trigger?), craving(intensity: Int?), checkInSmokeFree, unrecognized }
    let kind: Kind
    let rawText: String
}

enum VoiceInputService {
    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    /// Deterministic keyword parser — intentionally simple and auditable
    /// rather than a black-box model, per section 40 ("never require sending
    /// private smoking history to a cloud LLM").
    static func parse(_ text: String) -> ParsedVoiceEvent {
        let lower = text.lowercased()

        // Near-miss phrasing ("almost"/"nearly") means a craving was resisted,
        // not that smoking happened — checked before the plain "smoked" match
        // so it takes priority.
        let nearMiss = ["almost smoked", "almost smoking", "nearly smoked", "nearly smoking"]
        if nearMiss.contains(where: { lower.contains($0) }) {
            return ParsedVoiceEvent(kind: .craving(intensity: firstNumber(in: lower)), rawText: text)
        }

        // Explicit negation phrasing — every word the product spec calls out
        // (haven't, hasn't, didn't, never, not, without, no) combined with a
        // smoking term. Bare negation words ("no", "not") are deliberately
        // NOT matched in isolation: "I don't know why but I smoked" contains
        // "don't" without meaning "I didn't smoke," so isolated-word matching
        // would misfire. Phrase-level matching avoids that false negative.
        let negations = [
            "haven't smoked", "have not smoked", "hasn't smoked", "has not smoked",
            "didn't smoke", "did not smoke", "never smoked", "never smoke",
            "not smoked", "not smoking", "no smoking", "no cigarettes",
            "without smoking", "without a cigarette", "without smoke",
        ]
        if negations.contains(where: { lower.contains($0) }) || lower.contains("smoke-free") || lower.contains("smoke free") {
            return ParsedVoiceEvent(kind: .checkInSmokeFree, rawText: text)
        }
        if lower.contains("craving") || lower.contains("urge") || lower.contains("want to smoke") {
            return ParsedVoiceEvent(kind: .craving(intensity: firstNumber(in: lower)), rawText: text)
        }
        if lower.contains("smoked") || lower.contains("i smoke") {
            let quantity = firstNumber(in: lower) ?? 1
            let trigger = detectTrigger(in: lower)
            return ParsedVoiceEvent(kind: .smokingEvent(quantity: quantity, trigger: trigger), rawText: text)
        }
        return ParsedVoiceEvent(kind: .unrecognized, rawText: text)
    }

    private static func firstNumber(in text: String) -> Int? {
        let words: [String: Int] = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5]
        for (word, value) in words where text.contains(word) { return value }
        let digits = text.split(separator: " ").compactMap { Int($0) }
        return digits.first
    }

    private static func detectTrigger(in text: String) -> Trigger? {
        let map: [String: Trigger] = [
            "stress": .stress, "stressed": .stress, "dinner": .afterFood, "food": .afterFood,
            "coffee": .coffeeOrTea, "tea": .coffeeOrTea, "alcohol": .alcohol, "drink": .alcohol,
            "work": .work, "bored": .boredom, "anger": .anger, "angry": .anger, "social": .social,
        ]
        for (word, trigger) in map where text.contains(word) { return trigger }
        return nil
    }
}
