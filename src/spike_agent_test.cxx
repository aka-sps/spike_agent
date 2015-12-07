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
    try {
        spikeSetReset(1);
        spikeSetReset(0);

        for (;;) {
            /// Need call each clock 
            /// \return 0 - no transaction in this clock, 1 - read transaction, 2 - write transaction 
            auto const transaction_type = spikeClock();
            switch (transaction_type) {
                case 1:  // read transaction
                    (void)spikeGetAddress();
                    (void)spikeGetSize();
                    spikeSetData(data_distribution(generator));
                    break;
                case 2:  // write transaction
                    (void)spikeGetAddress();
                    (void)spikeGetSize();
                    (void)spikeGetData();
                    (void)spikeGetData();
                    break;
                default:
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

