.PHONY: baseline lint test sim ui model check-preservation
baseline:
	python3 scripts/run_baseline.py
lint:
	verilator --lint-only --Wall --top-module TINYPROJECT -f sim/rtl.f
test:
	python3 scripts/run_tests.py
sim: test
model:
	python3 scripts/build_model.py
ui: model
	python3 sim/server.py
check-preservation:
	shasum -a 256 -c legacy/SHA256SUMS
