//
//  QuickAddModalView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import SwiftData

/// 오늘 달리기 기록을 3초 만에 입력하거나 기존 수기 기록을 수정하는 바텀 시트 모달
struct QuickAddModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var sessionToEdit: RunSession? = nil
    var onSaved: (() -> Void)? = nil
    
    @State private var distanceKmText: String = "5.0"
    @State private var memo: String = ""
    @State private var durationMinutesText: String = ""
    
    private var isEditing: Bool {
        sessionToEdit != nil
    }
    
    private let quickChips: [Double] = [3.0, 5.0, 7.0, 10.0]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 상단 헤더 바
                VStack(spacing: 8) {
                    Text("달린 거리 (KM)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    // 대형 거리 입력 디스플레이
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField("5.0", text: $distanceKmText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(Color.orange)
                            .frame(maxWidth: 160)
                        
                        Text("KM")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(Color.orange)
                    }
                    .padding(.vertical, 4)
                    
                    // 퀵 거리 선택 칩
                    HStack(spacing: 8) {
                        ForEach(quickChips, id: \.self) { chip in
                            let isSelected = (Double(distanceKmText) ?? 0.0) == chip
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                distanceKmText = String(format: "%.1f", chip)
                            } label: {
                                Text("\(Int(chip))km")
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.orange.opacity(0.18) : Color(.tertiarySystemFill))
                                    .foregroundStyle(isSelected ? Color.orange : .primary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 1.5)
                                    )
                            }
                        }
                    }
                }
                .padding(.top, 12)
                
                // 메모 & 소요 시간 입력 폼
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("메모 및 코스 (예: 한강 탄천 러닝)", text: $memo)
                            .font(.system(size: 14))
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    HStack(spacing: 12) {
                        Image(systemName: "stopwatch")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("소요 시간 (분 단위, 선택)", text: $durationMinutesText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 14))
                        Text("분")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 저장 버튼
                Button(action: saveRun) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                        Text(isEditing ? "수정 내용 저장하기" : "오늘 달리기 저장하기")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .navigationTitle(isEditing ? "달리기 기록 수정" : "달리기 기록 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
            .onAppear {
                if let session = sessionToEdit {
                    distanceKmText = String(format: "%.1f", session.distanceKm)
                    memo = session.memo ?? ""
                    if session.durationSeconds > 0 {
                        durationMinutesText = "\(Int(session.durationSeconds / 60))"
                    }
                }
            }
        }
    }
    
    private func saveRun() {
        guard let km = Double(distanceKmText), km > 0 else { return }
        
        let minutes = Double(durationMinutesText) ?? 0
        let seconds = minutes * 60
        
        if let session = sessionToEdit {
            // 기존 세션 수정
            session.distanceKm = km
            session.durationSeconds = seconds
            session.memo = memo.isEmpty ? nil : memo
            try? modelContext.save()
        } else {
            // 신규 세션 추가
            let newSession = RunSession(
                distanceKm: km,
                date: Date(),
                durationSeconds: seconds,
                memo: memo.isEmpty ? nil : memo,
                isManual: true,
                source: "Manual"
            )
            modelContext.insert(newSession)
            try? modelContext.save()
        }
        
        // 햅틱 피드백 발생
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSaved?()
        dismiss()
    }
}

#Preview {
    QuickAddModalView()
        .modelContainer(for: RunSession.self, inMemory: true)
}
