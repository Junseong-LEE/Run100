//
//  RunningShoe.swift
//  Run100
//
//  Created by 이준성 on 9/24/26.
//

import Foundation
import SwiftData
import SwiftUI

/// 러닝화 유형 (카테고리별 권장 수명 프리셋)
enum ShoeType: String, Codable, CaseIterable {
    case cushion = "daily_cushion" // 데일리 쿠션화 / 안정화
    case tempo = "tempo_speed"     // 템포 / 스피드 훈련화
    case race = "carbon_race"      // 카본 레이싱화
    
    var title: String {
        switch self {
        case .cushion: return "데일리 쿠션화"
        case .tempo: return "템포 / 훈련화"
        case .race: return "카본 레이싱화"
        }
    }
    
    var subtitle: String {
        switch self {
        case .cushion: return "안정성 & 충격 흡수"
        case .tempo: return "경량 스피드 & 인터벌"
        case .race: return "초경량 고반발 대회용"
        }
    }
    
    var icon: String {
        switch self {
        case .cushion: return "figure.run"
        case .tempo: return "bolt.fill"
        case .race: return "flame.fill"
        }
    }
    
    var defaultLifespanKm: Double {
        switch self {
        case .cushion: return 600.0
        case .tempo: return 500.0
        case .race: return 300.0
        }
    }
}

/// 러닝화 소모 및 건강 상태
enum ShoeHealthStatus {
    case optimal    // 0% ~ 60%
    case moderate   // 61% ~ 85%
    case warning    // 86% ~ 100%
    case expired    // 100% 초과
    
    var label: String {
        switch self {
        case .optimal: return "최상"
        case .moderate: return "적정"
        case .warning: return "교체 준비"
        case .expired: return "수명 완료"
        }
    }
    
    var description: String {
        switch self {
        case .optimal: return "쿠션과 반발력이 최상의 상태입니다."
        case .moderate: return "미드솔 마모가 정상 진행 중입니다."
        case .warning: return "쿠션 탄성이 저하되어 새 신발 준비를 권장합니다."
        case .expired: return "미드솔 기능이 소진되었습니다. 관절 보호를 위해 교체해주세요."
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .optimal: return Color.green
        case .moderate: return Color.yellow
        case .warning: return Color.orange
        case .expired: return Color.red
        }
    }
}

/// 러닝화 데이터 모델
@Model
final class RunningShoe {
    @Attribute(.unique) var id: UUID
    var name: String                     // 모델명 (예: "페가수스 41", "인피니티 4")
    var brand: String                    // 브랜드 (예: "나이키", "아식스", "아디다스")
    var shoeTypeRaw: String              // ShoeType rawValue
    var targetLifespanKm: Double         // 목표 수명 거리 (기본값: 카테고리 프리셋 or 사용자 지정)
    var initialDistanceKm: Double        // 등록 전 이미 달렸던 누적 거리 (km)
    var startDate: Date                  // 착용 시작일
    var isActive: Bool                   // 현재 신고 있는 주력 러닝화 여부
    var isRetired: Bool                  // 은퇴 / 보관함 이동 여부
    var retiredDate: Date?               // 은퇴 날짜
    var retiredTotalDistanceKm: Double?  // 은퇴 시점 최종 누적 거리
    var memo: String?                    // 메모
    
    init(
        id: UUID = UUID(),
        name: String,
        brand: String = "",
        shoeType: ShoeType = .cushion,
        targetLifespanKm: Double = 600.0,
        initialDistanceKm: Double = 0.0,
        startDate: Date = Date(),
        isActive: Bool = true,
        isRetired: Bool = false,
        memo: String? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.shoeTypeRaw = shoeType.rawValue
        self.targetLifespanKm = targetLifespanKm
        self.initialDistanceKm = initialDistanceKm
        self.startDate = startDate
        self.isActive = isActive
        self.isRetired = isRetired
        self.memo = memo
    }
    
    var shoeType: ShoeType {
        get { ShoeType(rawValue: shoeTypeRaw) ?? .cushion }
        set { shoeTypeRaw = newValue.rawValue }
    }
    
    /// 세션 기록들을 기반으로 총 누적 거리 계산 (러닝화 로테이션 정밀 지원)
    func calculateTotalDistance(from sessions: [RunSession]) -> Double {
        if isRetired, let fixed = retiredTotalDistanceKm {
            return fixed
        }
        
        let startOfDay = Calendar.current.startOfDay(for: startDate)
        let sessionDistance = sessions.filter { session in
            if let assignedId = session.shoeId {
                // 특정 신발이 지정된 세션 -> 해당 신발 ID와 일치할 때만 누적
                return assignedId == self.id
            } else {
                // 신발이 별도 지정되지 않은 세션 -> 현재 주력 신발이고 착용 시작일 이후일 때 자동 누적
                return self.isActive && session.date >= startOfDay
            }
        }.reduce(0.0) { $0 + $1.distanceKm }
        
        return initialDistanceKm + sessionDistance
    }
    
    /// 소모율 (0.0 ~ 1.0+)
    func wearRate(from sessions: [RunSession]) -> Double {
        guard targetLifespanKm > 0 else { return 0 }
        return calculateTotalDistance(from: sessions) / targetLifespanKm
    }
    
    /// 건강 상태 판별
    func healthStatus(from sessions: [RunSession]) -> ShoeHealthStatus {
        let rate = wearRate(from: sessions)
        if rate <= 0.60 {
            return .optimal
        } else if rate <= 0.85 {
            return .moderate
        } else if rate <= 1.00 {
            return .warning
        } else {
            return .expired
        }
    }
    
    /// 남은 거리 (km)
    func remainingKm(from sessions: [RunSession]) -> Double {
        max(0.0, targetLifespanKm - calculateTotalDistance(from: sessions))
    }
}
