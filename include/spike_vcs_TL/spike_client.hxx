#ifndef SPIKE_VCS_TL__SPIKE_CLIENT_HXX_
#define SPIKE_VCS_TL__SPIKE_CLIENT_HXX_

#include <cstdint>
#include <stdexcept>

namespace spike_vcs_TL {
class vcs_device_agent
{
    vcs_device_agent();
    vcs_device_agent(vcs_device_agent const&) = delete;
    vcs_device_agent& operator = (vcs_device_agent const&) = delete;

public:
    class Exception :public std::runtime_error
    {
    public:
        typedef std::runtime_error Base_class;
    public:
        Exception(std::string const& _what = "vcs_device error") :Base_class(_what)
        {}
    };
    class Reset_active :public Exception
    {
        typedef Exception Base_class;
    public:
        Reset_active() :Base_class("active reset signal")
        {}
    };

    static vcs_device_agent&
        instance();

    void
        wait_while_reset_is_active()const;

    bool
        load(uint32_t addr, size_t len, uint8_t* bytes);
    bool
        store(uint32_t addr, size_t len, uint8_t const* bytes);
    void
        end_of_clock();

private:
    bool m_was_transactions;
};
}  // namespace spike_vcs_TL

#endif  // SPIKE_VCS_TL__SPIKE_CLIENT_HXX_
