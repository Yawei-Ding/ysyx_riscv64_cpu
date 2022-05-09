codec = csrc/sim_main.cpp
codev = vsrc/top.v

.PHONY:sim wave

com:${codec} ${codev}
	verilator -Wall --trace --cc --exe --build ${codec} ${codev}

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	obj_dir/Vtop
	
wave:
	gtkwave dump.vcd

clean:
	rm -rf obj_dir
	rm dump.vcd

all:
	com sim wave

include ../Makefile

