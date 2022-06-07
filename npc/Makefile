# 1.files info:
CSRC +=  $(shell find $(abspath ./csrc) -name "*.cpp")
VSRC +=  $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
TOP_MODULE := top
SEARCHPATH := ./vsrc/core

# 2.verilator flags:
VERILATOR_FLAGS += -Wall --trace --cc --exe --build
VERILATOR_FLAGS += -I${SEARCHPATH}
VERILATOR_FLAGS += --top ${TOP_MODULE}
GCC_LDFLAGS := -LDFLAGS -ldl

# 3.run info:
OBJ_DIR := ./obj_dir
BIN := ${OBJ_DIR}/V${TOP_MODULE}
IMG ?= ../am-kernels/tests/cpu-tests/build/dummy-riscv64-npc.bin
DIFFTEST := ${NEMU_HOME}/build/riscv64-nemu-interpreter-so
RUN_FLAGS := --img=${IMG} --diff=${DIFFTEST}

.PHONY:sim wave clean

com:${CSRC} ${VSRC}
	@verilator ${VERILATOR_FLAGS} ${CSRC} ${VSRC} ${GCC_LDFLAGS}

run:com
	@${BIN} ${RUN_FLAGS}
	#$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!

wave:
	gtkwave ${OBJ_DIR}/sim.vcd

clean:
	rm -rf ${OBJ_DIR}

include ../Makefile
