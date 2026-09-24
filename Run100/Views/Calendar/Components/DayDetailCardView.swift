//
//  DayDetailCardView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import SwiftData

/// 선택한 날짜의 달리기 상세 내역 카드 (소요 시간, 메모, 세션 정보, 착용 러닝화 로테이션)
struct DayDetailCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allShoes: [RunningShoe]
    
    let month: Int
    let day: Int
    let sessions: [RunSession]
    var onEdit: ((RunSession) -> Void)? = nil
    var onDelete: ((RunSession) -> Void)? = nil
    
    private var totalDistance: Double {
        let sum = sessions.reduce(0.0) { $0 + $1.distanceKm }
        return (sum * 10).rounded() / 10
    }
    
    private var totalSeconds: TimeInterval {
        sessions.reduce(0) { $0 + $1.durationSeconds }
    }
    
    private var isToday: Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.component(.month, from: today) == month && calendar.component(.day, from: today) == day
    }
    
    private var activeShoe: RunningShoe? {
        allShoes.first(where: { $0.isActive && !$0.isRetired })
    }
    
    private func currentShoe(for session: RunSession) -> RunningShoe? {
        if let shoeId = session.shoeId {
            return allShoes.first(where: { $0.id == shoeId })
        }
        return activeShoe
    }
    
    // 달리기 시작 시각 포맷 (예: "오전 7:30")
    private func formattedStartTime(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
    
    // 달린 시간(지속 시간) 포맷 (예: "32분 40초")
    private func formattedDuration(seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "시간 미기록" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if secs == 0 {
            return "\(mins)분"
        } else {
            return "\(mins)분 \(secs)초"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 상단 헤더
            HStack {
                HStack(spacing: 6) {
                    Text("\(month)월 \(day)일\(isToday ? " (오늘)" : "") 러닝 상세")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                if totalDistance > 0 {
                    Text(String(format: "%.1f km", totalDistance))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("휴식 Day")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }
            }
            
            if sessions.isEmpty {
                // 기록 없는 날 (휴식일)
                HStack(spacing: 12) {
                    Text("🧘")
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("충분한 휴식으로 회복했어요")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("근육이 쉬어야 다음 달리기가 더 강해집니다.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                // 기록이 있는 날
                VStack(spacing: 10) {
                    // 당일 총 소요 시간 및 완료 세션 요약 카드
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("총 소요 시간")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            let minutes = Int(totalSeconds) / 60
                            let seconds = Int(totalSeconds) % 60
                            Text(totalSeconds > 0 ? "\(minutes)분 \(seconds)초" : "시간 미기록")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("완료 세션")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            Text("\(sessions.count)회 달림")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.orange)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    // 당일 개별 러닝 세션 목록 (달리기 시간, 달린 시간, 거리, 페이스, 심박수 위주 배치)
                    ForEach(sessions) { session in
                        VStack(spacing: 8) {
                            // 상단: 달리기 시간(시작 시각) & 달린 거리
                            HStack(alignment: .firstTextBaseline) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                    Text(formattedStartTime(for: session.date))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.primary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                                
                                Spacer()
                                
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text(String(format: "%.1f", session.distanceKm))
                                        .font(.system(size: 18, weight: .black, design: .rounded))
                                        .foregroundStyle(Color.orange)
                                    Text("km")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Divider()
                                .opacity(0.4)
                            
                            // 하단: 달린 시간 | 페이스 | 심박수 3분할 메트릭
                            HStack {
                                // 달린 시간
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("달린 시간")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    Text(formattedDuration(seconds: session.durationSeconds))
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // 페이스
                                VStack(alignment: .center, spacing: 2) {
                                    Text("페이스")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 2) {
                                        Image(systemName: "speedometer")
                                            .font(.system(size: 9))
                                            .foregroundStyle(Color.orange)
                                        Text(session.paceString)
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                // 심박수
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("심박수")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 2) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 9))
                                            .foregroundStyle(session.averageHeartRate != nil ? Color.pink : .secondary.opacity(0.4))
                                        if let hr = session.averageHeartRate {
                                            Text("\(hr) bpm")
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundStyle(.primary)
                                        } else {
                                            Text("- bpm")
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            
                            // 착용 러닝화 로테이션 선택/변경 메뉴 바
                            if !allShoes.isEmpty {
                                Divider()
                                    .opacity(0.3)
                                
                                HStack {
                                    HStack(spacing: 4) {
                                        Image(systemName: "shoe.2.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color.orange)
                                        Text("착용 신발")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Menu {
                                        ForEach(allShoes) { shoe in
                                            Button {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                session.shoeId = shoe.id
                                                try? modelContext.save()
                                            } label: {
                                                HStack {
                                                    Text(shoe.isActive ? "\(shoe.name) (주력)" : shoe.name)
                                                    if (session.shoeId == shoe.id) || (session.shoeId == nil && shoe.isActive) {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(currentShoe(for: session)?.name ?? "신발 선택")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(Color.orange)
                                                .lineLimit(1)
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundStyle(Color.orange.opacity(0.8))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.orange.opacity(0.12))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .contextMenu {
                            if session.isManual {
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    onEdit?(session)
                                } label: {
                                    Label("기록 수정", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    onDelete?(session)
                                } label: {
                                    Label("기록 삭제", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            
            // 안내 팁
            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.orange)
                Text("캘린더의 날짜를 누르면 해당 일자의 러닝 기록을 바로 확인할 수 있습니다.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    DayDetailCardView(
        month: 9,
        day: 14,
        sessions: [
            RunSession(distanceKm: 6.2, durationSeconds: 1960, memo: "한강 탄천 저녁 러닝")
        ]
    )
    .padding()
}
