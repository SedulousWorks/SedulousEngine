// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - bidirectional text (E9c of Specs/gui-lab-evolution.md): the formatter resolves each
// paragraph's levels through Foundation's resolver (SheenBidi installed here, as GUISandbox does),
// wraps in logical order, then lays each line out in visual order, each piece shaped the way it
// reads; start and end alignment follow the paragraph; a caret's x is a glyph's leading edge and a
// point's offset the nearest edge, both the right way round in right-to-left text, with an affinity
// where the directions meet; Left and Right step through a line's caret places in visual order; a
// range is a box per stretch of glyphs side by side. Over DejaVu Sans
// Mono, which draws Arabic.
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.vfs;
import foundation.fonts;
import foundation.fonts.truetype;
import foundation.fonts.bidi;
import foundation.gui;

using namespace foundation::core;
using namespace foundation::gui;
namespace fonts = foundation::fonts;

namespace
{
    struct DejaVu
    {
        fonts::TrueTypeFontService service{DefaultAllocator()};
        DejaVu()
        {
            fonts::TrueTypeFonts::Initialize();
            const String root = foundation::vfs::FindDataRoot();
            REQUIRE(service.LoadFont(u8"DejaVu", foundation::vfs::DataPath(root.AsView(), u8"Assets/fonts/dejavu/DejaVuSansMono.ttf").AsView()) ==
                    fonts::FontLoadResult::Success);
        }
    };
    // The resolver for one test, removed after it.
    struct Bidi
    {
        Bidi() { fonts::BidiAlgorithm::Install(); }
        ~Bidi() { fonts::BidiAlgorithm::Uninstall(); }
    };

    TextLayoutStyle Style(DejaVu& font, fonts::TextDirection direction, f32 maxWidth = 0.0f)
    {
        TextLayoutStyle style;
        style.Font = font.service.GetFont(u8"DejaVu", 16.0f);
        style.Family = String(u8"DejaVu");
        style.Size = 16.0f;
        style.MaxWidth = maxWidth;
        style.Direction = direction;
        return style;
    }
    // The left edge of the glyphs drawing bytes [start, end) of the plain text.
    f32 LeftOf(const TextLayout& layout, usize start, usize end)
    {
        f32 left = 1e9f;
        for (const LaidOutGlyphs& run : layout.GlyphRuns)
            for (usize g = 0; g < run.Glyphs.Size(); ++g)
                if (run.GlyphStart[g] >= start && run.GlyphEnd[g] <= end)
                    left = Min(left, run.Glyphs[g].x);
        return left;
    }
    // Salaam (four letters, eight bytes).
    constexpr const char8_t* kWord = u8"\u0633\u0644\u0627\u0645";
}

TEST_CASE("bidi text: a right-to-left paragraph runs from the right, its first word rightmost, each glyph read right to left")
{
    DejaVu font;
    Bidi bidi;
    String text(kWord);
    text.Append(StringView(u8" "));
    text.Append(StringView(kWord)); // bytes 0 to 8, a space, 9 to 17
    const TextLayout layout = LayOutText(ParseTextMarkup(text.AsView()), Style(font, fonts::TextDirection::RightToLeft));
    REQUIRE(layout.Lines.Size() == 1u);
    CHECK(layout.Lines[0].RightToLeft);
    CHECK(LeftOf(layout, 0, 8) > LeftOf(layout, 9, 17));
    for (const LaidOutGlyphs& run : layout.GlyphRuns)
        for (const fonts::GlyphPosition& g : run.Glyphs)
            CHECK(g.rightToLeft);
    CHECK(LeftOf(layout, 0, 2) > LeftOf(layout, 6, 8)); // its first letter on its right
}

TEST_CASE("bidi text: Latin inside a right-to-left paragraph reads left to right, to the Arabic's left")
{
    DejaVu font;
    Bidi bidi;
    String text(kWord);
    text.Append(StringView(u8" hello world")); // Arabic 0 to 8; hello 9 to 14; world 15 to 20
    const TextLayout layout = LayOutText(ParseTextMarkup(text.AsView()), Style(font, fonts::TextDirection::RightToLeft));
    CHECK(LeftOf(layout, 9, 14) < LeftOf(layout, 0, 8));
    CHECK(LeftOf(layout, 9, 14) < LeftOf(layout, 15, 20));
    CHECK(LeftOf(layout, 15, 20) < LeftOf(layout, 0, 8));
}

TEST_CASE("bidi text: an Arabic word inside a left-to-right paragraph keeps its place and reads right to left")
{
    DejaVu font;
    Bidi bidi;
    String text(u8"a ");
    text.Append(StringView(kWord));
    text.Append(StringView(u8" b")); // a 0; Arabic 2 to 10; b 11
    const TextLayout layout = LayOutText(ParseTextMarkup(text.AsView()), Style(font, fonts::TextDirection::LeftToRight));
    CHECK_FALSE(layout.Lines[0].RightToLeft);
    CHECK(LeftOf(layout, 0, 1) < LeftOf(layout, 2, 10));
    CHECK(LeftOf(layout, 2, 10) < LeftOf(layout, 11, 12));
    CHECK(LeftOf(layout, 2, 4) > LeftOf(layout, 8, 10));
}

TEST_CASE("bidi text: start and end follow the paragraph; a wrapped right-to-left paragraph starts each line on the right")
{
    DejaVu font;
    Bidi bidi;
    // A word and its space, as the layout shapes them (Salaam's lam and alef join in one glyph).
    String two(kWord);
    two.Append(StringView(u8" "));
    two.Append(StringView(kWord));
    const f32 word = LayOutText(ParseTextMarkup(two.AsView()), Style(font, fonts::TextDirection::LeftToRight)).Lines[0].Width -
                     LayOutText(ParseTextMarkup(StringView(kWord)), Style(font, fonts::TextDirection::LeftToRight)).Lines[0].Width;
    String text;
    for (int i = 0; i < 3; ++i)
    {
        text.Append(StringView(kWord));
        if (i < 2)
            text.Append(StringView(u8" "));
    }
    TextLayoutStyle style = Style(font, fonts::TextDirection::RightToLeft, word * 2.5f);
    style.Align = TextHAlign::Start;
    const TextLayout layout = LayOutText(ParseTextMarkup(text.AsView()), style);
    REQUIRE(layout.Lines.Size() == 2u);
    for (const LaidOutLine& line : layout.Lines)
        CHECK(line.Left + line.Width == doctest::Approx(word * 2.5f));
    CHECK(LeftOf(layout, 0, 8) > LeftOf(layout, 9, 17)); // the first line's first word on its right
    style.Align = TextHAlign::End;
    CHECK(LayOutText(ParseTextMarkup(text.AsView()), style).Lines[0].Left == doctest::Approx(0.0f));
    TextLayoutStyle ltr = Style(font, fonts::TextDirection::LeftToRight, 300.0f);
    ltr.Align = TextHAlign::Start;
    CHECK(LayOutText(ParseTextMarkup(StringView(u8"hello")), ltr).Lines[0].Left == doctest::Approx(0.0f));
}

TEST_CASE("bidi text: a caret stands at a glyph's leading edge, and a point finds the nearest edge, the right way round")
{
    DejaVu font;
    Bidi bidi;
    const TextLayout layout = LayOutText(ParseTextMarkup(StringView(kWord)), Style(font, fonts::TextDirection::RightToLeft));
    const LaidOutLine& line = layout.Lines[0];
    const f32 right = line.Left + line.Width;
    CHECK(layout.CaretX(0) == doctest::Approx(right)); // before its first letter: the right edge
    CHECK(layout.CaretX(8) == doctest::Approx(line.Left)); // after its last: the left edge
    CHECK(layout.CaretX(2) < right);
    CHECK(layout.CaretX(2) > layout.CaretX(4));
    const f32 y = line.Top + line.Height * 0.5f;
    CHECK(layout.OffsetAt(Float2{right - 0.5f, y}) == 0u);
    CHECK(layout.OffsetAt(Float2{line.Left + 0.5f, y}) == 8u);
}

TEST_CASE("bidi text: with no resolver a right-to-left paragraph keeps its order and starts on the right")
{
    DejaVu font;
    TextLayoutStyle style = Style(font, fonts::TextDirection::RightToLeft, 300.0f);
    style.Align = TextHAlign::Start;
    const TextLayout layout = LayOutText(ParseTextMarkup(StringView(u8"ab cd")), style);
    CHECK(layout.Lines[0].RightToLeft);
    CHECK(LeftOf(layout, 0, 2) < LeftOf(layout, 3, 5));
    CHECK(layout.Lines[0].Left + layout.Lines[0].Width == doctest::Approx(300.0f));
}

TEST_CASE("bidi text: left-to-right text lays out the same with the resolver installed")
{
    DejaVu font;
    const TextLayout before = LayOutText(ParseTextMarkup(StringView(u8"hello [b]bold[/b] world")), Style(font, fonts::TextDirection::LeftToRight, 80.0f));
    Bidi bidi;
    const TextLayout after = LayOutText(ParseTextMarkup(StringView(u8"hello [b]bold[/b] world")), Style(font, fonts::TextDirection::LeftToRight, 80.0f));
    REQUIRE(before.GlyphRuns.Size() == after.GlyphRuns.Size());
    for (usize r = 0; r < before.GlyphRuns.Size(); ++r)
    {
        REQUIRE(before.GlyphRuns[r].Glyphs.Size() == after.GlyphRuns[r].Glyphs.Size());
        for (usize g = 0; g < before.GlyphRuns[r].Glyphs.Size(); ++g)
            CHECK(before.GlyphRuns[r].Glyphs[g].x == after.GlyphRuns[r].Glyphs[g].x);
    }
}

TEST_CASE("bidi text: Right steps through every caret place of a mixed line once, left to right")
{
    DejaVu font;
    Bidi bidi;
    String text(u8"ab ");
    text.Append(StringView(kWord)); // a 0, b 1, a space 2, Arabic 3 to 11
    const TextLayout layout = LayOutText(ParseTextMarkup(text.AsView()), Style(font, fonts::TextDirection::LeftToRight));
    usize offset = 0;
    bool upstream = false;
    f32 x = layout.CaretX(offset, upstream);
    int steps = 0;
    usize next = 0;
    bool nextUpstream = false;
    while (layout.OffsetVisually(offset, upstream, 1, next, nextUpstream))
    {
        const f32 nx = layout.CaretX(next, nextUpstream);
        CHECK(nx > x);
        x = nx;
        offset = next;
        upstream = nextUpstream;
        REQUIRE(++steps < 20);
    }
    CHECK(steps == 7); // three Latin edges and the space's, three inside the Arabic, its right end
    CHECK(x == doctest::Approx(layout.Lines[0].Width));
    CHECK(offset == 3u); // the right end is the Arabic's start
    // And back again, the same places.
    int back = 0;
    while (layout.OffsetVisually(offset, upstream, -1, next, nextUpstream))
    {
        offset = next;
        upstream = nextUpstream;
        REQUIRE(++back < 20);
    }
    CHECK(back == 7);
    CHECK(offset == 0u);
}

TEST_CASE("bidi text: a point's caret draws where it was found; a range across directions is in pieces")
{
    DejaVu font;
    Bidi bidi;
    String text(u8"ab ");
    text.Append(StringView(kWord));
    const TextLayout layout = LayOutText(ParseTextMarkup(text.AsView()), Style(font, fonts::TextDirection::LeftToRight));
    const LaidOutLine& line = layout.Lines[0];
    for (const LaidOutGlyphs& run : layout.GlyphRuns)
        for (const fonts::GlyphPosition& g : run.Glyphs)
        {
            const f32 edges[] = {g.x, g.x + g.advance};
            for (const f32 edge : edges)
            {
                bool upstream = false;
                const usize at = layout.OffsetAt(Float2{edge, line.Top + 1.0f}, &upstream);
                CHECK(layout.CaretX(at, upstream) == doctest::Approx(edge));
            }
        }
    Array<Float2> boxes;
    layout.RangeOnLine(0, 5, 0, boxes); // "ab ", then the first Arabic letter, at the far right
    REQUIRE(boxes.Size() == 2u);
    CHECK(boxes[0].x == doctest::Approx(0.0f));
    CHECK(boxes[1].y == doctest::Approx(line.Width));
    layout.RangeOnLine(0, 11, 0, boxes);
    CHECK(boxes.Size() == 1u); // all of it: one box
}

namespace
{
    // Caret places that run against the bytes, as a right-to-left line's do.
    struct Reversed : ITextCaretPlaces
    {
        usize Size = 0;
        bool OffsetVisually(usize offset, bool, i32 step, usize& out, bool& upstream) const override
        {
            upstream = false;
            if (step > 0 ? offset == 0 : offset >= Size)
                return false;
            out = step > 0 ? offset - 1 : offset + 1;
            return true;
        }
        bool IsRightToLeftAt(usize) const override { return RightToLeft; }
        bool RightToLeft = true;
    };
}

TEST_CASE("bidi text: the model moves Left and Right across the view's caret places, and stays at their ends")
{
    TextEditModel model;
    model.SetText(StringView(u8"abcd"));
    Reversed places;
    places.Size = 4;
    model.SetCaretPlaces(&places);
    model.SetCaret(1);
    CHECK(model.Run(TextEditCommand::MoveLeft));
    CHECK(model.GetCaret() == 2u); // left goes on through the text
    CHECK(model.Run(TextEditCommand::SelectRight));
    CHECK(model.GetCaret() == 1u);
    CHECK(model.GetAnchor() == 2u);
    model.SetCaret(0);
    CHECK(model.Run(TextEditCommand::MoveRight));
    CHECK(model.GetCaret() == 0u); // nowhere further that way
    model.SetCaretPlaces(nullptr);
    CHECK(model.Run(TextEditCommand::MoveRight));
    CHECK(model.GetCaret() == 1u); // without, as the bytes go
}

TEST_CASE("bidi text: a clamped right-to-left paragraph ends its last line's ellipsis on the left")
{
    DejaVu font;
    Bidi bidi;
    String text;
    for (int i = 0; i < 6; ++i)
    {
        text.Append(StringView(kWord));
        text.Append(StringView(u8" "));
    }
    TextLayoutStyle style = Style(font, fonts::TextDirection::RightToLeft, 120.0f);
    style.MaxLines = 1;
    style.Overflow = TextOverflow::Ellipsis;
    const TextLayout layout = LayOutText(ParseTextMarkup(text.AsView()), style);
    REQUIRE(layout.Clamped);
    const LaidOutGlyphs* ellipsis = nullptr;
    f32 textLeft = 1e9f;
    for (const LaidOutGlyphs& run : layout.GlyphRuns)
    {
        if (run.Run < 0)
            ellipsis = &run;
        else
            for (const fonts::GlyphPosition& g : run.Glyphs)
                textLeft = Min(textLeft, g.x);
    }
    REQUIRE(ellipsis != nullptr);
    CHECK(ellipsis->X < textLeft); // the end of a right-to-left line is its left
}

TEST_CASE("bidi text: in a right-to-left paragraph a word to the left is the next one, and Left collapses a selection to its end")
{
    TextEditModel model;
    model.SetText(StringView(u8"one two three"));
    Reversed places;
    places.Size = 13;
    model.SetCaretPlaces(&places);
    model.SetCaret(4); // before "two"
    CHECK(model.Run(TextEditCommand::MoveWordLeft));
    CHECK(model.GetCaret() > 4u); // on through the text: past "two"
    const usize past = model.GetCaret();
    CHECK(model.Run(TextEditCommand::MoveWordRight));
    CHECK(model.GetCaret() < past); // back
    model.SetCaret(4);
    CHECK(model.Run(TextEditCommand::SelectWordLeft));
    CHECK(model.GetAnchor() == 4u);
    CHECK(model.Run(TextEditCommand::MoveLeft));
    CHECK(model.GetCaret() == model.GetAnchor());
    CHECK(model.GetCaret() > 4u); // the selection's left end is its logical end
    // Deletes keep to the text's order: backward is backward.
    model.SetCaret(7); // after "two"
    CHECK(model.Run(TextEditCommand::DeleteWordBackward));
    CHECK(model.GetText() == StringView(u8"one  three"));
    // Left to right, as before.
    places.RightToLeft = false;
    model.SetText(StringView(u8"one two"));
    model.SetCaret(4);
    CHECK(model.Run(TextEditCommand::MoveWordLeft));
    CHECK(model.GetCaret() == 0u);
}
