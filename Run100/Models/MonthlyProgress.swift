//
//  MonthlyProgress.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import Foundation

/// 이번 달 일자별 누적 러닝 거리 데이터 포인트 (라인 차트용)
struct DailyCumulativePoint: Identifiable, Equatable {
    var id: Int { day }
    let day: Int
    let cumulativeKm: Double
}

/// 과거 비교 월 누적 러닝 시리즈 (라인 차트용)
struct MonthComparisonSeries: Identifiable, Equatable {
    var id: String { "\(year)_\(month)" }
    let year: Int
    let month: Int
    let monthOffset: Int // -1, -2, -3
    let totalKm: Double
    let points: [DailyCumulativePoint]
}

/// 월간 100km 목표 진행 상황 및 역산 코칭 집계 모델
struct MonthlyProgress {
    let year: Int
    let month: Int
    var targetKm: Double = 100.0
    var totalAccumulatedKm: Double
    var sessionsCount: Int
    var currentStreak: Int
    var runDaysCount: Int
    var totalDurationSeconds: TimeInterval = 0
    var dailyCumulativePoints: [DailyCumulativePoint] = []
    var pastMonthsSeries: [MonthComparisonSeries] = []
    var averageHeartRate: Int? = nil
    
    // MARK: - 계산 프로퍼티
    
    /// 당월 평균 심박수 수치 (예: "152" 또는 "-")
    var heartRateValueOnly: String {
        guard let hr = averageHeartRate, hr > 0 else { return "-" }
        return "\(hr)"
    }
    
    /// 심박수 운동 강도 가이드 문구
    var heartRateStatusMessage: String {
        guard let hr = averageHeartRate, hr > 0 else {
            return "측정된 심박수 기록 없음"
        }
        if hr >= 165 {
            return "고강도 러닝 구간 🔥"
        } else if hr >= 145 {
            return "적정 유산소 심박 구간 🏃"
        } else {
            return "가벼운 회복 러닝 구간 🧘"
        }
    }
    
    /// 당월 평균 페이스 (예: "5:30/km", "6:00/km")
    var averagePaceString: String {
        guard totalAccumulatedKm > 0 && totalDurationSeconds > 0 else {
            return "-:--"
        }
        return "\(paceValueOnly)/km"
    }
    
    /// 당월 평균 페이스 수치 (예: "5:30")
    var paceValueOnly: String {
        guard totalAccumulatedKm > 0 && totalDurationSeconds > 0 else {
            return "-:--"
        }
        let secondsPerKm = totalDurationSeconds / totalAccumulatedKm
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        guard minutes < 60 else { return "-:--" }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// 당월 총 러닝 시간 요약 (예: "총 12시간 30분", "총 45분")
    var formattedTotalDuration: String {
        let totalSec = Int(totalDurationSeconds)
        let hours = totalSec / 3600
        let minutes = (totalSec % 3600) / 60
        if hours > 0 {
            return "총 \(hours)시간 \(minutes)분"
        } else if minutes > 0 {
            return "총 \(minutes)분"
        } else {
            return "0분"
        }
    }
    
    /// 이번 달 남은 거리 (km)
    var remainingKm: Double {
        max(targetKm - totalAccumulatedKm, 0.0)
    }
    
    /// 목표 초과 달성 여부 (0.05km 이상 초과)
    var isOverachieved: Bool {
        totalAccumulatedKm > targetKm + 0.05
    }
    
    /// 초과 달성 거리 (km)
    var excessKm: Double {
        max(totalAccumulatedKm - targetKm, 0.0)
    }
    
    /// 목표 달성 비율 (0.0 ~ 1.0)
    var progressRatio: Double {
        guard targetKm > 0 else { return 0.0 }
        return min(totalAccumulatedKm / targetKm, 1.0)
    }
    
    /// 목표 달성 퍼센트 (0 ~ 100%)
    var completionPercentage: Int {
        Int(progressRatio * 100)
    }
    
    /// 목표 달성 여부
    var isGoalAchieved: Bool {
        totalAccumulatedKm >= targetKm
    }
    
    /// 이번 달 전체 일수 (예: 9월은 30일)
    var totalDaysInMonth: Int {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
    
    /// 이번 달 남은 일수 (오늘 포함 당월 말일까지)
    var remainingDaysInMonth: Int {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        let currentDay = calendar.component(.day, from: today)
        
        // 과거 월인 경우 남은 일수는 0
        if year < currentYear || (year == currentYear && month < currentMonth) {
            return 0
        }
        // 미래 월인 경우 해당 월 전체 일수
        if year > currentYear || (year == currentYear && month > currentMonth) {
            return totalDaysInMonth
        }
        // 현재 월인 경우: 오늘 포함 말일까지의 일수
        return max(totalDaysInMonth - currentDay + 1, 1)
    }
    
    /// 💡 핵심 코칭: 오늘 권장 달리기 거리 (km)
    /// 남은 거리 / 남은 일수 (오늘 포함)
    var recommendedDailyKm: Double {
        guard !isGoalAchieved, remainingDaysInMonth > 0 else { return 0.0 }
        let daily = remainingKm / Double(remainingDaysInMonth)
        // 소수점 1자리로 반올림
        return (daily * 10).rounded() / 10
    }
    
    /// 동기부여 코칭 안내 문구
    var coachMessage: String {
        if isGoalAchieved {
            if isOverachieved {
                if remainingDaysInMonth == 0 {
                    return String(format: "%dkm를 넘어 총 %.1fkm로 한계를 완벽히 돌파했던 달입니다 🏆", Int(targetKm), totalAccumulatedKm)
                } else if excessKm < 10.0 {
                    return String(format: "%dkm 완주 후 +%.1fkm 보너스 질주! 한계를 넘어서는 중 🚀", Int(targetKm), excessKm)
                } else {
                    return String(format: "목표를 +%.1fkm 초과 달성! 놀라운 러닝 레전드입니다 🔥", excessKm)
                }
            } else {
                return remainingDaysInMonth == 0 ? "🎉 \(Int(targetKm))km 완주를 달성했던 멋진 달입니다!" : "🎉 이번 달 \(Int(targetKm))km 완주를 축하합니다!"
            }
        } else if remainingDaysInMonth == 0 {
            return "\(month)월 러닝 챌린지가 종료되었습니다."
        } else if remainingDaysInMonth == 1 {
            return String(format: "오늘 마지막 날! %.1fkm 달리고 %dkm를 완성하세요! 🔥", remainingKm, Int(targetKm))
        } else {
            return String(format: "남은 %d일 동안 하루 %.1fkm만 뛰면 %dkm 완주! 🏃", remainingDaysInMonth, recommendedDailyKm, Int(targetKm))
        }
    }
    
    // MARK: - 동기간(N일차) 누적 거리 경쟁 (과거의 나와 대결)
    
    /// 당월 오늘 일자 (동기간 비교 기준 Day)
    var currentCompareDay: Int {
        let calendar = Calendar.current
        let today = Date()
        let curYear = calendar.component(.year, from: today)
        let curMonth = calendar.component(.month, from: today)
        let curDay = calendar.component(.day, from: today)
        
        if year == curYear && month == curMonth {
            return min(curDay, totalDaysInMonth)
        } else if year < curYear || (year == curYear && month < curMonth) {
            return totalDaysInMonth
        } else {
            return 1
        }
    }
    
    /// 최근 3개월의 나와 동기간(N일차) 누적 거리 경쟁 목록 (거리 내림차순 정렬)
    var samePeriodComparisons: [SamePeriodGhostComparison] {
        let compareDay = currentCompareDay
        var items: [SamePeriodGhostComparison] = []
        
        // 당월 데이터
        items.append(SamePeriodGhostComparison(
            year: year,
            month: month,
            monthOffset: 0,
            cumulativeKm: totalAccumulatedKm,
            isCurrentMonth: true
        ))
        
        // 과거 최대 3개월치 데이터
        for series in pastMonthsSeries {
            let pastKm = series.points.first(where: { $0.day == compareDay })?.cumulativeKm
                ?? series.points.last(where: { $0.day <= compareDay })?.cumulativeKm
                ?? series.points.last?.cumulativeKm
                ?? 0.0
            
            items.append(SamePeriodGhostComparison(
                year: series.year,
                month: series.month,
                monthOffset: series.monthOffset,
                cumulativeKm: (pastKm * 10).rounded() / 10,
                isCurrentMonth: false
            ))
        }
        
        // 누적 거리 내림차순 정렬 (1위 ~ 4위)
        return items.sorted { $0.cumulativeKm > $1.cumulativeKm }
    }
    
    /// 현재 월의 순위 (1 ~ 4위)
    var currentMonthRank: Int {
        let sorted = samePeriodComparisons
        guard let index = sorted.firstIndex(where: { $0.isCurrentMonth }) else { return 1 }
        return index + 1
    }
    
    /// 직전 1개월 전(지난달) 동기간 대비 거리 차이 및 코칭 메시지
    var ghostCompetitionMessage: String {
        guard let lastMonth = pastMonthsSeries.first(where: { $0.monthOffset == -1 }) else {
            return "첫 번째 달 도전 중! 멋지게 달리고 있습니다 🏃"
        }
        let compareDay = currentCompareDay
        let lastMonthKm = lastMonth.points.first(where: { $0.day == compareDay })?.cumulativeKm
            ?? lastMonth.points.last(where: { $0.day <= compareDay })?.cumulativeKm
            ?? lastMonth.points.last?.cumulativeKm
            ?? 0.0
        
        // 1. 아직 이번 달 첫 러닝 전인 경우
        if totalAccumulatedKm < 0.05 {
            return "첫 러닝으로 과거의 나를 앞서보세요! 🏃"
        }
        
        // 2. 거리 차이 계산 (소수점 1자리)
        let diff = ((totalAccumulatedKm - lastMonthKm) * 10).rounded() / 10
        
        // 3. 차이가 0.5km 초과하여 앞서고 있을 때
        if diff > 0.5 {
            return String(format: "지난달 대비 +%.1fkm 🔥", diff)
        }
        // 4. 차이가 0.5km 초과하여 뒤처져 있을 때
        else if diff < -0.5 {
            return String(format: "지난달 대비 -%.1fkm 🏃", abs(diff))
        }
        // 5. ±0.5km 이내 팽팽한 접전일 때
        else {
            return "지난달과 팽팽한 접전 ⚡️"
        }
    }
}

/// 동기간(동일 일자) 누적 거리 경쟁 모델 (과거의 나와 대결)
struct SamePeriodGhostComparison: Identifiable, Equatable {
    var id: String { "\(year)_\(month)" }
    let year: Int
    let month: Int
    let monthOffset: Int // 0: 당월, -1, -2, -3
    let cumulativeKm: Double
    let isCurrentMonth: Bool
    
    var monthTitle: String {
        if isCurrentMonth {
            return "\(month)월 (현재)"
        } else {
            return "\(month)월"
        }
    }
}

