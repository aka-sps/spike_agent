#ifndef SPIKE_VCS_TL_HXX_
#define SPIKE_VCS_TL_HXX_

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/unistd.h>
#include <netinet/in.h>

#include <cstdint>
#include <memory>
#include <vector>
#include <iostream>
#include <iomanip>

#define LOGGER std::cerr << __FILE__ << "(" << __LINE__ << "): "

namespace spike_vcs_TL {
enum class Request_type : uint8_t
{
    skip = 0,
    read = 1,
    write = 2,
    reset_state = 3,
};

class Request
{
    Request(Request const&) = delete;
    Request const& operator = (Request const&) = delete;
    Request(uint8_t _sn,
            Request_type _cmd,
            uint32_t _address = 0,
            uint8_t _size = 0,
            uint32_t _data = 0);

public:
    static std::shared_ptr<Request const>
        create(uint8_t a_sn,
        Request_type a_cmd,
        uint32_t a_address = 0,
        uint8_t a_size = 0,
        uint32_t a_data = 0);
    static std::shared_ptr<Request const>
        deserialize(std::vector<uint8_t> const& a_buf);
    std::vector<uint8_t>
        serialize()const;

    uint8_t m_sn;
    Request_type m_cmd;
    uint32_t m_address;
    uint8_t m_size;
    uint32_t m_data;

    friend std::ostream&
        operator << (std::ostream& a_ostr, Request const& a_req);
};

class ACK
{
    ACK(ACK const&) = delete;
    ACK& operator = (ACK const&) = delete;
    ACK(uint8_t a_sn, Request_type a_cmd, uint32_t a_data = 0);

public:
    static std::shared_ptr<ACK const>
        create(uint8_t a_sn, Request_type a_cmd, uint32_t a_data = 0);

    static std::shared_ptr<ACK const>
        deserialize(std::vector<uint8_t> const& a_buf);

    std::vector<uint8_t> serialize()const;
    uint8_t m_sn;
    Request_type m_cmd;
    uint32_t m_data;
    friend std::ostream&
        operator << (std::ostream& a_ostr, ACK const& a_ack);
};

class Server
{
    class Socket
    {
    public:
        Socket(uint16_t a_port)
            : m_socket(::socket(AF_INET, SOCK_DGRAM, 0))
        {
            struct sockaddr_in saddr;
            saddr.sin_family = AF_INET;
            saddr.sin_addr.s_addr = ::htonl(INADDR_ANY);
            saddr.sin_port = ::htons(a_port);
            if (::bind(this->m_socket, reinterpret_cast<struct sockaddr*>(&saddr), sizeof saddr) < 0)
                throw std::runtime_error("could not bind to port " + std::to_string(a_port));
        }

        ~Socket()
        {
            ::close(this->m_socket);
        }
        std::vector<uint8_t>
            recv(size_t const a_len = 1024)
        {
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
            send(std::vector<uint8_t> const& buf)const
        {
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
        get_last_request()const
    {
        return m_p_req;
    }
    void
        send_ack()const
    {
        // LOGGER << *m_p_ack << std::endl;
        this->m_socket.send(m_p_ack->serialize());
    }
    std::shared_ptr<Request const>
        get_next_request()
    {
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
        ack(Request_type const a_cmd, uint32_t a_data = 0)
    {
        this->m_p_ack = ACK::create(this->get_last_request()->m_sn, a_cmd, a_data);
    }
    void
        ack(uint32_t a_data = 0)
    {
        this->m_p_ack = ACK::create(this->get_last_request()->m_sn, this->get_last_request()->m_cmd, a_data);
    }
private:
    Server(uint16_t a_port = 5000) :m_socket(a_port)
    {}

    Socket m_socket;
    std::shared_ptr<Request const> m_p_req;
    std::shared_ptr<ACK const> m_p_ack;
};

class Client
{
    class Socket
    {
    public:
        Socket(uint16_t a_port)
            : m_socket(::socket(AF_INET, SOCK_DGRAM, 0))
        {
            this->m_saddr.sin_family = AF_INET;
            this->m_saddr.sin_addr.s_addr = ::htonl(INADDR_LOOPBACK);
            this->m_saddr.sin_port = ::htons(a_port);
        }

        ~Socket()
        {
            ::close(this->m_socket);
        }
        std::shared_ptr<std::vector<uint8_t> >
            recv(size_t const a_len = 1024)
        {

            fd_set rset;
            FD_ZERO(&rset);
            FD_SET(this->m_socket, &rset);

            fd_set eset;
            FD_ZERO(&eset);
            FD_SET(this->m_socket, &eset);

            struct timeval tmot;
            tmot.tv_sec = 1;
            tmot.tv_usec = 0;

            // LOGGER << "Select..." << std::endl;
            int const ready = ::select(this->m_socket + 1, &rset, nullptr, &eset, &tmot);
            typedef std::shared_ptr<std::vector<uint8_t> > result_type;
            if (ready != 1 || !FD_ISSET(this->m_socket, &rset)) {
                LOGGER << "...no answer!" << ready << std::endl;
                return result_type();
            }
            result_type res(new std::vector<uint8_t>(a_len));
            std::vector<uint8_t>& buf = *res;
            // LOGGER << "recvfrom..." << std::endl;
            ssize_t const size = ::recvfrom(this->m_socket, &buf[0], buf.size(), 0, nullptr, 0);
            if (size < 0) {
                LOGGER << "...recvfrom failure: " << size << std::endl;
                return result_type();
            }
            buf.resize(size);
            return res;
        }

        void
            send(std::vector<uint8_t> const& buf)const
        {
            auto res = ::sendto(this->m_socket, &buf[0], buf.size(), 0, reinterpret_cast<struct sockaddr const*>(&this->m_saddr), sizeof this->m_saddr);
            if (res < 0) {
                LOGGER << "Error sendto: " << errno << std::endl;
            }
        }

    private:
        int m_socket;
        struct sockaddr_in m_saddr;
    };

    Client(Client const&) = delete;
    Client& operator = (Client const&) = delete;
    Client(uint16_t a_port = 5000)
        : m_socket(a_port)
        , m_sn(0)
    {}

public:
    static Client& instance();
    std::shared_ptr<ACK const>
        request(Request_type a_cmd, uint32_t a_address = 0, uint8_t a_size = 0, uint32_t a_data = 0)
    {
        this->m_sn = (this->m_sn + 1) % 256;
        this->m_p_req = Request::create(this->m_sn, a_cmd, a_address, a_size, a_data);
        for (;;) {
            this->m_socket.send(this->m_p_req->serialize());
            // LOGGER << "Try to recv..." << std::endl;
            auto const pkt = this->m_socket.recv();
            if (!pkt) {
                LOGGER << "No answer: " << *this->m_p_req << std::endl;
                continue;
            }
            auto const ack = ACK::deserialize(*pkt);
            if (ack && ack->m_sn == this->m_sn) {
                LOGGER << *this->m_p_req << " ==> " << *ack << std::endl;
                return ack;
            }
        }
    }

private:
    Socket m_socket;
    uint8_t m_sn;
    std::shared_ptr<Request const> m_p_req;
};
}  // namespace spike_vcs_TL

#endif  // SPIKE_VCS_TL_HXX_
