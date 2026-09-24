//
//  ProgressRingView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI

/// 100km 목표 달성률을 시각화하는 원형 프로그레스 링 컴포넌트
struct ProgressRingView: View {
    let currentKm: Double
    let targetKm: Double
    let progressRatio: Double
    let percentage: Int
    
    // 오렌지-앰버 그라디언트
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
        ZStack {
            // 배경 트랙 링
            Circle()
                .stroke(
                    Color(.systemGray5),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
            
            // 게이지 프로그레스 링 (최대 100% 꽉 채움)
            Circle()
                .trim(from: 0, to: CGFloat(min(progressRatio, 1.0)))
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.75), value: progressRatio)
            
            // 링 중앙 텍스트 콘텐츠
            VStack(spacing: 2) {
                Text(String(format: "%.1f", currentKm))
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("/ \(Int(targetKm)) km")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .offset(y: -2)
                
                let isOverachieved = targetKm > 0 && currentKm > targetKm + 0.05
                
                HStack(spacing: 3) {
                    if isOverachieved {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8.5, weight: .bold))
                        Text("초과달성 중")
                    } else {
                        Text("\(min(percentage, 100))% 달성")
                    }
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color.orange.opacity(isOverachieved ? 0.2 : 0.15))
                .clipShape(Capsule())
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.top, 2)
            }
        }
        .frame(width: 144, height: 144)
    }
}

#Preview {
    ProgressRingView(currentKm: 68.0, targetKm: 100.0, progressRatio: 0.68, percentage: 68)
        .padding()
}
