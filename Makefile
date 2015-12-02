.PHONY: all
all:	clean comp run

.PHONY: comp
comp: ./simv

./simv: spike_agent.sv spike_tb.sv axi_mem.sv spike_agent.o
	vcs -full64 -timescale=1ns/100ps -debug_all -sverilog -l comp.log $^

spike_agent.o:spike_agent.hxx Makefile

spike_agent.o: %.o:%.cxx
	$(CXX) -std=c++11 -I$(SYNOPSYS)/vcsmx_vJ-2014.12-SP3/include -c $< -o $@

.PHONY: run
run:./simv
	./simv 

.PHONY: clean
clean:
	$(RM) -r simv* csrc* vc_hdrs.h *.log spike_agent.o
