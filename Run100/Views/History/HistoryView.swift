//
//  HistoryView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import SwiftData

enum HistoryMetric: String, CaseIterable, Identifiable {
    case distance = "거리"
    case pace = "페이스"
    case heartRate = "심박수"
    case consistency = "달린 날"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .distance: return "figure.run"
        case .pace: return "speedometer"
        case .heartRate: return "heart.fill"
        case .consistency: return "calendar.badge.clock"
        }
    }
}

struct HistoryView: View {
    @Bindable var store: RunStore
    @Query(sort: \RunSession.date, order: .reverse) private var allSessions: [RunSession]
    @AppStorage("monthlyTargetKm") private var targetKm: Double = 100.0
    
    @State private var selectedPeriod: HistoryPeriod = .twelveMonths
    @State private var selectedMetric: HistoryMetric = .distance
    
    // MARK: - 집계 데이터
    
    private var summaries: [MonthlyHistorySummary] {
        store.calculateHistorySummaries(
            from: allSessions,
            period: selectedPeriod,
            targetKm: targetKm
        )
    }
    
    /// 최근 월 순서로 정렬된 요약 목록 (성적표 피드용)
    private var reverseSummaries: [MonthlyHistorySummary] {
        summaries.reversed()
    }
    
    /// 해당 기간 전체 총 러닝 거리
    private var totalPeriodDistance: Double {
        summaries.reduce(0.0) { $0 + $1.totalDistanceKm }
    }
    
    /// 목표 달성 월 횟수
    private var achievedMonthsCount: Int {
        summaries.filter { $0.isGoalAchieved }.count
    }
    
    /// 해당 기간 전체 평균 페이스
    private var periodAveragePace: String {
        let totalKm = totalPeriodDistance
        let totalSec = summaries.reduce(0.0) { $0 + $1.totalDurationSeconds }
        guard totalKm > 0 && totalSec > 0 else { return "-:--" }
        let secPerKm = totalSec / totalKm
        let min = Int(secPerKm) / 60
        let sec = Int(secPerKm) % 60
        guard min < 60 else { return "-:--" }
        return String(format: "%d:%02d/km", min, sec)
    }
    
    /// 해당 기간 전체 평균 심박수
    private var periodAverageHeartRate: String {
        let hrItems = summaries.compactMap { $0.averageHeartRate }
        guard !hrItems.isEmpty else { return "-" }
        let avg = Int((Double(hrItems.reduce(0, +)) / Double(hrItems.count)).rounded())
        return "\(avg) bpm"
    }
    
    /// 빠른 월 선택 메뉴를 위한 최근 12개월 목록 (대시보드·캘린더와 동일)
    private var availableMonthDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<12).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: today)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. 상단 헤더 & 다른 탭과 연동되는 월 선택기 (< M월 ▾ >)
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("RUNNING HISTORY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.orange)
                            
                            Text("러닝 히스토리")
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        // 헤더 우측 월 선택기 (< M월 ▾ >) - 탭 간 전역 스토어 상태 동기화
                        HStack(spacing: 4) {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    store.changeMonth(by: -1)
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 28, height: 28)
                                    .contentShape(Rectangle())
                            }
                            
                            Menu {
                                ForEach(availableMonthDates, id: \.self) { date in
                                    let cal = Calendar.current
                                    let y = cal.component(.year, from: date)
                                    let m = cal.component(.month, from: date)
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            store.selectedYear = y
                                            store.selectedMonth = m
                                        }
                                    } label: {
                                        HStack {
                                            Text(verbatim: "\(y)년 \(m)월")
                                            if store.selectedYear == y && store.selectedMonth == m {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Text("\(store.selectedMonth)월")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 6)
                                    .frame(height: 28)
                            }
                            
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    store.changeMonth(by: 1)
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(store.isCurrentMonth ? Color.secondary.opacity(0.3) : .primary)
                                    .frame(width: 28, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .disabled(store.isCurrentMonth)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 3)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                    
                    // MARK: - F-301: 분석 기간 선택 필터
                    Picker("분석 기간", selection: $selectedPeriod) {
                        ForEach(HistoryPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // MARK: - 기간 종합 하이라이트 배너
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(selectedPeriod.title) 종합 요약")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", totalPeriodDistance))
                                        .font(.system(size: 30, weight: .black, design: .rounded))
                                        .foregroundStyle(.primary)
                                    Text("km")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if achievedMonthsCount > 0 {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("목표 달성")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 4) {
                                        Text("🏆")
                                        Text("\(achievedMonthsCount)회 완주")
                                            .font(.headline.bold())
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "speedometer")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Text("평균 페이스")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(periodAveragePace)
                                    .font(.caption.bold())
                                    .foregroundStyle(.primary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundStyle(.pink)
                                Text("평균 심박수")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(periodAverageHeartRate)
                                    .font(.caption.bold())
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // MARK: - 지표 탭 선택 (거리 / 페이스 / 심박수 / 달린 날수)
                    Picker("분석 지표", selection: $selectedMetric) {
                        ForEach(HistoryMetric.allCases) { metric in
                            Label(metric.rawValue, systemImage: metric.icon).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // MARK: - 인터랙티브 차트 (F-302 ~ F-305)
                    Group {
                        switch selectedMetric {
                        case .distance:
                            HistoryDistanceChartView(summaries: summaries, targetKm: targetKm)
                        case .pace:
                            HistoryPaceChartView(summaries: summaries)
                        case .heartRate:
                            HistoryHeartRateChartView(summaries: summaries)
                        case .consistency:
                            HistoryConsistencyChartView(summaries: summaries)
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - F-306: 월별 종합 성적표 (콤팩트 피드)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("월별 종합 성적표")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                HStack(spacing: 2) {
                                    Image(systemName: "figure.run")
                                        .foregroundStyle(.orange)
                                    Text("거리")
                                }
                                HStack(spacing: 2) {
                                    Image(systemName: "speedometer")
                                        .foregroundStyle(.blue)
                                    Text("페이스")
                                }
                                HStack(spacing: 2) {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(.pink)
                                    Text("심박")
                                }
                                HStack(spacing: 2) {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.green)
                                    Text("달린 날")
                                }
                            }
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 0) {
                            ForEach(Array(reverseSummaries.enumerated()), id: \.element.id) { index, item in
                                HistoryMonthlyCardView(summary: item)
                                
                                if index < reverseSummaries.count - 1 {
                                    Divider()
                                        .padding(.leading, 14)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 24)
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

#Preview {
    HistoryView(store: RunStore())
        .modelContainer(.preview)
}
