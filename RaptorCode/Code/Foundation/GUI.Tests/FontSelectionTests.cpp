// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - font-weight and font-style (E11 of Specs/gui-lab-evolution-2.md): a run's face is the
// family's of the nearest weight in CSS's order, its style matched first; bold and italic are
// synthesized only where no face has them. The faces are named as font files name them
// ("Roboto Bold", "Roboto Light Italic"), each loaded under its name.
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
    // Roboto's files, loaded under the names given (a name per face the test needs).
    struct Faces
    {
        fonts::TrueTypeFontService service{DefaultAllocator()};
        String root = foundation::vfs::FindDataRoot();
        Faces() { fonts::TrueTypeFonts::Initialize(); }
        void Load(const char8_t* name, const char8_t* file)
        {
            REQUIRE(service.LoadFont(StringView(name), foundation::vfs::DataPath(root.AsView(), StringView(file)).AsView()) ==
                    fonts::FontLoadResult::Success);
        }
        void LoadRoboto()
        {
            Load(u8"Roboto", u8"Assets/fonts/roboto/Roboto-Regular.ttf");
            Load(u8"Roboto Bold", u8"Assets/fonts/roboto/Roboto-Bold.ttf");
        }
    };
    struct Scene
    {
        RefPtr<GUIContext> context = MakeRef<GUIContext>(DefaultAllocator());
        RefPtr<SceneRoot> root;
        RefPtr<Panel> panel = MakeRef<Panel>(DefaultAllocator());
        RefPtr<Label> label = MakeRef<Label>(DefaultAllocator());
        StyleManager styles;
        Scene(Faces& faces, const char8_t* css)
        {
            context->SetFontService(&faces.service);
            root = MakeRef<SceneRoot>(DefaultAllocator(), context);
            root->AddChild(panel.Get());
            panel->AddChild(label.Get());
            panel->AddClass(StringView(u8"outer"));
            label->AddClass(StringView(u8"text"));
            label->SetText(StringView(u8"Words"));
            styles.SetFontService(&faces.service);
            styles.SetStyleSheet(CSSParser::Parse(StringView(css)));
            styles.ApplyTree(*root.Get());
        }
        const LaidOutGlyphs& FirstRun() const
        {
            const TextLayout& layout = label->GetTextLayout().LayoutFor(Rect{0.0f, 0.0f, 400.0f, 40.0f});
            REQUIRE(!layout.GlyphRuns.IsEmpty());
            return layout.GlyphRuns[0];
        }
    };
}

TEST_CASE("font selection: weights are tried in CSS's order")
{
    u16 order[9]{};
    foundation::gui::detail::WeightOrder(400, order);
    const u16 normal[] = {400, 500, 300, 200, 100, 600, 700, 800, 900};
    for (usize i = 0; i < 9; ++i)
        CHECK(order[i] == normal[i]);
    foundation::gui::detail::WeightOrder(300, order);
    const u16 light[] = {300, 200, 100, 400, 500, 600, 700, 800, 900};
    for (usize i = 0; i < 9; ++i)
        CHECK(order[i] == light[i]);
    foundation::gui::detail::WeightOrder(650, order); // to the nearest hundred: 700
    const u16 bold[] = {700, 800, 900, 600, 500, 400, 300, 200, 100};
    for (usize i = 0; i < 9; ++i)
        CHECK(order[i] == bold[i]);
    CHECK(foundation::gui::detail::Bolder(400) == 700);
    CHECK(foundation::gui::detail::Bolder(700) == 900);
    CHECK(foundation::gui::detail::Lighter(700) == 400);
    CHECK(foundation::gui::detail::Lighter(400) == 100);
}

TEST_CASE("font selection: the nearest weight's face, the style matched first, the rest synthesized")
{
    Faces faces;
    faces.Load(u8"X", u8"Assets/fonts/roboto/Roboto-Regular.ttf");
    faces.Load(u8"X Bold", u8"Assets/fonts/roboto/Roboto-Bold.ttf");
    faces.Load(u8"X Light Italic", u8"Assets/fonts/roboto/Roboto-Regular.ttf");

    foundation::gui::detail::FaceChoice face = foundation::gui::detail::ChooseFace(faces.service, StringView(u8"X"), 700, false);
    CHECK(face.Face == StringView(u8"X Bold"));
    CHECK_FALSE(face.SyntheticBold);
    face = foundation::gui::detail::ChooseFace(faces.service, StringView(u8"X"), 900, false); // none heavier: down to Bold
    CHECK(face.Face == StringView(u8"X Bold"));
    face = foundation::gui::detail::ChooseFace(faces.service, StringView(u8"X"), 600, false); // up before down
    CHECK(face.Face == StringView(u8"X Bold"));
    face = foundation::gui::detail::ChooseFace(faces.service, StringView(u8"X"), 500, false); // 500 then down: the regular
    CHECK(face.Face == StringView(u8"X"));
    face = foundation::gui::detail::ChooseFace(faces.service, StringView(u8"X"), 300, true);
    CHECK(face.Face == StringView(u8"X Light Italic"));
    CHECK_FALSE(face.SyntheticItalic);
    // Italic before weight: the light italic face, emboldened.
    face = foundation::gui::detail::ChooseFace(faces.service, StringView(u8"X"), 700, true);
    CHECK(face.Face == StringView(u8"X Light Italic"));
    CHECK(face.SyntheticBold);
    CHECK_FALSE(face.SyntheticItalic);
    // No face of the family: asked for as it is, all of it synthesized.
    face = foundation::gui::detail::ChooseFace(faces.service, StringView(u8"Y"), 700, true);
    CHECK(face.Face == StringView(u8"Y"));
    CHECK(face.SyntheticBold);
    CHECK(face.SyntheticItalic);
}

TEST_CASE("font selection: font-weight in a sheet draws a label in the family's bold face")
{
    Faces faces;
    faces.LoadRoboto();
    Scene scene(faces, u8".text { font-family: Roboto; font-size: 16px; font-weight: bold; }");
    CHECK(scene.label->GetTextStyle().Selection.Weight == 700);
    const LaidOutGlyphs& run = scene.FirstRun();
    CHECK(run.Font == faces.service.GetFont(u8"Roboto Bold", 16.0f));
    CHECK_FALSE(run.SyntheticBold);
    CHECK_FALSE(run.SyntheticItalic);
}

TEST_CASE("font selection: a light weight Roboto lacks falls to the regular; italic it lacks is slanted")
{
    Faces faces;
    faces.LoadRoboto();
    Scene scene(faces, u8".text { font-family: Roboto; font-size: 16px; font-weight: 300; font-style: italic; }");
    const LaidOutGlyphs& run = scene.FirstRun();
    CHECK(run.Font == faces.service.GetFont(u8"Roboto", 16.0f));
    CHECK_FALSE(run.SyntheticBold);
    CHECK(run.SyntheticItalic);
}

TEST_CASE("font selection: weight and style inherit, bolder and lighter are of the parent's")
{
    Faces faces;
    faces.LoadRoboto();
    Scene scene(faces, u8".outer { font-family: Roboto; font-size: 16px; font-weight: 700; font-style: italic; }"
                       u8".text { font-weight: bolder; }");
    CHECK(scene.label->GetTextStyle().Selection.Weight == 900);
    CHECK(scene.label->GetTextStyle().Selection.Italic);
    scene.styles.SetStyleSheet(CSSParser::Parse(StringView(u8".outer { font-weight: 700; } .text { font-weight: lighter; }")));
    scene.styles.ApplyTree(*scene.root.Get());
    CHECK(scene.label->GetTextStyle().Selection.Weight == 400);
    CHECK_FALSE(scene.label->GetTextStyle().Selection.Italic);
}

TEST_CASE("font selection: code's weight is pinned over the sheet's")
{
    Faces faces;
    faces.LoadRoboto();
    Scene scene(faces, u8".text { font-family: Roboto; font-size: 16px; font-weight: 300; }");
    scene.label->SetFontWeight(700);
    scene.styles.ApplyTree(*scene.root.Get());
    CHECK(scene.label->GetTextStyle().Selection.Weight == 700);
    CHECK(scene.FirstRun().Font == faces.service.GetFont(u8"Roboto Bold", 16.0f));
}
