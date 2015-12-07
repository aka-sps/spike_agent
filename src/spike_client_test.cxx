#include "spike_vcs_TL/spike_client.hxx"

#include <random>
#include <iostream>
#include <iomanip>
#include <cstdint>

namespace {
using namespace spike_vcs_TL;
static void
wait_while_reset_is_active()
{
    for (;;) {
        auto const ack = Client::instance().request(Request_type::reset_state);
        if (ack && ack->m_cmd == Request_type::reset_state && ack->m_data == 0) {
            break;
        }
    }
}
static uint32_t const base = 0xFEED0000u;
static uint32_t const limit_bytes = 1u << 12;
std::default_random_engine generator;

static std::shared_ptr<ACK const>
random_transaction()
{
    std::discrete_distribution<uint8_t> transactions_kind_distribution{0.50, 0.25, 0.25};
    uint8_t const transactions_kind = transactions_kind_distribution(generator);
    switch (transactions_kind) {
        // read or write
        case 1:
        case 2:
            {
                std::discrete_distribution<uint8_t> transactions_size_distribution{0.30, 0.20, 0.50};
                uint8_t const log2_byte_size = transactions_size_distribution(generator);
                uint8_t const size_bytes = 1u << log2_byte_size;
                uint32_t const num_cells = limit_bytes / size_bytes;
                std::uniform_int_distribution<uint32_t> offset_distribution(0, num_cells - 1);
                uint32_t const offset = offset_distribution(generator) * size_bytes;
                if (transactions_kind == 1) {
                    return Client::instance().request(Request_type::read, base + offset, size_bytes);
                } else {
                    uint8_t const size_bits = 8 * size_bytes;
                    std::uniform_int_distribution<uint32_t> offset_distribution(0, (1u << size_bits) - 1);
                    uint32_t const data = offset_distribution(generator);
                    uint32_t repeated_data = data;
                    for (int i = 1; i < (4 / size_bytes); ++i) {
                        repeated_data = (repeated_data << size_bits) | data;
                    }
                    return Client::instance().request(Request_type::write, base + offset, size_bytes, repeated_data);
                }
            }
            break;
        default:
            return Client::instance().request(Request_type::skip);
    }
}

}  // namespace

int main(int, char*[])
{
    try {
        wait_while_reset_is_active();
        for (;;) {
            auto const ack = random_transaction();
            if (ack) {
                if (ack->m_cmd == Request_type::reset_state && ack->m_data != 0) {
                    break;
                }
            }
        }
        return 0;
    } catch (std::exception const& a_excpt) {
        std::cerr << "Unhandled std exception: " << a_excpt.what() << std::endl;
    } catch (...) {
        std::cerr << "Unhandled unknown exception" << std::endl;
    }
}

