// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// TextArea (E4 of Specs/gui-lab-evolution.md): the multiline field over the editing model. Return
// breaks a line, its text wraps at its width, up and down move by the lines it shows, keeping their
// column, page keys move a page, Home and End stop at a shown line's ends, it scrolls down to keep
// the caret in view, and it is `rows` lines tall. A mock font: 6px a byte, 12px a line, no shaper.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

namespace
{
    using SV = core::StringView;

    class SixFont : public fonts::IFont
    {
    public:
        core::StringView FamilyName() const override { return SV(u8"six"); }
        core::Span<const core::u8> SourceData() const override { return {}; }
        fonts::FontMetrics Metrics() const override
        {
            fonts::FontMetrics m;
            m.ascent = 10.0f;
            m.descent = -2.0f;
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
        core::f32 MeasureString(core::StringView text) const override { return static_cast<core::f32>(text.Size()) * 6.0f; }
        core::f32 MeasureString(core::StringView text, core::Array<fonts::GlyphPosition>&) const override { return MeasureString(text); }
    };

    core::u32 Key(KeyCode k) { return static_cast<core::u32>(k); }

    // A focused area 54 wide (nine characters a line) and 36 tall (three lines).
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<TextArea> area = core::MakeRef<TextArea>(core::DefaultAllocator());
        fonts::CachedFont font{core::DefaultAllocator(), core::DefaultAllocator().New<SixFont>(), nullptr, nullptr};

        explicit Bed(SV text)
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            area->SetSize(core::Float2{54.0f, 36.0f});
            area->SetFont(&font);
            root->AddChild(area.Get());
            area->SetText(text);
            area->RequestFocus();
        }
        EventDispatcher* d() { return root->GetEventDispatcher(); }
    };
}

TEST_CASE("text area: Return breaks a line; it is rows lines tall when nothing sizes it")
{
    Bed bed(SV(u8"ab"));
    bed.d()->InjectKeyDown(Key(KeyCode::Return));
    bed.d()->InjectText(SV(u8"cd"));
    CHECK(bed.area->GetText() == SV(u8"ab\ncd"));
    int submits = 0;
    bed.area->SetOnSubmit([&](SV) { ++submits; });
    bed.d()->InjectKeyDown(Key(KeyCode::Return));
    CHECK(submits == 0); // a text area's Return is a line break
    bed.area->SetRows(5);
    CHECK(bed.area->MeasureContent(core::Float2{kUnbounded, kUnbounded}).y == doctest::Approx(60.0f));
}

TEST_CASE("text area: up and down move by shown lines and keep their column; Home and End stop at a wrap")
{
    // "alpha beta gamma" wraps at nine characters: "alpha " | "beta " | "gamma".
    Bed bed(SV(u8"alpha beta gamma"));
    bed.area->SetCaret(2); // al|pha
    bed.d()->InjectKeyDown(Key(KeyCode::Down));
    CHECK(bed.area->GetCaret() == 8u); // be|ta
    bed.d()->InjectKeyDown(Key(KeyCode::Down));
    CHECK(bed.area->GetCaret() == 13u); // ga|mma
    bed.d()->InjectKeyDown(Key(KeyCode::Up));
    bed.d()->InjectKeyDown(Key(KeyCode::Up));
    CHECK(bed.area->GetCaret() == 2u);
    bed.d()->InjectKeyDown(Key(KeyCode::End));
    CHECK(bed.area->GetCaret() == 5u); // before the space the line broke at
    bed.d()->InjectKeyDown(Key(KeyCode::Down), static_cast<core::u32>(KeyModShift));
    CHECK(bed.area->SelectedText() == SV(u8" beta"));
    bed.d()->InjectKeyDown(Key(KeyCode::Home));
    CHECK(bed.area->GetCaret() == 6u); // the start of "beta", the line it shows on
}

TEST_CASE("text area: it scrolls down to keep the caret in view; page keys move a page")
{
    Bed bed(SV(u8"1\n2\n3\n4\n5\n6\n7\n8"));
    // The caret at the end, on the eighth line of three shown: scrolled to show it.
    CHECK(bed.area->GetScrollY() == doctest::Approx(8.0f * 12.0f - 36.0f));
    bed.d()->InjectKeyDown(Key(KeyCode::Home), static_cast<core::u32>(KeyModCtrl));
    CHECK(bed.area->GetScrollY() == doctest::Approx(0.0f));
    bed.d()->InjectKeyDown(Key(KeyCode::PageDown));
    CHECK(bed.area->GetCaret() == 6u); // three lines down: the start of "4"
    // A click maps through the scroll.
    bed.d()->InjectKeyDown(Key(KeyCode::End), static_cast<core::u32>(KeyModCtrl));
    bed.d()->InjectMouseDown(core::Float2{1.0f, 1.0f}, MouseButton::Left);
    CHECK(bed.area->GetCaret() == 10u); // the top shown line is "6"
}

TEST_CASE("text area: markup and scripts make one by its element name")
{
    RegisterGuiElements();
    CHECK(ElementTypes::Find(u8"TextArea") == &TextArea::StaticType());
    CHECK(ElementTypes::Find(u8"RichText") == &RichText::StaticType());
}

TEST_CASE("text area: as tall as its text in a scroller, the scroller keeps the caret in view as it is typed in")
{
    core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    core::RefPtr<UIWidget> box = core::MakeRef<UIWidget>(core::DefaultAllocator());
    core::RefPtr<TextArea> area = core::MakeRef<TextArea>(core::DefaultAllocator());
    fonts::CachedFont font{core::DefaultAllocator(), core::DefaultAllocator().New<SixFont>(), nullptr, nullptr};
    root->SetSize(core::Float2{400.0f, 300.0f});
    root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    box->EditLayoutStyle([](LayoutStyle& s)
    {
        s.Direction = FlexDirection::Column;
        s.Width = LayoutLength::Px(100.0f);
        s.Height = LayoutLength::Px(36.0f);
        s.OverflowY = Overflow::Auto;
    });
    area->SetFont(&font);
    area->SetRows(10); // 120 tall, in a box 36 tall
    box->AddChild(area.Get());
    root->AddChild(box.Get());
    (void)root->UpdateLayout();
    area->RequestFocus();
    CHECK(box->GetScrollOffset().y == doctest::Approx(0.0f));
    for (int i = 0; i < 6; ++i)
        root->GetEventDispatcher()->InjectKeyDown(Key(KeyCode::Return));
    // The caret on the seventh line (72 to 84): the box scrolled by the least that shows it.
    CHECK(area->GetScrollY() == doctest::Approx(0.0f));
    CHECK(box->GetScrollOffset().y == doctest::Approx(84.0f - 36.0f));
    root->GetEventDispatcher()->InjectKeyDown(Key(KeyCode::Home), static_cast<core::u32>(KeyModCtrl));
    CHECK(box->GetScrollOffset().y == doctest::Approx(0.0f));
    area->SetFont(nullptr);
}
