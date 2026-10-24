// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :text_layout partition
//
// The inline formatter: lays a TextDocument's runs into lines. Text breaks after spaces and at line
// breaks, runs of different sizes share a baseline (each line as tall as its tallest run, or as the
// line height says), an icon sits on the baseline as tall as its run's text is big, and each line
// aligns on its own. What comes out is positioned glyphs per run, underlines, icon rectangles and
// link rectangles, in the layout's own coordinates; the widget draws them.
//
// A run that sets no font of its own draws in the style's font (the label's). One that sets a family,
// a size, bold or italic asks the font service; bold and italic take the family's "<family> Bold",
// "<family> Italic" or "<family> Bold Italic" face when one is loaded, and are synthesized when not
// (bold drawn twice a little apart, italic slanted), as browsers do. With no service, such a run
// draws in the style's font, its bold and italic synthesized. A character a run's face lacks takes
// the first of the style's fallback families that has it (the rest of a font-family list, E11 of
// Specs/gui-lab-evolution-2.md): a piece is measured in its faces' stretches, shaped with the
// whole list, and its glyphs come out as one run per face.
//
// Copied from foundation.ui's :text_layout (E4 of Specs/gui-lab-evolution.md), and the GUI's own
// from then on. The GUI adds what CSS's text properties need: a line height, letter spacing, a
// clamp on the line count and an ellipsis at a line's end, start or middle (text-overflow), and what
// editing needs: every glyph and line knows the bytes of the plain text it shows, so a caret finds
// its x and a point its offset. A font with no shaper still measures; its pieces come out as text
// to draw unshaped, each character placed by measuring (they take no ellipsis).

module;
#include "Core/Prelude.h"

export module foundation.gui:text_layout;

import foundation.core;  // Array, String, Rectangle, Float2, Max, Min, Abs
import foundation.fonts; // CachedFont, IFontService, GlyphPosition
import :text_runs;
import :text_segmentation; // NextGrapheme

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    enum class TextHAlign
    {
        Left,
        Center,
        Right,
        Start, ///< the line's start: left, or right in a right-to-left paragraph (E9c)
        End,   ///< the line's end
    };
    enum class TextVAlign
    {
        Top,
        Middle,
        Bottom
    };
    /// CSS's white-space: whether spaces and line breaks collapse, and whether lines wrap.
    enum class TextWhiteSpace : u8
    {
        Normal,  ///< collapse; wrap
        NoWrap,  ///< collapse; one line unless the text breaks it
        Pre,     ///< keep; break only where the text does
        PreWrap, ///< keep; wrap
    };
    /// CSS's text-overflow, with the GUI's start and middle ellipses (for paths).
    enum class TextOverflow : u8
    {
        Clip,
        Ellipsis,      ///< "Long text that…"
        EllipsisStart, ///< "…the end of it"
        EllipsisMiddle ///< "/home/…/file.txt"
    };

    [[nodiscard]] constexpr bool CollapsesSpaces(TextWhiteSpace w) noexcept
    {
        return w == TextWhiteSpace::Normal || w == TextWhiteSpace::NoWrap;
    }
    [[nodiscard]] constexpr bool Wraps(TextWhiteSpace w) noexcept
    {
        return w == TextWhiteSpace::Normal || w == TextWhiteSpace::PreWrap;
    }

    /// Whether `font` draws every character of `text`: its atlas holds a glyph for each (a font with
    /// no atlas is taken at its word). Atlases are baked over a range of codepoints, so a widget's
    /// own marks (an ellipsis, a password's bullet) fall back to ones it has.
    [[nodiscard]] inline bool FontDraws(const fonts::CachedFont* font, core::StringView text)
    {
        if (font == nullptr || font->font == nullptr)
            return false;
        if (font->atlas == nullptr)
            return true;
        for (usize i = 0; i < text.Size();)
        {
            const i32 glyph = font->atlas->GlyphFor(static_cast<i32>(core::DecodeUtf8(text, i)));
            if (glyph <= 0 || !font->atlas->Contains(glyph))
                return false;
        }
        return true;
    }
    /// The ellipsis `font` draws: U+2026, or three full stops.
    [[nodiscard]] inline core::StringView EllipsisFor(const fonts::CachedFont* font)
    {
        return FontDraws(font, core::StringView(u8"\u2026")) ? core::StringView(u8"\u2026") : core::StringView(u8"...");
    }

    /// What CSS chooses of a font past its family and size (E11 of Specs/gui-lab-evolution-2.md):
    /// the families a character the font lacks falls back to, the weight and the style.
    struct FontSelection
    {
        /// The rest of a font-family list (comma separated), in order.
        core::String FallbackFamilies;
        u16 Weight = 400; ///< 100 to 900, CSS's font-weight
        bool Italic = false;
        [[nodiscard]] bool operator==(const FontSelection& o) const noexcept
        {
            return FallbackFamilies == o.FallbackFamilies && Weight == o.Weight && Italic == o.Italic;
        }
    };

    /// Which way a text's paragraphs run: one way, or (Auto, E11) each as its first strong
    /// character reads, one with none as `AutoRightToLeft` says (its node's way).
    struct ParagraphDirection
    {
        fonts::TextDirection Direction = fonts::TextDirection::LeftToRight;
        bool AutoRightToLeft = false;
        [[nodiscard]] bool operator==(const ParagraphDirection&) const noexcept = default;
    };

    /// What a run takes when its markup leaves a style unset, and how the lines go.
    struct TextLayoutStyle
    {
        fonts::CachedFont* Font = nullptr;    ///< the label's font: plain runs draw in it
        fonts::IFontService* Fonts = nullptr; ///< resolves a run's own family, size, bold and italic
        core::String Family;                  ///< the label's family as the service names it
        /// The label's fallback families, weight and style: a run takes its face from them.
        FontSelection Selection;
        f32 Size = 16.0f;                     ///< the label's size in pixels
        Color TextColor = Color::White;
        TextHAlign Align = TextHAlign::Left;
        bool Wrap = true;
        f32 MaxWidth = 0.0f;      ///< The width lines wrap at, align in and end in an ellipsis past; 0: unbounded.
        f32 LineHeight = 0.0f;    ///< Each line's height in pixels; 0: its fonts' own.
        f32 LetterSpacing = 0.0f; ///< Added after every character, in pixels.
        bool BreakWords = false;  ///< overflow-wrap: a word wider than a line breaks between its graphemes
        u32 MaxLines = 0;         ///< The most lines kept (line-clamp); 0: all.
        TextOverflow Overflow = TextOverflow::Clip;
        /// Each paragraph's base direction (E9c): its node's, or (Auto) its first strong character's.
        fonts::TextDirection Direction = fonts::TextDirection::LeftToRight;
        /// An Auto paragraph with no strong character runs right to left (its node does).
        bool AutoRightToLeft = false;
    };

    /// A run's glyphs on one line: positions in layout coordinates, y on the baseline.
    struct LaidOutGlyphs
    {
        fonts::CachedFont* Font = nullptr;
        Array<fonts::GlyphPosition> Glyphs;
        /// Each glyph's bytes of the plain text, parallel to Glyphs (an ellipsis has none of its own:
        /// it covers what it stands for).
        Array<usize> GlyphStart;
        Array<usize> GlyphEnd;
        Color TextColor = Color::White;
        f32 Size = 0.0f;
        bool SyntheticBold = false;   ///< no bold face: draw twice, `Size / 24` apart
        bool SyntheticItalic = false; ///< no italic face: slant about the baseline
        bool Unshaped = false;        ///< its font has no shaper: draw TextStart..TextEnd at X as text (its glyphs only place carets)
        f32 Baseline = 0.0f;
        f32 X = 0.0f;     ///< where its first glyph starts
        f32 Width = 0.0f; ///< its advance
        usize TextStart = 0;
        usize TextEnd = 0;
        usize Line = 0;
        i32 Run = 0; ///< its run, or -1 for an ellipsis
    };

    /// One laid-out line.
    struct LaidOutLine
    {
        f32 Top = 0.0f;
        f32 Height = 0.0f;
        f32 Baseline = 0.0f;
        f32 Left = 0.0f;  ///< after alignment
        f32 Width = 0.0f; ///< without trailing spaces
        usize Start = 0;  ///< its bytes of the plain text, its line break left out
        usize End = 0;
        bool Ellipsized = false; ///< an ellipsis stands for some of its text
        bool RightToLeft = false; ///< its paragraph runs right to left: its start is on its right
    };

    /// A rectangle a part of the text covers, with its run (an icon's, an underline's, a link's).
    struct LaidOutBox
    {
        Rectangle Rect{};
        i32 Run = 0;
        usize Line = 0;
        Color TextColor = Color::White; ///< an underline's colour
    };

    /// A document laid out.
    struct TextLayout
    {
        Array<LaidOutLine> Lines;
        Array<LaidOutGlyphs> GlyphRuns;
        Array<LaidOutBox> Icons;
        Array<LaidOutBox> Underlines;
        Array<LaidOutBox> Links; ///< one per run per line it spans
        core::String Text;       ///< the plain text the offsets index (a ligature's inner caret places)
        f32 Width = 0.0f;  ///< the widest line
        f32 Height = 0.0f; ///< every line
        bool Clamped = false; ///< lines past the clamp were left out

        /// The run of the link under a point, or -1.
        [[nodiscard]] i32 LinkAt(core::Float2 point) const
        {
            for (const LaidOutBox& box : Links)
            {
                if (point.x >= box.Rect.x && point.x < box.Rect.x + box.Rect.width && point.y >= box.Rect.y &&
                    point.y < box.Rect.y + box.Rect.height)
                {
                    return box.Run;
                }
            }
            return -1;
        }

        /// The line a caret at `offset` stands on (at a wrap, the line it starts).
        [[nodiscard]] usize LineOf(usize offset) const
        {
            for (usize i = 0; i < Lines.Size(); ++i)
                if (offset < Lines[i].End || (offset == Lines[i].End && (i + 1 == Lines.Size() || Lines[i + 1].Start > offset)))
                    return i;
            return Lines.IsEmpty() ? 0 : Lines.Size() - 1;
        }
        /// Where a caret at `offset` stands across its line (`upstream`: after the text before it,
        /// where that is elsewhere, at a direction's boundary).
        [[nodiscard]] f32 CaretX(usize offset, bool upstream = false) const
        {
            return Lines.IsEmpty() ? 0.0f : CaretXOnLine(offset, LineOf(offset), upstream);
        }
        /// Where a caret at `offset` stands across line `line` (a wrapped line's end: its own, not
        /// the next line's start). Downstream (the default) it is before the text after it;
        /// `upstream`, after the text before it: the two differ where the directions meet (E9c).
        [[nodiscard]] f32 CaretXOnLine(usize offset, usize line, bool upstream = false) const
        {
            if (line >= Lines.Size())
                return 0.0f;
            if (upstream)
                for (const LaidOutGlyphs& run : GlyphRuns)
                {
                    if (run.Line != line || run.Run < 0)
                        continue;
                    for (usize g = 0; g < run.Glyphs.Size(); ++g)
                        if (run.GlyphEnd[g] == offset && run.GlyphStart[g] < offset)
                            return run.Glyphs[g].rightToLeft ? run.Glyphs[g].x : run.Glyphs[g].x + run.Glyphs[g].advance;
                }
            // The leading edge of the glyph the offset starts (a right-to-left glyph's is its
            // right), else the trailing edge of the one before it, else the line's start.
            const LaidOutLine& at = Lines[line];
            f32 x = at.RightToLeft ? at.Left + at.Width : at.Left;
            usize before = 0;
            bool found = false;
            for (const LaidOutGlyphs& run : GlyphRuns)
            {
                if (run.Line != line || run.Run < 0)
                    continue;
                for (usize g = 0; g < run.Glyphs.Size(); ++g)
                {
                    const fonts::GlyphPosition& glyph = run.Glyphs[g];
                    const usize start = run.GlyphStart[g], end = run.GlyphEnd[g];
                    if (offset >= start && offset < end)
                    {
                        // Inside a ligature: the share of its advance before the offset.
                        const f32 share = end > start ? static_cast<f32>(offset - start) / static_cast<f32>(end - start) : 0.0f;
                        return glyph.rightToLeft ? glyph.x + glyph.advance * (1.0f - share) : glyph.x + glyph.advance * share;
                    }
                    if (offset >= end && (!found || end >= before))
                    {
                        x = glyph.rightToLeft ? glyph.x : glyph.x + glyph.advance;
                        before = end;
                        found = true;
                    }
                }
            }
            return x;
        }
        /// The offset a caret takes for a point: the line under its y (the first above, the last
        /// below), then the glyph edge nearest its x; `upstream` says the edge was the trailing one
        /// of the text before the offset.
        [[nodiscard]] usize OffsetAt(core::Float2 point, bool* upstream = nullptr) const
        {
            if (upstream != nullptr)
                *upstream = false;
            if (Lines.IsEmpty())
                return 0;
            usize line = Lines.Size() - 1;
            for (usize i = 0; i < Lines.Size(); ++i)
                if (point.y < Lines[i].Top + Lines[i].Height)
                {
                    line = i;
                    break;
                }
            return OffsetOnLine(line, point.x, upstream);
        }
        /// The offset on line `line` nearest across to `x` (`upstream` as OffsetAt's).
        [[nodiscard]] usize OffsetOnLine(usize line, f32 x, bool* upstream = nullptr) const
        {
            if (upstream != nullptr)
                *upstream = false;
            if (line >= Lines.Size())
                return 0;
            bool trailing = false;
            usize best = Lines[line].Start;
            usize lastStart = Lines[line].Start; // the last glyph's start: a wrapped line's end
            f32 bestDistance = Abs(x - (Lines[line].RightToLeft ? Lines[line].Left + Lines[line].Width : Lines[line].Left));
            for (const LaidOutGlyphs& run : GlyphRuns)
            {
                if (run.Line != line || run.Run < 0)
                    continue;
                for (usize g = 0; g < run.Glyphs.Size(); ++g)
                {
                    const fonts::GlyphPosition& glyph = run.Glyphs[g];
                    const f32 left = Abs(x - glyph.x);
                    const f32 right = Abs(x - (glyph.x + glyph.advance));
                    // A right-to-left glyph's start is on its right.
                    const usize leftOffset = glyph.rightToLeft ? run.GlyphEnd[g] : run.GlyphStart[g];
                    const usize rightOffset = glyph.rightToLeft ? run.GlyphStart[g] : run.GlyphEnd[g];
                    if (left < bestDistance)
                    {
                        bestDistance = left;
                        best = leftOffset;
                        trailing = glyph.rightToLeft; // a right-to-left glyph's left edge is its end
                    }
                    if (right < bestDistance)
                    {
                        bestDistance = right;
                        best = rightOffset;
                        trailing = !glyph.rightToLeft;
                    }
                    lastStart = core::Max(lastStart, run.GlyphStart[g]);
                }
            }
            best = core::Min(best, Lines[line].End);
            // Where a line wraps, its end is the next line's start: a caret there would stand on
            // the next line, so the end of a wrapped line is before its last space.
            if (best == Lines[line].End && line + 1 < Lines.Size() && Lines[line + 1].Start == best)
            {
                best = lastStart;
                trailing = false;
            }
            // Upstream only where it stands apart from downstream (a direction's boundary).
            if (upstream != nullptr && trailing && best > Lines[line].Start)
                *upstream = CaretXOnLine(best, line, true) != CaretXOnLine(best, line, false);
            return best;
        }

        /// The caret one stop across from (`offset`, `upstream`) on its line, left (`step` below 0)
        /// or right, in visual order (E9c): the line's caret places sorted by x, each once. Past the
        /// line's edge it goes on to the next line where the line reads that way and to the one
        /// before where it reads the other way. False when there is nowhere to go.
        [[nodiscard]] bool OffsetVisually(usize offset, bool upstream, i32 step, usize& outOffset, bool& outUpstream) const
        {
            if (Lines.IsEmpty())
                return false;
            const usize line = LineOf(offset);
            struct Stop
            {
                f32 X;
                usize Offset;
                bool Upstream;
            };
            Array<Stop> stops;
            const auto add = [&](usize at, bool up)
            {
                const f32 x = CaretXOnLine(at, line, up);
                for (const Stop& s : stops)
                    if (Abs(s.X - x) < 0.01f)
                        return; // a place already reached
                stops.PushBack(Stop{x, at, up});
            };
            // Downstream first, so a place both reach keeps the plain caret.
            add(Lines[line].Start, false);
            const bool passes[] = {false, true};
            for (const bool up : passes)
                for (const LaidOutGlyphs& run : GlyphRuns)
                    if (run.Line == line && run.Run >= 0)
                        for (usize g = 0; g < run.Glyphs.Size(); ++g)
                        {
                            add(up ? run.GlyphEnd[g] : run.GlyphStart[g], up);
                            // Inside a ligature (fi, lam-alef), a place between each of its graphemes.
                            if (!up && run.GlyphEnd[g] <= Text.Size())
                                for (usize at = NextGrapheme(Text.AsView(), run.GlyphStart[g]); at < run.GlyphEnd[g];
                                     at = NextGrapheme(Text.AsView(), at))
                                    add(at, false);
                        }
            for (usize i = 1; i < stops.Size(); ++i) // insertion sort: a line's stops are few
                for (usize j = i; j > 0 && stops[j].X < stops[j - 1].X; --j)
                    Swap(stops[j], stops[j - 1]);
            const f32 x = CaretXOnLine(offset, line, upstream);
            usize at = 0;
            for (usize i = 0; i < stops.Size(); ++i)
                if (Abs(stops[i].X - x) < Abs(stops[at].X - x))
                    at = i;
            if (step > 0 && at + 1 < stops.Size())
            {
                outOffset = stops[at + 1].Offset;
                outUpstream = stops[at + 1].Upstream;
                return true;
            }
            if (step < 0 && at > 0)
            {
                outOffset = stops[at - 1].Offset;
                outUpstream = stops[at - 1].Upstream;
                return true;
            }
            const bool towardsEnd = (step > 0) != Lines[line].RightToLeft;
            if (towardsEnd && line + 1 < Lines.Size())
            {
                outOffset = Lines[line + 1].Start;
                outUpstream = false;
                return true;
            }
            if (!towardsEnd && line > 0)
            {
                outOffset = Lines[line - 1].End;
                outUpstream = true;
                return true;
            }
            return false;
        }

        /// The boxes across line `line` that bytes [start, end) of the text cover (one a stretch of
        /// glyphs side by side: a selection in mixed-direction text falls in pieces, E9c), left to
        /// right, as x ranges.
        void RangeOnLine(usize start, usize end, usize line, Array<core::Float2>& out) const
        {
            out.Clear();
            if (line >= Lines.Size() || end <= start)
                return;
            for (const LaidOutGlyphs& run : GlyphRuns)
            {
                if (run.Line != line || run.Run < 0)
                    continue;
                for (usize g = 0; g < run.Glyphs.Size(); ++g)
                {
                    const usize a = Max(start, run.GlyphStart[g]);
                    const usize b = Min(end, run.GlyphEnd[g]);
                    if (b <= a)
                        continue;
                    const fonts::GlyphPosition& glyph = run.Glyphs[g];
                    const usize span = run.GlyphEnd[g] - run.GlyphStart[g];
                    // A ligature's share (from its start's side).
                    f32 from = static_cast<f32>(a - run.GlyphStart[g]) / static_cast<f32>(span);
                    f32 to = static_cast<f32>(b - run.GlyphStart[g]) / static_cast<f32>(span);
                    if (glyph.rightToLeft)
                    {
                        const f32 f = 1.0f - to;
                        to = 1.0f - from;
                        from = f;
                    }
                    out.PushBack(core::Float2{glyph.x + glyph.advance * from, glyph.x + glyph.advance * to});
                }
            }
            for (usize i = 1; i < out.Size(); ++i)
                for (usize j = i; j > 0 && out[j].x < out[j - 1].x; --j)
                    Swap(out[j], out[j - 1]);
            usize kept = 0;
            for (usize i = 0; i < out.Size(); ++i)
            {
                if (kept > 0 && out[i].x <= out[kept - 1].y + 0.01f)
                    out[kept - 1].y = Max(out[kept - 1].y, out[i].y); // touching: one box
                else
                    out[kept++] = out[i];
            }
            out.Resize(kept);
        }
    };

    /// Calls `each` with every family of a CSS `font-family` list, in order: split at commas, the
    /// spaces and quotes around each taken off (`"Roboto", 'Noto Sans Arabic', sans-serif`).
    template <typename F>
    inline void ForEachFamily(core::StringView list, F&& each)
    {
        usize start = 0;
        while (start <= list.Size())
        {
            usize end = start;
            while (end < list.Size() && list[end] != u8',')
                ++end;
            core::StringView family = core::Trimmed(list.SubStr(start, end - start));
            if (family.Size() >= 2 && (family[0] == u8'"' || family[0] == u8'\'') && family[family.Size() - 1] == family[0])
                family = core::Trimmed(family.SubStr(1, family.Size() - 2));
            if (family.Size() != 0)
                each(family);
            start = end + 1;
        }
    }

    /// The font a run draws in, the faces it falls back to for what that one lacks (the rest of its
    /// `font-family` list, E11 of Specs/gui-lab-evolution-2.md), and what of its style the face
    /// lacks (to synthesize).
    struct ResolvedRunFont
    {
        static constexpr usize kMaxFallbacks = 4;
        fonts::CachedFont* Font = nullptr;
        fonts::CachedFont* Fallbacks[kMaxFallbacks]{};
        u8 FallbackCount = 0;
        f32 Size = 16.0f;
        bool SyntheticBold = false;
        bool SyntheticItalic = false;

        /// Face `i` of the list: 0 the run's font, then its fallbacks.
        [[nodiscard]] fonts::CachedFont* Face(usize i) const noexcept { return i == 0 ? Font : Fallbacks[i - 1]; }
        [[nodiscard]] usize FaceCount() const noexcept { return Font != nullptr ? 1u + FallbackCount : 0u; }
        /// The first face that has `codepoint` (the run's font when none has it, its missing glyph
        /// then drawn as that font draws one).
        [[nodiscard]] usize FaceFor(i32 codepoint) const noexcept
        {
            for (usize i = 0; i < FaceCount(); ++i)
                if (Face(i)->font != nullptr && Face(i)->font->HasGlyph(codepoint))
                    return i;
            return 0;
        }
    };

    namespace detail
    {
        // "<family><suffix>": a styled face's family name.
        [[nodiscard]] inline core::String WithSuffix(core::StringView family, const char8_t* suffix)
        {
            core::String name(family);
            name.Append(core::StringView(suffix));
            return name;
        }

        /// The name a family's face of a weight is loaded under: "Roboto Light", "Roboto", "Roboto
        /// Bold" (the weights' common names, as font files name them).
        [[nodiscard]] constexpr const char8_t* WeightSuffix(u16 weight) noexcept
        {
            constexpr const char8_t* kSuffixes[] = {u8" Thin", u8" ExtraLight", u8" Light", u8"", u8" Medium",
                                                    u8" SemiBold", u8" Bold", u8" ExtraBold", u8" Black"};
            return kSuffixes[(core::Clamp<u16>(weight, 100, 900) + 50) / 100 - 1];
        }
        /// CSS's bolder and lighter, from the weight inherited.
        [[nodiscard]] constexpr u16 Bolder(u16 weight) noexcept { return weight < 350 ? 400 : weight < 550 ? 700 : 900; }
        [[nodiscard]] constexpr u16 Lighter(u16 weight) noexcept { return weight < 550 ? 100 : weight < 750 ? 400 : 700; }

        /// The weights CSS tries for `desired`, nearest first (the hundreds; CSS Fonts 4, 5.2): from
        /// 400 to 500 up to 500 then down then above 500; below 400 down then up; above 500 up then
        /// down.
        inline void WeightOrder(u16 desired, u16 (&out)[9]) noexcept
        {
            const u16 want = static_cast<u16>((core::Clamp<u16>(desired, 100, 900) + 50) / 100 * 100);
            usize n = 0;
            const auto up = [&](u16 from, u16 to)
            {
                for (u16 w = from; w <= to; w = static_cast<u16>(w + 100))
                    out[n++] = w;
            };
            const auto down = [&](u16 from)
            {
                for (u16 w = from; w >= 100; w = static_cast<u16>(w - 100))
                    out[n++] = w;
            };
            if (want >= 400 && want <= 500)
            {
                up(want, 500);
                down(static_cast<u16>(want - 100));
                up(600, 900);
            }
            else if (want < 400)
            {
                down(want);
                up(static_cast<u16>(want + 100), 900);
            }
            else
            {
                up(want, 900);
                down(static_cast<u16>(want - 100));
            }
        }

        /// The face a family draws a weight and style in, and what of them it must synthesize.
        struct FaceChoice
        {
            core::String Face;
            bool SyntheticBold = false;
            bool SyntheticItalic = false;
        };
        /// CSS's matching over the faces the service has: the style first (an italic face of any
        /// weight before an upright one), then the nearest weight. Bold is synthesized where 600 or
        /// more was asked for and the face is lighter than 600, italic where no italic face is;
        /// with no face of the family at all, the family is asked for as it is.
        [[nodiscard]] inline FaceChoice ChooseFace(const fonts::IFontService& service, core::StringView family, u16 weight, bool italic)
        {
            u16 order[9]{};
            WeightOrder(weight, order);
            FaceChoice out;
            const bool styles[] = {true, false};
            for (const bool slanted : styles)
            {
                if (slanted && !italic)
                    continue;
                for (const u16 w : order)
                {
                    core::String name = WithSuffix(family, WeightSuffix(w));
                    if (slanted)
                        name.Append(core::StringView(u8" Italic"));
                    if (!service.HasFamily(name.AsView()))
                        continue;
                    out.Face = Move(name);
                    out.SyntheticBold = weight >= 600 && w < 600;
                    out.SyntheticItalic = italic && !slanted;
                    return out;
                }
            }
            out.Face = core::String(family);
            out.SyntheticBold = weight >= 600;
            out.SyntheticItalic = italic;
            return out;
        }
    }

    /// The faces a run falls back to, at its size: for a run of its own family the label's family
    /// first, then the rest of the label's list; up to ResolvedRunFont::kMaxFallbacks, a face already
    /// chosen not added again. (They are the families' regular faces: a bold run's fallback glyphs
    /// are not bold.)
    inline void AddFallbacks(ResolvedRunFont& out, const TextLayoutStyle& style, bool ownFamily)
    {
        if (style.Fonts == nullptr || out.Font == nullptr)
            return;
        const auto add = [&](core::StringView family)
        {
            if (out.FallbackCount >= ResolvedRunFont::kMaxFallbacks || !style.Fonts->HasFamily(family))
                return;
            fonts::CachedFont* face = style.Fonts->GetFont(family, out.Size);
            if (face == nullptr || face == out.Font)
                return;
            for (usize i = 0; i < out.FallbackCount; ++i)
                if (out.Fallbacks[i] == face)
                    return;
            out.Fallbacks[out.FallbackCount++] = face;
        };
        if (ownFamily && style.Family.Size() != 0)
            add(style.Family.AsView());
        ForEachFamily(style.Selection.FallbackFamilies.AsView(), add);
    }

    [[nodiscard]] inline ResolvedRunFont ResolveRunFont(const TextRun& run, const TextLayoutStyle& style)
    {
        ResolvedRunFont out;
        out.Font = style.Font;
        out.Size = run.Size.HasValue() ? run.Size.Value() : style.Size;
        // A run's <b> is CSS's bolder, its <i> italic, over the label's own weight and style.
        const u16 weight = run.Bold ? detail::Bolder(style.Selection.Weight) : style.Selection.Weight;
        const bool italic = run.Italic || style.Selection.Italic;
        const bool ownFont = run.Family.HasValue() || run.Size.HasValue() || weight != 400 || italic;
        if (!ownFont)
        {
            AddFallbacks(out, style, false);
            return out;
        }
        if (style.Fonts == nullptr)
        {
            // No service to ask: the label's font, its style synthesized.
            out.Size = style.Size;
            out.SyntheticBold = weight >= 600;
            out.SyntheticItalic = italic;
            return out;
        }
        fonts::IFontService& service = *style.Fonts;
        const core::StringView family = run.Family.HasValue() ? run.Family.Value().AsView() : style.Family.AsView();
        const detail::FaceChoice face = detail::ChooseFace(service, family, weight, italic);
        out.SyntheticBold = face.SyntheticBold;
        out.SyntheticItalic = face.SyntheticItalic;
        if (fonts::CachedFont* font = service.GetFont(face.Face.AsView(), out.Size))
            out.Font = font;
        AddFallbacks(out, style, run.Family.HasValue());
        return out;
    }

    namespace detail
    {
        // A piece the lines are made of: a word with the spaces after it, an icon, or a break.
        struct TextPiece
        {
            i32 Run = 0;
            core::StringView Text;
            usize Start = 0; // its bytes of the plain text
            ResolvedRunFont Font;
            f32 Width = 0.0f;
            f32 TrailingSpace = 0.0f; // the width of the spaces it ends with
            f32 Ascent = 0.0f;
            f32 Descent = 0.0f; // below the baseline, positive
            f32 Gap = 0.0f;
            bool Icon = false;
            bool LineBreak = false;
            f32 X = 0.0f;   // placed, from its line's start
            usize Line = 0; // the line it landed on
            u8 Level = 0;          // its bidi embedding level (E9c): odd reads right to left
            u8 ParagraphLevel = 0; // its paragraph's
            fonts::TextDirection Shaping = fonts::TextDirection::Auto; // the direction it is shaped in
        };

        [[nodiscard]] inline usize CodepointCount(core::StringView text)
        {
            usize count = 0;
            for (usize i = 0; i < text.Size(); ++i)
                if ((static_cast<u8>(text[i]) & 0xC0) != 0x80)
                    ++count;
            return count;
        }

        // Calls `each(face, text)` for the stretches of `text` each face of `font` draws, as the
        // shapers split a font list: a character takes the first face that has it, a neutral one
        // (a space, an ASCII digit or punctuation) the stretch's face where that has it.
        template <typename F>
        inline void ForEachFaceStretch(const ResolvedRunFont& font, core::StringView text, F&& each)
        {
            if (font.FallbackCount == 0)
            {
                each(usize{0}, text);
                return;
            }
            const auto neutral = [](i32 cp)
            {
                return cp == U' ' || cp == U'\t' || cp == 0xA0 || (cp >= 0x21 && cp <= 0x40) || (cp >= 0x5B && cp <= 0x60) ||
                       (cp >= 0x7B && cp <= 0x7E);
            };
            usize start = 0;
            usize face = 0;
            for (usize i = 0; i < text.Size();)
            {
                const usize at = i;
                const i32 cp = static_cast<i32>(core::DecodeUtf8(text, i));
                const fonts::IFont* current = font.Face(face)->font;
                const usize next = at != 0 && neutral(cp) && current != nullptr && current->HasGlyph(cp) ? face : font.FaceFor(cp);
                if (at == 0)
                    face = next;
                else if (next != face)
                {
                    each(face, text.SubStr(start, at - start));
                    start = at;
                    face = next;
                }
            }
            if (start < text.Size())
                each(face, text.SubStr(start, text.Size() - start));
        }

        // The width `font` draws `text` in, its faces each measuring their own stretches; `used`
        // gathers the faces that drew any (a bit each).
        [[nodiscard]] inline f32 MeasureInFaces(const ResolvedRunFont& font, core::StringView text, u32* used = nullptr)
        {
            f32 width = 0.0f;
            ForEachFaceStretch(font, text,
                               [&](usize face, core::StringView stretch)
                               {
                                   if (const fonts::IFont* f = font.Face(face)->font)
                                       width += f->MeasureString(stretch);
                                   if (used != nullptr)
                                       *used |= 1u << face;
                               });
            return width;
        }

        // `text` shaped with `font`'s faces as it will be drawn (ligatures, joined forms, kerning):
        // its advance, and in `trailing` that of the glyphs from character `trailingFrom` on; the
        // faces that drew any gathered in `used`. False with no shaper (the caller measures).
        [[nodiscard]] inline bool MeasureShaped(const ResolvedRunFont& font, core::StringView text, usize trailingFrom, f32& advance,
                                                f32& trailing, u32& used)
        {
            if (font.Font->shaper == nullptr)
                return false;
            fonts::IFont* list[1 + ResolvedRunFont::kMaxFallbacks]{};
            for (usize f = 0; f < font.FaceCount(); ++f)
                list[f] = font.Face(f)->font;
            fonts::ShapeRequest request;
            request.text = text;
            request.fonts = Span<fonts::IFont* const>(list, font.FaceCount());
            Array<fonts::GlyphPosition> glyphs;
            if (!font.Font->shaper->Shape(request, glyphs).HasValue())
                return false;
            advance = trailing = 0.0f;
            for (const fonts::GlyphPosition& g : glyphs)
            {
                advance += g.advance;
                if (static_cast<usize>(Max(0, g.cluster)) >= trailingFrom)
                    trailing += g.advance;
                used |= 1u << g.font;
            }
            return true;
        }

        inline void MeasurePiece(TextPiece& piece, f32 letterSpacing)
        {
            if (piece.Font.Font == nullptr || piece.Font.Font->font == nullptr)
                return;
            u32 used = 1; // the run's own face sets the line's height even where a fallback draws it all
            usize spaces = piece.Text.Size();
            while (spaces > 0 && piece.Text[spaces - 1] == u8' ')
                --spaces;
            const core::StringView kept = piece.Text.SubStr(0, spaces);
            const usize characters = CodepointCount(piece.Text);
            const usize keptCharacters = CodepointCount(kept);
            if (piece.Text.Size() != 0)
            {
                // Measured as it is shaped, so a line is as wide as what it draws; measured by
                // its characters' advances only where there is no shaper (it draws unshaped then).
                f32 advance = 0.0f;
                f32 trailing = 0.0f;
                if (!MeasureShaped(piece.Font, piece.Text, keptCharacters, advance, trailing, used))
                {
                    advance = MeasureInFaces(piece.Font, piece.Text, &used);
                    trailing = spaces < piece.Text.Size() ? advance - MeasureInFaces(piece.Font, kept) : 0.0f;
                }
                piece.Width = advance + letterSpacing * static_cast<f32>(characters);
                piece.TrailingSpace = trailing + letterSpacing * static_cast<f32>(characters - keptCharacters);
            }
            // Its line holds the tallest face it draws in.
            for (usize f = 0; f < piece.Font.FaceCount(); ++f)
                if ((used & (1u << f)) != 0 && piece.Font.Face(f)->font != nullptr)
                {
                    const fonts::FontMetrics metrics = piece.Font.Face(f)->font->Metrics();
                    piece.Ascent = Max(piece.Ascent, metrics.ascent);
                    piece.Descent = Max(piece.Descent, Abs(metrics.descent));
                    piece.Gap = Max(piece.Gap, metrics.lineGap);
                }
        }

        // The bytes of `piece` from its start that fit in `width`: whole graphemes, one at the
        // least (a line holds something).
        [[nodiscard]] inline usize FittingPrefix(const TextPiece& piece, f32 width, f32 letterSpacing)
        {
            const core::StringView text = piece.Text;
            usize fits = NextGrapheme(text, 0);
            for (usize at = fits; at < text.Size();)
            {
                const usize next = NextGrapheme(text, at);
                const core::StringView head = text.SubStr(0, next);
                f32 advance = 0.0f;
                f32 trailing = 0.0f;
                u32 used = 0;
                if (!MeasureShaped(piece.Font, head, head.Size(), advance, trailing, used))
                    advance = MeasureInFaces(piece.Font, head);
                if (advance + letterSpacing * static_cast<f32>(CodepointCount(head)) > width)
                    break;
                fits = next;
                at = next;
            }
            return fits;
        }

        // The byte offset of each codepoint of `text` from `base`, and the end (count + 1 entries).
        inline void CodepointOffsets(core::StringView text, usize base, Array<usize>& out)
        {
            out.Clear();
            for (usize i = 0; i < text.Size(); ++i)
                if ((static_cast<u8>(text[i]) & 0xC0) != 0x80)
                    out.PushBack(base + i);
            out.PushBack(base + text.Size());
        }

        // The first strongly directional character's way: 1 right to left (Hebrew, Arabic, Syriac,
        // Thaana, N'Ko and their presentation forms), 0 left to right (the letters of the scripts
        // that read so), -1 none (digits, spaces, punctuation and symbols only): an auto
        // paragraph's direction, by the rule of Unicode's P2 over the common scripts.
        [[nodiscard]] inline i32 FirstStrongDirection(const Array<u32>& codepoints) noexcept
        {
            for (const u32 cp : codepoints)
            {
                if ((cp >= 0x0590 && cp <= 0x08FF) || (cp >= 0xFB1D && cp <= 0xFDFF) || (cp >= 0xFE70 && cp <= 0xFEFF))
                    return 1;
                const bool letter = (cp >= u'A' && cp <= u'Z') || (cp >= u'a' && cp <= u'z') ||
                                    (cp >= 0xC0 && cp <= 0x058F && cp != 0xD7 && cp != 0xF7) || (cp >= 0x0900 && cp < 0x2000) ||
                                    (cp >= 0x3040 && cp < 0xFB1D);
                if (letter)
                    return 0;
            }
            return -1;
        }

        // Bidi (E9c): each paragraph's embedding levels from the installed resolver over its pieces'
        // characters (an icon as U+FFFC), and a piece crossing a level change split there, so each
        // piece reads one way. False when nothing reads right to left and the base direction is
        // left to right (the layout then runs as it always has, the pieces untouched). With no
        // resolver installed, a right-to-left paragraph keeps its pieces in order (only its start
        // moves to the right) and each is shaped as its script reads.
        [[nodiscard]] inline bool ResolveBidi(Array<TextPiece>& pieces, fonts::TextDirection direction, bool autoRightToLeft,
                                              f32 letterSpacing)
        {
            const bool automatic = direction == fonts::TextDirection::Auto;
            const u8 baseLevel = direction == fonts::TextDirection::RightToLeft || (automatic && autoRightToLeft) ? 1 : 0;
            bool rightToLeftText = false; // (a right-to-left base needs the path even for no text)
            for (const TextPiece& piece : pieces)
                for (usize i = 0; i < piece.Text.Size() && !rightToLeftText; ++i)
                    rightToLeftText = static_cast<u8>(piece.Text[i]) >= 0xD6; // a lead byte of U+0590 or above
            if (baseLevel == 0 && !rightToLeftText)
                return false;
            fonts::IBidiResolver* resolver = fonts::BidiResolverFactory::Resolver();
            Array<TextPiece> out;
            Array<u32> codepoints;
            Array<usize> owner;  // each character's piece
            Array<usize> within; // its byte in that piece's text
            fonts::BidiLevels levels;
            bool any = baseLevel != 0;
            usize first = 0;
            while (first < pieces.Size())
            {
                usize last = first; // a paragraph runs to its break
                while (last < pieces.Size() && !pieces[last].LineBreak)
                    ++last;
                codepoints.Clear();
                owner.Clear();
                within.Clear();
                for (usize p = first; p < last; ++p)
                {
                    if (pieces[p].Icon)
                    {
                        codepoints.PushBack(0xFFFC);
                        owner.PushBack(p);
                        within.PushBack(0);
                        continue;
                    }
                    const core::StringView t = pieces[p].Text;
                    for (usize i = 0; i < t.Size();)
                    {
                        within.PushBack(i);
                        codepoints.PushBack(static_cast<u32>(core::DecodeUtf8(t, i)));
                        owner.PushBack(p);
                    }
                }
                // An auto paragraph runs as its first strong character reads, else as its node does;
                // the resolver is then told which (a resolver alone would make it left to right).
                u8 paragraph = baseLevel;
                fonts::TextDirection paragraphDirection = direction;
                if (automatic)
                {
                    const i32 strong = FirstStrongDirection(codepoints);
                    paragraph = strong >= 0 ? static_cast<u8>(strong) : baseLevel;
                    paragraphDirection = paragraph != 0 ? fonts::TextDirection::RightToLeft : fonts::TextDirection::LeftToRight;
                }
                levels.levels.Clear();
                const bool resolved = resolver != nullptr && !codepoints.IsEmpty();
                if (resolved)
                {
                    resolver->Resolve(Span<const u32>(codepoints.Data(), codepoints.Size()), paragraphDirection, levels);
                    paragraph = levels.paragraphLevel;
                }
                while (levels.levels.Size() < codepoints.Size())
                    levels.levels.PushBack(resolved ? paragraph : u8{0});
                any = any || paragraph != 0;
                usize c = 0;
                for (usize p = first; p < last; ++p)
                {
                    const TextPiece& piece = pieces[p];
                    const usize begin = c;
                    while (c < owner.Size() && owner[c] == p)
                        ++c;
                    if (begin == c)
                    {
                        TextPiece part = piece;
                        part.Level = part.ParagraphLevel = paragraph;
                        out.PushBack(part);
                        continue;
                    }
                    usize from = begin;
                    for (usize k = begin + 1; k <= c; ++k)
                    {
                        if (k < c && levels.levels[k] == levels.levels[from])
                            continue;
                        TextPiece part = piece;
                        part.Level = levels.levels[from];
                        part.ParagraphLevel = paragraph;
                        part.Shaping = !resolved ? fonts::TextDirection::Auto
                                       : (part.Level & 1u) != 0 ? fonts::TextDirection::RightToLeft
                                                                : fonts::TextDirection::LeftToRight;
                        if (!piece.Icon && (from != begin || k != c))
                        {
                            const usize a = within[from];
                            const usize b = k == c ? piece.Text.Size() : within[k];
                            part.Text = piece.Text.SubStr(a, b - a);
                            part.Start = piece.Start + a;
                            part.Width = 0.0f;
                            part.TrailingSpace = 0.0f;
                            MeasurePiece(part, letterSpacing);
                        }
                        any = any || part.Level != 0;
                        out.PushBack(part);
                        from = k;
                    }
                }
                if (last < pieces.Size())
                {
                    TextPiece lineBreak = pieces[last];
                    lineBreak.Level = lineBreak.ParagraphLevel = paragraph;
                    out.PushBack(lineBreak);
                }
                first = last + 1;
            }
            pieces = Move(out);
            return any;
        }

        // Places pieces [from, to) of one line in visual order (rule L1: its trailing spaces at
        // the paragraph's level; L2: the runs at each level reversed), each from where the one to
        // its left ends. The line's last piece in logical order loses its trailing spaces' width,
        // which hang past its end (to its left when it reads right to left).
        inline void OrderLine(Array<TextPiece>& pieces, usize from, usize to, u8 baseLevel, LaidOutLine& line)
        {
            Array<usize> items;
            for (usize p = from; p < to; ++p)
                if (!pieces[p].LineBreak)
                    items.PushBack(p);
            const u8 paragraph = from < to ? pieces[from].ParagraphLevel : baseLevel; // an empty text: the base's
            line.RightToLeft = (paragraph & 1u) != 0;
            if (items.IsEmpty())
                return;
            fonts::BidiLevels levels;
            levels.paragraphLevel = paragraph;
            Array<u32> marks; // no character is whitespace to ReorderLine: L1 is applied by piece here
            for (const usize p : items)
            {
                levels.levels.PushBack(pieces[p].Level);
                marks.PushBack(U'x');
            }
            for (usize k = items.Size(); k-- > 0;)
            {
                const TextPiece& piece = pieces[items[k]];
                if (piece.Icon || piece.Text.Size() == 0 || piece.TrailingSpace < piece.Width - 0.001f)
                    break;
                levels.levels[k] = paragraph; // a piece of nothing but spaces at the line's end
            }
            Array<fonts::BidiRun> runs;
            fonts::ReorderLine(levels, Span<const u32>(marks.Data(), marks.Size()), 0, items.Size(), runs);
            const usize lastLogical = items.Back();
            f32 x = 0.0f;
            const auto place = [&](usize p)
            {
                TextPiece& piece = pieces[p];
                f32 width = piece.Width;
                f32 hang = 0.0f;
                if (p == lastLogical)
                {
                    width -= piece.TrailingSpace;
                    if ((piece.Level & 1u) != 0)
                        hang = piece.TrailingSpace;
                }
                piece.X = x - hang;
                x += width;
            };
            for (const fonts::BidiRun& run : runs)
            {
                if (run.RightToLeft())
                    for (usize k = run.end; k-- > run.start;)
                        place(items[k]);
                else
                    for (usize k = run.start; k < run.end; ++k)
                        place(items[k]);
            }
        }

        // A piece's glyphs from a list of faces, as runs of one face each (the face a run is drawn
        // and measured with), in order.
        inline void SplitByFace(TextLayout& layout, LaidOutGlyphs&& glyphs, const ResolvedRunFont& font)
        {
            usize g = 0;
            while (g < glyphs.Glyphs.Size())
            {
                const u8 face = glyphs.Glyphs[g].font;
                LaidOutGlyphs part;
                part.Font = face < font.FaceCount() ? font.Face(face) : font.Font;
                part.TextColor = glyphs.TextColor;
                part.Size = glyphs.Size;
                part.SyntheticBold = glyphs.SyntheticBold;
                part.SyntheticItalic = glyphs.SyntheticItalic;
                part.Baseline = glyphs.Baseline;
                part.Line = glyphs.Line;
                part.Run = glyphs.Run;
                part.TextStart = glyphs.GlyphStart[g];
                part.TextEnd = glyphs.GlyphEnd[g];
                f32 left = glyphs.Glyphs[g].x;
                f32 right = left;
                for (; g < glyphs.Glyphs.Size() && glyphs.Glyphs[g].font == face; ++g)
                {
                    const fonts::GlyphPosition& glyph = glyphs.Glyphs[g];
                    part.Glyphs.PushBack(glyph);
                    part.GlyphStart.PushBack(glyphs.GlyphStart[g]);
                    part.GlyphEnd.PushBack(glyphs.GlyphEnd[g]);
                    part.TextStart = Min(part.TextStart, glyphs.GlyphStart[g]);
                    part.TextEnd = Max(part.TextEnd, glyphs.GlyphEnd[g]);
                    left = Min(left, glyph.x);
                    right = Max(right, glyph.x + glyph.advance);
                }
                part.X = left;
                part.Width = right - left;
                layout.GlyphRuns.PushBack(Move(part));
            }
        }

        // Shifts everything laid out on `line` across by `dx`.
        inline void ShiftLine(TextLayout& layout, usize line, f32 dx)
        {
            if (dx == 0.0f)
                return;
            for (LaidOutGlyphs& run : layout.GlyphRuns)
                if (run.Line == line)
                {
                    run.X += dx;
                    for (fonts::GlyphPosition& g : run.Glyphs)
                        g.x += dx;
                }
            Array<LaidOutBox>* lists[] = {&layout.Icons, &layout.Underlines, &layout.Links};
            for (Array<LaidOutBox>* boxes : lists)
                for (LaidOutBox& box : *boxes)
                    if (box.Line == line)
                        box.Rect.x += dx;
        }

        // Keeps only what of `line` lies in [from, to) across; what straddles an edge is cut
        // (a glyph goes whole, a box is narrowed). Returns the right edge of what stayed, and sets
        // `left` to its left edge.
        inline f32 KeepSpan(TextLayout& layout, usize line, f32 from, f32 to, f32* left = nullptr)
        {
            f32 right = from;
            f32 leftmost = to;
            for (LaidOutGlyphs& run : layout.GlyphRuns)
            {
                if (run.Line != line || run.Unshaped)
                    continue;
                Array<fonts::GlyphPosition> glyphs;
                Array<usize> starts, ends;
                for (usize g = 0; g < run.Glyphs.Size(); ++g)
                {
                    const fonts::GlyphPosition& glyph = run.Glyphs[g];
                    if (glyph.x < from - 0.01f || glyph.x + glyph.advance > to + 0.01f)
                        continue;
                    glyphs.PushBack(glyph);
                    starts.PushBack(run.GlyphStart[g]);
                    ends.PushBack(run.GlyphEnd[g]);
                    right = Max(right, glyph.x + glyph.advance);
                    leftmost = Min(leftmost, glyph.x);
                }
                if (!glyphs.IsEmpty())
                {
                    // Its start and advance are its glyphs' that stayed.
                    run.X = glyphs[0].x;
                    run.Width = glyphs.Back().x + glyphs.Back().advance - run.X;
                }
                run.Glyphs = Move(glyphs);
                run.GlyphStart = Move(starts);
                run.GlyphEnd = Move(ends);
            }
            for (usize r = layout.GlyphRuns.Size(); r-- > 0;)
                if (layout.GlyphRuns[r].Line == line && !layout.GlyphRuns[r].Unshaped && layout.GlyphRuns[r].Glyphs.IsEmpty())
                    layout.GlyphRuns.RemoveAt(r);
            Array<LaidOutBox>* lists[] = {&layout.Icons, &layout.Underlines, &layout.Links};
            for (Array<LaidOutBox>* boxes : lists)
            {
                const bool whole = boxes == &layout.Icons; // an icon is not cut in two
                for (usize b = boxes->Size(); b-- > 0;)
                {
                    LaidOutBox& box = (*boxes)[b];
                    if (box.Line != line)
                        continue;
                    const f32 left = Max(box.Rect.x, from);
                    const f32 boxRight = Min(box.Rect.x + box.Rect.width, to);
                    if (boxRight <= left || (whole && (box.Rect.x < from - 0.01f || box.Rect.x + box.Rect.width > to + 0.01f)))
                    {
                        boxes->RemoveAt(b);
                        continue;
                    }
                    box.Rect.x = left;
                    box.Rect.width = boxRight - left;
                    if (whole)
                    {
                        right = Max(right, boxRight);
                        leftmost = Min(leftmost, left);
                    }
                }
            }
            if (left != nullptr)
                *left = leftmost;
            return right;
        }

        // An ellipsis on `line` at x in the style of `like`.
        inline void AddEllipsis(TextLayout& layout, usize line, f32 x, const LaidOutGlyphs& like, usize offset)
        {
            LaidOutGlyphs ellipsis;
            ellipsis.Font = like.Font;
            ellipsis.TextColor = like.TextColor;
            ellipsis.Size = like.Size;
            ellipsis.SyntheticBold = like.SyntheticBold;
            ellipsis.SyntheticItalic = like.SyntheticItalic;
            ellipsis.Baseline = layout.Lines[line].Baseline;
            ellipsis.X = x;
            ellipsis.Line = line;
            ellipsis.Run = -1;
            ellipsis.TextStart = ellipsis.TextEnd = offset;
            if (like.Font != nullptr && like.Font->shaper != nullptr && like.Font->font != nullptr &&
                like.Font->shaper->ShapeText(*like.Font->font, EllipsisFor(like.Font), x, ellipsis.Baseline, ellipsis.Glyphs)
                    .HasValue())
            {
                for (const fonts::GlyphPosition& g : ellipsis.Glyphs)
                {
                    ellipsis.Width += g.advance;
                    ellipsis.GlyphStart.PushBack(offset);
                    ellipsis.GlyphEnd.PushBack(offset);
                }
                layout.GlyphRuns.PushBack(Move(ellipsis));
            }
        }
        [[nodiscard]] inline f32 EllipsisWidth(const LaidOutGlyphs& like)
        {
            return like.Font != nullptr && like.Font->font != nullptr ? like.Font->font->MeasureString(EllipsisFor(like.Font)) : 0.0f;
        }

        // Ends `line` in an ellipsis where it passes `maxWidth` (always, when `forced`: the clamp cut
        // the lines after it), at its end, start or middle. The line is still unaligned (from 0).
        inline void Ellipsize(TextLayout& layout, usize line, f32 maxWidth, TextOverflow mode, bool forced, bool rightToLeft = false)
        {
            LaidOutLine& at = layout.Lines[line];
            const LaidOutGlyphs* first = nullptr;
            const LaidOutGlyphs* last = nullptr;
            for (const LaidOutGlyphs& run : layout.GlyphRuns)
                if (run.Line == line && !run.Unshaped && !run.Glyphs.IsEmpty())
                {
                    if (first == nullptr)
                        first = &run;
                    last = &run;
                }
            if (last == nullptr)
                return; // nothing shaped to cut
            const LaidOutGlyphs firstStyle = *first; // copies: the runs change below
            const LaidOutGlyphs lastStyle = *last;
            const f32 width = at.Width;
            if (forced)
                mode = rightToLeft ? TextOverflow::EllipsisStart : TextOverflow::Ellipsis; // a clamped paragraph ends at its end: its left in right to left
            const f32 e = EllipsisWidth(mode == TextOverflow::EllipsisStart ? firstStyle : lastStyle);
            const f32 room = Max(0.0f, maxWidth - e);
            if (mode == TextOverflow::Ellipsis)
            {
                const f32 limit = forced && width + e <= maxWidth ? width : room;
                const f32 right = KeepSpan(layout, line, 0.0f, limit);
                AddEllipsis(layout, line, right, lastStyle, at.End);
                at.Width = right + e;
            }
            else if (mode == TextOverflow::EllipsisStart)
            {
                // The tail from where its first whole glyph starts, moved up to the ellipsis.
                const f32 cut = width - room;
                f32 kept = cut;
                (void)KeepSpan(layout, line, cut, width + 1.0f, &kept);
                ShiftLine(layout, line, e - kept);
                AddEllipsis(layout, line, 0.0f, firstStyle, at.Start);
                at.Width = width - kept + e;
            }
            else
            {
                // A head and a tail of half the room each, the ellipsis between.
                const f32 half = room * 0.5f;
                const f32 tailFrom = width - half;
                // The tail moves next to the head: kept apart, then shifted.
                TextLayout tail = layout;
                const f32 headRight = KeepSpan(layout, line, 0.0f, half);
                f32 tailLeft = tailFrom;
                (void)KeepSpan(tail, line, tailFrom, width + 1.0f, &tailLeft);
                const f32 shift = headRight + e - tailLeft;
                for (LaidOutGlyphs& run : tail.GlyphRuns)
                    if (run.Line == line && !run.Unshaped)
                    {
                        run.X += shift;
                        for (fonts::GlyphPosition& g : run.Glyphs)
                            g.x += shift;
                        layout.GlyphRuns.PushBack(Move(run));
                    }
                for (LaidOutBox& box : tail.Icons)
                    if (box.Line == line)
                    {
                        box.Rect.x += shift;
                        layout.Icons.PushBack(box);
                    }
                for (LaidOutBox& box : tail.Underlines)
                    if (box.Line == line)
                    {
                        box.Rect.x += shift;
                        layout.Underlines.PushBack(box);
                    }
                for (LaidOutBox& box : tail.Links)
                    if (box.Line == line)
                    {
                        box.Rect.x += shift;
                        layout.Links.PushBack(box);
                    }
                AddEllipsis(layout, line, headRight, lastStyle, at.Start);
                at.Width = headRight + e + (width - tailLeft);
            }
            at.Ellipsized = true;
        }
    }

    /// Lay a document out.
    [[nodiscard]] inline TextLayout LayOutText(const TextDocument& document, const TextLayoutStyle& style)
    {
        using detail::TextPiece;
        const f32 spacing = style.LetterSpacing;
        Array<TextPiece> pieces;
        usize runStart = 0; // the run's first byte in the plain text
        for (usize r = 0; r < document.Runs.Size(); ++r)
        {
            const TextRun& run = document.Runs[r];
            const ResolvedRunFont font = ResolveRunFont(run, style);
            if (run.IsIcon())
            {
                TextPiece piece;
                piece.Run = static_cast<i32>(r);
                piece.Start = runStart;
                piece.Font = font;
                piece.Icon = true;
                detail::MeasurePiece(piece, spacing);
                piece.Width = font.Size;
                piece.Ascent = Max(piece.Ascent, font.Size);
                pieces.PushBack(piece);
                runStart += 3; // U+FFFC in the plain text
                continue;
            }
            const core::StringView text = run.Text.AsView();
            usize start = 0;
            usize i = 0;
            const auto emit = [&](usize end)
            {
                if (end <= start)
                    return;
                TextPiece piece;
                piece.Run = static_cast<i32>(r);
                piece.Text = text.SubStr(start, end - start);
                piece.Start = runStart + start;
                piece.Font = font;
                detail::MeasurePiece(piece, spacing);
                pieces.PushBack(piece);
            };
            while (i < text.Size())
            {
                if (text[i] == u8'\n')
                {
                    emit(i);
                    TextPiece lineBreak;
                    lineBreak.Run = static_cast<i32>(r);
                    lineBreak.Start = runStart + i;
                    lineBreak.Font = font;
                    lineBreak.LineBreak = true;
                    detail::MeasurePiece(lineBreak, spacing);
                    pieces.PushBack(lineBreak);
                    start = ++i;
                    continue;
                }
                if (text[i] == u8' ')
                {
                    while (i < text.Size() && text[i] == u8' ')
                        ++i;
                    emit(i); // a word takes the spaces after it
                    start = i;
                    continue;
                }
                ++i;
            }
            emit(text.Size());
            runStart += text.Size();
        }

        const bool bidi = detail::ResolveBidi(pieces, style.Direction, style.AutoRightToLeft, spacing);

        // The base font's metrics size an empty line.
        TextPiece empty;
        empty.Font = ResolveRunFont(TextRun{}, style);
        detail::MeasurePiece(empty, spacing);

        TextLayout layout;
        layout.Text = document.PlainText();
        const bool bounded = style.MaxWidth > 0.0f;
        usize lineStart = 0;
        f32 x = 0.0f;
        usize nextOffset = 0; // where the next line's text starts
        Array<usize> lineFirstPiece; // each line's first piece (its last is before the next's first)
        const auto finishLine = [&](usize end)
        {
            lineFirstPiece.PushBack(lineStart);
            LaidOutLine line;
            line.Top = layout.Height;
            f32 ascent = 0.0f, descent = 0.0f, gap = 0.0f;
            bool any = false;
            for (usize p = lineStart; p < end; ++p)
            {
                ascent = Max(ascent, pieces[p].Ascent);
                descent = Max(descent, pieces[p].Descent);
                gap = Max(gap, pieces[p].Gap);
                any = any || !pieces[p].LineBreak;
            }
            if (!any)
            {
                // A line with nothing on it is as tall as its break's font, or the base font's.
                const TextPiece& sized = (end > lineStart) ? pieces[lineStart] : empty;
                ascent = sized.Ascent;
                descent = sized.Descent;
                gap = sized.Gap;
            }
            if (style.LineHeight > 0.0f)
            {
                // CSS's half-leading: the line's extra height (or what it lacks) split above and below.
                line.Height = style.LineHeight;
                line.Baseline = line.Top + (style.LineHeight - (ascent + descent)) * 0.5f + ascent;
            }
            else
            {
                line.Height = ascent + descent + gap;
                line.Baseline = line.Top + ascent;
            }
            line.Width = x;
            for (usize p = end; p > lineStart; --p)
            {
                if (pieces[p - 1].LineBreak)
                    continue;
                line.Width -= pieces[p - 1].TrailingSpace;
                break;
            }
            line.Start = nextOffset;
            line.End = nextOffset;
            for (usize p = lineStart; p < end; ++p)
            {
                pieces[p].Line = layout.Lines.Size();
                if (pieces[p].LineBreak)
                {
                    line.End = pieces[p].Start;
                    nextOffset = pieces[p].Start + 1;
                }
                else
                {
                    line.End = pieces[p].Start + (pieces[p].Icon ? 3 : pieces[p].Text.Size());
                    nextOffset = line.End;
                }
            }
            layout.Lines.PushBack(line);
            layout.Height += line.Height;
            lineStart = end;
            x = 0.0f;
        };
        for (usize p = 0; p < pieces.Size(); ++p)
        {
            TextPiece& piece = pieces[p];
            if (piece.LineBreak)
            {
                finishLine(p + 1);
                continue;
            }
            if (style.Wrap && bounded && p > lineStart && x + piece.Width - piece.TrailingSpace > style.MaxWidth)
                finishLine(p);
            // overflow-wrap (E11): a word wider than the whole line breaks where the line ends,
            // between graphemes (one at the least), the rest going on as a piece of its own.
            if (style.Wrap && style.BreakWords && bounded && !piece.Icon && p == lineStart &&
                piece.Width - piece.TrailingSpace > style.MaxWidth)
            {
                const usize cut = detail::FittingPrefix(piece, style.MaxWidth, spacing);
                if (cut < piece.Text.Size())
                {
                    TextPiece rest = piece;
                    rest.Text = piece.Text.SubStr(cut, piece.Text.Size() - cut);
                    rest.Start = piece.Start + cut;
                    rest.Width = rest.TrailingSpace = 0.0f;
                    detail::MeasurePiece(rest, spacing);
                    piece.Text = piece.Text.SubStr(0, cut);
                    piece.Width = piece.TrailingSpace = 0.0f;
                    detail::MeasurePiece(piece, spacing);
                    pieces.Insert(p + 1, Move(rest));
                }
            }
            pieces[p].X = x;
            x += pieces[p].Width;
        }
        if (lineStart < pieces.Size() || layout.Lines.IsEmpty() || (!pieces.IsEmpty() && pieces.Back().LineBreak))
            finishLine(pieces.Size());

        // The clamp: the lines past it go.
        usize keptLines = layout.Lines.Size();
        if (style.MaxLines > 0 && keptLines > style.MaxLines)
        {
            keptLines = style.MaxLines;
            layout.Lines.Resize(keptLines);
            layout.Clamped = true;
            layout.Height = layout.Lines.Back().Top + layout.Lines.Back().Height;
        }

        // Each line in visual order (E9c), its pieces placed again from its left.
        if (bidi)
            for (usize l = 0; l < keptLines; ++l)
                detail::OrderLine(pieces, lineFirstPiece[l], l + 1 < lineFirstPiece.Size() ? lineFirstPiece[l + 1] : pieces.Size(),
                                  style.Direction == fonts::TextDirection::RightToLeft ||
                                          (style.Direction == fonts::TextDirection::Auto && style.AutoRightToLeft)
                                      ? u8{1}
                                      : u8{0},
                                  layout.Lines[l]);

        // Glyphs, icons, underlines and links, from each line's start.
        Array<usize> offsets;
        for (usize p = 0; p < pieces.Size(); ++p)
        {
            const TextPiece& piece = pieces[p];
            if (piece.LineBreak || piece.Line >= keptLines)
                continue;
            const LaidOutLine& at = layout.Lines[piece.Line];
            const TextRun& run = document.Runs[static_cast<usize>(piece.Run)];
            const Color color = run.TextColor.HasValue() ? run.TextColor.Value() : style.TextColor;
            const f32 visible = piece.Width - piece.TrailingSpace;
            if (piece.Icon)
            {
                LaidOutBox icon;
                icon.Rect = Rectangle{piece.X, at.Baseline - piece.Font.Size, piece.Font.Size, piece.Font.Size};
                icon.Run = piece.Run;
                icon.Line = piece.Line;
                layout.Icons.PushBack(icon);
            }
            else if (piece.Font.Font != nullptr)
            {
                LaidOutGlyphs glyphs;
                glyphs.Font = piece.Font.Font;
                glyphs.TextColor = color;
                glyphs.Size = piece.Font.Size;
                glyphs.SyntheticBold = piece.Font.SyntheticBold;
                glyphs.SyntheticItalic = piece.Font.SyntheticItalic;
                glyphs.Baseline = at.Baseline;
                glyphs.X = piece.X;
                glyphs.Width = piece.Width;
                glyphs.TextStart = piece.Start;
                glyphs.TextEnd = piece.Start + piece.Text.Size();
                glyphs.Line = piece.Line;
                glyphs.Run = piece.Run;
                // Shaped as it reads (E9c): one way, the level its piece is at.
                const auto shape = [&]() -> bool
                {
                    fonts::ITextShaper& shaper = *piece.Font.Font->shaper;
                    if (!bidi && piece.Font.FallbackCount == 0)
                        return shaper.ShapeText(*piece.Font.Font->font, piece.Text, piece.X, at.Baseline, glyphs.Glyphs).HasValue();
                    // Its faces in order: a character takes the first that has it.
                    fonts::IFont* list[1 + ResolvedRunFont::kMaxFallbacks]{};
                    for (usize f = 0; f < piece.Font.FaceCount(); ++f)
                        list[f] = piece.Font.Face(f)->font;
                    fonts::ShapeRequest request;
                    request.text = piece.Text;
                    request.fonts = Span<fonts::IFont* const>(list, piece.Font.FaceCount());
                    request.direction = piece.Shaping;
                    request.startX = piece.X;
                    request.startY = at.Baseline;
                    return shaper.Shape(request, glyphs.Glyphs).HasValue();
                };
                if (piece.Font.Font->shaper != nullptr && piece.Font.Font->font != nullptr && shape())
                {
                    // Each glyph's bytes from its cluster (a character index); letter spacing after
                    // every character before it.
                    detail::CodepointOffsets(piece.Text, piece.Start, offsets);
                    const usize count = offsets.Size() - 1;
                    for (fonts::GlyphPosition& g : glyphs.Glyphs)
                    {
                        const usize first = core::Min(static_cast<usize>(core::Max(0, g.cluster)), count);
                        const usize last = core::Min(static_cast<usize>(core::Max(0, g.ClusterEnd())), count);
                        glyphs.GlyphStart.PushBack(offsets[first]);
                        glyphs.GlyphEnd.PushBack(offsets[last]);
                        g.x += spacing * static_cast<f32>(first);
                        g.advance += spacing * static_cast<f32>(last - first);
                    }
                }
                else
                {
                    // No shaper: a position for each character from the widths of what comes
                    // before it, so carets still find their places; drawn as text.
                    glyphs.Glyphs.Clear();
                    glyphs.Unshaped = true;
                    detail::CodepointOffsets(piece.Text, piece.Start, offsets);
                    f32 before = 0.0f;
                    for (usize c = 0; c + 1 < offsets.Size(); ++c)
                    {
                        const usize end = offsets[c + 1] - piece.Start;
                        const f32 after = piece.Font.Font->font != nullptr
                                              ? piece.Font.Font->font->MeasureString(piece.Text.SubStr(0, end)) + spacing * static_cast<f32>(c + 1)
                                              : before;
                        fonts::GlyphPosition g;
                        g.cluster = static_cast<i32>(c);
                        g.x = piece.X + before;
                        g.y = at.Baseline;
                        g.advance = after - before;
                        glyphs.Glyphs.PushBack(g);
                        glyphs.GlyphStart.PushBack(offsets[c]);
                        glyphs.GlyphEnd.PushBack(offsets[c + 1]);
                        before = after;
                    }
                }
                if (piece.Font.FallbackCount == 0 || glyphs.Unshaped)
                    layout.GlyphRuns.PushBack(Move(glyphs));
                else
                    detail::SplitByFace(layout, Move(glyphs), piece.Font);
            }
            if (run.Underline && visible > 0.0f && piece.Font.Font != nullptr && piece.Font.Font->font != nullptr)
            {
                const fonts::TextDecorationMetrics decorations = piece.Font.Font->font->Metrics().decorations;
                LaidOutBox underline;
                // A word's underline runs on under the spaces after it unless it ends the line.
                // (Its spaces are on its left when it reads right to left.)
                const bool lastOnLine = p + 1 >= pieces.Size() || pieces[p + 1].LineBreak || pieces[p + 1].Line != piece.Line;
                const f32 hang = lastOnLine && (piece.Level & 1u) != 0 ? piece.TrailingSpace : 0.0f;
                underline.Rect = Rectangle{piece.X + hang, at.Baseline + decorations.underlinePosition,
                                           lastOnLine ? visible : piece.Width, decorations.underlineThickness};
                underline.Run = piece.Run;
                underline.Line = piece.Line;
                underline.TextColor = color;
                layout.Underlines.PushBack(underline);
            }
            if (run.Link.Size() != 0)
            {
                LaidOutBox link;
                link.Rect = Rectangle{piece.X, at.Top, piece.Width, at.Height};
                link.Run = piece.Run;
                link.Line = piece.Line;
                layout.Links.PushBack(link);
            }
        }

        // An ellipsis where a line passes the width (or ends a clamped paragraph), then alignment.
        for (usize l = 0; l < layout.Lines.Size(); ++l)
        {
            const bool forced = layout.Clamped && l + 1 == layout.Lines.Size() && style.Overflow != TextOverflow::Clip;
            // A right-to-left line ends on its left: its end ellipsis is the visual start's.
            TextOverflow overflow = style.Overflow;
            if (layout.Lines[l].RightToLeft && overflow == TextOverflow::Ellipsis)
                overflow = TextOverflow::EllipsisStart;
            else if (layout.Lines[l].RightToLeft && overflow == TextOverflow::EllipsisStart)
                overflow = TextOverflow::Ellipsis;
            if (bounded && style.Overflow != TextOverflow::Clip && (forced || layout.Lines[l].Width > style.MaxWidth + 0.01f))
                detail::Ellipsize(layout, l, style.MaxWidth, overflow, forced, layout.Lines[l].RightToLeft);
            LaidOutLine& line = layout.Lines[l];
            // Start and end are the paragraph's (E9c).
            TextHAlign align = style.Align;
            if (align == TextHAlign::Start)
                align = line.RightToLeft ? TextHAlign::Right : TextHAlign::Left;
            else if (align == TextHAlign::End)
                align = line.RightToLeft ? TextHAlign::Left : TextHAlign::Right;
            if (bounded && align == TextHAlign::Center)
                line.Left = (style.MaxWidth - line.Width) * 0.5f;
            else if (bounded && align == TextHAlign::Right)
                line.Left = style.MaxWidth - line.Width;
            detail::ShiftLine(layout, l, line.Left);
            layout.Width = Max(layout.Width, line.Width);
        }
        return layout;
    }
}
