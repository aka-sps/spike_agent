
all:	clean comp run
clean:
	\rm -rf simv* csrc* vc_hdrs.h *.log
comp:
	vcs -full64 -timescale=1ns/1ns spike_agent.sv spike_agent.cxx -debug_all -sverilog -l comp.log
run:
	./simv 
