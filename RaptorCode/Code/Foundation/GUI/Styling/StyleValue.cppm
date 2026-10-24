// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :style_value partition
//
// Typed CSS values (G2 of Specs/vg-and-gui-lab.md): what a declaration becomes once parsed, so
// a sheet parses each declaration once and the cascade, the applier and (G3) transitions work on
// values, not text. Also the value grammars the box properties need: lists split at top-level
// commas and spaces, angles, box shadows, transform functions, gradients and their stops, and
// var() substitution anywhere in a value (nested, partial, with fallbacks).

module;
#include "Core/Prelude.h"

export module foundation.gui:style_value;

import foundation.core;
import foundation.vg; // CornerRadii
import :css_values;   // LengthValue, ParseLengthValue, ParseColor
import :parse_util;   // IsIdentChar
import :transform2d;  // ComposeTransforms

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    // === Splitting ===

    /// The parts of `value` separated by `separator` at the top level (outside parentheses and
    /// quotes), trimmed, empty parts dropped. A space separator splits at any whitespace run.
    [[nodiscard]] inline Array<core::StringView> SplitTopLevel(core::StringView value, char8_t separator)
    {
        Array<core::StringView> parts;
        i32 depth = 0;
        char8_t quote = 0;
        usize start = 0;
        const auto isSeparator = [separator](char8_t c)
        { return separator == u8' ' ? IsWhiteSpace(c) : c == separator; };
        for (usize i = 0; i <= value.Size(); ++i)
        {
            const bool end = i == value.Size();
            const char8_t c = end ? char8_t{0} : value[i];
            if (!end && quote != 0)
            {
                if (c == quote)
                    quote = 0;
                continue;
            }
            if (!end && (c == u8'"' || c == u8'\''))
            {
                quote = c;
                continue;
            }
            if (!end && c == u8'(')
            {
                ++depth;
                continue;
            }
            if (!end && c == u8')')
            {
                --depth;
                continue;
            }
            if (end || (depth == 0 && isSeparator(c)))
            {
                const core::StringView part = Trim(value.SubStr(start, i - start));
                if (part.Size() != 0)
                    parts.PushBack(part);
                start = i + 1;
            }
        }
        return parts;
    }

    /// `name(arguments)`: true with the name and what is between the parentheses.
    [[nodiscard]] inline bool SplitFunction(core::StringView value, core::StringView& name, core::StringView& arguments)
    {
        const core::StringView v = Trim(value);
        usize open = 0;
        while (open < v.Size() && v[open] != u8'(')
            ++open;
        if (open == 0 || open >= v.Size() || v[v.Size() - 1] != u8')')
            return false;
        name = Trim(v.SubStr(0, open));
        arguments = Trim(v.SubStr(open + 1, v.Size() - open - 2));
        return true;
    }

    // === var() ===

    /// Substitutes every var(--name[, fallback]) in `value`, anywhere and nested, through
    /// `lookup` (a custom property's value, or empty when it has none), whose result is itself
    /// substituted. False when a reference has no value and no fallback, or the references run
    /// deeper than a cycle could (the declaration is then invalid, as CSS has it).
    [[nodiscard]] inline bool SubstituteVariables(core::StringView value,
                                                  const core::Function<Optional<core::String>(core::StringView)>& lookup,
                                                  core::String& out, i32 depth = 0)
    {
        if (depth > 16)
            return false;
        out.Clear();
        usize i = 0;
        while (i < value.Size())
        {
            const bool atVar = i + 4 <= value.Size() && value.SubStr(i, 4) == core::StringView(u8"var(") &&
                               (i == 0 || !IsIdentChar(value[i - 1]));
            if (!atVar)
            {
                out.PushBack(value[i]);
                ++i;
                continue;
            }
            // The reference's extent: its matching parenthesis, and its first top-level comma.
            usize close = i + 4;
            usize comma = 0;
            i32 nesting = 1;
            while (close < value.Size() && nesting > 0)
            {
                if (value[close] == u8'(')
                    ++nesting;
                else if (value[close] == u8')')
                    --nesting;
                else if (value[close] == u8',' && nesting == 1 && comma == 0)
                    comma = close;
                if (nesting > 0)
                    ++close;
            }
            if (close >= value.Size())
                return false; // unbalanced
            const usize nameEnd = comma != 0 ? comma : close;
            const core::StringView name = Trim(value.SubStr(i + 4, nameEnd - i - 4));
            core::String resolved;
            if (Optional<core::String> found = lookup(name); found.HasValue())
            {
                if (!SubstituteVariables(found.Value().AsView(), lookup, resolved, depth + 1))
                    return false;
            }
            else if (comma != 0)
            {
                if (!SubstituteVariables(Trim(value.SubStr(comma + 1, close - comma - 1)), lookup, resolved, depth + 1))
                    return false;
            }
            else
            {
                return false;
            }
            out.Append(resolved.AsView());
            i = close + 1;
        }
        return true;
    }

    // === Angles ===

    /// `90deg`, `1.5rad`, `0.25turn`, `100grad`, or a bare 0, in radians.
    [[nodiscard]] inline Optional<f32> ParseAngle(core::StringView value)
    {
        const core::StringView v = Trim(value);
        const auto number = [&](usize suffix) { return ParseLength(v.SubStr(0, v.Size() - suffix)); };
        const auto endsWith = [&](const char8_t* unit)
        {
            const core::StringView u(unit);
            return v.Size() > u.Size() && v.SubStr(v.Size() - u.Size(), u.Size()) == u;
        };
        constexpr f32 kPi = 3.14159265358979f;
        if (endsWith(u8"deg"))
            if (Optional<f32> n = number(3); n.HasValue())
                return n.Value() * kPi / 180.0f;
        if (endsWith(u8"grad"))
            if (Optional<f32> n = number(4); n.HasValue())
                return n.Value() * kPi / 200.0f;
        if (endsWith(u8"rad"))
            if (Optional<f32> n = number(3); n.HasValue())
                return n.Value();
        if (endsWith(u8"turn"))
            if (Optional<f32> n = number(4); n.HasValue())
                return n.Value() * 2.0f * kPi;
        if (v == core::StringView(u8"0"))
            return 0.0f;
        return {};
    }

    // === Box shadows ===

    struct ShadowValue
    {
        LengthValue OffsetX{};
        LengthValue OffsetY{};
        LengthValue Blur{};
        LengthValue Spread{};
        Color ShadowColor{0.0f, 0.0f, 0.0f, 0.5f};
        bool Inset = false;

        [[nodiscard]] bool operator==(const ShadowValue& o) const noexcept
        {
            const auto same = [](LengthValue a, LengthValue b) { return a == b; };
            return same(OffsetX, o.OffsetX) && same(OffsetY, o.OffsetY) && same(Blur, o.Blur) &&
                   same(Spread, o.Spread) && ShadowColor == o.ShadowColor && Inset == o.Inset;
        }
    };

    /// `box-shadow`: `none`, or a comma list of `[inset] <x> <y> [blur [spread]] [color]` (the
    /// keyword and the colour in either place). An empty list for none.
    [[nodiscard]] inline Optional<Array<ShadowValue>> ParseShadows(core::StringView value)
    {
        Array<ShadowValue> shadows;
        if (Trim(value) == core::StringView(u8"none"))
            return shadows;
        for (const core::StringView layer : SplitTopLevel(value, u8','))
        {
            ShadowValue shadow;
            LengthValue lengths[4];
            usize count = 0;
            bool colored = false;
            for (const core::StringView token : SplitTopLevel(layer, u8' '))
            {
                if (token == core::StringView(u8"inset"))
                {
                    shadow.Inset = true;
                    continue;
                }
                if (Optional<LengthValue> length = ParseLengthValue(token); length.HasValue())
                {
                    if (count == 4)
                        return {};
                    lengths[count++] = length.Value();
                    continue;
                }
                Optional<Color> color = ParseColor(token);
                if (!color.HasValue() || colored)
                    return {};
                shadow.ShadowColor = color.Value();
                colored = true;
            }
            if (count < 2)
                return {};
            shadow.OffsetX = lengths[0];
            shadow.OffsetY = lengths[1];
            if (count > 2)
                shadow.Blur = lengths[2];
            if (count > 3)
                shadow.Spread = lengths[3];
            if (shadow.Blur.Value < 0.0f)
                return {};
            shadows.PushBack(shadow);
        }
        return shadows;
    }

    // === Filters ===

    /// The filter functions the GUI draws (through VG's layers): a Gaussian blur so far. Others
    /// (brightness, drop-shadow, ...) need a colour pass VG does not have yet, so a list naming
    /// one does not parse.
    enum class FilterKind : u8
    {
        Blur, // Amount: the Gaussian's standard deviation, a length
    };

    struct FilterFunction
    {
        FilterKind Kind = FilterKind::Blur;
        LengthValue Amount{};

        [[nodiscard]] bool operator==(const FilterFunction& o) const noexcept
        {
            return Kind == o.Kind && Amount == o.Amount;
        }
    };

    /// `filter` and `backdrop-filter`: `none` (an empty list), or functions separated by spaces:
    /// `blur(<length>)` (no length: 0; negative: invalid).
    [[nodiscard]] inline Optional<Array<FilterFunction>> ParseFilters(core::StringView value)
    {
        Array<FilterFunction> filters;
        if (Trim(value) == core::StringView(u8"none"))
            return filters;
        const Array<core::StringView> tokens = SplitTopLevel(value, u8' ');
        if (tokens.IsEmpty())
            return {};
        for (const core::StringView token : tokens)
        {
            core::StringView name, arguments;
            if (!SplitFunction(token, name, arguments))
                return {};
            FilterFunction f;
            if (name == core::StringView(u8"blur"))
            {
                f.Kind = FilterKind::Blur;
                if (Trim(arguments).Size() != 0)
                {
                    const Optional<LengthValue> amount = ParseLengthValue(arguments);
                    if (!amount.HasValue() || amount.Value().Value < 0.0f || amount.Value().Unit == LengthUnit::Percent)
                        return {};
                    f.Amount = amount.Value();
                }
            }
            else
            {
                return {};
            }
            filters.PushBack(f);
        }
        return filters;
    }

    /// `text-outline: <width> [color]` and `text-glow: <radius> [color]` (either order), as a
    /// one-shadow list so they interpolate as shadows do: the outline's width rides as the spread,
    /// the glow's radius as the blur (as foundation.ui reads them). `none`: an empty list.
    [[nodiscard]] inline Optional<Array<ShadowValue>> ParseTextEffectShadow(core::StringView value, bool outline)
    {
        Array<ShadowValue> shadows;
        if (Trim(value) == core::StringView(u8"none"))
            return shadows;
        ShadowValue shadow;
        shadow.ShadowColor = outline ? Color{0.0f, 0.0f, 0.0f, 1.0f} : Color{1.0f, 1.0f, 1.0f, 1.0f};
        bool sized = false, colored = false;
        for (const core::StringView token : SplitTopLevel(value, u8' '))
        {
            if (Optional<LengthValue> length = ParseLengthValue(token); length.HasValue() && !sized)
            {
                if (length.Value().Value < 0.0f)
                    return {};
                (outline ? shadow.Spread : shadow.Blur) = length.Value();
                sized = true;
                continue;
            }
            Optional<Color> color = ParseColor(token);
            if (!color.HasValue() || colored)
                return {};
            shadow.ShadowColor = color.Value();
            colored = true;
        }
        if (!sized)
            return {};
        shadows.PushBack(shadow);
        return shadows;
    }

    // === Transforms ===

    enum class TransformKind : u8
    {
        Translate, // A, B: lengths (percentages of the element's own size)
        Rotate,    // Angle
        Scale,     // ScaleX, ScaleY
        Skew,      // Angle (x), AngleY
        Matrix,    // M[6]: a, b, c, d, e, f
    };

    struct TransformFunction
    {
        TransformKind Kind = TransformKind::Translate;
        LengthValue A{};
        LengthValue B{};
        f32 Angle = 0.0f;
        f32 AngleY = 0.0f;
        f32 ScaleX = 1.0f;
        f32 ScaleY = 1.0f;
        f32 M[6] = {1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f};
    };

    /// `transform`: `none`, or a space list of translate(x[, y]), translateX/Y, rotate(a),
    /// scale(s[, s]), scaleX/Y, skew(ax[, ay]), skewX/Y and matrix(a, b, c, d, e, f), applied
    /// left to right. An empty list for none.
    [[nodiscard]] inline Optional<Array<TransformFunction>> ParseTransforms(core::StringView value)
    {
        Array<TransformFunction> functions;
        if (Trim(value) == core::StringView(u8"none"))
            return functions;
        for (const core::StringView token : SplitTopLevel(value, u8' '))
        {
            core::StringView name, arguments;
            if (!SplitFunction(token, name, arguments))
                return {};
            const Array<core::StringView> args = SplitTopLevel(arguments, u8',');
            TransformFunction function;
            const auto length = [&](usize k, LengthValue& out)
            {
                if (k >= args.Size())
                    return false;
                const Optional<LengthValue> v = ParseLengthValue(args[k]);
                if (!v.HasValue())
                    return false;
                out = v.Value();
                return true;
            };
            const auto number = [&](usize k, f32& out)
            {
                if (k >= args.Size())
                    return false;
                const Optional<f32> v = ParseLength(args[k]);
                if (!v.HasValue())
                    return false;
                out = v.Value();
                return true;
            };
            const auto angle = [&](usize k, f32& out)
            {
                if (k >= args.Size())
                    return false;
                const Optional<f32> v = ParseAngle(args[k]);
                if (!v.HasValue())
                    return false;
                out = v.Value();
                return true;
            };
            bool ok = false;
            if (name == core::StringView(u8"translate"))
            {
                function.Kind = TransformKind::Translate;
                ok = length(0, function.A) && (args.Size() == 1 || length(1, function.B)) && args.Size() <= 2;
            }
            else if (name == core::StringView(u8"translateX"))
            {
                function.Kind = TransformKind::Translate;
                ok = args.Size() == 1 && length(0, function.A);
            }
            else if (name == core::StringView(u8"translateY"))
            {
                function.Kind = TransformKind::Translate;
                ok = args.Size() == 1 && length(0, function.B);
            }
            else if (name == core::StringView(u8"rotate"))
            {
                function.Kind = TransformKind::Rotate;
                ok = args.Size() == 1 && angle(0, function.Angle);
            }
            else if (name == core::StringView(u8"scale"))
            {
                function.Kind = TransformKind::Scale;
                ok = number(0, function.ScaleX) && args.Size() <= 2;
                function.ScaleY = function.ScaleX;
                ok = ok && (args.Size() == 1 || number(1, function.ScaleY));
            }
            else if (name == core::StringView(u8"scaleX"))
            {
                function.Kind = TransformKind::Scale;
                ok = args.Size() == 1 && number(0, function.ScaleX);
            }
            else if (name == core::StringView(u8"scaleY"))
            {
                function.Kind = TransformKind::Scale;
                ok = args.Size() == 1 && number(0, function.ScaleY);
            }
            else if (name == core::StringView(u8"skew"))
            {
                function.Kind = TransformKind::Skew;
                ok = angle(0, function.Angle) && args.Size() <= 2 && (args.Size() == 1 || angle(1, function.AngleY));
            }
            else if (name == core::StringView(u8"skewX"))
            {
                function.Kind = TransformKind::Skew;
                ok = args.Size() == 1 && angle(0, function.Angle);
            }
            else if (name == core::StringView(u8"skewY"))
            {
                function.Kind = TransformKind::Skew;
                ok = args.Size() == 1 && angle(0, function.AngleY);
            }
            else if (name == core::StringView(u8"matrix"))
            {
                function.Kind = TransformKind::Matrix;
                ok = args.Size() == 6;
                for (usize k = 0; ok && k < 6; ++k)
                    ok = number(k, function.M[k]);
            }
            if (!ok)
                return {};
            functions.PushBack(function);
        }
        return functions;
    }

    struct TransformOriginValue
    {
        LengthValue X{50.0f, LengthUnit::Percent};
        LengthValue Y{50.0f, LengthUnit::Percent};
    };

    /// A translation's or an origin's length in the box's units: a percentage of `size`, anything
    /// else as written (pixels).
    [[nodiscard]] inline f32 ResolveAgainst(LengthValue v, f32 size) noexcept
    {
        if (v.Unit == LengthUnit::Calc) // its pixels and percentage (E13)
            return v.Terms[static_cast<usize>(LengthUnit::Px)] + v.Terms[static_cast<usize>(LengthUnit::Percent)] * size / 100.0f;
        return v.Unit == LengthUnit::Percent ? v.Value * size / 100.0f : v.Value;
    }

    /// The matrix a transform list makes for a box of `size`: its functions applied left to right.
    [[nodiscard]] inline Transform2D ComposeTransforms(const Array<TransformFunction>& functions, core::Float2 size)
    {
        Transform2D m;
        for (const TransformFunction& f : functions)
        {
            switch (f.Kind)
            {
            case TransformKind::Translate:
                m.Translate(ResolveAgainst(f.A, size.x), ResolveAgainst(f.B, size.y));
                break;
            case TransformKind::Rotate:
                m.Rotate(f.Angle);
                break;
            case TransformKind::Scale:
                m.Scale(f.ScaleX, f.ScaleY);
                break;
            case TransformKind::Skew:
                m.Combine(Transform2D{1.0f, Tan(f.AngleY), Tan(f.Angle), 1.0f, 0.0f, 0.0f});
                break;
            case TransformKind::Matrix:
                m.Combine(Transform2D{f.M[0], f.M[1], f.M[2], f.M[3], f.M[4], f.M[5]});
                break;
            }
        }
        return m;
    }

    /// `transform-origin`: one or two of a length, a percentage, or left / center / right
    /// (horizontal) and top / center / bottom (vertical); 50% 50% where unsaid.
    [[nodiscard]] inline Optional<TransformOriginValue> ParseTransformOrigin(core::StringView value)
    {
        LengthValue x{50.0f, LengthUnit::Percent};
        LengthValue y{50.0f, LengthUnit::Percent};
        const Array<core::StringView> tokens = SplitTopLevel(value, u8' ');
        if (tokens.IsEmpty() || tokens.Size() > 2)
            return {};
        bool xSet = false, ySet = false;
        for (usize k = 0; k < tokens.Size(); ++k)
        {
            const core::StringView t = tokens[k];
            if (t == core::StringView(u8"left") || t == core::StringView(u8"right"))
            {
                x = LengthValue{t == core::StringView(u8"left") ? 0.0f : 100.0f, LengthUnit::Percent};
                xSet = true;
            }
            else if (t == core::StringView(u8"top") || t == core::StringView(u8"bottom"))
            {
                y = LengthValue{t == core::StringView(u8"top") ? 0.0f : 100.0f, LengthUnit::Percent};
                ySet = true;
            }
            else if (t == core::StringView(u8"center"))
            {
            }
            else if (Optional<LengthValue> length = ParseLengthValue(t); length.HasValue())
            {
                if (k == 0 && !xSet)
                {
                    x = length.Value();
                    xSet = true;
                }
                else if (!ySet)
                {
                    y = length.Value();
                    ySet = true;
                }
                else
                {
                    return {};
                }
            }
            else
            {
                return {};
            }
        }
        return TransformOriginValue{x, y};
    }

    // === Gradients ===

    enum class GradientKind : u8
    {
        Linear,
        Radial,
        Conic,
    };

    struct GradientStopValue
    {
        Color StopColor{};
        f32 Position = -1.0f; ///< A fraction of the gradient line; negative: spaced evenly (CSS).
    };

    struct GradientValue
    {
        GradientKind Kind = GradientKind::Linear;
        f32 Angle = 3.14159265358979f; ///< Linear: the CSS angle (0 up, clockwise; 180deg is down). Conic: from.
        bool Repeating = false;
        Array<GradientStopValue> Stops;
    };

    /// The stops with every position settled, as CSS does: the first at 0 and the last at 1 when
    /// unsaid, the ones between spaced evenly, and none before the one ahead of it.
    [[nodiscard]] inline Array<GradientStopValue> SettleStops(const Array<GradientStopValue>& stops)
    {
        Array<GradientStopValue> out = stops;
        if (out.IsEmpty())
            return out;
        if (out[0].Position < 0.0f)
            out[0].Position = 0.0f;
        if (out.Size() > 1 && out[out.Size() - 1].Position < 0.0f)
            out[out.Size() - 1].Position = 1.0f;
        for (usize i = 1; i < out.Size(); ++i)
            if (out[i].Position >= 0.0f && out[i].Position < out[i - 1].Position)
                out[i].Position = out[i - 1].Position;
        for (usize i = 1; i < out.Size(); ++i)
        {
            if (out[i].Position >= 0.0f)
                continue;
            usize next = i;
            while (out[next].Position < 0.0f)
                ++next;
            const f32 from = out[i - 1].Position;
            const f32 to = out[next].Position;
            for (usize k = i; k < next; ++k)
                out[k].Position = from + (to - from) * static_cast<f32>(k - i + 1) / static_cast<f32>(next - i + 1);
        }
        return out;
    }

    /// linear-gradient([<angle> | to <side or corner>,] stops), radial-gradient([<shape or
    /// position>,] stops) and conic-gradient([from <angle>,] stops), and their repeating-
    /// forms; a stop is `<color> [<percentage>]`.
    [[nodiscard]] inline Optional<GradientValue> ParseGradient(core::StringView value)
    {
        core::StringView name, arguments;
        if (!SplitFunction(value, name, arguments))
            return {};
        GradientValue gradient;
        core::StringView kind = name;
        if (kind.Size() > 10 && kind.SubStr(0, 10) == core::StringView(u8"repeating-"))
        {
            gradient.Repeating = true;
            kind = kind.SubStr(10, kind.Size() - 10);
        }
        if (kind == core::StringView(u8"linear-gradient"))
            gradient.Kind = GradientKind::Linear;
        else if (kind == core::StringView(u8"radial-gradient"))
            gradient.Kind = GradientKind::Radial;
        else if (kind == core::StringView(u8"conic-gradient"))
            gradient.Kind = GradientKind::Conic;
        else
            return {};
        if (gradient.Kind == GradientKind::Conic)
            gradient.Angle = 0.0f;

        const Array<core::StringView> parts = SplitTopLevel(arguments, u8',');
        usize first = 0;
        if (!parts.IsEmpty() && !ParseColor(SplitTopLevel(parts[0], u8' ')[0]).HasValue())
        {
            // A leading direction (linear), shape (radial, drawn as a circle) or start angle (conic).
            const core::StringView lead = parts[0];
            if (gradient.Kind == GradientKind::Linear)
            {
                if (Optional<f32> a = ParseAngle(lead); a.HasValue())
                {
                    gradient.Angle = a.Value();
                }
                else
                {
                    const Array<core::StringView> words = SplitTopLevel(lead, u8' ');
                    if (words.IsEmpty() || words[0] != core::StringView(u8"to"))
                        return {};
                    f32 dx = 0.0f, dy = 0.0f;
                    for (usize k = 1; k < words.Size(); ++k)
                    {
                        if (words[k] == core::StringView(u8"top"))
                            dy = -1.0f;
                        else if (words[k] == core::StringView(u8"bottom"))
                            dy = 1.0f;
                        else if (words[k] == core::StringView(u8"left"))
                            dx = -1.0f;
                        else if (words[k] == core::StringView(u8"right"))
                            dx = 1.0f;
                        else
                            return {};
                    }
                    if (dx == 0.0f && dy == 0.0f)
                        return {};
                    // The CSS angle: 0 points up, clockwise.
                    gradient.Angle = Atan2(dx, -dy);
                }
            }
            else if (gradient.Kind == GradientKind::Conic)
            {
                const Array<core::StringView> words = SplitTopLevel(lead, u8' ');
                if (words.Size() != 2 || words[0] != core::StringView(u8"from"))
                    return {};
                const Optional<f32> a = ParseAngle(words[1]);
                if (!a.HasValue())
                    return {};
                gradient.Angle = a.Value();
            }
            // A radial gradient's shape and position are read as a circle at the centre.
            first = 1;
        }
        for (usize k = first; k < parts.Size(); ++k)
        {
            const Array<core::StringView> words = SplitTopLevel(parts[k], u8' ');
            if (words.IsEmpty() || words.Size() > 2)
                return {};
            const Optional<Color> color = ParseColor(words[0]);
            if (!color.HasValue())
                return {};
            GradientStopValue stop;
            stop.StopColor = color.Value();
            if (words.Size() == 2)
            {
                const Optional<LengthValue> at = ParseLengthValue(words[1]);
                if (!at.HasValue() || at.Value().Unit != LengthUnit::Percent)
                    return {};
                stop.Position = at.Value().Value / 100.0f;
            }
            gradient.Stops.PushBack(stop);
        }
        if (gradient.Stops.Size() < 2)
            return {};
        return gradient;
    }

    // === Backgrounds ===

    enum class BackgroundKind : u8
    {
        Color,
        Gradient,
        Image,
    };

    struct BackgroundLayer
    {
        BackgroundKind Kind = BackgroundKind::Color;
        Color LayerColor{};
        GradientValue Gradient;
        core::String Image; ///< An image path (url()).
    };

    /// `background` / `background-image`: `none`, or a comma list of layers, the first on top,
    /// each a colour (the bottom one only, in CSS), a gradient, or url(path).
    [[nodiscard]] inline Optional<Array<BackgroundLayer>> ParseBackgroundLayers(core::StringView value)
    {
        Array<BackgroundLayer> layers;
        if (Trim(value) == core::StringView(u8"none"))
            return layers;
        for (const core::StringView part : SplitTopLevel(value, u8','))
        {
            BackgroundLayer layer;
            core::StringView name, arguments;
            if (SplitFunction(part, name, arguments) && name == core::StringView(u8"url"))
            {
                core::StringView path = arguments;
                if (path.Size() >= 2 && (path[0] == u8'"' || path[0] == u8'\'') && path[path.Size() - 1] == path[0])
                    path = path.SubStr(1, path.Size() - 2);
                layer.Kind = BackgroundKind::Image;
                layer.Image = core::String(path);
            }
            else if (Optional<GradientValue> gradient = ParseGradient(part); gradient.HasValue())
            {
                layer.Kind = BackgroundKind::Gradient;
                layer.Gradient = Move(gradient.Value());
            }
            else if (Optional<Color> color = ParseColor(part); color.HasValue())
            {
                layer.Kind = BackgroundKind::Color;
                layer.LayerColor = color.Value();
            }
            else
            {
                return {};
            }
            layers.PushBack(Move(layer));
        }
        return layers;
    }

    // === Side and corner lists ===

    /// One to four values for top, right, bottom, left (CSS's side order and fill-in), parsed by
    /// `parse`.
    template <typename T, typename Parse>
    [[nodiscard]] Optional<Array<T>> ParseSides(core::StringView value, Parse&& parse)
    {
        const Array<core::StringView> tokens = SplitTopLevel(value, u8' ');
        if (tokens.IsEmpty() || tokens.Size() > 4)
            return {};
        Array<T> parsed;
        for (const core::StringView token : tokens)
        {
            Optional<T> v = parse(token);
            if (!v.HasValue())
                return {};
            parsed.PushBack(v.Value());
        }
        Array<T> sides;
        const usize n = parsed.Size();
        sides.PushBack(parsed[0]);                             // top
        sides.PushBack(parsed[n > 1 ? 1 : 0]);                 // right
        sides.PushBack(parsed[n > 2 ? 2 : 0]);                 // bottom
        sides.PushBack(parsed[n > 3 ? 3 : (n > 1 ? 1 : 0)]);   // left
        return sides;
    }
}
