# spike_agent
Co-simulation of HW vcs simulation and SW spike RISC-V code simulation.

# Prerequisites
## riscv32i toolset
**Note:** spike should be made in `vcs` branch of `riscv-tools`.

```sh
export PATH=$PATH:~/riscv32i/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/riscv32i/lib
```
## vcs
## This repo

# Usage case
## Full simulation
```sh
make rebuild
./simv &
spike -m1024 --isa=RV32IMAFD <your RISC-V executable>
```

##  Simulation w/o spike
```sh
make rebuild
./simv &
spike_client_test
```

##  Simulation w/o vcs
```sh
make rebuild
spike_agent_test &
spike -m1024 --isa=RV32IMAFD <your RISC-V executable>
```

See example of RISC-V application in ricv-tests/benchmarks/vcsrnd

# Makefile goals
## all
Build simv, spike_client_test, spike_agent_test
## clean
Standard clean
## rebuld
Clean and build all

## simv
Agent/server: VCS simulator of external memory with spike communication agent.
Simulate external memory at address 0xFEED0000 with size 2^12 bytes.

## spike_agent_test
Agent/server: c++ simulator of external memory with spike communication agent.
Performs role of vcs model (simv) in vcs/spike communication.
Simulate external memory at address 0xFEED0000 with size 2^12 bytes. Check transaction size and address alignment.

## spike_client_test
Client: Performs role of spike application in vcs/spike communication.
Performs random read/write/clock transactions to external memory.

## spike_vcs_TL.so
Shared object of network communication protocol between vcs model and spike.
Set shared objects search path using LD_LIBRARY_PATH environment variable.
