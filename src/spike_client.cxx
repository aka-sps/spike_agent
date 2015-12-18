/// \file
/// \copyright Syntacore 2015
/// See LICENSE for license details

#include "spike_vcs_TL/spike_client.hxx"
#include "spike_vcs_TL.hxx"

#include <climits>
#include <string>

using spike_vcs_TL::Request_type;

namespace spike_vcs_TL {
vcs_device_agent::vcs_device_agent()
    : m_was_transactions(false)
{}

vcs_device_agent&
vcs_device_agent::instance()
{
    static vcs_device_agent inst;
    return inst;
}

bool
vcs_device_agent::load(uint32_t addr, size_t len, uint8_t* bytes)
{
    if (!(len == 1 || len == 2 || len == 4)) {
        throw std::length_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": vcs_device_agent::load bad lenght = " + std::to_string(len));
    }
    auto const ack = Client::instance().request(Request_type::read, addr, len);
    if (ack->m_cmd == Request_type::read) {
        auto data = ack->m_data;
        /// \warning Little endian only
        for (size_t i = 0; i < len; ++i) {
            *bytes++ = static_cast<uint8_t>(data);
            static_assert(CHAR_BIT == 8, "CHAR_BIT == 8 only");
            data >>= 8;
        }
    } else if (ack->m_cmd == Request_type::reset_state && ack->m_data != 0) {
        throw Reset_active();
    } else {
        throw Exception();
    }
    return this->m_was_transactions = true;
}

bool
vcs_device_agent::store(uint32_t addr, size_t len, uint8_t const* bytes)
{
    if (!(len == 1 || len == 2 || len == 4)) {
        throw std::length_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": vcs_device_agent::store bad lenght = " + std::to_string(len));
    }
    uint8_t const* p = bytes + len;
    /// \warning Little endian only
    uint32_t data = 0u;
    for (size_t i = 0; i < len; ++i) {
        static_assert(CHAR_BIT == 8, "CHAR_BIT == 8 only");
        data = (data <<= 8) | (*--p);
    }
    // LOGGER << "vcs_device_agent::store: len=" << len << std::endl;
    auto const ack = Client::instance().request(Request_type::write, addr, len, data);
    if (ack->m_cmd == Request_type::write) {
    } else if (ack->m_cmd == Request_type::reset_state && ack->m_data != 0) {
        throw Reset_active();
    } else {
        throw Exception();
    }
    return this->m_was_transactions = true;
}

void
vcs_device_agent::end_of_clock()
{
    if (this->m_was_transactions) {
        return;
    }
    auto const ack = Client::instance().request(Request_type::skip);
    if (ack->m_cmd == Request_type::skip) {
    } else if (ack->m_cmd == Request_type::reset_state && ack->m_data != 0) {
        throw Reset_active();
    } else {
        throw Exception();
    }
    this->m_was_transactions = false;
}

void
vcs_device_agent::wait_while_reset_is_active() const
{
    for (;;) {
        auto const ack = Client::instance().request(Request_type::reset_state);
        if (ack && ack->m_cmd == Request_type::reset_state && ack->m_data == 0) {
            break;
        }
    }
}

}  // namespace spike_vcs_TL
