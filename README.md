# DE2-115 FPGA 티켓 자판기 복원

2022년 Verilog 과제를 원본 보존·실패 재현·RTL 수정·자동 회귀·로컬 가상 보드로 복원한 프로젝트다. 자판기 동작은 실제 Verilog가 실행하며 브라우저에서 금액 로직을 다시 구현하지 않는다. 설명은 한국어로 정리했다.

- [요구사항과 검증 연결](docs/requirements.md)
- [설계·FSM·보드 연결](docs/architecture.md)
- [버그 재현과 수정 근거](docs/bugs.md)
- [실제 검증 결과와 한계](docs/verification.md)
- [작업 기록](docs/progress.md)

## macOS 준비

Apple Silicon macOS 26.6.2에서 Icarus 13.0, Verilator 5.054, Apple Clang 16.0.0, Python 3.12.0, Node 20.11.1, 시스템 make로 확인했다. Python/Node 패키지 설치는 필요 없다. C++ 빌드에는 Xcode Command Line Tools가 필요하다.

```sh
xcode-select --install  # 설치되어 있으면 생략
brew install icarus-verilog verilator python node
# PDF를 다시 읽고 렌더링할 때만 필요
brew install poppler
```

기존 Homebrew와 Python/Node가 있으면 다시 설치할 필요 없다. 처음 작업한 상위 폴더에도 별도 Git이 있으므로 반드시 실제 레포 안에서 실행한다.

```sh
cd /Users/hajiseung/DigitalSystemDesgin/Digital_System_Design-Vending_machine-22v
git rev-parse --show-toplevel
make check-preservation
make baseline
make baseline-hardware
make lint
make test
make sim
make test-ui
make ui
```

| 명령 | 결과 |
|---|---|
| `make baseline` | 무수정 원본의 기능 실패 6개와 HEX4 포트 누락 재현. 예상 실패가 맞으면 명령 성공 |
| `make baseline-hardware` | 원본 기본 분주에서 짧은 누름 유실을 재현 |
| `make lint` | 수정 RTL Verilator `--Wall` 정적 검사 |
| `make test` | 보존 해시, Icarus X/Z·기능·기본 분주, 729개 oracle 시나리오, Verilator demo/hardware 검사 |
| `make sim` | 대표 5000→3300구매→1700→1000추가→2700 및 부족한6600구매, VCD/JSON 생성 |
| `make test-ui` | 임시 localhost 서버에서 실제 app.js 핸들러·렌더러/HTTP/RTL/VCD/재생/연결 종료 검사. 브라우저 레이아웃 검사는 아님 |
| `make ui` | 빠른 데모 DIV_BITS=2, http://127.0.0.1:8765 |
| `make ui MODE=hardware PORT=8766` | 원래 분주 DIV_BITS=20의 보드 모델 |

서버 종료는 Ctrl+C. 포트 충돌이면 `PORT=8766` 등으로 바꾼다. 실행 모델은 소스·빌드 방법·도구 버전 해시로 갱신되며 `build/`만 삭제해도 모든 결과를 다시 만들 수 있다. PDF/ZIP은 테스트에 필요하지 않아 새 clone에서도 코드 검증이 가능하다. 원본 PDF의 로컬 보존본은 공개 Git에 포함하지 않았다.

## 가상 보드 사용

1. `make ui` 후 주소를 브라우저에서 연다. 상단에서 RTL 연결 상태와 데모/하드웨어 타이밍을 확인한다.
2. Reset을 누른다. SW2만 켜고 KEY3을 눌렀다 놓은 뒤 `클록 진행`(기본240)을 누르면 잔액 **05000**이다.
3. SW2를 끄고 SW6만 켠 뒤 KEY3을 눌렀다 놓고 240클록 진행하면 **01700**, HEX6은 **1**, LEDG4는 켜진다.
4. SW6을 끄고 다음 종류를 선택한 후 클록을 진행하면 발권 표시가 꺼진다. 새 구매에 성공할 때 다시 켜진다.
5. `실행`은 입력한 묶음 클록을 화면 주기에 맞춰 진행한다. `일시정지`, `+1 클록`, 원하는 묶음 수, KEY 누름·해제를 지원한다. 일시정지 상태에서도 KEY 조작은 동기화를 위해 명시적으로 5클록 진행한다.
6. 입력 기록 저장/재생은 실제 서버 명령과 RTL 버전을 사용한다. 기록은 초기 reset부터 재생한다. 같은 버전에서 재생해야 한다.

하드웨어 모드는 FSM 한 단계에 1,048,576개의 50 MHz 클록이 필요하다. 한 거래 완료까지 대략 3,500만 클록을 진행한다. 기본240 묶음 대신 `35000000`을 사용하거나 실행을 계속한다. 시뮬레이션 시간은 실제 진행한 클록으로 계산하고 화면 주기와 독립적이다.

KEY0 reset / KEY3 In은 active low이다. KEY1·2는 미사용, 여러 SW를 동시에 켜면 입력은 무효다. KEY는 이미 보드에서 debounce된다. 선택을 안정시킨 후 입력 대기 상태에서 누른다. 처리 중 새 누름은 버린다.

HEX4는 잔액의 상위 0 자리, HEX5는 미연결, HEX6/7은 티켓6/7 누적 수량이다. 사용자 선택으로 4비트 원본 수량 동작을 보존했다. **10~15장에서는 십진수 표시가 깨지고 16장에서 0으로 돌아간다.** 취소·환불·현금 거스름돈 배출은 PDF 명세에 없다.

## 파일과 증거

```text
legacy/   원본 소스·Quartus 설정·기존 보고서·SHA-256 목록
rtl/      수정 RTL (명시적 소스 목록 sim/rtl.f)
tb/       실패 재현과 Icarus 회귀 테스트
sim/      실제 Verilator 모델·C++ 하네스·로컬 HTTP 브리지
ui/       가상 보드 화면 (외부 웹 패키지 없음)
scripts/  모델 빌드·독립 기대값·검증·보존 확인
docs/     요구사항·설계·버그·검증·작업 기록
build/    재생성 가능한 모델·로그·파형·세션 (Git 제외)
```

대표 파형은 `build/representative.vcd`, 실패 파형은 `build/baseline-*.vcd`, UI 대조 파형은 `build/bridge.vcd`다. VCD를 지원하는 파형 뷰어에서 열 수 있다. 작은 실제 실행 로그는 `docs/evidence/`에 남겼다. 원본과 수정본은 별도로 컴파일한다.

현재 결과는 RTL 시뮬레이션 검증이다. **수정 RTL의 Quartus 합성·배치배선·타이밍 분석과 실제 FPGA 보드 동작은 미검증**이다. 당시 보고서도 적절한 50 MHz 클록 제약이 없었으므로 타이밍 통과 근거로 사용하지 않는다. 브라우저 제어 도구 부재로 실제 브라우저 레이아웃/마우스 조작의 육안 검증도 수행하지 못했다.

[원본 보존 안내](legacy/README.md) · [Icarus 공식 실행 안내](https://steveicarus.github.io/iverilog/usage/getting_started.html) · [Verilator 모델 연결](https://verilator.org/guide/latest/connecting.html) · [DE2-115 공식 매뉴얼](https://www.terasic.com.tw/attachment/archive/502/DE2_115_User_manual.pdf)
