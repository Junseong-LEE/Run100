//
//  Run100Widget.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import WidgetKit

/// 위젯 타임라인 엔트리 모델
struct SimpleWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetSnapshotData
}

/// 위젯 타임라인 제공자 (TimelineProvider)
struct Run100WidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleWidgetEntry {
        SimpleWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleWidgetEntry) -> Void) {
        let snapshot = WidgetDataBridge.shared.loadSnapshot()
        let entry = SimpleWidgetEntry(date: Date(), data: snapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleWidgetEntry>) -> Void) {
        let currentDate = Date()
        let snapshot = WidgetDataBridge.shared.loadSnapshot()
        let entry = SimpleWidgetEntry(date: currentDate, data: snapshot)
        
        // 1시간 주기로 위젯 타임라인 자동 갱신 (앱 실행 시에는 WidgetCenter를 통해 즉시 리로드됨)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

/// Run100 홈 화면 Medium(2x4) 단일 규격 위젯 정의
struct Run100MediumWidget: Widget {
    let kind: String = "Run100MediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Run100WidgetProvider()) { entry in
            MediumWidgetView(data: entry.data)
        }
        .configurationDisplayName("Run100 월간 러닝")
        .description("이번 달 완주율과 오늘 권장 달리기, 최근 7일 잔디 심기를 한눈에 확인하세요.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
