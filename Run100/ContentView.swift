//
//  ContentView.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var store = RunStore()
    @State private var selectedTab = 0
    @AppStorage("appTheme") private var appTheme: String = "dark"
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // 시스템 설정 일치
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(store: store) {
                withAnimation {
                    selectedTab = 1
                }
            }
            .tabItem {
                Label("대시보드", systemImage: "figure.run")
            }
            .tag(0)
            
            CalendarView(store: store)
                .tabItem {
                    Label("캘린더", systemImage: "calendar")
                }
                .tag(1)
            
            HistoryView(store: store)
                .tabItem {
                    Label("히스토리", systemImage: "chart.bar.xaxis")
                }
                .tag(2)
            
            SettingsView(isPresentedAsSheet: false)
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(Color.orange) // 액센트 오렌지 컬러
        .preferredColorScheme(colorScheme)
    }
}

#Preview {
    ContentView()
        .modelContainer(.preview)
}
