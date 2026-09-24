//
//  RunSession.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import Foundation
import SwiftData

/// 단일 달리기 운동 세션 데이터 모델
@Model
final class RunSession {
    @Attribute(.unique) var id: UUID
    var date: Date                   // 운동 일시
    var distanceKm: Double           // 달린 거리 (km)
    var durationSeconds: TimeInterval // 운동 시간 (초)
    var memo: String?                // 러닝 메모 및 코스
    var isManual: Bool               // 수동 입력 여부 (false: HealthKit 동기화)
    var source: String               // 데이터 출처 ("Manual", "AppleHealth", "Garmin" 등)
    var averageHeartRate: Int?       // 평균 심박수 (bpm)
    var shoeId: UUID?                // 착용 러닝화 ID (nil: 기본 주력 신발 자동 계산 또는 미지정)
    
    init(
        id: UUID = UUID(),
        distanceKm: Double,
        date: Date = Date(),
        durationSeconds: TimeInterval = 0,
        memo: String? = nil,
        isManual: Bool = true,
        source: String = "Manual",
        averageHeartRate: Int? = nil,
        shoeId: UUID? = nil
    ) {
        self.id = id
        self.distanceKm = distanceKm
        self.date = date
        self.durationSeconds = durationSeconds
        self.memo = memo
        self.isManual = isManual
        self.source = source
        self.averageHeartRate = averageHeartRate
        self.shoeId = shoeId
    }
    
    /// 단일 세션의 평균 페이스 문자열 (예: "5:32/km")
    var paceString: String {
        guard distanceKm > 0 && durationSeconds > 0 else { return "-:--" }
        let secPerKm = durationSeconds / distanceKm
        let min = Int(secPerKm) / 60
        let sec = Int(secPerKm) % 60
        guard min < 60 else { return "-:--" }
        return String(format: "%d:%02d/km", min, sec)
    }
}
