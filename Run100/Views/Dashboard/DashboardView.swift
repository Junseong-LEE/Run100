//
//  DashboardView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import SwiftData
import UIKit

/// 탭 1: 대시보드 화면 (100km 프로그레스 링 & 코칭 히어로 카드 & 빠른 액션 & 최근 달리기 피드)
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RunSession.date, order: .reverse) private var allSessions: [RunSession]
    
    var onSwitchToCalendar: (() -> Void)? = nil
    
    // 월간 목표 거리 환경설정 연동
    @AppStorage("monthlyTargetKm") private var monthlyTargetKm: Double = 100.0
    
    @Bindable var store: RunStore = RunStore()
    
    init(store: RunStore = RunStore(), onSwitchToCalendar: (() -> Void)? = nil) {
        self.store = store
        self.onSwitchToCalendar = onSwitchToCalendar
    }
    @State private var healthKitManager = HealthKitManager.shared
    @State private var syncAlertMessage = ""
    @State private var showSyncResultAlert = false
    @State private var showSimulatorMockDialog = false
    @State private var showTopSyncBanner = false
    @State private var topBannerMessage = ""
    @State private var sessionToEdit: RunSession? = nil
    @State private var sessionToDelete: RunSession? = nil
    @State private var showDeleteConfirmation = false
    @State private var showShoeManagement = false
    
    /// 빠른 월 선택 메뉴를 위한 최근 12개월 목록
    private var availableMonthDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<12).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: today)
        }
    }
    
    private var progress: MonthlyProgress {
        store.calculateMonthlyProgress(from: allSessions, targetKm: monthlyTargetKm)
    }
    
    // 이번 달 최신 러닝 기록 상위 7건 (거리, 페이스, 심박수, 날짜 4대 핵심 지표)
    private var recentMonthSessions: [RunSession] {
        let calendar = Calendar.current
        return allSessions.filter { session in
            let y = calendar.component(.year, from: session.date)
            let m = calendar.component(.month, from: session.date)
            return y == store.selectedYear && m == store.selectedMonth
        }.prefix(7).map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. 상단 앱 헤더 & D-Day
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("MONTHLY \(Int(monthlyTargetKm))K")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.orange)
                            
                            Text("\(store.selectedMonth)월 \(Int(monthlyTargetKm))km 대시보드")
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        // 헤더 우측 월 선택기 (< M월 ▾ >)
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
                    
                    // 상단 동기화 완료 알림 배너
                    if showTopSyncBanner {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.green)
                                .font(.system(size: 15, weight: .bold))
                            Text(topBannerMessage)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.green.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                        .padding(.horizontal)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                    
                    // 2. 100km 프로그레스 링 히어로 카드 (하단에 스트릭 + 러닝화 소모량 칩 통합)
                    HeroDashboardCard(
                        progress: progress,
                        onCalendarTap: {
                            onSwitchToCalendar?()
                        },
                        onShoeTap: {
                            showShoeManagement = true
                        }
                    )
                    .padding(.horizontal)
                    
                    // 3. 기능 F-103: 100km 러닝 트랙 & 최근 3개월 동기간(N일차) 과거의 나와 누적 경쟁
                    RunningTrackProgressCard(progress: progress)
                        .padding(.horizontal)
                    
                    // 4. 최근 달리기 피드 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("최근 달리기 기록")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Button {
                                onSwitchToCalendar?()
                            } label: {
                                Text("전체 캘린더")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.orange)
                            }
                        }
                        .padding(.horizontal)
                        
                        if recentMonthSessions.isEmpty {
                            // 등록된 세션이 없을 때 빈 상태 안내 카드
                            VStack(spacing: 8) {
                                Image(systemName: "figure.run.circle")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color.orange.opacity(0.6))
                                Text("아직 이번 달 기록이 없어요")
                                    .font(.system(size: 14, weight: .bold))
                                Text("오늘 3km 가볍게 달리고 첫 깃발을 꽂아보세요! 🚩")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(recentMonthSessions) { session in
                                    RecentRunRowView(
                                        session: session,
                                        onEdit: {
                                            sessionToEdit = session
                                        },
                                        onDelete: {
                                            sessionToDelete = session
                                            showDeleteConfirmation = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 4)
                    
                    Spacer(minLength: 24)
                }
            }
            .refreshable {
                await executeHealthSync()
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(uiColor: .systemGroupedBackground))
            .sheet(item: $sessionToEdit) { session in
                QuickAddModalView(sessionToEdit: session) {
                    WidgetDataBridge.shared.updateSnapshot(from: progress, allSessions: allSessions)
                    triggerTopBanner(message: "수기 달리기 기록이 수정되었습니다.")
                }
                .presentationDetents([.fraction(0.55), .medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showShoeManagement) {
                NavigationStack {
                    ShoeManagementView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("닫기") {
                                    showShoeManagement = false
                                }
                            }
                        }
                }
            }
            .alert("애플 건강 동기화", isPresented: $showSyncResultAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(syncAlertMessage)
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
                    Text("\(String(format: "%.1f", session.distanceKm))km (\(session.memo ?? "달리기")) 기록을 삭제하시겠습니까? 목표 달성률과 잔디 심기에서 제외됩니다.")
                }
            }
            .confirmationDialog(
                "시뮬레이터 테스트 안내",
                isPresented: $showSimulatorMockDialog,
                titleVisibility: .visible
            ) {
                Button("샘플 러닝 워크아웃 1건 추가") {
                    let result = healthKitManager.addSampleHealthWorkout(
                        with: modelContext,
                        existingSessions: allSessions,
                        targetYear: store.selectedYear,
                        targetMonth: store.selectedMonth
                    )
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    WidgetDataBridge.shared.updateSnapshot(from: progress, allSessions: allSessions)
                    triggerTopBanner(message: result.message)
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("시뮬레이터 환경에는 Apple HealthKit 러닝 기록이 없을 수 있습니다. 테스트용 샘플 애플 워치 러닝 세션을 생성하여 대시보드와 잔디 심기를 확인하시겠습니까?")
            }
            .onAppear {
                WidgetDataBridge.shared.updateSnapshot(from: progress, allSessions: allSessions)
            }
            .onChange(of: allSessions.count) { _, _ in
                WidgetDataBridge.shared.updateSnapshot(from: progress, allSessions: allSessions)
            }
            .onChange(of: monthlyTargetKm) { _, _ in
                WidgetDataBridge.shared.updateSnapshot(from: progress, allSessions: allSessions)
            }
        }
    }
    
    // MARK: - HealthKit 동기화 실행
    
    private func executeHealthSync() async {
        do {
            let result = try await healthKitManager.syncWorkouts(with: modelContext, existingSessions: allSessions)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            WidgetDataBridge.shared.updateSnapshot(from: progress, allSessions: allSessions)
            triggerTopBanner(message: result.message)
        } catch {
            #if targetEnvironment(simulator)
            // 시뮬레이터에서는 건강 데이터 부재 또는 권한 제한 시 테스트 샘플 옵션 제공
            showSimulatorMockDialog = true
            #else
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            syncAlertMessage = error.localizedDescription
            showSyncResultAlert = true
            #endif
        }
    }
    
    /// 상단 완료 알림 배너 3.5초간 노출
    private func triggerTopBanner(message: String) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            topBannerMessage = message
            showTopSyncBanner = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                showTopSyncBanner = false
            }
        }
    }
    
    // MARK: - 수기 세션 삭제
    
    private func deleteSession(_ session: RunSession) {
        modelContext.delete(session)
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        WidgetDataBridge.shared.updateSnapshot(from: progress, allSessions: allSessions)
        triggerTopBanner(message: "달리기 기록이 삭제되었습니다.")
    }
}

#Preview {
    DashboardView()
        .modelContainer(.preview)
}
