#ifndef SPIKE_VCS_TL_HXX_
#define SPIKE_VCS_TL_HXX_
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

}  // namespace spike_vcs_TL

#endif  // SPIKE_VCS_TL_HXX_
