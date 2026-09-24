//
//  HistoryDistanceChartView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import Charts

struct HistoryDistanceChartView: View {
    let summaries: [MonthlyHistorySummary]
    let targetKm: Double
    
    private var bestMonthId: String? {
        summaries.filter { $0.totalDistanceKm > 0 }
            .max(by: { $0.totalDistanceKm < $1.totalDistanceKm })?
            .id
    }
    
    private var maxDistance: Double {
        let maxVal = summaries.map(\.totalDistanceKm).max() ?? 0.0
        return max(maxVal, targetKm) * 1.15
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("월별 누적 거리 (km)", systemImage: "figure.run")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("100km 완주 🏆")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Chart {
                // 목표선 (수평 점선)
                RuleMark(y: .value("목표", targetKm))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(Color.orange.opacity(0.8))
                
                // 월별 막대 그래프
                ForEach(summaries) { item in
                    BarMark(
                        x: .value("월", item.monthLabel),
                        y: .value("누적 거리", item.totalDistanceKm)
                    )
                    .foregroundStyle(
                        item.isGoalAchieved
                            ? LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            : LinearGradient(
                                colors: [Color.orange.opacity(0.35), Color.orange.opacity(0.55)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                    )
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        if item.totalDistanceKm > 0 {
                            VStack(spacing: 1) {
                                if item.id == bestMonthId {
                                    Text("BEST")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                } else if item.isGoalAchieved {
                                    Text("🏆")
                                        .font(.system(size: 10))
                                }
                                Text(String(format: "%.0f", item.totalDistanceKm))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(item.isGoalAchieved ? Color.orange : Color.secondary)
                            }
                        }
                    }
                }
            }
            .chartYScale(domain: 0...max(maxDistance, 10.0))
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .frame(height: 190)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
