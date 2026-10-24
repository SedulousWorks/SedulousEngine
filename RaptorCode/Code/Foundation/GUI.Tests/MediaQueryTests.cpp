// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - @media query tests: condition evaluation against a MediaContext, and
// end-to-end parsing + media-gated resolution; a resize restyling only what reads the viewport.
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

TEST_CASE("media-query: single feature")
{
    MediaQuery mq(SV(u8"(min-width: 600px)"));
    CHECK(mq.FeatureCount() == 1);
    CHECK(mq.Evaluate(MediaContext{800.0f, 0.0f, 96.0f}));
    CHECK_FALSE(mq.Evaluate(MediaContext{400.0f, 0.0f, 96.0f}));
    CHECK(mq.Evaluate(MediaContext{600.0f, 0.0f, 96.0f})); // inclusive
}

TEST_CASE("media-query: conjunction (and)")
{
    MediaQuery mq(SV(u8"(min-width: 600px) and (max-width: 900px)"));
    CHECK(mq.FeatureCount() == 2);
    CHECK(mq.Evaluate(MediaContext{800.0f, 0.0f, 96.0f}));
    CHECK_FALSE(mq.Evaluate(MediaContext{1000.0f, 0.0f, 96.0f})); // over max
    CHECK_FALSE(mq.Evaluate(MediaContext{500.0f, 0.0f, 96.0f}));  // under min
}

TEST_CASE("media-query: height features")
{
    MediaQuery mq(SV(u8"(max-height: 480px)"));
    CHECK(mq.Evaluate(MediaContext{0.0f, 400.0f, 96.0f}));
    CHECK_FALSE(mq.Evaluate(MediaContext{0.0f, 600.0f, 96.0f}));
}

TEST_CASE("media-query: empty always matches")
{
    MediaQuery empty;
    CHECK(empty.IsEmpty());
    CHECK(empty.Evaluate(MediaContext{0.0f, 0.0f, 0.0f}));
}

TEST_CASE("media-query: @media block parses and gates resolution")
{
    StyleSheet sheet = CSSParser::Parse(
        SV(u8"button { color: black; } @media (min-width: 600px) { button { color: red; } }"));
    CHECK(sheet.RuleCount() == 2);

    auto w = Widget(u8"button");
    // Wide viewport: the @media rule is active and (later source) wins.
    CHECK(sheet.Resolve(*w.Get(), MediaContext{800.0f, 600.0f, 96.0f}).Get(SV(u8"color")) ==
          SV(u8"red"));
    // Narrow viewport: the @media rule is inactive; the base rule stands.
    CHECK(sheet.Resolve(*w.Get(), MediaContext{400.0f, 600.0f, 96.0f}).Get(SV(u8"color")) ==
          SV(u8"black"));
}

TEST_CASE("media-query: multiple rules inside one @media block")
{
    StyleSheet sheet = CSSParser::Parse(
        SV(u8"@media (min-width: 600px) { button { color: red; } .box { padding: 8; } }"));
    CHECK(sheet.RuleCount() == 2);

    auto btn = Widget(u8"button");
    CHECK(sheet.Resolve(*btn.Get(), MediaContext{800.0f, 0.0f, 96.0f}).Get(SV(u8"color")) ==
          SV(u8"red"));
    CHECK_FALSE(sheet.Resolve(*btn.Get(), MediaContext{400.0f, 0.0f, 96.0f}).Has(SV(u8"color")));
}

TEST_CASE("media-query: a feature it does not know matches nothing, rather than everything")
{
    const MediaContext wide{800.0f, 600.0f, 96.0f};
    CHECK_FALSE(MediaQuery(SV(u8"(aspect-ratio: 16/9)")).Evaluate(wide));
    CHECK_FALSE(MediaQuery(SV(u8"(prefers-reduced-motion)")).Evaluate(wide)); // known now: the context does not ask for it
    CHECK_FALSE(MediaQuery(SV(u8"(min-width: 600px) and (hover: hover)")).Evaluate(wide));
    CHECK(MediaQuery(SV(u8"(min-width: 600px)")).Evaluate(wide));
    StyleSheet sheet = CSSParser::Parse(SV(u8"button { color: black; } @media (pointer: coarse) { button { color: red; } }"));
    CHECK(sheet.Resolve(*Widget(u8"button").Get(), wide).Get(SV(u8"color")) == SV(u8"black"));
}

TEST_CASE("media-query: orientation, not, comma lists and media types (E13)")
{
    const MediaContext wide{800.0f, 600.0f, 96.0f};
    const MediaContext tall{600.0f, 800.0f, 96.0f};
    CHECK(MediaQuery(SV(u8"(orientation: landscape)")).Evaluate(wide));
    CHECK_FALSE(MediaQuery(SV(u8"(orientation: landscape)")).Evaluate(tall));
    CHECK(MediaQuery(SV(u8"(orientation: portrait)")).Evaluate(tall));
    CHECK(MediaQuery(SV(u8"not (orientation: portrait)")).Evaluate(wide));
    CHECK_FALSE(MediaQuery(SV(u8"not all and (min-width: 700px)")).Evaluate(wide));
    CHECK(MediaQuery(SV(u8"screen and (max-width: 500px), (orientation: portrait)")).Evaluate(tall)); // the second
    CHECK_FALSE(MediaQuery(SV(u8"screen and (max-width: 500px), (orientation: portrait)")).Evaluate(wide));
    CHECK_FALSE(MediaQuery(SV(u8"print")).Evaluate(wide));
    CHECK_FALSE(MediaQuery(SV(u8"not (hover: hover)")).Evaluate(wide)); // a feature it cannot test: not either
    CHECK(MediaQuery(SV(u8"(hover: hover), (min-width: 1px)")).Evaluate(wide)); // another in the list still can
}

TEST_CASE("media-query: the host's preferences: colour scheme, contrast, reduced motion")
{
    MediaContext context{800.0f, 600.0f, 96.0f};
    CHECK(MediaQuery(SV(u8"(prefers-color-scheme: dark)")).Evaluate(context)); // dark by default
    context.DarkScheme = false;
    CHECK(MediaQuery(SV(u8"(prefers-color-scheme: light)")).Evaluate(context));
    CHECK(MediaQuery(SV(u8"(prefers-contrast: no-preference)")).Evaluate(context));
    CHECK_FALSE(MediaQuery(SV(u8"(prefers-contrast)")).Evaluate(context));
    context.Contrast = ContrastPreference::More;
    CHECK(MediaQuery(SV(u8"(prefers-contrast: more)")).Evaluate(context));
    CHECK(MediaQuery(SV(u8"(prefers-contrast)")).Evaluate(context));
    CHECK_FALSE(MediaQuery(SV(u8"(prefers-reduced-motion: reduce)")).Evaluate(context));
    context.ReducedMotion = true;
    CHECK(MediaQuery(SV(u8"(prefers-reduced-motion)")).Evaluate(context));

    // From the GUI to a sheet: a root's media context carries the host's flags.
    core::RefPtr<GUIContext> gui = core::MakeRef<GUIContext>(core::DefaultAllocator());
    core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), gui);
    core::RefPtr<UIWidget> w = Widget(u8"button");
    root->AddChild(w.Get());
    StyleManager styles(CSSParser::Parse(SV(u8"button { opacity: 1; } @media (prefers-color-scheme: light) and (prefers-contrast: more) { button { opacity: 0.5; } }")));
    styles.SetMediaContext(root->GetMediaContext());
    styles.ApplyTree(*root.Get());
    CHECK(w->GetAlpha() == doctest::Approx(1.0f));
    gui->SetColorScheme(false);
    gui->SetContrastPreference(ContrastPreference::More);
    styles.SetMediaContext(root->GetMediaContext()); // the host passes it each frame: a change restyles
    styles.ApplyTree(*root.Get());
    CHECK(w->GetAlpha() == doctest::Approx(0.5f));
}

TEST_CASE("media: a resize restyles only what reads the viewport: a sheet's vw or vh, a size query that flips, an inline style's vw")
{
    const auto restyled = [](const char8_t* css, bool inlineVw)
    {
        core::RefPtr<GUIContext> gui = core::MakeRef<GUIContext>(core::DefaultAllocator());
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), gui);
        root->SetSize(core::Float2{800.0f, 600.0f});
        core::Array<core::RefPtr<UIWidget>> widgets;
        for (int i = 0; i < 4; ++i)
        {
            widgets.PushBack(Widget(u8"button"));
            root->AddChild(widgets.Back().Get());
        }
        if (inlineVw)
            widgets[2]->SetInlineStyle(SV(u8"width"), SV(u8"10vw"));
        StyleManager styles(CSSParser::Parse(core::StringView(css)));
        styles.SetMediaContext(root->GetMediaContext());
        styles.ApplyTree(*root.Get());
        root->SetSize(core::Float2{820.0f, 610.0f}); // a frame of a window's resize
        styles.SetMediaContext(root->GetMediaContext());
        styles.ApplyTree(*root.Get());
        return styles.LastRestyleCount();
    };
    CHECK(restyled(u8"button { opacity: 0.5; }", false) == 0u); // nothing reads the size
    CHECK(restyled(u8"button { opacity: 0.5; } @media (min-width: 1000px) { button { opacity: 1; } }", false) == 0u); // no flip
    CHECK(restyled(u8"button { opacity: 0.5; } @media (min-width: 810px) { button { opacity: 1; } }", false) >= 4u); // flips
    CHECK(restyled(u8"button { width: 50vw; }", false) >= 4u);
    CHECK(restyled(u8":root { --side: calc(100vh - 20px); } button { opacity: 0.5; }", false) >= 4u);
    CHECK(restyled(u8"button { opacity: 0.5; }", true) == 1u); // its own inline vw
}
