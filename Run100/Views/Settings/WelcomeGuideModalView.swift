//
//  WelcomeGuideModalView.swift
//  Run100
//
//  Created by 이준성 on 10/9/26.
//

import SwiftUI

/// 앱 처음 사용자 및 가이드 조회를 위한 애플 스타일 스와이프 온보딩 가이드 모달
struct WelcomeGuideModalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: Int = 0
    
    private let totalSteps = 5
    
    // 가이드 카드 데이터 모델
    private struct GuideSlide: Identifiable {
        let id: Int
        let badge: String
        let title: String
        let subtitle: String
        let systemImage: String
        let iconTint: Color
        let points: [(icon: String, text: String)]
    }
    
    private let slides: [GuideSlide] = [
        GuideSlide(
            id: 0,
            badge: "핵심 철학",
            title: "시작 버튼을 누르지 마세요",
            subtitle: "측정 대신 기록과 회고에 100% 집중합니다.",
            systemImage: "applewatch.radiowaves.left.and.right",
            iconTint: .orange,
            points: [
                ("applewatch", "애플워치, 가민, 기존 러닝 앱으로 평소처럼 자유롭게 달리고 오세요."),
                ("heart.text.square.fill", "Apple 건강(HealthKit)을 통해 3초 만에 자동으로 기록이 동기화됩니다."),
                ("square.and.pencil", "언제든 캘린더나 대시보드에서 수기 직접 입력도 가능해요.")
            ]
        ),
        GuideSlide(
            id: 1,
            badge: "대시보드",
            title: "이번 달 나의 러닝 성적표",
            subtitle: "월 100km 완주와 평균 페이스 & 심박수를 확인하세요.",
            systemImage: "circle.inset.filled",
            iconTint: .orange,
            points: [
                ("flame.fill", "100km 목표를 향해 실시간으로 차오르는 오렌지-앰버 프로그레스 링"),
                ("speedometer", "당월 전체 러닝의 '평균 페이스'와 '평균 심박수' 듀얼 성적표 즉각 회고"),
                ("trophy.fill", "100km 돌파 시 빛나는 '🔥 초과달성 🔥' 명예 뱃지 획득")
            ]
        ),
        GuideSlide(
            id: 2,
            badge: "고스트 레이스",
            title: "과거 나와의 결승선 맞대결",
            subtitle: "100m 육상 결승 트랙 위에서 펼쳐지는 올림픽 스타디움 레이스",
            systemImage: "figure.run.treadmill",
            iconTint: .red,
            points: [
                ("flag.checkered.2.crossed", "1번 레인의 '현재의 나' vs 2~4번 레인의 '과거 3개월의 나'"),
                ("calendar", "동일 일자(당월 N일차) 기준 누적 거리로 레인별 주자 위치가 실시간 결정"),
                ("bolt.fill", "지난달의 나를 앞지를 때 느끼는 짜릿한 성취감과 동기부여")
            ]
        ),
        GuideSlide(
            id: 3,
            badge: "러닝 캘린더",
            title: "매일 채워지는 습관의 잔디",
            subtitle: "월간 출석체크와 2차원 산점도로 러닝 품질을 분석하세요.",
            systemImage: "calendar.badge.checkmark",
            iconTint: .green,
            points: [
                ("square.grid.3x3.fill", "뛴 거리에 따라 4단계로 채도가 짙어지는 30일 잔디 매트릭스"),
                ("flame", "매일 달리는 연속 출석 스트릭(🔥 Streak)으로 러닝 습관 형성"),
                ("chart.dots.scatter", "'거리 × 페이스' 2차원 산점도로 당월 주행 효율성과 강도 분석")
            ]
        ),
        GuideSlide(
            id: 4,
            badge: "장비 관리 & 위젯",
            title: "러닝화 수명과 홈 화면 위젯",
            subtitle: "소중한 러닝화를 지키고 홈 화면에서 상시 동기부여를 받으세요.",
            systemImage: "shoe.2.fill",
            iconTint: .blue,
            points: [
                ("gauge.with.needle.fill", "쿠션화(600km)·훈련화(500km)·레이싱화(300km) 권장 수명 자동 관리"),
                ("arrow.triangle.2.circlepath", "2켤레 이상 러닝화 로테이션 및 세션별 착용 신발 1초 매핑"),
                ("square.grid.2x2.fill", "iOS 홈 화면 Medium 위젯으로 앱을 켜지 않고도 100km 진행률 상시 확인")
            ]
        )
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 단계 인디케이터 바
                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { idx in
                        Capsule()
                            .fill(idx == currentStep ? Color.orange : Color(.tertiarySystemFill))
                            .frame(height: 4)
                            .frame(maxWidth: idx == currentStep ? 28 : 12)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentStep)
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 6)
                
                // 스와이프 페이징 카드 뷰
                TabView(selection: $currentStep) {
                    ForEach(slides) { slide in
                        slideContentView(slide: slide)
                            .tag(slide.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 하단 인터랙션 컨트롤러
                bottomControlBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .padding(.top, 8)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
        }
    }
    
    // MARK: - 슬라이드 본문 뷰
    private func slideContentView(slide: GuideSlide) -> some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)
            
            // 중앙 비주얼 아이콘 엠블럼
            ZStack {
                Circle()
                    .fill(slide.iconTint.opacity(0.12))
                    .frame(width: 96, height: 96)
                
                Circle()
                    .stroke(slide.iconTint.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 108, height: 108)
                
                Image(systemName: slide.systemImage)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(slide.iconTint)
            }
            .padding(.top, 10)
            
            // 타이틀 & 배지 헤더
            VStack(spacing: 6) {
                Text(slide.badge)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(slide.iconTint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(slide.iconTint.opacity(0.12))
                    .clipShape(Capsule())
                
                Text(slide.title)
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text(slide.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // 3대 핵심 포인트 카드
            VStack(spacing: 9) {
                ForEach(slide.points, id: \.text) { point in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: point.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(slide.iconTint)
                            .frame(width: 20, height: 20)
                            .padding(.top, 1)
                        
                        Text(point.text)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.primary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            
            Spacer(minLength: 16)
        }
    }
    
    // MARK: - 하단 컨트롤 바
    private var bottomControlBar: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        currentStep -= 1
                    }
                } label: {
                    Text("이전")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 80)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if currentStep < totalSteps - 1 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        currentStep += 1
                    }
                } else {
                    dismiss()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentStep == totalSteps - 1 ? "Run100 시작하기 🏃" : "다음")
                        .font(.system(size: 16, weight: .bold))
                    
                    if currentStep < totalSteps - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color(red: 0.95, green: 0.40, blue: 0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}

#Preview {
    WelcomeGuideModalView()
}
