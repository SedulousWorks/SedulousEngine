// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - what the loaders say (E1 of Specs/gui-lab-evolution-3.md): the markup loader's and the CSS
// parser's diagnostics, with lines where they are known, and the check of a sheet's property names
// against the style table and the registered element types: what a cook warns of or fails on.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    bool Has(core::StringView text, core::StringView part) { return MarkupLoader::FindFrom(text, part, 0) < text.Size(); }
    bool Says(const core::Array<GuiDiagnostic>& all, const char8_t* part)
    {
        for (const GuiDiagnostic& d : all)
            if (Has(d.Message.AsView(), SV(part)))
                return true;
        return false;
    }
}

TEST_CASE("diagnostics: markup that does not parse is an error with its line; an unknown element and attribute are warnings")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    core::Array<GuiDiagnostic> said;
    MarkupLoader loader(elements, core::DefaultAllocator());
    loader.SetDiagnostics(&said);
    CHECK_FALSE(loader.LoadFromString(SV(u8"<Panel>\n  <Label text=\"a\">\n</Panel>")));
    REQUIRE(said.Size() == 1);
    CHECK(said[0].Level == GuiDiagnostic::Severity::Error);
    CHECK(said[0].Line >= 2u);

    said.Clear();
    core::RefPtr<Node> made = loader.LoadFromString(SV(u8"<Panel><Lable text=\"typo\"/><Label txet=\"x\"/></Panel>"));
    REQUIRE(made);
    CHECK(made->ChildCount() == 1); // the unknown element left out, the Label kept
    REQUIRE(said.Size() == 2);
    CHECK(said[0].Level == GuiDiagnostic::Severity::Warning);
    CHECK(Says(said, u8"<Lable>"));
    CHECK(Says(said, u8"'txet'"));

    said.Clear();
    CHECK_FALSE(loader.LoadFromString(SV(u8"<?xml version=\"1.0\"?>")));
    CHECK(said.Size() == 1);

    // Each warning names its line: the dropped element's, the unknown attribute's own (on a line
    // of its own here), so an editor marks it and a cook's warning says where.
    said.Clear();
    REQUIRE(loader.LoadFromString(SV(u8"<Panel>\n  <Lable text=\"typo\"/>\n  <Label text=\"ok\"\n         txet=\"x\"/>\n</Panel>")));
    REQUIRE(said.Size() == 2);
    for (const GuiDiagnostic& d : said)
        if (Has(d.Message.AsView(), SV(u8"<Lable>")))
            CHECK(d.Line == 2u);
        else if (Has(d.Message.AsView(), SV(u8"'txet'")))
            CHECK(d.Line == 4u);
}

TEST_CASE("diagnostics: the CSS parser says what it skips, each with its line")
{
    core::Array<GuiDiagnostic> said;
    const StyleSheet sheet = CSSParser::Parse(SV(u8"@charset \"utf-8\";\n"
                                                 u8".a { color: red; width 10px; }\n"
                                                 u8".b:hovr { color: blue; }\n"
                                                 u8"@unknown { x: y; }\n"
                                                 u8".c { color: green; }\n"
                                                 u8".d"),
                                              SV(u8"test.css"), &said);
    CHECK(sheet.Rules().Size() == 3); // .a, .b (never matching), .c
    CHECK(Says(said, u8"@charset"));
    CHECK(Says(said, u8"width 10px"));
    CHECK(Says(said, u8".b:hovr"));
    CHECK(Says(said, u8"@unknown"));
    CHECK(Says(said, u8".d"));
    for (const GuiDiagnostic& d : said)
        CHECK(d.Level == GuiDiagnostic::Severity::Warning);
    for (const GuiDiagnostic& d : said)
        if (Has(d.Message.AsView(), SV(u8"width 10px")))
            CHECK(d.Line == 2u);
        else if (Has(d.Message.AsView(), SV(u8".b:hovr")))
            CHECK(d.Line == 3u);

    core::Array<GuiDiagnostic> none;
    (void)CSSParser::Parse(SV(u8"@import \"other.css\"; @media (max-width: 600px) { .a { color: red; } } @keyframes k { from { opacity: 0; } }"),
                           SV(u8"ok.css"), &none);
    CHECK(none.IsEmpty());
}

TEST_CASE("diagnostics: a sheet's property names are checked against the style table and the registered element types")
{
    RegisterGuiElements();
    core::Array<GuiDiagnostic> said;
    const StyleSheet sheet = CSSParser::Parse(SV(u8".a { colour: red; color: red; --accent: #fff; margin: 4px; }\n"
                                                 u8"button { nav-up: #b; }\n"
                                                 u8"@keyframes k { from { opactiy: 0; } to { opacity: 1; } }"));
    CheckStyleSheetNames(sheet, said);
    REQUIRE(said.Size() == 2);
    CHECK(Says(said, u8"'colour'"));
    CHECK(said[0].Line == 1u);
    CHECK(Says(said, u8"'opactiy'"));
    CHECK_FALSE(Says(said, u8"nav-up")); // an element type takes it by its CSS name
}
