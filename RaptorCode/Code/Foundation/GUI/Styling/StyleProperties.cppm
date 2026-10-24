// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :style_properties partition
//
// The CSS properties the GUI knows (G2 of Specs/vg-and-gui-lab.md), as one table instead of a
// chain of string compares: each property's name, how its value parses into a typed StyleValue,
// and the shorthands that expand into longhands (`border` into twelve, `border-radius` into four)
// so the cascade works per longhand, as CSS's does. A property the table does not name may still
// reach a widget: a reflected property that declares its CSS name (the `css` property attribute)
// takes it, parsed by its type, so a library's widget gets CSS for its own properties with no
// applier code (StyleApplier).

module;
#include "Core/Prelude.h"

export module foundation.gui:style_properties;

import foundation.core;
import :css_values;
import :style_value;
import :motion; // the transition and animation shorthands' expansion

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    enum class StyleValueKind : u8
    {
        None,       ///< Not parsed (an unknown property's text, a custom property)
        Number,     ///< opacity
        Length,     ///< width, border-top-width, font-size, a corner radius
        ColorValue, ///< color, background-color, border-top-color
        Keyword,    ///< text-align, visibility, border-top-style, enabled
        Shadows,    ///< box-shadow
        Transforms, ///< transform
        Origin,     ///< transform-origin (two lengths)
        Layers,     ///< background-image
        Filters,    ///< filter, backdrop-filter
    };

    /// A declaration's value once parsed.
    struct StyleValue
    {
        StyleValueKind Kind = StyleValueKind::None;
        f32 Number = 0.0f;
        LengthValue Length{};
        Color ColorValue{};
        core::String Keyword;
        Array<ShadowValue> Shadows;
        Array<TransformFunction> Transforms;
        LengthValue OriginX{50.0f, LengthUnit::Percent};
        LengthValue OriginY{50.0f, LengthUnit::Percent};
        Array<BackgroundLayer> Layers;
        Array<FilterFunction> Filters;
    };

    /// How a property's value parses.
    enum class StyleGrammar : u8
    {
        Number,
        Length,
        Color,
        Keyword,
        Shadows,
        Transforms,
        Origin,
        Layers,
        Filters,
        TextOutline, ///< `<width> [color]`, a Shadows value (the width as the spread)
        TextGlow,    ///< `<radius> [color]`, a Shadows value (the radius as the blur)
        Text, ///< kept as written (font-family, transition, animation)
        Size, ///< a length or percentage, or auto, fit-content, min-content, max-content, none (a Keyword)
    };

    struct StylePropertySpec
    {
        const char8_t* Name;
        StyleGrammar Grammar;
        /// CSS's initial value, what `initial` sets (null: the node's own value). A property no
        /// rule sets returns to the node's own value, not to this.
        const char8_t* Initial = nullptr;
        /// Inherited, as CSS's is: a node the sheet sets none for takes its parent's.
        bool Inherited = false;
    };

    /// A longhand that changes only how a node is painted where it already is: never its place,
    /// its size or how far its drawing reaches (E8b: animating one out of view asks for no frames).
    [[nodiscard]] inline bool IsPaintOnlyStyleProperty(core::StringView name) noexcept
    {
        static constexpr const char8_t* kPaintOnly[] = {
            u8"opacity", u8"color", u8"background-color", u8"background-image", u8"border-top-color",
            u8"border-right-color", u8"border-bottom-color", u8"border-left-color", u8"caret-color", u8"accent-color"};
        for (const char8_t* p : kPaintOnly)
            if (name == core::StringView(p))
                return true;
        return false;
    }

    /// The longhands the GUI knows.
    [[nodiscard]] inline Span<const StylePropertySpec> AllStyleProperties()
    {
        static constexpr StylePropertySpec kProperties[] = {
            {u8"opacity", StyleGrammar::Number, u8"1"},
            {u8"width", StyleGrammar::Size, u8"auto"},
            {u8"height", StyleGrammar::Size, u8"auto"},
            {u8"min-width", StyleGrammar::Size, u8"auto"},
            {u8"min-height", StyleGrammar::Size, u8"auto"},
            {u8"max-width", StyleGrammar::Size, u8"none"},
            {u8"max-height", StyleGrammar::Size, u8"none"},
            {u8"padding-top", StyleGrammar::Length, u8"0"},
            {u8"padding-right", StyleGrammar::Length, u8"0"},
            {u8"padding-bottom", StyleGrammar::Length, u8"0"},
            {u8"padding-left", StyleGrammar::Length, u8"0"},
            {u8"margin-top", StyleGrammar::Length, u8"0"},
            {u8"margin-right", StyleGrammar::Length, u8"0"},
            {u8"margin-bottom", StyleGrammar::Length, u8"0"},
            {u8"margin-left", StyleGrammar::Length, u8"0"},
            {u8"margin-inline-start", StyleGrammar::Length},
            {u8"margin-inline-end", StyleGrammar::Length},
            {u8"padding-inline-start", StyleGrammar::Length},
            {u8"padding-inline-end", StyleGrammar::Length},
            {u8"inset-inline-start", StyleGrammar::Size},
            {u8"inset-inline-end", StyleGrammar::Size},
            {u8"enabled", StyleGrammar::Keyword},
            {u8"visibility", StyleGrammar::Keyword, u8"visible", true},
            {u8"color", StyleGrammar::Color, nullptr, true},
            {u8"text-align", StyleGrammar::Keyword, nullptr, true},
            {u8"vertical-align", StyleGrammar::Keyword},
            {u8"font-family", StyleGrammar::Text, nullptr, true},
            {u8"font-size", StyleGrammar::Length, nullptr, true},
            {u8"font-weight", StyleGrammar::Text, u8"normal", true},
            {u8"font-style", StyleGrammar::Keyword, u8"normal", true},
            {u8"overflow-wrap", StyleGrammar::Keyword, u8"normal", true},
            {u8"white-space", StyleGrammar::Keyword, nullptr, true},
            {u8"line-height", StyleGrammar::Text, u8"normal", true},
            {u8"letter-spacing", StyleGrammar::Text, u8"normal", true},
            {u8"direction", StyleGrammar::Keyword},
            {u8"background-color", StyleGrammar::Color, u8"transparent"},
            {u8"background-image", StyleGrammar::Layers},
            {u8"background-size", StyleGrammar::Text},
            {u8"background-position", StyleGrammar::Text},
            {u8"border-image", StyleGrammar::Text},
            {u8"border-top-width", StyleGrammar::Length},
            {u8"border-right-width", StyleGrammar::Length},
            {u8"border-bottom-width", StyleGrammar::Length},
            {u8"border-left-width", StyleGrammar::Length},
            {u8"border-top-color", StyleGrammar::Color},
            {u8"border-right-color", StyleGrammar::Color},
            {u8"border-bottom-color", StyleGrammar::Color},
            {u8"border-left-color", StyleGrammar::Color},
            {u8"border-top-style", StyleGrammar::Keyword},
            {u8"border-right-style", StyleGrammar::Keyword},
            {u8"border-bottom-style", StyleGrammar::Keyword},
            {u8"border-left-style", StyleGrammar::Keyword},
            {u8"border-top-left-radius", StyleGrammar::Length},
            {u8"border-top-right-radius", StyleGrammar::Length},
            {u8"border-bottom-right-radius", StyleGrammar::Length},
            {u8"border-bottom-left-radius", StyleGrammar::Length},
            {u8"box-shadow", StyleGrammar::Shadows, u8"none"},
            {u8"transform", StyleGrammar::Transforms},
            {u8"transform-origin", StyleGrammar::Origin},
            {u8"filter", StyleGrammar::Filters, u8"none"},
            {u8"text-shadow", StyleGrammar::Shadows},
            {u8"text-outline", StyleGrammar::TextOutline},
            {u8"text-glow", StyleGrammar::TextGlow},
            {u8"backdrop-filter", StyleGrammar::Filters, u8"none"},
            {u8"mix-blend-mode", StyleGrammar::Keyword, u8"normal"},
            // Layout (E2 of Specs/gui-lab-evolution.md): the node's box, out of flow, how it lays out
            // its children, and how its container places it.
            {u8"overflow-x", StyleGrammar::Keyword, u8"visible"},
            {u8"overflow-y", StyleGrammar::Keyword, u8"visible"},
            {u8"scroll-behavior", StyleGrammar::Keyword, u8"auto"},
            {u8"overscroll-behavior", StyleGrammar::Keyword, u8"auto"},
            {u8"scrollbar-width", StyleGrammar::Keyword, u8"auto"},
            {u8"scrollbar-visibility", StyleGrammar::Keyword, u8"auto"},
            {u8"box-sizing", StyleGrammar::Keyword},
            {u8"display", StyleGrammar::Keyword},
            {u8"position", StyleGrammar::Keyword},
            {u8"top", StyleGrammar::Size},
            {u8"right", StyleGrammar::Size},
            {u8"bottom", StyleGrammar::Size},
            {u8"left", StyleGrammar::Size},
            {u8"z-index", StyleGrammar::Number},
            {u8"flex-direction", StyleGrammar::Keyword},
            {u8"flex-wrap", StyleGrammar::Keyword},
            {u8"justify-content", StyleGrammar::Keyword},
            {u8"align-items", StyleGrammar::Keyword},
            {u8"align-content", StyleGrammar::Keyword},
            {u8"justify-items", StyleGrammar::Keyword},
            {u8"row-gap", StyleGrammar::Length},
            {u8"column-gap", StyleGrammar::Length},
            {u8"flex-grow", StyleGrammar::Number},
            {u8"flex-shrink", StyleGrammar::Number},
            {u8"flex-basis", StyleGrammar::Size},
            {u8"align-self", StyleGrammar::Keyword},
            {u8"justify-self", StyleGrammar::Keyword},
            {u8"order", StyleGrammar::Number},
            {u8"grid-template-columns", StyleGrammar::Text},
            {u8"grid-template-rows", StyleGrammar::Text},
            {u8"grid-auto-columns", StyleGrammar::Text},
            {u8"grid-auto-rows", StyleGrammar::Text},
            {u8"grid-auto-flow", StyleGrammar::Keyword},
            {u8"grid-column", StyleGrammar::Text},
            {u8"grid-row", StyleGrammar::Text},
            {u8"dock", StyleGrammar::Keyword},
            {u8"transition-property", StyleGrammar::Text},
            {u8"transition-duration", StyleGrammar::Text},
            {u8"transition-timing-function", StyleGrammar::Text},
            {u8"transition-delay", StyleGrammar::Text},
            {u8"animation-name", StyleGrammar::Text},
            {u8"animation-duration", StyleGrammar::Text},
            {u8"animation-timing-function", StyleGrammar::Text},
            {u8"animation-delay", StyleGrammar::Text},
            {u8"animation-iteration-count", StyleGrammar::Text},
            {u8"animation-direction", StyleGrammar::Text},
            {u8"animation-fill-mode", StyleGrammar::Text},
            {u8"animation-play-state", StyleGrammar::Text},
        };
        return Span<const StylePropertySpec>(kProperties, sizeof(kProperties) / sizeof(kProperties[0]));
    }
    /// A longhand the GUI knows, by name (null for one it does not).
    [[nodiscard]] inline const StylePropertySpec* FindStyleProperty(core::StringView name)
    {
        for (const StylePropertySpec& spec : AllStyleProperties())
            if (core::StringView(spec.Name) == name)
                return &spec;
        return nullptr;
    }

    /// `text` as a value of `grammar`; false when it does not parse.
    [[nodiscard]] inline bool ParseStyleValue(StyleGrammar grammar, core::StringView text, StyleValue& out)
    {
        const core::StringView v = Trim(text);
        switch (grammar)
        {
        case StyleGrammar::Number:
        {
            // A plain number, or a percentage of one (`opacity: 50%` is 0.5); a unit is no number.
            const bool percent = v.Size() > 1 && v[v.Size() - 1] == u8'%';
            const core::StringView digits = percent ? v.SubStr(0, v.Size() - 1) : v;
            for (usize i = 0; i < digits.Size(); ++i)
                if ((digits[i] >= u8'a' && digits[i] <= u8'z') || (digits[i] >= u8'A' && digits[i] <= u8'Z') || digits[i] == u8'%')
                    return false;
            if (Optional<f32> n = ParseLength(digits); n.HasValue())
            {
                out.Kind = StyleValueKind::Number;
                out.Number = percent ? n.Value() * 0.01f : n.Value();
                return true;
            }
            return false;
        }
        case StyleGrammar::Length:
            if (Optional<LengthValue> l = ParseLengthValue(v); l.HasValue())
            {
                out.Kind = StyleValueKind::Length;
                out.Length = l.Value();
                return true;
            }
            return false;
        case StyleGrammar::Color:
            if (Optional<Color> c = ParseColor(v); c.HasValue())
            {
                out.Kind = StyleValueKind::ColorValue;
                out.ColorValue = c.Value();
                return true;
            }
            return false;
        case StyleGrammar::Size:
            if (Optional<LengthValue> l = ParseLengthValue(v); l.HasValue())
            {
                out.Kind = StyleValueKind::Length;
                out.Length = l.Value();
                return true;
            }
            if (v == core::StringView(u8"auto") || v == core::StringView(u8"fit-content") || v == core::StringView(u8"min-content") ||
                v == core::StringView(u8"max-content") || v == core::StringView(u8"none"))
            {
                out.Kind = StyleValueKind::Keyword;
                out.Keyword = core::String(v);
                return true;
            }
            return false;
        case StyleGrammar::Keyword:
        case StyleGrammar::Text:
            if (v.Size() == 0)
                return false;
            out.Kind = StyleValueKind::Keyword;
            out.Keyword = core::String(v);
            return true;
        case StyleGrammar::Shadows:
            if (Optional<Array<ShadowValue>> s = ParseShadows(v); s.HasValue())
            {
                out.Kind = StyleValueKind::Shadows;
                out.Shadows = Move(s.Value());
                return true;
            }
            return false;
        case StyleGrammar::Transforms:
            if (Optional<Array<TransformFunction>> t = ParseTransforms(v); t.HasValue())
            {
                out.Kind = StyleValueKind::Transforms;
                out.Transforms = Move(t.Value());
                return true;
            }
            return false;
        case StyleGrammar::Origin:
            if (Optional<TransformOriginValue> o = ParseTransformOrigin(v); o.HasValue())
            {
                out.Kind = StyleValueKind::Origin;
                out.OriginX = o.Value().X;
                out.OriginY = o.Value().Y;
                return true;
            }
            return false;
        case StyleGrammar::Layers:
            if (Optional<Array<BackgroundLayer>> l = ParseBackgroundLayers(v); l.HasValue())
            {
                out.Kind = StyleValueKind::Layers;
                out.Layers = Move(l.Value());
                return true;
            }
            return false;
        case StyleGrammar::TextOutline:
        case StyleGrammar::TextGlow:
            if (Optional<Array<ShadowValue>> s = ParseTextEffectShadow(v, grammar == StyleGrammar::TextOutline); s.HasValue())
            {
                out.Kind = StyleValueKind::Shadows;
                out.Shadows = Move(s.Value());
                return true;
            }
            return false;
        case StyleGrammar::Filters:
            if (Optional<Array<FilterFunction>> f = ParseFilters(v); f.HasValue())
            {
                out.Kind = StyleValueKind::Filters;
                out.Filters = Move(f.Value());
                return true;
            }
            return false;
        }
        return false;
    }

    /// One longhand a declaration sets.
    struct StyleLonghand
    {
        core::String Name;
        core::String Text;
    };

    namespace detail
    {
        inline void Push(Array<StyleLonghand>& out, core::StringView name, core::StringView text)
        {
            out.PushBack(StyleLonghand{core::String(name), core::String(text)});
        }

        [[nodiscard]] inline bool IsBorderStyle(core::StringView t)
        {
            return t == core::StringView(u8"solid") || t == core::StringView(u8"none") ||
                   t == core::StringView(u8"hidden") || t == core::StringView(u8"dashed") ||
                   t == core::StringView(u8"dotted") || t == core::StringView(u8"double");
        }

        // `<width> || <style> || <color>`, any order: the three parts, CSS's initial values where
        // unsaid (medium is 3px; the colour, black here).
        [[nodiscard]] inline bool SplitBorder(core::StringView value, core::String& width, core::String& style,
                                              core::String& color)
        {
            width = core::String(u8"3px");
            style = core::String(u8"none");
            color = core::String(u8"#000000");
            bool w = false, s = false, c = false;
            for (const core::StringView token : SplitTopLevel(value, u8' '))
            {
                if (!s && IsBorderStyle(token))
                {
                    style = core::String(token);
                    s = true;
                }
                else if (!w && ParseLengthValue(token).HasValue())
                {
                    width = core::String(token);
                    w = true;
                }
                else if (!c && ParseColor(token).HasValue())
                {
                    color = core::String(token);
                    c = true;
                }
                else
                {
                    return false;
                }
            }
            return w || s || c; // no style: none, so nothing draws (CSS)
        }

        inline constexpr const char8_t* kSides[4] = {u8"top", u8"right", u8"bottom", u8"left"};
        inline constexpr const char8_t* kCorners[4] = {u8"top-left", u8"top-right", u8"bottom-right", u8"bottom-left"};

        [[nodiscard]] inline core::String Joined(const char8_t* a, const char8_t* b, const char8_t* c)
        {
            core::String s(a);
            s.Append(core::StringView(b));
            s.Append(core::StringView(c));
            return s;
        }
    }

    /// The longhands `name: text` sets: itself when it is one, its longhands when it is a
    /// shorthand (border, border-<side>, border-width, border-color, border-style, border-radius,
    /// padding, margin, margin-inline, padding-inline, inset-inline, background, transition, animation). False when a shorthand's value does not parse.
    [[nodiscard]] inline bool ExpandStyleShorthand(core::StringView name, core::StringView text,
                                                   Array<StyleLonghand>& out)
    {
        using detail::Joined;
        using detail::kSides;
        const core::StringView value = Trim(text);
        const auto sides = [&](const char8_t* prefix, const char8_t* suffix)
        {
            const Optional<Array<core::StringView>> parts =
                ParseSides<core::StringView>(value, [](core::StringView t) { return Optional<core::StringView>(t); });
            if (!parts.HasValue())
                return false;
            for (usize k = 0; k < 4; ++k)
                detail::Push(out, Joined(prefix, kSides[k], suffix).AsView(), parts.Value()[k]);
            return true;
        };
        if (name == core::StringView(u8"border"))
        {
            core::String w, s, c;
            if (!detail::SplitBorder(value, w, s, c))
                return false;
            for (const char8_t* side : kSides)
            {
                detail::Push(out, Joined(u8"border-", side, u8"-width").AsView(), w.AsView());
                detail::Push(out, Joined(u8"border-", side, u8"-style").AsView(), s.AsView());
                detail::Push(out, Joined(u8"border-", side, u8"-color").AsView(), c.AsView());
            }
            return true;
        }
        for (const char8_t* side : kSides)
        {
            if (name == Joined(u8"border-", side, u8"").AsView())
            {
                core::String w, s, c;
                if (!detail::SplitBorder(value, w, s, c))
                    return false;
                detail::Push(out, Joined(u8"border-", side, u8"-width").AsView(), w.AsView());
                detail::Push(out, Joined(u8"border-", side, u8"-style").AsView(), s.AsView());
                detail::Push(out, Joined(u8"border-", side, u8"-color").AsView(), c.AsView());
                return true;
            }
        }
        if (name == core::StringView(u8"border-width"))
            return sides(u8"border-", u8"-width");
        if (name == core::StringView(u8"border-color"))
            return sides(u8"border-", u8"-color");
        if (name == core::StringView(u8"border-style"))
            return sides(u8"border-", u8"-style");
        if (name == core::StringView(u8"padding"))
            return sides(u8"padding-", u8"");
        if (name == core::StringView(u8"inset"))
        {
            const Optional<Array<core::StringView>> parts =
                ParseSides<core::StringView>(value, [](core::StringView t) { return Optional<core::StringView>(t); });
            if (!parts.HasValue())
                return false;
            const char8_t* const kInsets[4] = {u8"top", u8"right", u8"bottom", u8"left"};
            for (usize k = 0; k < 4; ++k)
                detail::Push(out, core::StringView(kInsets[k]), parts.Value()[k]);
            return true;
        }
        if (name == core::StringView(u8"overflow") || name == core::StringView(u8"gap"))
        {
            // One value for both axes, or two: overflow's x then y, gap's row then column.
            const Array<core::StringView> parts = SplitTopLevel(value, u8' ');
            if (parts.IsEmpty() || parts.Size() > 2)
                return false;
            const bool overflow = name == core::StringView(u8"overflow");
            detail::Push(out, core::StringView(overflow ? u8"overflow-x" : u8"row-gap"), parts[0]);
            detail::Push(out, core::StringView(overflow ? u8"overflow-y" : u8"column-gap"), parts[parts.Size() - 1]);
            return true;
        }
        if (name == core::StringView(u8"flex"))
        {
            // none, auto, <grow>, <grow> <shrink>, <grow> <shrink> <basis>, <grow> <basis>, <basis>.
            const Array<core::StringView> parts = SplitTopLevel(value, u8' ');
            core::StringView grow = core::StringView(u8"0"), shrink = core::StringView(u8"1"), basis = core::StringView(u8"auto");
            if (parts.Size() == 1 && parts[0] == core::StringView(u8"none"))
                shrink = core::StringView(u8"0");
            else if (parts.Size() == 1 && parts[0] == core::StringView(u8"auto"))
                grow = core::StringView(u8"1");
            else
            {
                // A unitless number is grow, then shrink; anything else is the basis.
                const auto plainNumber = [](core::StringView t)
                {
                    if (t.Size() == 0)
                        return false;
                    for (usize i = 0; i < t.Size(); ++i)
                        if (!((t[i] >= u8'0' && t[i] <= u8'9') || t[i] == u8'.' || t[i] == u8'-' || t[i] == u8'+'))
                            return false;
                    return true;
                };
                usize numbers = 0;
                for (const core::StringView part : parts)
                {
                    if (plainNumber(part) && numbers == 0)
                    {
                        grow = part;
                        basis = core::StringView(u8"0px"); // `flex: 1` grows from nothing
                        ++numbers;
                    }
                    else if (plainNumber(part) && numbers == 1)
                    {
                        shrink = part;
                        ++numbers;
                    }
                    else
                        basis = part;
                }
            }
            detail::Push(out, core::StringView(u8"flex-grow"), grow);
            detail::Push(out, core::StringView(u8"flex-shrink"), shrink);
            detail::Push(out, core::StringView(u8"flex-basis"), basis);
            return true;
        }
        if (name == core::StringView(u8"flex-flow"))
        {
            for (const core::StringView part : SplitTopLevel(value, u8' '))
            {
                const bool wrap = part == core::StringView(u8"wrap") || part == core::StringView(u8"nowrap") ||
                                  part == core::StringView(u8"wrap-reverse");
                detail::Push(out, core::StringView(wrap ? u8"flex-wrap" : u8"flex-direction"), part);
            }
            return true;
        }
        if (name == core::StringView(u8"margin"))
            return sides(u8"margin-", u8"");
        if (name == core::StringView(u8"margin-inline") || name == core::StringView(u8"padding-inline") ||
            name == core::StringView(u8"inset-inline"))
        {
            // The inline start, then the end (one value for both).
            const Array<core::StringView> parts = SplitTopLevel(value, u8' ');
            if (parts.IsEmpty() || parts.Size() > 2)
                return false;
            core::String start(name), end(name);
            start.Append(core::StringView(u8"-start"));
            end.Append(core::StringView(u8"-end"));
            detail::Push(out, start.AsView(), parts[0]);
            detail::Push(out, end.AsView(), parts[parts.Size() - 1]);
            return true;
        }
        if (name == core::StringView(u8"border-radius"))
        {
            const Optional<Array<core::StringView>> parts =
                ParseSides<core::StringView>(value, [](core::StringView t) { return Optional<core::StringView>(t); });
            if (!parts.HasValue())
                return false;
            for (usize k = 0; k < 4; ++k)
                detail::Push(out, Joined(u8"border-", detail::kCorners[k], u8"-radius").AsView(), parts.Value()[k]);
            return true;
        }
        if (name == core::StringView(u8"transition") || name == core::StringView(u8"animation"))
        {
            Array<core::String> names, values;
            if (name == core::StringView(u8"transition"))
                ExpandTransition(value, names, values);
            else
                ExpandAnimation(value, names, values);
            for (usize i = 0; i < names.Size(); ++i)
                detail::Push(out, names[i].AsView(), values[i].AsView());
            return true;
        }
        if (name == core::StringView(u8"background"))
        {
            // Layers, the bottom one possibly a colour: the colour to background-color, the rest
            // (or none) to background-image.
            const Array<core::StringView> layers = SplitTopLevel(value, u8',');
            if (layers.IsEmpty())
                return false;
            core::StringView color = core::StringView(u8"transparent");
            usize imageCount = layers.Size();
            if (ParseColor(layers[layers.Size() - 1]).HasValue())
            {
                color = layers[layers.Size() - 1];
                --imageCount;
            }
            core::String images;
            for (usize k = 0; k < imageCount; ++k)
            {
                if (k > 0)
                    images.Append(core::StringView(u8", "));
                images.Append(layers[k]);
            }
            detail::Push(out, core::StringView(u8"background-color"), color);
            detail::Push(out, core::StringView(u8"background-image"),
                         imageCount == 0 ? core::StringView(u8"none") : images.AsView());
            return true;
        }
        detail::Push(out, name, value);
        return true;
    }
}
