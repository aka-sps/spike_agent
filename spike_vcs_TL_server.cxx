#include "spike_vcs_TL.hxx"
namespace spike_vcs_TL {

std::shared_ptr<Request const>
Request::deserialize(std::vector<uint8_t> const& a_buf) {
    typedef std::shared_ptr<Request const> res_type;
    if (a_buf.size() < 2) {
        LOGGER << "a_buf.size() < 2 (" << a_buf.size() << ")" << std::endl;
        return res_type();
    }
    uint8_t const sn = a_buf[0];
    if (a_buf[1] > static_cast<uint8_t>(Request_type::reset_state)) {
        LOGGER << "a_buf[1] > static_cast<uint8_t>(Request_type::reset) (" << a_buf[1] << ")" << std::endl;
        return res_type();
    }
    Request_type const cmd = static_cast<Request_type>(a_buf[1]);
    switch (cmd) {
        case Request_type::read:
        case Request_type::write:
            {
                size_t const size = a_buf[2];
                if (!(size == 1 || size == 2 || size == 4)) {
                    LOGGER << "Bad size: " << unsigned(size) << std::endl;
                    return res_type();
                }
                uint32_t const address = (((((a_buf[4] << 8) | a_buf[5]) << 8) | a_buf[6]) << 8) | a_buf[7];
                if (address & (size - 1) != 0) {
                    LOGGER << "address & (size - 1) != 0 (address=" << address << ", size=" << size << ")" << std::endl;
                    return res_type();
                }
                if (cmd == Request_type::write) {
                    uint32_t const data = (((((a_buf[8] << 8) | a_buf[9]) << 8) | a_buf[10]) << 8) | a_buf[11];
                    return res_type(new Request(sn, cmd, address, size, data));
                } else {
                    return res_type(new Request(sn, cmd, address, size));
                }
            }
            break;
        default:
            return res_type(new Request(sn, cmd));
    }
}

std::shared_ptr<ACK const>
ACK::create(uint8_t a_sn, Request_type a_cmd, uint32_t a_data /*= 0*/) {
    return std::shared_ptr<ACK const>(new ACK(a_sn, a_cmd, a_data));
}
std::vector<uint8_t>
ACK::serialize() const {
    typedef std::vector<uint8_t> res_type;
    res_type res;
    res.reserve(8);
    res.push_back(m_sn);
    res.push_back(static_cast<uint8_t>(m_cmd));
    switch (this->m_cmd) {
        case Request_type::read:
        case Request_type::reset_state:
            {
                res.resize(8);
                res[4] = static_cast<uint8_t>(this->m_data >> (8 * 3));
                res[5] = static_cast<uint8_t>(this->m_data >> (8 * 2));
                res[6] = static_cast<uint8_t>(this->m_data >> (8 * 1));
                res[7] = static_cast<uint8_t>(this->m_data >> (8 * 0));
            }
        default:
            break;
    }
    return res;
}
}  // namespace spike_vcs_TL
