//
//  CalendarView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import SwiftData

/// 탭 2: 러닝 캘린더 화면 (30일 잔디 심기 히트맵 & 스트릭 통계 & 일자별 상세 카드)
struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RunSession.date, order: .reverse) private var allSessions: [RunSession]
    
    // 환경설정의 월간 목표 거리 연동
    @AppStorage("monthlyTargetKm") private var monthlyTargetKm: Double = 100.0
    
    @Bindable var store: RunStore = RunStore()
    
    init(store: RunStore = RunStore()) {
        self.store = store
    }
    @State private var selectedDay: Int = {
        Calendar.current.component(.day, from: Date())
    }()
    @State private var sessionToEdit: RunSession? = nil
    @State private var sessionToDelete: RunSession? = nil
    @State private var showDeleteConfirmation = false
    
    private var progress: MonthlyProgress {
        store.calculateMonthlyProgress(from: allSessions, targetKm: monthlyTargetKm)
    }
    
    /// 빠른 월 선택 메뉴를 위한 최근 12개월 목록
    private var availableMonthDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<12).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: today)
        }
    }
    
    // 오늘까지 지나간 일수
    private var passedDays: Int {
        let calendar = Calendar.current
        let today = Date()
        let y = calendar.component(.year, from: today)
        let m = calendar.component(.month, from: today)
        if y == store.selectedYear && m == store.selectedMonth {
            return calendar.component(.day, from: today)
        }
        return progress.totalDaysInMonth
    }
    
    // 오늘까지의 휴식 일수
    private var restDaysCount: Int {
        max(passedDays - progress.runDaysCount, 0)
    }
    
    // 출석률 (%)
    private var attendanceRate: Double {
        guard passedDays > 0 else { return 0.0 }
        let rate = (Double(progress.runDaysCount) / Double(passedDays)) * 100.0
        return (rate * 10).rounded() / 10
    }
    
    // 선택된 일자의 러닝 세션들
    private var selectedDaySessions: [RunSession] {
        store.sessions(for: selectedDay, in: allSessions)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // 1. 캘린더 상단 헤더 & 월 선택 네비게이션
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("RUNNING CALENDAR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.orange)
                            
                            Text("\(store.selectedMonth)월 러닝 캘린더")
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        // 헤더 우측 월 선택기 (< M월 >)
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
                    
                    // 2. 월간 통계 3분할 콤팩트 바 (SF Symbols 벡터 심볼 적용)
                    HStack(spacing: 8) {
                        StatCard(
                            systemImage: "checkmark.circle.fill",
                            iconColor: .orange,
                            value: "\(progress.runDaysCount)일",
                            label: "달린 날"
                        )
                        
                        StatCard(
                            systemImage: "moon.stars.fill",
                            iconColor: .indigo,
                            value: "\(restDaysCount)일",
                            label: "휴식한 날"
                        )
                        
                        StatCard(
                            systemImage: "chart.line.uptrend.xyaxis",
                            iconColor: .green,
                            value: String(format: "%.1f%%", attendanceRate),
                            label: "출석률"
                        )
                    }
                    .padding(.horizontal)
                    
                    // 3. N월 출석체크 히트맵 그리드 (기능 F-202: 연속 스트릭 배지 내장)
                    HeatmapGridView(
                        year: store.selectedYear,
                        month: store.selectedMonth,
                        totalDays: progress.totalDaysInMonth,
                        currentStreak: progress.currentStreak,
                        sessions: allSessions,
                        selectedDay: $selectedDay,
                        onSelectDay: { day in
                            selectedDay = day
                        }
                    )
                    .padding(.horizontal)
                    
                    // 4. 기능 F-204: N월 일별 러닝 거리 막대 차트 (인터랙티브 날짜 연동)
                    DailyDistanceChartView(
                        year: store.selectedYear,
                        month: store.selectedMonth,
                        totalDays: progress.totalDaysInMonth,
                        sessions: allSessions,
                        selectedDay: $selectedDay
                    )
                    .padding(.horizontal)
                    
                    // 5. 선택 일자 러닝 상세 카드
                    DayDetailCardView(
                        month: store.selectedMonth,
                        day: selectedDay,
                        sessions: selectedDaySessions,
                        onEdit: { session in
                            sessionToEdit = session
                        },
                        onDelete: { session in
                            sessionToDelete = session
                            showDeleteConfirmation = true
                        }
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: 24)
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(uiColor: .systemGroupedBackground))
            .sheet(item: $sessionToEdit) { session in
                QuickAddModalView(sessionToEdit: session) {
                    WidgetDataBridge.shared.updateSnapshot(from: progress, allSessions: allSessions)
                }
                .presentationDetents([.fraction(0.55), .medium])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "달리기 기록 삭제",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("기록 삭제", role: .destructive) {
                    if let session = sessionToDelete {
                        deleteSession(session)
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                if let session = sessionToDelete {
                    Text("\(String(format: "%.1f", session.distanceKm))km (\(session.memo ?? "달리기")) 기록을 삭제하시겠습니까? 목표 달성률과 출석체크에서 제외됩니다.")
                }
            }
            .onChange(of: store.selectedMonth) { _, _ in
                if selectedDay > progress.totalDaysInMonth {
                    selectedDay = progress.totalDaysInMonth
                }
            }
        }
    }
    
    // MARK: - 수기 세션 삭제
    
    private func deleteSession(_ session: RunSession) {
        modelContext.delete(session)
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        WidgetDataBridge.shared.updateSnapshot(from: progress, allSessions: allSessions)
    }
}

/// 통계 미니 카드 컴포넌트 (SF Symbols 기반 콤팩트 칩)
private struct StatCard: View {
    let systemImage: String
    let iconColor: Color
    let value: String
    var label: String? = nil
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(iconColor)
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label ?? "") \(value)")
    }
}

#Preview {
    CalendarView()
        .modelContainer(.preview)
}
