//
//  HistoryMonthlyCardView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI

struct HistoryMonthlyCardView: View {
    let summary: MonthlyHistorySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 상단: 연/월 타이틀 및 완주 배지
            HStack(spacing: 6) {
                Text(summary.yearMonthLabel)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                
                if summary.isGoalAchieved {
                    let badgeLabel = summary.isOverachieved
                        ? String(format: "\(Int(summary.targetKm))km 완주 (+%.1fkm)", summary.excessKm)
                        : "\(Int(summary.targetKm))km 완주"
                    
                    HStack(spacing: 3) {
                        Text("🏆")
                            .font(.caption2)
                        Text(badgeLabel)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(summary.isOverachieved ? 0.22 : 0.15))
                    .foregroundStyle(Color.orange)
                    .clipShape(Capsule())
                } else if summary.totalDistanceKm > 0 {
                    let pct = Int((summary.totalDistanceKm / summary.targetKm * 100).rounded())
                    Text("\(pct)% 달성")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            // 하단: 각 지표를 균등 너비 컬럼으로 분할하여 상하(과월) 간 페이스, 심박수, 출석일수가 세로로 완벽히 일렬 정렬되도록 구성
            HStack(spacing: 0) {
                MetricIconItem(
                    icon: "figure.run",
                    value: String(format: "%.1f", summary.totalDistanceKm),
                    color: .orange
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                
                MetricIconItem(
                    icon: "speedometer",
                    value: summary.paceValueOnly,
                    color: .blue
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                
                MetricIconItem(
                    icon: "heart.fill",
                    value: summary.averageHeartRate != nil ? "\(summary.averageHeartRate!)" : "-",
                    color: .pink
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                
                MetricIconItem(
                    icon: "calendar",
                    value: "\(summary.runDaysCount)",
                    color: .green
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}

private struct MetricIconItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }
}
