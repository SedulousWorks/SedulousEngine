// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :css_values partition
//
// CSS value parsers: turn declaration value strings into typed values (color / length /
// bool / thickness). Ported from eepp's css value parsing (common subset). Number parsing
// is a small local scanner (core has no general string->float). Colors: named, #hex
// (#rgb/#rrggbb/#rrggbbaa), and rgb()/rgba().

module;
#include "Core/Prelude.h"

export module foundation.gui:css_values;

import foundation.core; // Color, Optional, StringView, f32
import foundation.vg;   // CornerRadii
import :thickness;

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    [[nodiscard]] inline Optional<Color> ParseNamedColor(core::StringView s); // defined below

    // Parse a decimal number (ignores a trailing unit like "px"/"%"). Empty if none.
    [[nodiscard]] inline Optional<f32> ParseLength(core::StringView value)
    {
        const core::StringView s = Trim(value);
        if (s.Size() == 0)
            return {};
        usize i = 0;
        f32 sign = 1.0f;
        if (s[i] == u8'+')
            ++i;
        else if (s[i] == u8'-')
        {
            sign = -1.0f;
            ++i;
        }

        f64 whole = 0.0;
        bool any = false;
        while (i < s.Size() && IsDigit(s[i]))
        {
            whole = whole * 10.0 + static_cast<f64>(s[i] - u8'0');
            ++i;
            any = true;
        }
        f64 frac = 0.0, scale = 1.0;
        if (i < s.Size() && s[i] == u8'.')
        {
            ++i;
            while (i < s.Size() && IsDigit(s[i]))
            {
                frac = frac * 10.0 + static_cast<f64>(s[i] - u8'0');
                scale *= 10.0;
                ++i;
                any = true;
            }
        }
        if (!any)
            return {};
        return static_cast<f32>(sign * (whole + frac / scale));
    }

    // === Length units (px / em / rem / vw / vh / %) ===
    enum class LengthUnit
    {
        Px,
        Em,
        Rem,
        Vw,
        Vh,
        Percent,
        Calc, ///< calc() (E13 of Specs/gui-lab-evolution-2.md): a sum of the units above, in Terms
    };
    inline constexpr usize kLengthUnitCount = 6; ///< the units a calc() sums (all but Calc)

    struct LengthValue
    {
        f32 Value = 0.0f;
        LengthUnit Unit = LengthUnit::Px;
        /// A calc()'s amount of each unit (Px to Percent): calc(100% - 2em + 4px) is 100 of
        /// Percent, -2 of Em and 4 of Px. Unused for a plain length.
        f32 Terms[kLengthUnitCount]{};

        /// Any length as its terms (a plain one: its value in its unit).
        constexpr void ToTerms(f32 (&out)[kLengthUnitCount]) const noexcept
        {
            for (usize i = 0; i < kLengthUnitCount; ++i)
                out[i] = Unit == LengthUnit::Calc ? Terms[i] : 0.0f;
            if (Unit != LengthUnit::Calc)
                out[static_cast<usize>(Unit)] = Value;
        }
        /// Its percentage part (a plain percentage's value; a calc()'s percent term).
        [[nodiscard]] constexpr f32 PercentPart() const noexcept
        {
            return Unit == LengthUnit::Calc ? Terms[static_cast<usize>(LengthUnit::Percent)] : Unit == LengthUnit::Percent ? Value : 0.0f;
        }
        [[nodiscard]] static constexpr LengthValue FromTerms(const f32 (&terms)[kLengthUnitCount]) noexcept
        {
            LengthValue v;
            v.Value = 1.0f; // never "a zero", which converts to any unit
            v.Unit = LengthUnit::Calc;
            for (usize i = 0; i < kLengthUnitCount; ++i)
                v.Terms[i] = terms[i];
            return v;
        }
        [[nodiscard]] constexpr bool operator==(const LengthValue& o) const noexcept
        {
            if (Unit != o.Unit)
                return false;
            if (Unit != LengthUnit::Calc)
                return Value == o.Value;
            for (usize i = 0; i < kLengthUnitCount; ++i)
                if (Terms[i] != o.Terms[i])
                    return false;
            return true;
        }
    };

    // Resolution context: root/element font sizes (for rem/em) and the viewport (for vw/vh).
    struct LengthContext
    {
        f32 RootFontSize = 16.0f;
        f32 ElementFontSize = 16.0f;
        f32 ViewportWidth = 0.0f;
        f32 ViewportHeight = 0.0f;
    };

    // Parse a number with an optional unit suffix: "12", "12px", "1.5rem", "2em", "50vw",
    // "80vh", "50%". Unitless is treated as px. An unrecognized unit yields nothing.
    namespace detail
    {
        // calc()'s grammar over a linear sum of units (E13): + and - between terms, * and / by a
        // plain number, parentheses and nested calc(). Each value is its terms and whether it is a
        // plain number (what * and / need on one side).
        struct CalcValue
        {
            f32 Terms[kLengthUnitCount]{};
            f32 Number = 0.0f;
            bool IsNumber = false;
        };
        class CalcParser
        {
        public:
            explicit CalcParser(core::StringView text) : m_text(text) {}
            [[nodiscard]] bool Parse(CalcValue& out)
            {
                if (!Sum(out))
                    return false;
                Skip();
                return m_at == m_text.Size();
            }

        private:
            void Skip()
            {
                while (m_at < m_text.Size() && (m_text[m_at] == u8' ' || m_text[m_at] == u8'\t'))
                    ++m_at;
            }
            bool Sum(CalcValue& out)
            {
                if (!Product(out))
                    return false;
                for (;;)
                {
                    Skip();
                    if (m_at >= m_text.Size() || (m_text[m_at] != u8'+' && m_text[m_at] != u8'-'))
                        return true;
                    const bool minus = m_text[m_at++] == u8'-';
                    CalcValue rhs;
                    if (!Product(rhs) || rhs.IsNumber != out.IsNumber)
                        return false; // a number and a length do not add
                    const f32 sign = minus ? -1.0f : 1.0f;
                    out.Number += sign * rhs.Number;
                    for (usize i = 0; i < kLengthUnitCount; ++i)
                        out.Terms[i] += sign * rhs.Terms[i];
                }
            }
            bool Product(CalcValue& out)
            {
                if (!Factor(out))
                    return false;
                for (;;)
                {
                    Skip();
                    if (m_at >= m_text.Size() || (m_text[m_at] != u8'*' && m_text[m_at] != u8'/'))
                        return true;
                    const bool divide = m_text[m_at++] == u8'/';
                    CalcValue rhs;
                    if (!Factor(rhs))
                        return false;
                    if (divide)
                    {
                        if (!rhs.IsNumber || rhs.Number == 0.0f)
                            return false;
                        Scale(out, 1.0f / rhs.Number);
                    }
                    else if (rhs.IsNumber)
                        Scale(out, rhs.Number);
                    else if (out.IsNumber)
                    {
                        const f32 by = out.Number;
                        out = rhs;
                        Scale(out, by);
                    }
                    else
                        return false; // a length times a length
                }
            }
            static void Scale(CalcValue& v, f32 by)
            {
                v.Number *= by;
                for (f32& t : v.Terms)
                    t *= by;
            }
            bool Factor(CalcValue& out)
            {
                Skip();
                if (m_at < m_text.Size() && m_text[m_at] == u8'(')
                    return Group(out);
                if (m_text.SubStr(m_at, core::Min<usize>(5, m_text.Size() - m_at)) == core::StringView(u8"calc("))
                {
                    m_at += 4;
                    return Group(out);
                }
                usize end = m_at;
                if (end < m_text.Size() && (m_text[end] == u8'+' || m_text[end] == u8'-'))
                    ++end;
                while (end < m_text.Size() && (IsDigit(m_text[end]) || m_text[end] == u8'.'))
                    ++end;
                const Optional<f32> number = ParseLength(m_text.SubStr(m_at, end - m_at));
                if (!number.HasValue())
                    return false;
                usize unitEnd = end;
                while (unitEnd < m_text.Size() && ((m_text[unitEnd] >= u8'a' && m_text[unitEnd] <= u8'z') || m_text[unitEnd] == u8'%'))
                    ++unitEnd;
                const core::StringView unit = m_text.SubStr(end, unitEnd - end);
                m_at = unitEnd;
                out = CalcValue{};
                if (unit.Size() == 0)
                {
                    out.IsNumber = true;
                    out.Number = number.Value();
                    return true;
                }
                static constexpr const char8_t* kUnits[kLengthUnitCount] = {u8"px", u8"em", u8"rem", u8"vw", u8"vh", u8"%"};
                for (usize i = 0; i < kLengthUnitCount; ++i)
                    if (unit == core::StringView(kUnits[i]))
                    {
                        out.Terms[i] = number.Value();
                        return true;
                    }
                return false;
            }
            bool Group(CalcValue& out)
            {
                ++m_at; // '('
                if (!Sum(out))
                    return false;
                Skip();
                if (m_at >= m_text.Size() || m_text[m_at] != u8')')
                    return false;
                ++m_at;
                return true;
            }
            core::StringView m_text;
            usize m_at = 0;
        };
    }

    /// A calc() expression's length (E13): `calc(100% - 2 * 8px)`. Empty when it does not parse or
    /// comes to a plain number (a length is wanted).
    [[nodiscard]] inline Optional<LengthValue> ParseCalcLength(core::StringView value)
    {
        const core::StringView s = Trim(value);
        if (s.Size() < 6 || s.SubStr(0, 5) != core::StringView(u8"calc(") || s[s.Size() - 1] != u8')')
            return {};
        detail::CalcValue calc;
        detail::CalcParser parser(s.SubStr(4, s.Size() - 4)); // "(...)": the group
        if (!parser.Parse(calc))
            return {};
        if (calc.IsNumber)
            return calc.Number == 0.0f ? Optional<LengthValue>(LengthValue{}) : Optional<LengthValue>{};
        return LengthValue::FromTerms(calc.Terms);
    }

    [[nodiscard]] inline Optional<LengthValue> ParseLengthValue(core::StringView value)
    {
        const core::StringView s = Trim(value);
        if (s.Size() == 0)
            return {};
        if (s.Size() > 5 && s.SubStr(0, 5) == core::StringView(u8"calc("))
            return ParseCalcLength(s);
        usize i = 0;
        if (s[i] == u8'+' || s[i] == u8'-')
            ++i;
        while (i < s.Size() && IsDigit(s[i]))
            ++i;
        if (i < s.Size() && s[i] == u8'.')
        {
            ++i;
            while (i < s.Size() && IsDigit(s[i]))
                ++i;
        }

        const Optional<f32> num = ParseLength(s.SubStr(0, i));
        if (!num.HasValue())
            return {};

        const core::StringView suffix = Trim(s.SubStr(i, s.Size() - i));
        LengthUnit unit = LengthUnit::Px;
        if (suffix.Size() == 0 || suffix == core::StringView(u8"px"))
            unit = LengthUnit::Px;
        else if (suffix == core::StringView(u8"rem"))
            unit = LengthUnit::Rem;
        else if (suffix == core::StringView(u8"em"))
            unit = LengthUnit::Em;
        else if (suffix == core::StringView(u8"vw"))
            unit = LengthUnit::Vw;
        else if (suffix == core::StringView(u8"vh"))
            unit = LengthUnit::Vh;
        else if (suffix == core::StringView(u8"%"))
            unit = LengthUnit::Percent;
        else
            return {};
        return LengthValue{num.Value(), unit};
    }

    // Resolve a length to pixels. `percentBase` is the value 100% maps to (the caller supplies
    // the relevant containing dimension); 0 if unknown.
    [[nodiscard]] inline f32 ResolveLengthValue(LengthValue lv, const LengthContext& ctx,
                                                f32 percentBase = 0.0f)
    {
        switch (lv.Unit)
        {
        case LengthUnit::Px:
            return lv.Value;
        case LengthUnit::Em:
            return lv.Value * ctx.ElementFontSize;
        case LengthUnit::Rem:
            return lv.Value * ctx.RootFontSize;
        case LengthUnit::Vw:
            return lv.Value * ctx.ViewportWidth / 100.0f;
        case LengthUnit::Vh:
            return lv.Value * ctx.ViewportHeight / 100.0f;
        case LengthUnit::Percent:
            return lv.Value * percentBase / 100.0f;
        case LengthUnit::Calc:
        {
            f32 sum = 0.0f;
            for (usize i = 0; i < kLengthUnitCount; ++i)
                if (lv.Terms[i] != 0.0f)
                {
                    LengthValue term;
                    term.Value = lv.Terms[i];
                    term.Unit = static_cast<LengthUnit>(i);
                    sum += ResolveLengthValue(term, ctx, percentBase);
                }
            return sum;
        }
        }
        return lv.Value;
    }

    // Parse + resolve a length string to pixels.
    [[nodiscard]] inline Optional<f32>
    ResolveLength(core::StringView value, const LengthContext& ctx, f32 percentBase = 0.0f)
    {
        const Optional<LengthValue> lv = ParseLengthValue(value);
        if (!lv.HasValue())
            return {};
        return ResolveLengthValue(lv.Value(), ctx, percentBase);
    }

    [[nodiscard]] inline Optional<bool> ParseBool(core::StringView value)
    {
        const core::StringView s = Trim(value);
        if (s == core::StringView(u8"true") || s == core::StringView(u8"1") ||
            s == core::StringView(u8"yes"))
            return true;
        if (s == core::StringView(u8"false") || s == core::StringView(u8"0") ||
            s == core::StringView(u8"no"))
            return false;
        return {};
    }

    namespace detail
    {
        // The arguments of a colour function, split at commas or, failing that, spaces (a `/`
        // before an alpha read as a separator).
        inline usize ColorArguments(core::StringView inside, core::StringView (&out)[4])
        {
            bool comma = false;
            for (usize i = 0; i < inside.Size(); ++i)
                comma = comma || inside[i] == u8',';
            usize n = 0;
            usize start = 0;
            for (usize i = 0; i <= inside.Size() && n < 4; ++i)
            {
                const bool split = i == inside.Size() || (comma ? inside[i] == u8',' : (inside[i] == u8' ' || inside[i] == u8'/'));
                if (!split)
                    continue;
                const core::StringView part = Trim(inside.SubStr(start, i - start));
                if (part.Size() != 0)
                    out[n++] = part;
                start = i + 1;
            }
            return n;
        }
        // A number, or a percentage as its fraction of `full` (an alpha: of 1; a saturation: of 100).
        inline Optional<f32> NumberOrPercent(core::StringView t, f32 full)
        {
            if (t.Size() > 1 && t[t.Size() - 1] == u8'%')
            {
                const Optional<f32> v = ParseLength(t.SubStr(0, t.Size() - 1));
                return v.HasValue() ? Optional<f32>(v.Value() * full / 100.0f) : Optional<f32>{};
            }
            return ParseLength(t);
        }
        // hsl() to rgb (CSS Color 4's algorithm), hue in degrees, saturation and lightness 0 to 1.
        inline Color HslToRgb(f32 h, f32 s, f32 l, f32 a)
        {
            h = h - 360.0f * static_cast<f32>(static_cast<i32>(h / 360.0f));
            if (h < 0.0f)
                h += 360.0f;
            const auto f = [&](f32 n)
            {
                f32 k = n + h / 30.0f;
                k = k - 12.0f * static_cast<f32>(static_cast<i32>(k / 12.0f));
                const f32 amount = s * Min(l, 1.0f - l);
                return l - amount * Max(-1.0f, Min(Min(k - 3.0f, 9.0f - k), 1.0f));
            };
            return Color{f(0.0f), f(8.0f), f(4.0f), a};
        }
    }

    [[nodiscard]] inline Optional<Color> ParseColor(core::StringView value)
    {
        const core::StringView s = Trim(value);
        if (s.Size() == 0)
            return {};
        const auto function = [&](const char8_t* name, core::StringView& inside)
        {
            const core::StringView n(name);
            if (s.Size() <= n.Size() + 1 || s.SubStr(0, n.Size()) != n || s[n.Size()] != u8'(' || s[s.Size() - 1] != u8')')
                return false;
            inside = s.SubStr(n.Size() + 1, s.Size() - n.Size() - 2);
            return true;
        };
        core::StringView inside;
        // hsl() / hsla() (E13 of Specs/gui-lab-evolution-2.md): hue in degrees (deg or none),
        // saturation and lightness as percentages, alpha a number or a percentage.
        if (function(u8"hsl", inside) || function(u8"hsla", inside))
        {
            core::StringView args[4];
            const usize n = detail::ColorArguments(inside, args);
            if (n < 3)
                return {};
            core::StringView hue = args[0];
            if (hue.Size() > 3 && hue.SubStr(hue.Size() - 3, 3) == core::StringView(u8"deg"))
                hue = hue.SubStr(0, hue.Size() - 3);
            const Optional<f32> h = ParseLength(hue);
            const Optional<f32> sat = detail::NumberOrPercent(args[1], 100.0f);
            const Optional<f32> light = detail::NumberOrPercent(args[2], 100.0f);
            const Optional<f32> alpha = n > 3 ? detail::NumberOrPercent(args[3], 1.0f) : Optional<f32>(1.0f);
            if (!h.HasValue() || !sat.HasValue() || !light.HasValue() || !alpha.HasValue())
                return {};
            return detail::HslToRgb(h.Value(), Clamp(sat.Value() / 100.0f, 0.0f, 1.0f), Clamp(light.Value() / 100.0f, 0.0f, 1.0f),
                                    Clamp(alpha.Value(), 0.0f, 1.0f));
        }
        // color-mix(in srgb, A [p%], B [q%]) (E13): premultiplied by alpha, the percentages made to
        // sum to 100 (one left out is the rest; a sum under 100 scales the alpha).
        if (function(u8"color-mix", inside))
        {
            core::StringView parts[3];
            usize n = 0, start = 0, depth = 0;
            for (usize i = 0; i <= inside.Size() && n < 3; ++i)
            {
                if (i < inside.Size() && inside[i] == u8'(')
                    ++depth;
                else if (i < inside.Size() && inside[i] == u8')' && depth > 0)
                    --depth;
                else if (i == inside.Size() || (inside[i] == u8',' && depth == 0))
                {
                    parts[n++] = Trim(inside.SubStr(start, i - start));
                    start = i + 1;
                }
            }
            if (n != 3 || (parts[0] != core::StringView(u8"in srgb") && parts[0] != core::StringView(u8"in srgb-linear")))
                return {};
            Color colors[2];
            Optional<f32> amounts[2];
            for (usize k = 0; k < 2; ++k)
            {
                core::StringView part = parts[k + 1];
                usize space = part.Size();
                for (usize i = part.Size(); i-- > 0;)
                    if (part[i] == u8' ')
                    {
                        space = i;
                        break;
                    }
                if (space < part.Size() && part[part.Size() - 1] == u8'%')
                {
                    amounts[k] = detail::NumberOrPercent(part.SubStr(space + 1, part.Size() - space - 1), 100.0f);
                    part = Trim(part.SubStr(0, space));
                }
                const Optional<Color> c = ParseColor(part);
                if (!c.HasValue())
                    return {};
                colors[k] = c.Value();
            }
            f32 p1 = amounts[0].HasValue() ? amounts[0].Value() : (amounts[1].HasValue() ? 100.0f - amounts[1].Value() : 50.0f);
            f32 p2 = amounts[1].HasValue() ? amounts[1].Value() : 100.0f - p1;
            const f32 sum = p1 + p2;
            if (sum <= 0.0f)
                return {};
            const f32 scaleAlpha = Min(sum, 100.0f) / 100.0f;
            p1 /= sum;
            p2 /= sum;
            const f32 a = colors[0].a * p1 + colors[1].a * p2;
            if (a <= 0.0f)
                return Color{0.0f, 0.0f, 0.0f, 0.0f};
            const auto channel = [&](f32 x, f32 y) { return (x * colors[0].a * p1 + y * colors[1].a * p2) / a; };
            return Color{channel(colors[0].r, colors[1].r), channel(colors[0].g, colors[1].g), channel(colors[0].b, colors[1].b),
                         a * scaleAlpha};
        }

        // #hex
        if (s[0] == u8'#')
        {
            const core::StringView hex = s.SubStr(1, s.Size() - 1);
            const usize len = hex.Size();
            auto nib = [&](usize k) { return HexValue(hex[k]); };
            f32 r = 0, g = 0, b = 0, a = 1.0f;
            if (len == 3)
            {
                const i32 hr = nib(0), hg = nib(1), hb = nib(2);
                if (hr < 0 || hg < 0 || hb < 0)
                    return {};
                r = (hr * 17) / 255.0f;
                g = (hg * 17) / 255.0f;
                b = (hb * 17) / 255.0f;
            }
            else if (len == 6 || len == 8)
            {
                for (usize k = 0; k < len; ++k)
                    if (nib(k) < 0)
                        return {};
                r = (nib(0) * 16 + nib(1)) / 255.0f;
                g = (nib(2) * 16 + nib(3)) / 255.0f;
                b = (nib(4) * 16 + nib(5)) / 255.0f;
                if (len == 8)
                    a = (nib(6) * 16 + nib(7)) / 255.0f;
            }
            else
            {
                return {};
            }
            return Color{r, g, b, a};
        }

        // rgb() / rgba()
        const bool rgba = (s.Size() > 5 && s.SubStr(0, 5) == core::StringView(u8"rgba("));
        const bool rgb = (s.Size() > 4 && s.SubStr(0, 4) == core::StringView(u8"rgb("));
        if (rgb || rgba)
        {
            const usize open = rgba ? 5 : 4;
            usize close = open;
            while (close < s.Size() && s[close] != u8')')
                ++close;
            const core::StringView inside = s.SubStr(open, close - open);
            f32 comps[4] = {0, 0, 0, 1.0f};
            usize ci = 0, start = 0;
            for (usize i = 0; i <= inside.Size() && ci < 4; ++i)
            {
                if (i == inside.Size() || inside[i] == u8',')
                {
                    const Optional<f32> v = ParseLength(inside.SubStr(start, i - start));
                    if (!v.HasValue())
                        return {};
                    comps[ci] = ci < 3 ? (v.Value() / 255.0f) : v.Value(); // alpha is 0..1
                    ++ci;
                    start = i + 1;
                }
            }
            return Color{comps[0], comps[1], comps[2], comps[3]};
        }

        // named
        return ParseNamedColor(s);
    }

    // 1-4 whitespace-separated lengths in CSS shorthand order (top / right / bottom / left).
    [[nodiscard]] inline Optional<Thickness> ParseThickness(core::StringView value)
    {
        f32 parts[4];
        usize count = 0, start = 0;
        const core::StringView s = Trim(value);
        for (usize i = 0; i <= s.Size(); ++i)
        {
            const bool boundary = (i == s.Size()) || IsWhiteSpace(s[i]);
            if (boundary)
            {
                if (i > start)
                {
                    if (count == 4)
                        return {}; // too many
                    const Optional<f32> v = ParseLength(s.SubStr(start, i - start));
                    if (!v.HasValue())
                        return {};
                    parts[count++] = v.Value();
                }
                start = i + 1;
            }
        }
        if (count == 0)
            return {};

        f32 top, right, bottom, left;
        if (count == 1)
        {
            top = right = bottom = left = parts[0];
        }
        else if (count == 2)
        {
            top = bottom = parts[0];
            right = left = parts[1];
        }
        else if (count == 3)
        {
            top = parts[0];
            right = left = parts[1];
            bottom = parts[2];
        }
        else
        {
            top = parts[0];
            right = parts[1];
            bottom = parts[2];
            left = parts[3];
        }
        return Thickness{left, top, right, bottom};
    }

    // border-radius: 1-4 lengths in CSS corner order (top-left, top-right, bottom-right,
    // bottom-left; 1 = all, 2 = TL/BR + TR/BL, 3 = TL, TR/BL, BR).
    [[nodiscard]] inline Optional<vg::CornerRadii> ParseCornerRadii(core::StringView value)
    {
        f32 parts[4];
        usize count = 0, start = 0;
        const core::StringView s = Trim(value);
        for (usize i = 0; i <= s.Size(); ++i)
        {
            const bool boundary = (i == s.Size()) || IsWhiteSpace(s[i]);
            if (boundary)
            {
                if (i > start)
                {
                    if (count == 4)
                        return {};
                    const Optional<f32> v = ParseLength(s.SubStr(start, i - start));
                    if (!v.HasValue())
                        return {};
                    parts[count++] = v.Value();
                }
                start = i + 1;
            }
        }
        if (count == 0)
            return {};

        f32 tl, tr, br, bl;
        if (count == 1)
        {
            tl = tr = br = bl = parts[0];
        }
        else if (count == 2)
        {
            tl = br = parts[0];
            tr = bl = parts[1];
        }
        else if (count == 3)
        {
            tl = parts[0];
            tr = bl = parts[1];
            br = parts[2];
        }
        else
        {
            tl = parts[0];
            tr = parts[1];
            br = parts[2];
            bl = parts[3];
        }
        return vg::CornerRadii{tl, tr, br, bl};
    }

    // The `border` shorthand: any order of a width (a length), a style keyword (ignored - only
    // solid is drawn), and a color. Missing width defaults to 1; missing color to black. A
    // leading "none"/"0" yields width 0. Returns width + color.
    struct BorderShorthand
    {
        f32 Width = 1.0f;
        Color LineColor{0.0f, 0.0f, 0.0f, 1.0f};
    };
    [[nodiscard]] inline Optional<BorderShorthand> ParseBorder(core::StringView value)
    {
        BorderShorthand out;
        bool any = false;
        const core::StringView s = Trim(value);
        usize start = 0;
        for (usize i = 0; i <= s.Size(); ++i)
        {
            const bool boundary = (i == s.Size()) || IsWhiteSpace(s[i]);
            if (!boundary)
                continue;
            if (i > start)
            {
                const core::StringView tok = s.SubStr(start, i - start);
                if (tok == core::StringView(u8"none"))
                {
                    out.Width = 0.0f;
                    any = true;
                }
                else if (tok == core::StringView(u8"solid") ||
                         tok == core::StringView(u8"dashed") ||
                         tok == core::StringView(u8"dotted") || tok == core::StringView(u8"hidden"))
                {
                    any = true;
                }
                else if (Optional<Color> c = ParseColor(tok); c.HasValue())
                {
                    out.LineColor = c.Value();
                    any = true;
                }
                else if (Optional<f32> w = ParseLength(tok); w.HasValue())
                {
                    out.Width = w.Value();
                    any = true;
                }
            }
            start = i + 1;
        }
        if (!any)
            return {};
        return out;
    }

    // Like ParseThickness, but each component is unit-resolved against `ctx` (no % support -
    // padding/margin percentages are a follow-up needing the containing block).
    [[nodiscard]] inline Optional<Thickness> ResolveThickness(core::StringView value,
                                                              const LengthContext& ctx)
    {
        f32 parts[4];
        usize count = 0, start = 0;
        const core::StringView s = Trim(value);
        for (usize i = 0; i <= s.Size(); ++i)
        {
            const bool boundary = (i == s.Size()) || IsWhiteSpace(s[i]);
            if (boundary)
            {
                if (i > start)
                {
                    if (count == 4)
                        return {};
                    const Optional<f32> v = ResolveLength(s.SubStr(start, i - start), ctx);
                    if (!v.HasValue())
                        return {};
                    parts[count++] = v.Value();
                }
                start = i + 1;
            }
        }
        if (count == 0)
            return {};

        f32 top, right, bottom, left;
        if (count == 1)
        {
            top = right = bottom = left = parts[0];
        }
        else if (count == 2)
        {
            top = bottom = parts[0];
            right = left = parts[1];
        }
        else if (count == 3)
        {
            top = parts[0];
            right = left = parts[1];
            bottom = parts[2];
        }
        else
        {
            top = parts[0];
            right = parts[1];
            bottom = parts[2];
            left = parts[3];
        }
        return Thickness{left, top, right, bottom};
    }

    // A small named-color set (core has only White/Black/Red/Green/Blue/Transparent).
    [[nodiscard]] inline Optional<Color> ParseNamedColor(core::StringView s)
    {
        if (s == core::StringView(u8"white"))
            return Color::White;
        if (s == core::StringView(u8"black"))
            return Color::Black;
        if (s == core::StringView(u8"red"))
            return Color::Red;
        if (s == core::StringView(u8"green"))
            return Color::Green;
        if (s == core::StringView(u8"blue"))
            return Color::Blue;
        if (s == core::StringView(u8"transparent"))
            return Color::Transparent;
        if (s == core::StringView(u8"yellow"))
            return Color{1.0f, 1.0f, 0.0f, 1.0f};
        if (s == core::StringView(u8"cyan"))
            return Color{0.0f, 1.0f, 1.0f, 1.0f};
        if (s == core::StringView(u8"magenta"))
            return Color{1.0f, 0.0f, 1.0f, 1.0f};
        if (s == core::StringView(u8"gray") || s == core::StringView(u8"grey"))
            return Color{0.5f, 0.5f, 0.5f, 1.0f};
        if (s == core::StringView(u8"orange"))
            return Color{1.0f, 0.647f, 0.0f, 1.0f};
        return {};
    }
}
