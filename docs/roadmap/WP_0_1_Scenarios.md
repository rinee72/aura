# WP-0.1: Flutter 멀티 플랫폼 프로젝트 초기화 - Scenario 분해

## 📋 Work Package 개요
**WP-0.1**: Flutter 멀티 플랫폼 프로젝트 초기화  
**목표**: Flutter 프로젝트를 생성하고 iOS/Android/Web에서 실행 가능한 상태로 만들기

---

## 🎯 Scenario 목록

### 그룹 A: 프로젝트 생성 및 기본 설정
- Scenario 0.1-1: Flutter CLI로 멀티 플랫폼 프로젝트 생성 성공
- Scenario 0.1-2: 잘못된 프로젝트명으로 생성 시도 시 실패
- Scenario 0.1-3: Flutter SDK 미설치 상태에서 프로젝트 생성 시도 시 실패

### 그룹 B: 의존성 관리
- Scenario 0.1-4: pubspec.yaml에 필수 패키지 추가 후 정상 설치
- Scenario 0.1-5: 존재하지 않는 패키지 버전 추가 시 실패
- Scenario 0.1-6: 의존성 충돌 발생 시 에러 메시지 확인

### 그룹 C: iOS 플랫폼 설정
- Scenario 0.1-7: iOS 프로젝트 기본 설정 완료
- Scenario 0.1-8: Info.plist 권한 추가 후 빌드 성공
- Scenario 0.1-9: Xcode 미설치 환경에서 iOS 빌드 시도 시 실패

### 그룹 D: Android 플랫폼 설정
- Scenario 0.1-10: Android Minimum SDK 21로 설정 성공
- Scenario 0.1-11: 인터넷 권한 추가 후 빌드 성공
- Scenario 0.1-12: Android SDK 미설치 환경에서 빌드 시도 시 실패

### 그룹 E: Web 플랫폼 설정
- Scenario 0.1-13: Web 프로젝트 기본 설정 완료
- Scenario 0.1-14: index.html 메타 태그 추가 후 빌드 성공

### 그룹 F: 멀티 플랫폼 실행 검증
- Scenario 0.1-15: Chrome에서 앱 실행 성공
- Scenario 0.1-16: iOS 시뮬레이터에서 앱 실행 성공
- Scenario 0.1-17: Android 에뮬레이터에서 앱 실행 성공
- Scenario 0.1-18: 실행 중인 디바이스 없을 때 실행 시도 시 실패

### 그룹 G: 환경 검증
- Scenario 0.1-19: flutter doctor 실행 시 이슈 없음 확인
- Scenario 0.1-20: flutter doctor 실행 시 경고 발견 시 해결

---

## 📝 상세 Scenario

### 🟢 그룹 A: 프로젝트 생성 및 기본 설정

#### Scenario 0.1-1: Flutter CLI로 멀티 플랫폼 프로젝트 생성 성공
- **Given**: Flutter SDK 3.19 이상이 설치되어 있음
- **When**: `flutter create aura_app --org com.aura --platforms=ios,android,web` 명령어 실행
- **Then**: 
  - `aura_app` 폴더가 생성됨
  - `lib/main.dart` 파일이 존재함
  - `pubspec.yaml` 파일이 존재함
  - ios, android, web 폴더가 모두 존재함
  - 터미널에 "All done!" 메시지 출력
- **선행 Scenario**: 없음

---

#### Scenario 0.1-2: 잘못된 프로젝트명으로 생성 시도 시 실패
- **Given**: Flutter SDK 3.19 이상이 설치되어 있음
- **When**: `flutter create 123InvalidName` 명령어 실행 (숫자로 시작하는 프로젝트명)
- **Then**: 
  - 프로젝트 생성 실패
  - "Invalid project name" 에러 메시지 출력
  - 프로젝트 폴더가 생성되지 않음
- **선행 Scenario**: 없음

---

#### Scenario 0.1-3: Flutter SDK 미설치 상태에서 프로젝트 생성 시도 시 실패
- **Given**: Flutter SDK가 PATH에 없음
- **When**: `flutter create aura_app` 명령어 실행
- **Then**: 
  - "flutter: command not found" 에러 메시지 출력
  - 프로젝트 생성 실패
- **선행 Scenario**: 없음

---

### 🟢 그룹 B: 의존성 관리

#### Scenario 0.1-4: pubspec.yaml에 필수 패키지 추가 후 정상 설치
- **Given**: Flutter 프로젝트가 생성되어 있음
- **When**: 
  - `pubspec.yaml`에 다음 패키지 추가:
    ```yaml
    dependencies:
      supabase_flutter: ^2.3.0
      go_router: ^13.0.0
      provider: ^6.1.1
      flutter_dotenv: ^5.1.0
    ```
  - `flutter pub get` 명령어 실행
- **Then**: 
  - 모든 패키지가 성공적으로 다운로드됨
  - `.dart_tool/package_config.json` 파일에 패키지 정보 존재
  - "Got dependencies!" 메시지 출력
  - 종료 코드 0 반환
- **선행 Scenario**: 0.1-1

---

#### Scenario 0.1-5: 존재하지 않는 패키지 버전 추가 시 실패
- **Given**: Flutter 프로젝트가 생성되어 있음
- **When**: 
  - `pubspec.yaml`에 존재하지 않는 버전 추가:
    ```yaml
    dependencies:
      supabase_flutter: ^999.0.0
    ```
  - `flutter pub get` 명령어 실행
- **Then**: 
  - 패키지 설치 실패
  - "version solving failed" 에러 메시지 출력
  - 종료 코드 1 반환
- **선행 Scenario**: 0.1-1

---

#### Scenario 0.1-6: 의존성 충돌 발생 시 에러 메시지 확인
- **Given**: Flutter 프로젝트가 생성되어 있음
- **When**: 
  - `pubspec.yaml`에 서로 호환되지 않는 버전 추가
  - `flutter pub get` 명령어 실행
- **Then**: 
  - 의존성 해결 실패
  - 충돌하는 패키지 이름 및 버전 정보 출력
  - "Because ... depends on ..., version solving failed" 메시지 출력
- **선행 Scenario**: 0.1-1

---

### 🟢 그룹 C: iOS 플랫폼 설정

#### Scenario 0.1-7: iOS 프로젝트 기본 설정 완료
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - macOS 환경
  - Xcode가 설치되어 있음
- **When**: `ios/` 폴더 확인
- **Then**: 
  - `ios/Runner.xcodeproj` 파일 존재
  - `ios/Runner/Info.plist` 파일 존재
  - `ios/Podfile` 파일 존재
- **선행 Scenario**: 0.1-1

---

#### Scenario 0.1-8: Info.plist 권한 추가 후 빌드 성공
- **Given**: 
  - iOS 프로젝트 기본 설정 완료
  - Xcode가 설치되어 있음
- **When**: 
  - `ios/Runner/Info.plist`에 다음 권한 추가:
    ```xml
    <key>NSCameraUsageDescription</key>
    <string>사진 촬영을 위해 카메라 접근이 필요합니다</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>사진 업로드를 위해 갤러리 접근이 필요합니다</string>
    ```
  - `flutter build ios --no-codesign` 명령어 실행
- **Then**: 
  - 빌드 성공
  - "Built build/ios/iphoneos/Runner.app" 메시지 출력
  - 종료 코드 0 반환
- **선행 Scenario**: 0.1-7

---

#### Scenario 0.1-9: Xcode 미설치 환경에서 iOS 빌드 시도 시 실패
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - macOS 환경이지만 Xcode가 설치되어 있지 않음
- **When**: `flutter build ios` 명령어 실행
- **Then**: 
  - 빌드 실패
  - "Xcode not found" 또는 유사한 에러 메시지 출력
  - 종료 코드 1 반환
- **선행 Scenario**: 0.1-1

---

### 🟢 그룹 D: Android 플랫폼 설정

#### Scenario 0.1-10: Android Minimum SDK 21로 설정 성공
- **Given**: Flutter 프로젝트가 생성되어 있음
- **When**: 
  - `android/app/build.gradle` 파일 열기
  - `minSdkVersion` 값을 21로 설정:
    ```gradle
    android {
        defaultConfig {
            minSdkVersion 21
        }
    }
    ```
- **Then**: 
  - 파일 저장 성공
  - `minSdkVersion 21` 값이 정확히 기록됨
- **선행 Scenario**: 0.1-1

---

#### Scenario 0.1-11: 인터넷 권한 추가 후 빌드 성공
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - Android SDK가 설치되어 있음
- **When**: 
  - `android/app/src/main/AndroidManifest.xml`에 권한 추가:
    ```xml
    <uses-permission android:name="android.permission.INTERNET"/>
    ```
  - `flutter build apk --debug` 명령어 실행
- **Then**: 
  - 빌드 성공
  - `build/app/outputs/flutter-apk/app-debug.apk` 파일 생성됨
  - "Built build/app/outputs/flutter-apk/app-debug.apk" 메시지 출력
- **선행 Scenario**: 0.1-10

---

#### Scenario 0.1-12: Android SDK 미설치 환경에서 빌드 시도 시 실패
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - Android SDK가 설치되어 있지 않음
- **When**: `flutter build apk` 명령어 실행
- **Then**: 
  - 빌드 실패
  - "Android SDK not found" 에러 메시지 출력
  - 종료 코드 1 반환
- **선행 Scenario**: 0.1-1

---

### 🟢 그룹 E: Web 플랫폼 설정

#### Scenario 0.1-13: Web 프로젝트 기본 설정 완료
- **Given**: Flutter 프로젝트가 생성되어 있음
- **When**: `web/` 폴더 확인
- **Then**: 
  - `web/index.html` 파일 존재
  - `web/manifest.json` 파일 존재
  - `web/favicon.png` 파일 존재
- **선행 Scenario**: 0.1-1

---

#### Scenario 0.1-14: index.html 메타 태그 추가 후 빌드 성공
- **Given**: Web 프로젝트 기본 설정 완료
- **When**: 
  - `web/index.html`에 메타 태그 추가:
    ```html
    <meta name="description" content="AURA - 셀럽-팬 소통 플랫폼">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    ```
  - `flutter build web` 명령어 실행
- **Then**: 
  - 빌드 성공
  - `build/web/` 폴더 생성됨
  - `build/web/index.html`에 추가한 메타 태그 포함됨
  - "Built build/web" 메시지 출력
- **선행 Scenario**: 0.1-13

---

### 🟢 그룹 F: 멀티 플랫폼 실행 검증

#### Scenario 0.1-15: Chrome에서 앱 실행 성공
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - 필수 패키지가 설치되어 있음
  - Chrome 브라우저가 설치되어 있음
- **When**: `flutter run -d chrome` 명령어 실행
- **Then**: 
  - Chrome 브라우저가 자동으로 열림
  - Flutter 기본 카운터 앱이 표시됨
  - Hot reload 기능 사용 가능 ("r" 키로 리로드 가능)
  - 콘솔에 "Running on http://localhost:xxxxx" 메시지 출력
- **선행 Scenario**: 0.1-4, 0.1-14

---

#### Scenario 0.1-16: iOS 시뮬레이터에서 앱 실행 성공
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - 필수 패키지가 설치되어 있음
  - macOS 환경
  - Xcode 설치 및 iOS 시뮬레이터 실행 중
- **When**: `flutter run -d ios` 명령어 실행
- **Then**: 
  - iOS 시뮬레이터에 앱이 설치되고 실행됨
  - Flutter 기본 카운터 앱이 표시됨
  - Hot reload 기능 사용 가능
  - 콘솔에 앱 실행 로그 출력
- **선행 Scenario**: 0.1-4, 0.1-8

---

#### Scenario 0.1-17: Android 에뮬레이터에서 앱 실행 성공
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - 필수 패키지가 설치되어 있음
  - Android SDK 설치 및 에뮬레이터 실행 중
- **When**: `flutter run -d emulator-5554` 명령어 실행 (에뮬레이터 ID)
- **Then**: 
  - Android 에뮬레이터에 앱이 설치되고 실행됨
  - Flutter 기본 카운터 앱이 표시됨
  - Hot reload 기능 사용 가능
  - 콘솔에 "Installing build/app/outputs/flutter-apk/app.apk..." 메시지 출력
- **선행 Scenario**: 0.1-4, 0.1-11

---

#### Scenario 0.1-18: 실행 중인 디바이스 없을 때 실행 시도 시 실패
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - 실행 중인 에뮬레이터/시뮬레이터/브라우저가 없음
- **When**: `flutter run` 명령어 실행
- **Then**: 
  - 실행 실패
  - "No devices found" 에러 메시지 출력
  - 사용 가능한 디바이스 목록 표시 (비어있음)
  - 종료 코드 1 반환
- **선행 Scenario**: 0.1-4

---

### 🟢 그룹 G: 환경 검증

#### Scenario 0.1-19: flutter doctor 실행 시 이슈 없음 확인
- **Given**: 
  - Flutter SDK가 설치되어 있음
  - 모든 필수 도구가 설치되어 있음 (Xcode, Android Studio 등)
- **When**: `flutter doctor` 명령어 실행
- **Then**: 
  - 모든 항목에 ✓ (체크) 표시
  - "No issues found!" 메시지 출력
  - Flutter 버전 정보 표시
  - 종료 코드 0 반환
- **선행 Scenario**: 없음

---

#### Scenario 0.1-20: flutter doctor 실행 시 경고 발견 시 해결
- **Given**: 
  - Flutter SDK가 설치되어 있음
  - 일부 선택적 도구가 설치되어 있지 않음 (예: Android licenses 미동의)
- **When**: `flutter doctor` 명령어 실행
- **Then**: 
  - 일부 항목에 ! (경고) 또는 ✗ (에러) 표시
  - 문제 해결 방법 제시 (예: "Run `flutter doctor --android-licenses`")
  - 해결 방법을 따라 실행하면 문제 해결됨
- **선행 Scenario**: 없음

---

## 📊 Scenario 의존성 다이어그램

```
[그룹 A: 프로젝트 생성]
0.1-1 (프로젝트 생성)
  ├─> 0.1-4 (의존성 설치) [그룹 B]
  ├─> 0.1-7 (iOS 설정) [그룹 C]
  ├─> 0.1-10 (Android 설정) [그룹 D]
  └─> 0.1-13 (Web 설정) [그룹 E]

[그룹 B: 의존성]
0.1-4 (의존성 설치)
  ├─> 0.1-15 (Chrome 실행) [그룹 F]
  ├─> 0.1-16 (iOS 실행) [그룹 F]
  └─> 0.1-17 (Android 실행) [그룹 F]

[그룹 C: iOS]
0.1-7 (iOS 설정)
  └─> 0.1-8 (Info.plist)
       └─> 0.1-16 (iOS 실행)

[그룹 D: Android]
0.1-10 (Android SDK)
  └─> 0.1-11 (권한 추가)
       └─> 0.1-17 (Android 실행)

[그룹 E: Web]
0.1-13 (Web 설정)
  └─> 0.1-14 (메타 태그)
       └─> 0.1-15 (Chrome 실행)

[그룹 G: 검증]
0.1-19, 0.1-20 (독립적 실행 가능)
```

---

## 📋 Scenario 실행 순서 (권장)

### Phase 1: 기본 설정 (필수)
1. 0.1-1: 프로젝트 생성
2. 0.1-19 또는 0.1-20: 환경 검증
3. 0.1-4: 의존성 설치

### Phase 2: 플랫폼별 설정 (병렬 가능)
**iOS 트랙**:
- 0.1-7 → 0.1-8

**Android 트랙**:
- 0.1-10 → 0.1-11

**Web 트랙**:
- 0.1-13 → 0.1-14

### Phase 3: 실행 검증 (병렬 가능)
- 0.1-15 (Web)
- 0.1-16 (iOS)
- 0.1-17 (Android)

### Phase 4: 실패 케이스 검증 (선택)
- 0.1-2, 0.1-3 (프로젝트 생성 실패)
- 0.1-5, 0.1-6 (의존성 실패)
- 0.1-9 (iOS 실패)
- 0.1-12 (Android 실패)
- 0.1-18 (실행 실패)

---

## ✅ WP-0.1 완료 조건 검증

WP-0.1은 다음 Scenario들이 모두 통과되어야 완료된 것으로 간주:

### 필수 통과 Scenario (Success Cases)
- ✅ 0.1-1: 프로젝트 생성 성공
- ✅ 0.1-4: 의존성 설치 성공
- ✅ 0.1-8: iOS 빌드 성공
- ✅ 0.1-11: Android 빌드 성공
- ✅ 0.1-14: Web 빌드 성공
- ✅ 0.1-15: Web 실행 성공
- ✅ 0.1-16: iOS 실행 성공
- ✅ 0.1-17: Android 실행 성공
- ✅ 0.1-19: flutter doctor 이슈 없음

### 검증 완료 Scenario (Failure Cases)
- ✅ 0.1-2, 0.1-3: 프로젝트 생성 실패 케이스 확인
- ✅ 0.1-5, 0.1-6: 의존성 실패 케이스 확인
- ✅ 0.1-9: iOS 실패 케이스 확인 (해당 환경에서)
- ✅ 0.1-12: Android 실패 케이스 확인 (해당 환경에서)
- ✅ 0.1-18: 디바이스 없을 때 실패 케이스 확인

---

## 🎯 요약

- **총 Scenario 수**: 20개
  - 성공 케이스: 14개
  - 실패 케이스: 6개
- **예상 실행 시간**: 0.5일
- **병렬 실행 가능**: 그룹 C, D, E는 병렬 가능
- **핵심 원칙**: 하나의 Scenario = 하나의 행동 = 하나의 검증
