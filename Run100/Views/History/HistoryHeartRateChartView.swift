//
//  HistoryHeartRateChartView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import Charts

struct HistoryHeartRateChartView: View {
    let summaries: [MonthlyHistorySummary]
    
    private var hrSummaries: [MonthlyHistorySummary] {
        summaries.filter { ($0.averageHeartRate ?? 0) > 0 }
    }
    
    private var lowestHrMonthId: String? {
        hrSummaries.min(by: { ($0.averageHeartRate ?? 999) < ($1.averageHeartRate ?? 999) })?.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("월별 평균 심박수 (bpm)", systemImage: "heart.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.pink)
                
                Spacer()
                
                if let lowest = hrSummaries.first(where: { $0.id == lowestHrMonthId }) {
                    HStack(spacing: 4) {
                        Text("🌱 가장 안정된 심박")
                            .font(.caption2.bold())
                            .foregroundStyle(.pink)
                        Text(lowest.heartRateDisplayString)
                            .font(.caption2.bold())
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.pink.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            if hrSummaries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "heart.slash")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("측정된 심박수 기록이 없습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Chart {
                    // 유산소 심박 기준 영역 (140 ~ 160 bpm)
                    RectangleMark(
                        yStart: .value("유산소 하한", 140),
                        yEnd: .value("유산소 상한", 160)
                    )
                    .foregroundStyle(Color.pink.opacity(0.06))
                    
                    ForEach(hrSummaries) { item in
                        let hr = item.averageHeartRate ?? 0
                        
                        LineMark(
                            x: .value("월", item.monthLabel),
                            y: .value("심박수", hr)
                        )
                        .foregroundStyle(Color.pink)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        
                        PointMark(
                            x: .value("월", item.monthLabel),
                            y: .value("심박수", hr)
                        )
                        .foregroundStyle(item.id == lowestHrMonthId ? Color.pink : Color.red)
                        .symbolSize(item.id == lowestHrMonthId ? 60 : 35)
                        .annotation(position: .top) {
                            VStack(spacing: 1) {
                                if item.id == lowestHrMonthId {
                                    Text("STABLE")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.pink)
                                        .clipShape(Capsule())
                                }
                                Text("\(hr)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.pink)
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
