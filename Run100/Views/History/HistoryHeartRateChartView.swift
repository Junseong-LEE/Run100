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
    
    /// Zone 2~3 적정 유산소 심박 범위 (130 ~ 155 bpm)
    private let zone23Min = 130
    private let zone23Max = 155
    
    /// Zone 2~3 구간에 포함되는 월 중 가장 최근 월 (없을 경우 140bpm에 가장 가까운 월)
    private var optimalHrMonth: MonthlyHistorySummary? {
        // 1. Zone 2~3 (130~155bpm) 범위에 들어오는 월 중 가장 최근 월
        if let optimal = hrSummaries.filter({
            guard let hr = $0.averageHeartRate else { return false }
            return hr >= zone23Min && hr <= zone23Max
        }).last {
            return optimal
        }
        // 2. 만약 해당 구간이 없다면 유산소 이상 기준점(142bpm)에 가장 가까운 월
        return hrSummaries.min(by: {
            abs(($0.averageHeartRate ?? 0) - 142) < abs(($1.averageHeartRate ?? 0) - 142)
        })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("월별 평균 심박수 (bpm)", systemImage: "heart.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.pink)
                
                Spacer()
                
                if let optimal = optimalHrMonth {
                    HStack(spacing: 4) {
                        Text("🎯 최적 유산소")
                            .font(.caption2.bold())
                            .foregroundStyle(.pink)
                        Text(optimal.heartRateDisplayString)
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
                    // Zone 2~3 유산소 심박 기준 영역 (130 ~ 155 bpm)
                    RectangleMark(
                        yStart: .value("유산소 하한", zone23Min),
                        yEnd: .value("유산소 상한", zone23Max)
                    )
                    .foregroundStyle(Color.pink.opacity(0.08))
                    
                    ForEach(hrSummaries) { item in
                        let hr = item.averageHeartRate ?? 0
                        let isOptimal = (item.id == optimalHrMonth?.id)
                        let inZone23 = (hr >= zone23Min && hr <= zone23Max)
                        
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
                        .foregroundStyle(isOptimal ? Color.pink : (inZone23 ? Color.pink.opacity(0.8) : Color.red))
                        .symbolSize(isOptimal ? 60 : 35)
                        .annotation(position: .top) {
                            VStack(spacing: 1) {
                                if isOptimal {
                                    Text("ZONE 2-3")
                                        .font(.system(size: 7.5, weight: .black))
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
