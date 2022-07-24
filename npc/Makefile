# 1.files info:
CSRC +=  $(shell find $(abspath ./csrc) -name "*.cpp")
VSRC +=  $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
TOP_MODULE := top
SEARCHPATH := ./vsrc/core/other

# 2.verilator flags:
VERILATOR_FLAGS += -I${SEARCHPATH}
VERILATOR_FLAGS += --top ${TOP_MODULE}
VERILATOR_FLAGS += --trace --cc --exe --build --threads 2 -j 8
VERILATOR_FLAGS += -Wno-fatal		# only print lint warning, but not terminate compile.
VERILATOR_FLAGS += -Wno-UNUSED 		# close <unused> warning.
VERILATOR_FLAGS += -Wno-PINMISSING	# close <pin missing> warning.
VERILATOR_FLAGS += -Wno-UNOPTFLAT 	# close <feedback to clock or circular logic> warning, use for rca_nbit(mul66)
GCC_LDFLAGS := -CFLAGS -g -LDFLAGS -ldl								# -g for gdb, -ldl for dynamic link(nemu difftest).

# 3.run info: 
IMG ?= ../am-kernels/tests/cpu-tests/build/dummy-riscv64-npc.bin#	# program img, run on npc.
DIFFTEST := ${NEMU_HOME}/build/riscv64-nemu-interpreter-so#			# nemu img, use for difftest.
OBJ_DIR := ./obj_dir# 												# npc obj path.
BIN := ${OBJ_DIR}/V${TOP_MODULE}#									# npc obj bin.
RUN_FLAGS := --img=${IMG} --diff=${DIFFTEST}#						# npc main args.
NPC_EXEC := ${BIN} ${RUN_FLAGS}#									# npc bin + args.

.PHONY:run gdb wave clean

com:${CSRC} ${VSRC}
	@verilator ${VERILATOR_FLAGS} ${CSRC} ${VSRC} ${GCC_LDFLAGS}

run:com
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@${NPC_EXEC}

gdb:com ${DIFFTEST}
	$(call git_commit, "gdb RTL") # DO NOT REMOVE THIS LINE!!!
	@gdb --silent -s ${BIN} --args ${NPC_EXEC}

wave:
	@gtkwave ${OBJ_DIR}/sim.vcd

clean:
	rm -rf ${OBJ_DIR}

include ../Makefile
