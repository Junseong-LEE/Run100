//
//  HistoryConsistencyChartView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import Charts

struct HistoryConsistencyChartView: View {
    let summaries: [MonthlyHistorySummary]
    
    private var mostConsistentMonthId: String? {
        summaries.filter { $0.runDaysCount > 0 }
            .max(by: { $0.runDaysCount < $1.runDaysCount })?
            .id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("월별 달린 날 및 출석률", systemImage: "calendar.badge.clock")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                
                Spacer()
                
                if let best = summaries.first(where: { $0.id == mostConsistentMonthId }) {
                    HStack(spacing: 4) {
                        Text("🔥 최다 달린 날")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                        Text("\(best.runDaysCount)일 (\(best.runAttendanceRate)%)")
                            .font(.caption2.bold())
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            Chart {
                ForEach(summaries) { item in
                    BarMark(
                        x: .value("월", item.monthLabel),
                        y: .value("달린 날", item.runDaysCount)
                    )
                    .foregroundStyle(
                        item.runAttendanceRate >= 50
                            ? LinearGradient(
                                colors: [Color.green, Color.mint],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            : LinearGradient(
                                colors: [Color.green.opacity(0.35), Color.green.opacity(0.55)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                    )
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        if item.runDaysCount > 0 {
                            VStack(spacing: 1) {
                                Text("\(item.runDaysCount)일")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.green)
                                Text("\(item.runAttendanceRate)%")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .chartYScale(domain: 0...31)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 10, 20, 30]) { _ in
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
