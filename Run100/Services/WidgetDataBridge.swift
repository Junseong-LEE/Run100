//
//  WidgetDataBridge.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import Foundation
import WidgetKit

/// 위젯의 최근 7일 잔디 심기 도트 데이터 모델
struct WidgetDayStatus: Codable, Identifiable {
    var id: String { dayLabel }
    let dayLabel: String     // 예: "월", "화", "수"
    let distanceKm: Double   // 당일 달린 거리 (km)
    let colorLevel: Int      // 0: 휴식, 1: 0.1~4.9km, 2: 5.0~9.9km, 3: 10km+
    let isToday: Bool
}

/// 위젯에 표시할 100km 진행 상황 및 일일 코칭 스냅샷 데이터
struct WidgetSnapshotData: Codable {
    let targetKm: Double
    let totalAccumulatedKm: Double
    let remainingKm: Double
    let completionPercentage: Int
    let recommendedDailyKm: Double
    let remainingDaysInMonth: Int
    let currentStreak: Int
    let recent7Days: [WidgetDayStatus]
    let lastUpdated: Date
    
    // MARK: - F-102 히어로 카드 일체형 정보 (평균 페이스 & 심박수)
    var paceValueOnly: String = "-:--"
    var formattedTotalDuration: String = "0분"
    var sessionsCount: Int = 0
    var heartRateValueOnly: String = "-"
    var heartRateStatusMessage: String = "측정된 심박수 기록 없음"
    
    /// 위젯 갤러리 및 로드 실패 시 노출할 기본 플레이스홀더 데이터
    static var placeholder: WidgetSnapshotData {
        let sample7Days: [WidgetDayStatus] = [
            WidgetDayStatus(dayLabel: "월", distanceKm: 5.0, colorLevel: 2, isToday: false),
            WidgetDayStatus(dayLabel: "화", distanceKm: 0.0, colorLevel: 0, isToday: false),
            WidgetDayStatus(dayLabel: "수", distanceKm: 6.2, colorLevel: 2, isToday: false),
            WidgetDayStatus(dayLabel: "목", distanceKm: 4.5, colorLevel: 1, isToday: false),
            WidgetDayStatus(dayLabel: "금", distanceKm: 0.0, colorLevel: 0, isToday: false),
            WidgetDayStatus(dayLabel: "토", distanceKm: 10.5, colorLevel: 3, isToday: false),
            WidgetDayStatus(dayLabel: "일", distanceKm: 3.5, colorLevel: 1, isToday: true)
        ]
        
        return WidgetSnapshotData(
            targetKm: 100.0,
            totalAccumulatedKm: 68.0,
            remainingKm: 32.0,
            completionPercentage: 68,
            recommendedDailyKm: 3.5,
            remainingDaysInMonth: 9,
            currentStreak: 4,
            recent7Days: sample7Days,
            lastUpdated: Date(),
            paceValueOnly: "5:30",
            formattedTotalDuration: "총 6시간 14분",
            sessionsCount: 12,
            heartRateValueOnly: "152",
            heartRateStatusMessage: "적정 유산소 심박 구간 🏃"
        )
    }
}

/// 앱 본체와 위젯 프로세스 간 데이터 동기화를 전담하는 브리지 클래스
final class WidgetDataBridge {
    static let shared = WidgetDataBridge()
    
    /// App Group Identifier (필요 시 Xcode Signing & Capabilities에서 App Group 활성화 가능)
    private let appGroupIdentifier = "group.com.sigpoby.Run100"
    private let snapshotKey = "run100_widget_snapshot_data"
    
    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? UserDefaults.standard
    }
    
    private init() {}
    
    // MARK: - 스냅샷 저장 및 위젯 리로드
    
    /// 앱의 최신 진행 상황과 세션 데이터를 위젯 공유 저장소에 저장하고 위젯 타임라인 즉시 리로드
    func updateSnapshot(from progress: MonthlyProgress, allSessions: [RunSession]) {
        let recent7Days = generateRecent7DaysData(from: allSessions)
        
        let snapshot = WidgetSnapshotData(
            targetKm: progress.targetKm,
            totalAccumulatedKm: progress.totalAccumulatedKm,
            remainingKm: progress.remainingKm,
            completionPercentage: progress.completionPercentage,
            recommendedDailyKm: progress.recommendedDailyKm,
            remainingDaysInMonth: progress.remainingDaysInMonth,
            currentStreak: progress.currentStreak,
            recent7Days: recent7Days,
            lastUpdated: Date(),
            paceValueOnly: progress.paceValueOnly,
            formattedTotalDuration: progress.formattedTotalDuration,
            sessionsCount: progress.sessionsCount,
            heartRateValueOnly: progress.heartRateValueOnly,
            heartRateStatusMessage: progress.heartRateStatusMessage
        )
        
        if let encoded = try? JSONEncoder().encode(snapshot) {
            sharedDefaults.set(encoded, forKey: snapshotKey)
            // 표준 UserDefaults에도 백업 저장
            UserDefaults.standard.set(encoded, forKey: snapshotKey)
        }
        
        // 위젯 타임라인 즉시 새로고침 요청
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - 스냅샷 로드
    
    /// 위젯 타임라인에서 표시할 최신 스냅샷 로드
    func loadSnapshot() -> WidgetSnapshotData {
        if let data = sharedDefaults.data(forKey: snapshotKey) ?? UserDefaults.standard.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetSnapshotData.self, from: data) {
            return snapshot
        }
        return .placeholder
    }
    
    // MARK: - 최근 7일 잔디 심기 데이터 생성
    
    private func generateRecent7DaysData(from allSessions: [RunSession]) -> [WidgetDayStatus] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
        
        var result: [WidgetDayStatus] = []
        
        // 6일 전부터 오늘까지 총 7일 순회
        for dayOffset in stride(from: -6, through: 0, by: 1) {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            let weekdayIndex = calendar.component(.weekday, from: targetDate) - 1
            let dayLabel = weekdaySymbols[max(0, min(weekdayIndex, 6))]
            
            // 해당 날짜의 세션 거리 합산
            let daySessions = allSessions.filter {
                calendar.isDate($0.date, inSameDayAs: targetDate)
            }
            let totalKm = daySessions.reduce(0.0) { $0 + $1.distanceKm }
            let roundedKm = (totalKm * 10).rounded() / 10
            
            // 잔디 색상 레벨 매핑
            let colorLevel: Int
            if roundedKm <= 0.0 {
                colorLevel = 0
            } else if roundedKm < 5.0 {
                colorLevel = 1
            } else if roundedKm < 10.0 {
                colorLevel = 2
            } else {
                colorLevel = 3
            }
            
            let isToday = (dayOffset == 0)
            result.append(WidgetDayStatus(dayLabel: dayLabel, distanceKm: roundedKm, colorLevel: colorLevel, isToday: isToday))
        }
        
        return result
    }
}
