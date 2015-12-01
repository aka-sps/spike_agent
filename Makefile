
all:	clean comp run
clean:
	\rm -rf simv* csrc* vc_hdrs.h *.log
comp:
	vcs -full64 -timescale=1ns/100ps spike_agent.sv spike_tb.sv axi_mem.sv spike_agent.cxx -debug_all -sverilog -l comp.log
run:
	./simv 
