// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :text_runs partition
//
// Rich text as runs: styled spans of text and inline icons, and the small markup that writes them,
// the same from markup and from script:
//
//   Your mark wears [color=#d04060][b]a rose gown[/b][/color] [icon=Icons/rose.png] [link=hint]?[/link]
//
// Tags: [b] bold, [i] italic, [u] underline, [color=#rrggbb | #rrggbbaa | name | rgb()],
// [size=<px>], [font=<family>], [link=<id>] (a span the label reports when clicked),
// [outline=<width> [colour]], [shadow=<x> <y> [blur] [colour]], [glow=<radius> [colour]] (text
// effects, drawn under the span's glyphs; a width or radius of 0 turns one off), each closed by
// [/name] or [/] (the innermost); [icon=<image path>] stands alone. "[[" is a literal "[". A tag
// that is malformed or unknown, or a close that matches nothing, is kept as text and reported in
// the diagnostics, never dropped.
//
// Copied from foundation.ui's :text_runs (E4 of Specs/gui-lab-evolution.md), and the GUI's own from
// then on: its names follow the GUI's, and colours parse as the GUI's sheets parse them.

module;
#include "Core/Prelude.h"

export module foundation.gui:text_runs;

import foundation.core; // String, StringView, Array, Optional, Function, Color, ParseFloat
import foundation.vg;   // TextEffects
import :css_values;     // ParseColor

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// The parts of TextEffects a run may set apart from each other.
    enum TextEffectPart : u8
    {
        TextEffectOutline = 1,
        TextEffectShadow = 2,
        TextEffectGlow = 4,
    };

    /// One styled span of a rich text, or an inline icon. A style field left unset takes the
    /// label's (its font family, size and text colour).
    struct TextRun
    {
        core::String Text;
        core::String Icon; ///< An image path: an inline icon sitting on the baseline (Text is empty).
        Optional<core::String> Family;
        Optional<f32> Size;
        Optional<Color> TextColor;
        bool Bold = false;
        bool Italic = false;
        bool Underline = false;
        core::String Link; ///< A link id the label reports when the run is clicked; empty for none.
        /// The effects the markup set, those parts named in EffectParts (TextEffectPart); the parts
        /// left out take the label's.
        vg::TextEffects Effects;
        u8 EffectParts = 0;

        [[nodiscard]] bool IsIcon() const noexcept { return Icon.Size() != 0; }
        /// Whether it sets nothing of its own: it draws in the label's font and colour.
        [[nodiscard]] bool IsPlain() const noexcept
        {
            return !Family.HasValue() && !Size.HasValue() && !TextColor.HasValue() && !Bold && !Italic && !Underline &&
                   Link.Size() == 0 && EffectParts == 0 && !IsIcon();
        }
        /// Same style (and link), so two runs may merge.
        [[nodiscard]] bool SameStyle(const TextRun& other) const
        {
            return !IsIcon() && !other.IsIcon() && Family == other.Family && Size == other.Size &&
                   TextColor == other.TextColor && Bold == other.Bold && Italic == other.Italic &&
                   Underline == other.Underline && Link == other.Link && EffectParts == other.EffectParts &&
                   Effects == other.Effects;
        }
        /// `inherited` (the label's effects) with the parts this run sets in their place.
        [[nodiscard]] vg::TextEffects EffectsOver(const vg::TextEffects& inherited) const
        {
            vg::TextEffects out = inherited;
            if ((EffectParts & TextEffectOutline) != 0)
            {
                out.outlineWidth = Effects.outlineWidth;
                out.outlineColor = Effects.outlineColor;
            }
            if ((EffectParts & TextEffectShadow) != 0)
            {
                out.shadowOffset = Effects.shadowOffset;
                out.shadowBlur = Effects.shadowBlur;
                out.shadowColor = Effects.shadowColor;
            }
            if ((EffectParts & TextEffectGlow) != 0)
            {
                out.glowRadius = Effects.glowRadius;
                out.glowColor = Effects.glowColor;
            }
            return out;
        }
    };

    /// A markup problem: where, in bytes, and what. The offending text stays in the runs.
    struct TextMarkupDiagnostic
    {
        usize Offset = 0;
        core::String Message;
    };

    /// A rich text: its runs in order, and what parsing its markup reported.
    struct TextDocument
    {
        Array<TextRun> Runs;
        Array<TextMarkupDiagnostic> Diagnostics;

        /// One run of plain text (what a label without markup holds).
        [[nodiscard]] static TextDocument Plain(core::StringView text)
        {
            TextDocument document;
            if (text.Size() != 0)
            {
                TextRun run;
                run.Text = core::String(text);
                document.Runs.PushBack(Move(run));
            }
            return document;
        }

        /// The text with the markup taken out (an icon is U+FFFC, the object replacement character).
        [[nodiscard]] core::String PlainText() const
        {
            core::String out;
            for (const TextRun& run : Runs)
            {
                if (run.IsIcon())
                    out.Append(core::StringView(u8"\uFFFC"));
                else
                    out.Append(run.Text.AsView());
            }
            return out;
        }
    };

    /// Resolves a colour name in markup ([color=gold]) beyond what a sheet's colours parse, as a
    /// palette would; null leaves only what ParseColor takes.
    using TextMarkupColorResolver = core::Function<Optional<Color>(core::StringView)>;

    namespace detail
    {
        struct MarkupFrame
        {
            core::String Tag; // the tag that opened it (b, i, u, color, size, font, link, outline, shadow, glow)
            TextRun Style;
        };

        class TextMarkupParser
        {
        public:
            TextMarkupParser(core::StringView markup, const TextMarkupColorResolver* resolver)
                : m_markup(markup), m_resolver(resolver)
            {
            }

            TextDocument Parse()
            {
                usize i = 0;
                while (i < m_markup.Size())
                {
                    const char8_t c = m_markup[i];
                    if (c != u8'[')
                    {
                        m_text.PushBack(c);
                        ++i;
                        continue;
                    }
                    if (i + 1 < m_markup.Size() && m_markup[i + 1] == u8'[')
                    {
                        m_text.PushBack(u8'['); // "[[": a literal bracket
                        i += 2;
                        continue;
                    }
                    usize close = i + 1;
                    while (close < m_markup.Size() && m_markup[close] != u8']' && m_markup[close] != u8'[')
                        ++close;
                    if (close >= m_markup.Size() || m_markup[close] != u8']')
                    {
                        Diagnose(i, u8"an unclosed '[' (write \"[[\" for a literal bracket)");
                        m_text.PushBack(c);
                        ++i;
                        continue;
                    }
                    const core::StringView body = m_markup.SubStr(i + 1, close - i - 1);
                    if (!Apply(body, i))
                        m_text.Append(m_markup.SubStr(i, close - i + 1)); // kept as text
                    i = close + 1;
                }
                Flush();
                return Move(m_document);
            }

        private:
            // Apply one tag's body (between the brackets); false when it is not a tag we take.
            bool Apply(core::StringView body, usize at)
            {
                if (body.Size() != 0 && body[0] == u8'/')
                    return Close(Trim(body.SubStr(1, body.Size() - 1)), at);
                core::StringView name = body;
                core::StringView value;
                bool hasValue = false;
                for (usize k = 0; k < body.Size(); ++k)
                {
                    if (body[k] == u8'=')
                    {
                        name = body.SubStr(0, k);
                        value = Trim(body.SubStr(k + 1, body.Size() - k - 1));
                        hasValue = true;
                        break;
                    }
                }
                name = Trim(name);
                TextRun style = Current();
                if (name == core::StringView(u8"b") || name == core::StringView(u8"i") || name == core::StringView(u8"u"))
                {
                    if (hasValue)
                        return Reject(at, u8"[b], [i] and [u] take no value");
                    if (name == core::StringView(u8"b"))
                        style.Bold = true;
                    else if (name == core::StringView(u8"i"))
                        style.Italic = true;
                    else
                        style.Underline = true;
                }
                else if (name == core::StringView(u8"color"))
                {
                    const Optional<Color> color = ParseMarkupColor(value);
                    if (!color.HasValue())
                        return Reject(at, u8"[color=] takes #rrggbb, #rrggbbaa or a colour name");
                    style.TextColor = color;
                }
                else if (name == core::StringView(u8"size"))
                {
                    const Optional<f64> size = ParseFloat(value);
                    if (!size.HasValue() || size.Value() <= 0.0)
                        return Reject(at, u8"[size=] takes a positive number");
                    style.Size = static_cast<f32>(size.Value());
                }
                else if (name == core::StringView(u8"font"))
                {
                    if (value.Size() == 0)
                        return Reject(at, u8"[font=] takes a family name");
                    style.Family = core::String(value);
                }
                else if (name == core::StringView(u8"link"))
                {
                    if (value.Size() == 0)
                        return Reject(at, u8"[link=] takes an id");
                    style.Link = core::String(value);
                }
                else if (name == core::StringView(u8"outline") || name == core::StringView(u8"shadow") ||
                         name == core::StringView(u8"glow"))
                {
                    if (!ApplyEffect(name, value, style))
                    {
                        return Reject(at, name == core::StringView(u8"outline")
                                              ? u8"[outline=] takes a width and a colour"
                                          : name == core::StringView(u8"shadow")
                                              ? u8"[shadow=] takes x and y offsets, a blur and a colour"
                                              : u8"[glow=] takes a radius and a colour");
                    }
                }
                else if (name == core::StringView(u8"icon"))
                {
                    if (value.Size() == 0)
                        return Reject(at, u8"[icon=] takes an image path");
                    Flush();
                    TextRun icon = Current();
                    icon.Icon = core::String(value);
                    m_document.Runs.PushBack(Move(icon));
                    return true;
                }
                else
                {
                    return Reject(at, u8"an unknown tag");
                }
                Flush();
                MarkupFrame frame;
                frame.Tag = core::String(name);
                frame.Style = Move(style);
                m_stack.PushBack(Move(frame));
                return true;
            }

            // [/name] closes back to the innermost frame of that name (inner ones with it); [/]
            // closes the innermost.
            bool Close(core::StringView name, usize at)
            {
                if (m_stack.IsEmpty())
                    return Reject(at, u8"a close with nothing open");
                usize index = m_stack.Size() - 1;
                if (name.Size() != 0)
                {
                    while (m_stack[index].Tag.AsView() != name)
                    {
                        if (index == 0)
                            return Reject(at, u8"a close that matches no open tag");
                        --index;
                    }
                    if (index != m_stack.Size() - 1)
                        Diagnose(at, u8"closes tags opened inside it");
                }
                Flush();
                m_stack.Resize(index);
                return true;
            }

            bool Reject(usize at, const char8_t* message)
            {
                Diagnose(at, message);
                return false;
            }

            void Diagnose(usize at, const char8_t* message)
            {
                TextMarkupDiagnostic diagnostic;
                diagnostic.Offset = at;
                diagnostic.Message = core::String(core::StringView(message));
                m_document.Diagnostics.PushBack(Move(diagnostic));
            }

            [[nodiscard]] TextRun Current() const { return m_stack.IsEmpty() ? TextRun{} : m_stack.Back().Style; }

            // The text so far becomes a run in the current style (merged into the last when alike).
            void Flush()
            {
                if (m_text.Size() == 0)
                    return;
                TextRun run = Current();
                if (!m_document.Runs.IsEmpty() && m_document.Runs.Back().SameStyle(run))
                {
                    m_document.Runs.Back().Text.Append(m_text.AsView());
                }
                else
                {
                    run.Text = Move(m_text);
                    m_document.Runs.PushBack(Move(run));
                }
                m_text = core::String();
            }

            // An effect tag's value: numbers then an optional colour, space separated
            // ([outline=2 #000], [shadow=2 2 3 black], [glow=6 yellow]).
            bool ApplyEffect(core::StringView name, core::StringView value, TextRun& style) const
            {
                f32 numbers[3] = {};
                usize count = 0;
                Optional<Color> color;
                usize k = 0;
                while (k < value.Size())
                {
                    while (k < value.Size() && value[k] == u8' ')
                        ++k;
                    usize end = k;
                    while (end < value.Size() && value[end] != u8' ')
                        ++end;
                    if (end == k)
                        break;
                    const core::StringView token = value.SubStr(k, end - k);
                    k = end;
                    if (color.HasValue())
                        return false; // the colour comes last
                    if (const Optional<f64> number = ParseFloat(token); number.HasValue())
                    {
                        if (count == 3)
                            return false;
                        numbers[count++] = static_cast<f32>(number.Value());
                        continue;
                    }
                    color = ParseMarkupColor(token);
                    if (!color.HasValue())
                        return false;
                }
                if (name == core::StringView(u8"outline"))
                {
                    if (count != 1 || numbers[0] < 0.0f)
                        return false;
                    style.Effects.outlineWidth = numbers[0];
                    style.Effects.outlineColor = color.HasValue() ? color.Value() : Color{0.0f, 0.0f, 0.0f, 1.0f};
                    style.EffectParts |= TextEffectOutline;
                }
                else if (name == core::StringView(u8"shadow"))
                {
                    if (count < 2 || (count == 3 && numbers[2] < 0.0f))
                        return false;
                    style.Effects.shadowOffset = Float2{numbers[0], numbers[1]};
                    style.Effects.shadowBlur = count == 3 ? numbers[2] : 0.0f;
                    style.Effects.shadowColor = color.HasValue() ? color.Value() : Color{0.0f, 0.0f, 0.0f, 0.5f};
                    style.EffectParts |= TextEffectShadow;
                }
                else
                {
                    if (count != 1 || numbers[0] < 0.0f)
                        return false;
                    style.Effects.glowRadius = numbers[0];
                    style.Effects.glowColor = color.HasValue() ? color.Value() : Color{1.0f, 1.0f, 1.0f, 1.0f};
                    style.EffectParts |= TextEffectGlow;
                }
                return true;
            }

            // The resolver first for a bare name (a palette's "$gold" too), then what a sheet takes.
            [[nodiscard]] Optional<Color> ParseMarkupColor(core::StringView value) const
            {
                if (value.Size() == 0)
                    return {};
                if (value[0] != u8'#' && m_resolver != nullptr && *m_resolver)
                {
                    const core::StringView name = value[0] == u8'$' ? value.SubStr(1, value.Size() - 1) : value;
                    if (Optional<Color> named = (*m_resolver)(name); named.HasValue())
                        return named;
                }
                return ParseColor(value);
            }

            core::StringView m_markup;
            const TextMarkupColorResolver* m_resolver;
            TextDocument m_document;
            Array<MarkupFrame> m_stack;
            core::String m_text;
        };
    }

    /// Parse markup into runs.
    [[nodiscard]] inline TextDocument ParseTextMarkup(core::StringView markup, const TextMarkupColorResolver* resolver = nullptr)
    {
        return detail::TextMarkupParser(markup, resolver).Parse();
    }
}
