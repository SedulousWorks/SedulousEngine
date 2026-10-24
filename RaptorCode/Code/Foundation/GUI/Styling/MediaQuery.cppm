// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :media_query partition
//
// MediaQuery + MediaContext: `@media` condition evaluation. Ported from eepp's css/MediaQuery
// (common subset), then widened (E13 of Specs/gui-lab-evolution-2.md): a comma list of queries
// (any one matching), each optionally `not`, a media type (`all`, `screen`; `print` never) and
// feature tests joined by `and`: width, height and resolution (min-, max-, exact), orientation,
// and the host's preferences, prefers-color-scheme, prefers-contrast and prefers-reduced-motion, and
// `input` (K2b: pointer, keyboard or pad, the kind in use). A rule carries an (optional) MediaQuery; StyleSheet::Resolve skips rules whose query does not match
// the MediaContext; a query naming any other feature matches nothing. Deferred: aspect-ratio,
// range syntax (`width >= 600px`), `or` inside a query.

module;
#include "Core/Prelude.h"

export module foundation.gui:media_query;

import foundation.core; // StringView, Array, f32
import :css_values;   // ParseLength
import :event;        // InputKind

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// How much contrast the user asks for (CSS's prefers-contrast).
    enum class ContrastPreference : u8
    {
        NoPreference,
        More,
        Less,
    };

    // The environment a media query is evaluated against: the viewport, and what the host knows of
    // the user's preferences (its platform's dark mode, contrast and reduced-motion settings).
    struct MediaContext
    {
        f32 Width = 0.0f;
        f32 Height = 0.0f;
        f32 Dpi = 96.0f;
        bool DarkScheme = true; ///< prefers-color-scheme: dark (else light)
        ContrastPreference Contrast = ContrastPreference::NoPreference;
        bool ReducedMotion = false; ///< prefers-reduced-motion: reduce
        InputKind Input = InputKind::Pointer; ///< `input`: what drives the GUI now (K2b)
        [[nodiscard]] bool operator==(const MediaContext&) const noexcept = default;
    };

    enum class MediaFeatureType
    {
        MinWidth,
        MaxWidth,
        MinHeight,
        MaxHeight,
        Width,
        Height,
        MinResolution, ///< in dpi: 1dppx (1x) is 96dpi
        MaxResolution,
        Resolution,
        Portrait,      ///< orientation: portrait (height at least width)
        Landscape,
        Dark,          ///< prefers-color-scheme
        Light,
        ContrastMore,  ///< prefers-contrast
        ContrastLess,
        ContrastNone,  ///< prefers-contrast: no-preference
        ContrastAny,   ///< (prefers-contrast): any preference
        ReduceMotion,  ///< prefers-reduced-motion: reduce
        NoMotionPreference,
        InputPointer,  ///< input: pointer (K2b: the input kind in use, not a device's presence)
        InputKeyboard,
        InputPad,
    };

    struct MediaFeature
    {
        MediaFeatureType Type;
        f32 Value = 0.0f;
    };

    // A list of queries, any one of which matching matches; each a conjunction of feature tests,
    // perhaps negated. An empty list always matches; a query with a feature the GUI does not know
    // never does (CSS's "not all"), so a rule written for a feature it cannot test is not applied
    // everywhere.
    class MediaQuery
    {
    public:
        MediaQuery() = default;
        explicit MediaQuery(core::StringView text) { Parse(text); }

        [[nodiscard]] bool IsEmpty() const noexcept { return m_queries.IsEmpty(); }
        /// The feature tests of every query in the list.
        [[nodiscard]] usize FeatureCount() const noexcept
        {
            usize n = 0;
            for (const Query& q : m_queries)
                n += q.Features.Size();
            return n;
        }

        [[nodiscard]] bool Evaluate(const MediaContext& context) const
        {
            if (m_queries.IsEmpty())
                return true;
            for (const Query& q : m_queries)
                if (EvaluateQuery(q, context))
                    return true;
            return false;
        }

    private:
        struct Query
        {
            Array<MediaFeature> Features;
            bool Not = false;
            bool Never = false; // a feature it cannot test, or a type it is not (print): false, and `not` does not save it
        };

        [[nodiscard]] static bool EvaluateQuery(const Query& q, const MediaContext& c)
        {
            if (q.Never)
                return false;
            bool all = true;
            for (const MediaFeature& f : q.Features)
                all = all && EvaluateFeature(f, c);
            return all != q.Not;
        }

        [[nodiscard]] static bool EvaluateFeature(const MediaFeature& f,
                                                  const MediaContext& c) noexcept
        {
            switch (f.Type)
            {
            case MediaFeatureType::MinWidth:
                return c.Width >= f.Value;
            case MediaFeatureType::MaxWidth:
                return c.Width <= f.Value;
            case MediaFeatureType::MinHeight:
                return c.Height >= f.Value;
            case MediaFeatureType::MaxHeight:
                return c.Height <= f.Value;
            case MediaFeatureType::Width:
                return c.Width == f.Value;
            case MediaFeatureType::Height:
                return c.Height == f.Value;
            case MediaFeatureType::MinResolution:
                return c.Dpi >= f.Value;
            case MediaFeatureType::MaxResolution:
                return c.Dpi <= f.Value;
            case MediaFeatureType::Resolution:
                return c.Dpi == f.Value;
            case MediaFeatureType::Portrait:
                return c.Height >= c.Width;
            case MediaFeatureType::Landscape:
                return c.Width > c.Height;
            case MediaFeatureType::Dark:
                return c.DarkScheme;
            case MediaFeatureType::Light:
                return !c.DarkScheme;
            case MediaFeatureType::ContrastMore:
                return c.Contrast == ContrastPreference::More;
            case MediaFeatureType::ContrastLess:
                return c.Contrast == ContrastPreference::Less;
            case MediaFeatureType::ContrastNone:
                return c.Contrast == ContrastPreference::NoPreference;
            case MediaFeatureType::ContrastAny:
                return c.Contrast != ContrastPreference::NoPreference;
            case MediaFeatureType::ReduceMotion:
                return c.ReducedMotion;
            case MediaFeatureType::NoMotionPreference:
                return !c.ReducedMotion;
            case MediaFeatureType::InputPointer:
                return c.Input == InputKind::Pointer;
            case MediaFeatureType::InputKeyboard:
                return c.Input == InputKind::Keyboard;
            case MediaFeatureType::InputPad:
                return c.Input == InputKind::Pad;
            }
            return true;
        }

        void Parse(core::StringView text)
        {
            // A comma list: each part a query (commas inside parentheses are the feature's own).
            usize start = 0;
            usize depth = 0;
            for (usize i = 0; i <= text.Size(); ++i)
            {
                if (i < text.Size() && text[i] == u8'(')
                    ++depth;
                else if (i < text.Size() && text[i] == u8')' && depth > 0)
                    --depth;
                else if (i == text.Size() || (text[i] == u8',' && depth == 0))
                {
                    const core::StringView part = core::Trim(text.SubStr(start, i - start));
                    if (part.Size() != 0)
                        m_queries.PushBack(ParseQuery(part));
                    start = i + 1;
                }
            }
        }

        [[nodiscard]] static Query ParseQuery(core::StringView text)
        {
            Query q;
            usize i = 0;
            const usize n = text.Size();
            // Words before and between the groups: `not`, `only`, a media type, `and`.
            const auto word = [&](core::StringView w)
            {
                if (w == core::StringView(u8"not"))
                    q.Not = true;
                else if (w == core::StringView(u8"print"))
                    q.Never = true;
                else if (w != core::StringView(u8"and") && w != core::StringView(u8"only") && w != core::StringView(u8"all") &&
                         w != core::StringView(u8"screen"))
                    q.Never = true; // a type or a keyword it does not know
            };
            while (i < n)
            {
                while (i < n && text[i] == u8' ')
                    ++i;
                if (i >= n)
                    break;
                if (text[i] != u8'(')
                {
                    const usize start = i;
                    while (i < n && text[i] != u8' ' && text[i] != u8'(')
                        ++i;
                    word(text.SubStr(start, i - start));
                    continue;
                }
                ++i;
                const usize start = i;
                while (i < n && text[i] != u8')')
                    ++i;
                if (!ParseFeature(text.SubStr(start, i - start), q.Features))
                    q.Never = true;
                if (i < n)
                    ++i; // skip ')'
            }
            return q;
        }

        // One "(feature: value)" or "(feature)" group; false for one it cannot test.
        [[nodiscard]] static bool ParseFeature(core::StringView group, Array<MediaFeature>& out)
        {
            usize colon = group.Size();
            for (usize i = 0; i < group.Size(); ++i)
                if (group[i] == u8':')
                {
                    colon = i;
                    break;
                }
            const core::StringView name = core::Trim(group.SubStr(0, colon));
            const core::StringView text = colon < group.Size() ? core::Trim(group.SubStr(colon + 1, group.Size() - colon - 1)) : core::StringView{};
            const auto keyword = [&](MediaFeatureType type)
            {
                out.PushBack(MediaFeature{type, 0.0f});
                return true;
            };
            if (name == core::StringView(u8"orientation"))
            {
                if (text == core::StringView(u8"portrait"))
                    return keyword(MediaFeatureType::Portrait);
                if (text == core::StringView(u8"landscape"))
                    return keyword(MediaFeatureType::Landscape);
                return false;
            }
            if (name == core::StringView(u8"prefers-color-scheme"))
            {
                if (text == core::StringView(u8"dark"))
                    return keyword(MediaFeatureType::Dark);
                if (text == core::StringView(u8"light"))
                    return keyword(MediaFeatureType::Light);
                return false;
            }
            if (name == core::StringView(u8"prefers-contrast"))
            {
                if (text.Size() == 0)
                    return keyword(MediaFeatureType::ContrastAny);
                if (text == core::StringView(u8"more"))
                    return keyword(MediaFeatureType::ContrastMore);
                if (text == core::StringView(u8"less"))
                    return keyword(MediaFeatureType::ContrastLess);
                if (text == core::StringView(u8"no-preference"))
                    return keyword(MediaFeatureType::ContrastNone);
                return false;
            }
            if (name == core::StringView(u8"input"))
            {
                if (text == core::StringView(u8"pointer"))
                    return keyword(MediaFeatureType::InputPointer);
                if (text == core::StringView(u8"keyboard"))
                    return keyword(MediaFeatureType::InputKeyboard);
                if (text == core::StringView(u8"pad"))
                    return keyword(MediaFeatureType::InputPad);
                return false;
            }
            if (name == core::StringView(u8"prefers-reduced-motion"))
            {
                if (text.Size() == 0 || text == core::StringView(u8"reduce"))
                    return keyword(MediaFeatureType::ReduceMotion);
                if (text == core::StringView(u8"no-preference"))
                    return keyword(MediaFeatureType::NoMotionPreference);
                return false;
            }
            if (colon >= group.Size())
                return false; // another boolean feature: none is known

            const bool resolution = name == core::StringView(u8"min-resolution") ||
                                    name == core::StringView(u8"max-resolution") ||
                                    name == core::StringView(u8"resolution");
            const Optional<f32> value = resolution ? ParseResolution(text) : ParseLength(text);
            if (!value.HasValue())
                return false;

            MediaFeatureType type;
            if (name == core::StringView(u8"min-width"))
                type = MediaFeatureType::MinWidth;
            else if (name == core::StringView(u8"max-width"))
                type = MediaFeatureType::MaxWidth;
            else if (name == core::StringView(u8"min-height"))
                type = MediaFeatureType::MinHeight;
            else if (name == core::StringView(u8"max-height"))
                type = MediaFeatureType::MaxHeight;
            else if (name == core::StringView(u8"width"))
                type = MediaFeatureType::Width;
            else if (name == core::StringView(u8"height"))
                type = MediaFeatureType::Height;
            else if (name == core::StringView(u8"min-resolution"))
                type = MediaFeatureType::MinResolution;
            else if (name == core::StringView(u8"max-resolution"))
                type = MediaFeatureType::MaxResolution;
            else if (name == core::StringView(u8"resolution"))
                type = MediaFeatureType::Resolution;
            else
                return false; // a feature it does not know

            out.PushBack(MediaFeature{type, value.Value()});
            return true;
        }

        // `2dppx`, `2x` or `192dpi`, in dpi.
        [[nodiscard]] static Optional<f32> ParseResolution(core::StringView text)
        {
            const auto number = [&](usize suffix) { return ParseLength(text.SubStr(0, text.Size() - suffix)); };
            const auto endsWith = [&](const char8_t* unit)
            {
                const core::StringView u(unit);
                return text.Size() > u.Size() && text.SubStr(text.Size() - u.Size(), u.Size()) == u;
            };
            if (endsWith(u8"dppx"))
                if (Optional<f32> n = number(4); n.HasValue())
                    return n.Value() * 96.0f;
            if (endsWith(u8"dpi"))
                return number(3);
            if (endsWith(u8"x"))
                if (Optional<f32> n = number(1); n.HasValue())
                    return n.Value() * 96.0f;
            return {};
        }

        Array<Query> m_queries;
    };
}
