VSRC_HOME = $(NPC_HOME)/vsrc
CSRC_HOME = $(NPC_HOME)/csrc
INCLUDE_PATH = $(VSRC_HOME)/lib

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
CSRC += ${CSRC_HOME}/main.cpp