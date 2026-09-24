//
//  HeroDashboardCard.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI

/// 대시보드 메인 히어로 카드 (원형 프로그레스 링 + 코칭 정보 + 연속 스트릭)
struct HeroDashboardCard: View {
    let progress: MonthlyProgress
    let onCalendarTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 상단 메인 영역 (원형 링 + 우측 통계 카드)
            HStack(spacing: 16) {
                // 좌측: 원형 프로그레스 링
                ProgressRingView(
                    currentKm: progress.totalAccumulatedKm,
                    targetKm: progress.targetKm,
                    progressRatio: progress.progressRatio,
                    percentage: progress.completionPercentage
                )
                
                // 우측: 이번 달 평균 페이스 & 이번 달 누적 거리 라인 차트
                VStack(spacing: 10) {
                    // 1. 이번 달 평균 페이스 카드
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("이번 달 평균 페이스")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "speedometer")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.orange)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(progress.paceValueOnly)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("/km")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.orange)
                        }
                        
                        Text("\(progress.sessionsCount)회 러닝 • \(progress.formattedTotalDuration)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    // 2. 이번 달 평균 심박수 카드
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("이번 달 평균 심박수")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.red)
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.red)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(progress.heartRateValueOnly)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("bpm")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.red)
                        }
                        
                        Text(progress.heartRateStatusMessage)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.red.opacity(0.20), lineWidth: 1)
                    )
                }
            }
            
            Divider()
                .padding(.top, 2)
            
            // 하단: 스트릭 인디케이터 바
            HStack {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.subheadline)
                    Text("\(progress.currentStreak)일 연속 달리는 중")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Button(action: onCalendarTap) {
                    HStack(spacing: 3) {
                        Text("캘린더 보기")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Color.orange)
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    HeroDashboardCard(
        progress: MonthlyProgress(
            year: 2026,
            month: 9,
            totalAccumulatedKm: 68.0,
            sessionsCount: 12,
            currentStreak: 14,
            runDaysCount: 11
        ),
        onCalendarTap: {}
    )
    .padding()
}
