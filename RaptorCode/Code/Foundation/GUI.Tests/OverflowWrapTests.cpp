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
