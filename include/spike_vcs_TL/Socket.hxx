#ifndef SPIKE_VCS_TL__SOCKET_HXX_
#define SPIKE_VCS_TL__SOCKET_HXX_

#include <sys/socket.h>
#include <sys/types.h>

namespace spike_vcs_TL {
class Socket
{
public:
    Socket(int __family, int __type, int __protocol);
    ~Socket();

    ssize_t
        recv(void* buf, size_t len, int flags = 0)const;
    ssize_t
        send(void const* buf, size_t len, int flags)const;
    ssize_t
        recvfrom(void* buf, size_t len, int flags, struct sockaddr* src_addr, socklen_t* addrlen)const;
    ssize_t
        sendto(void const* buf, size_t len, int flags, struct sockaddr const* dest_addr, socklen_t addrlen)const;

protected:
    int m_socket;
};

}  // namespace spike_vcs_TL
#endif // SPIKE_VCS_TL__SOCKET_HXX_
