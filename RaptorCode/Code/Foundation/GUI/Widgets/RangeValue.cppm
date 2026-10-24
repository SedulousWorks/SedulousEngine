// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :range_value partition
//
// RangeValue: the value of a slider, a scroll bar, a progress bar or a number field (E6 of
// Specs/gui-lab-evolution.md), after Godot's Range: a value between a minimum and a maximum,
// snapped to a step, a page (a scroll bar's visible part, PageShown: the value goes no further
// than the maximum less it; a slider's and a number field's page-key step), optionally exponential (its
// place along the track by logarithm, for a frequency or a zoom) and optionally allowed past either
// end (a number field typed beyond its range). The controls derive from RangeWidget, which holds
// one and reflects its properties (so a progress bar carries a page it hides).

module;
#include "Core/Prelude.h"

export module foundation.gui:range_value;

import foundation.core; // Max, Min, Log, Exp, Abs

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    struct RangeValue
    {
        f64 Min = 0.0;
        f64 Max = 1.0;
        f64 Step = 0.0; ///< what the value snaps to, from Min; 0: continuous
        f64 Page = 0.0; ///< a scroll bar's visible part; a page key's step elsewhere (0: a tenth)
        f64 Value = 0.0;
        bool Exponential = false; ///< its place along the track by logarithm (with Min above 0)
        bool AllowGreater = false;
        bool AllowLesser = false;
        bool PageShown = false; ///< the page is a visible part (a scroll bar's), not just a key's step

        /// The largest value: the maximum, less the page when the page is shown past it.
        [[nodiscard]] f64 Upper() const noexcept { return core::Max(Min, PageShown ? Max - Page : Max); }

        /// `v` as the range takes it: snapped to the step, kept within the range unless allowed past it.
        [[nodiscard]] f64 Constrain(f64 v) const noexcept
        {
            if (Step > 0.0)
                v = Min + RoundHalfAway((v - Min) / Step) * Step;
            if (!AllowGreater)
                v = core::Min(v, Upper());
            if (!AllowLesser)
                v = core::Max(v, Min);
            return v;
        }

        /// Where the value lies along [Min, Upper], 0 to 1 (by logarithm when exponential).
        [[nodiscard]] f64 Ratio() const noexcept { return RatioOf(Value); }
        [[nodiscard]] f64 RatioOf(f64 v) const noexcept
        {
            const f64 lo = Min, hi = Upper();
            if (hi <= lo)
                return 0.0;
            if (UsesLog())
            {
                const f64 l = static_cast<f64>(core::Log(static_cast<f32>(lo)));
                const f64 h = static_cast<f64>(core::Log(static_cast<f32>(hi)));
                const f64 x = static_cast<f64>(core::Log(static_cast<f32>(core::Max(v, lo))));
                return Clamp01((x - l) / (h - l));
            }
            return Clamp01((v - lo) / (hi - lo));
        }
        /// The value at `ratio` along [Min, Upper] (not yet snapped: Constrain does).
        [[nodiscard]] f64 FromRatio(f64 ratio) const noexcept
        {
            const f64 lo = Min, hi = Upper();
            ratio = Clamp01(ratio);
            if (UsesLog())
            {
                const f64 l = static_cast<f64>(core::Log(static_cast<f32>(lo)));
                const f64 h = static_cast<f64>(core::Log(static_cast<f32>(hi)));
                return static_cast<f64>(core::Exp(static_cast<f32>(l + (h - l) * ratio)));
            }
            return lo + (hi - lo) * ratio;
        }

        /// An arrow key's step: the step, else a twentieth of the range.
        [[nodiscard]] f64 KeyStep() const noexcept { return Step > 0.0 ? Step : (Max - Min) / 20.0; }
        /// A page key's step: the page, else a tenth of the range (never less than a key step).
        [[nodiscard]] f64 PageStep() const noexcept { return core::Max(Page > 0.0 ? Page : (Max - Min) / 10.0, KeyStep()); }

        /// How many decimals the step shows (0.25: 2; 1: 0; continuous: 3).
        [[nodiscard]] i32 Decimals() const noexcept
        {
            if (Step <= 0.0)
                return 3;
            i32 decimals = 0;
            f64 s = Step;
            while (decimals < 8 && core::Abs(s - RoundHalfAway(s)) > 1e-9)
            {
                s *= 10.0;
                ++decimals;
            }
            return decimals;
        }

        [[nodiscard]] bool operator==(const RangeValue&) const noexcept = default;

    private:
        [[nodiscard]] bool UsesLog() const noexcept { return Exponential && Min > 0.0; }
        [[nodiscard]] static f64 Clamp01(f64 r) noexcept { return r < 0.0 ? 0.0 : (r > 1.0 ? 1.0 : r); }
        [[nodiscard]] static f64 RoundHalfAway(f64 x) noexcept
        {
            return static_cast<f64>(static_cast<i64>(x < 0.0 ? x - 0.5 : x + 0.5));
        }
    };
}
