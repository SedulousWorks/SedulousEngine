// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The inline formatter over the bundled Roboto faces: mixed sizes share a baseline, a paragraph of
// three colours wraps inside its width, an icon sits on the baseline, breaks and alignment, and bold
// and italic take a face or synthesize one. Copied with the layout from foundation.ui (E4 of
// Specs/gui-lab-evolution.md).
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.vfs;
import foundation.fonts;
import foundation.fonts.truetype;
import foundation.vg;
import foundation.gui;

using namespace foundation::core;
using namespace foundation::gui;
namespace fonts = foundation::fonts;

namespace
{
    // Roboto, and Roboto Bold as its own family (as a project loads a bold face).
    struct RobotoService
    {
        fonts::TrueTypeFontService service{DefaultAllocator()};

        RobotoService()
        {
            fonts::TrueTypeFonts::Initialize();
            const String root = foundation::vfs::FindDataRoot();
            REQUIRE(service.LoadFont(u8"Roboto",
                                     foundation::vfs::DataPath(root.AsView(), u8"Assets/fonts/roboto/Roboto-Regular.ttf")
                                         .AsView()) == fonts::FontLoadResult::Success);
            REQUIRE(service.LoadFont(u8"Roboto Bold",
                                     foundation::vfs::DataPath(root.AsView(), u8"Assets/fonts/roboto/Roboto-Bold.ttf")
                                         .AsView()) == fonts::FontLoadResult::Success);
        }
    };

    // The label's font (Roboto 16), the service for runs that set their own.
    TextLayoutStyle Style(RobotoService& fonts, f32 maxWidth = 0.0f)
    {
        TextLayoutStyle style;
        style.Font = fonts.service.GetFont(u8"Roboto", 16.0f);
        style.Fonts = &fonts.service;
        style.Family = String(u8"Roboto");
        style.Size = 16.0f;
        style.MaxWidth = maxWidth;
        return style;
    }
}

TEST_CASE("text layout: runs of two sizes share one baseline, the line as tall as the larger")
{
    RobotoService fonts;
    const TextDocument doc = ParseTextMarkup(u8"small [size=32]BIG[/size] small");
    const TextLayout layout = LayOutText(doc, Style(fonts));
    REQUIRE(layout.Lines.Size() == 1u);
    REQUIRE(layout.GlyphRuns.Size() >= 3u);
    const f32 baseline = layout.Lines[0].Baseline;
    for (const LaidOutGlyphs& run : layout.GlyphRuns)
    {
        CHECK(run.Baseline == doctest::Approx(baseline));
        for (const fonts::GlyphPosition& g : run.Glyphs)
            CHECK(g.y == doctest::Approx(baseline));
    }
    fonts::CachedFont* big = fonts.service.GetFont(u8"Roboto", 32.0f);
    fonts::CachedFont* small = fonts.service.GetFont(u8"Roboto", 16.0f);
    REQUIRE(big != nullptr);
    REQUIRE(small != nullptr);
    CHECK(baseline == doctest::Approx(big->font->Metrics().ascent));
    CHECK(layout.Height > small->font->Metrics().lineHeight * 1.5f);
    // Runs follow on: each starts where the one before it ended.
    for (usize r = 1; r < layout.GlyphRuns.Size(); ++r)
        CHECK(layout.GlyphRuns[r].Glyphs[0].x > layout.GlyphRuns[r - 1].Glyphs[0].x);
}

TEST_CASE("text layout: a paragraph of three colours wraps inside its width and keeps its colours")
{
    RobotoService fonts;
    const TextDocument doc = ParseTextMarkup(
        u8"The [color=#ff0000]guests in red[/color] dance while [color=#00ff00]the ones in green[/color] "
        u8"watch and [color=#0000ff]the band in blue[/color] plays on into the night");
    const TextLayout layout = LayOutText(doc, Style(fonts, 160.0f));
    CHECK(layout.Lines.Size() >= 3u);
    f32 total = 0.0f;
    for (const LaidOutLine& line : layout.Lines)
    {
        CHECK(line.Width <= 160.0f + 0.01f);
        CHECK(line.Top == doctest::Approx(total));
        total += line.Height;
    }
    CHECK(layout.Height == doctest::Approx(total));
    bool red = false, green = false, blue = false;
    for (const LaidOutGlyphs& run : layout.GlyphRuns)
    {
        red = red || run.TextColor.r == 1.0f;
        green = green || run.TextColor.g == 1.0f;
        blue = blue || run.TextColor.b == 1.0f;
        for (const fonts::GlyphPosition& g : run.Glyphs)
            CHECK(g.x + g.advance <= 160.0f + 4.0f); // within the width (a space may hang over)
    }
    CHECK((red && green && blue));
}

TEST_CASE("text layout: an icon sits on the baseline as tall as its text is big")
{
    RobotoService fonts;
    const TextDocument doc = ParseTextMarkup(u8"a [size=20][icon=Icons/rose.png][/size] b");
    const TextLayout layout = LayOutText(doc, Style(fonts));
    REQUIRE(layout.Icons.Size() == 1u);
    const Rectangle icon = layout.Icons[0].Rect;
    CHECK(icon.width == doctest::Approx(20.0f));
    CHECK(icon.y + icon.height == doctest::Approx(layout.Lines[0].Baseline));
    CHECK(layout.Icons[0].Run == 1);
    // The text after it starts after it.
    CHECK(layout.GlyphRuns.Back().Glyphs[0].x >= icon.x + icon.width);
}

TEST_CASE("text layout: line breaks, an empty last line, and centring")
{
    RobotoService fonts;
    CHECK(LayOutText(ParseTextMarkup(u8"a\nb"), Style(fonts)).Lines.Size() == 2u);
    const TextLayout trailing = LayOutText(ParseTextMarkup(u8"a\n"), Style(fonts));
    REQUIRE(trailing.Lines.Size() == 2u);
    CHECK(trailing.Lines[1].Height > 0.0f);

    TextLayoutStyle centred = Style(fonts, 200.0f);
    centred.Align = TextHAlign::Center;
    const TextLayout layout = LayOutText(ParseTextMarkup(u8"middle"), centred);
    REQUIRE(layout.Lines.Size() == 1u);
    CHECK(layout.Lines[0].Left == doctest::Approx((200.0f - layout.Lines[0].Width) * 0.5f));
    CHECK(layout.GlyphRuns[0].Glyphs[0].x == doctest::Approx(layout.Lines[0].Left));
}

TEST_CASE("text layout: bold takes the bold face, italic without one is synthesized")
{
    RobotoService fonts;
    TextRun bold;
    bold.Bold = true;
    const ResolvedRunFont b = ResolveRunFont(bold, Style(fonts));
    REQUIRE(b.Font != nullptr);
    CHECK_FALSE(b.SyntheticBold);
    CHECK(b.Font != fonts.service.GetFont(u8"Roboto", 16.0f));
    TextRun italic;
    italic.Italic = true;
    const ResolvedRunFont i = ResolveRunFont(italic, Style(fonts));
    CHECK(i.SyntheticItalic);
    CHECK_FALSE(i.SyntheticBold);
    TextRun both;
    both.Bold = true;
    both.Italic = true;
    const ResolvedRunFont bi = ResolveRunFont(both, Style(fonts));
    CHECK_FALSE(bi.SyntheticBold); // the bold face, slanted
    CHECK(bi.SyntheticItalic);
}

TEST_CASE("text layout: underlines and links cover their runs")
{
    RobotoService fonts;
    const TextLayout layout =
        LayOutText(ParseTextMarkup(u8"see [u][link=hint]the hint[/link][/u] here"), Style(fonts));
    REQUIRE(layout.Links.Size() == 2u); // "the " and "hint"
    REQUIRE(layout.Underlines.Size() == 2u);
    const Rectangle first = layout.Links[0].Rect;
    CHECK(layout.LinkAt(Float2{first.x + 1.0f, first.y + first.height * 0.5f}) == 1);
    CHECK(layout.LinkAt(Float2{0.5f, first.y + first.height * 0.5f}) == -1); // "see"
    CHECK(layout.Underlines[0].Rect.y > layout.Lines[0].Baseline); // below the baseline
    // The underline runs on under the space between the words, and stops at the last letter.
    CHECK(layout.Underlines[0].Rect.x + layout.Underlines[0].Rect.width ==
          doctest::Approx(layout.Underlines[1].Rect.x));
}

TEST_CASE("text layout: plain runs draw in the label's font; with no service a bold run is synthesized in it")
{
    RobotoService fonts;
    TextLayoutStyle style = Style(fonts);
    const TextLayout plain = LayOutText(TextDocument::Plain(u8"plain"), style);
    REQUIRE(plain.GlyphRuns.Size() == 1u);
    CHECK(plain.GlyphRuns[0].Font == style.Font);
    style.Fonts = nullptr;
    TextRun bold;
    bold.Bold = true;
    const ResolvedRunFont b = ResolveRunFont(bold, style);
    CHECK(b.Font == style.Font);
    CHECK(b.SyntheticBold);
    // A size of its own needs the service: without one the run keeps the label's.
    TextRun big;
    big.Size = 32.0f;
    CHECK(ResolveRunFont(big, style).Font == style.Font);
    CHECK(ResolveRunFont(big, style).Size == doctest::Approx(16.0f));
}

// ============================================================================================
// The GUI's additions: ellipses, the clamp, line height and spacing on shaped text, carets.
// ============================================================================================

namespace
{
    // The plain text the glyphs on a line stand for, an ellipsis as "~".
    String Shown(const TextLayout& layout, StringView plain, usize line)
    {
        String out;
        for (const LaidOutGlyphs& run : layout.GlyphRuns)
        {
            if (run.Line != line)
                continue;
            if (run.Run < 0)
            {
                out.Append(StringView(u8"~"));
                continue;
            }
            for (usize g = 0; g < run.Glyphs.Size(); ++g)
                out.Append(plain.SubStr(run.GlyphStart[g], run.GlyphEnd[g] - run.GlyphStart[g]));
        }
        return out;
    }
    // Runs in x order (an ellipsis may be added after the runs it sits between).
    String ShownInOrder(TextLayout layout, StringView plain, usize line)
    {
        for (usize i = 0; i < layout.GlyphRuns.Size(); ++i)
            for (usize j = i + 1; j < layout.GlyphRuns.Size(); ++j)
                if (layout.GlyphRuns[j].X < layout.GlyphRuns[i].X)
                {
                    LaidOutGlyphs swap = Move(layout.GlyphRuns[i]);
                    layout.GlyphRuns[i] = Move(layout.GlyphRuns[j]);
                    layout.GlyphRuns[j] = Move(swap);
                }
        return Shown(layout, plain, line);
    }
}

TEST_CASE("text layout: an overflowing line ends in an ellipsis at its end, start or middle, inside the width")
{
    RobotoService fonts;
    const StringView path(u8"/home/player/saves/slot-three/profile.dat");
    const TextDocument doc = TextDocument::Plain(path);
    TextLayoutStyle style = Style(fonts, 150.0f);
    style.Wrap = false;
    const TextLayout full = LayOutText(doc, style);
    CHECK(full.Width > 150.0f); // clipped: as wide as the text
    CHECK_FALSE(full.Lines[0].Ellipsized);

    style.Overflow = TextOverflow::Ellipsis;
    const TextLayout end = LayOutText(doc, style);
    CHECK(end.Lines[0].Ellipsized);
    CHECK(end.Width <= 150.0f + 0.01f);
    const String endShown = ShownInOrder(end, path, 0);
    CHECK(endShown.AsView().SubStr(0, 6) == StringView(u8"/home/"));
    CHECK(endShown.AsView().SubStr(endShown.Size() - 1, 1) == StringView(u8"~"));

    style.Overflow = TextOverflow::EllipsisStart;
    const TextLayout start = LayOutText(doc, style);
    CHECK(start.Width <= 150.0f + 0.01f);
    const String startShown = ShownInOrder(start, path, 0);
    CHECK(startShown.AsView().SubStr(0, 1) == StringView(u8"~"));
    CHECK(startShown.AsView().SubStr(startShown.Size() - 4, 4) == StringView(u8".dat"));
    for (const LaidOutGlyphs& run : start.GlyphRuns)
        for (const fonts::GlyphPosition& g : run.Glyphs)
            CHECK(g.x >= -0.01f);

    style.Overflow = TextOverflow::EllipsisMiddle;
    const TextLayout middle = LayOutText(doc, style);
    CHECK(middle.Width <= 150.0f + 0.01f);
    const String middleShown = ShownInOrder(middle, path, 0);
    CHECK(middleShown.AsView().SubStr(0, 6) == StringView(u8"/home/"));
    CHECK(middleShown.AsView().SubStr(middleShown.Size() - 4, 4) == StringView(u8".dat"));
    bool ellipsisInside = false;
    for (usize i = 1; i + 1 < middleShown.Size(); ++i)
        ellipsisInside = ellipsisInside || middleShown[i] == u8'~';
    CHECK(ellipsisInside);

    // Centred, the shortened line centres.
    style.Overflow = TextOverflow::Ellipsis;
    style.Align = TextHAlign::Center;
    const TextLayout centred = LayOutText(doc, style);
    CHECK(centred.Lines[0].Left == doctest::Approx((150.0f - centred.Lines[0].Width) * 0.5f));
}

TEST_CASE("text layout: a clamp keeps its lines and ends the last in an ellipsis")
{
    RobotoService fonts;
    TextLayoutStyle style = Style(fonts, 120.0f);
    style.MaxLines = 2;
    style.Overflow = TextOverflow::Ellipsis;
    const TextLayout layout = LayOutText(
        TextDocument::Plain(u8"The guests dance while the band plays on into the night and the masks turn"), style);
    REQUIRE(layout.Lines.Size() == 2u);
    CHECK(layout.Clamped);
    CHECK(layout.Lines[1].Ellipsized);
    CHECK_FALSE(layout.Lines[0].Ellipsized);
    CHECK(layout.Height == doctest::Approx(layout.Lines[1].Top + layout.Lines[1].Height));
    for (const LaidOutGlyphs& run : layout.GlyphRuns)
        CHECK(run.Line < 2u);
}

TEST_CASE("text layout: line height spaces shaped lines; letter spacing widens each glyph's step")
{
    RobotoService fonts;
    TextLayoutStyle style = Style(fonts, 60.0f);
    style.LineHeight = 40.0f;
    const TextLayout tall = LayOutText(TextDocument::Plain(u8"one two three"), style);
    REQUIRE(tall.Lines.Size() >= 2u);
    CHECK(tall.Lines[1].Top == doctest::Approx(40.0f));
    CHECK(tall.Lines[1].Baseline - tall.Lines[0].Baseline == doctest::Approx(40.0f));

    TextLayoutStyle plain = Style(fonts);
    const TextLayout narrow = LayOutText(TextDocument::Plain(u8"abc"), plain);
    plain.LetterSpacing = 3.0f;
    const TextLayout wide = LayOutText(TextDocument::Plain(u8"abc"), plain);
    CHECK(wide.Width == doctest::Approx(narrow.Width + 9.0f));
    REQUIRE(wide.GlyphRuns[0].Glyphs.Size() == 3u);
    CHECK(wide.GlyphRuns[0].Glyphs[2].x - narrow.GlyphRuns[0].Glyphs[2].x == doctest::Approx(6.0f));
}

TEST_CASE("text layout: a caret's x follows its offset, and a point finds the nearest offset on its line")
{
    RobotoService fonts;
    const StringView text(u8"ab cd\nefg");
    const TextLayout layout = LayOutText(TextDocument::Plain(text), Style(fonts));
    REQUIRE(layout.Lines.Size() == 2u);
    CHECK(layout.Lines[0].Start == 0u);
    CHECK(layout.Lines[0].End == 5u);
    CHECK(layout.Lines[1].Start == 6u);
    CHECK(layout.Lines[1].End == 9u);
    CHECK(layout.LineOf(5) == 0u);
    CHECK(layout.LineOf(6) == 1u);
    f32 last = -1.0f;
    for (usize offset = 0; offset <= 5; ++offset)
    {
        const f32 x = layout.CaretX(offset);
        CHECK(x > last);
        last = x;
        CHECK(layout.OffsetAt(Float2{x + 0.5f, layout.Lines[0].Baseline}) == offset);
    }
    CHECK(layout.CaretX(6) == doctest::Approx(0.0f));
    CHECK(layout.OffsetAt(Float2{1000.0f, layout.Lines[1].Baseline}) == 9u);
    CHECK(layout.OffsetAt(Float2{-5.0f, -5.0f}) == 0u);
}

TEST_CASE("text layout: a wrapped line's caret end stays on it")
{
    RobotoService fonts;
    const TextLayout layout = LayOutText(TextDocument::Plain(u8"alpha beta"), Style(fonts, 50.0f));
    REQUIRE(layout.Lines.Size() == 2u);
    CHECK(layout.Lines[0].End == layout.Lines[1].Start);
    const usize end = layout.OffsetAt(Float2{49.0f, layout.Lines[0].Baseline});
    CHECK(layout.LineOf(end) == 0u);
}

TEST_CASE("label: measures shaped text, and a rich label reports a clicked link")
{
    RobotoService fonts;
    auto context = MakeRef<GUIContext>(DefaultAllocator());
    context->SetFontService(&fonts.service);
    auto root = MakeRef<SceneRoot>(DefaultAllocator(), context);
    root->SetSize(Float2{400.0f, 200.0f});
    fonts::CachedFont* roboto = fonts.service.GetFont(u8"Roboto", 16.0f);

    auto label = MakeRef<Label>(DefaultAllocator());
    label->SetFont(roboto);
    label->SetText(u8"Shaped width");
    CHECK(label->MeasureContent(Float2{kUnbounded, kUnbounded}).x ==
          doctest::Approx(LayOutText(TextDocument::Plain(u8"Shaped width"), Style(fonts)).Width));

    auto rich = MakeRef<RichText>(DefaultAllocator());
    rich->SetFont(roboto);
    rich->SetText(u8"go [link=door]open the door[/link] now");
    rich->SetPosition(Float2{0.0f, 0.0f});
    rich->SetSize(Float2{400.0f, 40.0f});
    root->AddChild(rich.Get());
    String heard;
    (void)rich->AddEventListener(EventType::Link,
                                 [&heard](const Event& e) { heard = String(static_cast<const LinkEvent&>(e).Link); });
    const Rect bounds = rich->GetContentBounds();
    const TextLayout& layout = rich->GetTextLayout().LayoutFor(bounds);
    REQUIRE_FALSE(layout.Links.IsEmpty());
    const Float2 origin = rich->GetTextLayout().Origin(bounds);
    const Float2 onLink{origin.x + layout.Links[0].Rect.x + 2.0f, origin.y + layout.Links[0].Rect.y + layout.Links[0].Rect.height * 0.5f};
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseDown(onLink, MouseButton::Left);
    d->InjectMouseUp(onLink, MouseButton::Left);
    CHECK(heard == StringView(u8"door"));
    heard.Clear();
    d->InjectMouseDown(Float2{origin.x + 1.0f, onLink.y}, MouseButton::Left); // on "go"
    d->InjectMouseUp(Float2{origin.x + 1.0f, onLink.y}, MouseButton::Left);
    CHECK(heard.IsEmpty());
}

TEST_CASE("text layout: the pointer shows the hand over a rich text's link, and only there")
{
    RobotoService fonts;
    auto context = MakeRef<GUIContext>(DefaultAllocator());
    context->SetFontService(&fonts.service);
    auto root = MakeRef<SceneRoot>(DefaultAllocator(), context);
    root->SetSize(Float2{400.0f, 200.0f});
    auto rich = MakeRef<RichText>(DefaultAllocator());
    rich->SetFont(fonts.service.GetFont(u8"Roboto", 16.0f));
    rich->SetText(u8"go [link=door]open the door[/link] now");
    rich->SetSize(Float2{400.0f, 40.0f});
    root->AddChild(rich.Get());
    const Rect bounds = rich->GetContentBounds();
    const TextLayout& layout = rich->GetTextLayout().LayoutFor(bounds);
    REQUIRE_FALSE(layout.Links.IsEmpty());
    const Float2 origin = rich->GetTextLayout().Origin(bounds);
    const Float2 onLink{origin.x + layout.Links[0].Rect.x + 2.0f, origin.y + layout.Links[0].Rect.y + layout.Links[0].Rect.height * 0.5f};
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseMove(Float2{origin.x + 1.0f, onLink.y}); // on "go"
    CHECK(d->GetCursor() == Cursor::Default);
    d->InjectMouseMove(onLink);
    CHECK(d->GetCursor() == Cursor::Pointer);
    d->InjectMouseMove(Float2{390.0f, 190.0f}); // off the label
    CHECK(d->GetCursor() == Cursor::Default);
    rich->SetCursor(Cursor::Text); // its own look elsewhere; the hand still over the link
    d->InjectMouseMove(Float2{origin.x + 1.0f, onLink.y});
    CHECK(d->GetCursor() == Cursor::Text);
    d->InjectMouseMove(onLink);
    CHECK(d->GetCursor() == Cursor::Pointer);
}

TEST_CASE("text layout: an ellipsis the font's atlas lacks falls back to full stops")
{
    RobotoService fonts; // baked over printable ASCII: no U+2026
    fonts::CachedFont* roboto = fonts.service.GetFont(u8"Roboto", 16.0f);
    CHECK_FALSE(FontDraws(roboto, StringView(u8"…")));
    CHECK(FontDraws(roboto, StringView(u8"abc")));
    CHECK(EllipsisFor(roboto) == StringView(u8"..."));
    TextLayoutStyle style = Style(fonts, 60.0f);
    style.Wrap = false;
    style.Overflow = TextOverflow::Ellipsis;
    const TextLayout layout = LayOutText(TextDocument::Plain(u8"a long line of text"), style);
    usize ellipsisGlyphs = 0;
    for (const LaidOutGlyphs& run : layout.GlyphRuns)
        if (run.Run < 0)
            ellipsisGlyphs += run.Glyphs.Size();
    CHECK(ellipsisGlyphs == 3u);
    CHECK(layout.Width <= 60.0f + 0.01f);
}
