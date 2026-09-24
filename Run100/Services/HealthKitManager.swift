//
//  HealthKitManager.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import Foundation
import HealthKit
import SwiftData
import SwiftUI

/// 건강 데이터 동기화 결과 요약 모델
struct HealthSyncResult {
    let newSessionsCount: Int
    let totalKmAdded: Double
    let message: String
}

/// Apple HealthKit과의 연동 및 워크아웃 데이터 동기화를 총괄 관리하는 매니저
@Observable
@MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    var isSyncing: Bool = false
    var lastSyncDate: Date? {
        didSet {
            if let date = lastSyncDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "lastHealthSyncTimestamp")
            }
        }
    }
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    init() {
        let savedTimestamp = UserDefaults.standard.double(forKey: "lastHealthSyncTimestamp")
        if savedTimestamp > 0 {
            self.lastSyncDate = Date(timeIntervalSince1970: savedTimestamp)
        }
    }
    
    // MARK: - 권한 요청
    
    /// 달리기 워크아웃 및 러닝/워킹 거리 데이터 읽기 권한 요청
    func requestAuthorization() async throws -> Bool {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    // MARK: - 워크아웃 쿼리 & SwiftData 동기화
    
    /// 당월(또는 지정된 기간)의 달리기 워크아웃을 HealthKit에서 가져와 SwiftData에 중복 없이 동기화
    /// - Parameters:
    ///   - modelContext: SwiftData 모델 컨텍스트
    ///   - existingSessions: 이미 로컬에 저장된 RunSession 목록 (UUID 중복 대조용)
    ///   - startDate: 동기화 시작 일시 (기본: 당월 1일 00:00:00)
    /// - Returns: 새로 추가된 세션 수 및 총 거리 정보를 담은 동기화 결과
    @discardableResult
    func syncWorkouts(
        with modelContext: ModelContext,
        existingSessions: [RunSession],
        startDate: Date? = nil
    ) async throws -> HealthSyncResult {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. 권한 확인 및 요청
        _ = try await requestAuthorization()
        
        // 2. 동기화 조회 기간 설정 (기본: 최근 1년 전 1일부터 조회하여 과월 데이터도 완벽 동기화)
        let calendar = Calendar.current
        let queryStartDate: Date
        if let startDate = startDate {
            queryStartDate = startDate
        } else {
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date().addingTimeInterval(-365 * 86400)
            let components = calendar.dateComponents([.year, .month], from: oneYearAgo)
            queryStartDate = calendar.date(from: components) ?? oneYearAgo
        }
        
        // 3. 워크아웃 쿼리 실행 (달리기 워크아웃만 필터링)
        let workouts = try await fetchRunningWorkouts(since: queryStartDate)
        
        // 4. 기존 세션 매핑 (신규 추가 및 기존 세션 심박수 백필용)
        let existingSessionMap = Dictionary(uniqueKeysWithValues: existingSessions.map { ($0.id, $0) })
        var newSessionsCount = 0
        var updatedHeartRateCount = 0
        var totalKmAdded: Double = 0.0
        
        for workout in workouts {
            // 이미 존재하는 세션인 경우: 심박수가 비어있다면 백필(Backfill) 업데이트
            if let existing = existingSessionMap[workout.uuid] {
                if existing.averageHeartRate == nil {
                    if let hr = await fetchAverageHeartRate(for: workout) {
                        existing.averageHeartRate = hr
                        updatedHeartRateCount += 1
                    }
                }
                continue
            }
            
            // 신규 세션인 경우
            // 거리 추출 (km 단위 환산)
            let distanceInMeters = workout.totalDistance?.doubleValue(for: .meter()) ?? 0.0
            guard distanceInMeters > 50 else { continue } // 50m 이하의 극소 측정 기록 제외
            
            let distanceKm = (distanceInMeters / 1000.0 * 10).rounded() / 10
            
            // 메모 생성 (출처 기기 정보 등)
            let deviceName = workout.sourceRevision.source.name
            let memoText = "\(deviceName) 러닝"
            
            // 심박수 추출 (1차 통계 + 2차 Fallback 쿼리)
            let avgHeartRate = await fetchAverageHeartRate(for: workout)
            
            let newSession = RunSession(
                id: workout.uuid,
                distanceKm: distanceKm,
                date: workout.startDate,
                durationSeconds: workout.duration,
                memo: memoText,
                isManual: false,
                source: "AppleHealth",
                averageHeartRate: avgHeartRate
            )
            
            modelContext.insert(newSession)
            newSessionsCount += 1
            totalKmAdded += distanceKm
        }
        
        // SwiftData 변경사항 저장
        if newSessionsCount > 0 || updatedHeartRateCount > 0 {
            try? modelContext.save()
        }
        
        let finalKm = (totalKmAdded * 10).rounded() / 10
        self.lastSyncDate = Date()
        
        let message: String
        if newSessionsCount > 0 && updatedHeartRateCount > 0 {
            message = "\(newSessionsCount)건 기록(+\(String(format: "%.1f", finalKm))km) 및 심박수 \(updatedHeartRateCount)건 동기화 완료!"
        } else if newSessionsCount > 0 {
            message = "\(newSessionsCount)건의 러닝 기록(+\(String(format: "%.1f", finalKm))km)을 동기화했습니다!"
        } else if updatedHeartRateCount > 0 {
            message = "기존 러닝 기록 \(updatedHeartRateCount)건의 심박수 정보를 최신으로 업데이트했습니다!"
        } else {
            message = "새로운 러닝 기록이 없거나 이미 모두 최신 상태입니다."
        }
        
        return HealthSyncResult(
            newSessionsCount: newSessionsCount,
            totalKmAdded: finalKm,
            message: message
        )
    }
    
    // MARK: - 심박수 추출 헬퍼 (1차: workout.statistics, 2차 Fallback: 워크아웃 구간 HKStatisticsQuery)
    
    /// 특정 워크아웃의 평균 심박수 추출
    private func fetchAverageHeartRate(for workout: HKWorkout) async -> Int? {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        
        // 1차: workout.statistics(for:) 확인
        if let stats = workout.statistics(for: hrType),
           let avgQuantity = stats.averageQuantity() {
            let bpm = avgQuantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            let rounded = Int(bpm.rounded())
            if rounded > 30 && rounded < 250 {
                return rounded
            }
        }
        
        // 2차 Fallback: 서드파티 앱(NRC, Strava, Garmin 등) 또는 통계 미포함 워크아웃을 위한 구간 쿼리
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                if let avg = statistics?.averageQuantity() {
                    let bpm = avg.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    let rounded = Int(bpm.rounded())
                    continuation.resume(returning: (rounded > 30 && rounded < 250) ? rounded : nil)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            self.healthStore.execute(query)
        }
    }
    
    /// 지정된 시작일 이후의 달리기(Running) 워크아웃 쿼리
    private func fetchRunningWorkouts(since startDate: Date) async throws -> [HKWorkout] {
        let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [runningPredicate, datePredicate])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 시뮬레이터 및 테스트용 샘플 동기화 지원
    
    /// 시뮬레이터 또는 테스트 환경에서 동기화 동작을 시연/검증할 수 있는 샘플 건강 데이터 생성 기능
    func addSampleHealthWorkout(
        with modelContext: ModelContext,
        existingSessions: [RunSession],
        targetYear: Int? = nil,
        targetMonth: Int? = nil
    ) -> HealthSyncResult {
        let sampleDistances: [Double] = [5.2, 7.0, 4.5, 10.0, 6.3]
        let randomDistance = sampleDistances.randomElement() ?? 5.0
        let randomDuration: TimeInterval = randomDistance * 360 // 약 6분 페이스
        
        let calendar = Calendar.current
        let sessionDate: Date
        if let targetYear = targetYear, let targetMonth = targetMonth {
            var components = DateComponents()
            components.year = targetYear
            components.month = targetMonth
            let maxDay = calendar.range(of: .day, in: .month, for: calendar.date(from: components) ?? Date())?.count ?? 28
            components.day = min(15, maxDay)
            components.hour = 7
            components.minute = 30
            sessionDate = calendar.date(from: components) ?? Date()
        } else {
            sessionDate = Date()
        }
        
        let newSession = RunSession(
            id: UUID(),
            distanceKm: randomDistance,
            date: sessionDate,
            durationSeconds: randomDuration,
            memo: "Apple Watch 울트라 러닝",
            isManual: false,
            source: "AppleHealth",
            averageHeartRate: Int.random(in: 145...165)
        )
        
        modelContext.insert(newSession)
        try? modelContext.save()
        self.lastSyncDate = Date()
        
        return HealthSyncResult(
            newSessionsCount: 1,
            totalKmAdded: randomDistance,
            message: "애플 워치 샘플 러닝(+\(String(format: "%.1f", randomDistance))km)이 정상 동기화되었습니다!"
        )
    }
}

// MARK: - 에러 타입 정의

enum HealthKitError: LocalizedError {
    case notAvailable
    case permissionDenied
    case queryFailed
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "이 기기에서는 Apple HealthKit을 지원하지 않습니다."
        case .permissionDenied:
            return "애플 건강 데이터 읽기 권한이 허용되지 않았습니다. [설정 > 건강 > 데이터 접근 및 기기]에서 권한을 확인해 주세요."
        case .queryFailed:
            return "건강 데이터를 불러오는 중 오류가 발생했습니다."
        }
    }
}
