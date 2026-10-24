// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - calc() (E13 of Specs/gui-lab-evolution-2.md): a length as a sum of units, + and - between
// terms, * and / by plain numbers, parentheses and nested calc(); resolved where its units are, and
// a transition between a calc() and a plain length blending each unit.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    core::f32 Term(const LengthValue& v, LengthUnit unit) { return v.Terms[static_cast<core::usize>(unit)]; }
}

TEST_CASE("calc: sums of units parse into their terms")
{
    const auto a = ParseLengthValue(SV(u8"calc(100% - 20px)"));
    REQUIRE(a.HasValue());
    CHECK(a.Value().Unit == LengthUnit::Calc);
    CHECK(Term(a.Value(), LengthUnit::Percent) == doctest::Approx(100.0f));
    CHECK(Term(a.Value(), LengthUnit::Px) == doctest::Approx(-20.0f));
    const auto b = ParseLengthValue(SV(u8"calc(2 * (10px + 5px) - calc(1em / 2))"));
    REQUIRE(b.HasValue());
    CHECK(Term(b.Value(), LengthUnit::Px) == doctest::Approx(30.0f));
    CHECK(Term(b.Value(), LengthUnit::Em) == doctest::Approx(-0.5f));
    CHECK(ParseLengthValue(SV(u8"calc(-2rem + 50vw)")).HasValue());
    // What CSS refuses: a length times a length, a number plus a length, dividing by a length or
    // by zero, unbalanced parentheses, an unknown unit.
    const char8_t* const bad[] = {u8"calc(10px * 2px)", u8"calc(10px + 2)", u8"calc(10px / 1px)", u8"calc(10px / 0)",
                                  u8"calc((10px + 2px)", u8"calc(10pt)", u8"calc()"};
    for (const char8_t* text : bad)
        CHECK_FALSE(ParseLengthValue(SV(text)).HasValue());
}

TEST_CASE("calc: it resolves each unit against its own base")
{
    LengthContext ctx;
    ctx.RootFontSize = 10.0f;
    ctx.ElementFontSize = 20.0f;
    ctx.ViewportWidth = 800.0f;
    ctx.ViewportHeight = 600.0f;
    const LengthValue v = ParseLengthValue(SV(u8"calc(50% + 1em + 2rem + 10vw - 5vh + 3px)")).Value();
    // 50% of 200, 20, 20, 80, -30, 3.
    CHECK(ResolveLengthValue(v, ctx, 200.0f) == doctest::Approx(100.0f + 20.0f + 20.0f + 80.0f - 30.0f + 3.0f));
    CHECK(v.PercentPart() == doctest::Approx(50.0f));
    CHECK(ResolveLengthValue(v, ctx, 0.0f) == doctest::Approx(93.0f)); // base 0: the percent drops out
}

TEST_CASE("calc: a transition between a calc() and a plain length blends each unit")
{
    const LengthValue from = ParseLengthValue(SV(u8"calc(100% - 40px)")).Value();
    const LengthValue to = ParseLengthValue(SV(u8"20px")).Value();
    LengthValue mid;
    REQUIRE(foundation::gui::detail::MixLength(from, to, 0.5f, mid));
    CHECK(mid.Unit == LengthUnit::Calc);
    CHECK(Term(mid, LengthUnit::Percent) == doctest::Approx(50.0f));
    CHECK(Term(mid, LengthUnit::Px) == doctest::Approx(-10.0f));
}
