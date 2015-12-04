#include <memory>
#include <cstdint>
#include <random>
#include <iostream>
#include <iomanip>

#include <sys/socket.h>
#include <sys/unistd.h>
#include <netinet/in.h>
#include <sys/select.h>
#include <sys/types.h>

namespace {
enum class Request_type : uint8_t
{
    skip = 0,
    read = 1,
    write = 2,
    get_reset_state = 3,
};

class Request
{
    Request(Request const&) = delete;
    Request const& operator = (Request const&) = delete;

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
public:
    static std::shared_ptr<Request const>
        create(uint8_t _sn,
        Request_type _cmd,
        uint32_t _address = 0,
        uint8_t _size = 0,
        uint32_t _data = 0);
    std::vector<uint8_t>
        serialize()const;

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

class ACK
{
    ACK(){}
    ACK(ACK const&) = delete;
    ACK operator = (ACK const&) = delete;
public:
    static std::shared_ptr<ACK const>
        deserialize(std::vector<uint8_t> const&);

    uint8_t m_sn;
    Request_type m_cmd;
    uint32_t m_data;
};

class Client
{
    class Socket
    {
    public:
        Socket(uint16_t a_port = 5000)
            : m_socket(::socket(AF_INET, SOCK_DGRAM, 0)) {
            m_saddr.sin_family = AF_INET;
            m_saddr.sin_addr.s_addr = INADDR_LOOPBACK;
            m_saddr.sin_port = ::htons(a_port);
        }

        ~Socket() {
            ::close(this->m_socket);
        }
        std::shared_ptr<std::vector<uint8_t> >
            recv(size_t const a_len = 1024) {
            fd_set wset;
            FD_ZERO(&wset);

            fd_set rset;
            FD_ZERO(&rset);
            FD_SET(this->m_socket, &rset);

            fd_set eset = rset;
            timeval timeout = {1, 0};
            int const ready = ::select(this->m_socket, &rset, &wset, &eset, &timeout);
            typedef std::shared_ptr<std::vector<uint8_t> > result_type;
            if (ready != 1 || !FD_ISSET(this->m_socket, &rset)) {
                return result_type();
            }
            result_type res(new std::vector<uint8_t>(a_len));
            std::vector<uint8_t>& buf = *res;
            // LOGGER << "recvfrom..." << std::endl;
            ssize_t const size = ::recvfrom(this->m_socket + 1, &buf[0], buf.size(), 0, nullptr, 0);
            // LOGGER << "...recvfrom receive " << size << " bytes" << std::endl;
            if (size < 0) {
                return result_type();
            }
            buf.resize(size);
            return res;
        }

        void
            send(std::vector<uint8_t> const& buf)const {
            do {
            } while (::sendto(this->m_socket, &buf[0], buf.size(), 0, reinterpret_cast<struct sockaddr const*>(&this->m_saddr), sizeof this->m_saddr) != buf.size());
        }

    private:
        int m_socket;
        socklen_t m_addrlen;
        struct sockaddr_in m_saddr;
    };

    Client(Client const&) = delete;
    Client& operator = (Client const&) = delete;
    Client(uint16_t a_port = 5000)
        : m_socket(a_port)
        , m_sn(0) {}

public:
    static Client& instance();
    std::shared_ptr<ACK const>
        request(Request_type a_cmd, uint32_t a_address = 0, uint8_t a_size = 0, uint32_t a_data = 0) {
        this->m_sn = (this->m_sn + 1) % 256;
        this->m_p_req = Request::create(this->m_sn, a_cmd, a_address, a_size, a_data);
        for (;;) {
            this->m_socket.send(this->m_p_req->serialize());
            auto const pkt = this->m_socket.recv();
            if (!pkt) {
                continue;
            }
            auto const ack = ACK::deserialize(*pkt);
            if (ack && ack->m_sn == this->m_sn) {
                return ack;
            }
        }
    }

    Socket m_socket;
    uint8_t m_sn;
    std::shared_ptr<Request const> m_p_req;
};
Client& Client::instance() {
    static Client _instance;
    return _instance;
}

void
wait_reset_inactive() {
    for (;;) {
        auto const ack = Client::instance().request(Request_type::get_reset_state);
        if (ack && ack->m_cmd == Request_type::get_reset_state && ack->m_data == 0) {
            break;
        }
    }
}
static uint32_t const base = 0xFEED0000u;
static uint32_t const limit_bytes = 1u << 12;
std::default_random_engine generator;

std::shared_ptr<ACK const>
random_transaction() {
    std::discrete_distribution<uint8_t> transactions_kind_distribution{0.50, 0.25, 0.25};
    uint8_t const transactions_kind = transactions_kind_distribution(generator);
    switch (transactions_kind) {
        // read or write
        case 1:
        case 2:
            {
                std::discrete_distribution<uint8_t> transactions_size_distribution{0.30, 0.20, 0.50};
                uint8_t const log2_byte_size = transactions_size_distribution(generator);
                uint8_t const size_bytes = 1u << log2_byte_size;
                uint32_t const num_cells = limit_bytes / size_bytes;
                std::uniform_int_distribution<uint32_t> offset_distribution(0, num_cells - 1);
                uint32_t const offset = offset_distribution(generator) * size_bytes;
                if (transactions_kind == 1) {
                    return Client::instance().request(Request_type::read, base + offset, size_bytes);
                } else {
                    uint8_t const size_bits = 8 * size_bytes;
                    std::uniform_int_distribution<uint32_t> offset_distribution(0, (1u << size_bits) - 1);
                    uint32_t const data = offset_distribution(generator);
                    uint32_t repeated_data = data;
                    for (int i = 1; i < (4 / size_bytes); ++i) {
                        repeated_data = (repeated_data << size_bits) | data;
                    }
                    return Client::instance().request(Request_type::write, base + offset, size_bytes, repeated_data);
                }
            }
            break;
        default:
            return Client::instance().request(Request_type::skip);
    }
}

}  // namespace

int main(int, char*[]) {
    wait_reset_inactive();
    for (;;) {
        auto const ack = random_transaction();
        if (ack && ack->m_cmd == Request_type::get_reset_state && ack->m_data != 0) {
            break;
        }
    }
    return 0;
}