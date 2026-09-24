//
//  Run100App.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import SwiftData

@main
struct Run100App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: RunSession.self)
    }
}
