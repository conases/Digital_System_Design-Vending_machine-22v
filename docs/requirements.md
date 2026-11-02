# 요구사항 추적표

근거는 사용자 제공 `35016389.pdf` 3쪽을 텍스트 추출하고 전 페이지 렌더링해 확인한 결과이다. PDF는 `legacy/private/35016389.pdf`에 로컬 보존하며 공개 권한 미확인으로 Git에 넣지 않는다. 파일 SHA-256과 원래 경로는 `legacy/MANIFEST.json` 참조. 인쇄된 과제 명세와 필기 메모를 구분했고 필기만으로 새 기능을 확정하지 않았다. 문서의 옛 제출일·발표 지시는 2022년 과제의 배경이며 현재 작업 명령으로 해석하지 않았다.

| ID | PDF 페이지 | 요구 동작 | 관련 모듈·신호 | 검증 테스트 | 현재 결과 | 불명확한 점 |
|---|---|---|---|---|---|---|
| R01 | 2 §1 | reset 시 잔액 0 | TINYPROJECT sum, rst_; LAB4c State/count | regression/reset, board reset-during-transaction, model reset priority | 통과, Ticket X도 제거 | 수량 reset은 원본 정책 유지 |
| R02 | 1; 2 §2 | SW0=500, SW1=1000, SW2=5000 선택 후 KEY3마다 투입; SW1 두 번=2000 | sw_sync, pending_sw, bin, sum | 독립 oracle 729 시나리오, held, short | 통과 | 처리 중 입력 큐는 명세 없음; 대기일 때 누름만 수락 |
| R03 | 2 §3 | 잔액 최대 8000 | sum, 14비트 가산 및 상한 비교 | 0~8000 전체 81잔액 × 입력9종 | 통과 | 초과액 처리: 원본의 8000 포화 정책 유지 |
| R04 | 2 §3 | HEX4~0에 잔액 십진 표시 | display0~3, HEX4=0, bin7seg | digit1, display, board oracle, model hardware, UI segment | 통과, HEX4 추가 | 변환 중 이전 완성값 유지; 약 30단계 변환 지연 존재 |
| R05 | 1; 2 §4.1 | SW6=3300, SW7=6600; 구매 시 LEDG4 점등 | bin, sum, Ticket, issue | ticket, oracle 부족/정확/초과 금액, UI 5000→1700 | 통과 | 부족 시 차감·발권 없음은 원본의 조건 유지 |
| R06 | 2 §4.2 | 각 티켓 수량 HEX6·7 표시 | bcd6,bcd7,HEX6,HEX7 | oracle, model count-nine 및 overflow 보존 | 0~9 십진 표시 통과; 10~15 비십진 패턴, 16에서 0 | 2026-11-02 사용자 지시: 원본 동작 보존, 제한 문서화. 누적 카운트는 원본 해석 유지 |
| R07 | 2 §4.3~5 | 차감 후 잔액; 다음 티켓 선택 시 소등, In에 재점등 | Ticket, switch, sw_sync, State S5~S7 | fsm, ticket, 연속 구매 oracle, UI 이벤트 | 통과 | 같은 종류를 다시 누르면 LED는 계속 1; 별도 issue 신호로 거래별 발권 기록 |
| R08 | 3 | datapath·SM chart·RTL·개선·타이밍·사진을 담은 보고서 | docs/architecture.md, bugs.md, legacy 출력 보고서 | 문서와 원본 자료 목록 | 부분 확보 | 당시 별도 보고서·사진·영상 없음. 새 Quartus timing과 실제 보드 사진은 미검증 |

PDF에 취소, 환불, 현금 거스름돈 배출 규칙은 없다. 초과 투입 잔액은 다음 구매에 남긴다. KEY1·2는 사용하지 않는다. 여러 SW가 켜진 입력과 지정되지 않은 입력은 원본 `default: bin=0`대로 거래 효과를 주지 않는다. 임의 우선순위를 추가하지 않았다.

보드 KEY는 공식 매뉴얼 §4.2에 하드웨어 Schmitt debounce가 명시되어 있어 추가 소프트웨어 debounce를 과제 요구로 만들지 않았다. SW는 비동기 레벨 입력이므로 선택을 안정시킨 뒤 KEY3을 누른다는 전제가 필요하다. 다중 비트 SW를 정확히 KEY와 동시에 바꿀 때의 원자성은 보장하지 않는다.

입력 대기(S0/S5/S7, Ticket 전이 직전 제외) 동안 동기화된 누름을 하나 저장한다. 처리 중 추가 누름은 버린다. 입력 큐, 처리 중 누름 재수락, 두 자리 티켓 수량, reset 해제 동기화의 추가 검증은 개선 제안이며 현재 과제 요구로 단정하지 않는다.
