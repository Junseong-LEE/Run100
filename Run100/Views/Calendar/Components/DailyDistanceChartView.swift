//
//  DailyDistanceChartView.swift
//  Run100
//
//  Created by 이준성 on 9/24/26.
//

import SwiftUI

/// 기능 F-204 리팩토링: 월간 거리 vs 페이스 산점도 (Scatter Plot) 차트
/// X축: 주행 거리 (km)
/// Y축: 평균 페이스 (위로 갈수록 빠른 페이스, 아래로 갈수록 느린 페이스)
/// 점의 투명도 & 색상: 평균 심박수 (bpm) 반영
/// 캘린더 탭의 selectedDay와 양방향 인터랙션 (점 터치 시 날짜 선택, 날짜 선택 시 해당 점 하이라이트)
struct DailyDistanceChartView: View {
    let year: Int
    let month: Int
    let totalDays: Int
    let sessions: [RunSession]
    @Binding var selectedDay: Int
    
    // MARK: - 데이터 가공
    fileprivate struct ScatterPoint: Identifiable {
        let id: UUID
        let day: Int
        let distanceKm: Double
        let paceSeconds: Double   // 초 / km
        let heartRate: Int?       // bpm
        let memo: String?
        
        var paceMinutesSeconds: (min: Int, sec: Int) {
            let m = Int(paceSeconds) / 60
            let s = Int(paceSeconds) % 60
            return (m, s)
        }
        
        var formattedPace: String {
            let p = paceMinutesSeconds
            return String(format: "%d'%02d\"", p.min, p.sec)
        }
    }
    
    // 당월 유효 달리기 세션 목록
    private var monthlyPoints: [ScatterPoint] {
        let calendar = Calendar.current
        return sessions.compactMap { session in
            let y = calendar.component(.year, from: session.date)
            let m = calendar.component(.month, from: session.date)
            let d = calendar.component(.day, from: session.date)
            guard y == year && m == month else { return nil }
            guard session.distanceKm > 0.05 && session.durationSeconds > 10 else { return nil }
            
            let paceSec = session.durationSeconds / session.distanceKm
            // 극단적인 비정상 페이스(1분 미만, 15분 이상) 제외
            guard paceSec >= 60 && paceSec <= 900 else { return nil }
            
            return ScatterPoint(
                id: session.id,
                day: d,
                distanceKm: session.distanceKm,
                paceSeconds: paceSec,
                heartRate: session.averageHeartRate,
                memo: session.memo
            )
        }
    }
    
    // 현재 선택된 일자의 러닝 포인트들
    private var selectedDayPoints: [ScatterPoint] {
        monthlyPoints.filter { $0.day == selectedDay }
    }
    
    // X축 (거리) 범위: 최소 0km, 최대치는 데이터 기반 (최소 10km 보장)
    private var maxXKm: Double {
        let maxDist = monthlyPoints.map(\.distanceKm).max() ?? 0.0
        return max(ceil(maxDist * 1.15), 10.0)
    }
    
    // Y축 (페이스) 범위: 위쪽(빠름 = 초가 작음), 아래쪽(느림 = 초가 큼)
    // 기본 가드: 4'30"(270초) ~ 7'30"(450초)
    private var paceDomain: (fastest: Double, slowest: Double) {
        let paces = monthlyPoints.map(\.paceSeconds)
        guard !paces.isEmpty else {
            return (fastest: 270.0, slowest: 450.0)
        }
        let minPace = paces.min() ?? 270.0
        let maxPace = paces.max() ?? 450.0
        
        // 여유 버퍼 20초 부여
        let fast = max(minPace - 20.0, 180.0) // 3분 이상
        let slow = min(maxPace + 20.0, 720.0) // 12분 이하
        let diff = slow - fast
        if diff < 60 {
            return (fastest: fast - 30, slowest: slow + 30)
        }
        return (fastest: fast, slowest: slow)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // MARK: - 1. 헤더 (타이틀 & 범례)
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.dots.scatter")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.orange)
                    
                    Text("\(month)월 러닝 분포")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("거리 × 페이스")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                // 심박수 투명도 미니 범례
                HStack(spacing: 4) {
                    Text("심박수")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(.secondary)
                    Circle()
                        .fill(Color.orange.opacity(0.35))
                        .frame(width: 5, height: 5)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Circle()
                        .fill(Color.orange.opacity(1.0))
                        .frame(width: 7, height: 7)
                }
            }
            
            // MARK: - 2. 선택된 날짜 피드백 서브바
            HStack(spacing: 6) {
                Text("\(selectedDay)일:")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if let mainPoint = selectedDayPoints.first {
                    HStack(spacing: 8) {
                        Text(String(format: "%.1f km", mainPoint.distanceKm))
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.orange)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.5))
                        
                        Text(mainPoint.formattedPace)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        if let hr = mainPoint.heartRate {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary.opacity(0.5))
                            
                            HStack(spacing: 2) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.red.opacity(0.85))
                                Text("\(hr) bpm")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("휴식 Day")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("총 \(monthlyPoints.count)회 러닝")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemFill).opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            // MARK: - 3. 산점도 플롯 영역
            if monthlyPoints.isEmpty {
                // 기록이 없는 경우 미니멀 플레이스홀더
                VStack(spacing: 6) {
                    Image(systemName: "figure.run.circle")
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("이번 달 완료된 러닝 세션이 없습니다")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color(.tertiarySystemFill).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                scatterPlotView
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - 산점도 코어 뷰
    private var scatterPlotView: some View {
        GeometryReader { proxy in
            let plotWidth = proxy.size.width - 34 // Y축 라벨 여백 34pt
            let plotHeight = proxy.size.height - 18 // X축 라벨 여백 18pt
            let domain = paceDomain
            let paceSpan = max(domain.slowest - domain.fastest, 1.0)
            
            ZStack(alignment: .topLeading) {
                // 1) 배경 가이드 그리드 & Y축 라벨
                yAxisAndGrid(plotWidth: plotWidth, plotHeight: plotHeight, domain: domain)
                
                // 2) 하단 X축 거리 눈금 라벨
                xAxisLabels(plotWidth: plotWidth, plotHeight: plotHeight)
                
                // 3) 산점도 데이터 포인트 렌더링
                ForEach(monthlyPoints) { point in
                    let isSelected = (point.day == selectedDay)
                    let (xPos, yPos) = calculatePosition(
                        point: point,
                        plotWidth: plotWidth,
                        plotHeight: plotHeight,
                        domain: domain,
                        paceSpan: paceSpan
                    )
                    
                    ScatterDotView(
                        point: point,
                        isSelected: isSelected,
                        onTap: {
                            selectDay(point.day)
                        }
                    )
                    .position(x: xPos, y: yPos)
                    .zIndex(isSelected ? 10 : 1)
                }
            }
        }
        .frame(height: 126)
    }
    
    // MARK: - Y축 및 수평 가이드선 (페이스가 높을수록 상단)
    @ViewBuilder
    private func yAxisAndGrid(plotWidth: CGFloat, plotHeight: CGFloat, domain: (fastest: Double, slowest: Double)) -> some View {
        let midPaceSec = (domain.fastest + domain.slowest) / 2
        
        VStack(spacing: 0) {
            // 상단: 가장 높은 페이스 라인 (예: 7'30")
            gridRow(paceSec: domain.slowest, width: plotWidth, isTop: true)
            Spacer()
            // 중간: 평균 페이스 라인 (예: 6'00")
            gridRow(paceSec: midPaceSec, width: plotWidth, isTop: false)
            Spacer()
            // 하단: 가장 낮은 페이스 라인 (예: 4'30")
            gridRow(paceSec: domain.fastest, width: plotWidth, isTop: false)
        }
        .frame(width: plotWidth + 34, height: plotHeight, alignment: .leading)
    }
    
    private func gridRow(paceSec: Double, width: CGFloat, isTop: Bool) -> some View {
        HStack(spacing: 4) {
            Text(formatPaceLabel(paceSec))
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(Color.secondary.opacity(0.65))
                .frame(width: 30, alignment: .trailing)
            
            Line()
                .stroke(style: StrokeStyle(lineWidth: 0.5, dash: isTop ? [] : [2, 3]))
                .foregroundStyle(Color.secondary.opacity(0.2))
                .frame(width: width, height: 1)
        }
        .frame(height: 14)
    }
    
    // MARK: - X축 눈금 라벨 (거리)
    private func xAxisLabels(plotWidth: CGFloat, plotHeight: CGFloat) -> some View {
        let ticks: [Double] = [0.0, maxXKm * 0.5, maxXKm]
        return HStack(spacing: 0) {
            Spacer().frame(width: 34) // Y축 라벨 여백
            
            ForEach(Array(ticks.enumerated()), id: \.offset) { index, dist in
                let label = String(format: "%.0fkm", dist)
                Text(label)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: index == 0 ? .leading : (index == ticks.count - 1 ? .trailing : .center))
            }
        }
        .frame(width: plotWidth + 34)
        .offset(y: plotHeight + 4)
    }
    
    // MARK: - 좌표 계산 (X: 거리, Y: 페이스 수치가 높을수록 위쪽)
    private func calculatePosition(
        point: ScatterPoint,
        plotWidth: CGFloat,
        plotHeight: CGFloat,
        domain: (fastest: Double, slowest: Double),
        paceSpan: Double
    ) -> (x: CGFloat, y: CGFloat) {
        // X축: 0km -> maxXKm
        let xRatio = CGFloat(min(max(point.distanceKm / maxXKm, 0.0), 1.0))
        let xPos = 34 + (xRatio * (plotWidth - 12)) + 6 // Y축 라벨 오프셋(34) + 여백 6
        
        // Y축: 페이스가 높을수록(domain.slowest) 위쪽(yRatio = 0.0), 페이스가 낮을수록(domain.fastest) 아래쪽(yRatio = 1.0)
        let paceClamped = min(max(point.paceSeconds, domain.fastest), domain.slowest)
        let yRatio = CGFloat((domain.slowest - paceClamped) / paceSpan)
        let yPos = (yRatio * (plotHeight - 14)) + 7 // gridRow 중심(7pt)에 정밀 일치
        
        return (xPos, yPos)
    }
    
    // MARK: - 헬퍼 함수
    private func selectDay(_ day: Int) {
        guard day >= 1 && day <= totalDays else { return }
        if day != selectedDay {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
                selectedDay = day
            }
        }
    }
    
    private func formatPaceLabel(_ paceSec: Double) -> String {
        let m = Int(paceSec) / 60
        let s = Int(paceSec) % 60
        return String(format: "%d'%02d\"", m, s)
    }
}

// MARK: - 단일 산점도 도트 뷰 (오렌지 단색 + 심박수 투명도)
private struct ScatterDotView: View {
    let point: DailyDistanceChartView.ScatterPoint
    let isSelected: Bool
    let onTap: () -> Void
    
    // 심박수(bpm)에 따른 투명도 계산 (최저 0.30 ~ 최고 1.0)
    private var heartRateOpacity: Double {
        guard let hr = point.heartRate else { return 0.65 }
        let clamped = min(max(Double(hr), 110.0), 185.0)
        let ratio = (clamped - 110.0) / 75.0
        return 0.30 + (ratio * 0.70)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected {
                    // 선택된 점: 쫀득한 펄스 링
                    Circle()
                        .stroke(Color.orange.opacity(0.4), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    Circle()
                        .fill(Color.orange.opacity(0.18))
                        .frame(width: 22, height: 22)
                }
                
                // 점 본체: 오렌지 단색 + 심박수 투명도
                Circle()
                    .fill(Color.orange.opacity(isSelected ? 1.0 : heartRateOpacity))
                    .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.white : Color.white.opacity(0.4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.orange.opacity(0.6) : Color.black.opacity(0.08),
                        radius: isSelected ? 4 : 1,
                        x: 0,
                        y: 1
                    )
            }
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 0.95)
        .animation(.spring(response: 0.25, dampingFraction: 0.72), value: isSelected)
    }
}

// MARK: - 수평선 서포트
private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

#Preview {
    DailyDistanceChartView(
        year: 2026,
        month: 9,
        totalDays: 30,
        sessions: [
            RunSession(distanceKm: 5.2, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, durationSeconds: 1620, averageHeartRate: 148),
            RunSession(distanceKm: 10.0, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, durationSeconds: 3180, averageHeartRate: 165),
            RunSession(distanceKm: 7.5, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, durationSeconds: 2400, averageHeartRate: 156),
            RunSession(distanceKm: 3.1, date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, durationSeconds: 880, averageHeartRate: 132),
            RunSession(distanceKm: 15.0, date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, durationSeconds: 5100, averageHeartRate: 172)
        ],
        selectedDay: .constant(23)
    )
    .padding()
}
