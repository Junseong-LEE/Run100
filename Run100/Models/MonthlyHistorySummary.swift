//
//  MonthlyHistorySummary.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import Foundation

/// 월별 러닝 성장 지표 분석 및 히스토리 요약 모델
/// 히스토리 조회 기간 (올해 vs 최근 12개월)
enum HistoryPeriod: String, CaseIterable, Identifiable {
    case twelveMonths = "최근 12개월"
    case thisYear = "올해"
    
    var id: String { rawValue }
    var title: String { rawValue }
}

struct MonthlyHistorySummary: Identifiable, Equatable {
    var id: String { "\(year)_\(month)" }
    let year: Int
    let month: Int
    var targetKm: Double = 100.0
    var totalDistanceKm: Double
    var sessionsCount: Int
    var runDaysCount: Int
    var totalDurationSeconds: TimeInterval
    var averageHeartRate: Int?
    
    // MARK: - 계산 프로퍼티
    
    /// 100km 목표 달성 여부
    var isGoalAchieved: Bool {
        totalDistanceKm >= targetKm
    }
    
    /// 목표 초과 달성 여부 (0.05km 이상 초과)
    var isOverachieved: Bool {
        totalDistanceKm > targetKm + 0.05
    }
    
    /// 초과 달성 거리 (km)
    var excessKm: Double {
        max(totalDistanceKm - targetKm, 0.0)
    }
    
    /// 월 레이블 (예: "9월")
    var monthLabel: String {
        "\(month)월"
    }
    
    /// 연/월 전체 레이블 (예: "2026년 9월")
    var yearMonthLabel: String {
        "\(year)년 \(month)월"
    }
    
    /// 해당 월의 총 일수 (출석률 계산용)
    var daysInMonth: Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        let calendar = Calendar.current
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
    
    /// 월간 러닝 출석률 (달린 날수 / 해당 월 일수, 백분율 %)
    var runAttendanceRate: Int {
        guard daysInMonth > 0 else { return 0 }
        let rate = (Double(runDaysCount) / Double(daysInMonth)) * 100.0
        return min(Int(rate.rounded()), 100)
    }
    
    /// 킬로미터당 평균 소요 시간 (초 단위)
    var averagePaceSeconds: Double? {
        guard totalDistanceKm > 0 && totalDurationSeconds > 0 else { return nil }
        return totalDurationSeconds / totalDistanceKm
    }
    
    /// 평균 페이스 표시용 문자열 (예: "5:30/km", "-:--")
    var averagePaceString: String {
        guard let paceSec = averagePaceSeconds else { return "-:--" }
        let minutes = Int(paceSec) / 60
        let seconds = Int(paceSec) % 60
        guard minutes < 60 else { return "-:--" }
        return String(format: "%d:%02d/km", minutes, seconds)
    }
    
    /// 평균 페이스 분:초 수치만 반환 (예: "5:30")
    var paceValueOnly: String {
        guard let paceSec = averagePaceSeconds else { return "-:--" }
        let minutes = Int(paceSec) / 60
        let seconds = Int(paceSec) % 60
        guard minutes < 60 else { return "-:--" }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// 평균 심박수 수치 문자열 (예: "152 bpm", "-")
    var heartRateDisplayString: String {
        guard let hr = averageHeartRate, hr > 0 else { return "-" }
        return "\(hr) bpm"
    }
    
    /// 총 운동 시간 요약 (예: "12시간 30분", "45분")
    var formattedTotalDuration: String {
        let totalSec = Int(totalDurationSeconds)
        let hours = totalSec / 3600
        let minutes = (totalSec % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if minutes > 0 {
            return "\(minutes)분"
        } else {
            return "0분"
        }
    }
}
