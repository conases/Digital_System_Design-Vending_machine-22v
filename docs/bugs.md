# 재현·수정 및 남긴 제한

원본을 고치지 않고 실행했다. 로그는 `docs/evidence/`, 큰 파형은 `build/`에 재생성한다. `make baseline`은 의도된 FATAL 메시지까지 일치하는 실패를 확인했을 때 0으로 끝난다. 원본 기능이 통과했다는 뜻이 아니다. 예상 밖 성공, 컴파일 실패, 다른 실패, timeout은 재현 실패로 처리한다.

| 버그 ID | 관련 요구사항 | 원본 파일·위치 | 재현 입력 | 기대값 | 실제값 | 원인 | 수정 내용 | 회귀 테스트 | 실행 결과 |
|---|---|---|---|---|---|---|---|---|---|
| B01 | R01,R05 | TINYPROJECT.v reset 블록(81~89행) | KEY0 reset 후 해제 | Ticket=0 | Ticket=X | reset에서 Ticket 대입 누락 | reset에 Ticket=0, 미구동 LED도 0으로 정의 | regression/reset, board four-state | 원본 실패 → 수정 통과 |
| B02 | R07 | LAB4c S7 전이(313~320행) | 단위 테스트로 S7과 IN=1 주입 | NextState=S1 | S7 | if 뒤의 무조건 대입이 S1 덮어씀 | else로 S7 유지 조건 분리 | regression/fsm | 원본 실패 → 수정 통과 |
| B03 | R02 | LAB4c S0,S5 | SW0, KEY3 180 내부 클록 누름 | 500원 한 번 | 3500원 | IN 레벨을 반복 수락 | 초기 단계 누름 이벤트, 최종 50 MHz 엣지 포착 | regression/held, model held | 원본 실패 → 수정 통과 |
| B04 | R04 | bin7seg 1(392행) | 5000 투입, Ticket6 구매 → 1700 | 1은 세그먼트1·2 점등 | 세그먼트4·5 점등 | 1111001 잘못된 상수 | 1001111로 수정; [0:6] 순서 유지 | regression/digit1, oracle, UI | 원본 실패 → 수정 통과 |
| B05 | R05,R07 | TINYPROJECT Ticket clear(140~142행) | 5000 투입 후 Ticket6 | 다음 선택까지 LEDG4=1 | 변환 중 LED=0 | S4의 prt=0 분기가 조기 소등 | SW 선택 변경까지 Ticket 유지, issue 이벤트 별도 | regression/ticket, test_model, UI | 원본 실패 → 수정 통과 |
| B06 | R04 | 최상위 포트(1~18행) | HEX4를 연결해 컴파일 | HEX4 존재, 상위자리0 | 포트 없음으로 컴파일 오류 | QSF에는 핀만 있고 RTL 포트 누락 | HEX4 포트와 0 패턴 연결 | hex4_probe, board oracle | 원본 컴파일 실패 → 수정 통과 |
| B07 | R02 | Clk_Down/느린 Clk 입력 샘플링(39~45행) | 기본 분주에서 50 MHz 5클록만 KEY3 누름 | 잔액500 | 잔액0 | 약21 ms 샘플 간격 사이 누름 유실 | 50 MHz 동기화·엣지·1입력 포착, 단일 클록 enable | short_press, model hardware | 최소 기능 수정본 실패 → 구조 수정 후 통과 |
| B08 | R04 | bcd0~3 직접 출력(149~174행) | 5000 표시 후 500 추가, 변환 매주기 관찰 | 5000 또는 완성5500 | 중간0000 등 표시 | 작업 BCD를 바로 HEX로 출력 | 완성된 표시 레지스터를 분리 | regression/display | 원본 실패 → 수정 통과 |

B02는 원본 자연 거래에서 도달했다고 주장하지 않는다. B05가 Ticket을 먼저 지워 원본의 자연 거래는 S6/S7에 도달하지 못했다. S7 전이 결함은 상태 주입으로 분리 재현했다. 기능 시나리오의 분주 출력 강제는 빠른 원인 분리용이며, 실제 분주·전체 경로 검증은 `board_regression`과 `short_press`, Verilator hardware에서 별도 수행한다.

B07은 원본과 같은 분주를 가진 최소 기능 수정 커밋 `5334076`에서 먼저 재현했다. `docs/evidence/minimal-short.log`가 그 기록이며, 최종 회귀는 똑같은 `tb/short_press.sv`의 입력과 기대값을 사용한다. 원본 직접 재현은 `make baseline-hardware`로도 가능하다.

금액 상수는 각각 500/1000/5000/3300/6600/8000으로 PDF와 일치한다. 가격 버그는 없다. 원본의 조합 블록에는 기본 대입과 @(*)가 있으며 재현한 조합 래치는 없다. 원본 blocking 대입·절단·암시적 tic은 새 RTL에서 명시적 폭과 nonblocking, 선언된 신호로 정리했다. 다중 드라이버나 signed 차감 결함이 확인됐다고 주장하지 않는다.

## 보존한 제한 및 가설

- **티켓 카운트 10~16:** 사용자(2026-11-02)가 원본 동작 보존을 선택했다. 10~15는 decoder default `1000010`, 16은 4비트 rollover로 0이다. 별도 회귀로 이 제한까지 보존되는 것을 검사한다. 해결한 버그로 세지 않는다.
- **입력 처리 중 누름:** 대기 상태에서 한 번 포착하며 처리 중 추가 누름은 버린다. 무제한 큐를 추가하지 않았다. 여러 SW 동시 입력은 우선순위 없이 무효다. reset과 입력 동시는 reset 우선이다.
- **동기화:** SW를 안정시킨 뒤 KEY를 누르는 것이 전제다. FPGA 핀 metastability, SW 다중비트 원자성, reset 비동기 해제 recovery/removal, 실제 회로 잡음은 이벤트 시뮬레이션만으로 검증할 수 없다. KEY의 보드 debounce를 확인했으므로 임의 추가 bounce 필터를 요구사항으로 만들지 않았다.
- **초기화:** reset 전 정상 출력을 보장하지 않는다. Icarus에서 reset 후 출력 X/Z 검사를 수행하며 Verilator의 초기 0을 근거로 정상이라 하지 않는다.
- **Quartus:** 과거 STA는 사용자 클록 제약 없이 자동 1 ns 주기로 분석되어 음수 slack이 있다. 이것만으로 실제 50 MHz 실패를 판정할 수 없다. 수정 설계의 합성·배치배선·20 ns 타이밍은 아직 수행하지 않았다.

## 도구 오류

초기 SystemVerilog `string` case 테스트벤치에서 Icarus 13.0 내부 assertion이 발생했다. packed 문자열로 바꾸고 원본 RTL은 그대로 유지했다. `evidence/icarus-string-concat-crash.log`라는 초기 이름의 로그에 컴파일러 assertion이 있다. 정확한 최소 도구 버그 원인까지 격리하지 않아 문자열 concatenation만의 문제라고 확정하지 않는다. 원본 RTL 호환성 패치는 필요 없었다.

최초 테스트 준비 중 SW0의 기대값을 오독했으나, 기능 재현 로그를 얻기 전에 PDF·원본 상수를 대조해 500으로 바로잡았다. 확정된 실패를 통과시키기 위해 기대값을 바꾸지 않았다.
