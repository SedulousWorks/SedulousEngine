// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - @font-face (E11 of Specs/gui-lab-evolution-2.md): a sheet names a face of a family and its
// file; the style manager asks the host's loader for each, once, under the name the face is chosen
// by ("Brand Bold"), before the restyle that draws in it.
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

TEST_CASE("font face: the parser reads a face's family, source, weight and style")
{
    const StyleSheet sheet = CSSParser::Parse(StringView(
        u8"@font-face { font-family: \"Brand\"; src: url('fonts/brand-bold.ttf') format(\"truetype\"), url(other.woff); font-weight: bold; }"
        u8"@font-face { font-family: Brand; src: url(fonts/brand-italic.ttf); font-style: italic; font-weight: 300; }"
        u8"@font-face { src: url(no-family.ttf); }"
        u8".a { color: red; }"));
    REQUIRE(sheet.FontFaces().Size() == 2u);
    const FontFaceRule& bold = sheet.FontFaces()[0];
    CHECK(bold.Family == StringView(u8"Brand"));
    CHECK(bold.Source == StringView(u8"fonts/brand-bold.ttf"));
    CHECK(bold.Weight == 700);
    CHECK_FALSE(bold.Italic);
    const FontFaceRule& light = sheet.FontFaces()[1];
    CHECK(light.Source == StringView(u8"fonts/brand-italic.ttf"));
    CHECK(light.Weight == 300);
    CHECK(light.Italic);
    CHECK(sheet.Rules().Size() == 1u); // the rule after them still parses
}

TEST_CASE("font face: the loader is asked once per face per sheet, under the name the face is chosen by")
{
    fonts::TrueTypeFontService service{DefaultAllocator()};
    Array<String> asked;
    StyleManager styles;
    styles.SetFontService(&service);
    styles.SetFontFaceLoader(
        [&](StringView face, StringView source)
        {
            String line(face);
            line += StringView(u8"=");
            line += source;
            asked.PushBack(Move(line));
            return false;
        });
    styles.SetStyleSheet(CSSParser::Parse(StringView(u8"@font-face { font-family: Brand; src: url(b.ttf); font-weight: 700; }"
                                                     u8"@font-face { font-family: Brand; src: url(li.ttf); font-weight: 300; font-style: italic; }"
                                                     u8"@font-face { font-family: Brand; src: url(r.ttf); }")));
    RefPtr<SceneRoot> root = MakeRef<SceneRoot>(DefaultAllocator(), MakeRef<GUIContext>(DefaultAllocator()));
    styles.ApplyTree(*root.Get());
    REQUIRE(asked.Size() == 3u);
    CHECK(asked[0] == StringView(u8"Brand Bold=b.ttf"));
    CHECK(asked[1] == StringView(u8"Brand Light Italic=li.ttf"));
    CHECK(asked[2] == StringView(u8"Brand=r.ttf"));
    styles.ApplyTree(*root.Get());
    CHECK(asked.Size() == 3u); // not again for the same sheet
}

TEST_CASE("font face: a face loaded through the host draws the label that asks for its weight")
{
    fonts::TrueTypeFontService service{DefaultAllocator()};
    fonts::TrueTypeFonts::Initialize();
    const String root = foundation::vfs::FindDataRoot();
    REQUIRE(service.LoadFont(u8"Brand", foundation::vfs::DataPath(root.AsView(), u8"Assets/fonts/roboto/Roboto-Regular.ttf").AsView()) ==
            fonts::FontLoadResult::Success);
    usize loads = 0;
    StyleManager styles;
    styles.SetFontService(&service);
    styles.SetFontFaceLoader(
        [&](StringView face, StringView source)
        {
            ++loads;
            return service.LoadFont(face, foundation::vfs::DataPath(root.AsView(), source).AsView()) == fonts::FontLoadResult::Success;
        });
    // The regular face the service has already is not asked for.
    styles.SetStyleSheet(CSSParser::Parse(StringView(u8"@font-face { font-family: Brand; src: url(Assets/fonts/roboto/Roboto-Regular.ttf); }"
                                                     u8"@font-face { font-family: Brand; src: url(Assets/fonts/roboto/Roboto-Bold.ttf); font-weight: bold; }"
                                                     u8".text { font-family: Brand; font-size: 16px; font-weight: 700; }")));
    RefPtr<GUIContext> context = MakeRef<GUIContext>(DefaultAllocator());
    context->SetFontService(&service);
    RefPtr<SceneRoot> scene = MakeRef<SceneRoot>(DefaultAllocator(), context);
    RefPtr<Label> label = MakeRef<Label>(DefaultAllocator());
    scene->AddChild(label.Get());
    label->AddClass(StringView(u8"text"));
    label->SetText(StringView(u8"Bold"));
    styles.ApplyTree(*scene.Get());

    CHECK(loads == 1u);
    CHECK(label->GetTextStyle().Selection.Weight == 700);
    CHECK(label->GetTextLayout().GetFont() == service.GetFont(u8"Brand", 16.0f));
    CHECK(service.HasFamily(u8"Brand Bold"));
    CHECK(foundation::gui::detail::ChooseFace(service, StringView(u8"Brand"), 700, false).Face == StringView(u8"Brand Bold"));
    CHECK(label->GetTextLayout().GetFontService() == &service);
    const TextLayout& layout = label->GetTextLayout().LayoutFor(Rect{0.0f, 0.0f, 400.0f, 40.0f});
    REQUIRE(!layout.GlyphRuns.IsEmpty());
    CHECK(layout.GlyphRuns[0].Font == service.GetFont(u8"Brand Bold", 16.0f));
    CHECK_FALSE(layout.GlyphRuns[0].SyntheticBold);
}
