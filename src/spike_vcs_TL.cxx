#include "spike_vcs_TL.hxx"

namespace spike_vcs_TL {

Request::Request(uint8_t _sn, Request_type _cmd, uint32_t _address /*= 0*/, uint8_t _size /*= 0*/, uint32_t _data /*= 0*/) : m_sn(_sn)
, m_cmd(_cmd)
, m_address(_address)
, m_size(_size)
, m_data(_data) {
}

ACK::ACK(uint8_t a_sn, Request_type a_cmd, uint32_t a_data /*= 0*/) : m_sn(a_sn)
, m_cmd(a_cmd)
, m_data(a_data) {

}

std::ostream&
operator << (std::ostream& a_ostr, Request const& a_req) {
    a_ostr <<
        "Request" <<
        " sn = " << std::dec << unsigned(a_req.m_sn) <<
        " cmd = " << unsigned(a_req.m_cmd);
    if (a_req.m_cmd == Request_type::read || a_req.m_cmd == Request_type::write) {
        a_ostr <<
            " address = " << std::hex << a_req.m_address << std::dec <<
            " size = " << unsigned(a_req.m_size);
        if (a_req.m_cmd == Request_type::write) {
            a_ostr <<
                " data = " << std::hex << unsigned(a_req.m_data) << std::dec;
        }
    }
    return a_ostr;
}

std::ostream&
operator << (std::ostream& a_ostr, ACK const& a_ack) {
    a_ostr <<
        "ACK:" <<
        " sn = " << std::dec << unsigned(a_ack.m_sn) <<
        " cmd = " << unsigned(a_ack.m_cmd);
    if (a_ack.m_cmd == Request_type::read || a_ack.m_cmd == Request_type::reset_state) {
        a_ostr <<
            " data = " << std::hex << unsigned(a_ack.m_data) << std::dec;
    }
    return a_ostr;
}

}  // namespace spike_vcs_TL
