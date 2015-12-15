////////////////////////////////////////////////////
// Copyright 2015 Syntacore 
// See LICENSE for license details
////////////////////////////////////////////////////

#include "spike_vcs_TL/spike_client.hxx"

#include <random>
#include <iostream>
#include <iomanip>
#include <algorithm>

#define LOGGER std::cerr << __FILE__ << "(" << __LINE__ << "): "

namespace {
static uint32_t const base = 0xFEED0000u;
static uint32_t const limit_bytes = 1u << 12;
std::default_random_engine generator;

std::discrete_distribution<uint8_t> transactions_kind_distribution{0.50, 0.25, 0.25};
std::discrete_distribution<uint8_t> transactions_size_distribution{0.30, 0.20, 0.50};
std::uniform_int_distribution<uint8_t> data_distribution(0, std::numeric_limits<uint8_t>::max());

void
random_transaction() {
    auto& vcs = spike_vcs_TL::vcs_device_agent::instance();
    uint8_t const transactions_kind = transactions_kind_distribution(generator);
    switch (transactions_kind) {
        // read or write
        case 1:
        case 2:
            {
                uint8_t const log2_byte_size = transactions_size_distribution(generator);
                uint8_t const size_bytes = 1u << log2_byte_size;
                uint32_t const num_cells = limit_bytes / size_bytes;
                std::uniform_int_distribution<uint32_t> offset_distribution(0, num_cells - 1);
                uint32_t const offset = offset_distribution(generator) * size_bytes;
                if (transactions_kind == 1) {
                    uint8_t buffer[4];
                    // LOGGER << "Read size: " << unsigned(size_bytes) << std::endl;
                    vcs.load(base + offset, size_bytes, buffer);
                } else {
                    uint8_t buffer[4];
                    std::generate_n(buffer, size_bytes, [](){return data_distribution(generator);});
                    // LOGGER << "Write size: " << unsigned(size_bytes) << std::endl;
                    vcs.store(base + offset, size_bytes, buffer);
                }
            }
            break;

        default:
            break;
    }
    vcs.end_of_clock();
}

}  // namespace

int
main(int, char*[]) {
    using namespace spike_vcs_TL;
    try {
        auto& vcs = vcs_device_agent::instance();
        vcs.wait_while_reset_is_active();
        for (;;) {
            random_transaction();
        }
        return EXIT_SUCCESS;
    } catch (vcs_device_agent::Reset_active const& a_excpt) {
        std::cerr << "vcs: reset detected: " << std::endl;
        return EXIT_SUCCESS;
    } catch (std::exception const& a_excpt) {
        std::cerr << "Unhandled std exception: " << a_excpt.what() << std::endl;
    } catch (...) {
        std::cerr << "Unhandled unknown exception" << std::endl;
    }
    return EXIT_FAILURE;
}