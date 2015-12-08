#include "spike_vcs_TL/udp_socket.hxx"

/// socket
#include <sys/socket.h>

/// close
#include <sys/unistd.h>

/// AF_INET, SOCK_DGRAM
#include <netinet/in.h>

#include <sys/select.h>
#include <sys/unistd.h>

namespace spike_vcs_TL {

UDP_Socket::UDP_Socket()
    : Base_class(AF_INET, SOCK_DGRAM, 0)
{}

std::shared_ptr<std::vector<uint8_t> >
UDP_Socket::recvfrom(std::vector<unsigned char>& a_buffer, struct sockaddr_in& sender_addr)const
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
    ssize_t const size = ::recvfrom(this->m_socket, &a_buffer[0], a_buffer.size(), 0, nullptr, 0);
    if (size < 0) {
        LOGGER << "...recvfrom failure: " << size << std::endl;
        return result_type();
    }
    buf.resize(size);
}

void
UDP_Socket::send(std::vector<uint8_t> const& buf, struct sockaddr const* dest_addr, socklen_t addrlen) const
{
    do {
    } while (::sendto(this->m_socket, &buf[0], buf.size(), 0, dest_addr, addrlen) != buf.size());
}


}  // namespace spike_vcs_TL
