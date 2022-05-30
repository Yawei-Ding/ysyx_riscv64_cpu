CSRC_HOME = $(NPC_HOME)/csrc
VSRC_HOME = $(NPC_HOME)/vsrc
DIFFTEST = ${NEMU_HOME}/build/riscv64-nemu-interpreter-so

VSRC += ${VSRC_HOME}/lib/define.sv
VSRC += ${VSRC_HOME}/lib/rst.sv
VSRC += ${VSRC_HOME}/lib/regfile.sv
VSRC += ${VSRC_HOME}/idu.sv
VSRC += ${VSRC_HOME}/pcu.sv
VSRC += ${VSRC_HOME}/exu/alu.sv
VSRC += ${VSRC_HOME}/exu/exu.sv
VSRC += ${VSRC_HOME}/lsu.sv
VSRC += ${VSRC_HOME}/wbu.sv
VSRC += ${VSRC_HOME}/top.sv

CSRC += ${CSRC_HOME}/mem.cpp
CSRC += ${CSRC_HOME}/init.cpp
CSRC += ${CSRC_HOME}/dpic.cpp
CSRC += ${CSRC_HOME}/difftest.cpp
CSRC += ${CSRC_HOME}/main.cpp