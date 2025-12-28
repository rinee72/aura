# Flutter Daemon 오류 해결 방법

## 문제 상황
- "The Flutter Daemon failed to start." 오류
- "Some packages are missing or out of date" 메시지
- 앱이 실행되지 않음

## 해결 방법

### 1단계: 패키지 업데이트 (가장 중요!)

**Cursor/VS Code에서:**
1. 에러 메시지 팝업에서 **"Run 'pub get'"** 버튼 클릭
   - 또는 Command Palette (Ctrl+Shift+P) → "Dart: Pub Get" 실행

**터미널에서 직접 실행:**
```bash
cd c:\modu\aura_app
C:\flutter\bin\flutter.bat pub get
```

### 2단계: Flutter Extension 재시작

**Cursor/VS Code에서:**
1. 에러 메시지 팝업에서 **"Restart Extension"** 버튼 클릭
   - 또는 Command Palette (Ctrl+Shift+P) → "Dart: Restart Analysis Server" 실행

### 3단계: Flutter 캐시 정리 (필요한 경우)

터미널에서 실행:
```bash
cd c:\modu\aura_app
C:\flutter\bin\flutter.bat clean
C:\flutter\bin\flutter.bat pub get
```

### 4단계: Cursor/VS Code 재시작

위 방법들이 작동하지 않으면:
1. Cursor/VS Code 완전히 종료
2. 다시 실행
3. 프로젝트 폴더 열기

### 5단계: Flutter 환경 확인

터미널에서 실행:
```bash
C:\flutter\bin\flutter.bat doctor
```

## 빠른 해결 (권장 순서)

1. ✅ **에러 팝업에서 "Run 'pub get'" 클릭** ← 가장 빠름!
2. ✅ **에러 팝업에서 "Restart Extension" 클릭**
3. ✅ Cursor/VS Code 재시작
4. ✅ `flutter clean` 후 `flutter pub get` 실행

## 참고

- PowerShell 인코딩 오류는 환경 문제이며 Flutter 코드 오류가 아닙니다
- Flutter Daemon은 Dart/Flutter 확장이 자동으로 시작하는 백그라운드 프로세스입니다
- 패키지가 업데이트되면 Daemon이 자동으로 재시작됩니다
