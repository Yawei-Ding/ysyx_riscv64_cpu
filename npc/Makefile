include $(NPC_HOME)/filelist.mk

.PHONY:sim wave clean

com:${CSRC} ${VSRC}
	echo ${INCLUDE_PATH} 
	verilator -Wall --trace --cc --exe --build ${CSRC} ${VSRC} --top top -LDFLAGS -ldl

sim:com
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	obj_dir/Vtop --img=${IMG} --diff=${DIFFTEST}

wave:
	gtkwave dump.vcd

clean:
	rm -rf obj_dir
	rm dump.vcd

include ../Makefile
