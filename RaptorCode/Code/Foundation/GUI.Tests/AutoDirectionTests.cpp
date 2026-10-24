// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - direction: auto (E11 of Specs/gui-lab-evolution-2.md): each paragraph of a node's text
// runs as its first strong character reads, typed or translated; one with none runs as the node's
// boxes do, which follow what holds it. With the resolver installed and without. Over DejaVu Sans
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
    struct Bidi
    {
        Bidi() { fonts::BidiAlgorithm::Install(); }
        ~Bidi() { fonts::BidiAlgorithm::Uninstall(); }
    };
    TextLayout Lay(DejaVu& font, StringView text, bool autoRightToLeft)
    {
        TextLayoutStyle style;
        style.Font = font.service.GetFont(u8"DejaVu", 16.0f);
        style.Family = String(u8"DejaVu");
        style.Size = 16.0f;
        style.Direction = fonts::TextDirection::Auto;
        style.AutoRightToLeft = autoRightToLeft;
        TextDocument document;
        TextRun run;
        run.Text = String(text);
        document.Runs.PushBack(Move(run));
        return LayOutText(document, style);
    }
    // Salaam, then a Latin word.
    constexpr const char8_t* kArabicFirst = u8"سلام ok";
    constexpr const char8_t* kLatinFirst = u8"ok سلام";
}

TEST_CASE("auto direction: a paragraph runs as its first strong character reads, each paragraph its own")
{
    DejaVu font;
    Bidi bidi;
    CHECK(Lay(font, StringView(kArabicFirst), false).Lines[0].RightToLeft);
    CHECK_FALSE(Lay(font, StringView(kLatinFirst), true).Lines[0].RightToLeft);
    String two(kArabicFirst);
    two += StringView(u8"\n");
    two += StringView(kLatinFirst);
    const TextLayout layout = Lay(font, two.AsView(), false);
    REQUIRE(layout.Lines.Size() == 2u);
    CHECK(layout.Lines[0].RightToLeft);
    CHECK_FALSE(layout.Lines[1].RightToLeft);
}

TEST_CASE("auto direction: digits and punctuation alone run as the node does")
{
    DejaVu font;
    Bidi bidi;
    CHECK(Lay(font, StringView(u8"42 - 7"), true).Lines[0].RightToLeft);
    CHECK_FALSE(Lay(font, StringView(u8"42 - 7"), false).Lines[0].RightToLeft);
    CHECK(Lay(font, StringView{}, true).Lines[0].RightToLeft); // an empty field's caret on its node's start
}

TEST_CASE("auto direction: without a resolver the first strong character still decides")
{
    DejaVu font;
    CHECK(Lay(font, StringView(kArabicFirst), false).Lines[0].RightToLeft);
    CHECK_FALSE(Lay(font, StringView(kLatinFirst), true).Lines[0].RightToLeft);
}

TEST_CASE("auto direction: a sheet's direction: auto sets a label's paragraphs by its text, its boxes by its parent")
{
    DejaVu font;
    Bidi bidi;
    RefPtr<GUIContext> context = MakeRef<GUIContext>(DefaultAllocator());
    RefPtr<SceneRoot> root = MakeRef<SceneRoot>(DefaultAllocator(), context);
    RefPtr<Panel> panel = MakeRef<Panel>(DefaultAllocator());
    RefPtr<Label> label = MakeRef<Label>(DefaultAllocator());
    root->AddChild(panel.Get());
    panel->AddChild(label.Get());
    panel->AddClass(StringView(u8"page"));
    label->AddClass(StringView(u8"field"));
    label->SetFont(font.service.GetFont(u8"DejaVu", 16.0f));
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(StringView(u8".page { direction: rtl; } .field { direction: auto; }")));
    styles.ApplyTree(*root.Get());

    CHECK(label->GetLayoutDirection() == Node::LayoutDirection::Auto);
    CHECK(label->IsRightToLeft()); // its boxes: as the page's
    CHECK(label->GetTextLayout().GetDirection().Direction == fonts::TextDirection::Auto);
    CHECK(label->GetTextLayout().GetDirection().AutoRightToLeft);
    label->SetText(StringView(kLatinFirst));
    CHECK_FALSE(label->GetTextLayout().LayoutFor(Rect{0.0f, 0.0f, 400.0f, 40.0f}).Lines[0].RightToLeft);
    label->SetText(StringView(kArabicFirst));
    CHECK(label->GetTextLayout().LayoutFor(Rect{0.0f, 0.0f, 400.0f, 40.0f}).Lines[0].RightToLeft);
    CHECK(label->GetDirectionName() == StringView(u8"auto"));
}
