// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - @keyframes tests: parsing keyframe blocks, and the animation runtime (an `animation`
// property runs its stops through the widget's StyleAnimation on the GUI's clock): any property,
// eased per segment, with delays, iteration counts, directions and fill modes.
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
    core::Duration Secs(double s) { return core::Duration::FromSeconds(s); }
}

TEST_CASE("keyframes: parse names, offsets (%, from/to), and stop declarations")
{
    StyleSheet sheet = CSSParser::Parse(core::StringView(
        u8"@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.25; } 100% { opacity: 1; } }"
        u8"@keyframes fade  { from { opacity: 1; } to { opacity: 0; } }"));

    CHECK(sheet.KeyframesCount() == 2);

    const Keyframes* pulse = sheet.FindKeyframes(core::StringView(u8"pulse"));
    REQUIRE(pulse != nullptr);
    REQUIRE(pulse->Stops.Size() == 3);
    CHECK(pulse->Stops[0].Offset == doctest::Approx(0.0f));
    CHECK(pulse->Stops[1].Offset == doctest::Approx(0.5f));
    CHECK(pulse->Stops[2].Offset == doctest::Approx(1.0f));
    CHECK(pulse->Stops[1].Properties.Size() == 1);

    const Keyframes* fade = sheet.FindKeyframes(core::StringView(u8"fade"));
    REQUIRE(fade != nullptr);
    REQUIRE(fade->Stops.Size() == 2);
    CHECK(fade->Stops[0].Offset == doctest::Approx(0.0f)); // from
    CHECK(fade->Stops[1].Offset == doctest::Approx(1.0f)); // to
}

TEST_CASE("keyframes: a comma offset list shares the block")
{
    StyleSheet sheet = CSSParser::Parse(
        core::StringView(u8"@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0; } }"));
    const Keyframes* blink = sheet.FindKeyframes(core::StringView(u8"blink"));
    REQUIRE(blink != nullptr);
    CHECK(blink->Stops.Size() == 3); // 0%, 100%, 50%
}

TEST_CASE("keyframes: the animation property drives opacity across the stops")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto w = Make<UIWidget>();
    w->AddClass(core::StringView(u8"anim"));
    root->AddChild(w.Get());

    StyleManager mgr;
    mgr.SetStyleSheet(CSSParser::Parse(core::StringView(
        u8"@keyframes fade { 0% { opacity: 1; } 50% { opacity: 0; } 100% { opacity: 1; } }"
        u8".anim { animation: fade 2s linear; }")));
    mgr.ApplyTree(*root.Get()); // starts the animation; it applies t=0 at once

    CHECK(w->GetAlpha() == doctest::Approx(1.0f)); // stop 0% -> 1

    root->GetContext().Update(Secs(0.5)); // t=0.25 -> between 1 and 0, halfway -> 0.5
    CHECK(w->GetAlpha() == doctest::Approx(0.5f));

    root->GetContext().Update(Secs(0.5)); // t=0.5 -> 0
    CHECK(w->GetAlpha() == doctest::Approx(0.0f));

    root->GetContext().Update(Secs(0.5)); // t=0.75 -> halfway back -> 0.5
    CHECK(w->GetAlpha() == doctest::Approx(0.5f));

    root->GetContext().Update(Secs(0.5)); // t=1.0 -> 1 (non-looping: ends here)
    CHECK(w->GetAlpha() == doctest::Approx(1.0f));
}

TEST_CASE("keyframes: infinite animations loop")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto w = Make<UIWidget>();
    w->AddClass(core::StringView(u8"loop"));
    root->AddChild(w.Get());

    StyleManager mgr;
    mgr.SetStyleSheet(CSSParser::Parse(core::StringView(
        u8"@keyframes fade { 0% { opacity: 1; } 50% { opacity: 0; } 100% { opacity: 1; } }"
        u8".loop { animation: fade 2s linear infinite; }")));
    mgr.ApplyTree(*root.Get());

    root->GetContext().Update(Secs(1.0)); // t=0.5 -> 0
    CHECK(w->GetAlpha() == doctest::Approx(0.0f));
    root->GetContext().Update(Secs(1.0)); // elapsed 2.0 -> wraps to t=0 -> 1 (still running)
    CHECK(w->GetAlpha() == doctest::Approx(1.0f));
    root->GetContext().Update(Secs(1.0)); // elapsed 3.0 -> t=0.5 -> 0 again (looped)
    CHECK(w->GetAlpha() == doctest::Approx(0.0f));
}

TEST_CASE("keyframes: the animation is spawned once, not re-spawned each ApplyTree")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto w = Make<UIWidget>();
    w->AddClass(core::StringView(u8"anim"));
    root->AddChild(w.Get());

    StyleManager mgr;
    mgr.SetStyleSheet(CSSParser::Parse(core::StringView(
        u8"@keyframes fade { 0% { opacity: 1; } 50% { opacity: 0; } 100% { opacity: 1; } }"
        u8".anim { animation: fade 2s linear; }")));

    mgr.ApplyTree(*root.Get());
    root->GetContext().Update(Secs(1.0));                       // t=0.5 -> 0
    mgr.ApplyTree(*root.Get());                    // re-apply must NOT restart the animation
    CHECK(w->GetAlpha() == doctest::Approx(0.0f)); // still mid-animation, not reset to t=0
}

TEST_CASE("keyframes: animates background-color across the stops")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto w = Make<UIWidget>();
    w->AddClass(core::StringView(u8"cycle"));
    root->AddChild(w.Get());

    StyleManager mgr;
    mgr.SetStyleSheet(CSSParser::Parse(core::StringView(
        u8"@keyframes cyc { 0% { background-color: #000000; } 100% { background-color: #ffffff; } }"
        u8".cycle { animation: cyc 2s linear forwards; }")));
    mgr.ApplyTree(*root.Get());

    // At t=0 the background is black; halfway it's mid-grey; at the end white (held: forwards).
    auto grey = [&](float expect)
    {
        CHECK(w->GetBox().BackgroundColor.r == doctest::Approx(expect));
    };
    grey(0.0f);
    root->GetContext().Update(Secs(1.0)); // t=0.5 -> mid grey
    grey(0.5f);
    root->GetContext().Update(Secs(1.0)); // t=1.0 -> white
    grey(1.0f);
}

namespace
{
    struct AnimBed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<UIWidget> w = Make<UIWidget>();
        StyleManager mgr;

        explicit AnimBed(const char8_t* css)
        {
            w->AddClass(core::StringView(u8"a"));
            {
                Node::StyleWriteScope defaults(*w); // the widget's own size, which the sheet animates
                w->SetSize(core::Float2{100.0f, 50.0f});
            }
            root->AddChild(w.Get());
            mgr.SetStyleSheet(CSSParser::Parse(core::StringView(css)));
            mgr.ApplyTree(*root.Get());
            root->UpdateLayout(); // sizes are the layout's, from the style
        }
    };
}

TEST_CASE("keyframes: any property animates: a transform, a box shadow, a length")
{
    AnimBed bed(u8"@keyframes spin { from { transform: rotate(0deg); box-shadow: 0 0 0 #000000; width: 100; } "
                u8"to { transform: rotate(180deg); box-shadow: 0 0 10px #000000; width: 200; } } "
                u8".a { animation: spin 2s linear; }");
    bed.root->GetContext().Update(Secs(1.0));
    REQUIRE(bed.w->GetStyleTransforms().Size() == 1u);
    CHECK(bed.w->GetStyleTransforms()[0].Angle == doctest::Approx(1.5707963f)); // 90deg
    REQUIRE(bed.w->GetBox().Shadows.Size() == 1u);
    CHECK(bed.w->GetBox().Shadows[0].Blur == doctest::Approx(5.0f));
    CHECK(bed.w->GetSize().x == doctest::Approx(150.0f));
}

TEST_CASE("keyframes: delay, iteration count, alternate direction and fill forwards")
{
    AnimBed bed(u8"@keyframes grow { from { width: 100; } to { width: 200; } } "
                u8".a { width: 50; animation: grow 1s linear 0.5s 2 alternate forwards; }");
    CHECK(bed.w->GetSize().x == doctest::Approx(50.0f)); // the delay, no backwards fill: the target
    bed.root->GetContext().Update(Secs(0.75));                         // 0.25 into the first, forwards
    CHECK(bed.w->GetSize().x == doctest::Approx(125.0f));
    bed.root->GetContext().Update(Secs(1.0));                          // 0.25 into the second, backwards
    CHECK(bed.w->GetSize().x == doctest::Approx(175.0f));
    bed.root->GetContext().Update(Secs(2.0));                          // ended: the last iteration's end (100)
    CHECK(bed.w->GetSize().x == doctest::Approx(100.0f));
    CHECK_FALSE(bed.root->GetActionManager()->IsEmpty()); // forwards keeps showing it
}

TEST_CASE("keyframes: a stop's timing function eases its segment; a missing end takes the target")
{
    AnimBed bed(u8"@keyframes half { 0% { opacity: 0; animation-timing-function: steps(2); } 50% { opacity: 1; } } "
                u8".a { opacity: 0.2; animation: half 2s linear; }");
    bed.root->GetContext().Update(Secs(0.4)); // 0.2 of the animation, 0.4 of the first segment: steps(2) holds 0
    CHECK(bed.w->GetAlpha() == doctest::Approx(0.0f));
    bed.root->GetContext().Update(Secs(0.2)); // 0.3, 0.6 of the segment: the second step, 0.5
    CHECK(bed.w->GetAlpha() == doctest::Approx(0.5f));
    bed.root->GetContext().Update(Secs(1.0)); // 0.8: between 50% (1) and the implicit 100% (the target 0.2), linear
    CHECK(bed.w->GetAlpha() == doctest::Approx(1.0f + (0.2f - 1.0f) * 0.6f));
}

TEST_CASE("keyframes: removing the animation stops it and the target shows")
{
    AnimBed bed(u8"@keyframes pulse { from { opacity: 0; } to { opacity: 1; } } "
                u8".a { animation: pulse 2s linear infinite; }");
    bed.root->GetContext().Update(Secs(0.5));
    CHECK(bed.w->GetAlpha() == doctest::Approx(0.25f));
    bed.w->RemoveClass(core::StringView(u8"a"));
    bed.mgr.ApplyTree(*bed.root.Get());
    CHECK(bed.w->GetAlpha() == doctest::Approx(1.0f)); // no animation: the node's own 1
    bed.root->GetContext().Update(Secs(0.5));
    CHECK(bed.w->GetAlpha() == doctest::Approx(1.0f));
}
