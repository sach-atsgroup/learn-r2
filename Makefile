# radare2 course - build, grade, diagnose.
SHELL   := /bin/bash
BUILD   := build
SRC     := src
CC      := gcc
CXX     := g++
CROSSCC := /opt/V1X00/sysroots/x86_64-cclinuxsdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-gcc
SYSROOT := /opt/V1X00/sysroots/aarch64-poky-linux

X86 := 00_arith 01_tour 02_haystack 03_keycheck 04_guard 05_xorbox \
       06_structs 07_trial 08_many 09_stripped capstone
ALL := $(addprefix $(BUILD)/,$(X86)) $(BUILD)/06_vtable $(BUILD)/10_arm

.PHONY: all clean doctor check score solve help
.DEFAULT_GOAL := all

all: $(ALL)
	@echo "built: $(words $(ALL)) targets in $(BUILD)/"

$(BUILD):
	@mkdir -p $(BUILD)

# --- default: unoptimised, with symbols -------------------------------------
$(BUILD)/%: $(SRC)/%.c | $(BUILD)
	$(CC) -O0 -g -fno-inline -o $@ $<

# --- per-target overrides ---------------------------------------------------

# A string appended past the last section: iz cannot see it, izz can.
$(BUILD)/02_haystack: $(SRC)/02_haystack.c | $(BUILD)
	$(CC) -O0 -g -fno-inline -o $@ $<
	@printf 'overlay: izz found me, iz did not' >> $@

$(BUILD)/06_vtable: $(SRC)/06_vtable.cpp | $(BUILD)
	$(CXX) -O0 -g -fno-inline -o $@ $<

$(BUILD)/09_stripped: $(SRC)/09_stripped.c | $(BUILD)
	$(CC) -O2 -s -o $@ $<

$(BUILD)/capstone: $(SRC)/capstone.c | $(BUILD)
	$(CC) -O2 -s -o $@ $<

$(BUILD)/10_arm: $(SRC)/10_arm.c | $(BUILD)
	@test -x $(CROSSCC) || { echo "cross gcc missing: $(CROSSCC)"; exit 1; }
	$(CROSSCC) --sysroot=$(SYSROOT) -O0 -g -fno-inline -o $@ $<

# --- grading ----------------------------------------------------------------
check:
	@./check.sh "$(N)" "$(A)"

score:
	@./check.sh score

solve:
	@echo "Solutions are written on request, one module at a time. Ask for module N."

doctor:
	@./check.sh doctor

clean:
	rm -rf $(BUILD)

help:
	@echo "make            build every target"
	@echo "make doctor     check the toolchain"
	@echo "make check N=3 A='answer'"
	@echo "make score      progress so far"
	@echo "make clean      remove build/"
