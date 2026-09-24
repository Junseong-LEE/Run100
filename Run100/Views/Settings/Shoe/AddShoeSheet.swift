//
//  AddShoeSheet.swift
//  Run100
//
//  Created by 이준성 on 9/24/26.
//

import SwiftUI
import SwiftData
import UIKit

/// 러닝화 등록 및 수정 시트
struct AddShoeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allShoes: [RunningShoe]
    
    // 편집 대상 신발 (nil이면 신규 등록)
    var shoeToEdit: RunningShoe? = nil
    
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var selectedType: ShoeType = .cushion
    @State private var targetLifespanKm: Double = 600.0
    @State private var initialDistanceKm: Double = 0.0
    @State private var startDate: Date = Date()
    @State private var setAsActive: Bool = true
    @State private var memo: String = ""
    
    @State private var showValidationError: Bool = false
    
    private var isEditing: Bool {
        shoeToEdit != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. 기본 정보 (단일 이름 입력 필드로 통합)
                Section(header: Text("러닝화 이름")) {
                    TextField("예: 나이키 페가수스 41, 아식스 님버스 26", text: $name)
                        .font(.system(size: 15))
                }
                
                // 2. 신발 유형 및 권장 수명 프리셋
                Section(
                    header: Text("신발 유형 (탭하면 권장 수명이 자동 세팅됩니다)"),
                    footer: Text(selectedType.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                ) {
                    VStack(spacing: 10) {
                        ForEach(ShoeType.allCases, id: \.self) { type in
                            let isSelected = selectedType == type
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedType = type
                                // 유형 변경 시 권장 수명으로 자동 세팅
                                targetLifespanKm = type.defaultLifespanKm
                            } label: {
                                HStack {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(isSelected ? Color.orange : .secondary)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(type.title)
                                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                                            .foregroundStyle(isSelected ? Color.orange : .primary)
                                        Text(type.subtitle)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(Int(type.defaultLifespanKm))km")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(isSelected ? Color.orange : .secondary)
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(Color.orange)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            
                            if type != ShoeType.allCases.last {
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 3. 목표 수명 세부 설정
                Section(header: Text("목표 수명 거리")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("교체 권장 거리")
                                .font(.system(size: 14))
                            Spacer()
                            Text("\(Int(targetLifespanKm)) km")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.orange)
                        }
                        
                        Slider(value: $targetLifespanKm, in: 200...1000, step: 50)
                            .tint(Color.orange)
                    }
                    .padding(.vertical, 4)
                }
                
                // 4. 착용 시작일 및 기존 거리
                Section(
                    header: Text("착용 시작 정보"),
                    footer: Text("착용 시작일 이후에 기록된 러닝 세션의 거리가 자동으로 합산됩니다.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                ) {
                    DatePicker(
                        "착용 시작일",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .font(.system(size: 15))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("기존 누적 거리")
                                .font(.system(size: 15))
                            Text("새 신발이면 0km로 유지하세요")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("0", value: $initialDistanceKm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("km")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // 5. 주력 신발 설정
                Section {
                    Toggle("현재 주력 러닝화로 설정", isOn: $setAsActive)
                        .font(.system(size: 15, weight: .medium))
                        .tint(Color.orange)
                } footer: {
                    Text("주력 신발로 설정하면 대시보드에서 소모량을 실시간으로 확인하고, 앞으로 달리는 거리가 이 신발에 우선 트래킹됩니다.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(isEditing ? "러닝화 수정" : "새 러닝화 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "완료" : "등록") {
                        saveShoe()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.orange)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let shoe = shoeToEdit {
                    name = shoe.name
                    brand = shoe.brand
                    selectedType = shoe.shoeType
                    targetLifespanKm = shoe.targetLifespanKm
                    initialDistanceKm = shoe.initialDistanceKm
                    startDate = shoe.startDate
                    setAsActive = shoe.isActive
                    memo = shoe.memo ?? ""
                }
            }
            .alert("입력 오류", isPresented: $showValidationError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("러닝화 이름을 입력해주세요.")
            }
        }
    }
    
    private func saveShoe() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showValidationError = true
            return
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // 주력 신발로 지정하는 경우, 다른 기존 신발들의 isActive를 false로 해제
        if setAsActive {
            for existing in allShoes {
                if existing.id != shoeToEdit?.id {
                    existing.isActive = false
                }
            }
        }
        
        if let shoe = shoeToEdit {
            shoe.name = trimmedName
            shoe.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
            shoe.shoeType = selectedType
            shoe.targetLifespanKm = targetLifespanKm
            shoe.initialDistanceKm = initialDistanceKm
            shoe.startDate = startDate
            shoe.isActive = setAsActive
            shoe.memo = memo.isEmpty ? nil : memo
        } else {
            let newShoe = RunningShoe(
                name: trimmedName,
                brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
                shoeType: selectedType,
                targetLifespanKm: targetLifespanKm,
                initialDistanceKm: initialDistanceKm,
                startDate: startDate,
                isActive: setAsActive,
                memo: memo.isEmpty ? nil : memo
            )
            modelContext.insert(newShoe)
        }
        
        try? modelContext.save()
        dismiss()
    }
}
