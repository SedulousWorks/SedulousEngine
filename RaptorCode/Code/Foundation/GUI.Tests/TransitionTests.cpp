// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - motion (G3 of Specs/vg-and-gui-lab.md): the `transition` and `animation` lists parse; a
// changed property with a transition moves from what showed toward its new value on the GUI's
// clock, eased, for any property the sheet sets (opacity, lengths, colours, box shadows,
// transforms, gradients); without one, or unchanged, nothing moves; a transition retargets from
// where it is.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    core::Duration Sec(double s) { return core::Duration::FromSeconds(s); }

    // A widget in a GUI, styled by a sheet; `cls` toggles a class to change its style.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<UIWidget> widget = core::MakeRef<UIWidget>(core::DefaultAllocator());
        StyleManager styles;

        explicit Bed(const char8_t* css)
        {
            widget->SetTag(SV(u8"box"));
            {
                Node::StyleWriteScope defaults(*widget); // the widget's own size, which the sheet animates
                widget->SetSize(core::Float2{100.0f, 50.0f});
            }
            root->AddChild(widget.Get());
            styles.SetStyleSheet(CSSParser::Parse(SV(css)));
            styles.ApplyTree(*root);
        }
        void Toggle(const char8_t* cls)
        {
            widget->ToggleClass(SV(cls));
            styles.ApplyTree(*root);
        }
        void Advance(double seconds) { root->GetContext().Update(Sec(seconds)); }
    };
}

TEST_CASE("transition: the list parses properties, durations, easings and delays")
{
    const core::Array<TransitionSpec> one = ParseTransitionList(SV(u8"opacity 0.3s"));
    REQUIRE(one.Size() == 1u);
    CHECK(one[0].Property == SV(u8"opacity"));
    CHECK(one[0].Duration == doctest::Approx(0.3f));
    CHECK(one[0].Timing.Kind == EasingKind::CubicBezier); // ease, CSS's default

    const core::Array<TransitionSpec> many =
        ParseTransitionList(SV(u8"opacity 300ms linear 0.1s, transform 1s steps(4, jump-start), all 2s"));
    REQUIRE(many.Size() == 3u);
    CHECK(many[0].Duration == doctest::Approx(0.3f));
    CHECK(many[0].Delay == doctest::Approx(0.1f));
    CHECK(many[0].Timing.Kind == EasingKind::Linear);
    CHECK(many[1].Timing.Kind == EasingKind::Steps);
    CHECK(many[1].Timing.Steps == 4);
    CHECK(many[2].Property == SV(u8"all"));
    CHECK(ParseTransitionList(SV(u8"none")).IsEmpty());
}

TEST_CASE("transition: opacity moves on the GUI's clock, linearly when asked")
{
    Bed bed(u8"box { opacity: 1; transition: opacity 0.5s linear; } box.gone { opacity: 0; }");
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f));
    bed.Toggle(u8"gone");
    CHECK(bed.root->GetActionManager()->Count() == 1); // the widget's StyleAnimation
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f)); // starts where it was
    bed.Advance(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.5f)); // halfway
    bed.Advance(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.0f)); // arrived
    CHECK(bed.root->GetActionManager()->IsEmpty());          // finished
}

TEST_CASE("transition: a property set by no rule before moves from its initial value, and back to it when no rule sets it any more")
{
    // Only the class sets them: put on, opacity moves from 1 (its initial value) to 0, as CSS's
    // does; taken off, it goes back to 1 and the transform to none.
    Bed bed(u8"box { transition: opacity 0.5s linear, transform 0.5s linear; } box.entering { opacity: 0; transform: translate(0, 8px); }");
    bed.Toggle(u8"entering");
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f)); // from its initial value, not snapping
    bed.Advance(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.5f));
    bed.Advance(0.75);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.0f));
    bed.Toggle(u8"entering");
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.0f)); // from where it was
    bed.Advance(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.5f));
    bed.Advance(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f));
    CHECK(bed.root->GetActionManager()->IsEmpty());
}

TEST_CASE("transition: the easing shapes the move (ease-in starts slow)")
{
    Bed bed(u8"box { opacity: 0; transition: opacity 1s ease-in; } box.on { opacity: 1; }");
    bed.Toggle(u8"on");
    bed.Advance(0.5);
    const float expected = Easing::Bezier(0.42f, 0.0f, 1.0f, 1.0f).Evaluate(0.5f);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(expected));
    CHECK(bed.widget->GetAlpha() < 0.5f);
}

TEST_CASE("transition: without a transition, or with no change, nothing moves")
{
    Bed snap(u8"box { opacity: 1; } box.gone { opacity: 0; }");
    snap.Toggle(u8"gone");
    CHECK(snap.widget->GetAlpha() == doctest::Approx(0.0f));
    CHECK(snap.root->GetActionManager()->IsEmpty());

    Bed same(u8"box { opacity: 1; transition: opacity 0.5s; } box.same { opacity: 1; }");
    same.Toggle(u8"same");
    CHECK(same.root->GetActionManager()->IsEmpty());
}

TEST_CASE("transition: any property moves: a length, a colour, box shadows, a transform")
{
    Bed bed(u8"box { width: 100; background-color: #000000; box-shadow: 0 0 0 transparent; transform: rotate(0deg); "
            u8"transition: all 1s linear; } "
            u8"box.on { width: 200; background-color: #ff0000; box-shadow: 0 4px 8px #000000; transform: rotate(90deg); }");
    bed.Toggle(u8"on");
    bed.Advance(0.5);
    CHECK(bed.widget->GetSize().x == doctest::Approx(150.0f));
    CHECK(bed.widget->GetBox().BackgroundColor.r == doctest::Approx(0.5f));
    REQUIRE(bed.widget->GetBox().Shadows.Size() == 1u);
    CHECK(bed.widget->GetBox().Shadows[0].Offset.y == doctest::Approx(2.0f));
    CHECK(bed.widget->GetBox().Shadows[0].Blur == doctest::Approx(4.0f));
    REQUIRE(bed.widget->GetStyleTransforms().Size() == 1u);
    CHECK(bed.widget->GetStyleTransforms()[0].Angle == doctest::Approx(0.7853982f)); // 45deg
    bed.Advance(0.5);
    CHECK(bed.widget->GetSize().x == doctest::Approx(200.0f));
    CHECK(bed.widget->GetStyleTransforms()[0].Angle == doctest::Approx(1.5707963f));
}

TEST_CASE("transition: a delay holds the old value; a change mid-way retargets from where it is")
{
    Bed bed(u8"box { width: 100; transition: width 1s linear 0.5s; } box.wide { width: 300; }");
    bed.Toggle(u8"wide");
    bed.Advance(0.25);
    CHECK(bed.widget->GetSize().x == doctest::Approx(100.0f)); // still in the delay
    bed.Advance(0.75);                                          // 0.5 s into the move
    CHECK(bed.widget->GetSize().x == doctest::Approx(200.0f));
    bed.Toggle(u8"wide"); // back, from 200, after its own delay
    bed.Advance(0.5);
    CHECK(bed.widget->GetSize().x == doctest::Approx(200.0f));
    bed.Advance(0.5);
    CHECK(bed.widget->GetSize().x == doctest::Approx(150.0f)); // halfway from 200 to 100
}

TEST_CASE("transition: a gradient's stops and angle move; different shapes switch halfway")
{
    Bed bed(u8"box { background-image: linear-gradient(0deg, #000000, #000000); transition: background-image 1s linear; } "
            u8"box.on { background-image: linear-gradient(90deg, #ff0000, #0000ff); }");
    bed.Toggle(u8"on");
    bed.Advance(0.5);
    REQUIRE(bed.widget->GetBox().Layers.Size() == 1u);
    CHECK(bed.widget->GetBox().Layers[0].Gradient.Angle == doctest::Approx(0.7853982f));
    CHECK(bed.widget->GetBox().Layers[0].Gradient.Stops[0].color.r == doctest::Approx(0.5f));

    // A keyword cannot interpolate: it switches at the halfway point.
    StyleValue left, right;
    left.Kind = right.Kind = StyleValueKind::Keyword;
    left.Keyword = core::String(u8"left");
    right.Keyword = core::String(u8"right");
    CHECK(InterpolateStyleValue(left, right, 0.4f).Keyword == SV(u8"left"));
    CHECK(InterpolateStyleValue(left, right, 0.6f).Keyword == SV(u8"right"));
}

TEST_CASE("transition: a widget destroyed mid-move ends its animation, which never touches it again")
{
    Bed bed(u8"box { opacity: 1; transition: opacity 1s linear; } box.gone { opacity: 0; }");
    bed.Toggle(u8"gone");
    REQUIRE(bed.root->GetActionManager()->Count() == 1);
    bed.styles.Forget(bed.widget.Get());
    bed.root->RemoveChild(bed.widget.Get());
    bed.widget = core::RefPtr<UIWidget>{}; // destroyed: the animation held it weakly
    bed.Advance(0.25);
    CHECK(bed.root->GetActionManager()->IsEmpty());
}

TEST_CASE("transition: transform lists of different functions move through their matrices")
{
    core::Array<TransformFunction> translate = ParseTransforms(SV(u8"translate(100px, 0)")).Value();
    core::Array<TransformFunction> rotate = ParseTransforms(SV(u8"rotate(90deg)")).Value();
    StyleValue a, b;
    a.Kind = b.Kind = StyleValueKind::Transforms;
    a.Transforms = translate;
    b.Transforms = rotate;
    StyleInterpolationContext ctx;
    ctx.BoxSize = core::Float2{100.0f, 50.0f};
    // Halfway: half the translation, half the turn, as one matrix.
    const StyleValue half = InterpolateStyleValue(a, b, 0.5f, &ctx);
    REQUIRE(half.Transforms.Size() == 1u);
    CHECK(half.Transforms[0].Kind == TransformKind::Matrix);
    const Transform2D m = ComposeTransforms(half.Transforms, ctx.BoxSize);
    CHECK(m.tx == doctest::Approx(50.0f));
    CHECK(core::Atan2(m.b, m.a) == doctest::Approx(0.7853982f));
    // The ends are the lists themselves.
    const Transform2D atEnd = ComposeTransforms(InterpolateStyleValue(a, b, 1.0f, &ctx).Transforms, ctx.BoxSize);
    CHECK(atEnd.a == doctest::Approx(0.0f).epsilon(1e-5));
    CHECK(atEnd.b == doctest::Approx(1.0f));
    CHECK(atEnd.tx == doctest::Approx(0.0f).epsilon(1e-4));

    // Through matrices the rotation goes the short way round: 170deg to -170deg passes 180, not 0.
    a.Transforms = ParseTransforms(SV(u8"rotate(170deg) scale(1)")).Value();
    b.Transforms = ParseTransforms(SV(u8"rotate(-170deg)")).Value();
    const Transform2D turned = ComposeTransforms(InterpolateStyleValue(a, b, 0.5f, &ctx).Transforms, ctx.BoxSize);
    CHECK(turned.a == doctest::Approx(-1.0f)); // 180deg
    CHECK(turned.b == doctest::Approx(0.0f).epsilon(1e-4));

    // A skew and a scale survive the decomposition (a matrix's own ends are reproduced).
    a.Transforms = ParseTransforms(SV(u8"skewX(30deg) scale(2, 3)")).Value();
    b.Transforms = ParseTransforms(SV(u8"rotate(10deg)")).Value();
    const Transform2D start = ComposeTransforms(InterpolateStyleValue(a, b, 0.0f, &ctx).Transforms, ctx.BoxSize);
    const Transform2D original = ComposeTransforms(a.Transforms, ctx.BoxSize);
    CHECK(start.a == doctest::Approx(original.a));
    CHECK(start.b == doctest::Approx(original.b).epsilon(1e-4));
    CHECK(start.c == doctest::Approx(original.c));
    CHECK(start.d == doctest::Approx(original.d));
}

TEST_CASE("transition: lengths in different units move in pixels; a percentage against another unit switches")
{
    Bed bed(u8"box { width: 100px; transition: width 1s linear; } box.on { width: 10rem; }");
    bed.Toggle(u8"on");
    bed.Advance(0.5);
    CHECK(bed.widget->GetSize().x == doctest::Approx(130.0f)); // (100 + 160) / 2, rem at 16

    StyleValue px, pct;
    px.Kind = pct.Kind = StyleValueKind::Length;
    px.Length = LengthValue{100.0f, LengthUnit::Px};
    pct.Length = LengthValue{50.0f, LengthUnit::Percent};
    StyleInterpolationContext ctx;
    CHECK(InterpolateStyleValue(px, pct, 0.4f, &ctx).Length.Unit == LengthUnit::Px);
    CHECK(InterpolateStyleValue(px, pct, 0.6f, &ctx).Length.Unit == LengthUnit::Percent);
}

TEST_CASE("transition: the longhands cascade on their own, shorter lists repeating")
{
    // The shorthand sets all four; a later longhand overrides one; a one-item list repeats.
    Bed bed(u8"box { opacity: 1; width: 100; transition: opacity 4s ease; } "
            u8"box.fast { transition-property: opacity, width; transition-duration: 1s; transition-timing-function: linear; } "
            u8"box.fast.on { opacity: 0; width: 200; }");
    bed.Toggle(u8"fast");
    bed.Toggle(u8"on");
    bed.Advance(0.5);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.5f));
    CHECK(bed.widget->GetSize().x == doctest::Approx(150.0f));

    const core::Array<TransitionSpec> composed =
        ComposeTransitions(SV(u8"a, b, c"), SV(u8"1s, 2s"), SV(u8"linear"), SV(u8"0s"));
    REQUIRE(composed.Size() == 3u);
    CHECK(composed[2].Duration == doctest::Approx(1.0f)); // 1s, 2s, 1s
    CHECK(composed[1].Timing.Kind == EasingKind::Linear);
}

TEST_CASE("transition: animation-play-state pauses an animation's clock, and running resumes it")
{
    Bed bed(u8"@keyframes grow { from { width: 100; } to { width: 200; } } "
            u8"box { animation: grow 1s linear infinite; } box.held { animation-play-state: paused; }");
    bed.Advance(0.25);
    CHECK(bed.widget->GetSize().x == doctest::Approx(125.0f));
    bed.Toggle(u8"held");
    bed.Advance(0.5);
    CHECK(bed.widget->GetSize().x == doctest::Approx(125.0f)); // paused
    bed.Toggle(u8"held");
    bed.Advance(0.25);
    CHECK(bed.widget->GetSize().x == doctest::Approx(150.0f)); // resumed where it stood
}

TEST_CASE("style cache: destroyed widgets' entries do not pile up, nor pass to a widget at their address")
{
    core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(SV(u8"box { opacity: 0.3; } box.glow { animation: glow 1s linear; } "
                                                 u8"@keyframes glow { from { opacity: 0; } to { opacity: 1; } }")));
    // Churn: rows made, styled and destroyed, as a list rebuilding them does, nobody calling Forget.
    for (int i = 0; i < 2000; ++i)
    {
        core::RefPtr<UIWidget> row = core::MakeRef<UIWidget>(core::DefaultAllocator());
        row->SetTag(SV(u8"box"));
        root->AddChild(row.Get());
        styles.ApplyTree(*root);
        root->RemoveChild(row.Get());
    }
    styles.ApplyTree(*root);
    CHECK(styles.CachedWidgetCount() < 600u); // swept as they grew, not one per row ever made

    // A widget at a destroyed one's address: its own style, and its own animation from the start.
    const void* address = nullptr;
    {
        core::RefPtr<UIWidget> first = core::MakeRef<UIWidget>(core::DefaultAllocator());
        first->SetTag(SV(u8"box"));
        first->AddClass(SV(u8"glow"));
        root->AddChild(first.Get());
        styles.ApplyTree(*root);
        root->GetContext().Update(core::Duration::FromSeconds(2.0)); // its animation ran out
        address = first.Get();
        root->RemoveChild(first.Get());
    }
    bool reused = false;
    for (int attempt = 0; attempt < 64 && !reused; ++attempt)
    {
        core::RefPtr<UIWidget> next = core::MakeRef<UIWidget>(core::DefaultAllocator());
        if (next.Get() != address)
            continue;
        reused = true;
        next->SetTag(SV(u8"box"));
        next->AddClass(SV(u8"glow"));
        root->AddChild(next.Get());
        styles.ApplyTree(*root);
        root->GetContext().Update(core::Duration::FromSeconds(0.5));
        CHECK(next->GetAlpha() == doctest::Approx(0.5f)); // half way through its own run (not the 0.3 at rest)
        root->RemoveChild(next.Get());
    }
    if (!reused)
        MESSAGE("no widget landed at the freed address; the reuse half was not exercised");
}
