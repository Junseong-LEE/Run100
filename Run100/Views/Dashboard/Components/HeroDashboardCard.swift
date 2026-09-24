//
//  HeroDashboardCard.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import SwiftData
import UIKit

/// 대시보드 메인 히어로 카드 (원형 프로그레스 링 + 코칭 정보 + 연속 스트릭 + 러닝화 소모량)
struct HeroDashboardCard: View {
    let progress: MonthlyProgress
    let onCalendarTap: () -> Void
    var onShoeTap: (() -> Void)? = nil
    
    @Query private var allShoes: [RunningShoe]
    @Query private var allSessions: [RunSession]
    
    private var activeShoe: RunningShoe? {
        allShoes.first(where: { $0.isActive && !$0.isRetired })
    }
    
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
            
            // 하단: 스트릭 칩 & 러닝화 소모량 원터치 칩
            HStack(spacing: 8) {
                // 1. 스트릭 칩 (탭 시 캘린더 이동)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onCalendarTap()
                } label: {
                    HStack(spacing: 5) {
                        Text("🔥")
                            .font(.system(size: 12))
                        Text("\(progress.currentStreak)일 연속")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.secondary.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 2. 러닝화 소모량 칩 (탭 시 러닝화 관리 시트 오픈)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onShoeTap?()
                } label: {
                    if let shoe = activeShoe {
                        let percent = Int(shoe.wearRate(from: allSessions) * 100)
                        let status = shoe.healthStatus(from: allSessions)
                        
                        HStack(spacing: 5) {
                            Image(systemName: "shoe.2.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.orange)
                            
                            Text(shoe.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Text("\(percent)%")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(status.badgeColor)
                            
                            Circle()
                                .fill(status.badgeColor)
                                .frame(width: 6, height: 6)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(status.badgeColor.opacity(0.12))
                        .clipShape(Capsule())
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "shoe.2.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.orange)
                            Text("러닝화 등록 +")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.orange)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}
