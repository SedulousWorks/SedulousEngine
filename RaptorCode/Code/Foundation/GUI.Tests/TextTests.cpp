// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Text tests: measurement, alignment, white-space, line height, spacing and clamping against a
// mock IFont (6px advance/byte, 12px line height, no shaper: its pieces lay out unshaped). The full
// glyph-render path (atlas + texture) is an integration concern; here we assert Text's own logic and
// the draw guards.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace vg = foundation::vg;

namespace
{
    // 6px advance per byte, 12px line height.
    class MockFont : public fonts::IFont
    {
    public:
        core::StringView FamilyName() const override { return core::StringView(u8"mock"); }
        core::Span<const core::u8> SourceData() const override { return {}; }
        fonts::FontMetrics Metrics() const override
        {
            fonts::FontMetrics m;
            m.ascent = 10.0f;
            m.descent = -2.0f;
            m.lineGap = 0.0f;
            m.lineHeight = 12.0f;
            m.pixelHeight = 10.0f;
            m.scale = 1.0f;
            return m;
        }
        core::f32 PixelHeight() const override { return 10.0f; }
        fonts::GlyphInfo GetGlyphInfo(core::i32 cp) const override
        {
            fonts::GlyphInfo g;
            g.codepoint = cp;
            g.advanceWidth = 6.0f;
            return g;
        }
        core::f32 GetKerning(core::i32, core::i32) const override { return 0.0f; }
        bool HasGlyph(core::i32) const override { return true; }
        core::f32 MeasureString(core::StringView text) const override
        {
            return static_cast<core::f32>(text.Size()) * 6.0f;
        }
        core::f32 MeasureString(core::StringView text,
                                core::Array<fonts::GlyphPosition>& out) const override
        {
            (void)out;
            return static_cast<core::f32>(text.Size()) * 6.0f;
        }
    };

    MockFont* NewMock() { return core::DefaultAllocator().New<MockFont>(); }
}

TEST_CASE("text: measurement uses font metrics")
{
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr); // owns + deletes the mock on scope exit
    Text t{core::StringView(u8"Hello"), &cf};
    CHECK(t.GetWidth() == doctest::Approx(30.0f)); // 5 * 6
    CHECK(t.GetLineHeight() == doctest::Approx(12.0f));
    CHECK(t.Measure().x == doctest::Approx(30.0f));
    CHECK(t.Measure().y == doctest::Approx(12.0f));
}

TEST_CASE("text: no font measures to zero")
{
    Text t;
    t.SetString(core::StringView(u8"Hello"));
    CHECK(t.GetWidth() == 0.0f);
    CHECK(t.GetLineHeight() == 0.0f);
}

TEST_CASE("text: string/color/alignment accessors")
{
    Text t;
    t.SetString(core::StringView(u8"abc"));
    CHECK(t.GetString() == core::StringView(u8"abc"));
    CHECK_FALSE(t.IsEmpty());
    t.SetColor(core::Color::Red);
    CHECK(t.GetColor().r == doctest::Approx(1.0f));
    t.SetAlignment(TextHAlign::Center, TextVAlign::Bottom);
    CHECK(t.GetHAlign() == TextHAlign::Center);
    CHECK(t.GetVAlign() == TextVAlign::Bottom);
}

namespace
{
    // The text of each laid-out line.
    core::Array<core::StringView> LinesOf(const Text& t, const TextLayout& layout)
    {
        core::Array<core::StringView> lines;
        for (const LaidOutLine& line : layout.Lines)
            lines.PushBack(t.PlainText().SubStr(line.Start, line.End - line.Start));
        return lines;
    }
}

TEST_CASE("text: alignment within bounds")
{
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr);
    Text t{core::StringView(u8"Hello"), &cf}; // width 30, height 12
    const Rect bounds{0.0f, 0.0f, 100.0f, 50.0f};

    t.SetAlignment(TextHAlign::Left, TextVAlign::Top);
    CHECK(t.LayoutFor(bounds).Lines[0].Left == doctest::Approx(0.0f));
    CHECK(t.Origin(bounds).y == doctest::Approx(0.0f));

    t.SetAlignment(TextHAlign::Center, TextVAlign::Middle);
    CHECK(t.LayoutFor(bounds).Lines[0].Left == doctest::Approx(35.0f)); // (100-30)/2
    CHECK(t.Origin(bounds).y == doctest::Approx(19.0f));                // (50-12)/2

    t.SetAlignment(TextHAlign::Right, TextVAlign::Bottom);
    CHECK(t.LayoutFor(bounds).Lines[0].Left == doctest::Approx(70.0f)); // 100-30
    CHECK(t.Origin(bounds).y == doctest::Approx(38.0f));                // 50-12
}

TEST_CASE("text: draw guards - no font or empty produces no geometry")
{
    vg::VGContext ctx; // no font service -> VG DrawText early-returns anyway
    DrawContext dc{ctx};

    Text noFont;
    noFont.SetString(core::StringView(u8"Hello"));
    noFont.Draw(dc, core::Float2{0.0f, 0.0f});
    CHECK(ctx.GetBatch().vertices.Size() == 0);

    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr);
    Text empty{core::StringView(u8""), &cf};
    empty.Draw(dc, core::Float2{0.0f, 0.0f});
    CHECK(ctx.GetBatch().vertices.Size() == 0);
}

TEST_CASE("text: white-space normal breaks at spaces to fit the width")
{
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr); // 6px/byte, 12px line height
    Text t{core::StringView(u8"hello world foo"), &cf};
    t.SetWhiteSpace(TextWhiteSpace::Normal);

    const core::Array<core::StringView> lines = LinesOf(t, t.LayoutFor(Rect{0.0f, 0.0f, 60.0f, 100.0f})); // 10 bytes
    REQUIRE(lines.Size() == 2);
    CHECK(lines[0] == core::StringView(u8"hello ")); // a wrapped line keeps the space it broke at
    CHECK(lines[1] == core::StringView(u8"world foo"));

    const core::Float2 wrapped = t.MeasureWrapped(60.0f);
    CHECK(wrapped.x == doctest::Approx(54.0f)); // widest line "world foo" = 9 * 6
    CHECK(wrapped.y == doctest::Approx(24.0f)); // 2 lines * 12
    // Unbounded, and at no width (each word its own line: its min-content).
    CHECK(t.MeasureWrapped(kUnbounded).x == doctest::Approx(90.0f));
    CHECK(t.MeasureWrapped(0.0f).x == doctest::Approx(30.0f));
    CHECK(t.MeasureWrapped(0.0f).y == doctest::Approx(36.0f));
}

TEST_CASE("text: pre keeps line breaks and spaces; normal and nowrap collapse them")
{
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr);
    Text t{core::StringView(u8"a\nbc  \nd"), &cf};
    t.SetWhiteSpace(TextWhiteSpace::Pre);
    const core::Array<core::StringView> lines = LinesOf(t, t.LayoutFor(Rect{0.0f, 0.0f, 1000.0f, 100.0f}));
    REQUIRE(lines.Size() == 3);
    CHECK(lines[0] == core::StringView(u8"a"));
    CHECK(lines[1] == core::StringView(u8"bc  "));
    CHECK(lines[2] == core::StringView(u8"d"));

    t.SetWhiteSpace(TextWhiteSpace::NoWrap);
    CHECK(t.PlainText() == core::StringView(u8"a bc d"));
    CHECK(t.LayoutFor(Rect{0.0f, 0.0f, 10.0f, 100.0f}).Lines.Size() == 1u); // no wrap
    Text padded{core::StringView(u8"  x \t y  "), &cf};
    CHECK(padded.PlainText() == core::StringView(u8"x y"));
}

TEST_CASE("text: a word longer than the width takes its own line (overflows)")
{
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr);
    Text t{core::StringView(u8"abcdefghij k"), &cf}; // first word 10 bytes = 60px
    t.SetWhiteSpace(TextWhiteSpace::Normal);

    const core::Array<core::StringView> lines = LinesOf(t, t.LayoutFor(Rect{0.0f, 0.0f, 30.0f, 100.0f}));
    REQUIRE(lines.Size() == 2);
    CHECK(lines[0] == core::StringView(u8"abcdefghij ")); // overflows its line
    CHECK(lines[1] == core::StringView(u8"k"));
}

TEST_CASE("text: line-height sets each line's height and centres the text in it; letter-spacing widens it")
{
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr); // ascent 10, descent 2
    Text t{core::StringView(u8"ab cd"), &cf};
    t.SetWhiteSpace(TextWhiteSpace::Normal);
    t.SetLineHeight(20.0f);
    const TextLayout& layout = t.LayoutFor(Rect{0.0f, 0.0f, 20.0f, 100.0f});
    REQUIRE(layout.Lines.Size() == 2u);
    CHECK(layout.Lines[1].Top == doctest::Approx(20.0f));
    CHECK(layout.Lines[0].Baseline == doctest::Approx((20.0f - 12.0f) * 0.5f + 10.0f)); // half-leading
    CHECK(t.GetLineHeight() == doctest::Approx(20.0f));

    Text spaced{core::StringView(u8"abc"), &cf};
    spaced.SetLetterSpacing(2.0f);
    CHECK(spaced.GetWidth() == doctest::Approx(18.0f + 6.0f));
}

TEST_CASE("text: a clamp keeps the first lines")
{
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr);
    Text t{core::StringView(u8"one two three four"), &cf};
    t.SetWhiteSpace(TextWhiteSpace::Normal);
    t.SetMaxLines(2);
    const TextLayout& layout = t.LayoutFor(Rect{0.0f, 0.0f, 30.0f, 100.0f});
    CHECK(layout.Lines.Size() == 2u);
    CHECK(layout.Clamped);
    CHECK(t.MeasureWrapped(30.0f).y == doctest::Approx(24.0f));
}

TEST_CASE("text: a wrapped draw without a font service produces no geometry and does not crash")
{
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr);
    Text t{core::StringView(u8"hello world foo"), &cf};
    t.SetWhiteSpace(TextWhiteSpace::Normal);

    vg::VGContext ctx; // no font service -> DrawText early-returns, but exercises the layout path
    DrawContext dc{ctx};
    t.Draw(dc, Rect{0.0f, 0.0f, 60.0f, 100.0f});
    CHECK(ctx.GetBatch().vertices.Size() == 0);
}
