// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - @import (E13 of Specs/gui-lab-evolution-2.md): a sheet's imports load through the resource
// provider, each (its own imports first) ahead of what imported it, so the importing sheet wins a
// tie; a chain that comes back to a sheet stops there.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.image;
import foundation.vg.svg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // Sheets by path; every load counted.
    class Sheets : public IResourceProvider
    {
    public:
        Sheets() : IResourceProvider(core::DefaultAllocator()) {}
        core::Array<core::String> paths;
        core::Array<core::String> texts;
        core::Array<core::String> loaded;
        void Add(const char8_t* path, const char8_t* text)
        {
            paths.PushBack(core::String(SV(path)));
            texts.PushBack(core::String(SV(text)));
        }
        const foundation::image::ImageData* LoadImage(core::StringView) override { return nullptr; }
        const foundation::vg::svg::SVGDocument* LoadSvg(core::StringView) override { return nullptr; }
        bool LoadText(core::StringView path, core::String& out) override
        {
            loaded.PushBack(core::String(path));
            for (core::usize i = 0; i < paths.Size(); ++i)
                if (paths[i].AsView() == path)
                {
                    out = texts[i];
                    return true;
                }
            return false;
        }
    };
}

TEST_CASE("import: the parser reads url() and quoted paths")
{
    const StyleSheet sheet = CSSParser::Parse(SV(u8"@import url(\"theme/base.css\"); @import 'theme/extra.css' screen; .a { color: red; }"));
    REQUIRE(sheet.Imports().Size() == 2u);
    CHECK(sheet.Imports()[0] == SV(u8"theme/base.css"));
    CHECK(sheet.Imports()[1] == SV(u8"theme/extra.css"));
    CHECK(sheet.RuleCount() == 1u);
}

TEST_CASE("import: imported rules come first, nested imports before them, a cycle stops, a missing one is skipped")
{
    Sheets sheets;
    sheets.Add(u8"base.css", u8"@import url(tokens.css); .a { opacity: 0.25; } .b { opacity: 0.25; }");
    sheets.Add(u8"tokens.css", u8"@import url(base.css); .a { opacity: 0.1; } .c { opacity: 0.1; }"); // back to base: stops
    core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    core::RefPtr<Panel> a = core::MakeRef<Panel>(core::DefaultAllocator());
    core::RefPtr<Panel> b = core::MakeRef<Panel>(core::DefaultAllocator());
    core::RefPtr<Panel> c = core::MakeRef<Panel>(core::DefaultAllocator());
    a->AddClass(SV(u8"a"));
    b->AddClass(SV(u8"b"));
    c->AddClass(SV(u8"c"));
    root->AddChild(a.Get());
    root->AddChild(b.Get());
    root->AddChild(c.Get());
    StyleManager styles;
    styles.SetResourceProvider(&sheets);
    styles.SetStyleSheet(CSSParser::Parse(SV(u8"@import url(base.css); @import url(missing.css); .b { opacity: 0.5; }"), SV(u8"main.css")));
    styles.ApplyTree(*root.Get());
    CHECK(a->GetAlpha() == doctest::Approx(0.25f)); // base.css after tokens.css: it wins
    CHECK(b->GetAlpha() == doctest::Approx(0.5f));  // the importing sheet after both
    CHECK(c->GetAlpha() == doctest::Approx(0.1f));
    CHECK(sheets.loaded.Size() == 3u); // base, tokens, missing; base not again
    styles.ApplyTree(*root.Get());
    CHECK(sheets.loaded.Size() == 3u); // once per sheet
    // A new sheet expands its imports again (hot reload).
    styles.SetStyleSheet(CSSParser::Parse(SV(u8"@import url(tokens.css);"), SV(u8"main.css")));
    styles.ApplyTree(*root.Get());
    CHECK(c->GetAlpha() == doctest::Approx(0.1f));
    CHECK(a->GetAlpha() == doctest::Approx(0.1f)); // tokens imports base ahead of itself: tokens wins now
}
