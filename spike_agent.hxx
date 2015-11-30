#ifndef SPIKE_AGENT_HXX__
#define SPIKE_AGENT_HXX__

#include <svdpi.h>
#ifdef __cplusplus
extern "C" {
#endif

/// Send of 0 enables spike execution, send 1 stop spike execution
/// No return until connect to spike
void spikeSetReset(logic a);

/// Need call each clock 
/// \return 0 - no transaction in this clock, 1 - read transaction, 2 - write transaction 
int spikeClock(void);

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction address
int spikeGetAddress(void);

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction size
int spikeGetSize(void);

/// If spikeClock() != 2 then there is write transaction from spike to vcs
/// \return data to write
int spikeGetData(void);

/// If spikeClock() != 1 then there is read transaction from spike to vcs
/// \param data read data
void spikeSetData(int data);

/// Each clock with or without transaction should be finished with call of this function
void spikeEndClock(void);

#ifdef __cplusplus
}
#endif

#endif  // SPIKE_AGENT_HXX__
