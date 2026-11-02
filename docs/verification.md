# 검증 결과

2026-11-02, Asia/Seoul. 모든 표의 통과는 실제 실행한 범위에만 해당한다.

## 환경과 설치

| 항목 | 확인한 값 |
|---|---|
| OS / CPU | macOS 26.6.2 (25G83), arm64 |
| Icarus Verilog | 13.0 stable v13_0 |
| Verilator | 5.054, 2026-11-01, rev vUNKNOWN-built20261101 |
| C++ | Apple clang 16.0.0, C++17 |
| Python / Node | 3.12.0 / 20.11.1 |
| PDF 도구 | Poppler pdftotext 26.10.0 |
| 빌드 도구 | /usr/bin/make |

기존 brew/Python/Node/Clang은 있었고 Icarus·Verilator·Poppler는 없었다. `brew install icarus-verilog verilator poppler`를 실행했다. 샌드박스에서 Cellar 쓰기가 막혀 승인된 확대 권한으로 다시 실행해 설치했다. `chown` 등 소유권 변경은 수행하지 않았다. Homebrew가 Poppler 의존성도 설치/갱신했다. Python/Node 외부 패키지는 설치하지 않았다.

원본은 Icarus에서 그대로 컴파일된다. 암시적 tic 경고는 로그에 보존했고 시뮬레이터 호환성 복사본이나 빈 IP 스텁은 필요하지 않았다. 원본에 없는 IP를 만들어 끼우지 않았다. 초기에 PDFKit로도 읽기를 시도했지만 최종 페이지 확인은 Poppler 추출·PNG 렌더링으로 수행했다.

## 실행 결과

| 명령 / 검사 | 실제 결과 | 증거 |
|---|---|---|
| `make check-preservation` | 공개 보존본16파일 및 로컬 비공개 첨부/ZIP 멤버106개 SHA-256 일치 | legacy/SHA256SUMS, MANIFEST.json |
| `make baseline` | 6개 기능 실패와 HEX4 포트 컴파일 실패 재현 | evidence/baseline-*.log |
| `make baseline-hardware` | 원본 기본 분주에서 KEY3 5클록 누름 → 500 대신0 재현 | evidence/baseline-hardware.log |
| `make lint` | 수정 RTL --Wall 통과 | evidence/lint.log |
| `make test` | 보존·기능7종·short·HEX4·Icarus oracle·Verilator 검사 통과 | evidence/final-tests.log |
| Icarus board oracle | 81잔액 × 입력9종 =729 시나리오, reset 포함5022단계, 4293거래; 출력 X/Z 및 거래 중 reset 통과 | evidence/board-tests.log |
| Verilator demo | 같은729 시나리오·4293거래, 수량0~9, 원본 수량10~16 제한 보존, 긴 누름 및 reset 우선 통과 | evidence/model-tests.log |
| Verilator hardware | 첫 FSM tick=524288, 주기1048576; 짧은 누름 포착, 완성00500 표시 통과 | evidence/model-tests.log |
| `make sim` | 5000→3300구매→1700→1000입금→2700→6600구매 실패 시나리오 통과 | evidence/sim.log; build/representative.vcd, .json |
| `make test-ui` | 실제 app.js 입력/렌더 함수→HTTP→Verilator 잔액1700·56세그먼트 상태·발권 이벤트·재생·오류표시 통과 | evidence/ui-test.log |
| UI 시퀀스/파형 대조 | 같은 명령으로 직접 RTL 실행과 HTTP UI 출력 일치. 실제 issue VCD 시각5620ns와 JSON 이벤트 일치 | evidence/bridge-test.log; build/bridge.vcd |
| 모델 종료 | 실제 모델 프로세스 종료 후 연결 오류 발생; 가짜 정상 응답 없음 | evidence/bridge-test.log |
| 깨끗한 소스 사본 | 기존 build/PDF/ZIP 없이 같은 설치 도구 환경에서 baseline·baseline-hardware·lint·test·sim 및 별도 test-ui 통과 | evidence/clean-checkout.log, clean-ui.log |
| 실제 브라우저 | 미검증: in-app/Chrome 사용 불가, 환경 inventory/Safari 제어 timeout | 육안 클릭·반응형 레이아웃·스크린샷 미확보 |
| FPGA / Quartus | 미수행 | 합성·배치배선·STA·보드 검증 필요 |

독립 oracle은 PDF의 십진수 화폐·가격으로 상태 공간을 탐색한다. RTL의 bin 상수·add3/shift 구현을 기대값 생성에 복사하지 않는다. 각 도달 잔액에 화폐3종·티켓2종·무효4종(0,3,192,8191)을 적용한다. 정확한3300/6600, 부족, 초과, 최소0/최대8000, 자리올림과 연속 구매가 이 집합에 포함된다. 결정적 전수 시나리오이므로 랜덤 seed는 없다. 실패 시 시나리오ID·SW·기대/실제값이 표시되고 fixture는 `build/oracle.txt`로 재생성한다.

SV 테스트는 비교 실패·timeout에 `$fatal(1)`을 사용한다. 실행기는 subprocess timeout과 종료 코드를 검사한다. baseline은 기대 FATAL 텍스트까지 확인해야 성공한다. 최종 구현 전 기준 실패를 커밋으로 먼저 남겼다. 상태 주입/분주 우회로 원인을 분리한 작은 테스트와 실제 50 MHz 입력부터의 통합 테스트를 구분했다.

오름차순 HEX 벡터 경고 ASCRANGE는 보드 인덱스 보존을 위해 해당 선언 근처만 제한적으로 해제했다. `-Wno-fatal`이나 전체 경고 무시는 사용하지 않았다. `issue`의 Verilator public 속성은 실제 진단 관측 목적이며 동작을 대신하는 스텁이 아니다.

## 시간·초기화 해석

C++ 하네스는 CLOCK_50의 반주기마다 eval하고 10ns씩 진행한다. Verilator 빌드에 `--timescale 1ns/1ns`를 명시해 VCD 단위와 UI의 ns를 일치시킨다. UI 화면 주기는 별도의100/500ms 타이머이다. 작은 거래에도 존재하는 issue 펄스를 클록별 기록해 화면 사이에서 유실하지 않는다.

Icarus는 네 상태 X/Z를 검사하며 reset 직후 원본 Ticket X를 확인했다. Verilator의 두 상태 초기값으로 reset 누락을 정상 판정하지 않았다. 최종 reset 후에는 미사용 LED까지 정의된 값으로 검사한다. reset 전의 정상 출력을 약속하지 않는다.

## 하드웨어 검증 한계

원본 Quartus 20.1.1 Fitter는 2022-12-12 성공으로 기록돼 있다. 그러나 STA는 사용자 constrained clock이 없어 `derive_clocks -period 1.0`으로 CLOCK_50와 Clk_Down[19] 모두1ns를 적용했다(원본 sta.rpt 2172행 이후). 요약의 setup slack -1.871ns/-5.330ns 및 음수 pulse-width는 적절한50MHz 제약의 결과가 아니므로 실제 보드 타이밍 성공 또는 실패를 여기서 확정하지 않는다.

수정 RTL은 단일50MHz 클록으로 바뀌었고 기존 QSF는 계속 원본 파일만 가리킨다. Quartus용 새 소스 목록과20ns SDC, 핀 전압/JP 설정, reset 해제와 비동기 입력 제약을 검토한 후 합성·배치배선·STA를 새로 수행해야 한다. 보드에서 동기화 지연·비동기 SW 동시변경·물리적 bounce·발권 LED 유지와 수량 제한을 확인해야 한다.

티켓 수량10장 이상은 사용자 지시로 원본 제한을 유지했다. 처리 중 버튼 입력 큐와 취소/환불/현금 반환은 구현하지 않았다. 이는 PDF에서 확정되지 않은 기능이며 검증을 완료했다고 주장하지 않는다.

## 재생성과 연결 확인

새 clone에서 README 도구를 준비한 뒤 `make baseline baseline-hardware lint test sim test-ui`를 실행한다. `build/`는 커밋하지 않는다. PDF 미보유여도 코드 검증은 가능하다. 실제 브라우저 UI는 `make ui`로 추가 수동 확인한다. 로컬 파일·네트워크를 제한하는 에이전트 환경에서는 localhost listen/connect에 추가 실행 권한이 필요할 수 있다. 일반 터미널에서는 같은 명령을 실행한다.
