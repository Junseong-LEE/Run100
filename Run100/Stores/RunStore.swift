//
//  RunStore.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import Foundation
import SwiftData

/// 앱의 러닝 데이터 계산 및 상태를 총괄 관리하는 매니저
@Observable
final class RunStore {
    var selectedYear: Int
    var selectedMonth: Int
    
    init(date: Date = Date()) {
        let calendar = Calendar.current
        self.selectedYear = calendar.component(.year, from: date)
        self.selectedMonth = calendar.component(.month, from: date)
    }
    
    // MARK: - 월 변경 탐색
    
    /// 현재 선택된 월에서 이전/다음 달로 변경
    func changeMonth(by offset: Int) {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        
        let calendar = Calendar.current
        if let currentDate = calendar.date(from: components),
           let newDate = calendar.date(byAdding: .month, value: offset, to: currentDate) {
            self.selectedYear = calendar.component(.year, from: newDate)
            self.selectedMonth = calendar.component(.month, from: newDate)
        }
    }
    
    /// 현재 달인지 여부 판별
    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        return selectedYear == calendar.component(.year, from: now) &&
               selectedMonth == calendar.component(.month, from: now)
    }
    
    // MARK: - 월간 통계 계산
    
    /// 주어진 세션 목록에서 선택된 연/월의 진행 상황 집계 반환
    func calculateMonthlyProgress(from allSessions: [RunSession], targetKm: Double = 100.0) -> MonthlyProgress {
        let calendar = Calendar.current
        
        // 선택된 연/월 세션 필터링
        let monthSessions = allSessions.filter { session in
            let sessionYear = calendar.component(.year, from: session.date)
            let sessionMonth = calendar.component(.month, from: session.date)
            return sessionYear == selectedYear && sessionMonth == selectedMonth
        }
        
        let totalKm = monthSessions.reduce(0.0) { $0 + $1.distanceKm }
        let totalDuration = monthSessions.reduce(0.0) { $0 + $1.durationSeconds }
        
        // 고유 달린 날 집계
        let uniqueRunDays = Set(monthSessions.map { calendar.component(.day, from: $0.date) })
        
        // 연속 달리기(스트릭) 계산
        let streak = calculateCurrentStreak(from: allSessions)
        
        // 당월 일자별 누적 러닝 거리 계산 (라인 차트용)
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        let totalDaysInMonth = (calendar.date(from: components).flatMap { calendar.range(of: .day, in: .month, for: $0) })?.count ?? 30
        
        let now = Date()
        let isCurrentYearMonth = (calendar.component(.year, from: now) == selectedYear && calendar.component(.month, from: now) == selectedMonth)
        let maxDisplayDay = isCurrentYearMonth ? min(calendar.component(.day, from: now), totalDaysInMonth) : totalDaysInMonth
        
        var dayDistanceDict: [Int: Double] = [:]
        for session in monthSessions {
            let day = calendar.component(.day, from: session.date)
            dayDistanceDict[day, default: 0.0] += session.distanceKm
        }
        
        var cumulativePoints: [DailyCumulativePoint] = []
        var runningTotal: Double = 0.0
        // 차트 시각화를 위해 최소 1일부터 maxDisplayDay까지 누적 추이 구성
        for d in 1...max(maxDisplayDay, 1) {
            runningTotal += dayDistanceDict[d, default: 0.0]
            cumulativePoints.append(DailyCumulativePoint(day: d, cumulativeKm: (runningTotal * 10).rounded() / 10))
        }
        
        // 최근 3개월치(직전 1, 2, 3개월) 비교 데이터 시리즈 계산
        var pastSeries: [MonthComparisonSeries] = []
        for offset in [-3, -2, -1] {
            var c = DateComponents()
            c.year = selectedYear
            c.month = selectedMonth
            c.day = 1
            guard let baseDate = calendar.date(from: c),
                  let targetDate = calendar.date(byAdding: .month, value: offset, to: baseDate) else { continue }
            
            let pastYear = calendar.component(.year, from: targetDate)
            let pastMonth = calendar.component(.month, from: targetDate)
            
            let pastMonthSessions = allSessions.filter { session in
                let y = calendar.component(.year, from: session.date)
                let m = calendar.component(.month, from: session.date)
                return y == pastYear && m == pastMonth
            }
            
            guard !pastMonthSessions.isEmpty else { continue }
            
            let daysInPastMonth = calendar.range(of: .day, in: .month, for: targetDate)?.count ?? 30
            var pastDayDict: [Int: Double] = [:]
            for s in pastMonthSessions {
                let day = calendar.component(.day, from: s.date)
                pastDayDict[day, default: 0.0] += s.distanceKm
            }
            
            var pastPoints: [DailyCumulativePoint] = []
            var pTotal: Double = 0.0
            for d in 1...daysInPastMonth {
                pTotal += pastDayDict[d, default: 0.0]
                pastPoints.append(DailyCumulativePoint(day: d, cumulativeKm: (pTotal * 10).rounded() / 10))
            }
            
            pastSeries.append(MonthComparisonSeries(
                year: pastYear,
                month: pastMonth,
                monthOffset: offset,
                totalKm: (pTotal * 10).rounded() / 10,
                points: pastPoints
            ))
        }
        
        // 당월 평균 심박수 집계 (심박수 기록이 존재하는 세션들의 평균)
        let heartRateValues = monthSessions.compactMap { $0.averageHeartRate }
        let avgHeartRate: Int? = heartRateValues.isEmpty ? nil : Int((Double(heartRateValues.reduce(0, +)) / Double(heartRateValues.count)).rounded())
        
        return MonthlyProgress(
            year: selectedYear,
            month: selectedMonth,
            targetKm: targetKm,
            totalAccumulatedKm: (totalKm * 10).rounded() / 10,
            sessionsCount: monthSessions.count,
            currentStreak: streak,
            runDaysCount: uniqueRunDays.count,
            totalDurationSeconds: totalDuration,
            dailyCumulativePoints: cumulativePoints,
            pastMonthsSeries: pastSeries,
            averageHeartRate: avgHeartRate
        )
    }
    
    /// 당일 기준 최근 연속 달리기 일수(스트릭) 계산
    func calculateCurrentStreak(from allSessions: [RunSession]) -> Int {
        guard !allSessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 날짜별로 정렬된 고유한 운동 날짜 집합
        let runDays = Set(allSessions.map { calendar.startOfDay(for: $0.date) })
        
        var streak = 0
        var checkDate = today
        
        // 오늘 뛰었는지 체크. 오늘 안 뛰었으면 어제부터 스트릭 카운트 시작 (당일은 아직 뛸 수 있으므로)
        if !runDays.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            checkDate = yesterday
        }
        
        while runDays.contains(checkDate) {
            streak += 1
            guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDate
        }
        
        return streak
    }
    
    /// 캘린더용: 선택된 연/월의 특정 일자(day) 세션들 반환
    func sessions(for day: Int, in sessions: [RunSession]) -> [RunSession] {
        let calendar = Calendar.current
        return sessions.filter { session in
            let y = calendar.component(.year, from: session.date)
            let m = calendar.component(.month, from: session.date)
            let d = calendar.component(.day, from: session.date)
            return y == selectedYear && m == selectedMonth && d == day
        }
    }
    
    /// 캘린더용: 특정 일자의 총 달린 거리 합산
    func totalDistance(for day: Int, in sessions: [RunSession]) -> Double {
        let daySessions = self.sessions(for: day, in: sessions)
        let total = daySessions.reduce(0.0) { $0 + $1.distanceKm }
        return (total * 10).rounded() / 10
    }
    
    // MARK: - 히스토리 월별 추이 계산 (F-301 ~ F-306)
    
    /// 히스토리 기간(최근 12개월 또는 올해)에 대한 월별 성장 추이 요약 목록 반환 (과거 -> 현재 순서)
    func calculateHistorySummaries(
        from allSessions: [RunSession],
        period: HistoryPeriod = .twelveMonths,
        targetKm: Double = 100.0
    ) -> [MonthlyHistorySummary] {
        let calendar = Calendar.current
        var summaries: [MonthlyHistorySummary] = []
        
        let targetMonths: [(year: Int, month: Int)]
        
        switch period {
        case .thisYear:
            // 기준 연도(selectedYear)의 1월부터 선택된 월(selectedMonth)까지
            targetMonths = (1...selectedMonth).map { m in
                (year: selectedYear, month: m)
            }
        case .twelveMonths:
            var currentComps = DateComponents()
            currentComps.year = selectedYear
            currentComps.month = selectedMonth
            currentComps.day = 1
            let baseDate = calendar.date(from: currentComps) ?? Date()
            
            targetMonths = stride(from: -11, through: 0, by: 1).compactMap { offset in
                guard let targetDate = calendar.date(byAdding: .month, value: offset, to: baseDate) else { return nil }
                return (year: calendar.component(.year, from: targetDate),
                        month: calendar.component(.month, from: targetDate))
            }
        }
        
        for (y, m) in targetMonths {
            let monthSessions = allSessions.filter { session in
                let sy = calendar.component(.year, from: session.date)
                let sm = calendar.component(.month, from: session.date)
                return sy == y && sm == m
            }
            
            let totalKm = monthSessions.reduce(0.0) { $0 + $1.distanceKm }
            let totalDuration = monthSessions.reduce(0.0) { $0 + $1.durationSeconds }
            let uniqueRunDays = Set(monthSessions.map { calendar.component(.day, from: $0.date) }).count
            
            let hrValues = monthSessions.compactMap { $0.averageHeartRate }
            let avgHr: Int? = hrValues.isEmpty ? nil : Int((Double(hrValues.reduce(0, +)) / Double(hrValues.count)).rounded())
            
            summaries.append(MonthlyHistorySummary(
                year: y,
                month: m,
                targetKm: targetKm,
                totalDistanceKm: (totalKm * 10).rounded() / 10,
                sessionsCount: monthSessions.count,
                runDaysCount: uniqueRunDays,
                totalDurationSeconds: totalDuration,
                averageHeartRate: avgHr
            ))
        }
        
        return summaries
    }
    
    /// 하위 호환성을 위한 최근 N개월 요약 메서드
    func calculateHistorySummaries(from allSessions: [RunSession], monthsLimit: Int, targetKm: Double = 100.0) -> [MonthlyHistorySummary] {
        let calendar = Calendar.current
        var summaries: [MonthlyHistorySummary] = []
        
        var currentComps = DateComponents()
        currentComps.year = selectedYear
        currentComps.month = selectedMonth
        currentComps.day = 1
        let baseDate = calendar.date(from: currentComps) ?? Date()
        
        for offset in stride(from: -(monthsLimit - 1), through: 0, by: 1) {
            guard let targetDate = calendar.date(byAdding: .month, value: offset, to: baseDate) else { continue }
            let y = calendar.component(.year, from: targetDate)
            let m = calendar.component(.month, from: targetDate)
            
            let monthSessions = allSessions.filter { session in
                let sy = calendar.component(.year, from: session.date)
                let sm = calendar.component(.month, from: session.date)
                return sy == y && sm == m
            }
            
            let totalKm = monthSessions.reduce(0.0) { $0 + $1.distanceKm }
            let totalDuration = monthSessions.reduce(0.0) { $0 + $1.durationSeconds }
            let uniqueRunDays = Set(monthSessions.map { calendar.component(.day, from: $0.date) }).count
            
            let hrValues = monthSessions.compactMap { $0.averageHeartRate }
            let avgHr: Int? = hrValues.isEmpty ? nil : Int((Double(hrValues.reduce(0, +)) / Double(hrValues.count)).rounded())
            
            summaries.append(MonthlyHistorySummary(
                year: y,
                month: m,
                targetKm: targetKm,
                totalDistanceKm: (totalKm * 10).rounded() / 10,
                sessionsCount: monthSessions.count,
                runDaysCount: uniqueRunDays,
                totalDurationSeconds: totalDuration,
                averageHeartRate: avgHr
            ))
        }
        
        return summaries
    }
}
