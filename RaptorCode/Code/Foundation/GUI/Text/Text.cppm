// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :text partition
//
// Text: what a widget measures and draws its text with (E4 of Specs/gui-lab-evolution.md). It holds
// a string, or a rich text's runs from markup, and lays them out through :text_layout: shaped, wrapped
// as CSS's white-space says, its lines as tall as line-height says, letter-spaced, clamped to a line
// count and ended by an ellipsis where they overflow. The layout is cached for the last widths asked
// (a widget measures unbounded and draws at its width), and laid out again only when something it
// reads changes. It holds a non-owning CachedFont (the font service owns it), and a service for runs
// that set a font of their own, and draws through the DrawContext's VG.

module;
#include "Core/Prelude.h"

export module foundation.gui:text;

import foundation.core;  // String, StringView, Float2, Color, Array, Max
import foundation.fonts; // CachedFont, IFontService
import foundation.vg;    // TextEffects
import foundation.image; // ImageData
import foundation.vg.svg; // SVGDocument, SVGRenderer (an inline icon an SVG)
export import :text_layout; // TextHAlign, TextVAlign, TextWhiteSpace, TextOverflow, TextLayout
import :text_runs;
import :rect;
import :draw_context;
import :resource_provider;

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// A character in lower case, for the scripts type-ahead matches by case: Latin (ASCII,
    /// Latin-1 and Latin Extended-A), Greek and Cyrillic; any other as it is.
    [[nodiscard]] constexpr char32_t SimpleLowerCase(char32_t c) noexcept
    {
        if ((c >= U'A' && c <= U'Z') || (c >= 0xC0 && c <= 0xDE && c != 0xD7) || (c >= 0x391 && c <= 0x3AB && c != 0x3A2) ||
            (c >= 0x410 && c <= 0x42F))
            return c + 0x20;
        if (c >= 0x400 && c <= 0x40F)
            return c + 0x50;
        // Latin Extended-A pairs: upper case even, lower odd, but for a run where it is the other way.
        if ((c >= 0x100 && c <= 0x137 && c != 0x130 && (c & 1u) == 0) || (c >= 0x14A && c <= 0x177 && (c & 1u) == 0))
            return c + 1;
        if (((c >= 0x139 && c <= 0x148) || (c >= 0x179 && c <= 0x17E)) && (c & 1u) == 1)
            return c + 1;
        if (c == 0x178)
            return 0xFF;
        return c;
    }

    /// Whether `text` starts with `prefix`, letters in either case alike (SimpleLowerCase): what
    /// type-ahead matches.
    [[nodiscard]] inline bool StartsWithIgnoringCase(core::StringView text, core::StringView prefix) noexcept
    {
        usize t = 0;
        usize p = 0;
        while (p < prefix.Size())
        {
            if (t >= text.Size())
                return false;
            if (SimpleLowerCase(static_cast<char32_t>(core::DecodeUtf8(text, t))) !=
                SimpleLowerCase(static_cast<char32_t>(core::DecodeUtf8(prefix, p))))
                return false;
        }
        return true;
    }

    /// A label's text with its access key marked (`&File`, E12 of Specs/gui-lab-evolution-2.md):
    /// what it shows (`File`, `&&` an ampersand), the key (the marked character, lower case; 0 for
    /// none) and the bytes of the shown text it underlines.
    struct Mnemonic
    {
        core::String Shown;
        char32_t Key = 0;
        usize Start = 0;
        usize End = 0;
    };
    [[nodiscard]] inline Mnemonic ParseMnemonic(core::StringView text)
    {
        Mnemonic out;
        for (usize i = 0; i < text.Size();)
        {
            if (text[i] == u8'&' && i + 1 < text.Size())
            {
                if (text[i + 1] == u8'&')
                {
                    out.Shown.PushBack(u8'&');
                    i += 2;
                    continue;
                }
                if (out.Key == 0)
                {
                    usize next = i + 1;
                    const char32_t c = static_cast<char32_t>(core::DecodeUtf8(text, next));
                    out.Key = c >= U'A' && c <= U'Z' ? c - U'A' + U'a' : c;
                    out.Start = out.Shown.Size();
                    out.Shown.Append(text.SubStr(i + 1, next - i - 1));
                    out.End = out.Shown.Size();
                    i = next;
                    continue;
                }
            }
            out.Shown.PushBack(text[i]);
            ++i;
        }
        return out;
    }

    class Text
    {
    public:
        Text() = default;
        Text(core::StringView string, fonts::CachedFont* font, Color color = Color::White)
            : m_string(string), m_font(font), m_color(color)
        {
        }

        // === What it shows ===
        /// Plain text.
        void SetString(core::StringView string)
        {
            if (!m_rich && string == m_string.AsView())
                return;
            m_string = core::String(string);
            m_rich = false;
            Dirty();
        }
        /// A rich text's markup ([b], [color=], [link=] and the rest, :text_runs).
        void SetMarkup(core::StringView markup)
        {
            if (m_rich && markup == m_string.AsView())
                return;
            m_string = core::String(markup);
            m_rich = true;
            Dirty();
        }
        /// Underlines bytes [start, end) of a plain text (a mnemonic's letter, E12); start == end: none.
        void SetUnderline(usize start, usize end)
        {
            if (start == m_underlineStart && end == m_underlineEnd)
                return;
            m_underlineStart = start;
            m_underlineEnd = end;
            Dirty();
        }
        /// What was set: the plain text, or the markup.
        [[nodiscard]] core::StringView GetString() const { return m_string.AsView(); }
        [[nodiscard]] bool IsRich() const noexcept { return m_rich; }
        [[nodiscard]] bool IsEmpty() const { return m_string.Size() == 0; }
        /// The runs it lays out (spaces collapsed where its white-space says).
        [[nodiscard]] const TextDocument& Document() const
        {
            Sync();
            return m_document;
        }
        /// The text it lays out, markup taken out and spaces collapsed: what the layout's offsets count.
        [[nodiscard]] core::StringView PlainText() const
        {
            Sync();
            return m_plain.AsView();
        }

        // === How it looks ===
        void SetFont(fonts::CachedFont* font)
        {
            if (font == m_font)
                return;
            m_font = font;
            Dirty();
        }
        [[nodiscard]] fonts::CachedFont* GetFont() const noexcept { return m_font; }
        /// What of the font CSS chose past its size: the family as the sheet names it (its faces
        /// are named after it, not after the font file's own name), the fallback families, the
        /// weight and the style; and the service that has those faces (a rich text's own faces
        /// come from it too).
        void SetFontSelection(fonts::IFontService* service, core::StringView family, const FontSelection& selection)
        {
            if (!(selection == FontSelection{}))
                SetFontService(service);
            if (selection == m_selection && family == m_family.AsView())
                return;
            m_selection = selection;
            m_family = core::String(family);
            Dirty();
        }
        /// A font that can draw (one is set and loaded).
        [[nodiscard]] bool HasFont() const noexcept { return m_font != nullptr && m_font->font != nullptr; }
        /// Resolves runs that set a family, a size, bold or italic of their own (null: they take its font).
        void SetFontService(fonts::IFontService* service)
        {
            if (service == m_fontService)
                return;
            m_fontService = service;
            Dirty();
        }
        [[nodiscard]] fonts::IFontService* GetFontService() const noexcept { return m_fontService; }
        /// Loads a rich text's inline icons (null: they keep their space, undrawn).
        void SetResourceProvider(IResourceProvider* resources) noexcept { m_resources = resources; }

        void SetColor(Color color)
        {
            if (color == m_color)
                return;
            m_color = color;
            Dirty();
        }
        [[nodiscard]] Color GetColor() const noexcept { return m_color; }

        void SetAlignment(TextHAlign horizontal, TextVAlign vertical)
        {
            if (horizontal == m_hAlign && vertical == m_vAlign)
                return;
            m_hAlign = horizontal;
            m_vAlign = vertical;
            Dirty();
        }
        [[nodiscard]] TextHAlign GetHAlign() const noexcept { return m_hAlign; }
        /// Which way its paragraphs run (E9c): left to right, right to left, or (Auto) as each one's
        /// first strong character says.
        void SetDirection(ParagraphDirection direction)
        {
            if (direction == m_direction)
                return;
            m_direction = direction;
            Dirty();
        }
        [[nodiscard]] ParagraphDirection GetDirection() const noexcept { return m_direction; }
        [[nodiscard]] TextVAlign GetVAlign() const noexcept { return m_vAlign; }

        /// CSS's white-space: whether spaces collapse and lines wrap. A Text starts as NoWrap (one line,
        /// spaces collapsed), a widget's usual text; a sheet's `white-space: normal` wraps it.
        void SetWhiteSpace(TextWhiteSpace whiteSpace)
        {
            if (whiteSpace == m_whiteSpace)
                return;
            m_whiteSpace = whiteSpace;
            Dirty();
        }
        [[nodiscard]] TextWhiteSpace GetWhiteSpace() const noexcept { return m_whiteSpace; }
        [[nodiscard]] bool IsWrapping() const noexcept { return Wraps(m_whiteSpace); }
        /// Each line's height in pixels (0: the font's own).
        void SetLineHeight(f32 pixels)
        {
            if (pixels == m_lineHeight)
                return;
            m_lineHeight = core::Max(0.0f, pixels);
            Dirty();
        }
        [[nodiscard]] f32 GetLineHeightSetting() const noexcept { return m_lineHeight; }
        void SetLetterSpacing(f32 pixels)
        {
            if (pixels == m_letterSpacing)
                return;
            m_letterSpacing = pixels;
            Dirty();
        }
        [[nodiscard]] f32 GetLetterSpacing() const noexcept { return m_letterSpacing; }
        /// CSS's overflow-wrap: a word wider than its line breaks between its characters
        /// (break-word, anywhere) rather than running out of its box (normal).
        void SetBreakWords(bool breakWords)
        {
            if (breakWords == m_breakWords)
                return;
            m_breakWords = breakWords;
            Dirty();
        }
        [[nodiscard]] bool GetBreakWords() const noexcept { return m_breakWords; }
        void SetOverflow(TextOverflow overflow)
        {
            if (overflow == m_overflow)
                return;
            m_overflow = overflow;
            Dirty();
        }
        [[nodiscard]] TextOverflow GetOverflow() const noexcept { return m_overflow; }
        /// The most lines it shows (line-clamp); 0: all.
        void SetMaxLines(u32 lines)
        {
            if (lines == m_maxLines)
                return;
            m_maxLines = lines;
            Dirty();
        }
        [[nodiscard]] u32 GetMaxLines() const noexcept { return m_maxLines; }

        // === Measurement (0 with no font) ===
        /// Its width on one line, unbroken but where the text breaks.
        [[nodiscard]] f32 GetWidth() const { return HasFont() ? LayoutAt(0.0f).Width : 0.0f; }
        /// One line's height: the line height set, or the font's.
        [[nodiscard]] f32 GetLineHeight() const
        {
            if (!HasFont())
                return 0.0f;
            return m_lineHeight > 0.0f ? m_lineHeight : m_font->font->Metrics().lineHeight;
        }
        /// Its size unbounded (one line unless the text breaks it).
        [[nodiscard]] core::Float2 Measure() const
        {
            if (!HasFont())
                return core::Float2{0.0f, 0.0f};
            const TextLayout& layout = LayoutAt(0.0f);
            return core::Float2{layout.Width, layout.Height};
        }
        /// Its size laid out in `maxWidth` (wrapped where its white-space wraps: at no width, a line a
        /// word, its min-content; at kUnbounded, unbroken); an empty text measures zero.
        [[nodiscard]] core::Float2 MeasureWrapped(f32 maxWidth) const
        {
            if (!HasFont() || IsEmpty())
                return core::Float2{0.0f, 0.0f};
            const bool bounded = IsWrapping() && maxWidth < 1.0e8f;
            const TextLayout& layout = LayoutAt(bounded ? core::Max(maxWidth, 0.01f) : 0.0f);
            return core::Float2{layout.Width, layout.Height};
        }
        /// The layout it draws in `bounds` (laid out at their width).
        [[nodiscard]] const TextLayout& LayoutFor(const Rect& bounds) const { return LayoutAt(BoundedWidth(bounds.width)); }
        /// Where the layout's origin goes in `bounds` (its block aligned up and down).
        [[nodiscard]] core::Float2 Origin(const Rect& bounds) const
        {
            const TextLayout& layout = LayoutFor(bounds);
            f32 top = bounds.Top();
            if (m_vAlign == TextVAlign::Middle)
                top += (bounds.height - layout.Height) * 0.5f;
            else if (m_vAlign == TextVAlign::Bottom)
                top += bounds.height - layout.Height;
            return core::Float2{bounds.Left(), top};
        }
        /// Where Draw(ctx, bounds) puts the first line's baseline.
        [[nodiscard]] f32 FirstBaseline(const Rect& bounds) const
        {
            if (!HasFont())
                return bounds.Top() + bounds.height;
            const TextLayout& layout = LayoutFor(bounds);
            const f32 first = layout.Lines.IsEmpty() ? m_font->font->Metrics().ascent : layout.Lines[0].Baseline;
            return Origin(bounds).y + first;
        }
        /// The link id under `point` when drawn in `bounds` (empty: none).
        [[nodiscard]] core::StringView LinkAt(const Rect& bounds, core::Float2 point) const
        {
            if (!m_rich || !HasFont())
                return {};
            const core::Float2 origin = Origin(bounds);
            const i32 run = LayoutFor(bounds).LinkAt(core::Float2{point.x - origin.x, point.y - origin.y});
            return run >= 0 ? m_document.Runs[static_cast<usize>(run)].Link.AsView() : core::StringView{};
        }

        // === Drawing ===
        /// Draws at `position` (the top-left), unbounded.
        void Draw(DrawContext& ctx, core::Float2 position) const
        {
            if (!HasFont() || IsEmpty())
                return;
            DrawLayout(ctx, LayoutAt(0.0f), position);
        }
        /// Draws aligned within `bounds`.
        void Draw(DrawContext& ctx, const Rect& bounds) const
        {
            if (!HasFont() || IsEmpty())
                return;
            DrawLayout(ctx, LayoutFor(bounds), Origin(bounds));
        }
        /// Draws a layout at `origin` (a field draws its own, scrolled).
        void DrawLayout(DrawContext& ctx, const TextLayout& layout, core::Float2 origin) const
        {
            Sync();
            vg::VGContext& g = ctx.VG();
            bool anyEffects = false;
            for (const TextRun& run : m_document.Runs)
                anyEffects = anyEffects || run.EffectParts != 0;
            if (anyEffects)
            {
                // Every run's effects (its own over the node's) under every run's glyphs, so one
                // run's outline or shadow never covers its neighbour.
                const vg::TextEffects inherited = g.GetTextEffects();
                g.PushState();
                g.SetTextEffectsOnly(true);
                for (const LaidOutGlyphs& run : layout.GlyphRuns)
                {
                    const vg::TextEffects effects =
                        run.Run >= 0 ? m_document.Runs[static_cast<usize>(run.Run)].EffectsOver(inherited) : inherited;
                    if (!effects.Any())
                        continue;
                    g.SetTextEffects(effects);
                    DrawRun(ctx, run, origin);
                }
                g.PopState();
                g.PushState();
                g.ClearTextEffects();
            }
            for (const LaidOutGlyphs& run : layout.GlyphRuns)
                DrawRun(ctx, run, origin);
            if (anyEffects)
                g.PopState();
            for (const LaidOutBox& underline : layout.Underlines)
            {
                const Rectangle r = underline.Rect;
                g.FillRect(Rectangle{r.x + origin.x, r.y + origin.y, r.width, r.height}, underline.TextColor);
            }
            for (const LaidOutBox& icon : layout.Icons)
            {
                if (m_resources == nullptr)
                    break;
                const TextRun& run = m_document.Runs[static_cast<usize>(icon.Run)];
                const Rectangle r{icon.Rect.x + origin.x, icon.Rect.y + origin.y, icon.Rect.width, icon.Rect.height};
                if (IsSvgSource(run.Icon.AsView())) // drawn as paths, crisp at the line's size
                {
                    if (const foundation::vg::svg::SVGDocument* svg = m_resources->Svg(run.Icon.AsView()))
                        foundation::vg::svg::SVGRenderer::Render(g, *svg, r);
                }
                else if (const foundation::image::ImageData* image = m_resources->LoadImage(run.Icon.AsView()))
                    g.DrawImage(image, r);
            }
        }

    private:
        [[nodiscard]] static f32 BoundedWidth(f32 width) noexcept { return width > 0.0f && width < 1.0e8f ? width : 0.0f; }

        void Dirty() noexcept
        {
            m_synced = false;
            m_cache[0].Valid = m_cache[1].Valid = false;
        }

        // The runs from the string (parsed when rich), spaces collapsed where white-space says.
        void Sync() const
        {
            if (m_synced)
                return;
            m_synced = true;
            TextDocument document = m_rich ? ParseTextMarkup(m_string.AsView()) : TextDocument::Plain(m_string.AsView());
            // A plain text's underlined range (a mnemonic): its own run between the rest.
            if (!m_rich && m_underlineStart < m_underlineEnd && m_underlineEnd <= m_string.Size() && document.Runs.Size() == 1)
            {
                TextRun middle = document.Runs[0];
                TextRun after = document.Runs[0];
                const core::StringView all = m_string.AsView();
                document.Runs[0].Text = core::String(all.SubStr(0, m_underlineStart));
                middle.Text = core::String(all.SubStr(m_underlineStart, m_underlineEnd - m_underlineStart));
                middle.Underline = true;
                after.Text = core::String(all.SubStr(m_underlineEnd, all.Size() - m_underlineEnd));
                document.Runs.PushBack(core::Move(middle));
                document.Runs.PushBack(core::Move(after));
                for (usize r = document.Runs.Size(); r-- > 0;)
                    if (document.Runs[r].Text.Size() == 0)
                        document.Runs.RemoveAt(r);
            }
            if (CollapsesSpaces(m_whiteSpace))
            {
                // Spaces, tabs and line breaks become one space; none at the start or the end.
                bool lastSpace = true;
                for (TextRun& run : document.Runs)
                {
                    if (run.IsIcon())
                    {
                        lastSpace = false;
                        continue;
                    }
                    core::String collapsed;
                    for (usize i = 0; i < run.Text.Size(); ++i)
                    {
                        const char8_t c = run.Text[i];
                        const bool space = c == u8' ' || c == u8'\t' || c == u8'\n' || c == u8'\r';
                        if (space && lastSpace)
                            continue;
                        collapsed.PushBack(space ? u8' ' : c);
                        lastSpace = space;
                    }
                    run.Text = core::Move(collapsed);
                }
                for (usize r = document.Runs.Size(); r-- > 0;)
                {
                    TextRun& run = document.Runs[r];
                    if (run.IsIcon())
                        break;
                    while (run.Text.Size() != 0 && run.Text[run.Text.Size() - 1] == u8' ')
                        run.Text.Remove(run.Text.Size() - 1, 1);
                    if (run.Text.Size() != 0)
                        break;
                }
                for (usize r = document.Runs.Size(); r-- > 0;)
                    if (!document.Runs[r].IsIcon() && document.Runs[r].Text.Size() == 0)
                        document.Runs.RemoveAt(r);
            }
            m_document = core::Move(document);
            m_plain = m_document.PlainText();
        }

        [[nodiscard]] const TextLayout& LayoutAt(f32 maxWidth) const
        {
            Sync();
            for (LayoutCache& cache : m_cache)
                if (cache.Valid && cache.Width == maxWidth)
                    return cache.Layout;
            LayoutCache& slot = m_cache[m_nextSlot];
            m_nextSlot = (m_nextSlot + 1) % 2;
            TextLayoutStyle style;
            style.Font = m_font;
            style.Fonts = m_fontService;
            if (HasFont())
            {
                style.Family = m_family.Size() != 0 ? m_family : core::String(m_font->font->FamilyName());
                style.Size = m_font->font->PixelHeight();
            }
            style.Selection = m_selection;
            style.TextColor = m_color;
            style.Align = m_hAlign;
            style.Wrap = IsWrapping();
            style.MaxWidth = maxWidth;
            style.LineHeight = m_lineHeight;
            style.LetterSpacing = m_letterSpacing;
            style.BreakWords = m_breakWords;
            style.MaxLines = m_maxLines;
            style.Overflow = m_overflow;
            style.Direction = m_direction.Direction;
            style.AutoRightToLeft = m_direction.AutoRightToLeft;
            slot.Layout = LayOutText(m_document, style);
            slot.Width = maxWidth;
            slot.Valid = true;
            return slot.Layout;
        }

        // One run's glyphs, slanted when its italic is synthesized and twice when its bold is; a run
        // its font could not shape, as text.
        void DrawRun(DrawContext& ctx, const LaidOutGlyphs& run, core::Float2 origin) const
        {
            vg::VGContext& g = ctx.VG();
            if (run.Unshaped)
            {
                const core::StringView text = m_plain.AsView().SubStr(run.TextStart, run.TextEnd - run.TextStart);
                g.DrawText(text, run.Font, core::Float2{origin.x + run.X, origin.y + run.Baseline}, run.TextColor);
                return;
            }
            if (run.SyntheticItalic)
            {
                // Lean the glyphs about their baseline: x moves right by a fifth of the height above it.
                g.PushState();
                Float4x4 lean = Float4x4::Identity();
                const f32 baseline = origin.y + run.Baseline;
                lean.m[1][0] = -0.2f;
                lean.m[3][0] = 0.2f * baseline;
                g.SetTransform(lean * g.GetTransform());
            }
            g.DrawPositionedGlyphs(run.Glyphs, run.Font, origin.x, origin.y, run.TextColor);
            if (run.SyntheticBold && !g.TextEffectsOnly()) // effects once, under both strokes
                g.DrawPositionedGlyphs(run.Glyphs, run.Font, origin.x + core::Max(0.5f, run.Size / 24.0f), origin.y, run.TextColor);
            if (run.SyntheticItalic)
                g.PopState();
        }

        struct LayoutCache
        {
            TextLayout Layout;
            f32 Width = 0.0f;
            bool Valid = false;
        };

        core::String m_string;
        bool m_rich = false;
        fonts::CachedFont* m_font = nullptr; // non-owning (owned by the font service)
        fonts::IFontService* m_fontService = nullptr;
        FontSelection m_selection;
        core::String m_family; // as the sheet names it (empty: the font's own name)
        IResourceProvider* m_resources = nullptr;
        Color m_color = Color::White;
        TextHAlign m_hAlign = TextHAlign::Start;
        ParagraphDirection m_direction;
        usize m_underlineStart = 0; // a plain text's underlined bytes (a mnemonic)
        usize m_underlineEnd = 0;
        TextVAlign m_vAlign = TextVAlign::Top;
        TextWhiteSpace m_whiteSpace = TextWhiteSpace::NoWrap;
        f32 m_lineHeight = 0.0f;
        f32 m_letterSpacing = 0.0f;
        bool m_breakWords = false;
        u32 m_maxLines = 0;
        TextOverflow m_overflow = TextOverflow::Clip;

        mutable bool m_synced = false;
        mutable TextDocument m_document;
        mutable core::String m_plain;
        mutable LayoutCache m_cache[2];
        mutable usize m_nextSlot = 0;
    };
}
