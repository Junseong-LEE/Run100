//
//  MediumWidgetView.swift
//  Run100Widget
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import WidgetKit

/// [F-102] 대시보드 히어로 카드(프로그레스 링 + 평균 페이스/심박수 카드)와 1:1 대응되는 홈 화면 Medium(2x4) 위젯 전용 뷰
struct MediumWidgetView: View {
    let data: WidgetSnapshotData
    
    @Environment(\.colorScheme) private var systemColorScheme
    
    // 앱 설정 테마("dark", "light", "system")와 위젯 테마 동기화
    private var effectiveColorScheme: ColorScheme {
        switch data.appTheme {
        case "dark": return .dark
        case "light": return .light
        default: return systemColorScheme
        }
    }
    
    private var progressRatio: Double {
        guard data.targetKm > 0 else { return 0.0 }
        return min(max(data.totalAccumulatedKm / data.targetKm, 0.0), 1.0)
    }
    
    // 오렌지-앰버 그라디언트 (F-102 ProgressRingView와 동일)
    private let ringGradient = AngularGradient(
        gradient: Gradient(colors: [
            Color(red: 0.98, green: 0.45, blue: 0.09), // Vibrant Orange (#F97316)
            Color(red: 0.98, green: 0.75, blue: 0.14), // Amber Gold (#FBBF24)
            Color(red: 0.98, green: 0.45, blue: 0.09)
        ]),
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - [좌측] F-102 원형 프로그레스 링 (ProgressRingView 축소판)
            ZStack {
                // 배경 트랙 링
                Circle()
                    .stroke(
                        effectiveColorScheme == .dark ? Color.white.opacity(0.12) : Color(.systemGray5),
                        style: StrokeStyle(lineWidth: 10.5, lineCap: .round)
                    )
                
                // 게이지 프로그레스 링
                Circle()
                    .trim(from: 0, to: CGFloat(min(progressRatio, 1.0)))
                    .stroke(
                        ringGradient,
                        style: StrokeStyle(lineWidth: 10.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // 링 내부 텍스트 콘텐츠
                VStack(spacing: 1) {
                    Text(String(format: "%.1f", data.totalAccumulatedKm))
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
                    
                    Text("/ \(Int(data.targetKm)) km")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .offset(y: -1)
                    
                    let isOverachieved = data.targetKm > 0 && data.totalAccumulatedKm > data.targetKm + 0.05
                    
                    HStack(spacing: 2.5) {
                        if isOverachieved {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 7.5, weight: .bold))
                            Text("초과달성 중")
                        } else {
                            Text("\(min(data.completionPercentage, 100))% 달성")
                        }
                    }
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(isOverachieved ? 0.2 : 0.15))
                    .clipShape(Capsule())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 1)
                }
            }
            .frame(width: 114, height: 114)
            .padding(.leading, 2)
            
            // MARK: - [우측] F-102 2단 정보 카드 (이번 달 평균 페이스 & 평균 심박수)
            VStack(spacing: 7) {
                // 1. 이번 달 평균 페이스 카드
                VStack(alignment: .leading, spacing: 2.5) {
                    HStack {
                        Text("이번 달 평균 페이스")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "speedometer")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(Color.orange)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2.5) {
                        Text(data.paceValueOnly)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("/km")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.orange)
                    }
                    
                    Text("\(data.sessionsCount)회 러닝 • \(data.formattedTotalDuration)")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // 2. 이번 달 평균 심박수 카드
                VStack(alignment: .leading, spacing: 2.5) {
                    HStack {
                        Text("이번 달 평균 심박수")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(Color.red)
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(Color.red)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2.5) {
                        Text(data.heartRateValueOnly)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("bpm")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.red)
                    }
                    
                    Text(data.heartRateStatusMessage)
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.red.opacity(0.20), lineWidth: 0.8)
                )
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .environment(\.colorScheme, effectiveColorScheme)
        .containerBackground(for: .widget) {
            if effectiveColorScheme == .dark {
                Color(red: 0.11, green: 0.11, blue: 0.12)
            } else {
                Color(uiColor: .secondarySystemGroupedBackground)
            }
        }
    }
}

#Preview("Medium Widget (Light)", as: .systemMedium) {
    Run100Widget()
} timeline: {
    SimpleWidgetEntry(date: Date(), data: .placeholder)
}

#Preview("Medium Widget (Dark)") {
    MediumWidgetView(data: .placeholder)
        .frame(width: 338, height: 158)
        .preferredColorScheme(.dark)
}
