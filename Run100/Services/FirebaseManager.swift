//
//  FirebaseManager.swift
//  Run100
//
//  Created by 이준성 on 9/24/26.
//

import SwiftUI
import FirebaseCore
import FirebaseCrashlytics
import FirebaseAnalytics
import FirebaseRemoteConfig
import FirebaseMessaging
import UserNotifications

/// Firebase 통합 관리 서비스 (Crashlytics, Analytics, Remote Config, Messaging)
@Observable
final class FirebaseManager: NSObject {
    static let shared = FirebaseManager()
    
    // Remote Config를 통해 원격에서 제어되는 속성들
    var announcementMessage: String = ""
    var isAnnouncementActive: Bool = false
    var latestFCMToken: String? = nil
    
    private var remoteConfig: RemoteConfig?
    
    private override init() {
        super.init()
    }
    
    /// 앱 구동 시 Firebase 코어 초기화
    func configure() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // 1. Crashlytics 수집 활성화
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #if DEBUG
        Crashlytics.crashlytics().setCustomValue("Debug", forKey: "build_mode")
        #else
        Crashlytics.crashlytics().setCustomValue("Release", forKey: "build_mode")
        #endif
        
        // 2. Remote Config 초기화 및 기본값 설정
        self.remoteConfig = RemoteConfig.remoteConfig()
        setupRemoteConfig()
        
        // 3. Analytics 기본 앱 실행 이벤트
        logEvent("app_launch", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_model": UIDevice.current.model
        ])
    }
    
    // MARK: - Remote Config
    private func setupRemoteConfig() {
        guard let remoteConfig = remoteConfig else { return }
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0 // 디버그 시 즉시 반영
        #else
        settings.minimumFetchInterval = 3600 // 상용에서는 1시간 캐싱
        #endif
        remoteConfig.configSettings = settings
        
        // 인앱 기본값 지정 (서버 연결 실패 시 안전하게 대체)
        let defaults: [String: NSObject] = [
            "announcement_active": false as NSObject,
            "announcement_message": "" as NSObject,
            "motivational_quote": "오늘 달린 1km가 내일의 단단한 습관을 만듭니다." as NSObject
        ]
        remoteConfig.setDefaults(defaults)
        
        fetchRemoteConfig()
    }
    
    /// Remote Config 최신값 페치 및 적용
    func fetchRemoteConfig() {
        guard let remoteConfig = remoteConfig else { return }
        remoteConfig.fetchAndActivate { [weak self] status, error in
            guard let self = self else { return }
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
                return
            }
            
            DispatchQueue.main.async {
                self.isAnnouncementActive = remoteConfig["announcement_active"].boolValue
                self.announcementMessage = remoteConfig["announcement_message"].stringValue
            }
        }
    }
    
    // MARK: - Analytics (익명 사용 패턴 분석)
    /// 커스텀 이벤트 로깅
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
    
    /// 화면 전환 로깅
    func logScreenView(screenName: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenName
        ])
    }
    
    /// 달리기 기록 추가 이벤트
    func logRunAdded(distanceKm: Double, isManual: Bool, shoeName: String?) {
        var params: [String: Any] = [
            "distance_km": distanceKm,
            "is_manual": isManual
        ]
        if let shoeName = shoeName {
            params["shoe_name"] = shoeName
        }
        Analytics.logEvent("run_recorded", parameters: params)
    }
    
    /// 러닝화 등록 이벤트
    func logShoeAdded(type: String, targetLifespanKm: Double) {
        Analytics.logEvent("shoe_registered", parameters: [
            "shoe_type": type,
            "target_lifespan_km": targetLifespanKm
        ])
    }
    
    // MARK: - Crashlytics (에러 & 로깅)
    /// 디버깅 및 사용자 세션에 남길 커스텀 로그
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    /// 비정상 에러 수집
    func record(error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}

// MARK: - Messaging & APNs Delegate
extension FirebaseManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        self.latestFCMToken = token
        #if DEBUG
        print("🔥 [FirebaseManager] FCM Registration Token: \(token)")
        #endif
    }
}
