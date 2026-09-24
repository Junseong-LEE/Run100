//
//  DailyDistanceChartView.swift
//  Run100
//
//  Created by 이준성 on 9/24/26.
//

import SwiftUI

/// 기능 F-204: 캘린더 탭 일별 러닝 거리 막대 차트 (Daily Distance Bar Chart)
/// 1일부터 말일까지 일자별 달린 거리(km)를 시각화하고, 탭/드래그 시 선택 일자(selectedDay)와 실시간 연동
struct DailyDistanceChartView: View {
    let year: Int
    let month: Int
    let totalDays: Int
    let sessions: [RunSession]
    @Binding var selectedDay: Int
    
    // 일자별 달린 거리 데이터 포인트
    private var dailyPoints: [DailyBarPoint] {
        let calendar = Calendar.current
        
        // 당월 세션 필터링
        let monthSessions = sessions.filter { session in
            let y = calendar.component(.year, from: session.date)
            let m = calendar.component(.month, from: session.date)
            return y == year && m == month
        }
        
        // 일자별(1...totalDays) 누적 거리 맵 생성
        var dayDistanceMap: [Int: Double] = [:]
        for session in monthSessions {
            let d = calendar.component(.day, from: session.date)
            dayDistanceMap[d, default: 0.0] += session.distanceKm
        }
        
        return (1...totalDays).map { day in
            DailyBarPoint(
                day: day,
                distanceKm: dayDistanceMap[day] ?? 0.0
            )
        }
    }
    
    // 이번 달 최장 러닝 일자 및 거리
    private var bestDayPoint: DailyBarPoint? {
        dailyPoints.filter { $0.distanceKm > 0 }
            .max(by: { $0.distanceKm < $1.distanceKm })
    }
    
    // 이번 달 달린 날들의 평균 주행거리
    private var averageKm: Double {
        let runDays = dailyPoints.filter { $0.distanceKm > 0 }
        guard !runDays.isEmpty else { return 0.0 }
        let total = runDays.reduce(0.0) { $0 + $1.distanceKm }
        return total / Double(runDays.count)
    }
    
    // 차트 Y축 최대치 (최소 10km 보장 및 여유 15%)
    private var maxDistanceY: Double {
        let maxVal = dailyPoints.map(\.distanceKm).max() ?? 0.0
        return max(maxVal * 1.15, 10.0)
    }
    
    // 현재 선택된 날짜의 달린 거리
    private var selectedDayDistance: Double {
        dailyPoints.first(where: { $0.day == selectedDay })?.distanceKm ?? 0.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - 1. 차트 헤더 (타이틀 & 최고 기록 뱃지)
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.orange)
                    
                    Text("\(month)월 일별 러닝")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // 최고 기록 뱃지
                if let best = bestDayPoint, best.distanceKm > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.yellow)
                        Text(String(format: "최고 %.1fkm (%d일)", best.distanceKm, best.day))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.orange)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            // MARK: - 2. 선택된 날짜 피드백 서브 헤더
            HStack(spacing: 6) {
                Text("\(selectedDay)일:")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if selectedDayDistance > 0 {
                    Text(String(format: "%.1f km 완주", selectedDayDistance))
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.orange)
                } else {
                    Text("휴식 Day")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if averageKm > 0 {
                    Text(String(format: "달린 날 평균 %.1fkm", averageKm))
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemFill).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            // MARK: - 3. 커스텀 일별 막대 차트 (안정적 렌더링 & 스크러빙 인터랙션)
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    let chartHeight: CGFloat = 90
                    let totalWidth = geometry.size.width
                    let dayWidth = totalWidth / CGFloat(max(totalDays, 1))
                    
                    ZStack(alignment: .bottomLeading) {
                        // 1) 배경 수평 가이드선 (50%, 100%)
                        VStack(spacing: 0) {
                            HStack {
                                Text(String(format: "%.0fk", maxDistanceY))
                                    .font(.system(size: 8, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.secondary.opacity(0.4))
                                Line()
                                    .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                    .foregroundStyle(Color.secondary.opacity(0.2))
                                    .frame(height: 1)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Text(String(format: "%.0fk", maxDistanceY / 2))
                                    .font(.system(size: 8, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.secondary.opacity(0.4))
                                Line()
                                    .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                    .foregroundStyle(Color.secondary.opacity(0.2))
                                    .frame(height: 1)
                            }
                            
                            Spacer()
                            
                            // 베이스라인
                            Rectangle()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 1)
                        }
                        .frame(height: chartHeight)
                        
                        // 2) 선택 일자 하이라이트 배경 컬럼
                        let selIndex = CGFloat(max(min(selectedDay, totalDays), 1) - 1)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: max(dayWidth + 2, 8), height: chartHeight + 10)
                            .offset(x: selIndex * dayWidth - 1, y: 0)
                            .animation(.easeInOut(duration: 0.15), value: selectedDay)
                        
                        // 3) 1일부터 말일까지 일자별 막대 렌더링
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(dailyPoints) { point in
                                let isSelected = point.day == selectedDay
                                let barRatio = CGFloat(min(point.distanceKm / maxDistanceY, 1.0))
                                let barH = max(barRatio * chartHeight, point.distanceKm > 0 ? 5 : 2)
                                
                                VStack(spacing: 2) {
                                    // 선택된 날짜에 거리가 있으면 상단에 미니 뱃지 표시
                                    if isSelected && point.distanceKm > 0 {
                                        Text(String(format: "%.1f", point.distanceKm))
                                            .font(.system(size: 8, weight: .black, design: .rounded))
                                            .foregroundStyle(Color.orange)
                                            .lineLimit(1)
                                            .fixedSize()
                                    }
                                    
                                    // 막대 본체
                                    Capsule()
                                        .fill(
                                            isSelected
                                                ? LinearGradient(
                                                    colors: [Color.yellow, Color.orange],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                                : (point.distanceKm > 0
                                                    ? LinearGradient(
                                                        colors: [Color.orange.opacity(0.9), Color.orange.opacity(0.45)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                    : LinearGradient(
                                                        colors: [Color.secondary.opacity(0.2), Color.secondary.opacity(0.15)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    ))
                                        )
                                        .frame(width: max(dayWidth * 0.65, 3), height: barH)
                                }
                                .frame(width: dayWidth, height: chartHeight + 16, alignment: .bottom)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectDay(point.day)
                                }
                            }
                        }
                    }
                    .frame(height: chartHeight + 16)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                let rawDay = Int((x / totalWidth) * CGFloat(totalDays)) + 1
                                let clampedDay = min(max(rawDay, 1), totalDays)
                                if clampedDay != selectedDay {
                                    selectDay(clampedDay)
                                }
                            }
                    )
                }
                .frame(height: 106)
                
                // 4) 하단 날짜 눈금 라벨 (1, 5, 10, 15, 20, 25, 말일)
                GeometryReader { geo in
                    let totalW = geo.size.width
                    let dayW = totalW / CGFloat(max(totalDays, 1))
                    let tickDays = [1, 5, 10, 15, 20, 25, totalDays]
                    
                    ZStack(alignment: .leading) {
                        ForEach(tickDays, id: \.self) { d in
                            let xPos = (CGFloat(d - 1) + 0.5) * dayW
                            let isCurrentSel = (d == selectedDay)
                            
                            Text("\(d)일")
                                .font(.system(size: 8.5, weight: isCurrentSel ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isCurrentSel ? Color.orange : Color.secondary.opacity(0.7))
                                .position(x: xPos, y: 8)
                        }
                    }
                }
                .frame(height: 16)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
    
    // 일자 선택 및 햅틱
    private func selectDay(_ day: Int) {
        guard day >= 1 && day <= totalDays else { return }
        if day != selectedDay {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDay = day
            }
        }
    }
}

/// 수평 점선 헬퍼
private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

/// 일자별 차트용 데이터 모델
struct DailyBarPoint: Identifiable, Equatable {
    var id: Int { day }
    let day: Int
    let distanceKm: Double
}

#Preview {
    DailyDistanceChartView(
        year: 2026,
        month: 9,
        totalDays: 30,
        sessions: [
            RunSession(distanceKm: 5.2, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
            RunSession(distanceKm: 10.0, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
            RunSession(distanceKm: 7.5, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
        ],
        selectedDay: .constant(14)
    )
    .padding()
}
