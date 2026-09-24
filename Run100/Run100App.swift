//
//  Run100App.swift
//  Run100
//
//  Created by 이준성 on 9/19/26.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// MARK: - App Delegate for Firebase & Push
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Firebase 매니저 초기화
        FirebaseManager.shared.configure()
        
        // 원격 푸시 알림 및 권한 대리자 설정
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = FirebaseManager.shared
        
        // APNs 원격 알림 등록 요청
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // APNs 디바이스 토큰 수신
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // 포그라운드 알림 수신 시 배너 표출
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([[.banner, .sound, .badge]])
    }
}

@main
struct Run100App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [RunSession.self, RunningShoe.self])
    }
}
