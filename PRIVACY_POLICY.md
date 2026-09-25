# Run100 (런백) 개인정보처리방침 (Privacy Policy)

**최종 수정일:** 2026년 9월 25일  
**적용 대상:** Run100 iOS 애플리케이션 (이하 "앱")

Run100(이하 "개발자")은 이용자의 개인정보 및 건강 데이터를 매우 소중하게 생각하며, 대한민국 「개인정보 보호법」 및 Apple의 App Store 심사 지침을 엄격히 준수합니다. 본 방침은 앱 이용 시 어떠한 정보가 어떻게 처리되는지 투명하게 안내하기 위해 작성되었습니다.

---

## 1. 수집 및 처리하는 데이터 항목

Run100은 이름, 주민등록번호, 연락처, 비밀번호 등 **이용자를 직접 식별할 수 있는 민감한 개인정보를 요구하거나 수집하지 않습니다.**

### (1) 기기 내부 로컬 저장 데이터 (외부 전송되지 않음)
* **사용자 입력 데이터**: 직접 입력한 달리기 거리(km), 소요 시간, 일자, 메모, 월간 목표 거리(km)
* **러닝화 관리 데이터**: 러닝화 이름, 신발 유형(쿠션화/템포화/카본화 등), 목표 수명 거리(km), 착용 시작일
* **Apple HealthKit(애플 건강) 데이터**: 걷기 및 달리기 운동 기록(`HKWorkout`), 이동 거리(`HKQuantityTypeIdentifierDistanceWalkingRunning`), 심박수(`HKQuantityTypeIdentifierHeartRate`)
> ※ 위 데이터는 이용자의 iPhone 로컬 저장소(`SwiftData`)에만 암호화 보관되며, **외부 서버로 일절 전송되지 않습니다.**

### (2) 서비스 안정성 및 기능 개선을 위한 비식별 데이터 (Google Firebase)
앱의 품질 향상 및 오류 수정을 위해 Google LLC가 제공하는 Firebase 서비스를 이용하며, 개인을 특정할 수 없는 비식별 정보만을 처리합니다:
* **앱 충돌 및 오류 진단 (Firebase Crashlytics)**: 앱 비정상 종료 시 기기 모델, OS 버전, 오류 발생 코드 라인 분석 로그
* **앱 이용 통계 (Firebase Analytics)**: 화면 방문, 주요 기능 이용 횟수 등 통계적 제품 상호작용 데이터
* **익명 식별자 (Firebase Authentication)**: 개별 로그인 없이 기기 구분을 위해 시스템이 자동 생성하는 무작위 난수 식별자(UID)
* **원격 구성 및 푸시 알림 (Remote Config & Cloud Messaging)**: 앱 공지사항 수신 및 러닝 동기부여 알림 발송을 위한 기기 토큰

---

## 2. 데이터의 이용 목적

* **월 100km 목표 관리**: 누적 거리 계산, D-Day 역산 권장 거리 코칭 제공
* **습관 형성 및 통계**: 캘린더 일별 출석체크, 거리×페이스 산점도 차트, 4대 지표 히스토리 분석
* **장비 보호**: 러닝화 미드솔 수명 소모율 트래킹 및 교체 주기 안내
* **위젯 연동**: iOS 홈 화면(Medium 2x4) 위젯 실시간 진행 상황 동기화
* **앱 품질 최적화**: 크래시 디버깅, 긴급 공지사항 표출, 서비스 안정성 유지

---

## 3. 개인정보의 제3자 제공 및 추적(Tracking) 금지

1. **타사 광고 및 추적 금지**:
   * Run100은 타사 광고 플랫폼(AdMob 등)을 탑재하지 않습니다.
   * 이용자의 데이터를 타사 앱이나 웹사이트의 활동과 결합하여 맞춤형 광고를 제공하는 **'추적(Tracking)' 행위를 일절 하지 않습니다.**
2. **Apple HealthKit 데이터의 절대적 보호**:
   * **애플 건강(HealthKit) 데이터는 Google Firebase를 포함한 그 어떤 외부 서버로도 전송되지 않으며**, 오직 이용자 기기 내부 연산에만 사용됩니다.
   * HealthKit 데이터를 제3자, 데이터 브로커, 마케팅 업체에 판매하거나 공유하지 않습니다.

---

## 4. 데이터의 보관 및 파기

* **로컬 데이터**: 앱을 삭제하거나 앱 내 [설정 > 데이터 관리]에서 초기화를 진행할 경우 기기 내의 모든 세션 및 러닝화 데이터가 즉시 영구 삭제됩니다.
* **HealthKit 권한 철회**: 이용자는 언제든지 iPhone의 **[설정] > [건강] > [데이터 접근 및 기기] > [Run100]**에서 건강 데이터 접근 권한을 철회할 수 있습니다.

---

## 5. 개인정보 보호책임자 및 문의처

개인정보 처리 및 앱 이용과 관련된 문의, 의견은 아래의 연락처로 언제든지 문의해 주시기 바랍니다.

* **개발자:** 이준성 (Junseong Lee)
* **문의 이메일:** `poby.developer@gmail.com`
* **공식 저장소:** [https://github.com/Junseong-LEE/Run100](https://github.com/Junseong-LEE/Run100)

---

# Privacy Policy for Run100 (English)

**Last Updated:** September 25, 2026

Run100 ("the App") is committed to protecting your privacy. The App is designed with an on-device local-first architecture that prioritizes minimal data exposure and maximum security.

### 1. Data Collection and Usage
* **On-Device Data (Never Uploaded)**: Workout sessions, custom running notes, running shoe lifespan data, and Apple HealthKit metrics (`HKWorkout`, distance, heart rate) are processed and stored exclusively on your device via SwiftData.
* **Diagnostics & Anonymous Analytics (Google Firebase)**: We utilize Firebase Crashlytics and Analytics to monitor app stability, crash reports, and aggregate usage statistics using randomly generated, non-identifiable identifiers (Anonymous UIDs). 
* **No Tracking**: We do not track users across third-party apps or websites, and we never sell user data or HealthKit data to advertising networks or data brokers.

### 2. Apple HealthKit Privacy
* HealthKit data is never transmitted outside your device and is not shared with any third party, including Google Firebase.
* You can modify or revoke HealthKit permissions at any time via **iPhone Settings > Health > Data Access & Devices > Run100**.

### 3. Contact Us
For any inquiries regarding this policy, please reach out to: `poby.developer@gmail.com`
