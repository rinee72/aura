# Git 재설치 가이드 - Windows

## 현재 상태
- Git 버전: 2.52.0.windows.1
- 문제: `remote-https` helper 오류로 GitHub와 통신 불가

---

## Git 재설치 단계

### 1단계: 현재 Git 제거

1. **Windows 설정 열기**
   - `Win + I` 키 누르기
   - 또는 시작 메뉴에서 "설정" 검색

2. **앱 제거**
   - "앱" 또는 "애플리케이션" 클릭
   - 검색창에 "Git" 입력
   - "Git" 또는 "Git for Windows" 찾기
   - 클릭 후 "제거" 버튼 클릭

3. **제거 확인**
   - 모든 Git 관련 항목 제거 확인
   - PowerShell이나 명령 프롬프트를 모두 닫기

---

### 2단계: 최신 Git 다운로드

1. **Git 공식 사이트 방문**
   - https://git-scm.com/download/win
   - 또는 https://github.com/git-for-windows/git/releases

2. **최신 버전 다운로드**
   - "64-bit Git for Windows Setup" 다운로드
   - 파일명 예: `Git-2.xx.x-64-bit.exe`

---

### 3단계: Git 설치 (중요 옵션 선택)

설치 마법사에서 다음 옵션들을 **반드시** 선택하세요:

#### 선택할 옵션들:

1. **"Use bundled OpenSSH"** ✅
   - SSH 클라이언트로 사용

2. **"Use OpenSSL library"** ✅
   - HTTPS 연결에 필요

3. **"Use Git Credential Manager"** ✅
   - GitHub 인증에 필요

4. **"Use bundled OpenSSH"** ✅
   - (중복이지만 확인)

#### 기본값으로 두면 되는 옵션들:
- Editor: Visual Studio Code 또는 원하는 에디터
- Default branch name: main
- PATH environment: Git from the command line and also from 3rd-party software

---

### 4단계: 설치 완료 후 확인

1. **새 PowerShell 창 열기**
   - 기존 창은 닫고 새로 열기

2. **Git 버전 확인**
   ```powershell
   git --version
   ```

3. **Git 설정 확인**
   ```powershell
   git config --list
   ```

---

### 5단계: GitHub 연결 테스트

1. **원격 저장소 확인**
   ```powershell
   cd C:\modu
   git remote -v
   ```

2. **Fetch 테스트**
   ```powershell
   git fetch origin
   ```

3. **Push 테스트**
   ```powershell
   git push origin main
   ```

---

## 문제 해결

### 여전히 오류가 발생하면:

1. **Git Credential Manager 확인**
   ```powershell
   git config --global credential.helper manager-core
   ```

2. **환경 변수 확인**
   - Git 설치 경로가 PATH에 포함되어 있는지 확인

3. **GitHub Desktop 사용**
   - Git 재설치 후 GitHub Desktop도 다시 시작

---

## 빠른 설치 링크

- **공식 다운로드**: https://git-scm.com/download/win
- **최신 릴리스**: https://github.com/git-for-windows/git/releases/latest

---

## 설치 후 해야 할 일

1. ✅ Git 재설치 완료
2. ✅ 새 PowerShell 창 열기
3. ✅ `cd C:\modu` 이동
4. ✅ `git fetch origin` 테스트
5. ✅ `git push origin main` 실행

---

## 참고사항

- Git 재설치 후에는 기존 설정이 유지됩니다
- 로컬 커밋은 그대로 남아있습니다
- 원격 저장소 연결 정보도 유지됩니다

