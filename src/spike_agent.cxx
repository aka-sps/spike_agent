#include "spike_vcs_TL/spike_agent.hxx"
#include "spike_vcs_TL/spike_vcs_TL.hxx"

#include <stdexcept>

#include <string>
#include <cstdio>
#include <vector>
#include <iostream>
#include <iomanip>
#include <cstdint>

using spike_vcs_TL::Server;
using spike_vcs_TL::Request_type;

/// Send of 0 enables spike execution, send 1 stop spike execution
/// No return until connect to spike
void
spikeSetReset(int active)
{
    uint32_t const data = active;
    LOGGER << "event @ reset: " << data << std::endl;
    auto& serv = Server::instance();
    do {
        // LOGGER << "get_next_request" << std::endl;
    } while (!serv.get_next_request());
    serv.ack(Request_type::reset_state, data);
    serv.send_ack();
    LOGGER << "reset done: " << data << std::endl;
}

/// Need call each clock
/// \return 0 - no transaction in this clock, 1 - read transaction, 2 - write transaction
int
spikeClock(void)
{
    // LOGGER << "event @ clk" << std::endl;
    auto& serv = Server::instance();
    auto const p_req = serv.get_next_request();
    // LOGGER << *p_req << std::endl;
    switch (p_req->m_cmd) {
        case Request_type::read:
            return 1;
        case Request_type::write:
            serv.ack();
            return 2;
        case Request_type::reset_state:
            serv.ack(Request_type::reset_state, 0);
            return 0;
        default:
            serv.ack();
            return 0;
    }
}

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction address
int
spikeGetAddress(void)
{
    auto& serv = Server::instance();
    auto const p_req = serv.get_last_request();
    // LOGGER << "spikeGetAddress: " << std::hex << p_req->m_address << std::dec << std::endl;
    return p_req->m_address;
}

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction size
int
spikeGetSize(void)
{
    auto& serv = Server::instance();
    auto const p_req = serv.get_last_request();
    // LOGGER << "spikeGetSize: " << int(p_req->m_size) << std::endl;
    return p_req->m_size;
}

/// If spikeClock() != 2 then there is write transaction from spike to vcs
/// \return data to write
int
spikeGetData(void)
{
    auto& serv = Server::instance();
    auto const p_req = serv.get_last_request();
    // LOGGER << "spikeGetData: " << std::hex << p_req->m_data << std::dec << std::endl;
    return p_req->m_data;
}

/// If spikeClock() != 1 then there is read transaction from spike to vcs
/// \param data read data
void spikeSetData(int data)
{
    auto& serv = Server::instance();
    // LOGGER << "spikeSetData: " << std::hex << data << std::dec << std::endl;
    serv.ack(data);
}

/// Each clock with or without transaction should be finished with call of this function
void spikeEndClock(void)
{
    auto& serv = Server::instance();
    // LOGGER << "spikeEndClock" << std::endl;
    serv.send_ack();
}
