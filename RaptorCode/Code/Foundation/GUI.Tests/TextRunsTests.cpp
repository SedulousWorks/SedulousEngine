// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Rich text runs and their markup: what each tag sets, how runs merge and nest, and that nothing
// malformed is ever dropped. Copied with the runs from foundation.ui (E4 of
// Specs/gui-lab-evolution.md).
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.gui;
import foundation.vg;

using namespace foundation::core;
using namespace foundation::gui;

TEST_CASE("text runs: plain text is one unstyled run")
{
    const TextDocument doc = ParseTextMarkup(u8"Your mark wears a gown");
    REQUIRE(doc.Runs.Size() == 1u);
    CHECK(doc.Runs[0].Text == StringView(u8"Your mark wears a gown"));
    CHECK_FALSE(doc.Runs[0].TextColor.HasValue());
    CHECK_FALSE(doc.Runs[0].Bold);
    CHECK(doc.Diagnostics.IsEmpty());
}

TEST_CASE("text runs: tags style their span and nest")
{
    const TextDocument doc =
        ParseTextMarkup(u8"Your mark wears [color=#d04060][b]a rose[/b] gown[/color] [size=24][i]now[/]");
    REQUIRE(doc.Runs.Size() == 5u);
    CHECK(doc.Runs[0].Text == StringView(u8"Your mark wears "));
    CHECK(doc.Runs[1].Text == StringView(u8"a rose"));
    CHECK(doc.Runs[1].Bold);
    REQUIRE(doc.Runs[1].TextColor.HasValue());
    CHECK(doc.Runs[1].TextColor.Value().r == doctest::Approx(0xd0 / 255.0f));
    CHECK(doc.Runs[2].Text == StringView(u8" gown"));
    CHECK_FALSE(doc.Runs[2].Bold);
    CHECK(doc.Runs[2].TextColor.HasValue()); // still inside the colour
    CHECK(doc.Runs[3].Text == StringView(u8" "));
    CHECK_FALSE(doc.Runs[3].TextColor.HasValue());
    CHECK(doc.Runs[4].Text == StringView(u8"now"));
    CHECK(doc.Runs[4].Italic);
    REQUIRE(doc.Runs[4].Size.HasValue());
    CHECK(doc.Runs[4].Size.Value() == doctest::Approx(24.0f));
    CHECK(doc.Diagnostics.IsEmpty());
    CHECK(doc.PlainText() == StringView(u8"Your mark wears a rose gown now"));
}

TEST_CASE("text runs: fonts, underline, links and icons")
{
    const TextDocument doc =
        ParseTextMarkup(u8"[font=Chewy][u]Hi[/u][/font] [icon=Icons/rose.png] [link=hint]what?[/link]");
    REQUIRE(doc.Runs.Size() == 5u);
    REQUIRE(doc.Runs[0].Family.HasValue());
    CHECK(doc.Runs[0].Family.Value() == StringView(u8"Chewy"));
    CHECK(doc.Runs[0].Underline);
    CHECK(doc.Runs[2].IsIcon());
    CHECK(doc.Runs[2].Icon == StringView(u8"Icons/rose.png"));
    CHECK(doc.Runs[2].Text.IsEmpty());
    CHECK(doc.Runs[4].Link == StringView(u8"hint"));
    CHECK(doc.Runs[4].Text == StringView(u8"what?"));
    CHECK(doc.PlainText() == StringView(u8"Hi \uFFFC what?"));
}

TEST_CASE("text runs: a doubled bracket is a literal one, and a lone ] is text")
{
    const TextDocument doc = ParseTextMarkup(u8"[[b]] is not bold ]");
    REQUIRE(doc.Runs.Size() == 1u);
    CHECK(doc.Runs[0].Text == StringView(u8"[b]] is not bold ]"));
    CHECK_FALSE(doc.Runs[0].Bold);
    CHECK(doc.Diagnostics.IsEmpty());
}

TEST_CASE("text runs: malformed tags stay as text and are reported")
{
    const TextDocument doc =
        ParseTextMarkup(u8"a [blink]b[/blink] [size=big]c [color=nope]d [/i] [b=1]e [ f");
    // Every character of the source is still there.
    CHECK(doc.PlainText() == StringView(u8"a [blink]b[/blink] [size=big]c [color=nope]d [/i] [b=1]e [ f"));
    for (const TextRun& run : doc.Runs)
    {
        CHECK_FALSE(run.Bold);
        CHECK_FALSE(run.Size.HasValue());
        CHECK_FALSE(run.TextColor.HasValue());
    }
    // blink, /blink, size, color, /i, b=1, and the unclosed bracket.
    CHECK(doc.Diagnostics.Size() == 7u);
    CHECK(doc.Diagnostics[0].Offset == 2u);
}

TEST_CASE("text runs: a close past inner tags closes them too, and colour names resolve")
{
    const TextMarkupColorResolver palette = [](StringView name) -> Optional<Color>
    {
        if (name == StringView(u8"gold"))
            return Color{1.0f, 0.8f, 0.2f, 1.0f};
        return {};
    };
    const TextDocument doc = ParseTextMarkup(u8"[color=$gold][b]x[/color]y [color=red]z", &palette);
    REQUIRE(doc.Runs.Size() == 3u);
    CHECK(doc.Runs[0].Bold);
    REQUIRE(doc.Runs[0].TextColor.HasValue());
    CHECK(doc.Runs[0].TextColor.Value().g == doctest::Approx(0.8f));
    CHECK_FALSE(doc.Runs[1].Bold); // closed with the colour
    CHECK_FALSE(doc.Runs[1].TextColor.HasValue());
    REQUIRE(doc.Runs[2].TextColor.HasValue()); // a named CSS colour without the resolver's help
    CHECK(doc.Runs[2].TextColor.Value().r == doctest::Approx(1.0f));
    CHECK(doc.Diagnostics.Size() == 1u); // [/color] closing the [b] inside it
}

TEST_CASE("text runs: outline, shadow and glow tags set their part of a run's effects")
{
    const TextDocument doc = ParseTextMarkup(
        u8"[outline=2 #102030]Hunt[shadow=1 2 3 red] the[/shadow][/outline] [glow=6]mask[/glow] [shadow=4 5]free[/]");
    REQUIRE(doc.Diagnostics.IsEmpty());
    REQUIRE(doc.Runs.Size() == 6u);
    // An outline alone, its colour as written.
    CHECK(doc.Runs[0].EffectParts == TextEffectOutline);
    CHECK(doc.Runs[0].Effects.outlineWidth == doctest::Approx(2.0f));
    CHECK(doc.Runs[0].Effects.outlineColor.g == doctest::Approx(0x20 / 255.0f));
    // A shadow inside it: both parts.
    CHECK(doc.Runs[1].EffectParts == (TextEffectOutline | TextEffectShadow));
    CHECK(doc.Runs[1].Effects.shadowOffset.x == doctest::Approx(1.0f));
    CHECK(doc.Runs[1].Effects.shadowOffset.y == doctest::Approx(2.0f));
    CHECK(doc.Runs[1].Effects.shadowBlur == doctest::Approx(3.0f));
    CHECK(doc.Runs[1].Effects.shadowColor.r == doctest::Approx(1.0f));
    CHECK(doc.Runs[2].EffectParts == 0); // the space after both closed
    // A glow takes white without a colour, a shadow half black and no blur.
    CHECK(doc.Runs[3].EffectParts == TextEffectGlow);
    CHECK(doc.Runs[3].Effects.glowRadius == doctest::Approx(6.0f));
    CHECK(doc.Runs[3].Effects.glowColor.r == doctest::Approx(1.0f));
    CHECK(doc.Runs[5].Effects.shadowBlur == doctest::Approx(0.0f));
    CHECK(doc.Runs[5].Effects.shadowColor.a == doctest::Approx(0.5f));
}

TEST_CASE("text runs: a run's effects take the control's for the parts it leaves out")
{
    const TextDocument doc = ParseTextMarkup(u8"[outline=0]plain[/] [glow=3 yellow]bright");
    REQUIRE(doc.Runs.Size() == 3u);
    foundation::vg::TextEffects control;
    control.outlineWidth = 1.0f;
    control.shadowColor = Color{0.0f, 0.0f, 0.0f, 1.0f};
    control.shadowOffset = Float2{2.0f, 2.0f};
    // [outline=0] turns the control's outline off and keeps its shadow.
    const foundation::vg::TextEffects plain = doc.Runs[0].EffectsOver(control);
    CHECK_FALSE(plain.HasOutline());
    CHECK(plain.HasShadow());
    // An unmarked run is the control's.
    CHECK(doc.Runs[1].EffectsOver(control) == control);
    const foundation::vg::TextEffects bright = doc.Runs[2].EffectsOver(control);
    CHECK(bright.HasOutline());
    CHECK(bright.HasGlow());
    CHECK(bright.glowRadius == doctest::Approx(3.0f));
}

TEST_CASE("text runs: malformed effect tags are reported and kept as text")
{
    // A width without a number, a shadow with one offset, a glow with two radii, a colour not last.
    const TextDocument doc = ParseTextMarkup(u8"[outline=red]a [shadow=2]b [glow=1 2]c [outline=#fff 1]d");
    CHECK(doc.PlainText() == StringView(u8"[outline=red]a [shadow=2]b [glow=1 2]c [outline=#fff 1]d"));
    CHECK(doc.Diagnostics.Size() == 4u);
    for (const TextRun& run : doc.Runs)
        CHECK(run.EffectParts == 0);
}
