MODE ?= demo
PORT ?= 8765
.PHONY: baseline lint test test-ui sim ui model check-preservation
baseline:
	python3 scripts/run_baseline.py
lint:
	verilator --lint-only --Wall --top-module TINYPROJECT -f sim/rtl.f
test:
	python3 scripts/check_preservation.py
	python3 scripts/run_tests.py
test-ui: model
	python3 scripts/run_ui_test.py
sim:
	python3 scripts/build_model.py demo
	python3 scripts/run_scenario.py
model:
	python3 scripts/build_model.py $(MODE)
ui: model
	python3 sim/server.py --mode $(MODE) --port $(PORT)
check-preservation:
	python3 scripts/check_preservation.py
