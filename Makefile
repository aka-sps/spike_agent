.PHONY: all rebuild run brun clean
all: ./simv spike_client
rebuild:clean all
brun: rebuild

./simv: spike_agent.sv spike_tb.sv axi_mem.sv spike_agent.o spike_vcs_TL.o spike_vcs_TL_server.o
	vcs -full64 -timescale=1ns/100ps -debug_all -sverilog -l comp.log $^

files-to-clean+=./simv vc_hdrs.h comp.log
dirs-to-clean +=simv.daidir csrc

spike_client: spike_client.o spike_vcs_TL.o spike_vcs_TL_client.o
	$(CXX) -std=c++11 -I$(SYNOPSYS)/vcsmx_vJ-2014.12-SP3/include $+ -o $@
files-to-clean+=spike_client

c++--objs := \
	spike_client.o \
	spike_agent.o \
	spike_vcs_TL.o \
	spike_vcs_TL_server.o \
	spike_vcs_TL_client.o \

files-to-clean += $(c++--objs)
$(c++--objs): %.o:%.cxx
	$(CXX) -std=c++11 -I$(SYNOPSYS)/vcsmx_vJ-2014.12-SP3/include -c $< -o $@

spike_agent.o spike_client.o spike_vcs_TL.o spike_vcs_TL_server.o spike_vcs_TL_client.o: spike_vcs_TL.hxx
spike_agent.o:spike_agent.hxx spike_vcs_TL.hxx

run:./simv
	./simv 

clean:
	$(RM) -r $(dirs-to-clean)
	$(RM) -r $(files-to-clean)
