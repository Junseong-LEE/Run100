//
//  HeatmapGridView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI

/// 30일 잔디 심기 히트맵 그리드 컴포넌트 (월~일 7열)
struct HeatmapGridView: View {
    let year: Int
    let month: Int
    let totalDays: Int
    var currentStreak: Int = 0
    let sessions: [RunSession]
    @Binding var selectedDay: Int
    let onSelectDay: (Int) -> Void
    
    private let weekDaySymbols = ["월", "화", "수", "목", "금", "토", "일"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    
    // 그리드 아이템 식별 모델 (빈 셀과 날짜 셀의 ID 중복 원천 차단)
    private enum GridItemType: Identifiable {
        case empty(id: String)
        case day(id: String, number: Int)
        
        var id: String {
            switch self {
            case .empty(let id): return id
            case .day(let id, _): return id
            }
        }
    }
    
    // 이번 달 1일의 요일 오프셋 (0 = 월요일, 6 = 일요일)
    private var firstDayWeekdayOffset: Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        comps.hour = 12 // 자정/타임존 경계 문제 방지
        let calendar = Calendar.current
        guard let firstDate = calendar.date(from: comps) else { return 0 }
        
        // Calendar weekday: 1 = 일요일, 2 = 월요일, ... 7 = 토요일
        let weekday = calendar.component(.weekday, from: firstDate)
        // 월요일을 0으로 변환: 일(1)->6, 월(2)->0, 화(3)->1, 수(4)->2, 목(5)->3, 금(6)->4, 토(7)->5
        return (weekday + 5) % 7
    }
    
    // 그리드 전체 아이템 목록 (빈 오프셋 셀 + 날짜 셀 순서대로 일원화)
    private var gridItems: [GridItemType] {
        var items: [GridItemType] = []
        for i in 0..<firstDayWeekdayOffset {
            items.append(.empty(id: "empty_\(year)_\(month)_\(i)"))
        }
        for d in 1...totalDays {
            items.append(.day(id: "day_\(year)_\(month)_\(d)", number: d))
        }
        return items
    }
    
    // 오늘 일자
    private var currentDay: Int? {
        let calendar = Calendar.current
        let today = Date()
        let y = calendar.component(.year, from: today)
        let m = calendar.component(.month, from: today)
        if y == year && m == month {
            return calendar.component(.day, from: today)
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // 상단 타이틀 & 연속 스트릭 배지 & 히트맵 범례
            HStack(spacing: 8) {
                Text("\(month)월 출석체크")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                
                // 연속 스트릭 배지 (기능 F-202 잔디 심기 상단으로 이동)
                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.system(size: 10))
                    Text("\(currentStreak)일 연속")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.orange)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
                
                Spacer()
                
                // 범례 (Legend)
                HStack(spacing: 3) {
                    Text("휴식")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(width: 10, height: 10)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.orange.opacity(0.35))
                        .frame(width: 10, height: 10)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.98, green: 0.75, blue: 0.14))
                        .frame(width: 10, height: 10)
                    
                    Text("10k+")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.orange)
                }
            }
            
            // 요일 헤더 (월~일)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekDaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                }
            }
            
            // 날짜 그리드 매트릭스 (고유 ID 모델 및 월 단위 뷰 리셋으로 셀 재사용 버그 방지)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(gridItems) { item in
                    switch item {
                    case .empty:
                        Color.clear
                            .frame(height: 44)
                    case .day(_, let day):
                        let distance = totalDistance(for: day)
                        let isToday = (currentDay == day)
                        let isSelected = (selectedDay == day)
                        let isFuture = (currentDay != nil && day > (currentDay ?? 0))
                        
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedDay = day
                            onSelectDay(day)
                        } label: {
                            HeatmapCellView(
                                day: day,
                                distanceKm: distance,
                                isToday: isToday,
                                isSelected: isSelected,
                                isFuture: isFuture
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .id("\(year)-\(month)") // 연/월 변경 시 전체 그리드를 새롭게 리빌드
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
    
    private func totalDistance(for day: Int) -> Double {
        let calendar = Calendar.current
        let daySessions = sessions.filter { session in
            let y = calendar.component(.year, from: session.date)
            let m = calendar.component(.month, from: session.date)
            let d = calendar.component(.day, from: session.date)
            return y == year && m == month && d == day
        }
        let sum = daySessions.reduce(0.0) { $0 + $1.distanceKm }
        return (sum * 10).rounded() / 10
    }
}

#Preview {
    HeatmapGridView(
        year: 2026,
        month: 9,
        totalDays: 30,
        sessions: [],
        selectedDay: .constant(14),
        onSelectDay: { _ in }
    )
    .padding()
}
