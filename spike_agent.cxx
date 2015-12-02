#include "spike_agent.hxx"

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/unistd.h>
#include <netinet/in.h>

#include <stdexcept>

#include <string>
#include <cassert>
#include <cstdio>
#include <memory>
#include <vector>
#include <iostream>
#include <iomanip>

#define LOGGER std::cerr << __FILE__ << "(" << __LINE__ << "): "
namespace {
enum class Request_type : uint8_t
{
    skip = 0,
    read = 1,
    write = 2,
    reset = 3,
};

struct Request
{
    Request() = default;
    Request(uint8_t _sn,
            Request_type _cmd,
            uint32_t _address = 0,
            uint8_t _size = 0,
            uint32_t _data = 0)
            : m_sn(_sn)
            , m_cmd(_cmd)
            , m_address(_address)
            , m_size(_size)
            , m_data(_data) {}

    static std::shared_ptr<Request const>
        deserialize(std::vector<uint8_t> const& a_buf) {
        typedef std::shared_ptr<Request const> res_type;
        if (a_buf.size() < 2) {
            LOGGER << "a_buf.size() < 2 (" << a_buf.size() << ")" << std::endl;
            return res_type();
        }
        uint8_t const sn = a_buf[0];
        if (a_buf[1] > static_cast<uint8_t>(Request_type::reset)) {
            LOGGER << "a_buf[1] > static_cast<uint8_t>(Request_type::reset) (" << a_buf[1] << ")" << std::endl;
            return res_type();
        }
        Request_type const cmd = static_cast<Request_type>(a_buf[1]);
        switch (cmd) {
            case Request_type::read:
            case Request_type::write:
                {
                    size_t const size = a_buf[2];
                    if (!(size == 1 || size == 2 || size == 4)) {
                        LOGGER << "Bad size: " << unsigned(size) << std::endl;
                        return res_type();
                    }
                    uint32_t const address = (((((a_buf[4] << 8) | a_buf[5]) << 8) | a_buf[6]) << 8) | a_buf[7];
                    if (address & (size - 1) != 0) {
                        LOGGER << "address & (size - 1) != 0 (address=" << address << ", size=" << size << ")" << std::endl;
                        return res_type();
                    }
                    if (cmd == Request_type::write) {
                        uint32_t const data = (((((a_buf[8] << 8) | a_buf[9]) << 8) | a_buf[10]) << 8) | a_buf[11];
                        return res_type(new Request(sn, cmd, address, size, data));
                    } else {
                        return res_type(new Request(sn, cmd, address, size));
                    }
                }
                break;
            default:
                return res_type(new Request(sn, cmd));
        }
    }

    uint8_t m_sn;
    Request_type m_cmd;
    uint32_t m_address;
    uint8_t m_size;
    uint32_t m_data;

    friend std::ostream&
        operator << (std::ostream& a_ostr, Request const& a_req) {
        a_ostr <<
            "Request" <<
            " sn = " << std::dec << unsigned(a_req.m_sn) <<
            " cmd = " << unsigned(a_req.m_cmd);
        if (a_req.m_cmd == Request_type::read || a_req.m_cmd == Request_type::write) {
            a_ostr <<
                " address = " << std::hex << a_req.m_address << std::dec <<
                " size = " << unsigned(a_req.m_size);
            if (a_req.m_cmd == Request_type::write) {
                a_ostr <<
                    " data = " << std::hex << unsigned(a_req.m_data) << std::dec;
            }
        }
        return a_ostr;
    }
};

struct ACK
{
    ACK() = default;
    ACK(uint8_t a_sn, Request_type a_cmd, uint32_t a_data = 0)
        : m_sn(a_sn)
        , m_cmd(a_cmd)
        , m_data(a_data) {}
    ACK(Request const& _req)
        : m_sn(_req.m_sn)
        , m_cmd(_req.m_cmd) {}

    std::vector<uint8_t> serialize()const {
        typedef std::vector<uint8_t> res_type;
        res_type res;
        res.reserve(8);
        res.push_back(m_sn);
        res.push_back(static_cast<uint8_t>(m_cmd));
        switch (this->m_cmd) {
            case Request_type::read:
            case Request_type::reset:
                {
                    res.resize(8);
                    res[4] = static_cast<uint8_t>(this->m_data >> (8 * 3));
                    res[5] = static_cast<uint8_t>(this->m_data >> (8 * 2));
                    res[6] = static_cast<uint8_t>(this->m_data >> (8 * 1));
                    res[7] = static_cast<uint8_t>(this->m_data >> (8 * 0));
                }
            default:
                break;
        }
        return res;
    }
    uint8_t m_sn;
    Request_type m_cmd;
    uint32_t m_data;

    friend std::ostream&
        operator << (std::ostream& a_ostr, ACK const& a_req) {
        a_ostr <<
            "ACK" <<
            " sn = " << std::dec << unsigned(a_req.m_sn) <<
            " cmd = " << unsigned(a_req.m_cmd);
        if (a_req.m_cmd == Request_type::read || a_req.m_cmd == Request_type::reset) {
            a_ostr
                << " data = " << std::hex << unsigned(a_req.m_data) << std::dec;
        }
        return a_ostr;
    }
};

class Server
{
    class Socket
    {
    public:
        Socket(uint16_t a_port = 5000)
            : m_socket(::socket(AF_INET, SOCK_DGRAM, 0)) {
            struct sockaddr_in saddr;
            saddr.sin_family = AF_INET;
            saddr.sin_addr.s_addr = INADDR_ANY;
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
    std::shared_ptr<Request const>
        get_next_request() {
        for (;;) {
            std::shared_ptr<Request const> const p_req = Request::deserialize(this->m_socket.recv());
            if (!p_req) {
                LOGGER << "Bad Request" << std::endl;
                continue;
            }
            // LOGGER << "Receive " << *p_req << std::endl;
            if (get_last_request() && p_req->m_sn == get_last_request()->m_sn) {
                LOGGER << "Resend ACK" << std::endl;
                this->m_socket.send(m_p_ack->serialize());
            } else {
                this->m_p_req = p_req;
                break;
            }
        }
        return get_last_request();
    }
    void
        ack(Request_type const a_cmd, uint32_t a_data = 0) {
        typedef std::shared_ptr<ACK> res_type;
        this->m_p_ack = res_type(new ACK(this->get_last_request()->m_sn, a_cmd, a_data));
    }
    void
        ack(uint32_t a_data = 0) {
        typedef std::shared_ptr<ACK> res_type;
        this->m_p_ack = res_type(new ACK(this->get_last_request()->m_sn, this->get_last_request()->m_cmd, a_data));
    }
    void
        send_ack()const {
        LOGGER << *m_p_ack << std::endl;
        this->m_socket.send(m_p_ack->serialize());
    }
private:
    Server() {}

    Socket m_socket;
    std::shared_ptr<Request const> m_p_req;
    std::shared_ptr<ACK> m_p_ack;
};

Server& Server::instance() {
    static Server _instance;
    return _instance;
}
}

/// Send of 0 enables spike execution, send 1 stop spike execution
/// No return until connect to spike
void spikeSetReset(svLogicVec32 active) {
    if (bool(active.d))
        return;
    LOGGER << "event @ reset: " << bool(active.d) << std::endl;
    auto& serv = Server::instance();
    do {
    } while (serv.get_next_request()->m_cmd != Request_type::reset);
    serv.ack(0);
    serv.send_ack();
}

/// Need call each clock
/// \return 0 - no transaction in this clock, 1 - read transaction, 2 - write transaction
int
spikeClock(void) {
    LOGGER << "event @ clk" << std::endl;
    auto& serv = Server::instance();
    auto const p_req = serv.get_next_request();
    LOGGER << *p_req << std::endl;
    switch (p_req->m_cmd) {
        case Request_type::read:
            return 1;
        case Request_type::write:
            serv.ack();
            return 2;
        case Request_type::reset:
            serv.ack(Request_type::reset, 0);
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
    LOGGER << "spikeGetAddress: " << int(p_req->m_address) << std::endl;
    return p_req->m_address;
}

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction size
int
spikeGetSize(void) {
    auto& serv = Server::instance();
    auto const p_req = serv.get_last_request();
    LOGGER << "spikeGetSize: " << int(p_req->m_size) << std::endl;
    return p_req->m_size;
}

/// If spikeClock() != 2 then there is write transaction from spike to vcs
/// \return data to write
int
spikeGetData(void) {
    auto& serv = Server::instance();
    auto const p_req = serv.get_last_request();
    LOGGER << "spikeGetData: " << int(p_req->m_data) << std::endl;
    return p_req->m_data;
}

/// If spikeClock() != 1 then there is read transaction from spike to vcs
/// \param data read data
void spikeSetData(int data) {
    auto& serv = Server::instance();
    LOGGER << "spikeSetData: " << data << std::endl;
    serv.ack(data);
}

/// Each clock with or without transaction should be finished with call of this function
void spikeEndClock(void) {
    auto& serv = Server::instance();
    LOGGER << "spikeEndClock" << std::endl;
    serv.send_ack();
}
