// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - overflow-wrap (E11 of Specs/gui-lab-evolution-2.md): a word wider than its whole line
// breaks where the line ends, between graphemes, instead of running out of its box; a word that
// fits a line of its own goes to the next line first, as before. Over DejaVu Sans Mono, every
// character as wide as the next.
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.vfs;
import foundation.fonts;
import foundation.fonts.truetype;
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
        fonts::CachedFont* Font() { return service.GetFont(u8"DejaVu", 16.0f); }
        f32 Advance() { return Font()->font->MeasureString(StringView(u8"a")); }
    };
    TextLayout Lay(DejaVu& font, StringView text, f32 maxWidth, bool breakWords)
    {
        TextLayoutStyle style;
        style.Font = font.Font();
        style.Family = String(u8"DejaVu");
        style.Size = 16.0f;
        style.MaxWidth = maxWidth;
        style.BreakWords = breakWords;
        TextDocument document;
        TextRun run;
        run.Text = String(text);
        document.Runs.PushBack(Move(run));
        return LayOutText(document, style);
    }
    // Every line within `width`, and together they cover the text, each starting where the last ended.
    void CheckCovers(const TextLayout& layout, usize size, f32 width)
    {
        REQUIRE(!layout.Lines.IsEmpty());
        CHECK(layout.Lines[0].Start == 0u);
        for (usize i = 0; i < layout.Lines.Size(); ++i)
        {
            CHECK(layout.Lines[i].Width <= width + 0.01f);
            if (i + 1 < layout.Lines.Size())
                CHECK(layout.Lines[i + 1].Start == layout.Lines[i].End);
        }
        CHECK(layout.Lines.Back().End == size);
    }
}

TEST_CASE("overflow wrap: without it a long word runs out of its line")
{
    DejaVu font;
    const f32 width = font.Advance() * 5.5f;
    const TextLayout layout = Lay(font, StringView(u8"abcdefghijklmnop"), width, false);
    REQUIRE(layout.Lines.Size() == 1u);
    CHECK(layout.Lines[0].Width > width);
}

TEST_CASE("overflow wrap: break-word breaks a word wider than its line where the line ends")
{
    DejaVu font;
    const f32 width = font.Advance() * 5.5f; // five characters to a line
    const TextLayout layout = Lay(font, StringView(u8"abcdefghijklmnop"), width, true);
    REQUIRE(layout.Lines.Size() == 4u);
    CHECK(layout.Lines[0].End == 5u);
    CheckCovers(layout, 16, width);
}

TEST_CASE("overflow wrap: a long word after a short one starts its own line, then breaks")
{
    DejaVu font;
    const f32 width = font.Advance() * 5.5f;
    const TextLayout layout = Lay(font, StringView(u8"hi abcdefghij"), width, true);
    REQUIRE(layout.Lines.Size() == 3u);
    CHECK(layout.Lines[0].End == 3u); // "hi " alone
    CHECK(layout.Lines[1].End == 8u);
    CheckCovers(layout, 13, width);
}

TEST_CASE("overflow wrap: a line narrower than a character still holds one, and a grapheme is not split")
{
    DejaVu font;
    const TextLayout narrow = Lay(font, StringView(u8"abc"), font.Advance() * 0.5f, true);
    CHECK(narrow.Lines.Size() == 3u);
    // e and a combining acute: one grapheme, two characters.
    const TextLayout marks = Lay(font, StringView(u8"aéb"), font.Advance() * 0.5f, true);
    REQUIRE(marks.Lines.Size() == 3u);
    CHECK(marks.Lines[1].Start == 1u);
    CHECK(marks.Lines[1].End == 4u);
}

TEST_CASE("overflow wrap: inherits from a sheet, and normal turns it off")
{
    DejaVu font;
    RefPtr<SceneRoot> root = MakeRef<SceneRoot>(DefaultAllocator(), MakeRef<GUIContext>(DefaultAllocator()));
    RefPtr<Panel> panel = MakeRef<Panel>(DefaultAllocator());
    RefPtr<Label> label = MakeRef<Label>(DefaultAllocator());
    root->AddChild(panel.Get());
    panel->AddChild(label.Get());
    panel->AddClass(StringView(u8"page"));
    label->SetFont(font.Font());
    label->AddClass(StringView(u8"text"));
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(StringView(u8".page { overflow-wrap: break-word; }")));
    styles.ApplyTree(*root.Get());
    CHECK(label->GetTextStyle().BreakWords);
    CHECK(label->GetTextLayout().GetBreakWords());
    styles.SetStyleSheet(CSSParser::Parse(StringView(u8".page { overflow-wrap: anywhere; } .text { overflow-wrap: normal; }")));
    styles.ApplyTree(*root.Get());
    CHECK_FALSE(label->GetTextStyle().BreakWords);
}
