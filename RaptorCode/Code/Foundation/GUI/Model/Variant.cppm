// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :variant partition
//
// Variant: a small tagged value a Model hands to a view for a cell - the currency of the MVC
// layer. Modeled on eepp's Models::Variant (role only, common subset): empty / bool / int /
// float / string / color, and Core's curve keys and colour gradient (T5: what a property grid's
// curve and gradient rows carry, one value each, as a colour is). Stored as a plain struct (no
// union) for simplicity and safety; ToString renders it for display (a colour as #RRGGBBAA, a
// curve as its count of keys) and Compare orders it for sorting (a colour channel by channel, a
// curve and a gradient field by field, so differing values never compare equal).

module;
#include "Core/Prelude.h"

export module foundation.gui:variant;

import foundation.core; // String, StringView, Color, i64, f64

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// A colour gradient as one value: Core's colour stops and alpha stops, sorted by time, and the
    /// space they blend in (ruling 2: Core's gradient, no model of the GUI's own).
    struct ColorGradient
    {
        core::Array<core::GradientColorStop> Colors;
        core::Array<core::GradientAlphaStop> Alphas;
        core::GradientInterpolation Interpolation = core::GradientInterpolation::Srgb;

        [[nodiscard]] core::Color Evaluate(f32 time) const noexcept
        {
            return core::EvaluateGradient(Colors.AsSpan(), Alphas.AsSpan(), Interpolation, time);
        }
        [[nodiscard]] bool operator==(const ColorGradient& other) const noexcept
        {
            if (Interpolation != other.Interpolation || Colors.Size() != other.Colors.Size() || Alphas.Size() != other.Alphas.Size())
                return false;
            for (usize i = 0; i < Colors.Size(); ++i)
                if (Colors[i].time != other.Colors[i].time || !(Colors[i].color == other.Colors[i].color))
                    return false;
            for (usize i = 0; i < Alphas.Size(); ++i)
                if (Alphas[i].time != other.Alphas[i].time || Alphas[i].alpha != other.Alphas[i].alpha)
                    return false;
            return true;
        }
    };

    class Variant
    {
    public:
        enum class Type
        {
            Empty,
            Bool,
            Int,
            Float,
            String,
            Color,
            Curve,   ///< Core's curve keys, sorted by time
            Gradient ///< a ColorGradient
        };

        Variant() = default;
        Variant(bool value) : m_type(Type::Bool), m_bool(value) {}
        Variant(i64 value) : m_type(Type::Int), m_int(value) {}
        Variant(i32 value) : m_type(Type::Int), m_int(value) {}
        Variant(f64 value) : m_type(Type::Float), m_float(value) {}
        Variant(core::StringView value) : m_type(Type::String), m_string(value) {}
        Variant(const core::String& value) : m_type(Type::String), m_string(value) {}
        Variant(core::Color value) : m_type(Type::Color), m_color(value) {}
        Variant(const ColorGradient& value) : m_type(Type::Gradient), m_gradient(value) {}
        /// A curve's keys (a constructor of its own: a span of keys is no other value).
        [[nodiscard]] static Variant FromCurve(core::Span<const core::CurveKey> keys)
        {
            Variant out;
            out.m_type = Type::Curve;
            for (const core::CurveKey& key : keys)
                out.m_keys.PushBack(key);
            return out;
        }

        [[nodiscard]] Type GetType() const noexcept { return m_type; }
        [[nodiscard]] bool IsEmpty() const noexcept { return m_type == Type::Empty; }

        [[nodiscard]] bool AsBool() const noexcept
        {
            return m_type == Type::Bool ? m_bool : (m_type == Type::Int ? m_int != 0 : false);
        }
        [[nodiscard]] i64 AsInt() const noexcept
        {
            return m_type == Type::Int ? m_int
                                       : (m_type == Type::Float ? static_cast<i64>(m_float) : 0);
        }
        [[nodiscard]] f64 AsFloat() const noexcept
        {
            return m_type == Type::Float ? m_float
                                         : (m_type == Type::Int ? static_cast<f64>(m_int) : 0.0);
        }
        [[nodiscard]] core::StringView AsString() const noexcept { return m_string.AsView(); }
        [[nodiscard]] core::Color AsColor() const noexcept { return m_color; }
        /// A curve's keys; none for another type.
        [[nodiscard]] core::Span<const core::CurveKey> AsCurve() const noexcept { return m_keys.AsSpan(); }
        /// A gradient; an empty one for another type.
        [[nodiscard]] const ColorGradient& AsGradient() const noexcept { return m_gradient; }

        // A display string for any type (numbers rendered simply; string returned as-is).
        [[nodiscard]] core::String ToString() const
        {
            switch (m_type)
            {
            case Type::Empty:
                return core::String{};
            case Type::Bool:
                return core::String(m_bool ? core::StringView(u8"true")
                                           : core::StringView(u8"false"));
            case Type::Int:
                return IntToString(m_int);
            case Type::Float:
                return FloatToString(m_float);
            case Type::String:
                return m_string;
            case Type::Color:
            {
                // #RRGGBBAA, as a hex code writes it.
                const u32 packed = m_color.ToRGBA8();
                char8_t text[9] = {u8'#'};
                for (i32 i = 0; i < 8; ++i)
                {
                    const u32 nibble = (packed >> ((7 - i) * 4)) & 0xFu;
                    text[1 + i] = static_cast<char8_t>(nibble < 10 ? u8'0' + nibble : u8'A' + nibble - 10);
                }
                return core::String(core::StringView(text, 9));
            }
            case Type::Curve:
                return core::Format(u8"{} keys", m_keys.Size());
            case Type::Gradient:
                return core::Format(u8"{} colours, {} alphas", m_gradient.Colors.Size(), m_gradient.Alphas.Size());
            }
            return core::String{};
        }

        // Order two variants: numbers by value (an int against a float too, so a column mixing
        // them sorts as numbers), strings lexicographically, bools false<true. Other mixed and
        // empty types compare by their Type ordinal (a stable, if arbitrary, total order).
        [[nodiscard]] i32 Compare(const Variant& other) const
        {
            const bool numbers = (m_type == Type::Int || m_type == Type::Float) && (other.m_type == Type::Int || other.m_type == Type::Float);
            if (numbers && m_type != other.m_type)
            {
                const f64 a = m_type == Type::Int ? static_cast<f64>(m_int) : m_float;
                const f64 b = other.m_type == Type::Int ? static_cast<f64>(other.m_int) : other.m_float;
                return a == b ? 0 : (a < b ? -1 : 1);
            }
            if (m_type != other.m_type)
                return static_cast<i32>(m_type) < static_cast<i32>(other.m_type) ? -1 : 1;
            switch (m_type)
            {
            case Type::Empty:
                return 0;
            case Type::Bool:
                return (m_bool == other.m_bool) ? 0 : (!m_bool ? -1 : 1);
            case Type::Int:
                return (m_int == other.m_int) ? 0 : (m_int < other.m_int ? -1 : 1);
            case Type::Float:
                return (m_float == other.m_float) ? 0 : (m_float < other.m_float ? -1 : 1);
            case Type::String:
                return CompareStrings(m_string.AsView(), other.m_string.AsView());
            case Type::Color:
            {
                // Channel by channel, so two colours are equal only when they are the same.
                const f32 a[] = {m_color.r, m_color.g, m_color.b, m_color.a};
                const f32 b[] = {other.m_color.r, other.m_color.g, other.m_color.b, other.m_color.a};
                for (i32 i = 0; i < 4; ++i)
                    if (a[i] != b[i])
                        return a[i] < b[i] ? -1 : 1;
                return 0;
            }
            case Type::Curve:
            {
                // Its count, then key by key, field by field.
                if (m_keys.Size() != other.m_keys.Size())
                    return m_keys.Size() < other.m_keys.Size() ? -1 : 1;
                for (usize k = 0; k < m_keys.Size(); ++k)
                {
                    const core::CurveKey& x = m_keys[k];
                    const core::CurveKey& y = other.m_keys[k];
                    const f32 a[] = {x.time, x.value, x.tangentIn, x.tangentOut, static_cast<f32>(x.interpolation), static_cast<f32>(x.tangentMode)};
                    const f32 b[] = {y.time, y.value, y.tangentIn, y.tangentOut, static_cast<f32>(y.interpolation), static_cast<f32>(y.tangentMode)};
                    if (const i32 order = CompareFloats(a, b, 6); order != 0)
                        return order;
                }
                return 0;
            }
            case Type::Gradient:
            {
                const ColorGradient& x = m_gradient;
                const ColorGradient& y = other.m_gradient;
                if (x.Interpolation != y.Interpolation)
                    return x.Interpolation < y.Interpolation ? -1 : 1;
                if (x.Colors.Size() != y.Colors.Size())
                    return x.Colors.Size() < y.Colors.Size() ? -1 : 1;
                if (x.Alphas.Size() != y.Alphas.Size())
                    return x.Alphas.Size() < y.Alphas.Size() ? -1 : 1;
                for (usize i = 0; i < x.Colors.Size(); ++i)
                {
                    const core::GradientColorStop& p = x.Colors[i];
                    const core::GradientColorStop& q = y.Colors[i];
                    const f32 a[] = {p.time, p.color.r, p.color.g, p.color.b, p.color.a};
                    const f32 b[] = {q.time, q.color.r, q.color.g, q.color.b, q.color.a};
                    if (const i32 order = CompareFloats(a, b, 5); order != 0)
                        return order;
                }
                for (usize i = 0; i < x.Alphas.Size(); ++i)
                {
                    const f32 a[] = {x.Alphas[i].time, x.Alphas[i].alpha};
                    const f32 b[] = {y.Alphas[i].time, y.Alphas[i].alpha};
                    if (const i32 order = CompareFloats(a, b, 2); order != 0)
                        return order;
                }
                return 0;
            }
            }
            return 0;
        }

    private:
        [[nodiscard]] static i32 CompareFloats(const f32* a, const f32* b, usize count) noexcept
        {
            for (usize i = 0; i < count; ++i)
                if (a[i] != b[i])
                    return a[i] < b[i] ? -1 : 1;
            return 0;
        }
        [[nodiscard]] static i32 CompareStrings(core::StringView a, core::StringView b) noexcept
        {
            const usize n = a.Size() < b.Size() ? a.Size() : b.Size();
            for (usize i = 0; i < n; ++i)
                if (a[i] != b[i])
                    return a[i] < b[i] ? -1 : 1;
            if (a.Size() == b.Size())
                return 0;
            return a.Size() < b.Size() ? -1 : 1;
        }

        [[nodiscard]] static core::String IntToString(i64 value)
        {
            char8_t buf[24];
            usize pos = 24;
            const bool neg = value < 0;
            u64 v = neg ? static_cast<u64>(-(value + 1)) + 1u : static_cast<u64>(value);
            if (v == 0)
                buf[--pos] = u8'0';
            while (v > 0)
            {
                buf[--pos] = static_cast<char8_t>(u8'0' + (v % 10));
                v /= 10;
            }
            if (neg)
                buf[--pos] = u8'-';
            return core::String(core::StringView(buf + pos, 24 - pos));
        }

        // Compact fixed-ish float rendering (integer part + up to 3 decimals, trailing zeros trimmed).
        [[nodiscard]] static core::String FloatToString(f64 value)
        {
            const bool neg = value < 0.0;
            f64 v = neg ? -value : value;
            const i64 whole = static_cast<i64>(v);
            f64 frac = v - static_cast<f64>(whole);
            core::String out;
            if (neg)
                out.Append(core::StringView(u8"-"));
            out += IntToString(whole);
            // up to 3 decimal digits
            char8_t digits[3];
            usize dc = 0;
            for (usize i = 0; i < 3; ++i)
            {
                frac *= 10.0;
                const i32 d = static_cast<i32>(frac);
                digits[dc++] = static_cast<char8_t>(u8'0' + d);
                frac -= d;
            }
            while (dc > 0 && digits[dc - 1] == u8'0')
                --dc; // trim trailing zeros
            if (dc > 0)
            {
                out.Append(core::StringView(u8"."));
                out.Append(core::StringView(digits, dc));
            }
            return out;
        }

        Type m_type = Type::Empty;
        bool m_bool = false;
        i64 m_int = 0;
        f64 m_float = 0.0;
        core::String m_string;
        core::Color m_color{};
        core::Array<core::CurveKey> m_keys;
        ColorGradient m_gradient;
    };
}
