#ifndef OSMIUM_OSM_TIMESTAMP_HPP
#define OSMIUM_OSM_TIMESTAMP_HPP

/*

This file is part of Osmium (https://osmcode.org/libosmium).

Copyright 2013-2022 Jochen Topf <jochen@topf.org> and others (see README).

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/

#include <osmium/util/minmax.hpp> // IWYU pragma: keep

#include <array>
#include <cassert>
#include <cstdint>
#include <ctime>
#include <iosfwd>
#include <limits>
#include <stdexcept>
#include <string>
#include <type_traits>

namespace osmium {

    namespace detail {

        inline void add_2digit_int_to_string(int value, std::string& out) {
            assert(value >= 0 && value <= 99);
            if (value > 9) {
                const int dec = value / 10;
                out += static_cast<char>('0' + dec);
                value -= dec * 10;
            } else {
                out += '0';
            }
            out += static_cast<char>('0' + value);
        }

        inline void add_4digit_int_to_string(int value, std::string& out) {
            assert(value >= 1000 && value <= 9999);

            const int dec1 = value / 1000;
            out += static_cast<char>('0' + dec1);
            value -= dec1 * 1000;

            const int dec2 = value / 100;
            out += static_cast<char>('0' + dec2);
            value -= dec2 * 100;

            const int dec3 = value / 10;
            out += static_cast<char>('0' + dec3);
            value -= dec3 * 10;

            out += static_cast<char>('0' + value);
        }

        inline time_t parse_timestamp(const char* str) {
            static const std::array<int, 12> mon_lengths = {{
                31, 29, 31, 30, 31, 30,
                31, 31, 30, 31, 30, 31
            }};

            if (str[ 0] >= '0' && str[ 0] <= '9' &&
                str[ 1] >= '0' && str[ 1] <= '9' &&
                str[ 2] >= '0' && str[ 2] <= '9' &&
                str[ 3] >= '0' && str[ 3] <= '9' &&
                str[ 4] == '-' &&
                str[ 5] >= '0' && str[ 5] <= '9' &&
                str[ 6] >= '0' && str[ 6] <= '9' &&
                str[ 7] == '-' &&
                str[ 8] >= '0' && str[ 8] <= '9' &&
                str[ 9] >= '0' && str[ 9] <= '9' &&
                str[10] == 'T' &&
                str[11] >= '0' && str[11] <= '9' &&
                str[12] >= '0' && str[12] <= '9' &&
                str[13] == ':' &&
                str[14] >= '0' && str[14] <= '9' &&
                str[15] >= '0' && str[15] <= '9' &&
                str[16] == ':' &&
                str[17] >= '0' && str[17] <= '9' &&
                str[18] >= '0' && str[18] <= '9' &&
                str[19] == 'Z') {
                std::tm tm; // NOLINT(cppcoreguidelines-pro-type-member-init,hicpp-member-init)
                tm.tm_year = (str[ 0] - '0') * 1000 +
                             (str[ 1] - '0') *  100 +
                             (str[ 2] - '0') *   10 +
                             (str[ 3] - '0')        - 1900;
                tm.tm_mon  = (str[ 5] - '0') * 10 + (str[ 6] - '0') - 1;
                tm.tm_mday = (str[ 8] - '0') * 10 + (str[ 9] - '0');
                tm.tm_hour = (str[11] - '0') * 10 + (str[12] - '0');
                tm.tm_min  = (str[14] - '0') * 10 + (str[15] - '0');
                tm.tm_sec  = (str[17] - '0') * 10 + (str[18] - '0');
                tm.tm_wday = 0;
                tm.tm_yday = 0;
                tm.tm_isdst = 0;
                if (tm.tm_year >= 0 &&
                    tm.tm_mon  >= 0 && tm.tm_mon  <= 11 &&
                    tm.tm_mday >= 1 && tm.tm_mday <= mon_lengths[tm.tm_mon] &&
                    tm.tm_hour >= 0 && tm.tm_hour <= 23 &&
                    tm.tm_min  >= 0 && tm.tm_min  <= 59 &&
                    tm.tm_sec  >= 0 && tm.tm_sec  <= 60) {
#ifndef _WIN32
                    return 0;
#else
                    return _mkgmtime(&tm);
#endif
                }
            }
            throw std::invalid_argument{std::string{"can not parse timestamp: '"} + str + "'"};
        }

    } // namespace detail

    /**
     * A timestamp. Internal representation is an unsigned 32bit integer
     * holding seconds since epoch (1970-01-01T00:00:00Z), so this will
     * overflow in 2106. We can use an unsigned integer here, because the
     * OpenStreetMap project was started long after 1970, so there will
     * never be dates before that.
     */
    class Timestamp {

        uint32_t m_timestamp = 0;

        void to_iso_str(std::string& s) const {
            std::tm tm; // NOLINT(cppcoreguidelines-pro-type-member-init,hicpp-member-init)
            time_t sse = seconds_since_epoch();
#ifndef NDEBUG
            auto result =
#endif
#ifndef _WIN32
            gmtime_r(&sse, &tm);
            assert(result != nullptr);
#else
            gmtime_s(&tm, &sse);
            assert(result == 0);
#endif

            detail::add_4digit_int_to_string(tm.tm_year + 1900, s);
            s += '-';
            detail::add_2digit_int_to_string(tm.tm_mon + 1, s);
            s += '-';
            detail::add_2digit_int_to_string(tm.tm_mday, s);
            s += 'T';
            detail::add_2digit_int_to_string(tm.tm_hour, s);
            s += ':';
            detail::add_2digit_int_to_string(tm.tm_min, s);
            s += ':';
            detail::add_2digit_int_to_string(tm.tm_sec, s);
            s += 'Z';
        }

    public:

        /**
         * Default construct an invalid Timestamp.
         */
        constexpr Timestamp() noexcept = default;

        /**
         * Construct a Timestamp from any integer type containing the seconds
         * since the epoch. This will not check for overruns, you have to
         * make sure the value fits into a uint32_t which is used internally
         * in the Timestamp.
         *
         * The constructor is not declared "explicit" so that conversions
         * like @code node.set_timestamp(123); @endcode work.
         */
        template <typename T, typename std::enable_if<std::is_integral<T>::value, int>::type = 0>
        constexpr Timestamp(T timestamp) noexcept : // NOLINT(google-explicit-constructor, hicpp-explicit-conversions)
            m_timestamp(uint32_t(timestamp)) {
        }

        /**
         * Construct timestamp from ISO date/time string in the format
         * "yyyy-mm-ddThh:mm:ssZ".
         *
         * @throws std::invalid_argument if the timestamp can not be parsed.
         */
        explicit Timestamp(const char* timestamp) :
            m_timestamp(static_cast<uint32_t>(detail::parse_timestamp(timestamp))) {
        }

        /**
         * Construct timestamp from ISO date/time string in the format
         * "yyyy-mm-ddThh:mm:ssZ".
         *
         * @throws std::invalid_argument if the timestamp can not be parsed.
         */
        explicit Timestamp(const std::string& timestamp) :
            Timestamp(timestamp.c_str()) {
        }

        /**
         * Returns true if this timestamp is valid (ie set to something other
         * than 0).
         */
        bool valid() const noexcept {
            return m_timestamp != 0;
        }

        /// Explicit conversion into bool.
        explicit constexpr operator bool() const noexcept {
            return m_timestamp != 0;
        }

        /// Explicit conversion into time_t.
        constexpr time_t seconds_since_epoch() const noexcept {
            return time_t(m_timestamp);
        }

        /// Explicit conversion into uint32_t.
        explicit constexpr operator uint32_t() const noexcept {
            return uint32_t(m_timestamp);
        }

        /// Explicit conversion into uint64_t.
        explicit constexpr operator uint64_t() const noexcept {
            return uint64_t(m_timestamp);
        }

        template <typename T>
        void operator+=(T time_difference) noexcept {
            m_timestamp += time_difference;
        }

        template <typename T>
        void operator-=(T time_difference) noexcept {
            m_timestamp -= time_difference;
        }

        /**
         * Return the timestamp as string in ISO date/time
         * ("yyyy-mm-ddThh:mm:ssZ") format. If the timestamp is invalid, an
         * empty string will be returned.
         */
        std::string to_iso() const {
            std::string s;

            if (m_timestamp != 0) {
                to_iso_str(s);
            }

            return s;
        }

        /**
         * Return the timestamp as string in ISO date/time
         * ("yyyy-mm-ddThh:mm:ssZ") format. If the timestamp is invalid, the
         * string "1970-01-01T00:00:00Z" will be returned.
         */
        std::string to_iso_all() const {
            std::string s;

            to_iso_str(s);

            return s;
        }

    }; // class Timestamp

    /**
     * A special Timestamp guaranteed to be ordered before any other valid
     * Timestamp.
     */
    inline constexpr Timestamp start_of_time() noexcept {
        return {1};
    }

    /**
     * A special Timestamp guaranteed to be ordered after any other valid
     * Timestamp.
     */
    inline constexpr Timestamp end_of_time() noexcept {
        return {std::numeric_limits<uint32_t>::max()};
    }

    template <typename TChar, typename TTraits>
    inline std::basic_ostream<TChar, TTraits>& operator<<(std::basic_ostream<TChar, TTraits>& out, Timestamp timestamp) {
        out << timestamp.to_iso();
        return out;
    }

    inline bool operator==(const Timestamp& lhs, const Timestamp& rhs) noexcept {
        return uint32_t(lhs) == uint32_t(rhs);
    }

    inline bool operator!=(const Timestamp& lhs, const Timestamp& rhs) noexcept {
        return !(lhs == rhs);
    }

    inline bool operator<(const Timestamp& lhs, const Timestamp& rhs) noexcept {
        return uint32_t(lhs) < uint32_t(rhs);
    }

    inline bool operator>(const Timestamp& lhs, const Timestamp& rhs) noexcept {
        return rhs < lhs;
    }

    inline bool operator<=(const Timestamp& lhs, const Timestamp& rhs) noexcept {
        return !(rhs < lhs);
    }

    inline bool operator>=(const Timestamp& lhs, const Timestamp& rhs) noexcept {
        return !(lhs < rhs);
    }

    template <>
    inline osmium::Timestamp min_op_start_value<osmium::Timestamp>() {
        return end_of_time();
    }

    template <>
    inline osmium::Timestamp max_op_start_value<osmium::Timestamp>() {
        return start_of_time();
    }

} // namespace osmium

#endif // OSMIUM_OSM_TIMESTAMP_HPP