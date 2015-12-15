###############################################
## Copyright 2015 Syntacore 
## See LICENSE for license details
###############################################
RANLIB:=ranlib

.PHONY: all rebuild run brun clean
all: ./simv spike_client_test spike_agent_test
tests: spike_client_test spike_agent_test
rebuild:clean all
vpath %.cxx src
vpath %.hxx include src

./simv: spike_agent.sv spike_tb.sv axi_mem.sv spike_vcs_TL.so
	vcs -full64 -timescale=1ns/100ps -debug_all -sverilog -l comp.log $^

files-to-clean+=./simv vc_hdrs.h comp.log
dirs-to-clean +=simv.daidir csrc

spike_client_test--objs := spike_client_test.o 
spike_client_test: $(spike_client_test--objs) spike_vcs_TL.so
	$(CXX) $^ -o $@
files-to-clean += spike_client_test

spike_agent_test--objs := spike_agent_test.o 
spike_agent_test: $(spike_agent_test--objs) spike_vcs_TL.so
	$(CXX) $^ -o $@
files-to-clean += spike_agent_test


spike_vcs_TL--objs := $(sort spike_agent.o spike_client.o spike_vcs_TL.o spike_vcs_TL_server.o spike_vcs_TL_client.o)
$(spike_vcs_TL--objs):CXXFLAGS+=-fPIC
spike_vcs_TL.so: $(sort $(spike_vcs_TL--objs))
	$(CXX) -shared $^ -o $@
files-to-clean += spike_vcs_TL.so

c++--objs := $(sort $(simv--objs) $(spike_client_test--objs) $(spike_agent_test--objs) $(spike_vcs_TL--objs))
$(c++--objs): %.o:%.cxx
	$(CXX) -std=c++11 $(CXXFLAGS) -Iinclude -c $< -o $@
files-to-clean += $(c++--objs)

$(spike_vcs_TL--objs): spike_vcs_TL.hxx
spike_agent_test.o spike_agent.o: spike_vcs_TL/spike_agent.hxx
spike_client_test.o spike_client.o: spike_vcs_TL/spike_client.hxx

run:./simv
	./simv 

clean:
	$(RM) -r $(dirs-to-clean)
	$(RM) $(files-to-clean)
