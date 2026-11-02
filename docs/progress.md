# 작업 기록

2026-11-02 (Asia/Seoul)

## 시작과 자료

실제 레포는 `/Users/hajiseung/DigitalSystemDesgin/Digital_System_Design-Vending_machine-22v`이다. 상위 `/Users/hajiseung/DigitalSystemDesgin`도 별도 Git 저장소이나 건드리지 않았다. 홈이 Git 최상위인 문제는 없었고 적용 AGENTS.md는 찾지 못했다. 시작 상태는 main, `135ea32`, README만 존재, 사용자 변경 없음이었다. origin은 `git@github.com:conases/Digital_System_Design-Vending_machine-22v.git`이다.

첨부 요청문을 현재 요청으로 읽었으며 과제 PDF의 제출일·발표 지시를 새 실행 명령으로 해석하지 않았다. ZIP에 당시 RTL과 설정·빌드 산출물이 있고, 별도 보고서·사진·영상·테스트벤치·SDC·ROM/include/IP는 없었다. 전체 자료를 먼저 바이트 보존하고 해시를 기록했다. PDF·ZIP 전체/캐시는 로컬 `legacy/private/`에 보존하되 업로드하지 않는다.

실행 계획은 원본 보존 → PDF/공식 보드 확인 → 실패 재현 → 최소 기능 수정 → 구조 개선 → 독립 oracle 회귀 → Verilator UI → 문서·커밋·push였다.

## 완료한 작업

- 보존 커밋 `39bf09a`: 원본16파일과 전체 첨부 provenance/해시, private 보존 영역.
- 실패 재현 `47ecdbc`~`391041d`: 초기 도구 assertion도 기록하고 원본 다섯 기능 결함을 재현.
- 최소 기능 수정 `5334076`: Ticket/reset/눌림/LED/S7/숫자1/HEX4를 작은 패치로 수정.
- 짧은 누름 실패 `1fa96eb`: 원래 하드웨어 분주에서 최소 수정본의 유실을 먼저 확인.
- 구조 개선 `874585c`: 50MHz 입력 동기화·포착, 원래 주기의 clock enable, 완성 표시 레지스터. 원본 FSM·BCD 알고리즘 유지. 표시 중간값 실패도 추가 재현.
- 전수 회귀 `ee51202`: PDF 십진 가격 기준729개 시나리오, 두 시뮬레이터 실행 모델.
- UI `e2ea25e`: 실제 RTL 연결 브리지, 세그먼트·LED, 클록 제어, 기록·재생, 오류 표시.
- 후속 검증: 시간 단위 명시 및 VCD 실제 펄스 대조, 원본HEX4 포트 누락과 기본 분주 입력 유실 추가 재현, 엄격 lint 및 최종 회귀.
- 사용자 결정: 10장 이상 티켓 수량은 원본4비트·decoder 동작 보존. 10~15 표시 이상과16 rollover를 제한으로 문서화하고 회귀 검사.

실제 결과는 `verification.md`와 `evidence/`에 기록한다. 원본 가격 상수는 맞으며 가격 버그를 만들거나 임의 환불 요구를 추가하지 않았다. source SHA-256 검사를 다시 수행했다.

## 현재 상태와 남은 범위

코드·자동 검증·로컬 UI 구현은 완료했다. 비공개 첨부와 기존 build가 없는 git archive 사본에서도 baseline·baseline-hardware·lint·test·sim이 통과했다. 검증용으로 띄운 UI 서버는 종료했으며 `make ui`로 다시 실행한다. 브라우저 도구(in-app/Chrome 없음, inventory/Safari timeout) 때문에 실제 브라우저 육안 검증은 수행하지 못했다. 실제 app.js 핸들러/렌더러는 최소 DOM 하네스와 실제 HTTP/RTL/VCD로 검사했다. Quartus/실보드 검증과 당시 별도 보고서·사진 복원은 미완료다. 제출한 적 없는 보드 사진이나 과거 결과를 새로 만들지 않았다.

과거 STA는 자동1ns 클록 제약이므로50MHz 타이밍 결과로 판단할 수 없다. 다음 보드 단계는 수정 파일 목록·20ns SDC·물리 입력/reset 제약 준비 후 Quartus 검증이다. PDF 공개 권한 확인 전 업로드 보류를 유지한다.

작업 브랜치는 `restore/rtl-verification`이며 기본 main은 변경하지 않는다. 원격 main은 시작 커밋과 일치하고 SSH 읽기 접근을 확인했다. 최종 push 결과는 이 문서의 원격 업로드 기록과 최종 응답에 남긴다.
