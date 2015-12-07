#ifndef SPIKE_SERVER_HXX_
#define SPIKE_SERVER_HXX_
#include "spike_vcs_TL/udp_socket.hxx"
#include "spike_vcs_TL/spike_vcs_TL.hxx"

namespace spike_vcs_TL {
class Server
{
    class Socket :public UDP_Socket
    {
    public:
        Socket(uint16_t a_port);
    };

public:
    static Server& instance();
    std::shared_ptr<Request const>
        get_last_request()const
    {
        return m_p_req;
    }
    void
        send_ack()const;
    std::shared_ptr<Request const>
        get_next_request();
    void
        ack(Request_type const a_cmd, uint32_t a_data = 0);
    void
        ack(uint32_t a_data = 0);
private:
    Server(uint16_t a_port = 5000);

    Socket m_socket;
    struct sockaddr_in m_saddr;
    socklen_t m_addrlen;
    std::shared_ptr<Request const> m_p_req;
    std::shared_ptr<ACK const> m_p_ack;
};

}  // spike_vcs_TL

#endif  // SPIKE_SERVER_HXX_
