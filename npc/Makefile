include $(NPC_HOME)/filelist.mk

.PHONY:sim wave clean

com:${CSRC} ${VSRC}
	echo ${INCLUDE_PATH} 
	verilator --trace --cc --exe --build ${CSRC} ${VSRC} -FI ${CSRC_HOME}/include/mem.h --top top #-Wall 

sim:com
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	obj_dir/Vtop ${IMG}

wave:com sim
	gtkwave dump.vcd

clean:
	rm -rf obj_dir
	rm dump.vcd

include ../Makefile
