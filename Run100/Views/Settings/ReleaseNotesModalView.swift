//
//  ReleaseNotesModalView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI

struct ReleaseNotesModalView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 버전별 주요 변경점 목록
    private let releases: [ReleaseNoteItem] = [
        ReleaseNoteItem(
            version: "v1.2.1",
            date: "2026.09.24",
            isLatest: true,
            title: "1~4번 레인 육상 스타디움 트랙 & 목표 초과 달성 위트 있는 시각화",
            highlights: [
                "🏟️ 1~4번 레인 육상 스타디움 트랙: 실제 100m 결승 트랙 모티브의 독립 4레인 및 상단 0k~100k 체크포인트 룰러 탑재",
                "🏃 전 레인 균일화 및 러너 질주: 전 레인 트랙 두께 13pt 균일화, 모노크롬 슬레이트 그레이 트랙 및 오른쪽 방향 러너(🏃) 통일",
                "📊 스코어보드 & 줄바꿈 최적화: 우측 폭 70pt 확장 및 줄바꿈 방지 적용, 순위 메달(🥇, 🥈, 🥉)과 콤팩트 코칭 요약 문구 제공",
                "🔥 초과달성 배지: 100km를 초과할 경우 대시보드 링 중앙에 SF Symbols 불꽃 심볼이 적용된 '초과달성 중' 앰버 캡슐 배지 표출",
                "🏆 완주 초과 거리 표기: 트랙 헤더에 '🏆 완주 (+X.Xkm)' 형태로 보너스 달린 거리 실시간 안내",
                "🚀 한계 돌파 코칭 메시지: 100km 완주 후에도 지속적인 러닝을 독려하는 레전드 러너 코칭 문구",
                "🗓️ 캘린더 '출석체크' 개편 & 통계 슬림화: 텍스트를 덜어내고 세련된 SF Symbols 심볼 칩으로 콤팩트화, 'N월 출석체크'로 직관적인 명칭 변경",
                "📊 일별 러닝 거리 막대 차트: 1일부터 말일까지 일자별 주행 거리(km) 비교 및 터치 시 캘린더·상세 카드 실시간 연동",
                "✨ 테스트 샘플 데이터 지원: 설정 탭에서 최근 4개월(당월 112.5km 초과달성 포함) 샘플 데이터를 탭 한 번에 채우기 지원"
            ]
        ),
        ReleaseNoteItem(
            version: "v1.2.0",
            date: "2026.09.20",
            isLatest: false,
            title: "100km 레이스 트랙 & 과거의 나와 고스트 경쟁",
            highlights: [
                "🏃 100km 실시간 레이스 트랙: 결승선(오른쪽)을 향해 달리는 러너 이모지와 누적 거리 말풍선",
                "🏆 완주 배지 심플화: 100km 목표 도달 시 깔끔한 '🏆 완주' 배지로 미니멀화",
                "👻 트랙 위 고스트 핀: 과거 3개월의 동기간(N일차) 누적 거리가 트랙 위 유령 핀으로 함께 주행",
                "🥇 최근 3개월 동기간 경쟁: 당월과 과거 3개월의 동일 시점 거리 순위 및 차이값 비교",
                "📐 3개 탭 헤더 위치 통일: 대시보드·캘린더·히스토리 상단 시작 높이(Y축) 칼각 일치",
                "🗓️ 히스토리 월 선택기 연동: 우측 상단 < M월 ▾ > 버튼 탑재 및 전 탭 상태 실시간 동기화",
                "📊 히스토리 기간 필터 개편: 중복된 6개월 제거, '최근 12개월(기본)'과 '올해' 2개 탭 구성",
                "📱 F-102 히어로 카드 위젯: 바탕화면에서 대시보드와 동일한 100km 링 & 페이스/심박 2단 카드 확인",
                "📈 월별 종합 성적표 칼각 정렬: 거리, 페이스, 심박, 달린 날 4대 지표 수직 일렬 정렬",
                "⚡️ 건강 동기화 일원화: 대시보드 당겨서 새로고침(Pull-to-Refresh) 지원"
            ]
        ),
        ReleaseNoteItem(
            version: "v1.1.0",
            date: "2026.09.19",
            isLatest: false,
            title: "히스토리 탭 신설 & 4대 지표 다차원 성장 추이",
            highlights: [
                "📊 하단 3번째 '히스토리' 탭 신설 (최근 6개월 / 12개월 분석)",
                "📈 거리, 페이스, 심박수, 출석률 4대 지표별 Swift Charts 시각화",
                "🏆 100km 완주 월 골드 하이라이트 및 최고 기록(BEST) 월 자동 안내",
                "🎯 차트 Y축 라벨 정리로 시원한 풀와이드 비주얼 제공"
            ]
        ),
        ReleaseNoteItem(
            version: "v1.0.0",
            date: "2026.09.19",
            isLatest: false,
            title: "Run100 정식 출시",
            highlights: [
                "🏃 월 100km 누적 달리기 챌린지 및 D-Day 역산 코칭",
                "🌱 깃허브 스타일 데일리 잔디 심기 히트맵 캘린더",
                "⌚️ Apple Watch & 애플 건강(HealthKit) 백그라운드 자동 연동",
                "📱 잠금화면 / 홈화면 Medium 위젯 지원"
            ]
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 상단 헤더 배너
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text("🏃")
                                .font(.title3)
                            Text("Run100 업데이트 히스토리")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        Text("러너의 꾸준한 습관 형성을 위해 지속적으로 진화하고 있습니다.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // 버전별 카드 리스트
                    ForEach(releases) { release in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Text(release.version)
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(release.isLatest ? Color.orange : .primary)
                                    
                                    if release.isLatest {
                                        Text("최신 버전")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                Spacer()
                                
                                Text(release.date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(release.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(release.highlights, id: \.self) { highlight in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .font(.caption)
                                            .foregroundStyle(Color.orange)
                                        Text(highlight)
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(release.isLatest ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle("릴리즈 노트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.orange)
                }
            }
        }
    }
}

private struct ReleaseNoteItem: Identifiable {
    var id: String { version }
    let version: String
    let date: String
    let isLatest: Bool
    let title: String
    let highlights: [String]
}
