#ifndef SPIKE_VCS_TL__UDP_SOCKET_HXX_
#define SPIKE_VCS_TL__UDP_SOCKET_HXX_

#include "spike_vcs_TL/Socket.hxx"
#include <netinet/in.h>

namespace spike_vcs_TL {
class UDP_Socket : public Socket
{
    typedef Socket Base_class;
public:
    UDP_Socket();
    ssize_t
        recvfrom(void* buf, size_t len, int flags, struct sockaddr_in* src_addr)const
    {
        socklen_t socklen = sizeof(struct sockaddr);
        Base_class::recvfrom(buf, len, flags, reinterpret_cast<struct sockaddr*>(src_addr), &socklen);
    }
    ssize_t
        sendto(void const* buf, size_t len, int flags, struct sockaddr_in const* dest_addr)const
    {
        Base_class::sendto(buf, len, flags, reinterpret_cast<struct sockaddr const*>(dest_addr), sizeof(sockaddr_in));
    }
};
}  // namespace spike_vcs_TL

#endif  // SPIKE_VCS_TL__UDP_SOCKET_HXX_
