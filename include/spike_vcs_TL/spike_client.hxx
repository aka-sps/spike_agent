#ifndef SPIKE_CLIENT_HXX_
#define SPIKE_CLIENT_HXX_

#include "spike_vcs_TL.hxx"
#include "udp_socket.hxx"
#include <cstdint>

namespace spike_vcs_TL {
class Client {
    class Socket:public UDP_Socket
    {
    public:
        Socket(uint16_t a_port);

        std::shared_ptr<std::vector<uint8_t> >
            recv(size_t const a_len = 1024);

        void
            send(std::vector<uint8_t> const& buf)const;

    private:
        struct sockaddr_in m_saddr;
    };

    Client(Client const&) = delete;
    Client& operator = (Client const&) = delete;
    Client(uint16_t a_port = 5000);

public:
    static Client& instance();
    std::shared_ptr<ACK const>
        request(Request_type a_cmd, uint32_t a_address = 0, uint8_t a_size = 0, uint32_t a_data = 0);

    Socket m_socket;
    uint8_t m_sn;
    std::shared_ptr<Request const> m_p_req;
};
}  // namespace spike_vcs_TL
#endif  // SPIKE_CLIENT_HXX_
