//
//  SettingsView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import SwiftData
import UIKit

/// 설정 화면 (월간 목표 설정, 테마, 알림, 애플 건강 연동, 데이터 관리)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allSessions: [RunSession]
    
    var isPresentedAsSheet: Bool = false
    
    // 환경설정 영구 저장 (@AppStorage)
    @AppStorage("monthlyTargetKm") private var monthlyTargetKm: Double = 100.0
    @AppStorage("appTheme") private var appTheme: String = "dark" // "system", "light", "dark"
    
    @State private var healthKitManager = HealthKitManager.shared
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false
    @State private var syncResultMessage = ""
    @State private var showSyncResultAlert = false
    @State private var showReleaseNotes = false
    
    private let targetPresets: [Double] = [50.0, 100.0, 150.0]
    
    /// 앱의 번들 버전 동적 로드 (예: "v1.2.0")
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. 월간 목표 거리 설정 섹션
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("이번 달 목표 거리")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Text("\(Int(monthlyTargetKm)) km")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(Color.orange)
                        }
                        
                        // 목표 프리셋 칩
                        HStack(spacing: 8) {
                            ForEach(targetPresets, id: \.self) { preset in
                                let isSelected = monthlyTargetKm == preset
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    monthlyTargetKm = preset
                                } label: {
                                    Text("\(Int(preset))km")
                                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color.orange.opacity(0.18) : Color(.tertiarySystemFill))
                                        .foregroundStyle(isSelected ? Color.orange : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 1.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // 슬라이더 미세 조정
                        Slider(value: $monthlyTargetKm, in: 30...300, step: 5)
                            .tint(Color.orange)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("목표 러닝", systemImage: "flag.checkered")
                } footer: {
                    Text("목표를 변경하면 대시보드 게이지 및 일일 권장 거리가 즉시 재계산됩니다.")
                        .font(.caption2)
                }
                
                // 2. 화면 테마 모드 섹션
                Section {
                    Picker("화면 모드", selection: $appTheme) {
                        Text("다크 모드 (기본)").tag("dark")
                        Text("라이트 모드").tag("light")
                        Text("시스템 설정 일치").tag("system")
                    }
                    .pickerStyle(.menu)
                } header: {
                    Label("화면 스타일", systemImage: "circle.lefthalf.filled")
                }

                
                // 4. 애플 건강 (HealthKit) 연동 상태
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple HealthKit 지원")
                                .font(.system(size: 14, weight: .semibold))
                            Text("애플워치 러닝 기록 자동 동기화")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if healthKitManager.isHealthKitAvailable {
                            Text("지원됨")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.12))
                                .clipShape(Capsule())
                        } else {
                            Text("미지원 기기")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let lastSync = healthKitManager.lastSyncDate {
                        HStack {
                            Text("최근 동기화")
                                .font(.system(size: 14))
                            Spacer()
                            Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        Task {
                            await syncFromSettings()
                        }
                    } label: {
                        HStack {
                            Text(healthKitManager.isSyncing ? "동기화 진행 중..." : "지금 즉시 동기화하기")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(healthKitManager.isSyncing ? .secondary : Color.orange)
                            Spacer()
                            if healthKitManager.isSyncing {
                                ProgressView()
                                    .tint(Color.orange)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.orange)
                            }
                        }
                    }
                    .disabled(healthKitManager.isSyncing)
                } header: {
                    Label("데이터 연동", systemImage: "heart.fill")
                } footer: {
                    Text("Apple Watch 등으로 측정되어 애플 건강(Apple Health)에 저장된 달리기 기록을 중복 없이 가져옵니다.")
                        .font(.caption2)
                }
                
                // 5. 데이터 관리
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Text("기록 데이터 전체 초기화")
                            Spacer()
                            Text("\(allSessions.count)개 기록")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("데이터 관리", systemImage: "cylinder.split.1x2.fill")
                } footer: {
                    Text("저장된 모든 달리기 기록을 기기에서 영구적으로 삭제합니다.")
                        .font(.caption2)
                }
                
                // 앱 정보
                Section {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showReleaseNotes = true
                    } label: {
                        HStack {
                            Text("앱 버전")
                                .foregroundStyle(.primary)
                            Spacer()
                            HStack(spacing: 5) {
                                Text(appVersionString)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    
                    HStack {
                        Text("개발자")
                        Spacer()
                        Text("Junseong Lee")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("앱 정보", systemImage: "info.circle.fill")
                } footer: {
                    Text("앱 버전을 터치하면 최신 업데이트 릴리즈 노트를 확인할 수 있습니다.")
                        .font(.caption2)
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showReleaseNotes) {
                ReleaseNotesModalView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .toolbar {
                if isPresentedAsSheet {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("완료") {
                            dismiss()
                        }
                        .fontWeight(.bold)
                        .foregroundStyle(Color.orange)
                    }
                }
            }
            .confirmationDialog(
                "달리기 기록을 모두 삭제하시겠습니까?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("모든 기록 삭제", role: .destructive) {
                    deleteAllSessions()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("삭제된 달리기 세션과 잔디 심기 기록은 복구할 수 없습니다.")
            }
            .alert("초기화 완료", isPresented: $showResetSuccess) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("모든 기록이 초기화되었습니다.")
            }
            .alert("건강 데이터 동기화", isPresented: $showSyncResultAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(syncResultMessage)
            }
        }
    }
    
    private func syncFromSettings() async {
        do {
            let result = try await healthKitManager.syncWorkouts(with: modelContext, existingSessions: allSessions)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            syncResultMessage = result.message
            showSyncResultAlert = true
        } catch {
            #if targetEnvironment(simulator)
            let result = healthKitManager.addSampleHealthWorkout(with: modelContext, existingSessions: allSessions)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            syncResultMessage = result.message
            showSyncResultAlert = true
            #else
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            syncResultMessage = error.localizedDescription
            showSyncResultAlert = true
            #endif
        }
    }
    
    private func deleteAllSessions() {
        for session in allSessions {
            modelContext.delete(session)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showResetSuccess = true
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: RunSession.self, inMemory: true)
}
