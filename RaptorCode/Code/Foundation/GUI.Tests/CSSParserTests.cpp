// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - CSSParser tests: parse .css text into a StyleSheet (comments, selector
// lists, declaration blocks), then resolve end-to-end against a UIWidget.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    core::RefPtr<UIWidget> Widget(const char8_t* tag)
    {
        auto w = Make<UIWidget>();
        w->SetTag(SV(tag));
        return w;
    }
}

TEST_CASE("css-parser: rules, selector lists, and comments")
{
    const char8_t* css = u8R"(
        /* theme */
        button { color: black; padding: 4; }
        .primary, .secondary { color: white; } /* two selectors share the block */
        #ok:hover { color: green; }
    )";
    StyleSheet sheet = CSSParser::Parse(SV(css));
    CHECK(sheet.RuleCount() == 4); // button, .primary, .secondary, #ok:hover
}

TEST_CASE("css-parser: end-to-end resolve on a widget")
{
    const char8_t* css = u8"button { color: black; padding: 4; } .primary { color: white; }";
    StyleSheet sheet = CSSParser::Parse(SV(css));

    auto w = Widget(u8"button");
    w->AddClass(SV(u8"primary"));
    ResolvedStyle rs = sheet.Resolve(*w.Get());

    CHECK(rs.Get(SV(u8"color")) == SV(u8"white")); // .primary beats button
    CHECK(rs.Get(SV(u8"padding-top")) == SV(u8"4")); // the shorthand, as its longhands
    CHECK(rs.Get(SV(u8"padding-left")) == SV(u8"4"));
}

TEST_CASE("css-parser: a shorthand's values reach its sides; trailing semicolon optional")
{
    const char8_t* css = u8"box { margin: 1 2 3 4; color: red }";
    StyleSheet sheet = CSSParser::Parse(SV(css));
    REQUIRE(sheet.RuleCount() == 1);

    auto w = Widget(u8"box");
    ResolvedStyle rs = sheet.Resolve(*w.Get());
    // The shorthand's four values reach their four sides.
    CHECK(rs.Get(SV(u8"margin-top")) == SV(u8"1"));
    CHECK(rs.Get(SV(u8"margin-right")) == SV(u8"2"));
    CHECK(rs.Get(SV(u8"margin-bottom")) == SV(u8"3"));
    CHECK(rs.Get(SV(u8"margin-left")) == SV(u8"4"));
    CHECK(rs.Get(SV(u8"color")) == SV(u8"red"));      // last decl, no semicolon
}

TEST_CASE("css-parser: comment stripping inside blocks and selectors")
{
    const char8_t* css = u8"/* a */ button /* b */ { color: /* c */ red; }";
    StyleSheet sheet = CSSParser::Parse(SV(css));
    auto w = Widget(u8"button");
    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"red"));
}

TEST_CASE("css-parser: descendant/child selectors survive parsing")
{
    const char8_t* css = u8".panel > button { color: blue; } .panel label { color: gray; }";
    StyleSheet sheet = CSSParser::Parse(SV(css));
    CHECK(sheet.RuleCount() == 2);

    auto panel = Make<UIWidget>();
    panel->AddClass(SV(u8"panel"));
    auto button = Widget(u8"button");
    panel->AddChild(button.Get());

    ResolvedStyle rs = sheet.Resolve(*button.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"blue")); // .panel > button matches direct child
}

TEST_CASE("css-parser: empty and malformed input is tolerated")
{
    CHECK(CSSParser::Parse(SV(u8"")).RuleCount() == 0);
    CHECK(CSSParser::Parse(SV(u8"   \n  ")).RuleCount() == 0);
    CHECK(CSSParser::Parse(SV(u8".x {}")).RuleCount() == 1); // empty block ok
    CHECK(CSSParser::Parse(SV(u8"button { color")).RuleCount() ==
          1); // unterminated block: best-effort
}

TEST_CASE("css-parser: each rule keeps its sheet's name, its selector as written and its line, past comments over lines")
{
    const StyleSheet sheet = CSSParser::Parse(SV(
        u8"/* a comment\n"
        u8"   over two lines */\n"
        u8"button { color: red; }\n"       // line 3
        u8"\n"
        u8".a, .b > label\n"               // line 5: both rules of the list
        u8"{ color: blue; }\n"
        u8"@media (min-width: 10px) {\n"
        u8"  /* inside */ panel:hover { opacity: 0.5; }\n" // line 8
        u8"}\n"),
        SV(u8"pages/demo.css"));
    CHECK(sheet.Name() == SV(u8"pages/demo.css"));
    REQUIRE(sheet.RuleCount() == 4u);
    CHECK(sheet.Rules()[0].SelectorText() == SV(u8"button"));
    CHECK(sheet.Rules()[0].Line() == 3u);
    CHECK(sheet.Rules()[1].SelectorText() == SV(u8".a"));
    CHECK(sheet.Rules()[1].Line() == 5u);
    CHECK(sheet.Rules()[2].SelectorText() == SV(u8".b > label"));
    CHECK(sheet.Rules()[2].Line() == 5u);
    CHECK(sheet.Rules()[3].SelectorText() == SV(u8"panel:hover"));
    CHECK(sheet.Rules()[3].Line() == 8u);
    CHECK(CSSParser::Parse(SV(u8"a { color: red; }")).Name().Size() == 0u);
}

TEST_CASE("css-parser: a quoted string and parentheses keep their semicolons, braces and comment openers")
{
    const StyleSheet sheet = CSSParser::Parse(SV(
        u8".a { background-image: url(\"data:image/svg+xml,<svg style='fill:red;stroke:none'>{}/*x*/</svg>\"); color: red; }\n"
        u8".b { background-image: url(data:image/svg+xml;base64,PHN2Zy8+); color: blue; }\n"
        u8"@media (min-width: 1px) { .c { content: \"}\"; color: green; } }\n"
        u8".d { content: 'it\\'s; } still'; color: black; }\n"));
    REQUIRE(sheet.RuleCount() == 4u);
    const auto& a = sheet.Rules()[0].Properties();
    REQUIRE(a.Size() == 2u);
    CHECK(a[0].Value.AsView() == SV(u8"url(\"data:image/svg+xml,<svg style='fill:red;stroke:none'>{}/*x*/</svg>\")"));
    CHECK(a[1].Name.AsView() == SV(u8"color"));
    const auto& b = sheet.Rules()[1].Properties();
    REQUIRE(b.Size() == 2u);
    CHECK(b[0].Value.AsView() == SV(u8"url(data:image/svg+xml;base64,PHN2Zy8+)"));
    const auto& c = sheet.Rules()[2].Properties();
    REQUIRE(c.Size() == 2u);
    CHECK(c[0].Value.AsView() == SV(u8"\"}\""));
    CHECK(sheet.Rules()[2].SelectorText() == SV(u8".c"));
    const auto& d = sheet.Rules()[3].Properties();
    REQUIRE(d.Size() == 2u);
    CHECK(d[1].Value.AsView() == SV(u8"black"));
}
