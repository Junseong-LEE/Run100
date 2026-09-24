//
//  ShoeWearCardView.swift
//  Run100
//
//  Created by 이준성 on 9/24/26.
//

import SwiftUI
import SwiftData
import UIKit

/// 대시보드 주력 러닝화 소모 게이지 카드 (추천 2)
struct ShoeWearCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allShoes: [RunningShoe]
    @Query private var allSessions: [RunSession]
    
    var onOpenManagement: (() -> Void)? = nil
    
    private var activeShoe: RunningShoe? {
        allShoes.first(where: { $0.isActive && !$0.isRetired })
    }
    
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onOpenManagement?()
        } label: {
            if let shoe = activeShoe {
                activeCardContent(shoe: shoe)
            } else {
                emptyCardContent
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 활성 신발 소모 게이지 카드
    @ViewBuilder
    private func activeCardContent(shoe: RunningShoe) -> some View {
        let totalDist = shoe.calculateTotalDistance(from: allSessions)
        let rate = shoe.wearRate(from: allSessions)
        let percent = Int(min(rate * 100, 999))
        let status = shoe.healthStatus(from: allSessions)
        let remaining = shoe.remainingKm(from: allSessions)
        
        VStack(alignment: .leading, spacing: 12) {
            // 1. 헤더: 라벨 & 신발 유형 & 상태 뱃지
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "shoe.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.orange)
                    
                    Text("주력 러닝화")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Text(shoe.shoeType.title)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                // 상태 뱃지
                HStack(spacing: 4) {
                    Circle()
                        .fill(status.badgeColor)
                        .frame(width: 7, height: 7)
                    Text(status.label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(status.badgeColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.badgeColor.opacity(0.12))
                .clipShape(Capsule())
            }
            
            // 2. 신발 모델명
            HStack(alignment: .firstTextBaseline) {
                Text(shoe.name)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if !shoe.brand.isEmpty {
                    Text(shoe.brand)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            
            // 3. 누적 거리 & 소모율
            HStack(alignment: .bottom) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", totalDist))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(" / \(Int(shoe.targetLifespanKm)) km")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(percent)% 소모")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(status.badgeColor)
            }
            
            // 4. 프로그레스 바
            GeometryReader { geo in
                let w = geo.size.width
                let fillW = min(max(w * CGFloat(rate), 0), w)
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, status.badgeColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillW, height: 8)
                }
            }
            .frame(height: 8)
            
            // 5. 하단 캡션 안내
            HStack(spacing: 5) {
                Image(systemName: rate < 1.0 ? "heart.text.square.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(status.badgeColor)
                
                if rate < 1.0 {
                    Text("교체 권장까지 약 \(String(format: "%.0f", remaining))km 남음")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text("권장 수명 \(String(format: "%.0f", totalDist - shoe.targetLifespanKm))km 초과 · 교체 권장")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.red)
                }
                
                Spacer()
                
                Text("관리 >")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.orange)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - 등록된 신발 없을 때 유도 카드
    private var emptyCardContent: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "shoe.2.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.orange)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("러닝화 수명 트래킹")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                Text("신고 계신 러닝화를 등록하고 교체 시기를 확인하세요")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("등록")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
