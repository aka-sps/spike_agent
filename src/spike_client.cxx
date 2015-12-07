#include "spike_vcs_TL/spike_client.hxx"

namespace spike_vcs_TL {
Client::Socket::Socket(uint16_t a_port)
{
    this->m_saddr.sin_family = AF_INET;
    this->m_saddr.sin_addr.s_addr = ::htonl(INADDR_LOOPBACK);
    this->m_saddr.sin_port = ::htons(a_port);
}

std::shared_ptr<std::vector<uint8_t> >
Client::Socket::recv(size_t const a_len /*= 1024*/)
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


void Client::Socket::send(std::vector<uint8_t> const& buf) const
{
    auto res = ::sendto(this->m_socket, &buf[0], buf.size(), 0, reinterpret_cast<struct sockaddr const*>(&this->m_saddr), sizeof this->m_saddr);
    if (res < 0) {
        LOGGER << "Error sendto: " << errno << std::endl;
    }
}

Client::Client(uint16_t a_port /*= 5000*/)
    : m_socket(a_port)
    , m_sn(0)
{}

Client& Client::instance()
{
    static Client _instance;
    return _instance;
}


std::shared_ptr<ACK const>
Client::request(Request_type a_cmd, uint32_t a_address /*= 0*/, uint8_t a_size /*= 0*/, uint32_t a_data /*= 0*/)
{
    this->m_sn = (this->m_sn + 1) % 256;
    this->m_p_req = Request::create(this->m_sn, a_cmd, a_address, a_size, a_data);
    for (;;) {
        // LOGGER << "Send" << std::endl;
        this->m_socket.send(this->m_p_req->serialize());
        // LOGGER << "Try to recv..." << std::endl;
        auto const pkt = this->m_socket.recv();
        if (!pkt) {
            continue;
        }
        auto const ack = ACK::deserialize(*pkt);
        if (ack && ack->m_sn == this->m_sn) {
            LOGGER << *this->m_p_req << " ==> " << *ack << std::endl;
            return ack;
        }
    }
}

}  // namespace spike_vcs_TL
