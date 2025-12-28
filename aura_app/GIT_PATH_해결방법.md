# Git PATH 오류 해결 방법

## 문제 상황
- `Error: Unable to find git in your PATH.` 오류 발생
- `flutter pub get` 명령이 실패
- Flutter Daemon이 시작되지 않음

## 원인
Flutter는 일부 패키지를 가져올 때 Git을 사용합니다. Git이 시스템 PATH에 없으면 Flutter가 패키지를 제대로 가져올 수 없습니다.

## 해결 방법

### 방법 1: Git 설치 확인 및 PATH 추가 (권장)

#### 1단계: Git 설치 확인
1. Windows 검색에서 "Git Bash" 또는 "Git CMD" 검색
2. 실행되면 Git이 설치된 것입니다

#### 2단계: Git 경로 찾기
일반적인 Git 설치 경로:
- `C:\Program Files\Git\cmd\git.exe`
- `C:\Program Files (x86)\Git\cmd\git.exe`
- `C:\Users\사용자명\AppData\Local\Programs\Git\cmd\git.exe`

#### 3단계: PATH에 Git 추가
1. Windows 검색에서 "환경 변수" 검색
2. "시스템 환경 변수 편집" 선택
3. "환경 변수" 버튼 클릭
4. "시스템 변수" 섹션에서 "Path" 선택 → "편집" 클릭
5. "새로 만들기" 클릭
6. Git의 `cmd` 폴더 경로 추가 (예: `C:\Program Files\Git\cmd`)
7. "확인" 클릭하여 모든 창 닫기
8. **Cursor/VS Code 완전히 재시작** (중요!)

### 방법 2: Git 재설치 (Git이 없는 경우)

1. [Git 공식 사이트](https://git-scm.com/download/win)에서 Git 다운로드
2. 설치 시 **"Add Git to PATH"** 옵션 선택 (중요!)
3. 설치 완료 후 Cursor/VS Code 재시작

### 방법 3: 임시 해결 (Git 없이 진행)

일부 경우 Git 없이도 작동할 수 있지만 권장하지 않습니다:
- `pubspec.yaml`에 Git 의존성이 없으면 작동할 수 있음
- 하지만 Flutter 자체가 Git을 찾으려고 시도하므로 완전한 해결책은 아닙니다

## 확인 방법

터미널에서 다음 명령 실행:
```powershell
git --version
```

정상적으로 설치되어 있으면 버전 정보가 표시됩니다.

## 다음 단계

Git이 PATH에 추가된 후:
1. Cursor/VS Code 완전히 재시작
2. Command Palette (Ctrl+Shift+P) → "Dart: Pub Get" 실행
3. Command Palette → "Dart: Restart Analysis Server" 실행
4. 앱 실행: `flutter run -d chrome --dart-define=ENVIRONMENT=development`

## 참고

- Git이 PATH에 추가되면 Flutter가 패키지를 정상적으로 가져올 수 있습니다
- 이 문제가 해결되면 Flutter Daemon도 정상적으로 시작됩니다
- PowerShell 인코딩 오류는 별도 문제이며, Git PATH 문제와는 무관합니다
