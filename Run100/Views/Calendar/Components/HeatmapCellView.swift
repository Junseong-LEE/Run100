//
//  HeatmapCellView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI

/// 캘린더 히트맵의 단일 날짜 셀 (깃허브 잔디 심기 스타일)
struct HeatmapCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let day: Int
    let distanceKm: Double
    let isToday: Bool
    let isSelected: Bool
    let isFuture: Bool
    
    // 달린 거리별 4단계 색상 매핑 (라이트/다크 적응형)
    private var cellBackgroundColor: Color {
        if isFuture {
            return Color(.tertiarySystemFill).opacity(0.4)
        }
        
        if distanceKm == 0 {
            // 휴식 Day
            return colorScheme == .dark
                ? Color(red: 0.15, green: 0.15, blue: 0.16) // #27272A
                : Color(.systemGray6)
        } else if distanceKm < 5.0 {
            // 0.1 ~ 4.9 km (Low Intensity)
            return colorScheme == .dark
                ? Color(red: 0.49, green: 0.18, blue: 0.07).opacity(0.8) // #7C2D12
                : Color(red: 1.0, green: 0.93, blue: 0.84) // #FFEDD5
        } else if distanceKm < 10.0 {
            // 5.0 ~ 9.9 km (Mid Intensity)
            return Color.orange
        } else {
            // 10.0 km 이상 (High Intensity)
            return Color(red: 0.98, green: 0.75, blue: 0.14) // Amber Gold #FBBF24
        }
    }
    
    // 텍스트 색상
    private var textColor: Color {
        if isFuture {
            return .secondary.opacity(0.5)
        }
        if distanceKm == 0 {
            return .secondary
        } else if distanceKm < 5.0 {
            return colorScheme == .dark ? Color.orange.opacity(0.9) : Color.orange
        } else if distanceKm < 10.0 {
            return .white
        } else {
            return .black
        }
    }
    
    var body: some View {
        VStack(spacing: 1) {
            Text("\(day)")
                .font(.system(size: 11, weight: isSelected || isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(textColor)
            
            if isFuture {
                Text("-")
                    .font(.system(size: 8))
                    .foregroundStyle(textColor)
            } else if distanceKm == 0 {
                Text("휴")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(textColor)
            } else {
                Text(String(format: "%.0fk", distanceKm))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(cellBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isSelected
                        ? Color.orange
                        : (isToday ? (colorScheme == .dark ? Color.white : Color.orange.opacity(0.8)) : Color.clear),
                    lineWidth: isSelected ? 2.5 : (isToday ? 1.5 : 0)
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    HStack(spacing: 6) {
        HeatmapCellView(day: 1, distanceKm: 0.0, isToday: false, isSelected: false, isFuture: false)
        HeatmapCellView(day: 2, distanceKm: 4.0, isToday: false, isSelected: false, isFuture: false)
        HeatmapCellView(day: 3, distanceKm: 6.0, isToday: false, isSelected: false, isFuture: false)
        HeatmapCellView(day: 4, distanceKm: 10.5, isToday: true, isSelected: true, isFuture: false)
        HeatmapCellView(day: 5, distanceKm: 0.0, isToday: false, isSelected: false, isFuture: true)
    }
    .padding()
}
