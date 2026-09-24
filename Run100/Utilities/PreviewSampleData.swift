//
//  PreviewSampleData.swift
//  Run100
//
//  Xcode 프리뷰 및 시뮬레이터 테스트용 고품질 샘플 데이터 매니저
//

import Foundation
import SwiftData

/// Xcode Preview 및 테스트 환경을 위한 샘플 러닝 데이터 생성기
@MainActor
struct SampleData {
    /// 지정된 ModelContext에 최근 4개월(당월 + 과거 3개월)간의 사실적인 러닝 세션 데이터 일괄 삽입
    static func insertSampleSessions(into context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()
        let curYear = calendar.component(.year, from: today)
        let curMonth = calendar.component(.month, from: today)
        
        // MARK: - 1. 이번 달 (총 112.5km 초과 달성 세션들)
        let currentMonthConfigs: [(day: Int, km: Double, durationMinutes: Int, hr: Int, memo: String, source: String)] = [
            (2, 5.5, 31, 142, "상쾌한 아침 한강 조깅 🌅", "AppleHealth"),
            (5, 10.0, 52, 155, "퇴근길 10k 템포런", "AppleHealth"),
            (8, 7.2, 39, 148, "가벼운 회복 러닝", "Manual"),
            (11, 12.0, 63, 158, "주말 LSD 장거리 달리기", "AppleHealth"),
            (14, 8.8, 47, 150, "트랙 인터벌 페이스 훈련", "AppleHealth"),
            (17, 15.0, 79, 162, "남산 순환 업힐 코스 ⛰️", "AppleHealth"),
            (19, 10.0, 51, 156, "시원한 나이트 시티런 🌙", "AppleHealth"),
            (21, 14.0, 73, 160, "하프 마라톤 대비 지속주", "AppleHealth"),
            (23, 15.0, 78, 163, "100km 완주 돌파 레이스! 🏆", "AppleHealth"),
            (24, 15.0, 77, 164, "초과 달성 보너스 러닝 🔥", "AppleHealth")
        ]
        
        for config in currentMonthConfigs {
            var comp = DateComponents()
            comp.year = curYear
            comp.month = curMonth
            comp.day = config.day
            comp.hour = 7
            comp.minute = 30
            let date = calendar.date(from: comp) ?? today
            
            let session = RunSession(
                distanceKm: config.km,
                date: date,
                durationSeconds: TimeInterval(config.durationMinutes * 60),
                memo: config.memo,
                isManual: config.source == "Manual",
                source: config.source,
                averageHeartRate: config.hr
            )
            context.insert(session)
        }
        
        // MARK: - 2. 과거 3개월 데이터 (1달 전: 85km, 2달 전: 72.3km, 3달 전: 55km)
        let pastConfigs: [(offset: Int, configs: [(day: Int, km: Double, durationMinutes: Int, hr: Int, memo: String)])] = [
            // 1달 전 (총 85.0km)
            (-1, [
                (3, 8.0, 44, 146, "월초 몸풀기"),
                (6, 10.0, 54, 152, "퇴근 조깅"),
                (10, 12.0, 65, 158, "주말 LSD"),
                (13, 7.0, 38, 144, "회복 러닝"),
                (16, 15.0, 81, 161, "중거리 템포"),
                (20, 10.0, 52, 153, "시티런"),
                (24, 11.0, 59, 156, "야간 러닝"),
                (27, 12.0, 63, 157, "월말 스퍼트")
            ]),
            // 2달 전 (총 72.3km)
            (-2, [
                (4, 7.3, 41, 145, "조깅 스타트"),
                (8, 10.0, 55, 150, "한강 러닝"),
                (12, 12.0, 66, 158, "주말 달리기"),
                (16, 8.0, 44, 147, "가벼운 페이스"),
                (20, 15.0, 83, 163, "장거리 러닝"),
                (23, 10.0, 53, 152, "퇴근런"),
                (26, 10.0, 54, 154, "마무리 조깅")
            ]),
            // 3달 전 (총 55.0km)
            (-3, [
                (5, 5.0, 28, 140, "첫 러닝"),
                (9, 8.0, 45, 148, "공원 조깅"),
                (14, 10.0, 56, 152, "10k 첫 완주"),
                (18, 12.0, 68, 159, "주말 러닝"),
                (22, 10.0, 55, 153, "야간 조깅"),
                (27, 10.0, 54, 151, "월말 러닝")
            ])
        ]
        
        for past in pastConfigs {
            var monthComp = DateComponents()
            monthComp.year = curYear
            monthComp.month = curMonth + past.offset
            let targetMonthDate = calendar.date(from: monthComp) ?? today
            let pYear = calendar.component(.year, from: targetMonthDate)
            let pMonth = calendar.component(.month, from: targetMonthDate)
            
            for item in past.configs {
                var c = DateComponents()
                c.year = pYear
                c.month = pMonth
                c.day = item.day
                c.hour = 8
                c.minute = 0
                let date = calendar.date(from: c) ?? targetMonthDate
                
                let session = RunSession(
                    distanceKm: item.km,
                    date: date,
                    durationSeconds: TimeInterval(item.durationMinutes * 60),
                    memo: item.memo,
                    isManual: false,
                    source: "AppleHealth",
                    averageHeartRate: item.hr
                )
                context.insert(session)
            }
        }
        
        try? context.save()
    }
}

// MARK: - SwiftData ModelContainer Preview Extension

extension ModelContainer {
    /// Xcode Canvas #Preview 전용 완성형 인메모리 ModelContainer
    @MainActor
    static var preview: ModelContainer = {
        let schema = Schema([RunSession.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            SampleData.insertSampleSessions(into: container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()
}
