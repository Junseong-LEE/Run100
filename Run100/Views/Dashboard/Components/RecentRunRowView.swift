//
//  RecentRunRowView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI

/// 대시보드 하단 최근 달리기 리스트의 단일 행 컴포넌트
/// (거리, 페이스, 심박수, 날짜 4대 핵심 지표만 직관적으로 표시)
struct RecentRunRowView: View {
    let session: RunSession
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    // 날짜 포맷 (예: 9월 14일)
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: session.date)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // 좌측: 날짜 배지 & 달린 거리
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", session.distanceKm))
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(Color.orange)
                    Text("km")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 80, alignment: .leading)
            
            Spacer()
            
            // 우측: 페이스 & 심박수 메트릭 (2열 정렬)
            HStack(spacing: 16) {
                // 페이스
                VStack(alignment: .trailing, spacing: 3) {
                    Text("페이스")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.orange)
                        Text(session.paceString)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }
                .frame(minWidth: 68, alignment: .trailing)
                
                // 심박수
                VStack(alignment: .trailing, spacing: 3) {
                    Text("심박수")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(session.averageHeartRate != nil ? Color.pink : .secondary.opacity(0.5))
                        if let hr = session.averageHeartRate {
                            Text("\(hr) bpm")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        } else {
                            Text("- bpm")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(minWidth: 64, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // 수기 입력 데이터인 경우 꾹 눌렀을 때(롱프레스) 수정 및 삭제 팝업 메뉴 노출
        .contextMenu {
            if session.isManual {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onEdit?()
                } label: {
                    Label("기록 수정", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    onDelete?()
                } label: {
                    Label("기록 삭제", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        RecentRunRowView(
            session: RunSession(
                distanceKm: 6.2,
                date: Date(),
                durationSeconds: 1960,
                memo: "한강 탄천 저녁 러닝",
                averageHeartRate: 152
            )
        )
        RecentRunRowView(
            session: RunSession(
                distanceKm: 4.0,
                date: Date(),
                durationSeconds: 1440,
                memo: nil,
                averageHeartRate: nil
            )
        )
    }
    .padding()
}
