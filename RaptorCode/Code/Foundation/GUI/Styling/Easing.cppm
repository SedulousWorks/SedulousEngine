// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :easing partition
//
// CSS easing functions (G3 of Specs/vg-and-gui-lab.md): cubic-bezier(x1, y1, x2, y2), steps(n,
// position), linear, and the named curves (ease, ease-in, ease-out, ease-in-out, step-start,
// step-end). A cubic Bezier maps time to progress through its x(s) = t, solved by Newton's method
// with a bisection fallback, then y(s).

module;
#include "Core/Prelude.h"

export module foundation.gui:easing;

import foundation.core;
import :style_value; // SplitFunction, SplitTopLevel

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    enum class EasingKind : u8
    {
        Linear,
        CubicBezier,
        Steps,
        Named, ///< one of the named curves past CSS's (E14): a family eased in, out, or both
    };

    /// The named curves' families (easings.net's, as Godot's Tween and Zero's eases name them):
    /// powers of t, a sine, an exponential, a circle, and three that leave [0, 1] on the way
    /// (back overshoots, elastic rings, bounce bounces at the end).
    enum class EaseFamily : u8
    {
        Sine,
        Quad,
        Cubic,
        Quart,
        Quint,
        Expo,
        Circ,
        Back,
        Elastic,
        Bounce,
    };
    /// Which end of a family's curve is slow: the start (in), the end (out), or both (in-out).
    enum class EaseMode : u8
    {
        In,
        Out,
        InOut,
    };

    /// Where a steps() easing jumps: at the start of each interval, at its end, at both, or at
    /// neither (CSS's jump-start, jump-end, jump-both, jump-none; start and end alias the first two).
    enum class StepPosition : u8
    {
        JumpStart,
        JumpEnd,
        JumpNone,
        JumpBoth,
    };

    struct Easing
    {
        EasingKind Kind = EasingKind::Linear;
        f32 X1 = 0.0f, Y1 = 0.0f, X2 = 1.0f, Y2 = 1.0f; ///< CubicBezier's control points
        i32 Steps = 1;
        StepPosition Position = StepPosition::JumpEnd;
        EaseFamily Family = EaseFamily::Quad; ///< Named's
        EaseMode Mode = EaseMode::Out;

        [[nodiscard]] static constexpr Easing Linear() noexcept { return Easing{}; }
        [[nodiscard]] static constexpr Easing Bezier(f32 x1, f32 y1, f32 x2, f32 y2) noexcept
        {
            Easing e;
            e.Kind = EasingKind::CubicBezier;
            e.X1 = x1;
            e.Y1 = y1;
            e.X2 = x2;
            e.Y2 = y2;
            return e;
        }
        [[nodiscard]] static constexpr Easing Stepped(i32 steps, StepPosition position) noexcept
        {
            Easing e;
            e.Kind = EasingKind::Steps;
            e.Steps = steps;
            e.Position = position;
            return e;
        }
        [[nodiscard]] static constexpr Easing Named(EaseFamily family, EaseMode mode) noexcept
        {
            Easing e;
            e.Kind = EasingKind::Named;
            e.Family = family;
            e.Mode = mode;
            return e;
        }
        /// CSS's default easing.
        [[nodiscard]] static constexpr Easing Ease() noexcept { return Bezier(0.25f, 0.1f, 0.25f, 1.0f); }

        /// Progress at time `t` in [0, 1] (a Bezier's y may leave [0, 1]: overshoot is allowed).
        [[nodiscard]] f32 Evaluate(f32 t) const noexcept
        {
            t = Clamp(t, 0.0f, 1.0f);
            switch (Kind)
            {
            case EasingKind::Linear:
                return t;
            case EasingKind::CubicBezier:
                return BezierAt(SolveForX(t), Y1, Y2);
            case EasingKind::Steps:
                return StepAt(t);
            case EasingKind::Named:
                return NamedAt(t);
            }
            return t;
        }

    private:
        // Foundation's curves (Math/Easings), by family and mode.
        [[nodiscard]] f32 NamedAt(f32 t) const noexcept
        {
            static constexpr EasingFunction kCurves[][3] = {
                {&EaseInSin, &EaseOutSin, &EaseInOutSin},
                {&EaseInQuadratic, &EaseOutQuadratic, &EaseInOutQuadratic},
                {&EaseInCubic, &EaseOutCubic, &EaseInOutCubic},
                {&EaseInQuartic, &EaseOutQuartic, &EaseInOutQuartic},
                {&EaseInQuintic, &EaseOutQuintic, &EaseInOutQuintic},
                {&EaseInExponential, &EaseOutExponential, &EaseInOutExponential},
                {&EaseInCircular, &EaseOutCircular, &EaseInOutCircular},
                {&EaseInBack, &EaseOutBack, &EaseInOutBack},
                {&EaseInElastic, &EaseOutElastic, &EaseInOutElastic},
                {&EaseInBounce, &EaseOutBounce, &EaseInOutBounce},
            };
            return kCurves[static_cast<usize>(Family)][static_cast<usize>(Mode)](t);
        }

        // One coordinate of the curve from (0, 0) through p1, p2 to (1, 1) at parameter s.
        [[nodiscard]] static f32 BezierAt(f32 s, f32 p1, f32 p2) noexcept
        {
            const f32 u = 1.0f - s;
            return 3.0f * u * u * s * p1 + 3.0f * u * s * s * p2 + s * s * s;
        }
        [[nodiscard]] static f32 BezierSlope(f32 s, f32 p1, f32 p2) noexcept
        {
            const f32 u = 1.0f - s;
            return 3.0f * u * u * p1 + 6.0f * u * s * (p2 - p1) + 3.0f * s * s * (1.0f - p2);
        }
        // The parameter s whose x is `x` (x is monotonic in s for x1, x2 in [0, 1]).
        [[nodiscard]] f32 SolveForX(f32 x) const noexcept
        {
            f32 s = x;
            for (i32 i = 0; i < 8; ++i)
            {
                const f32 error = BezierAt(s, X1, X2) - x;
                if (Abs(error) < 1e-6f)
                    return s;
                const f32 slope = BezierSlope(s, X1, X2);
                if (Abs(slope) < 1e-6f)
                    break;
                s -= error / slope;
            }
            f32 lo = 0.0f, hi = 1.0f;
            s = x;
            for (i32 i = 0; i < 32; ++i)
            {
                const f32 at = BezierAt(s, X1, X2);
                if (Abs(at - x) < 1e-6f)
                    break;
                if (at < x)
                    lo = s;
                else
                    hi = s;
                s = (lo + hi) * 0.5f;
            }
            return s;
        }
        [[nodiscard]] f32 StepAt(f32 t) const noexcept
        {
            const i32 n = Max(Steps, 1);
            // CSS: the step index rounds down, starts a jump earlier for jump-start / jump-both,
            // and the output divides by the number of jumps.
            i32 step = static_cast<i32>(Floor(t * static_cast<f32>(n)));
            if (Position == StepPosition::JumpStart || Position == StepPosition::JumpBoth)
                ++step;
            if (t >= 1.0f && (Position == StepPosition::JumpEnd || Position == StepPosition::JumpNone))
                step = n; // the last interval's end
            i32 jumps = n;
            if (Position == StepPosition::JumpNone)
                jumps = n - 1;
            else if (Position == StepPosition::JumpBoth)
                jumps = n + 1;
            if (jumps <= 0)
                return t >= 1.0f ? 1.0f : 0.0f;
            return Clamp(static_cast<f32>(Min(step, jumps)) / static_cast<f32>(jumps), 0.0f, 1.0f);
        }
    };

    namespace detail
    {
        inline constexpr const char8_t* kEaseFamilyNames[] = {u8"sine", u8"quad", u8"cubic", u8"quart", u8"quint",
                                                              u8"expo", u8"circ", u8"back", u8"elastic", u8"bounce"};
        inline constexpr const char8_t* kEaseModePrefixes[] = {u8"ease-in-", u8"ease-out-", u8"ease-in-out-"}; // by EaseMode
    }

    /// A named curve: `ease-in-<family>`, `ease-out-<family>` or `ease-in-out-<family>`, the
    /// family one of sine, quad, cubic, quart, quint, expo, circ, back, elastic, bounce.
    [[nodiscard]] inline Optional<Easing> ParseNamedEasing(core::StringView v)
    {
        // In-out first: "ease-in-" is a prefix of it.
        constexpr EaseMode kOrder[] = {EaseMode::InOut, EaseMode::In, EaseMode::Out};
        for (const EaseMode mode : kOrder)
        {
            const core::StringView prefix(detail::kEaseModePrefixes[static_cast<usize>(mode)]);
            if (v.Size() <= prefix.Size() || v.SubStr(0, prefix.Size()) != prefix)
                continue;
            const core::StringView family = v.SubStr(prefix.Size(), v.Size() - prefix.Size());
            for (usize i = 0; i < sizeof(detail::kEaseFamilyNames) / sizeof(detail::kEaseFamilyNames[0]); ++i)
                if (family == core::StringView(detail::kEaseFamilyNames[i]))
                    return Easing::Named(static_cast<EaseFamily>(i), mode);
            return {};
        }
        return {};
    }
    /// A named curve's name, as ParseNamedEasing reads it.
    [[nodiscard]] inline core::String NamedEasingText(const Easing& e)
    {
        core::String text{core::StringView(detail::kEaseModePrefixes[static_cast<usize>(e.Mode)])};
        text.Append(core::StringView(detail::kEaseFamilyNames[static_cast<usize>(e.Family)]));
        return text;
    }

    /// A CSS <easing-function>: linear, ease, ease-in, ease-out, ease-in-out, step-start,
    /// step-end, cubic-bezier(x1, y1, x2, y2) (x1 and x2 in [0, 1]) or steps(n[, position]); or a
    /// named curve past CSS's (ParseNamedEasing), so sheets and code ease alike.
    [[nodiscard]] inline Optional<Easing> ParseEasing(core::StringView text)
    {
        const core::StringView v = Trim(text);
        if (Optional<Easing> named = ParseNamedEasing(v); named.HasValue())
            return named;
        if (v == core::StringView(u8"linear"))
            return Easing::Linear();
        if (v == core::StringView(u8"ease"))
            return Easing::Ease();
        if (v == core::StringView(u8"ease-in"))
            return Easing::Bezier(0.42f, 0.0f, 1.0f, 1.0f);
        if (v == core::StringView(u8"ease-out"))
            return Easing::Bezier(0.0f, 0.0f, 0.58f, 1.0f);
        if (v == core::StringView(u8"ease-in-out"))
            return Easing::Bezier(0.42f, 0.0f, 0.58f, 1.0f);
        if (v == core::StringView(u8"step-start"))
            return Easing::Stepped(1, StepPosition::JumpStart);
        if (v == core::StringView(u8"step-end"))
            return Easing::Stepped(1, StepPosition::JumpEnd);
        core::StringView name, arguments;
        if (!SplitFunction(v, name, arguments))
            return {};
        const Array<core::StringView> args = SplitTopLevel(arguments, u8',');
        if (name == core::StringView(u8"cubic-bezier"))
        {
            if (args.Size() != 4)
                return {};
            f32 p[4];
            for (usize i = 0; i < 4; ++i)
            {
                const Optional<f32> n = ParseLength(args[i]);
                if (!n.HasValue())
                    return {};
                p[i] = n.Value();
            }
            if (p[0] < 0.0f || p[0] > 1.0f || p[2] < 0.0f || p[2] > 1.0f)
                return {};
            return Easing::Bezier(p[0], p[1], p[2], p[3]);
        }
        if (name == core::StringView(u8"steps"))
        {
            if (args.IsEmpty() || args.Size() > 2)
                return {};
            const Optional<f32> n = ParseLength(args[0]);
            if (!n.HasValue() || n.Value() < 1.0f || n.Value() != Floor(n.Value()))
                return {};
            StepPosition position = StepPosition::JumpEnd;
            if (args.Size() == 2)
            {
                const core::StringView p = args[1];
                if (p == core::StringView(u8"jump-start") || p == core::StringView(u8"start"))
                    position = StepPosition::JumpStart;
                else if (p == core::StringView(u8"jump-end") || p == core::StringView(u8"end"))
                    position = StepPosition::JumpEnd;
                else if (p == core::StringView(u8"jump-none"))
                    position = StepPosition::JumpNone;
                else if (p == core::StringView(u8"jump-both"))
                    position = StepPosition::JumpBoth;
                else
                    return {};
            }
            if (position == StepPosition::JumpNone && n.Value() < 2.0f)
                return {};
            return Easing::Stepped(static_cast<i32>(n.Value()), position);
        }
        return {};
    }

    /// A CSS <time>: `300ms`, `0.3s`; seconds out.
    [[nodiscard]] inline Optional<f32> ParseTime(core::StringView text)
    {
        const core::StringView v = Trim(text);
        if (v.Size() > 2 && v.SubStr(v.Size() - 2, 2) == core::StringView(u8"ms"))
            if (Optional<f32> n = ParseLength(v.SubStr(0, v.Size() - 2)); n.HasValue())
                return n.Value() / 1000.0f;
        if (v.Size() > 1 && v[v.Size() - 1] == u8's')
            if (Optional<f32> n = ParseLength(v.SubStr(0, v.Size() - 1)); n.HasValue())
                return n.Value();
        return {};
    }
}
