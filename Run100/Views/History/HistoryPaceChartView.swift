//
//  HistoryPaceChartView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import Charts

struct HistoryPaceChartView: View {
    let summaries: [MonthlyHistorySummary]
    
    private var paceSummaries: [MonthlyHistorySummary] {
        summaries.filter { ($0.averagePaceSeconds ?? 0) > 0 }
    }
    
    private var fastestMonthId: String? {
        paceSummaries.min(by: { ($0.averagePaceSeconds ?? 9999) < ($1.averagePaceSeconds ?? 9999) })?.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("월별 평균 페이스 (/km)", systemImage: "speedometer")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let fastest = summaries.first(where: { $0.id == fastestMonthId }) {
                    HStack(spacing: 4) {
                        Text("⚡️ 최고 페이스")
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                        Text(fastest.averagePaceString)
                            .font(.caption2.bold())
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            if paceSummaries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("해당 기간의 러닝 페이스 기록이 없습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Chart {
                    ForEach(paceSummaries) { item in
                        let paceMin = (item.averagePaceSeconds ?? 0) / 60.0
                        
                        AreaMark(
                            x: .value("월", item.monthLabel),
                            y: .value("페이스(분)", paceMin)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        LineMark(
                            x: .value("월", item.monthLabel),
                            y: .value("페이스(분)", paceMin)
                        )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        
                        PointMark(
                            x: .value("월", item.monthLabel),
                            y: .value("페이스(분)", paceMin)
                        )
                        .foregroundStyle(item.id == fastestMonthId ? Color.blue : Color.cyan)
                        .symbolSize(item.id == fastestMonthId ? 60 : 35)
                        .annotation(position: .top) {
                            VStack(spacing: 1) {
                                if item.id == fastestMonthId {
                                    Text("BEST")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                }
                                Text(item.paceValueOnly)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(item.id == fastestMonthId ? Color.blue : Color.secondary)
                            }
                        }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
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
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
