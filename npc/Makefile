csrc = csrc/*.cpp 
vsrc = vsrc/*.sv vsrc/lib/*.sv 

.PHONY:sim wave clean

com:${csrc} ${vsrc}
	verilator --trace --cc --exe --build ${csrc} ${vsrc} --top top #-Wall 

sim:com
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	obj_dir/Vtop

wave:com sim
	gtkwave dump.vcd

clean:
	rm -rf obj_dir
	rm dump.vcd

include ../Makefile
