//
//  WidgetDataBridge.swift
//  Run100Widget
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
    
    // MARK: - 화면 테마 모드 ("dark", "light", "system")
    var appTheme: String = "dark"
    
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

/// 위젯 프로세스에서 최신 스냅샷 데이터를 읽어오는 브리지 클래스
final class WidgetDataBridge {
    static let shared = WidgetDataBridge()
    
    private let appGroupIdentifier = "group.com.sigpoby.Run100"
    private let snapshotKey = "run100_widget_snapshot_data"
    
    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? UserDefaults.standard
    }
    
    private init() {}
    
    // MARK: - 스냅샷 로드
    
    /// 위젯 타임라인에서 표시할 최신 스냅샷 로드
    func loadSnapshot() -> WidgetSnapshotData {
        if let data = sharedDefaults.data(forKey: snapshotKey) ?? UserDefaults.standard.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetSnapshotData.self, from: data) {
            return snapshot
        }
        return .placeholder
    }
}
