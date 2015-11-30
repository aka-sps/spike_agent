/// Send of 0 enables spike execution, send 1 stop spike execution
/// No return until connect to spike
import "DPI-C" function void spikeSetReset(logic a);

/// Need call each clock 
/// \return 0 - no transaction in this clock, 1 - read transaction, 2 - write transaction 
import "DPI-C" context function int spikeClock();

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction address
import "DPI-C" context function longint spikeGetAddress();

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction size
import "DPI-C" context function int spikeGetSize();

/// If spikeClock() != 2 then there is write transaction from spike to vcs
/// \return data to write
import "DPI-C" context function longint spikeGetData();

/// If spikeClock() != 1 then there is read transaction from spike to vcs
/// \param data read data
import "DPI-C" context function void spikeSetData(longint data);

/// Each clock with or without transaction should be finished with call of this function
import "DPI-C" context function void spikeEndClock();
