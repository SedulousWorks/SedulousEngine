// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - CSS !important + custom-property (variable) tests, end-to-end via the
// parser -> cascade -> resolve (+ typed application for the var-driven background).
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

TEST_CASE("css-important: overrides higher specificity")
{
    auto w = Widget(u8"button");
    w->AddClass(SV(u8"primary"));
    // .primary (1024) beats button (1) normally, but button's !important wins.
    StyleSheet sheet =
        CSSParser::Parse(SV(u8".primary { color: red; } button { color: blue !important; }"));
    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"blue"));
}

TEST_CASE("css-important: important beats important by specificity")
{
    auto w = Widget(u8"button");
    w->AddClass(SV(u8"primary"));
    StyleSheet sheet = CSSParser::Parse(
        SV(u8"button { color: red !important; } .primary { color: green !important; }"));
    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"green")); // .primary (higher spec) important wins
}

TEST_CASE("css-important: normal declaration cannot override an important one")
{
    auto w = Widget(u8"button");
    w->AddClass(SV(u8"primary"));
    // button:!important applied first (low spec), then .primary normal (higher spec) - must NOT win.
    StyleSheet sheet =
        CSSParser::Parse(SV(u8"button { color: red !important; } .primary { color: green; }"));
    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"red"));
}

TEST_CASE("css-vars: var() resolves against a custom property")
{
    auto w = Widget(u8"button");
    StyleSheet sheet =
        CSSParser::Parse(SV(u8"button { --accent: #00ff00; color: var(--accent); }"));
    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"#00ff00"));
    CHECK(rs.Get(SV(u8"--accent")) == SV(u8"#00ff00")); // custom property retained
}

TEST_CASE("css-vars: fallback used when the variable is missing")
{
    auto w = Widget(u8"button");
    StyleSheet sheet = CSSParser::Parse(SV(u8"button { color: var(--missing, blue); }"));
    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"blue"));
}

TEST_CASE("css-vars: cascade of the variable drives the resolved value")
{
    auto w = Widget(u8"button");
    w->AddClass(SV(u8"primary"));
    // .primary overrides --accent; color: var(--accent) should pick the cascaded value.
    StyleSheet sheet = CSSParser::Parse(
        SV(u8"button { --accent: red; color: var(--accent); } .primary { --accent: blue; }"));
    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"blue"));
}

TEST_CASE("css-vars: end-to-end through the applier")
{
    auto w = Widget(u8"button");
    StyleSheet sheet =
        CSSParser::Parse(SV(u8"button { --bg: #0000ff; background-color: var(--bg); }"));
    ApplyStyle(*w.Get(), sheet.Resolve(*w.Get()));

    CHECK(w->GetBox().BackgroundColor.b == doctest::Approx(1.0f)); // var(--bg) -> #0000ff -> blue
}
