#include "spike_vcs_TL/spike_agent.hxx"
#include "spike_vcs_TL/spike_vcs_TL.hxx"

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/unistd.h>
#include <netinet/in.h>

#include <stdexcept>

#include <string>
#include <cassert>
#include <cstdio>
#include <vector>
#include <iostream>
#include <iomanip>
#include <cstdint>

namespace {
using namespace spike_vcs_TL;
class Server
{
    class Socket
    {
    public:
        Socket(uint16_t a_port)
            : m_socket(::socket(AF_INET, SOCK_DGRAM, 0)) {
            struct sockaddr_in saddr;
            saddr.sin_family = AF_INET;
            saddr.sin_addr.s_addr = ::htonl(INADDR_ANY);
            saddr.sin_port = ::htons(a_port);
            if (::bind(this->m_socket, reinterpret_cast<struct sockaddr*>(&saddr), sizeof saddr) < 0)
                throw std::runtime_error("could not bind to port " + std::to_string(a_port));
        }

        ~Socket() {
            ::close(this->m_socket);
        }
        std::vector<uint8_t>
            recv(size_t const a_len = 1024) {
            struct sockaddr *src_addr = reinterpret_cast<struct sockaddr*>(&this->m_saddr);
            socklen_t* addrlen = &this->m_addrlen;
            for (;;) {
                std::vector<uint8_t> buf(a_len);
                this->m_addrlen = sizeof this->m_saddr;
                // LOGGER << "recvfrom..." << std::endl;
                ssize_t const size = ::recvfrom(this->m_socket, &buf[0], buf.size(), 0, src_addr, addrlen);
                if (size >= 0) {
                    buf.resize(size);
                    // LOGGER << "...recvfrom receive " << size << " bytes" << std::endl;
                    return buf;
                }
            }
        }

        void
            send(std::vector<uint8_t> const& buf)const {
            struct sockaddr const* dest_addr = reinterpret_cast<struct sockaddr const*>(&this->m_saddr);
            socklen_t addrlen = this->m_addrlen;
            do {
            } while (::sendto(this->m_socket, &buf[0], buf.size(), 0, dest_addr, addrlen) != buf.size());
        }

    private:
        int m_socket;
        struct sockaddr_in m_saddr;
        socklen_t m_addrlen;
    };

public:
    static Server& instance();
    std::shared_ptr<Request const>
        get_last_request()const {
        return m_p_req;
    }
    void
        send_ack()const {
        // LOGGER << *m_p_ack << std::endl;
        this->m_socket.send(m_p_ack->serialize());
    }
    std::shared_ptr<Request const>
        get_next_request() {
        for (;;) {
            std::shared_ptr<Request const> const p_req = Request::deserialize(this->m_socket.recv());
            if (!p_req) {
                LOGGER << "Bad Request" << std::endl;
            } else if (this->m_p_ack && this->m_p_ack->m_sn == p_req->m_sn) {
                LOGGER << "Resend ACK" << std::endl;
                send_ack();
            } else {
                this->m_p_req = p_req;
                this->m_p_ack.reset();
                // LOGGER << "Receive: " << *this->m_p_req << std::endl;
                break;
            }
        }
        return get_last_request();
    }
    void
        ack(Request_type const a_cmd, uint32_t a_data = 0) {
        this->m_p_ack = ACK::create(this->get_last_request()->m_sn, a_cmd, a_data);
    }
    void
        ack(uint32_t a_data = 0) {
        this->m_p_ack = ACK::create(this->get_last_request()->m_sn, this->get_last_request()->m_cmd, a_data);
    }
private:
    Server(uint16_t a_port = 5000) :m_socket(a_port){}

    Socket m_socket;
    std::shared_ptr<Request const> m_p_req;
    std::shared_ptr<ACK const> m_p_ack;
};

Server& Server::instance() {
    static Server _instance;
    return _instance;
}
}

/// Send of 0 enables spike execution, send 1 stop spike execution
/// No return until connect to spike
void spikeSetReset(int active) {
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
spikeClock(void) {
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
spikeGetAddress(void) {
    auto& serv = Server::instance();
    auto const p_req = serv.get_last_request();
    // LOGGER << "spikeGetAddress: " << std::hex << p_req->m_address << std::dec << std::endl;
    return p_req->m_address;
}

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction size
int
spikeGetSize(void) {
    auto& serv = Server::instance();
    auto const p_req = serv.get_last_request();
    // LOGGER << "spikeGetSize: " << int(p_req->m_size) << std::endl;
    return p_req->m_size;
}

/// If spikeClock() != 2 then there is write transaction from spike to vcs
/// \return data to write
int
spikeGetData(void) {
    auto& serv = Server::instance();
    auto const p_req = serv.get_last_request();
    // LOGGER << "spikeGetData: " << std::hex << p_req->m_data << std::dec << std::endl;
    return p_req->m_data;
}

/// If spikeClock() != 1 then there is read transaction from spike to vcs
/// \param data read data
void spikeSetData(int data) {
    auto& serv = Server::instance();
    // LOGGER << "spikeSetData: " << std::hex << data << std::dec << std::endl;
    serv.ack(data);
}

/// Each clock with or without transaction should be finished with call of this function
void spikeEndClock(void) {
    auto& serv = Server::instance();
    // LOGGER << "spikeEndClock" << std::endl;
    serv.send_ack();
}
