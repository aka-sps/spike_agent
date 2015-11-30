#include "spike_agent.hxx"

namespace {
	bool is_run = false;
	uint32_t tr_address;
	uint32_t tr_size;
	uint32_t tr_data;
	void simulate_write(){
		tr_address = 0xFEED0000;
		tr_size = 4;
		tr_data = 0xFEEDBEEF;
	}
	void simulate_read(){
		tr_address = 0xFEED0000;
		tr_size = 4;
	}
}

/// Send of 0 enables spike execution, send 1 stop spike execution
/// No return until connect to spike
void spikeSetReset(logic active){
	is_run = !active;
}

/// Need call each clock 
/// \return 0 - no transaction in this clock, 1 - read transaction, 2 - write transaction 
int spikeClock(void){
	if (!is_run) {
		return 0;
	}
	static unsigned cnt = 0;
	switch (cnt++ % 4) {
	case 2:
		simulate_write();
		return 2;
	case 3:
		simulate_read();
		return 1;
	default:
		return 0;
	}
}

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction address
int spikeGetAddress(void){
	return tr_address;
}

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction size
int spikeGetSize(void){
	return tr_size;
}

/// If spikeClock() != 2 then there is write transaction from spike to vcs
/// \return data to write
int spikeGetData(void){
	return tr_data;
}

/// If spikeClock() != 1 then there is read transaction from spike to vcs
/// \param data read data
void spikeSetData(int data){
	tr_data = data;
}

/// Each clock with or without transaction should be finished with call of this function
void spikeEndClock(void){
	
}
