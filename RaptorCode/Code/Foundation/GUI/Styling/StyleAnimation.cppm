// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :style_animation partition
//
// Motion (G3 of Specs/vg-and-gui-lab.md): CSS transitions and @keyframes animations over any
// property a sheet sets. A widget whose style moves gets one StyleAnimation, an action on its
// SceneRoot's clock (so a GUI's time is its own), holding the style the sheet wants (the target)
// and a track per moving property: a transition from the value showing when the property changed
// toward its new one, or a keyframe animation's track through its stops, each eased (cubic-bezier,
// steps, the named curves) and interpolated through the typed values. Each tick it applies the
// target with the tracks' values over it. It holds its widget weakly (the element table), so a
// destroyed widget ends it. A transition that ends tells its widget `transitionend`, an animation
// that runs its last iteration `animationend` (K0), and a widget leaving goes once nothing it waits
// for moves it.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:style_animation;

import foundation.core;
import foundation.fonts;
import :node;
import :event; // MotionEndEvent
import :ui_node;
import :element_types; // Element<T>
import :action;
import :css_values;
import :style_value;
import :style_properties;
import :style_rule;
import :style_sheet;
import :style_interpolation;
import :style_applier;
import :easing;
import :motion; // TransitionSpec, AnimationSpec and their lists
import :resource_provider;

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    /// Whether a property's values move smoothly in a transition (`all` covers these): those the
    /// property table parses into numbers, lengths, colours, shadows, transforms, origins, layers or filters.
    [[nodiscard]] inline bool IsTransitionable(core::StringView property)
    {
        const StylePropertySpec* spec = FindStyleProperty(property);
        if (spec == nullptr)
            return false;
        switch (spec->Grammar)
        {
        case StyleGrammar::Number:
        case StyleGrammar::Length:
        case StyleGrammar::Size: // lengths move; auto and the content sizes switch
        case StyleGrammar::Color:
        case StyleGrammar::Shadows:
        case StyleGrammar::Transforms:
        case StyleGrammar::Origin:
        case StyleGrammar::Layers:
        case StyleGrammar::Filters:
        case StyleGrammar::TextOutline:
        case StyleGrammar::TextGlow:
            return true;
        case StyleGrammar::Keyword:
        case StyleGrammar::Text:
            return false;
        }
        return false;
    }

    // === Tracks ===

    struct AnimationKey
    {
        f32 Offset = 0.0f;
        StyleValue Value;
        Easing Timing; ///< the segment from this key to the next
    };

    /// One moving property: a transition (two keys) or a keyframe animation's track.
    struct AnimationTrack
    {
        core::String Property;
        core::String Animation; ///< the @keyframes name; empty for a transition
        Array<AnimationKey> Keys;
        f32 Duration = 0.0f;
        f32 Delay = 0.0f;
        f32 Iterations = 1.0f; ///< negative: infinite
        AnimationDirection Direction = AnimationDirection::Normal;
        AnimationFill Fill = AnimationFill::None;
        bool Paused = false; ///< animation-play-state: its clock stands still
        f32 Elapsed = 0.0f;

        [[nodiscard]] bool Ended() const noexcept
        {
            return Iterations >= 0.0f && Elapsed >= Delay + Duration * Iterations;
        }

        /// The value now, or false when the track shows nothing (before its delay without a
        /// backwards fill, after its end without a forwards one).
        [[nodiscard]] bool ValueNow(StyleValue& out, const StyleInterpolationContext* ctx = nullptr) const
        {
            if (Keys.IsEmpty())
                return false;
            const f32 active = Elapsed - Delay;
            f32 iterationProgress = 0.0f;
            f32 iteration = 0.0f;
            if (active < 0.0f)
            {
                if (Fill != AnimationFill::Backwards && Fill != AnimationFill::Both)
                    return false;
            }
            else if (Ended() || Duration <= 0.0f)
            {
                if (Fill != AnimationFill::Forwards && Fill != AnimationFill::Both)
                    return false;
                // The end of the last iteration (a whole count ends at its full progress).
                const f32 total = Iterations < 0.0f ? 1.0f : Iterations;
                iteration = Max(0.0f, Ceil(total) - 1.0f);
                iterationProgress = total - iteration;
                if (total == 0.0f)
                {
                    iteration = 0.0f;
                    iterationProgress = 0.0f;
                }
            }
            else
            {
                const f32 cycles = active / Duration;
                iteration = Floor(cycles);
                iterationProgress = cycles - iteration;
            }
            // Direction: odd iterations of an alternating animation run backwards.
            const bool odd = static_cast<i64>(iteration) % 2 != 0;
            const bool reversed = Direction == AnimationDirection::Reverse ||
                                  (Direction == AnimationDirection::Alternate && odd) ||
                                  (Direction == AnimationDirection::AlternateReverse && !odd);
            const f32 p = reversed ? 1.0f - iterationProgress : iterationProgress;
            // The segment the progress falls in, eased by its first key's timing.
            if (p <= Keys[0].Offset)
            {
                out = Keys[0].Value;
                return true;
            }
            for (usize i = 0; i + 1 < Keys.Size(); ++i)
            {
                const AnimationKey& a = Keys[i];
                const AnimationKey& b = Keys[i + 1];
                if (p <= b.Offset)
                {
                    const f32 span = b.Offset - a.Offset;
                    const f32 local = span > 0.0f ? (p - a.Offset) / span : 1.0f;
                    out = InterpolateStyleValue(a.Value, b.Value, a.Timing.Evaluate(local), ctx);
                    return true;
                }
            }
            out = Keys[Keys.Size() - 1].Value;
            return true;
        }
    };

    /// What applying a style needs besides the style.
    struct StyleApplyContext
    {
        IResourceProvider* Resources = nullptr;
        fonts::IFontService* FontService = nullptr;
        LengthContext Lengths{};
    };

    /// The node's animated layer over `style` (E14): each value a tween moves, from its start or
    /// the value underneath (the cascade's and its transitions', else the property's initial
    /// value) toward its end, as CSS's animation origin outranks the rest. Each value shown is
    /// kept, for a tween that replaces it to start there.
    inline void OverlayMotion(UINode& node, ResolvedStyle& style, const StyleInterpolationContext* ctx)
    {
        for (MotionValue& motion : node.MotionValues())
        {
            const core::StringView property = motion.Property.AsView();
            const StyleValue* under = style.Value(property);
            StyleValue initial;
            if (under == nullptr)
                if (const StylePropertySpec* spec = FindStyleProperty(property); spec != nullptr && spec->Initial != nullptr)
                {
                    initial = ResolvedStyle::ParseLonghand(property, core::StringView(spec->Initial));
                    if (initial.Kind != StyleValueKind::None)
                        under = &initial;
                }
            const StyleValue* from = motion.HasFrom ? &motion.From : under;
            // Nothing to move from (no start, nothing underneath): it shows its end.
            StyleValue value = from != nullptr ? InterpolateStyleValue(*from, motion.To, motion.Progress, ctx) : motion.To;
            // Kept before the override, which writes over the value `from` may point at.
            motion.HasUnder = from != nullptr;
            if (from != nullptr)
                motion.Under = *from;
            style.Override(property, value);
            motion.Shown = core::Move(value);
            motion.HasShown = true;
        }
    }

    // === The action ===

    class StyleAnimation : public Action
    {
        RTTI_OBJECT(StyleAnimation, Action)
    public:
        explicit StyleAnimation(UINode& node) : m_node(node) {}

        /// The style the sheet wants now, and what applying it needs.
        void SetTargetStyle(ResolvedStyle target, const StyleApplyContext& context)
        {
            m_targetStyle = Move(target);
            m_context = context;
        }
        [[nodiscard]] const ResolvedStyle& TargetStyle() const noexcept { return m_targetStyle; }

        /// It moves its node only through a property that is not paint alone (a colour or an
        /// opacity changes how the node looks where it is; a transform, a size or a shadow may
        /// change where its drawing reaches).
        [[nodiscard]] bool CanMoveTarget() const override
        {
            for (const AnimationTrack& track : m_tracks)
                if (!IsPaintOnlyStyleProperty(track.Property.AsView()))
                    return true;
            return false;
        }

        /// The value a track shows for `property` now, or false when none moves it (a transition
        /// retargets from here; the target style is already the new one).
        [[nodiscard]] bool TrackValue(core::StringView property, StyleValue& out) const
        {
            const StyleInterpolationContext ctx = InterpolationContext();
            for (usize i = m_tracks.Size(); i-- > 0;)
                if (m_tracks[i].Property.AsView() == property && m_tracks[i].ValueNow(out, &ctx))
                    return true;
            return false;
        }

        /// A transition of `property` from `from` to `to` (replacing one already running on it).
        void StartTransition(core::StringView property, const StyleValue& from, const StyleValue& to,
                             const TransitionSpec& spec)
        {
            RemoveTracks(property, core::StringView{});
            AnimationTrack track;
            track.Property = core::String(property);
            track.Duration = spec.Duration;
            track.Delay = spec.Delay;
            track.Fill = AnimationFill::Backwards; // the old value shows through the delay
            track.Keys.PushBack(AnimationKey{0.0f, from, spec.Timing});
            track.Keys.PushBack(AnimationKey{1.0f, to, Easing::Linear()});
            m_tracks.PushBack(Move(track));
        }

        /// A keyframe animation: one track per property its stops set, each stop's declarations
        /// expanded and parsed; a property missing from the first or last stop takes the target's
        /// value there (CSS's implicit keyframes). A stop's animation-timing-function eases the
        /// segment it starts, the animation's timing the others.
        void StartKeyframes(const AnimationSpec& spec, const Keyframes& keyframes)
        {
            StopKeyframes(spec.Name.AsView());
            ForgetEnded(spec.Name.AsView());
            Array<AnimationTrack> tracks;
            const auto trackFor = [&](core::StringView property) -> AnimationTrack&
            {
                for (AnimationTrack& t : tracks)
                    if (t.Property.AsView() == property)
                        return t;
                AnimationTrack t;
                t.Property = core::String(property);
                t.Animation = spec.Name;
                t.Duration = spec.Duration;
                t.Delay = spec.Delay;
                t.Iterations = spec.Iterations;
                t.Direction = spec.Direction;
                t.Fill = spec.Fill;
                t.Paused = spec.Paused;
                tracks.PushBack(Move(t));
                return tracks[tracks.Size() - 1];
            };
            for (const KeyframeStop& stop : keyframes.Stops)
            {
                Easing timing = spec.Timing;
                for (const StyleProperty& declared : stop.Properties)
                    if (declared.Name.AsView() == core::StringView(u8"animation-timing-function"))
                        if (Optional<Easing> e = ParseEasing(declared.Value.AsView()); e.HasValue())
                            timing = e.Value();
                for (const StyleProperty& declared : stop.Properties)
                {
                    if (declared.Name.AsView() == core::StringView(u8"animation-timing-function"))
                        continue;
                    Array<StyleLonghand> longhands;
                    if (!ExpandStyleShorthand(declared.Name.AsView(), declared.Value.AsView(), longhands))
                        continue;
                    for (const StyleLonghand& longhand : longhands)
                    {
                        const StyleValue value = ResolvedStyle::ParseLonghand(longhand.Name.AsView(), longhand.Text.AsView());
                        if (value.Kind == StyleValueKind::None)
                            continue;
                        AnimationTrack& track = trackFor(longhand.Name.AsView());
                        track.Keys.PushBack(AnimationKey{stop.Offset, value, timing});
                    }
                }
            }
            for (AnimationTrack& track : tracks)
            {
                SortKeys(track.Keys);
                const StyleValue* underlying = m_targetStyle.Value(track.Property.AsView());
                if (track.Keys[0].Offset > 0.0f && underlying != nullptr)
                    track.Keys.Insert(0, AnimationKey{0.0f, *underlying, spec.Timing});
                if (track.Keys[track.Keys.Size() - 1].Offset < 1.0f && underlying != nullptr)
                    track.Keys.PushBack(AnimationKey{1.0f, *underlying, spec.Timing});
                m_tracks.PushBack(Move(track));
            }
            m_animations.PushBack(spec.Name);
        }

        void StopKeyframes(core::StringView name)
        {
            RemoveTracks(core::StringView{}, name);
            for (usize i = 0; i < m_animations.Size(); ++i)
            {
                if (m_animations[i].AsView() == name)
                {
                    m_animations.RemoveAt(i);
                    break;
                }
            }
        }
        /// Pauses or resumes a keyframe animation (animation-play-state).
        void SetPaused(core::StringView name, bool paused)
        {
            for (AnimationTrack& t : m_tracks)
                if (t.Animation.AsView() == name)
                    t.Paused = paused;
        }

        [[nodiscard]] bool RunsKeyframes(core::StringView name) const
        {
            for (const core::String& n : m_animations)
                if (n.AsView() == name)
                    return true;
            return false;
        }
        [[nodiscard]] const Array<core::String>& KeyframeAnimations() const noexcept { return m_animations; }
        [[nodiscard]] usize TrackCount() const noexcept { return m_tracks.Size(); }
        /// Whether something it runs will end and has not (a leaving node waits for it): an
        /// infinite animation or a paused one is not waited for.
        [[nodiscard]] bool WaitsForEnd() const noexcept
        {
            for (const AnimationTrack& t : m_tracks)
                if (!t.Paused && t.Iterations >= 0.0f && !t.Ended())
                    return true;
            return false;
        }

        /// Applies the target with every track's value now over it.
        void ApplyNow()
        {
            UINode* node = m_node.Get();
            if (node == nullptr)
            {
                m_done = true;
                return;
            }
            ResolvedStyle effective = m_targetStyle;
            const StyleInterpolationContext ctx = InterpolationContext();
            // A track in its delay or past its end shows the target: the sheet's value, or the node's
            // own when the sheet sets none (the applier returns it there).
            for (const AnimationTrack& track : m_tracks)
            {
                StyleValue value;
                if (track.ValueNow(value, &ctx))
                    effective.Override(track.Property.AsView(), value);
            }
            OverlayMotion(*node, effective, &ctx); // tweens over the sheet's motion
            m_resets.Clear();
            ApplyStyle(*node, effective, m_context.Resources, m_context.FontService, m_context.Lengths);
        }

        // === Action ===
        void Start() override { ApplyNow(); }
        void Stop() override { m_done = true; }
        void Update(core::Duration elapsed) override
        {
            if (m_done)
                return;
            const f32 seconds = elapsed.AsSecondsF();
            for (AnimationTrack& track : m_tracks)
                if (!track.Paused)
                    track.Elapsed += seconds;
            ApplyNow();
            // The animations whose every track has now ended (told once; a forwards fill keeps its
            // tracks, so this is asked before the others go).
            Array<MotionEnd> ends;
            for (const core::String& name : m_animations)
            {
                bool any = false;
                bool ended = true;
                f32 ran = 0.0f;
                for (const AnimationTrack& t : m_tracks)
                    if (t.Animation.AsView() == name.AsView())
                    {
                        any = true;
                        ended = ended && t.Ended();
                        ran = t.Duration * t.Iterations;
                    }
                if (any && ended && !HasEnded(name.AsView()))
                {
                    m_ended.PushBack(name);
                    ends.PushBack(MotionEnd{EventType::AnimationEnd, name, ran});
                }
            }
            // Ended tracks that hold nothing go (a forwards fill keeps its track, showing its end).
            for (usize i = 0; i < m_tracks.Size();)
            {
                const AnimationTrack& t = m_tracks[i];
                const bool holds = t.Fill == AnimationFill::Forwards || t.Fill == AnimationFill::Both;
                if (t.Ended() && (!holds || t.Animation.IsEmpty()))
                {
                    if (t.Animation.IsEmpty())
                        ends.PushBack(MotionEnd{EventType::TransitionEnd, t.Property, t.Duration});
                    m_resets.PushBack(t.Property);
                    m_tracks.RemoveAt(i);
                }
                else
                {
                    ++i;
                }
            }
            if (!m_resets.IsEmpty())
                ApplyNow(); // what the ended tracks moved returns to the target, or its initial value
            UINode* node = m_node.Get();
            if (node == nullptr)
                return;
            // Told after the tick is done: a listener may restyle, retarget or remove the node.
            const RefPtr<Node> held(node);
            for (const MotionEnd& end : ends)
                node->SendEvent(MotionEndEvent(end.Type, node, end.Name.AsView(), end.Elapsed));
            if (node->WatchesMotion() && !WaitsForEnd())
                node->MotionSettled();
        }
        [[nodiscard]] bool IsDone() override { return m_done || m_tracks.IsEmpty(); }
        [[nodiscard]] f32 GetCurrentProgress() override { return 0.0f; }
        [[nodiscard]] core::Duration GetTotalTime() override { return core::Duration{}; }

    private:
        struct MotionEnd
        {
            EventType Type = EventType::TransitionEnd;
            core::String Name;
            f32 Elapsed = 0.0f;
        };
        [[nodiscard]] bool HasEnded(core::StringView animation) const
        {
            for (const core::String& name : m_ended)
                if (name.AsView() == animation)
                    return true;
            return false;
        }
        void ForgetEnded(core::StringView animation)
        {
            for (usize i = 0; i < m_ended.Size(); ++i)
                if (m_ended[i].AsView() == animation)
                {
                    m_ended.RemoveAt(i);
                    return;
                }
        }

        [[nodiscard]] StyleInterpolationContext InterpolationContext() const
        {
            StyleInterpolationContext ctx;
            ctx.Lengths = m_context.Lengths;
            if (UINode* node = m_node.Get())
                ctx.BoxSize = node->GetSize();
            return ctx;
        }

        static void SortKeys(Array<AnimationKey>& keys)
        {
            for (usize a = 1; a < keys.Size(); ++a)
            {
                AnimationKey key = keys[a];
                usize b = a;
                while (b > 0 && keys[b - 1].Offset > key.Offset)
                {
                    keys[b] = keys[b - 1];
                    --b;
                }
                keys[b] = Move(key);
            }
        }

        // Removes the tracks of `property` (any, when empty) belonging to `animation` (transitions
        // when empty, unless `property` is empty too).
        void RemoveTracks(core::StringView property, core::StringView animation)
        {
            for (usize i = 0; i < m_tracks.Size();)
            {
                const AnimationTrack& t = m_tracks[i];
                const bool match = property.IsEmpty() ? t.Animation.AsView() == animation
                                                      : (t.Property.AsView() == property && t.Animation.IsEmpty());
                if (match)
                {
                    m_resets.PushBack(t.Property);
                    m_tracks.RemoveAt(i);
                }
                else
                {
                    ++i;
                }
            }
        }

        Element<UINode> m_node;
        ResolvedStyle m_targetStyle;
        StyleApplyContext m_context;
        Array<AnimationTrack> m_tracks;
        Array<core::String> m_animations;
        Array<core::String> m_resets; // properties whose tracks just went, to return on the next apply
        Array<core::String> m_ended;  // the animations that told their end (not again until restarted)
        bool m_done = false;
    };

    RTTI_DEFINE_OBJECT(StyleAnimation, "rtti::gui")
}
