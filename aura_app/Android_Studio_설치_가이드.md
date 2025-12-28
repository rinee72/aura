# Android Studio 설치 및 Flutter 에뮬레이터 설정 가이드

## 📋 사전 준비사항

- Windows 10/11
- 최소 8GB RAM (16GB 권장)
- 최소 4GB 디스크 공간 (SDK 및 에뮬레이터 포함 시 더 필요)
- 인터넷 연결

---

## 1단계: Android Studio 다운로드

1. **공식 웹사이트 접속**
   - 브라우저에서 https://developer.android.com/studio 접속
   - 또는 직접 다운로드 링크: https://redirector.gvt1.com/edgedl/android/studio/install/2024.1.1.15/android-studio-2024.1.1.15-windows.exe

2. **다운로드**
   - "Download Android Studio" 버튼 클릭
   - 약 1GB 크기의 설치 파일 다운로드
   - 다운로드 위치 확인 (보통 `Downloads` 폴더)

---

## 2단계: Android Studio 설치

1. **설치 파일 실행**
   - 다운로드한 `android-studio-*.exe` 파일 더블클릭
   - 사용자 계정 컨트롤(UAC) 창이 나타나면 "예" 클릭

2. **설치 마법사 진행**
   - **Welcome 화면**: "Next" 클릭
   - **Choose Components 화면**: 
     - ✅ Android Studio (필수)
     - ✅ Android SDK (필수)
     - ✅ Android Virtual Device (AVD) - **반드시 체크!**
     - ✅ Performance (Intel HAXM) - Intel CPU인 경우
     - "Next" 클릭
   
   - **License Agreement**: 
     - "I Agree" 클릭
   
   - **Installation Location**:
     - 기본 경로 사용 권장: `C:\Program Files\Android\Android Studio`
     - 또는 원하는 경로 선택
     - "Next" 클릭
   
   - **Start Menu Folder**: 
     - 기본값 유지
     - "Install" 클릭
   
   - **설치 진행**: 
     - 설치가 완료될 때까지 대기 (5-10분 소요)
     - "Next" 클릭
   
   - **Completing Android Studio Setup**:
     - ✅ "Start Android Studio" 체크
     - "Finish" 클릭

---

## 3단계: Android Studio 초기 설정

1. **첫 실행**
   - Android Studio가 자동으로 실행됩니다
   - "Do not import settings" 선택 (처음 설치하는 경우)
   - "OK" 클릭

2. **Setup Wizard**
   - **Welcome 화면**: "Next" 클릭
   
   - **Install Type**:
     - "Standard" 선택 (권장)
     - "Next" 클릭
   
   - **Verify Settings**:
     - Android SDK Location 확인 (기본: `C:\Users\<사용자명>\AppData\Local\Android\Sdk`)
     - "Next" 클릭
   
   - **SDK Components Setup**:
     - 필요한 컴포넌트 자동 선택됨
     - **중요**: "Android SDK Platform" 최신 버전 확인
     - "Next" 클릭
   
   - **Emulator Settings**:
     - "Next" 클릭 (기본 설정 사용)
   
   - **License Agreement**:
     - 모든 라이선스에 대해 "Accept" 클릭
     - "Finish" 클릭
   
   - **Downloading Components**:
     - 필요한 SDK 및 도구 다운로드 (10-30분 소요, 인터넷 속도에 따라 다름)
     - 완료되면 "Finish" 클릭

---

## 4단계: Android Virtual Device (AVD) 생성

1. **AVD Manager 열기**
   - Android Studio 메인 화면에서
   - 상단 메뉴: **Tools** > **Device Manager**
   - 또는 **More Actions** > **Virtual Device Manager**

2. **가상 기기 생성**
   - "Create Device" 버튼 클릭
   
   - **Select Hardware**:
     - 권장: **Pixel 5** 또는 **Pixel 6**
     - 또는 원하는 기기 선택
     - "Next" 클릭
   
   - **System Image**:
     - **Release Name** 탭 선택
     - **API Level 33 (Android 13)** 또는 **API Level 34 (Android 14)** 선택
     - ✅ "Show Downloadable System Images" 체크 해제 (이미 다운로드된 것만 표시)
     - 다운로드 아이콘(⬇️)이 있는 경우 클릭하여 다운로드 (5-10분 소요)
     - "Next" 클릭
   
   - **AVD Configuration**:
     - **AVD Name**: 원하는 이름 입력 (예: "Pixel_5_API_33")
     - **Startup orientation**: Portrait (세로) 또는 Landscape (가로)
     - **Graphics**: Automatic (권장) 또는 Hardware - GLES 2.0
     - **Advanced Settings** (선택사항):
       - RAM: 2048 MB 이상 권장
       - VM heap: 512 MB
     - "Finish" 클릭

3. **AVD 확인**
   - Device Manager에 생성된 AVD가 표시됩니다
   - ▶️ (Play) 버튼을 클릭하여 에뮬레이터 실행 테스트
   - 에뮬레이터가 정상적으로 부팅되는지 확인

---

## 5단계: Flutter와 연동 확인

1. **Flutter Doctor 확인**
   ```bash
   cd c:\modu\aura_app
   flutter doctor
   ```
   
   - Android toolchain이 ✅로 표시되는지 확인
   - 에뮬레이터가 인식되는지 확인

2. **에뮬레이터 목록 확인**
   ```bash
   flutter emulators
   ```
   
   - 생성한 AVD가 목록에 표시되어야 합니다
   - 예: `Pixel_5_API_33` (mobile) • Pixel 5 API 33 • Google • android

---

## 6단계: Flutter 앱 실행

1. **에뮬레이터 실행**
   ```bash
   flutter emulators --launch Pixel_5_API_33
   ```
   
   또는 Android Studio에서 Device Manager의 ▶️ 버튼 클릭

2. **에뮬레이터 부팅 대기**
   - 에뮬레이터가 완전히 부팅될 때까지 대기 (1-2분)
   - 홈 화면이 나타나면 준비 완료

3. **Flutter 앱 실행**
   ```bash
   cd c:\modu\aura_app
   flutter devices  # 에뮬레이터가 목록에 있는지 확인
   flutter run
   ```

4. **앱 확인**
   - 에뮬레이터에 AURA 앱이 자동으로 설치되고 실행됩니다
   - AppBar의 팔레트 아이콘(🎨)을 클릭하여 컴포넌트 카탈로그 확인

---

## 🔧 문제 해결

### 문제 1: "Android SDK not found"
**해결 방법:**
```bash
flutter config --android-sdk "C:\Users\<사용자명>\AppData\Local\Android\Sdk"
```

### 문제 2: "No Android SDK found"
**해결 방법:**
1. Android Studio 열기
2. File > Settings (또는 Ctrl+Alt+S)
3. Appearance & Behavior > System Settings > Android SDK
4. SDK Location 확인 및 복사
5. 위의 `flutter config` 명령어에 경로 입력

### 문제 3: 에뮬레이터가 느림
**해결 방법:**
1. AVD 설정에서 Graphics를 "Hardware - GLES 2.0"으로 변경
2. RAM을 4096 MB로 증가
3. Windows의 Hyper-V 비활성화 (Intel CPU인 경우)

### 문제 4: HAXM 설치 오류
**해결 방법:**
- Intel CPU가 아닌 경우 무시해도 됩니다
- Intel CPU인 경우: https://github.com/intel/haxm/releases 에서 수동 설치

### 문제 5: 에뮬레이터가 시작되지 않음
**해결 방법:**
1. Android Studio > Tools > SDK Manager
2. SDK Tools 탭
3. "Android Emulator" 체크 확인
4. Apply 클릭하여 재설치

---

## ✅ 설치 완료 확인 체크리스트

- [ ] Android Studio 설치 완료
- [ ] Android SDK 다운로드 완료
- [ ] AVD 생성 완료
- [ ] 에뮬레이터 실행 테스트 성공
- [ ] `flutter doctor`에서 Android toolchain ✅ 표시
- [ ] `flutter emulators`에서 AVD 목록 확인
- [ ] `flutter run`으로 앱 실행 성공

---

## 📝 추가 팁

1. **에뮬레이터 성능 향상**
   - Windows 기능에서 "Hyper-V" 비활성화 (Intel CPU인 경우)
   - BIOS에서 가상화(VT-x) 활성화 확인

2. **여러 AVD 생성**
   - 다양한 API 레벨과 기기로 여러 AVD 생성 가능
   - 테스트 시 다양한 환경에서 확인 가능

3. **에뮬레이터 단축키**
   - Ctrl + M: 메뉴 열기
   - Ctrl + F11: 방향 전환
   - Ctrl + F12: 화면 회전

---

## 🎯 다음 단계

설치가 완료되면:
1. 에뮬레이터 실행
2. `cd c:\modu\aura_app`
3. `flutter run`
4. 컴포넌트 카탈로그 확인!

설치 중 문제가 발생하면 알려주세요!
