// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - easing functions (G3 of Specs/vg-and-gui-lab.md): curves sampled against their formulas.
// A cubic Bezier is checked on its own parametric points (x(s), y(s)); steps() against CSS's
// definitions of each jump position; the names against their CSS curves.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // The curve from (0, 0) through (x1, y1), (x2, y2) to (1, 1) at parameter s.
    float BezierCoordinate(float s, float p1, float p2)
    {
        const float u = 1.0f - s;
        return 3.0f * u * u * s * p1 + 3.0f * u * s * s * p2 + s * s * s;
    }

    void CheckBezier(const Easing& e, float x1, float y1, float x2, float y2)
    {
        for (int i = 0; i <= 50; ++i)
        {
            const float s = static_cast<float>(i) / 50.0f;
            const float x = BezierCoordinate(s, x1, x2);
            const float y = BezierCoordinate(s, y1, y2);
            INFO("s ", s, " x ", x);
            CHECK(e.Evaluate(x) == doctest::Approx(y).epsilon(1e-4));
        }
    }
}

TEST_CASE("easing: cubic-bezier follows its curve, overshoot included")
{
    const core::Optional<Easing> custom = ParseEasing(SV(u8"cubic-bezier(0.1, 0.7, 1.0, 0.1)"));
    REQUIRE(custom.HasValue());
    CheckBezier(custom.Value(), 0.1f, 0.7f, 1.0f, 0.1f);

    // y may leave [0, 1] (a back-out bounce); x may not.
    const core::Optional<Easing> back = ParseEasing(SV(u8"cubic-bezier(0.34, 1.56, 0.64, 1)"));
    REQUIRE(back.HasValue());
    CheckBezier(back.Value(), 0.34f, 1.56f, 0.64f, 1.0f);
    CHECK(back.Value().Evaluate(0.6f) > 1.0f);
    CHECK_FALSE(ParseEasing(SV(u8"cubic-bezier(1.5, 0, 0.5, 1)")).HasValue());

    CHECK(custom.Value().Evaluate(0.0f) == doctest::Approx(0.0f));
    CHECK(custom.Value().Evaluate(1.0f) == doctest::Approx(1.0f));
}

TEST_CASE("easing: the named curves are CSS's")
{
    CheckBezier(ParseEasing(SV(u8"ease")).Value(), 0.25f, 0.1f, 0.25f, 1.0f);
    CheckBezier(ParseEasing(SV(u8"ease-in")).Value(), 0.42f, 0.0f, 1.0f, 1.0f);
    CheckBezier(ParseEasing(SV(u8"ease-out")).Value(), 0.0f, 0.0f, 0.58f, 1.0f);
    CheckBezier(ParseEasing(SV(u8"ease-in-out")).Value(), 0.42f, 0.0f, 0.58f, 1.0f);
    const Easing linear = ParseEasing(SV(u8"linear")).Value();
    for (int i = 0; i <= 10; ++i)
        CHECK(linear.Evaluate(i / 10.0f) == doctest::Approx(i / 10.0f));
}

TEST_CASE("easing: steps jump where their position says")
{
    // jump-end (the default): 0, 0.25, 0.5, 0.75 across the intervals, 1 at the end.
    const Easing end = ParseEasing(SV(u8"steps(4)")).Value();
    CHECK(end.Evaluate(0.0f) == doctest::Approx(0.0f));
    CHECK(end.Evaluate(0.24f) == doctest::Approx(0.0f));
    CHECK(end.Evaluate(0.25f) == doctest::Approx(0.25f));
    CHECK(end.Evaluate(0.99f) == doctest::Approx(0.75f));
    CHECK(end.Evaluate(1.0f) == doctest::Approx(1.0f));
    // jump-start: each interval starts on its jump.
    const Easing start = ParseEasing(SV(u8"steps(4, jump-start)")).Value();
    CHECK(start.Evaluate(0.0f) == doctest::Approx(0.25f));
    CHECK(start.Evaluate(0.74f) == doctest::Approx(0.75f));
    CHECK(start.Evaluate(0.75f) == doctest::Approx(1.0f));
    // jump-none: 5 steps hold 0, 0.25, 0.5, 0.75, 1.
    const Easing none = ParseEasing(SV(u8"steps(5, jump-none)")).Value();
    CHECK(none.Evaluate(0.0f) == doctest::Approx(0.0f));
    CHECK(none.Evaluate(0.2f) == doctest::Approx(0.25f));
    CHECK(none.Evaluate(0.99f) == doctest::Approx(1.0f));
    // jump-both: 3 steps hold 1/4, 2/4, 3/4, and 1 at the end.
    const Easing both = ParseEasing(SV(u8"steps(3, jump-both)")).Value();
    CHECK(both.Evaluate(0.0f) == doctest::Approx(0.25f));
    CHECK(both.Evaluate(0.5f) == doctest::Approx(0.5f));
    CHECK(both.Evaluate(0.99f) == doctest::Approx(0.75f));
    CHECK(both.Evaluate(1.0f) == doctest::Approx(1.0f));
    // step-start and step-end are steps(1, start / end).
    CHECK(ParseEasing(SV(u8"step-start")).Value().Evaluate(0.1f) == doctest::Approx(1.0f));
    CHECK(ParseEasing(SV(u8"step-end")).Value().Evaluate(0.9f) == doctest::Approx(0.0f));
    // Malformed.
    CHECK_FALSE(ParseEasing(SV(u8"steps(0)")).HasValue());
    CHECK_FALSE(ParseEasing(SV(u8"steps(1, jump-none)")).HasValue());
    CHECK_FALSE(ParseEasing(SV(u8"wobble")).HasValue());
}

TEST_CASE("easing: times parse in seconds and milliseconds")
{
    CHECK(ParseTime(SV(u8"0.25s")).Value() == doctest::Approx(0.25f));
    CHECK(ParseTime(SV(u8"250ms")).Value() == doctest::Approx(0.25f));
    CHECK_FALSE(ParseTime(SV(u8"250")).HasValue());
}

TEST_CASE("easing: the named curves past CSS's: ten families, eased in, out and in-out (E14)")
{
    const char8_t* families[] = {u8"sine", u8"quad", u8"cubic", u8"quart", u8"quint", u8"expo", u8"circ", u8"back", u8"elastic", u8"bounce"};
    const char8_t* modes[] = {u8"ease-in-", u8"ease-out-", u8"ease-in-out-"};
    for (const char8_t* family : families)
        for (const char8_t* mode : modes)
        {
            core::String name(mode);
            name.Append(core::StringView(family));
            INFO(reinterpret_cast<const char*>(name.Data()));
            const core::Optional<Easing> e = ParseEasing(name.AsView());
            REQUIRE(e.HasValue());
            CHECK(e.Value().Kind == EasingKind::Named);
            CHECK(e.Value().Evaluate(0.0f) == doctest::Approx(0.0f).epsilon(1e-3));
            CHECK(e.Value().Evaluate(1.0f) == doctest::Approx(1.0f).epsilon(1e-3));
        }
    const Easing outQuad = ParseEasing(SV(u8"ease-out-quad")).Value();
    CHECK(outQuad.Evaluate(0.5f) == doctest::Approx(0.75f));
    CHECK(ParseEasing(SV(u8"ease-in-quad")).Value().Evaluate(0.5f) == doctest::Approx(0.25f));
    const Easing inOutCubic = ParseEasing(SV(u8"ease-in-out-cubic")).Value();
    CHECK(inOutCubic.Evaluate(0.5f) == doctest::Approx(0.5f));
    CHECK(inOutCubic.Evaluate(0.25f) == doctest::Approx(1.0f - inOutCubic.Evaluate(0.75f))); // symmetric
    CHECK(ParseEasing(SV(u8"ease-in-back")).Value().Evaluate(0.2f) < 0.0f);  // pulls back first
    CHECK(ParseEasing(SV(u8"ease-out-back")).Value().Evaluate(0.8f) > 1.0f); // overshoots
    CHECK(ParseEasing(SV(u8"ease-out-bounce")).Value().Evaluate(0.5f) > 0.5f);
    // Not curves: an unknown family, a missing one, CSS's own names still beziers.
    CHECK_FALSE(ParseEasing(SV(u8"ease-out-wobble")).HasValue());
    CHECK_FALSE(ParseEasing(SV(u8"ease-out-")).HasValue());
    CHECK(ParseEasing(SV(u8"ease-out")).Value().Kind == EasingKind::CubicBezier);
    // A sheet's transition takes them too.
    const core::Array<TransitionSpec> list = ParseTransitionList(SV(u8"opacity 0.3s ease-out-elastic"));
    REQUIRE(list.Size() == 1u);
    CHECK(list[0].Timing.Kind == EasingKind::Named);
    CHECK(list[0].Timing.Family == EaseFamily::Elastic);
}

TEST_CASE("easing: a named curve's name reads back as the same curve")
{
    const Easing e = Easing::Named(EaseFamily::Back, EaseMode::InOut);
    CHECK(NamedEasingText(e) == SV(u8"ease-in-out-back"));
    const Easing again = ParseEasing(NamedEasingText(e).AsView()).Value();
    CHECK(again.Family == EaseFamily::Back);
    CHECK(again.Mode == EaseMode::InOut);
}
