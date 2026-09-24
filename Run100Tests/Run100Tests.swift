//
//  Run100Tests.swift
//  Run100Tests
//
//  Created by 이준성 on 9/19/26.
//

import Foundation
import Testing
@testable import Run100

struct Run100Tests {

    @Test func testMonthlyProgressCalculations() async throws {
        // 100km 중 65.0km 달렸을 때의 진행률 검증
        let progress = MonthlyProgress(
            year: 2026,
            month: 9,
            totalAccumulatedKm: 65.0,
            sessionsCount: 10,
            currentStreak: 3,
            runDaysCount: 8
        )
        
        #expect(progress.remainingKm == 35.0)
        #expect(progress.completionPercentage == 65)
        #expect(!progress.isGoalAchieved)
    }

    @Test func testGoalAchievedCalculations() async throws {
        // 100km 정확히 달성 시 검증
        let exactProgress = MonthlyProgress(
            year: 2026,
            month: 9,
            totalAccumulatedKm: 100.0,
            sessionsCount: 15,
            currentStreak: 5,
            runDaysCount: 14
        )
        
        #expect(exactProgress.remainingKm == 0.0)
        #expect(exactProgress.completionPercentage == 100)
        #expect(exactProgress.isGoalAchieved)
        #expect(!exactProgress.isOverachieved)
        #expect(exactProgress.excessKm == 0.0)
        #expect(exactProgress.recommendedDailyKm == 0.0)
        
        // 100km 초과 달성 시 검증 (102.5km)
        let overProgress = MonthlyProgress(
            year: 2026,
            month: 9,
            totalAccumulatedKm: 102.5,
            sessionsCount: 16,
            currentStreak: 6,
            runDaysCount: 15
        )
        
        #expect(overProgress.remainingKm == 0.0)
        #expect(overProgress.completionPercentage == 100)
        #expect(overProgress.isGoalAchieved)
        #expect(overProgress.isOverachieved)
        #expect(overProgress.excessKm == 2.5)
        #expect(overProgress.coachMessage.contains("보너스 질주"))
    }

    @Test func testRunStoreAggregation() async throws {
        let store = RunStore()
        let now = Date()
        
        let session1 = RunSession(distanceKm: 5.0, date: now, memo: "아침 러닝")
        let session2 = RunSession(distanceKm: 7.2, date: now, memo: "저녁 러닝")
        
        let progress = store.calculateMonthlyProgress(from: [session1, session2])
        
        #expect(progress.totalAccumulatedKm == 12.2)
        #expect(progress.sessionsCount == 2)
        #expect(progress.runDaysCount == 1)
        #expect(progress.remainingKm == 87.8)
    }
    
    @Test func testHealthKitSessionMappingAndDuplicatePrevention() async throws {
        let workoutUUID = UUID()
        let session = RunSession(
            id: workoutUUID,
            distanceKm: 8.5,
            date: Date(),
            durationSeconds: 2700,
            memo: "Apple Watch 울트라 러닝",
            isManual: false,
            source: "AppleHealth"
        )
        
        #expect(session.id == workoutUUID)
        #expect(session.distanceKm == 8.5)
        #expect(!session.isManual)
        #expect(session.source == "AppleHealth")
        
        // 기존 세션 목록에서 동일 UUID 포함 여부 검증 (중복 방지 알고리즘 검증)
        let existingSessions = [session]
        let existingUUIDs = Set(existingSessions.map { $0.id })
        
        #expect(existingUUIDs.contains(workoutUUID))
        
        let newWorkoutUUID = UUID()
        #expect(!existingUUIDs.contains(newWorkoutUUID))
    }
    
    @Test func testWidgetSnapshotDataModel() async throws {
        let placeholder = WidgetSnapshotData.placeholder
        
        #expect(placeholder.targetKm == 100.0)
        #expect(placeholder.totalAccumulatedKm == 68.0)
        #expect(placeholder.remainingKm == 32.0)
        #expect(placeholder.completionPercentage == 68)
        #expect(placeholder.paceValueOnly == "5:30")
        #expect(placeholder.heartRateValueOnly == "152")
        #expect(placeholder.sessionsCount == 12)
        #expect(placeholder.recent7Days.count == 7)
        #expect(placeholder.recent7Days.last?.isToday == true)
        
        // JSON 직렬화/역직렬화 검증 (App Group 공유 데이터 무결성)
        let encoded = try JSONEncoder().encode(placeholder)
        let decoded = try JSONDecoder().decode(WidgetSnapshotData.self, from: encoded)
        
        #expect(decoded.completionPercentage == 68)
        #expect(decoded.paceValueOnly == "5:30")
        #expect(decoded.heartRateValueOnly == "152")
        #expect(decoded.sessionsCount == 12)
        #expect(decoded.recent7Days.count == 7)
    }
    
    @Test func testAveragePaceCalculations() async throws {
        // 10km를 3300초(55분) 동안 달렸을 때 -> 330초/km = 5분 30초 (5:30/km)
        let progress = MonthlyProgress(
            year: 2026,
            month: 9,
            totalAccumulatedKm: 10.0,
            sessionsCount: 2,
            currentStreak: 2,
            runDaysCount: 2,
            totalDurationSeconds: 3300
        )
        
        #expect(progress.averagePaceString == "5:30/km")
        
        // 거리가 0일 때 방어 테스트
        let emptyProgress = MonthlyProgress(
            year: 2026,
            month: 9,
            totalAccumulatedKm: 0.0,
            sessionsCount: 0,
            currentStreak: 0,
            runDaysCount: 0,
            totalDurationSeconds: 0
        )
        #expect(emptyProgress.averagePaceString == "-:--")
    }
    
    @Test func testDailyCumulativePointsAggregation() async throws {
        let store = RunStore()
        let calendar = Calendar.current
        var comps = DateComponents()
        comps.year = store.selectedYear
        comps.month = store.selectedMonth
        comps.day = 1
        let day1 = calendar.date(from: comps) ?? Date()
        comps.day = 3
        let day3 = calendar.date(from: comps) ?? Date()
        
        let session1 = RunSession(distanceKm: 5.0, date: day1, durationSeconds: 1500)
        let session2 = RunSession(distanceKm: 7.0, date: day3, durationSeconds: 2100)
        
        let progress = store.calculateMonthlyProgress(from: [session1, session2])
        
        #expect(progress.dailyCumulativePoints.count >= 3)
        #expect(progress.dailyCumulativePoints[0].cumulativeKm == 5.0)
        // 2일차는 러닝이 없으므로 1일차 5.0km 유지
        #expect(progress.dailyCumulativePoints[1].cumulativeKm == 5.0)
        // 3일차는 7.0km 추가되어 12.0km
        #expect(progress.dailyCumulativePoints[2].cumulativeKm == 12.0)
    }
    
    @Test func testPastMonthsSeriesAggregation() async throws {
        let store = RunStore()
        let calendar = Calendar.current
        
        // 1개월 전 날짜 생성
        var c = DateComponents()
        c.year = store.selectedYear
        c.month = store.selectedMonth
        c.day = 10
        let baseDate = calendar.date(from: c) ?? Date()
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: baseDate) ?? Date()
        
        let pastSession = RunSession(distanceKm: 8.0, date: oneMonthAgo, durationSeconds: 2400)
        let progress = store.calculateMonthlyProgress(from: [pastSession])
        
        #expect(!progress.pastMonthsSeries.isEmpty)
        #expect(progress.pastMonthsSeries.first?.totalKm == 8.0)
    }
    
    @Test func testAverageHeartRateCalculations() async throws {
        let store = RunStore()
        let now = Date()
        
        let session1 = RunSession(distanceKm: 5.0, date: now, durationSeconds: 1800, averageHeartRate: 150)
        let session2 = RunSession(distanceKm: 7.0, date: now, durationSeconds: 2400, averageHeartRate: 160)
        let session3 = RunSession(distanceKm: 3.0, date: now, durationSeconds: 1000, averageHeartRate: nil) // 심박수 없는 수기 세션
        
        let progress = store.calculateMonthlyProgress(from: [session1, session2, session3])
        
        // (150 + 160) / 2 = 155 bpm
        #expect(progress.averageHeartRate == 155)
        #expect(progress.heartRateValueOnly == "155")
        #expect(progress.heartRateStatusMessage.contains("적정 유산소 심박 구간"))
    }
    
    @Test func testCalendarWeekdayOffsets() async throws {
        let calendar = Calendar.current
        
        // 2026년 8월 1일 검증 (토요일)
        var augComps = DateComponents(year: 2026, month: 8, day: 1, hour: 12)
        let augDate = calendar.date(from: augComps)!
        let augWeekday = calendar.component(.weekday, from: augDate)
        let augOffset = (augWeekday + 5) % 7
        // 1(일), 2(월), 3(화), 4(수), 5(목), 6(금), 7(토)
        #expect(augWeekday == 7) // 토요일
        #expect(augOffset == 5)  // 월(0), 화(1), 수(2), 목(3), 금(4) 뒤 토요일(5)
        
        // 2026년 8월 5일 검증 (수요일)
        var aug5Comps = DateComponents(year: 2026, month: 8, day: 5, hour: 12)
        let aug5Date = calendar.date(from: aug5Comps)!
        let aug5Weekday = calendar.component(.weekday, from: aug5Date)
        #expect(aug5Weekday == 4) // 수요일
        
        // 2026년 9월 1일 검증 (화요일)
        var sepComps = DateComponents(year: 2026, month: 9, day: 1, hour: 12)
        let sepDate = calendar.date(from: sepComps)!
        let sepWeekday = calendar.component(.weekday, from: sepDate)
        let sepOffset = (sepWeekday + 5) % 7
        #expect(sepWeekday == 3) // 화요일
        #expect(sepOffset == 1)  // 월(0) 뒤 화요일(1)
    }
    
    @Test func testRunSessionPaceString() async throws {
        // 5km를 1650초(27분 30초)에 달렸을 때 -> 330초/km = 5:30/km
        let session = RunSession(distanceKm: 5.0, durationSeconds: 1650)
        #expect(session.paceString == "5:30/km")
        
        // 거리가 0이거나 운동 시간이 0일 때 방어 테스트
        let zeroSession = RunSession(distanceKm: 0.0, durationSeconds: 0)
        #expect(zeroSession.paceString == "-:--")
    }
    
    @Test func testMonthlyHistorySummaryCalculations() async throws {
        // 100km 완주 달성 월 검증
        let achievedSummary = MonthlyHistorySummary(
            year: 2026,
            month: 9,
            targetKm: 100.0,
            totalDistanceKm: 105.4,
            sessionsCount: 12,
            runDaysCount: 10,
            totalDurationSeconds: 34800, // 5:30/km 수준
            averageHeartRate: 152
        )
        
        #expect(achievedSummary.isGoalAchieved)
        #expect(achievedSummary.monthLabel == "9월")
        #expect(achievedSummary.yearMonthLabel == "2026년 9월")
        #expect(achievedSummary.heartRateDisplayString == "152 bpm")
        #expect(achievedSummary.daysInMonth == 30) // 9월은 30일
        #expect(achievedSummary.runAttendanceRate == 33) // 10/30 = 33%
        
        // 미달성 월 검증
        let unachievedSummary = MonthlyHistorySummary(
            year: 2026,
            month: 8,
            targetKm: 100.0,
            totalDistanceKm: 65.0,
            sessionsCount: 8,
            runDaysCount: 7,
            totalDurationSeconds: 21450,
            averageHeartRate: nil
        )
        #expect(!unachievedSummary.isGoalAchieved)
        #expect(unachievedSummary.heartRateDisplayString == "-")
        #expect(unachievedSummary.daysInMonth == 31) // 8월은 31일
    }
    
    @Test func testCalculateHistorySummariesPeriodsAndOrdering() async throws {
        let store = RunStore()
        let calendar = Calendar.current
        
        // 당월 세션 및 2달 전 세션 준비
        var comps = DateComponents()
        comps.year = store.selectedYear
        comps.month = store.selectedMonth
        comps.day = 5
        let currentMonthDate = calendar.date(from: comps) ?? Date()
        
        let twoMonthsAgoDate = calendar.date(byAdding: .month, value: -2, to: currentMonthDate) ?? Date()
        
        let session1 = RunSession(distanceKm: 10.0, date: currentMonthDate, durationSeconds: 3300, averageHeartRate: 150)
        let session2 = RunSession(distanceKm: 15.0, date: twoMonthsAgoDate, durationSeconds: 4950, averageHeartRate: 145)
        
        // 올해(.thisYear) 조회 검증: 1월부터 당월(selectedMonth)까지의 요약 반환
        let thisYearSummaries = store.calculateHistorySummaries(from: [session1, session2], period: .thisYear)
        #expect(thisYearSummaries.count == store.selectedMonth)
        #expect(thisYearSummaries.first?.month == 1)
        #expect(thisYearSummaries.first?.year == store.selectedYear)
        
        // 마지막 항목은 현재 선택된 연/월
        #expect(thisYearSummaries.last?.year == store.selectedYear)
        #expect(thisYearSummaries.last?.month == store.selectedMonth)
        #expect(thisYearSummaries.last?.totalDistanceKm == 10.0)
        #expect(thisYearSummaries.last?.averageHeartRate == 150)
        
        // 최근 12개월(.twelveMonths) 조회 검증
        let twelveMonths = store.calculateHistorySummaries(from: [session1, session2], period: .twelveMonths)
        #expect(twelveMonths.count == 12)
        #expect(twelveMonths.last?.year == store.selectedYear)
        #expect(twelveMonths.last?.month == store.selectedMonth)
        
        // 하위 호환성 monthsLimit 검증
        let legacySixMonths = store.calculateHistorySummaries(from: [session1, session2], monthsLimit: 6)
        #expect(legacySixMonths.count == 6)
    }
    
    @Test func testSamePeriodGhostCompetitionCalculations() async throws {
        // 과거 3개월 데이터가 포함된 MonthlyProgress 생성
        let pastSeries1 = MonthComparisonSeries(
            year: 2026,
            month: 8,
            monthOffset: -1,
            totalKm: 85.0,
            points: [
                DailyCumulativePoint(day: 1, cumulativeKm: 3.0),
                DailyCumulativePoint(day: 19, cumulativeKm: 50.0),
                DailyCumulativePoint(day: 31, cumulativeKm: 85.0)
            ]
        )
        let pastSeries2 = MonthComparisonSeries(
            year: 2026,
            month: 7,
            monthOffset: -2,
            totalKm: 105.0,
            points: [
                DailyCumulativePoint(day: 1, cumulativeKm: 5.0),
                DailyCumulativePoint(day: 19, cumulativeKm: 70.0),
                DailyCumulativePoint(day: 31, cumulativeKm: 105.0)
            ]
        )
        
        var progress = MonthlyProgress(
            year: 2026,
            month: 9,
            totalAccumulatedKm: 60.0,
            sessionsCount: 10,
            currentStreak: 2,
            runDaysCount: 8
        )
        progress.pastMonthsSeries = [pastSeries1, pastSeries2]
        
        let comparisons = progress.samePeriodComparisons
        // 당월 + 과거 2개월 = 총 3개
        #expect(comparisons.count == 3)
        
        // 7월(70km) > 9월 당월(60km) > 8월(50km) 순위 정렬 검증
        #expect(comparisons[0].month == 7)
        #expect(comparisons[0].cumulativeKm == 70.0)
        #expect(comparisons[1].month == 9)
        #expect(comparisons[1].cumulativeKm == 60.0)
        #expect(comparisons[1].isCurrentMonth == true)
        #expect(comparisons[2].month == 8)
        #expect(comparisons[2].cumulativeKm == 50.0)
        
        // 당월 순위는 2위
        #expect(progress.currentMonthRank == 2)
        
        // 지난달(8월 50km) 대비 당월(60km)은 +10.0km 앞섬 메시지 검증
        #expect(progress.ghostCompetitionMessage.contains("지난달 대비 +10.0km 🔥"))
        
        // 팽팽한 접전 케이스 (지난달 50.0km vs 당월 50.3km -> 차이 +0.3km로 0.5km 이내)
        progress.totalAccumulatedKm = 50.3
        #expect(progress.ghostCompetitionMessage.contains("지난달과 팽팽한 접전 ⚡️"))
        
        // 0km 첫 러닝 전 케이스
        progress.totalAccumulatedKm = 0.0
        #expect(progress.ghostCompetitionMessage.contains("첫 러닝으로 과거의 나를 앞서보세요! 🏃"))
    }
}

