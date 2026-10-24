// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - font fallback (E11 of Specs/gui-lab-evolution-2.md): font-family takes a list; the first
// family the font service has is the font and the rest are the faces a character it lacks falls
// back to. A piece's glyphs split into runs by the face that drew them, each drawn and measured
// with that face. Over Roboto, which has no Arabic, and DejaVu Sans Mono, which has.
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
    struct Faces
    {
        fonts::TrueTypeFontService service{DefaultAllocator()};
        Faces()
        {
            fonts::TrueTypeFonts::Initialize();
            const String root = foundation::vfs::FindDataRoot();
            REQUIRE(service.LoadFont(u8"Roboto", foundation::vfs::DataPath(root.AsView(), u8"Assets/fonts/roboto/Roboto-Regular.ttf").AsView()) ==
                    fonts::FontLoadResult::Success);
            REQUIRE(service.LoadFont(u8"DejaVu", foundation::vfs::DataPath(root.AsView(), u8"Assets/fonts/dejavu/DejaVuSansMono.ttf").AsView()) ==
                    fonts::FontLoadResult::Success);
        }
        fonts::CachedFont* Roboto() { return service.GetFont(u8"Roboto", 16.0f); }
        fonts::CachedFont* DejaVu() { return service.GetFont(u8"DejaVu", 16.0f); }
    };

    TextLayoutStyle Style(Faces& faces, StringView fallbacks)
    {
        TextLayoutStyle style;
        style.Font = faces.Roboto();
        style.Fonts = &faces.service;
        style.Family = String(u8"Roboto");
        style.Selection.FallbackFamilies = String(fallbacks);
        style.Size = 16.0f;
        return style;
    }
    TextDocument Plain(StringView text)
    {
        TextDocument document;
        TextRun run;
        run.Text = String(text);
        document.Runs.PushBack(Move(run));
        return document;
    }
    // "ab " then Salaam (bytes 3 to 11).
    constexpr const char8_t* kMixed = u8"ab سلام";

    // The run drawing bytes [start, end), or null when glyphs of more than one run do.
    const LaidOutGlyphs* RunOf(const TextLayout& layout, usize start, usize end)
    {
        const LaidOutGlyphs* found = nullptr;
        for (const LaidOutGlyphs& run : layout.GlyphRuns)
            for (usize g = 0; g < run.Glyphs.Size(); ++g)
                if (run.GlyphStart[g] >= start && run.GlyphEnd[g] <= end)
                {
                    if (found != nullptr && found != &run)
                        return nullptr;
                    found = &run;
                }
        return found;
    }
    bool AllDrawn(const LaidOutGlyphs& run)
    {
        for (const fonts::GlyphPosition& g : run.Glyphs)
            if (g.glyphId == 0)
                return false;
        return !run.Glyphs.IsEmpty();
    }
}

TEST_CASE("font fallback: without a fallback, Roboto draws Arabic as missing glyphs")
{
    Faces faces;
    const TextLayout layout = LayOutText(Plain(StringView(kMixed)), Style(faces, StringView{}));
    const LaidOutGlyphs* arabic = RunOf(layout, 3, 11);
    REQUIRE(arabic != nullptr);
    CHECK(arabic->Font == faces.Roboto());
    CHECK_FALSE(AllDrawn(*arabic));
}

TEST_CASE("font fallback: what the font lacks comes from the first fallback that has it, in a run of that face")
{
    Faces faces;
    // A family the service lacks is passed over.
    const TextLayout layout = LayOutText(Plain(StringView(kMixed)), Style(faces, StringView(u8"Missing, 'DejaVu'")));
    const LaidOutGlyphs* latin = RunOf(layout, 0, 2);
    const LaidOutGlyphs* arabic = RunOf(layout, 3, 11);
    REQUIRE(latin != nullptr);
    REQUIRE(arabic != nullptr);
    CHECK(latin->Font == faces.Roboto());
    CHECK(arabic->Font == faces.DejaVu());
    CHECK(arabic != latin);
    CHECK(AllDrawn(*arabic));
    CHECK(AllDrawn(*latin));
    for (const fonts::GlyphPosition& g : arabic->Glyphs)
        CHECK(g.font == 1); // the request's second face
    // Its text and box are its glyphs'.
    CHECK(arabic->TextStart == 3u);
    CHECK(arabic->TextEnd == 11u);
}

TEST_CASE("font fallback: a line measures what its faces draw, and is as tall as the tallest")
{
    Faces faces;
    const TextLayout layout = LayOutText(Plain(StringView(kMixed)), Style(faces, StringView(u8"DejaVu")));
    REQUIRE(layout.Lines.Size() == 1u);
    f32 advances = 0.0f;
    for (const LaidOutGlyphs& run : layout.GlyphRuns)
        for (const fonts::GlyphPosition& g : run.Glyphs)
            advances += g.advance;
    CHECK(layout.Lines[0].Width == doctest::Approx(advances).epsilon(0.01));
    const f32 roboto = faces.Roboto()->font->Metrics().ascent;
    const f32 dejavu = faces.DejaVu()->font->Metrics().ascent;
    CHECK(layout.Lines[0].Baseline >= Max(roboto, dejavu) - 0.01f);
}

TEST_CASE("font fallback: Latin alone keeps one run in the font, its fallbacks unused")
{
    Faces faces;
    const TextLayout layout = LayOutText(Plain(StringView(u8"plain words")), Style(faces, StringView(u8"DejaVu")));
    for (const LaidOutGlyphs& run : layout.GlyphRuns)
        CHECK(run.Font == faces.Roboto());
    CHECK(layout.Lines[0].Baseline == doctest::Approx(faces.Roboto()->font->Metrics().ascent));
}

TEST_CASE("font fallback: a sheet's font-family list gives a label its font, its fallbacks, and draws Arabic")
{
    Faces faces;
    RefPtr<GUIContext> context = MakeRef<GUIContext>(DefaultAllocator());
    context->SetFontService(&faces.service);
    RefPtr<SceneRoot> root = MakeRef<SceneRoot>(DefaultAllocator(), context);
    RefPtr<Label> label = MakeRef<Label>(DefaultAllocator());
    root->AddChild(label.Get());
    label->AddClass(StringView(u8"mixed"));
    label->SetText(StringView(kMixed));
    StyleManager styles;
    styles.SetFontService(&faces.service);
    styles.SetStyleSheet(CSSParser::Parse(StringView(u8".mixed { font-family: \"Nope\", Roboto, 'DejaVu'; font-size: 16px; }")));
    styles.ApplyTree(*root.Get());

    CHECK(label->GetTextStyle().FontFamily == StringView(u8"Roboto"));
    CHECK(label->GetTextStyle().Selection.FallbackFamilies == StringView(u8"DejaVu"));
    CHECK(label->GetFont() == faces.Roboto());
    const TextLayout& layout = label->GetTextLayout().LayoutFor(Rect{0.0f, 0.0f, 400.0f, 40.0f});
    const LaidOutGlyphs* arabic = RunOf(layout, 3, 11);
    REQUIRE(arabic != nullptr);
    CHECK(arabic->Font == faces.DejaVu());
    CHECK(AllDrawn(*arabic));
}
