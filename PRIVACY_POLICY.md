# Run100 (런백) 개인정보처리방침 (Privacy Policy)

**최종 수정일:** 2026년 9월 20일  
**적용 대상:** Run100 iOS 애플리케이션 (이하 "앱")

Run100(이하 "개발자")은 이용자의 개인정보 및 건강 데이터를 매우 소중하게 생각하며, 「개인정보 보호법」 및 Apple의 개발자 가이드라인을 준수합니다. 본 앱은 **별도의 회원가입이나 외부 서버 저장 없이, 모든 데이터가 이용자의 기기 내부에만 안전하게 보관되는 로컬 중심 애플리케이션**입니다.

---

## 1. 개인정보 및 데이터 수집 항목

Run100은 이용자의 식별 가능한 개인정보(이름, 전화번호, 이메일, 주민등록번호 등)를 일절 수집하거나 요구하지 않습니다. 앱에서 다루는 데이터는 다음과 같습니다:

1. **사용자 입력 데이터**:
   - 직접 입력한 달리기 거리(km), 소요 시간, 일자, 메모
   - 설정한 월간 목표 거리(km)
2. **Apple HealthKit(애플 건강) 연동 데이터**:
   - 걷기 및 달리기 운동 기록 (`HKWorkoutTypeIdentifier`)
   - 달리기 거리 (`HKQuantityTypeIdentifierDistanceWalkingRunning`)
   - 심박수 (`HKQuantityTypeIdentifierHeartRate`)

---

## 2. 데이터의 처리 및 이용 목적

수집 및 접근하는 모든 데이터는 오직 다음의 목적으로만 이용자의 기기 내부에서 처리됩니다:
- 월 100km 챌린지 달성률 계산 및 D-Day 역산 코칭 제공
- 캘린더 데일리 러닝 잔디 심기 히트맵 시각화
- 러닝 히스토리 성장 분석 (거리, 페이스, 심박수 추이 차트)
- 스마트폰 홈 화면(바탕화면) 위젯에 최신 러닝 진행 상황 표시

---

## 3. 데이터의 제3자 제공 및 외부 전송 금지

Run100은 **클라우드 서버나 외부 데이터베이스를 운영하지 않습니다.**
- 이용자의 모든 러닝 기록과 건강 데이터는 이용자 본인의 iPhone 내부(`SwiftData` 및 `UserDefaults`)에만 암호화되어 안전하게 로컬 저장됩니다.
- **개발자를 포함한 그 어떤 제3자에게도 데이터를 전송하거나 공유하지 않으며, 광고 및 마케팅 목적으로 사용되지 않습니다.**

---

## 4. Apple HealthKit 데이터 보호 준수

Run100은 Apple의 Human Interface Guidelines 및 App Store 심사 지침을 엄격히 준수합니다:
- HealthKit을 통해 읽어온 데이터는 건강 및 피트니스 통계 제공 외의 다른 목적으로 사용되지 않습니다.
- HealthKit 데이터를 제3자 광고 플랫폼, 데이터 브로커, 또는 정보 리셀러에게 판매하거나 공유하지 않습니다.
- 이용자는 언제든지 iPhone의 **[설정] > [건강] > [데이터 접근 및 기기] > [Run100]**에서 건강 데이터 접근 권한을 허용하거나 철회할 수 있습니다.

---

## 5. 데이터의 보유 및 파기

- 모든 데이터는 이용자의 기기 내에만 존재하므로, 앱을 삭제(제거)하거나 기기 내 데이터를 초기화할 경우 모든 기록이 즉시 영구적으로 파기됩니다.
- 앱 내 설정 또는 기록 관리 화면에서 언제든지 특정 러닝 세션을 직접 삭제할 수 있습니다.

---

## 6. 개인정보 보호책임자 및 문의처

앱 이용 중 개인정보처리방침에 대한 문의나 의견이 있으신 경우 아래 연락처로 문의해 주시기 바랍니다.

- **개발자:** 이준성 (Junseong Lee)
- **문의 이메일:** `poby.developer@gmail.com`
- **GitHub 저장소:** [https://github.com/Junseong-LEE/SwiftSideProject](https://github.com/Junseong-LEE/SwiftSideProject)

---

# Privacy Policy for Run100 (English)

**Last Updated:** September 20, 2026

Run100 ("the App") is committed to protecting your privacy. The App is designed as an on-device local utility that does not require user registration or external server infrastructure.

### 1. Data Collection and Usage
- The App accesses Apple HealthKit data (`HKWorkout`, distance, heart rate) solely to calculate your monthly 100km running challenge progress, pace, consistency, and to update home screen widgets on your device.
- All workout sessions and personal records are stored locally on your device via SwiftData and are never uploaded to external servers.

### 2. Third-Party Sharing
- We do not share, sell, or transmit any user data or HealthKit information to third parties, advertising networks, or analytics services.

### 3. User Control
- You can enable or revoke HealthKit permissions at any time in your iPhone **Settings > Health > Data Access & Devices > Run100**.
- Deleting the application will immediately remove all locally stored data.

### Contact
If you have any questions regarding this Privacy Policy, please contact: `poby.developer@gmail.com`
