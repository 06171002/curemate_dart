# curemate

## 프로젝트 개요

## 디렉토리 구조

```
curemate/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app/                    # 테마, 언어 공통 관리
│   │   ├── locale/
│   │   │   ├── locale_provider.dart
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_theme.dart
│   │   │   ├── theme_provider.dart
│   ├── features/               # 주요 기능별 폴더
│   │   ├── auth/               # 로그인/인증 관련
│   │   │   ├── data/           # 데이터 소스, API 연동
│   │   │   ├── model/          # 데이터 모델
│   │   │   ├── view/           # 화면(UI)
│   │   │   └── viewmodel/      # 상태관리, 비즈니스로직
│   │   ├── youtube/            # 유튜브 관련 기능
│   │   │   ├── data/
│   │   │   ├── model/
│   │   │   ├── view/
│   │   │   └── viewmodel/
│   │   ├── summary/            # 요약 관련 기능
│   │   │   ├── data/
│   │   │   ├── model/
│   │   │   ├── view/
│   │   │   └── viewmodel/
│   │   └── notification/       # 알림 관련
│   ├── services/               # 외부 API, 백엔드 연동 등
│   ├── widgets/                # 공통 위젯
│   └── l10n/                   # 다국어 지원(필요시)
├── test/                       # 테스트 코드
├── pubspec.yaml
└── README.md
```

---

필요하신 파일을 위 내용을 복사해서 직접 생성해 주세요.  
추가로, 샘플 코드나 각 폴더별 예시 파일이 필요하시면 언제든 요청해 주세요!

## 폴더별 설명
- **core/**: 테마, 라우팅, 공통 유틸, 상수 등
- **features/**: 기능별로 폴더를 나누고, 각 기능은 MVVM(혹은 Clean Architecture) 패턴으로 세분화
- **services/**: 외부 API, 백엔드 통신 등
- **widgets/**: 여러 곳에서 재사용하는 공통 위젯
- **test/**: 단위/통합 테스트

---

# 🔡 Flutter TextTheme의 의미와 역할

Flutter의 `TextTheme`에서 `display`, `headline`, `title`, `body`, `label` 등으로 스타일을 나누는 것은 단순히 글자 크기를 구분하는 것을 넘어, 각 텍스트에 **의미와 위계(Hierarchy)를 부여**하기 위함입니다.

이는 구글의 머티리얼 디자인 가이드라인에 기반하며, 앱 전체의 타이포그래피에 **일관성**을 부여하고 사용자가 화면 구조와 정보의 중요도를 쉽게 파악하도록 돕습니다.

<br>

### 📖 Display
화면에서 **가장 크고 중요한 텍스트**를 위해 사용됩니다. 주로 화면을 대표하는 짧은 문구나 핵심 수치를 강조할 때 사용하며, 한 화면에 한 번 정도만 사용하는 것이 일반적입니다.

- **주요 용도**:
    - 앱의 랜딩 페이지나 스플래시 화면의 슬로건
    - 대시보드의 핵심 지표 (예: "₩1,234,567")
    - 짧은 환영 메시지
- **스타일 종류**: `displayLarge`, `displayMedium`, `displaySmall`

<br>

### 📰 Headline
Display 스타일보다는 작지만, 여전히 **중요도가 높은 제목**을 위해 사용됩니다. 스크롤이 긴 페이지의 섹션을 구분하거나 정보 그룹의 헤더로 사용하기에 적합합니다.

- **주요 용도**:
    - 설정 페이지의 각 섹션 제목 (예: "알림", "화면 설정")
    - 다이얼로그(Dialog) 창의 제목
- **스타일 종류**: `headlineLarge`, `headlineMedium`, `headlineSmall`

<br>

### 📝 Title
**일반적인 제목**을 나타낼 때 사용되며, Headline보다 사용 빈도가 높습니다. 카드나 리스트 아이템과 같은 개별 컴포넌트의 제목으로 가장 흔하게 사용됩니다.

- **주요 용도**:
    - 카드(Card) UI의 제목
    - 리스트 아이템(`ListTile`)의 제목
    - 중간 크기 정보 그룹의 제목
- **스타일 종류**: `titleLarge`, `titleMedium`, `titleSmall`

<br>

### 📄 Body
가장 긴 텍스트, 즉 **본문(Body)**을 위해 사용됩니다. 앱에서 가장 높은 빈도로 사용되는 스타일이며, 상세 설명이나 긴 문단을 표현하는 데 적합합니다.

- **주요 용도**:
    - 게시글의 상세 내용
    - 사용자 리뷰, 댓글
    - 채팅 메시지 내용
- **스타일 종류**: `bodyLarge`, `bodyMedium`, `bodySmall`

<br>

### 🏷️ Label
**작고 기능적인 텍스트**를 위해 사용됩니다. 주로 다른 UI 요소에 대한 이름표나 보조적인 설명을 붙이는 역할을 합니다.

- **주요 용도**:
    - 버튼(Button) 내부의 텍스트
    - 탭(Tab) 메뉴의 이름
    - 아이콘 하단의 설명 텍스트 (Caption)
- **스타일 종류**: `labelLarge`, `labelMedium`, `labelSmall`

<br>

---

### 🔖 한눈에 보기

| 분류 (Category) | 스타일 종류 | 주요 용도 (Primary Use) |
| :--- | :--- | :--- |
| **Display** | `displayLarge`, `Medium`, `Small` | 화면의 가장 큰 핵심 정보, 짧은 강조 문구 |
| **Headline**| `headlineLarge`, `Medium`, `Small` | 스크롤 화면의 섹션 제목, 중요한 그룹의 헤더 |
| **Title** | `titleLarge`, `Medium`, `Small` | 카드나 리스트 아이템 등 개별 컴포넌트의 제목 |
| **Body** | `bodyLarge`, `Medium`, `Small` | 상세 설명, 긴 문단 등 앱의 표준 본문 텍스트 |
| **Label** | `labelLarge`, `Medium`, `Small` | 버튼, 탭, 아이콘, 캡션 등 기능적/보조적 텍스트 |
