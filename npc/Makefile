# 1.files info:
CSRC +=  $(shell find $(abspath ./csrc) -name "*.cpp")
VSRC +=  $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
TOP_MODULE := top
SEARCHPATH := $(NPC_HOME)/vsrc

# 2.verilator flags:
VERILATOR_FLAGS += -I${SEARCHPATH}
VERILATOR_FLAGS += --top ${TOP_MODULE}
VERILATOR_FLAGS += --trace-fst --cc --exe --build --threads 2 -j 8
VERILATOR_FLAGS += -Wno-fatal		# only print lint warning, but not terminate compile.
VERILATOR_FLAGS += -Wno-UNUSED 		# close <unused> warning.
INC_PATH   		?= $(NPC_HOME)/csrc/include
CFLAGS			+= -g -I${INC_PATH}#								# -g for gdb
LDFLAGS			+= -ldl -lSDL2# 									# -ldl for dynamic link(nemu difftest).

# 3.run info: 
LOG ?= $(NPC_HOME)/obj_dir/log.txt
IMG ?= ../am-kernels/tests/cpu-tests/build/dummy-riscv64-npc.bin#	# program img, run on npc.
DIFFTEST := ${NEMU_HOME}/build/riscv64-nemu-interpreter-so#			# nemu img, use for difftest.
OBJ_DIR := ./obj_dir# 												# npc obj path.
BIN := ${OBJ_DIR}/V${TOP_MODULE}#									# npc obj bin.
RUN_FLAGS := --img=${IMG} --diff=${DIFFTEST} --log=${LOG}#			# npc main args.
NPC_EXEC := ${BIN} ${RUN_FLAGS}#									# npc bin + args.

.PHONY:run gdb wave clean

com:${CSRC} ${VSRC}
	@verilator ${VERILATOR_FLAGS} ${CSRC} ${VSRC} $(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS))

run:com
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@${NPC_EXEC}

gdb:com ${DIFFTEST}
	$(call git_commit, "gdb RTL") # DO NOT REMOVE THIS LINE!!!
	@gdb --silent -s ${BIN} --args ${NPC_EXEC}

wave:
	@gtkwave ${OBJ_DIR}/sim.fst

clean:
	rm -rf ${OBJ_DIR}

include ../Makefile
