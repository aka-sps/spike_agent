.PHONY: all
all:	clean comp run

.PHONY: comp
comp: ./simv

./simv: spike_agent.sv spike_tb.sv axi_mem.sv spike_agent.o
	vcs -full64 -timescale=1ns/100ps -debug_all -sverilog -l comp.log $^

files-to-clean+=./simv vc_hdrs.h comp.log
dirs-to-clean +=simv.daidir csrc

spike_agent.o:spike_agent.hxx Makefile
files-to-clean+=spike_agent.o

spike_agent.o: %.o:%.cxx
	$(CXX) -std=c++11 -I$(SYNOPSYS)/vcsmx_vJ-2014.12-SP3/include -c $< -o $@

.PHONY: run
run:./simv
	./simv 

.PHONY: clean
clean:
	$(RM) -r $(dirs-to-clean)
	$(RM) -r $(files-to-clean)
