//
//  RunningTrackProgressCard.swift
//  Run100
//
//  기능 F-103: 4레인 스타디움 레이스 트랙 & 최근 3개월 동기간 경쟁 (4-Lane Stadium Track & Past Ghost Competition)
//

import SwiftUI

struct RunningTrackProgressCard: View {
    let progress: MonthlyProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // MARK: - 1. 트랙 헤더 (제목 & 완주/순위 배지)
            trackHeaderView
            
            // MARK: - 2. 1~4번 레인 스타디움 레이스 트랙
            raceTrackView
            
            // MARK: - 구분선
            Divider()
                .background(Color(.separator))
            
            // MARK: - 3. 하단 실시간 코칭 요약 (동기간 N일차 기준)
            trackFooterView
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 1. 트랙 헤더
    private var trackHeaderView: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 5) {
                Text("🏃")
                    .font(.system(size: 15))
                Text("100km 레이스 트랙")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // 완주 달성 시 축하 뱃지, 미완주 시 현재 순위 뱃지 표시
            if progress.isGoalAchieved {
                let badgeText = progress.isOverachieved
                    ? String(format: "🏆 완주 (+%.1fkm)", progress.excessKm)
                    : "🏆 완주"
                
                Text(badgeText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Text("현재 \(progress.currentMonthRank)위")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(rankColor(rank: progress.currentMonthRank))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(rankColor(rank: progress.currentMonthRank).opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - 2. 1~4번 레인 스타디움 레이스 트랙 본체
    private var raceTrackView: some View {
        VStack(spacing: 6) {
            // 상단 거리 룰러 눈금 (0k, 25k, 50k, 75k, 100k)
            trackRulerView
            
            // 4개 레인 스택 (1번: 이번 달, 2~4번: 과거 3개월)
            VStack(spacing: 7) {
                ForEach(trackLanes) { lane in
                    trackLaneRow(lane: lane)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 트랙 상단 체크포인트 룰러
    private var trackRulerView: some View {
        HStack(spacing: 0) {
            // 좌측 라벨 여백 맞춤 (32pt 라벨 + 8pt 간격)
            Spacer()
                .frame(width: 40)
            
            // 트랙 레인 중앙 구간에 일치하는 체크포인트 눈금
            HStack {
                Text("0k")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                Spacer()
                Text("25k")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                Spacer()
                Text("50k")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                Spacer()
                Text("75k")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                Spacer()
                Text("100k")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.orange.opacity(0.85))
            }
            
            // 우측 거리 라벨 여백 맞춤 (70pt 라벨 + 8pt 간격)
            Spacer()
                .frame(width: 78)
        }
    }
    
    // MARK: - 개별 레인 행 (1~4번)
    private func trackLaneRow(lane: TrackLaneData) -> some View {
        HStack(spacing: 8) {
            // 1. 좌측 월 라벨 (폭 32pt)
            Text(lane.monthTitle)
                .font(.system(size: 12, weight: lane.isCurrentMonth ? .heavy : .medium))
                .foregroundStyle(lane.isCurrentMonth ? Color.primary : Color.secondary)
                .frame(width: 32, alignment: .leading)
            
            // 2. 중앙 스타디움 레인 바
            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let trackHeight: CGFloat = 13
                let iconSize: CGFloat = 14
                
                let ratio = CGFloat(min(max(lane.cumulativeKm / max(lane.targetKm, 1.0), 0.0), 1.0))
                
                let minX: CGFloat = iconSize / 2 + 3
                let maxX: CGFloat = max(trackWidth - iconSize / 2 - 3, minX)
                let iconX = minX + (maxX - minX) * ratio
                
                ZStack(alignment: .leading) {
                    // 2-1. 트랙 바탕 바 (우레탄 질감)
                    Capsule()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: trackHeight)
                        .overlay(
                            Capsule()
                                .stroke(
                                    lane.isCurrentMonth
                                        ? Color.orange.opacity(0.35)
                                        : Color.primary.opacity(0.06),
                                    lineWidth: 1
                                )
                        )
                    
                    // 2-2. 누적 주행 게이지 채움 바
                    if lane.isAvailable && lane.cumulativeKm > 0 {
                        Capsule()
                            .fill(
                                lane.isCurrentMonth
                                    ? LinearGradient(
                                        colors: progress.isGoalAchieved
                                            ? [Color.orange, Color.yellow]
                                            : [Color.orange.opacity(0.85), Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.secondary.opacity(0.25), Color.secondary.opacity(0.42)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                            .frame(width: max(trackWidth * ratio, trackHeight), height: trackHeight)
                    }
                    
                    // 2-3. 레인 중앙 가이드 점선
                    TrackDashLine()
                        .stroke(
                            Color.white.opacity(lane.isCurrentMonth ? 0.35 : 0.2),
                            style: StrokeStyle(lineWidth: 1.0, lineCap: .round, dash: [3, 4])
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 6)
                    
                    // 2-4. 출발선 (Start Line)
                    Capsule()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 1.5, height: trackHeight - 4)
                        .offset(x: 4)
                    
                    // 2-5. 결승선 (Finish Line: 더블 피니시 바)
                    HStack(spacing: 1.5) {
                        Capsule()
                            .fill((lane.isCurrentMonth && progress.isGoalAchieved) ? Color.yellow : Color.white.opacity(0.8))
                            .frame(width: 1.5, height: trackHeight - 4)
                        Capsule()
                            .fill((lane.isCurrentMonth && progress.isGoalAchieved) ? Color.orange : Color.white.opacity(0.4))
                            .frame(width: 1.5, height: trackHeight - 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(x: -4)
                    
                    // 2-6. 러너 (🏃/🎉) 아이콘 (모든 레인 오른쪽 방향 질주)
                    if lane.isAvailable {
                        Group {
                            if lane.isCurrentMonth {
                                if progress.isGoalAchieved {
                                    Text("🎉")
                                        .font(.system(size: iconSize))
                                } else {
                                    Text("🏃")
                                        .font(.system(size: iconSize))
                                        .scaleEffect(x: -1, y: 1) // 오른쪽 방향으로 달리기
                                }
                            } else {
                                Text("🏃")
                                    .font(.system(size: iconSize))
                                    .scaleEffect(x: -1, y: 1) // 오른쪽 방향으로 달리기
                                    .opacity(lane.cumulativeKm > 0 ? 0.85 : 0.4)
                            }
                        }
                        .position(x: iconX, y: geometry.size.height / 2)
                        .shadow(
                            color: lane.isCurrentMonth ? Color.orange.opacity(0.35) : Color.clear,
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                    }
                }
                .frame(height: geometry.size.height)
            }
            .frame(height: 18)
            
            // 3. 우측 누적 거리 & 순위 (폭 70pt)
            HStack(spacing: 2) {
                if lane.isAvailable {
                    HStack(spacing: 1) {
                        Text(String(format: "%.1f", lane.cumulativeKm))
                            .font(.system(size: lane.isCurrentMonth ? 12 : 11, weight: lane.isCurrentMonth ? .heavy : .bold, design: .rounded))
                            .foregroundStyle(lane.isCurrentMonth ? Color.orange : Color.primary)
                        
                        Text("k")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(lane.isCurrentMonth ? Color.orange.opacity(0.85) : Color.secondary)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    
                    if let rank = lane.rank, !rankMedal(rank: rank).isEmpty {
                        Text(rankMedal(rank: rank))
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 17, alignment: .trailing)
                    } else {
                        Spacer()
                            .frame(width: 17)
                    }
                } else {
                    Text("대기")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 0)
    }
    
    // MARK: - 3. 하단 코칭 요약 바
    private var trackFooterView: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.orange)
            
            Text(progress.ghostCompetitionMessage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.orange)
                .lineLimit(1)
            
            Spacer(minLength: 4)
            
            Text("동기간 \(progress.currentCompareDay)일차")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Color(.tertiarySystemFill))
                .clipShape(Capsule())
        }
        .padding(.top, 2)
    }
    
    // MARK: - 4개 레인 데이터 계산
    private var trackLanes: [TrackLaneData] {
        let calendar = Calendar.current
        let today = Date()
        let comparisons = progress.samePeriodComparisons
        
        // 1번 레인: 이번 달 (현재)
        let currentRank = progress.currentMonthRank
        let lane1 = TrackLaneData(
            id: 1,
            laneNumber: 1,
            monthTitle: "\(progress.month)월",
            cumulativeKm: progress.totalAccumulatedKm,
            targetKm: progress.targetKm,
            isCurrentMonth: true,
            rank: currentRank,
            isAvailable: true
        )
        
        var lanes: [TrackLaneData] = [lane1]
        
        // 2, 3, 4번 레인: 1달 전(-1), 2달 전(-2), 3달 전(-3)
        for offset in [-1, -2, -3] {
            let laneNum = 1 - offset // 2, 3, 4
            
            // 대상 월 계산 (예: 9월 기준 -> 8월, 7월, 6월)
            var comp = DateComponents()
            comp.year = progress.year
            comp.month = progress.month + offset
            let date = calendar.date(from: comp) ?? today
            let targetMonth = calendar.component(.month, from: date)
            
            if let pastItem = comparisons.first(where: { $0.monthOffset == offset }) {
                let rankIndex = comparisons.firstIndex(where: { $0.id == pastItem.id }) ?? 0
                lanes.append(TrackLaneData(
                    id: laneNum,
                    laneNumber: laneNum,
                    monthTitle: "\(pastItem.month)월",
                    cumulativeKm: pastItem.cumulativeKm,
                    targetKm: progress.targetKm,
                    isCurrentMonth: false,
                    rank: rankIndex + 1,
                    isAvailable: true
                ))
            } else {
                lanes.append(TrackLaneData(
                    id: laneNum,
                    laneNumber: laneNum,
                    monthTitle: "\(targetMonth)월",
                    cumulativeKm: 0.0,
                    targetKm: progress.targetKm,
                    isCurrentMonth: false,
                    rank: nil,
                    isAvailable: false
                ))
            }
        }
        
        return lanes
    }
    
    // 순위 메달 (1~3위만 메달 표출, 4위 이하는 빈 문자열)
    private func rankMedal(rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
    
    // 순위 색상
    private func rankColor(rank: Int) -> Color {
        switch rank {
        case 1: return Color.orange
        case 2: return Color.blue
        case 3: return Color.purple
        default: return Color.secondary
        }
    }
}

/// 4레인 트랙 정보 모델
private struct TrackLaneData: Identifiable {
    let id: Int
    let laneNumber: Int
    let monthTitle: String
    let cumulativeKm: Double
    let targetKm: Double
    let isCurrentMonth: Bool
    let rank: Int?
    let isAvailable: Bool
}

/// 트랙 레인 중앙 점선 Shape
private struct TrackDashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
