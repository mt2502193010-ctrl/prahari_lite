// ap_types.h
// MacBook g++ compatibility stub for Xilinx HLS types
// In Vitis HLS: include <ap_fixed.h> and <hls_stream.h> instead
// This file is NOT used in actual HLS synthesis — logic verification only

#ifndef AP_TYPES_H
#define AP_TYPES_H

#include <cstdint>
#include <cmath>
#include <algorithm>
#include <queue>

// ── ap_fixed stub ──────────────────────────────────────────────
// Approximates ap_fixed<W,I> using double for g++ testing
template<int W, int I>
class ap_fixed {
public:
    double val;
    static constexpr int width     = W;
    static constexpr int int_bits  = I;
    static constexpr int frac_bits = W - I;

    ap_fixed() : val(0.0) {}
    ap_fixed(double v) : val(v) {}
    ap_fixed(float  v) : val((double)v) {}
    ap_fixed(int    v) : val((double)v) {}
    ap_fixed(long   v) : val((double)v) {}
    // Cross-width copy constructor — enables weight_t(accum_t_val)
    template<int W2, int I2>
    ap_fixed(const ap_fixed<W2,I2>& o) : val(o.val) {}

    explicit operator bool()   const { return val != 0.0; }
    operator double() const { return val; }
    operator float()  const { return (float)val; }
    operator int()    const { return (int)val; }

    ap_fixed operator+(const ap_fixed& o) const { return ap_fixed(val + o.val); }
    ap_fixed operator-(const ap_fixed& o) const { return ap_fixed(val - o.val); }
    ap_fixed operator*(const ap_fixed& o) const { return ap_fixed(val * o.val); }
    ap_fixed operator/(const ap_fixed& o) const { return ap_fixed(val / o.val); }
    bool operator<=(const ap_fixed& o) const { return val <= o.val; }
    bool operator>=(const ap_fixed& o) const { return val >= o.val; }
    bool operator< (const ap_fixed& o) const { return val <  o.val; }
    bool operator> (const ap_fixed& o) const { return val >  o.val; }
    bool operator==(const ap_fixed& o) const { return val == o.val; }
    bool operator!=(const ap_fixed& o) const { return val != o.val; }
    ap_fixed& operator+=(const ap_fixed& o) { val += o.val; return *this; }
    ap_fixed& operator-=(const ap_fixed& o) { val -= o.val; return *this; }
    ap_fixed& operator*=(const ap_fixed& o) { val *= o.val; return *this; }
    ap_fixed& operator/=(const ap_fixed& o) { val /= o.val; return *this; }
    ap_fixed& operator/=(int n)             { val /= n;     return *this; }
};

// ── ap_uint stub ───────────────────────────────────────────────
template<int W>
class ap_uint {
public:
    uint32_t val;
    ap_uint() : val(0) {}
    ap_uint(uint32_t v) : val(v) {}
    ap_uint(int v)      : val((uint32_t)v) {}
    explicit operator bool()   const { return val != 0; }
    operator int()      const { return (int)val; }
    operator uint32_t() const { return val; }
    operator long()     const { return (long)val; }
    bool operator==(int o)            const { return (int)val == o; }
    bool operator!=(int o)            const { return (int)val != o; }
    bool operator< (uint32_t o)       const { return val < o; }
    bool operator> (uint32_t o)       const { return val > o; }
    bool operator>=(const ap_uint& o) const { return val >= o.val; }
    bool operator<=(const ap_uint& o) const { return val <= o.val; }
    bool operator!=(const ap_uint& o) const { return val != o.val; }
    bool operator==(const ap_uint& o) const { return val == o.val; }
    ap_uint  operator^(const ap_uint& o) const { return ap_uint(val ^ o.val); }
    ap_uint  operator|(const ap_uint& o) const { return ap_uint(val | o.val); }
    ap_uint  operator&(const ap_uint& o) const { return ap_uint(val & o.val); }
    ap_uint& operator=(int v)       { val=(uint32_t)v; return *this; }
    ap_uint& operator=(uint32_t v)  { val=v; return *this; }
};

// ── hls::stream stub ──────────────────────────────────────────
namespace hls {
    template<typename T>
    class stream {
    public:
        std::queue<T> q;
        void write(const T& v)      { q.push(v); }
        T    read()                 { T v = q.front(); q.pop(); return v; }
        bool read_nb(T& v)          { if (q.empty()) return false; v = q.front(); q.pop(); return true; }
        bool empty() const          { return q.empty(); }
        bool full()  const          { return false; }
    };
}

// ── HLS pragmas — ignored by g++ ──────────────────────────────
// In Vitis HLS these become #pragma HLS PIPELINE II=1 etc.
#ifdef __SYNTHESIS__
// Real pragmas handled by synthesiser
#endif

// PRAHARI-Lite: each HLS module defines its own types locally.
// The PRAHARI v7 global typedefs (feature_t, weight_t, etc.) are
// intentionally omitted here to avoid conflicts with Lite module types.

#define NUM_FEATURES 15
#define NUM_CLASSES   5

#endif // AP_TYPES_H
