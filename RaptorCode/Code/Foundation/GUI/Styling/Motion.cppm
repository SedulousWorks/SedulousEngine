// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :motion partition
//
// What `transition` and `animation` declare (G3 of Specs/vg-and-gui-lab.md): their lists, the
// shorthands expanded into their longhands (transition-property, -duration, -timing-function,
// -delay; animation-name, -duration, -timing-function, -delay, -iteration-count, -direction,
// -fill-mode, -play-state) so each cascades on its own, and the specs composed back from the
// longhands, a shorter list repeating to the length of the property or name list, as CSS does.

module;
#include "Core/Prelude.h"

export module foundation.gui:motion;

import foundation.core;
import :css_values;
import :style_value;
import :easing;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    // === Declarations ===

    /// One entry of `transition`: a property (or `all`), a duration, an easing, a delay.
    struct TransitionSpec
    {
        core::String Property;
        f32 Duration = 0.0f;
        f32 Delay = 0.0f;
        Easing Timing = Easing::Ease();
    };

    /// `transition`: a comma list of `<property> <duration> [<easing>] [<delay>]` in any order
    /// past the property (the first time is the duration, the second the delay); `none` is empty.
    [[nodiscard]] inline Array<TransitionSpec> ParseTransitionList(core::StringView value)
    {
        Array<TransitionSpec> out;
        if (Trim(value) == core::StringView(u8"none"))
            return out;
        for (const core::StringView entry : SplitTopLevel(value, u8','))
        {
            TransitionSpec spec;
            spec.Property = core::String(u8"all");
            bool haveDuration = false, haveProperty = false;
            for (const core::StringView token : SplitTopLevel(entry, u8' '))
            {
                if (Optional<f32> time = ParseTime(token); time.HasValue())
                {
                    if (!haveDuration)
                    {
                        spec.Duration = time.Value();
                        haveDuration = true;
                    }
                    else
                    {
                        spec.Delay = time.Value();
                    }
                }
                else if (Optional<Easing> easing = ParseEasing(token); easing.HasValue())
                {
                    spec.Timing = easing.Value();
                }
                else if (!haveProperty)
                {
                    spec.Property = core::String(token);
                    haveProperty = true;
                }
            }
            out.PushBack(Move(spec));
        }
        return out;
    }

    enum class AnimationDirection : u8
    {
        Normal,
        Reverse,
        Alternate,
        AlternateReverse,
    };

    enum class AnimationFill : u8
    {
        None,
        Forwards,
        Backwards,
        Both,
    };

    /// One entry of `animation`.
    struct AnimationSpec
    {
        core::String Name;
        f32 Duration = 0.0f;
        f32 Delay = 0.0f;
        Easing Timing = Easing::Ease();
        f32 Iterations = 1.0f; ///< negative: infinite
        AnimationDirection Direction = AnimationDirection::Normal;
        AnimationFill Fill = AnimationFill::None;
        bool Paused = false; ///< animation-play-state: paused
    };

    /// `animation`: a comma list of `<name> <duration> [<easing>] [<delay>] [<iteration-count> |
    /// infinite] [<direction>] [<fill-mode>]`, keywords in any order; `none` is empty.
    [[nodiscard]] inline Array<AnimationSpec> ParseAnimationList(core::StringView value)
    {
        Array<AnimationSpec> out;
        if (Trim(value) == core::StringView(u8"none"))
            return out;
        for (const core::StringView entry : SplitTopLevel(value, u8','))
        {
            AnimationSpec spec;
            bool haveDuration = false;
            for (const core::StringView token : SplitTopLevel(entry, u8' '))
            {
                if (Optional<f32> time = ParseTime(token); time.HasValue())
                {
                    (haveDuration ? spec.Delay : spec.Duration) = time.Value();
                    haveDuration = true;
                }
                else if (token == core::StringView(u8"infinite"))
                    spec.Iterations = -1.0f;
                else if (Optional<f32> count = ParseLength(token); count.HasValue() && token.Size() > 0 &&
                                                                    (IsDigit(token[0]) || token[0] == u8'.'))
                    spec.Iterations = Max(0.0f, count.Value());
                else if (token == core::StringView(u8"normal"))
                    spec.Direction = AnimationDirection::Normal;
                else if (token == core::StringView(u8"reverse"))
                    spec.Direction = AnimationDirection::Reverse;
                else if (token == core::StringView(u8"alternate"))
                    spec.Direction = AnimationDirection::Alternate;
                else if (token == core::StringView(u8"alternate-reverse"))
                    spec.Direction = AnimationDirection::AlternateReverse;
                else if (token == core::StringView(u8"forwards"))
                    spec.Fill = AnimationFill::Forwards;
                else if (token == core::StringView(u8"backwards"))
                    spec.Fill = AnimationFill::Backwards;
                else if (token == core::StringView(u8"both"))
                    spec.Fill = AnimationFill::Both;
                else if (token == core::StringView(u8"paused"))
                    spec.Paused = true;
                else if (token == core::StringView(u8"running"))
                    spec.Paused = false;
                else if (Optional<Easing> easing = ParseEasing(token); easing.HasValue())
                    spec.Timing = easing.Value();
                else if (spec.Name.IsEmpty())
                    spec.Name = core::String(token);
            }
            if (!spec.Name.IsEmpty())
                out.PushBack(Move(spec));
        }
        return out;
    }

    // === The longhands ===

    namespace detail
    {
        inline void AppendListItem(core::String& list, core::StringView item)
        {
            if (!list.IsEmpty())
                list.Append(core::StringView(u8", "));
            list.Append(item);
        }

        [[nodiscard]] inline core::String TimeText(f32 seconds) { return Format(u8"{}s", seconds); }

        [[nodiscard]] inline core::String EasingText(const Easing& e)
        {
            switch (e.Kind)
            {
            case EasingKind::Linear:
                return core::String(u8"linear");
            case EasingKind::CubicBezier:
                return Format(u8"cubic-bezier({}, {}, {}, {})", e.X1, e.Y1, e.X2, e.Y2);
            case EasingKind::Steps:
                return Format(u8"steps({}, {})", e.Steps,
                              core::StringView(e.Position == StepPosition::JumpStart  ? u8"jump-start"
                                               : e.Position == StepPosition::JumpEnd  ? u8"jump-end"
                                               : e.Position == StepPosition::JumpNone ? u8"jump-none"
                                                                                      : u8"jump-both"));
            case EasingKind::Named:
                return NamedEasingText(e);
            }
            return core::String(u8"ease");
        }

        // The `index`-th item of a comma list, the list repeating when shorter (CSS's rule for the
        // longhands); empty when the list is.
        [[nodiscard]] inline core::StringView Cycled(const Array<core::StringView>& list, usize index)
        {
            return list.IsEmpty() ? core::StringView{} : list[index % list.Size()];
        }
    }

    /// `transition` as its four longhands (each a comma list, one item per entry).
    inline void ExpandTransition(core::StringView value, Array<core::String>& names, Array<core::String>& values)
    {
        core::String properties, durations, timings, delays;
        const Array<TransitionSpec> specs = ParseTransitionList(value);
        if (specs.IsEmpty())
            properties = core::String(u8"none");
        for (const TransitionSpec& spec : specs)
        {
            detail::AppendListItem(properties, spec.Property.AsView());
            detail::AppendListItem(durations, detail::TimeText(spec.Duration).AsView());
            detail::AppendListItem(timings, detail::EasingText(spec.Timing).AsView());
            detail::AppendListItem(delays, detail::TimeText(spec.Delay).AsView());
        }
        const char8_t* longhands[4] = {u8"transition-property", u8"transition-duration", u8"transition-timing-function",
                                       u8"transition-delay"};
        const core::String* texts[4] = {&properties, &durations, &timings, &delays};
        for (usize i = 0; i < 4; ++i)
        {
            names.PushBack(core::String(core::StringView(longhands[i])));
            values.PushBack(texts[i]->IsEmpty() ? core::String(u8"0s") : *texts[i]);
        }
    }

    /// `animation` as its eight longhands.
    inline void ExpandAnimation(core::StringView value, Array<core::String>& names, Array<core::String>& values)
    {
        core::String n, durations, timings, delays, counts, directions, fills, states;
        const Array<AnimationSpec> specs = ParseAnimationList(value);
        if (specs.IsEmpty())
            n = core::String(u8"none");
        for (const AnimationSpec& spec : specs)
        {
            detail::AppendListItem(n, spec.Name.AsView());
            detail::AppendListItem(durations, detail::TimeText(spec.Duration).AsView());
            detail::AppendListItem(timings, detail::EasingText(spec.Timing).AsView());
            detail::AppendListItem(delays, detail::TimeText(spec.Delay).AsView());
            detail::AppendListItem(counts, spec.Iterations < 0.0f ? core::StringView(u8"infinite")
                                                                  : Format(u8"{}", spec.Iterations).AsView());
            detail::AppendListItem(directions, core::StringView(spec.Direction == AnimationDirection::Reverse ? u8"reverse"
                                                                : spec.Direction == AnimationDirection::Alternate ? u8"alternate"
                                                                : spec.Direction == AnimationDirection::AlternateReverse
                                                                    ? u8"alternate-reverse"
                                                                    : u8"normal"));
            detail::AppendListItem(fills, core::StringView(spec.Fill == AnimationFill::Forwards    ? u8"forwards"
                                                           : spec.Fill == AnimationFill::Backwards ? u8"backwards"
                                                           : spec.Fill == AnimationFill::Both      ? u8"both"
                                                                                                   : u8"none"));
            detail::AppendListItem(states, core::StringView(spec.Paused ? u8"paused" : u8"running"));
        }
        const char8_t* longhands[8] = {u8"animation-name",       u8"animation-duration",        u8"animation-timing-function",
                                       u8"animation-delay",      u8"animation-iteration-count", u8"animation-direction",
                                       u8"animation-fill-mode",  u8"animation-play-state"};
        const core::String* texts[8] = {&n, &durations, &timings, &delays, &counts, &directions, &fills, &states};
        const char8_t* defaults[8] = {u8"none", u8"0s", u8"ease", u8"0s", u8"1", u8"normal", u8"none", u8"running"};
        for (usize i = 0; i < 8; ++i)
        {
            names.PushBack(core::String(core::StringView(longhands[i])));
            values.PushBack(texts[i]->IsEmpty() ? core::String(core::StringView(defaults[i])) : *texts[i]);
        }
    }

    /// The transitions the longhands declare: one per item of transition-property (none: no
    /// transitions), the other lists repeating to its length; an item that does not parse takes
    /// the longhand's initial value.
    [[nodiscard]] inline Array<TransitionSpec> ComposeTransitions(core::StringView properties, core::StringView durations,
                                                                  core::StringView timings, core::StringView delays)
    {
        Array<TransitionSpec> out;
        if (properties.IsEmpty() || Trim(properties) == core::StringView(u8"none"))
            return out;
        const Array<core::StringView> p = SplitTopLevel(properties, u8',');
        const Array<core::StringView> d = SplitTopLevel(durations, u8',');
        const Array<core::StringView> t = SplitTopLevel(timings, u8',');
        const Array<core::StringView> l = SplitTopLevel(delays, u8',');
        for (usize i = 0; i < p.Size(); ++i)
        {
            TransitionSpec spec;
            spec.Property = core::String(p[i]);
            spec.Duration = ParseTime(detail::Cycled(d, i)).ValueOr(0.0f);
            spec.Timing = ParseEasing(detail::Cycled(t, i)).ValueOr(Easing::Ease());
            spec.Delay = ParseTime(detail::Cycled(l, i)).ValueOr(0.0f);
            out.PushBack(Move(spec));
        }
        return out;
    }

    /// The animations the longhands declare: one per item of animation-name (none: none).
    [[nodiscard]] inline Array<AnimationSpec> ComposeAnimations(core::StringView names, core::StringView durations,
                                                                core::StringView timings, core::StringView delays,
                                                                core::StringView counts, core::StringView directions,
                                                                core::StringView fills, core::StringView states)
    {
        Array<AnimationSpec> out;
        if (names.IsEmpty() || Trim(names) == core::StringView(u8"none"))
            return out;
        const Array<core::StringView> n = SplitTopLevel(names, u8',');
        const Array<core::StringView> d = SplitTopLevel(durations, u8',');
        const Array<core::StringView> t = SplitTopLevel(timings, u8',');
        const Array<core::StringView> l = SplitTopLevel(delays, u8',');
        const Array<core::StringView> c = SplitTopLevel(counts, u8',');
        const Array<core::StringView> r = SplitTopLevel(directions, u8',');
        const Array<core::StringView> f = SplitTopLevel(fills, u8',');
        const Array<core::StringView> s = SplitTopLevel(states, u8',');
        for (usize i = 0; i < n.Size(); ++i)
        {
            if (n[i] == core::StringView(u8"none"))
                continue;
            AnimationSpec spec;
            spec.Name = core::String(n[i]);
            spec.Duration = ParseTime(detail::Cycled(d, i)).ValueOr(0.0f);
            spec.Timing = ParseEasing(detail::Cycled(t, i)).ValueOr(Easing::Ease());
            spec.Delay = ParseTime(detail::Cycled(l, i)).ValueOr(0.0f);
            const core::StringView count = detail::Cycled(c, i);
            spec.Iterations = count == core::StringView(u8"infinite") ? -1.0f : Max(0.0f, ParseLength(count).ValueOr(1.0f));
            const core::StringView dir = detail::Cycled(r, i);
            spec.Direction = dir == core::StringView(u8"reverse")             ? AnimationDirection::Reverse
                             : dir == core::StringView(u8"alternate")         ? AnimationDirection::Alternate
                             : dir == core::StringView(u8"alternate-reverse") ? AnimationDirection::AlternateReverse
                                                                              : AnimationDirection::Normal;
            const core::StringView fill = detail::Cycled(f, i);
            spec.Fill = fill == core::StringView(u8"forwards")    ? AnimationFill::Forwards
                        : fill == core::StringView(u8"backwards") ? AnimationFill::Backwards
                        : fill == core::StringView(u8"both")      ? AnimationFill::Both
                                                                  : AnimationFill::None;
            spec.Paused = detail::Cycled(s, i) == core::StringView(u8"paused");
            out.PushBack(Move(spec));
        }
        return out;
    }
}
