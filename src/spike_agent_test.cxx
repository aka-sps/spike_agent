#include "spike_vcs_TL/spike_agent.hxx"

#include <cstdint>
#include <random>
#include <limits>
#include <iostream>
#include <iomanip>
#include <exception>

namespace {
std::default_random_engine generator;
std::uniform_int_distribution<uint32_t> data_distribution(0, std::numeric_limits<uint32_t>::max());
}  // namespace

int
main(int, char*[])
{
    uint32_t const base = 0xFEED0000u;
    uint32_t const mem_size = 1 << 12u;
    uint8_t mem[mem_size];
    try {
        spikeSetReset(1);
        spikeSetReset(0);

        for (;;) {
            /// Need call each clock 
            /// \return 0 - no transaction in this clock, 1 - read transaction, 2 - write transaction 
            auto const transaction_type = spikeClock();
            switch (transaction_type) {
                case 1:  // read transaction
                    {
                        uint32_t const address = spikeGetAddress();
                        uint32_t const size = spikeGetSize();
                        if (address < base || base + mem_size < address + size || !(size == 1 || size == 2 || size == 4) || address & (size - 1) != 0) {
                            std::cerr << "Bad read: address=" << std::hex << address << ", size=" << std::hex << size << std::dec << std::endl;
                        }
                        uint32_t data = 0;
                        uint8_t const* p = &mem[address - base + size];
                        for (size_t i = 0; i < size; ++i) {
                            data = (data << 8) | *(--p);
                        }
                        spikeSetData(data);
                    }
                    break;
                case 2:  // write transaction
                    {
                        uint32_t const address = spikeGetAddress();
                        uint32_t const size = spikeGetSize();
                        uint32_t data = spikeGetData();
                        if (address < base || base + mem_size < address + size || !(size == 1 || size == 2 || size == 4) || address & (size - 1) != 0) {
                            std::cerr << "Bad write: address=" << std::hex << address << ", size=" << std::hex << size << ", data=" << std::hex << data << std::dec << std::endl;
                        }
                        uint8_t* p = &mem[address - base];
                        for (size_t i = 0; i < size; ++i) {
                            *(p++) = uint8_t(data);
                            data >>= 8;
                        }
                    }
                    break;
                default:
                    std::cerr << "empty clock" << std::endl;
                    break;
            }
            spikeEndClock();
        }
        return 0;
    } catch (std::exception const& a_excpt) {
        std::cerr << "Unhandled std exception: " << a_excpt.what() << std::endl;
    } catch (...) {
        std::cerr << "Unhandled unknown exception" << std::endl;
    }
}
