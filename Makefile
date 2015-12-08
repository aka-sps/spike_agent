RANLIB:=ranlib

.PHONY: all rebuild run brun clean
all: ./simv spike_client_test spike_agent_test
rebuild:clean all
brun: rebuild
vpath %.cxx src
vpath %.hxx include

./simv: spike_agent.sv spike_tb.sv axi_mem.sv spike_vcs_TL.a
	vcs -full64 -timescale=1ns/100ps -debug_all -sverilog -l comp.log $^

files-to-clean+=./simv vc_hdrs.h comp.log
dirs-to-clean +=simv.daidir csrc

spike_client_test--objs := spike_client.o 
spike_client_test: $(spike_client_test--objs)
	$(CXX) $^ spike_vcs_TL.a  -o $@
files-to-clean += spike_client_test

spike_agent_test--objs := spike_agent_test.o 
spike_agent_test: $(spike_agent_test--objs)
	$(CXX) $^ spike_vcs_TL.a -o $@
files-to-clean += spike_agent_test

spike_vcs_TL--objs := spike_agent.o spike_vcs_TL.o spike_vcs_TL_server.o spike_vcs_TL.o spike_vcs_TL_client.o
spike_vcs_TL.a: spike_vcs_TL.a($(spike_vcs_TL--objs))
	$(RANLIB) $@
files-to-clean += spike_vcs.a

spike_vcs_TL.a(%):%
	$(AR) r $@ $<

c++--objs := $(sort $(simv--objs) $(spike_client_test--objs) $(spike_agent_test--objs) $(spike_vcs_TL--objs))
$(c++--objs): %.o:%.cxx
	$(CXX) -std=c++11 -I$(SYNOPSYS)/vcsmx_vJ-2014.12-SP3/include -Iinclude -c $< -o $@
files-to-clean += $(c++--objs)

spike_agent.o spike_client.o spike_vcs_TL.o spike_vcs_TL_server.o spike_vcs_TL_client.o: spike_vcs_TL/spike_vcs_TL.hxx
spike_client.o spike_agent.o: spike_vcs_TL/spike_agent.hxx

run:./simv
	./simv 

clean:
	$(RM) -r $(dirs-to-clean)
	$(RM) -r $(files-to-clean)
