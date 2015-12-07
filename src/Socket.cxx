#include "spike_vcs_TL/Socket.hxx"

namespace spike_vcs_TL {
Socket::Socket(int __family, int __type, int __protocol)
    : m_socket(::socket(__family, __type, __protocol))
{}

Socket::~Socket()
{
    ::close(this->m_socket);
}

ssize_t
Socket::recv(void* buf, size_t len, int flags /*= 0*/) const
{
    return ::recv(m_socket, buf, len, flags);
}

ssize_t
Socket::recvfrom(void *buf, size_t len, int flags, struct sockaddr* src_addr, socklen_t* addrlen) const
{
    return ::recvfrom(m_socket, buf, len, flags, src_addr, addrlen);
}

ssize_t
Socket::send(void const* buf, size_t len, int flags) const
{
    return ::send(m_socket, buf, len, flags);
}

ssize_t
Socket::sendto(const void *buf, size_t len, int flags, struct sockaddr const* dest_addr, socklen_t addrlen) const
{
    return ::sendto(m_socket, buf, len, flags, dest_addr, addrlen);
}

}  // namespace spike_vcs_TL
