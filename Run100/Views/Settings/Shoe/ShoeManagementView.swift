//
//  ShoeManagementView.swift
//  Run100
//
//  Created by 이준성 on 9/24/26.
//

import SwiftUI
import SwiftData
import UIKit

/// 러닝화 관리 화면 (주력 신발 상태, 신발 목록, 은퇴 보관함)
struct ShoeManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RunningShoe.startDate, order: .reverse) private var allShoes: [RunningShoe]
    @Query(sort: \RunSession.date, order: .reverse) private var allSessions: [RunSession]
    
    @State private var showAddShoeSheet = false
    @State private var shoeToEdit: RunningShoe? = nil
    @State private var shoeToRetire: RunningShoe? = nil
    @State private var showRetireConfirmation = false
    @State private var shoeToDelete: RunningShoe? = nil
    @State private var showDeleteConfirmation = false
    
    // 현재 활성화된 주력 신발 (은퇴하지 않은 활성 신발)
    private var activeShoe: RunningShoe? {
        allShoes.first(where: { $0.isActive && !$0.isRetired })
    }
    
    // 보조/대기 중인 신발 (활성화되지 않았고 은퇴하지 않은 신발)
    private var standbyShoes: [RunningShoe] {
        allShoes.filter { !$0.isActive && !$0.isRetired }
    }
    
    // 은퇴한 신발 목록
    private var retiredShoes: [RunningShoe] {
        allShoes.filter { $0.isRetired }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 현재 주력 러닝화 카드
                if let shoe = activeShoe {
                    activeShoeHeroCard(shoe: shoe)
                } else {
                    noActiveShoeCard
                }
                
                // 2. 보조 / 대기 중인 러닝화 목록
                if !standbyShoes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("보유 중인 러닝화")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 4)
                        
                        ForEach(standbyShoes) { shoe in
                            standbyShoeRow(shoe: shoe)
                        }
                    }
                }
                
                // 3. 은퇴한 러닝화 보관함 (명예의 전당)
                if !retiredShoes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("은퇴한 러닝화 보관함")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(retiredShoes.count)켤레")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)
                        
                        ForEach(retiredShoes) { shoe in
                            retiredShoeRow(shoe: shoe)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("러닝화 관리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    shoeToEdit = nil
                    showAddShoeSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("등록")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.orange)
                }
            }
        }
        .sheet(isPresented: $showAddShoeSheet) {
            AddShoeSheet()
        }
        .sheet(item: $shoeToEdit) { shoe in
            AddShoeSheet(shoeToEdit: shoe)
        }
        .confirmationDialog(
            "러닝화 은퇴",
            isPresented: $showRetireConfirmation,
            titleVisibility: .visible
        ) {
            Button("은퇴 처리 (누적 거리 확정 및 보관)", role: .none) {
                if let shoe = shoeToRetire {
                    retireShoe(shoe)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            if let shoe = shoeToRetire {
                let dist = shoe.calculateTotalDistance(from: allSessions)
                Text("'\(shoe.name)' 러닝화를 은퇴 처리하시겠습니까? 현재까지의 총 누적 거리 \(String(format: "%.1f", dist))km가 보관함에 영구 보존됩니다.")
            }
        }
        .confirmationDialog(
            "러닝화 삭제",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                if let shoe = shoeToDelete {
                    deleteShoe(shoe)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("해당 러닝화 등록 정보를 완전히 삭제하시겠습니까?")
        }
    }
    
    // MARK: - 현재 주력 신발 히어로 카드
    @ViewBuilder
    private func activeShoeHeroCard(shoe: RunningShoe) -> some View {
        let totalDist = shoe.calculateTotalDistance(from: allSessions)
        let rate = shoe.wearRate(from: allSessions)
        let percent = Int(min(rate * 100, 999))
        let status = shoe.healthStatus(from: allSessions)
        let remaining = shoe.remainingKm(from: allSessions)
        
        VStack(alignment: .leading, spacing: 16) {
            // 상단: 타이틀 & 뱃지
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("CURRENT GEAR")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.orange)
                        
                        Text("주력 신발")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.14))
                            .foregroundStyle(Color.orange)
                            .clipShape(Capsule())
                    }
                    
                    Text(shoe.name)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // 상태 뱃지
                HStack(spacing: 5) {
                    Circle()
                        .fill(status.badgeColor)
                        .frame(width: 8, height: 8)
                    Text(status.label)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(status.badgeColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(status.badgeColor.opacity(0.12))
                .clipShape(Capsule())
            }
            
            // 중앙: 주행 거리 & 소모율 수치
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("누적 주행 거리")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", totalDist))
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("/ \(Int(shoe.targetLifespanKm)) km")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("소모율")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("\(percent)%")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(status.badgeColor)
                }
            }
            
            // 프로그레스 바
            GeometryReader { geo in
                let w = geo.size.width
                let fillW = min(max(w * CGFloat(rate), 0), w)
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 10)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, status.badgeColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillW, height: 10)
                }
            }
            .frame(height: 10)
            
            // 하단 안내 가이드
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(status.badgeColor)
                
                if rate < 1.0 {
                    Text("교체 권장까지 약 \(String(format: "%.0f", remaining))km 남음 · \(status.description)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    Text("권장 수명을 \(String(format: "%.0f", totalDist - shoe.targetLifespanKm))km 초과함 · \(status.description)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.red)
                }
            }
            .padding(.top, -4)
            
            Divider()
            
            // 액션 버튼 (수정, 은퇴)
            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    shoeToEdit = shoe
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("정보 수정")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    shoeToRetire = shoe
                    showRetireConfirmation = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "archivebox")
                        Text("은퇴시키기")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - 주력 신발 없을 때 안내 카드
    private var noActiveShoeCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "shoe.2.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.orange)
                .padding(.top, 6)
            
            VStack(spacing: 4) {
                Text("현재 착용 중인 러닝화가 없습니다")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                Text("신고 계신 러닝화를 등록하면 달릴 때마다 자동으로 누적 거리가 쌓이고 교체 시기를 알려드립니다.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                shoeToEdit = nil
                showAddShoeSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("첫 러닝화 등록하기")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.orange)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - 대기 중인 신발 행
    @ViewBuilder
    private func standbyShoeRow(shoe: RunningShoe) -> some View {
        let totalDist = shoe.calculateTotalDistance(from: allSessions)
        let status = shoe.healthStatus(from: allSessions)
        let rate = shoe.wearRate(from: allSessions)
        let percent = Int(min(rate * 100, 999))
        
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(shoe.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text(shoe.shoeType.title)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 6) {
                    Text("\(String(format: "%.1f", totalDist))km / \(Int(shoe.targetLifespanKm))km")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("(\(percent)% 소모)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(status.badgeColor)
                }
            }
            
            Spacer()
            
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                activateShoe(shoe)
            } label: {
                Text("주력 지정")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Menu {
                Button {
                    shoeToEdit = shoe
                } label: {
                    Label("수정", systemImage: "pencil")
                }
                
                Button {
                    shoeToRetire = shoe
                    showRetireConfirmation = true
                } label: {
                    Label("은퇴 처리", systemImage: "archivebox")
                }
                
                Button(role: .destructive) {
                    shoeToDelete = shoe
                    showDeleteConfirmation = true
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - 은퇴한 신발 행
    @ViewBuilder
    private func retiredShoeRow(shoe: RunningShoe) -> some View {
        let finalDist = shoe.retiredTotalDistanceKm ?? shoe.calculateTotalDistance(from: allSessions)
        
        HStack(spacing: 12) {
            Image(systemName: "archivebox.fill")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(shoe.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("최종 누적 주행: \(String(format: "%.1f", finalDist)) km")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    unretireShoe(shoe)
                } label: {
                    Label("다시 신기 (보관 해제)", systemImage: "arrow.uturn.backward")
                }
                
                Button(role: .destructive) {
                    shoeToDelete = shoe
                    showDeleteConfirmation = true
                } label: {
                    Label("완전 삭제", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - 신발 상태 제어 메서드
    private func activateShoe(_ shoe: RunningShoe) {
        for s in allShoes {
            s.isActive = (s.id == shoe.id)
        }
        shoe.isRetired = false
        shoe.retiredTotalDistanceKm = nil
        try? modelContext.save()
    }
    
    private func retireShoe(_ shoe: RunningShoe) {
        shoe.retiredTotalDistanceKm = shoe.calculateTotalDistance(from: allSessions)
        shoe.retiredDate = Date()
        shoe.isRetired = true
        shoe.isActive = false
        try? modelContext.save()
    }
    
    private func unretireShoe(_ shoe: RunningShoe) {
        shoe.isRetired = false
        shoe.retiredTotalDistanceKm = nil
        activateShoe(shoe)
    }
    
    private func deleteShoe(_ shoe: RunningShoe) {
        modelContext.delete(shoe)
        try? modelContext.save()
    }
}
