// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - StyleRule / StyleSheet cascade tests: property blocks and specificity-
// ordered resolution against a UIWidget.
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

    core::RefPtr<UIWidget> Widget(const char8_t* tag)
    {
        auto w = Make<UIWidget>();
        w->SetTag(core::StringView(tag));
        return w;
    }
    StyleRule Rule(const char8_t* selector) { return StyleRule(core::StringView(selector)); }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
}

TEST_CASE("style-rule: set and override declarations")
{
    StyleRule r = Rule(u8"button");
    r.SetProperty(SV(u8"color"), SV(u8"black"));
    r.SetProperty(SV(u8"padding"), SV(u8"4"));
    CHECK(r.PropertyCount() == 2);
    r.SetProperty(SV(u8"color"), SV(u8"white")); // override, not append
    CHECK(r.PropertyCount() == 2);
    CHECK(r.Specificity() == 1); // tag
}

TEST_CASE("resolved-style: set/get/has/override")
{
    ResolvedStyle s;
    CHECK_FALSE(s.Has(SV(u8"color")));
    s.Set(SV(u8"color"), SV(u8"red"));
    s.Set(SV(u8"color"), SV(u8"blue")); // override
    CHECK(s.Count() == 1);
    CHECK(s.Has(SV(u8"color")));
    CHECK(s.Get(SV(u8"color")) == SV(u8"blue"));
    CHECK(s.Get(SV(u8"missing"), SV(u8"fallback")) == SV(u8"fallback"));
}

TEST_CASE("stylesheet: higher specificity wins")
{
    auto w = Widget(u8"button");
    w->AddClass(SV(u8"primary"));

    StyleSheet sheet;
    StyleRule tagRule = Rule(u8"button");
    tagRule.SetProperty(SV(u8"color"), SV(u8"black"));
    tagRule.SetProperty(SV(u8"padding"), SV(u8"4"));
    StyleRule classRule = Rule(u8".primary");
    classRule.SetProperty(SV(u8"color"), SV(u8"white")); // class (1024) beats tag (1)
    sheet.AddRule(core::Move(tagRule));
    sheet.AddRule(core::Move(classRule));

    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"white")); // from .primary
    CHECK(rs.Get(SV(u8"padding-top")) == SV(u8"4"));   // only in the tag rule
    CHECK_FALSE(rs.Has(SV(u8"margin")));
}

TEST_CASE("stylesheet: id beats class beats tag")
{
    auto w = Widget(u8"button");
    w->SetId(SV(u8"ok"));
    w->AddClass(SV(u8"primary"));

    StyleSheet sheet;
    StyleRule t = Rule(u8"button");
    t.SetProperty(SV(u8"color"), SV(u8"tag"));
    StyleRule c = Rule(u8".primary");
    c.SetProperty(SV(u8"color"), SV(u8"class"));
    StyleRule i = Rule(u8"#ok");
    i.SetProperty(SV(u8"color"), SV(u8"id"));
    sheet.AddRule(core::Move(t));
    sheet.AddRule(core::Move(i)); // add id before class to prove ordering is by specificity
    sheet.AddRule(core::Move(c));

    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"id"));
}

TEST_CASE("stylesheet: equal specificity resolves by source order (last wins)")
{
    auto w = Widget(u8"button");
    w->AddClass(SV(u8"x"));

    StyleSheet sheet;
    StyleRule a = Rule(u8".x");
    a.SetProperty(SV(u8"color"), SV(u8"red"));
    StyleRule b = Rule(u8".x");
    b.SetProperty(SV(u8"color"), SV(u8"blue"));
    sheet.AddRule(core::Move(a));
    sheet.AddRule(core::Move(b));

    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Get(SV(u8"color")) == SV(u8"blue")); // later source wins the tie
}

TEST_CASE("stylesheet: non-matching rules contribute nothing")
{
    auto w = Widget(u8"button");
    StyleSheet sheet;
    StyleRule other = Rule(u8"span");
    other.SetProperty(SV(u8"color"), SV(u8"nope"));
    sheet.AddRule(core::Move(other));

    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Count() == 0);
}

TEST_CASE("stylesheet: rules found through different keys still tie by source order")
{
    // The index keys .a and .b apart; the element lists b first, so .b's rule is found first, yet
    // .a came first in the sheet and the later .b wins.
    auto w = Widget(u8"button");
    w->AddClass(SV(u8"b"));
    w->AddClass(SV(u8"a"));
    StyleSheet sheet;
    StyleRule a = Rule(u8".a");
    a.SetProperty(SV(u8"color"), SV(u8"red"));
    StyleRule b = Rule(u8".b");
    b.SetProperty(SV(u8"color"), SV(u8"blue"));
    sheet.AddRule(core::Move(a));
    sheet.AddRule(core::Move(b));
    CHECK(sheet.Resolve(*w.Get()).Get(SV(u8"color")) == SV(u8"blue"));
}

TEST_CASE("stylesheet: each key kind finds its rules, and a rule added after a resolve is seen")
{
    auto w = Widget(u8"button");
    w->SetId(SV(u8"ok"));
    w->AddClass(SV(u8"primary"));
    StyleSheet sheet;
    const auto add = [&sheet](const char8_t* selector, const char8_t* name)
    {
        StyleRule rule = Rule(selector);
        rule.SetProperty(SV(name), SV(u8"1px"));
        sheet.AddRule(core::Move(rule));
    };
    add(u8"#ok", u8"padding-left");
    add(u8"panel .primary", u8"padding-top");   // keyed by its subject's class, not the ancestor's
    add(u8"button:hover", u8"padding-right");   // keyed by tag; the state turns it away
    add(u8"*", u8"padding-bottom");
    add(u8"[id=ok]", u8"margin-left");          // no id, class or tag: tried everywhere
    add(u8"#other", u8"margin-top");
    add(u8"label", u8"margin-right");
    add(u8"button:no-such-state", u8"margin-bottom"); // never matches: in no list

    const ResolvedStyle first = sheet.Resolve(*w.Get());
    CHECK(first.Has(SV(u8"padding-left")));
    CHECK_FALSE(first.Has(SV(u8"padding-top"))); // no panel above it
    CHECK_FALSE(first.Has(SV(u8"padding-right")));
    CHECK(first.Has(SV(u8"padding-bottom")));
    CHECK(first.Has(SV(u8"margin-left")));
    CHECK_FALSE(first.Has(SV(u8"margin-top")));
    CHECK_FALSE(first.Has(SV(u8"margin-right")));
    CHECK_FALSE(first.Has(SV(u8"margin-bottom")));

    add(u8"button.primary", u8"border-left-width");
    CHECK(sheet.Resolve(*w.Get()).Has(SV(u8"border-left-width")));
}
