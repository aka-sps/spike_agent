#include "spike_vcs_TL/spike_server.hxx"

namespace spike_vcs_TL {
Server::Socket::Socket(uint16_t a_port)
{
    struct sockaddr_in saddr;
    saddr.sin_family = AF_INET;
    saddr.sin_addr.s_addr = ::htonl(INADDR_ANY);
    saddr.sin_port = ::htons(a_port);
    if (::bind(this->m_socket, reinterpret_cast<struct sockaddr*>(&saddr), sizeof saddr) < 0)
        throw std::runtime_error("could not bind to port " + std::to_string(a_port));
}


Server::Server(uint16_t a_port /*= 5000*/) :m_socket(a_port)
{

}

Server&
Server::instance()
{
    static Server _instance;
    return _instance;
}

void Server::send_ack() const
{
    // LOGGER << *m_p_ack << std::endl;
    this->m_socket.send(m_p_ack->serialize());
}

std::shared_ptr<Request const> Server::get_next_request()
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

void Server::ack(Request_type const a_cmd, uint32_t a_data /*= 0*/)
{
    this->m_p_ack = ACK::create(this->get_last_request()->m_sn, a_cmd, a_data);
}

void Server::ack(uint32_t a_data /*= 0*/)
{
    this->m_p_ack = ACK::create(this->get_last_request()->m_sn, this->get_last_request()->m_cmd, a_data);
}

}  // spike_vcs_TL
