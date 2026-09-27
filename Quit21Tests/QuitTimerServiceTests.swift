import XCTest
@testable import Quit21

final class QuitTimerServiceTests: XCTestCase {
    func testBreakdownZero() {
        let b = QuitTimerService.breakdown(seconds: 0)
        XCTAssertEqual(b.days, 0); XCTAssertEqual(b.hours, 0); XCTAssertEqual(b.minutes, 0); XCTAssertEqual(b.seconds, 0)
    }

    func testBreakdownFourDaysSevenHours() {
        let seconds: TimeInterval = 4 * 86400 + 7 * 3600 + 32 * 60 + 14
        let b = QuitTimerService.breakdown(seconds: seconds)
        XCTAssertEqual(b.days, 4)
        XCTAssertEqual(b.hours, 7)
        XCTAssertEqual(b.minutes, 32)
        XCTAssertEqual(b.seconds, 14)
    }

    func testNeverNegative() {
        let b = QuitTimerService.breakdown(seconds: -500)
        XCTAssertEqual(b.days, 0)
    }
}

final class QuitJourneyTests: XCTestCase {
    func testCurrentStreakUsesQuitDateWhenNoSmokingEvent() {
        let journey = QuitJourney(startDate: .now, quitDate: Date().addingTimeInterval(-3600))
        let seconds = journey.currentStreakSeconds(now: .now)
        XCTAssertEqual(seconds, 3600, accuracy: 1)
    }

    func testCurrentStreakUsesLastSmokingEventWhenPresent() {
        let journey = QuitJourney(startDate: .now, quitDate: Date().addingTimeInterval(-7200))
        journey.lastSmokingEventDate = Date().addingTimeInterval(-1800)
        XCTAssertEqual(journey.currentStreakSeconds(now: .now), 1800, accuracy: 1)
    }

    func testCurrentDayStartsAtOne() {
        let journey = QuitJourney(startDate: .now, quitDate: .now)
        XCTAssertEqual(journey.currentDay(now: .now), 1)
    }

    func testCurrentDayAfterOneFullDay() {
        let journey = QuitJourney(startDate: .now, quitDate: Date().addingTimeInterval(-90000))
        XCTAssertEqual(journey.currentDay(now: .now), 2)
    }

    /// Section 36: elapsed time must be immune to DST, timezone changes and
    /// midnight rollovers. `Date` and `timeIntervalSince` are absolute-time
    /// (UTC-based) by construction — this test pins that guarantee so a
    /// future refactor can't accidentally introduce calendar-based
    /// day-counting, which WOULD be affected by DST/timezone shifts.
    func testStreakUnaffectedByDaylightSavingTransition() {
        // US DST: clocks spring forward 2am -> 3am on 2027-03-14.
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "America/New_York")!
        let before = utc.date(from: DateComponents(year: 2027, month: 3, day: 14, hour: 1, minute: 0))!
        let after = utc.date(from: DateComponents(year: 2027, month: 3, day: 14, hour: 4, minute: 0))! // wall-clock +3h, actual +2h
        let journey = QuitJourney(startDate: before, quitDate: before)
        // Real elapsed time is 2 hours despite the wall clock reading +3h.
        XCTAssertEqual(journey.currentStreakSeconds(now: after), 2 * 3600, accuracy: 1)
    }

    func testStreakUnaffectedByMidnightRollover() {
        let justBeforeMidnight = Calendar.current.date(from: DateComponents(year: 2027, month: 6, day: 1, hour: 23, minute: 59, second: 0))!
        let justAfterMidnight = Calendar.current.date(from: DateComponents(year: 2027, month: 6, day: 2, hour: 0, minute: 1, second: 0))!
        let journey = QuitJourney(startDate: justBeforeMidnight, quitDate: justBeforeMidnight)
        XCTAssertEqual(journey.currentStreakSeconds(now: justAfterMidnight), 120, accuracy: 1)
    }

    /// Section 17: the exact instant a user crosses from Day 21 into "Stay
    /// Quit" territory. One second before is still Day 21, the boundary
    /// itself is Day 22, first day of "Stay Quit."
    func test21DayBoundaryTransition() {
        let quitDate = Date().addingTimeInterval(-21 * 86400)
        let journey = QuitJourney(startDate: quitDate, quitDate: quitDate)
        XCTAssertEqual(journey.currentDay(now: .now), 22)
        XCTAssertEqual(journey.currentDay(now: quitDate.addingTimeInterval(21 * 86400 - 1)), 21)
    }

    func testFutureDatedSmokingEventDoesNotProduceNegativeStreak() {
        let journey = QuitJourney(startDate: .now, quitDate: .now)
        journey.lastSmokingEventDate = Date().addingTimeInterval(3600) // clock skew / bad input
        XCTAssertGreaterThanOrEqual(journey.currentStreakSeconds(now: .now), 0)
    }
}

final class MotivationEngineTests: XCTestCase {
    func testDay1IsScripted() {
        let ctx = MotivationContext(day: 1, recentSmokingEvents: [], recentCravingEvents: [], primaryReasonText: nil, strongestTrigger: nil)
        XCTAssertEqual(MotivationEngine.message(for: ctx), "You made the decision. Today, we protect it.")
    }

    func testDay21IsScripted() {
        let ctx = MotivationContext(day: 21, recentSmokingEvents: [], recentCravingEvents: [], primaryReasonText: nil, strongestTrigger: nil)
        XCTAssertTrue(MotivationEngine.message(for: ctx).contains("21 days"))
    }

    func testUnscriptedDayNeverEmpty() {
        for day in [6, 8, 9, 11, 30, 90] {
            let ctx = MotivationContext(day: day, recentSmokingEvents: [], recentCravingEvents: [], primaryReasonText: nil, strongestTrigger: nil)
            XCTAssertFalse(MotivationEngine.message(for: ctx).isEmpty)
        }
    }
}

final class TriggerAnalysisServiceTests: XCTestCase {
    func testStrongestTriggerFromRepeatedEvents() {
        let events = [
            SmokingEvent(trigger: .alcohol), SmokingEvent(trigger: .alcohol), SmokingEvent(trigger: .work),
        ]
        XCTAssertEqual(TriggerAnalysisService.strongestTrigger(smokingEvents: events), .alcohol)
    }

    func testInsightsEmptyWithNoEvents() {
        XCTAssertTrue(TriggerAnalysisService.insights(smokingEvents: [], cravingEvents: []).isEmpty)
    }

    func testMostSuccessfulIntervention() {
        let cravings = [
            CravingEvent(beforeIntensity: 7, trigger: .stress, intervention: .walk, resolved: true),
            CravingEvent(beforeIntensity: 6, trigger: .stress, intervention: .walk, resolved: true),
            CravingEvent(beforeIntensity: 8, trigger: .stress, intervention: .breathing, resolved: false),
        ]
        XCTAssertEqual(TriggerAnalysisService.mostSuccessfulIntervention(for: .stress, cravingEvents: cravings), .walk)
    }
}

final class InterventionEngineTests: XCTestCase {
    func testAlcoholStepsWarnAboutRisk() {
        let (intro, steps) = InterventionEngine.steps(for: .alcohol, priorSuccess: nil)
        XCTAssertTrue(intro.lowercased().contains("alcohol"))
        XCTAssertFalse(steps.isEmpty)
    }

    func testPriorSuccessIsPromotedFirst() {
        let (_, steps) = InterventionEngine.steps(for: .stress, priorSuccess: .water)
        XCTAssertEqual(steps.first?.kind, .water)
    }
}

final class VoiceInputServiceTests: XCTestCase {
    func testParsesSmokingEvent() {
        let result = VoiceInputService.parse("I smoked two cigarettes after dinner because I was stressed")
        if case let .smokingEvent(quantity, trigger) = result.kind {
            XCTAssertEqual(quantity, 2)
            XCTAssertEqual(trigger, .stress)
        } else {
            XCTFail("expected smokingEvent")
        }
    }

    func testParsesCraving() {
        let result = VoiceInputService.parse("I am having a really bad craving")
        if case .craving = result.kind {} else { XCTFail("expected craving") }
    }

    func testParsesSmokeFreeCheckIn() {
        let result = VoiceInputService.parse("I haven't smoked for 5 days")
        if case .checkInSmokeFree = result.kind {} else { XCTFail("expected checkInSmokeFree") }
    }

    /// Section 32, marked CRITICAL: "Never interpret 'I haven't smoked.' as
    /// 'I smoked.'" One case per negation word the spec explicitly lists:
    /// haven't, hasn't, didn't, never, not, without, no. Each phrase contains
    /// "smoke"/"smoked" so a naive substring match on "smoked" alone would
    /// misfire — this is exactly the regression the spec is guarding against.
    func testNegationWordsNeverReadAsSmokingEvent() {
        let phrases = [
            "I haven't smoked today",
            "I hasn't smoked all week",              // ungrammatical but should still resist misfire
            "I have not smoked since Monday",
            "I didn't smoke at the party",
            "I did not smoke even once",
            "I have never smoked since I quit",
            "I never smoke anymore",
            "I'm not smoking today",
            "There was no smoking at the event",
            "I got through the party without smoking",
            "I made it through dinner without a cigarette",
        ]
        for phrase in phrases {
            let result = VoiceInputService.parse(phrase)
            if case .smokingEvent = result.kind {
                XCTFail("negation phrase misread as a smoking event: \"\(phrase)\"")
            }
        }
    }

    /// "Almost"/"nearly" mean a craving was resisted, not that smoking
    /// happened — matches the spec's own example ("I almost smoked because I
    /// was stressed" → a craving event with trigger stress).
    func testAlmostAndNearlyReadAsCravingNotSmoking() {
        for phrase in ["I almost smoked because I was stressed", "I nearly smoked but didn't"] {
            let result = VoiceInputService.parse(phrase)
            if case .craving = result.kind {} else { XCTFail("expected craving for near-miss phrase: \"\(phrase)\"") }
        }
    }

    func testPositiveSmokingStillDetectedDespiteUnrelatedNegationWord() {
        // "don't know why" contains "don't" but is not a negation of smoking —
        // the real event (smoked) must still be detected.
        let result = VoiceInputService.parse("I don't know why but I smoked one cigarette")
        if case let .smokingEvent(quantity, _) = result.kind {
            XCTAssertEqual(quantity, 1)
        } else {
            XCTFail("expected smokingEvent despite unrelated negation word")
        }
    }
}

final class DataExportServiceTests: XCTestCase {
    func testJSONRoundTrips() {
        let snapshot = ExportSnapshot(exportedAt: .now, quitStartDate: .now, quitDate: .now, smokingEvents: [], cravingEvents: [], checkIns: [])
        let data = DataExportService.json(snapshot)
        XCTAssertFalse(data.isEmpty)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try? decoder.decode(ExportSnapshot.self, from: data)
        XCTAssertNotNil(decoded)
    }

    func testCSVHasHeader() {
        let snapshot = ExportSnapshot(exportedAt: .now, quitStartDate: nil, quitDate: nil, smokingEvents: [], cravingEvents: [], checkIns: [])
        let csv = String(data: DataExportService.csv(snapshot), encoding: .utf8) ?? ""
        XCTAssertTrue(csv.hasPrefix("type,timestamp"))
    }
}
