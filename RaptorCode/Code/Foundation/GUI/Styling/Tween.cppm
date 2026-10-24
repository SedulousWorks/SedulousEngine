// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :tween partition
//
// Motion as an API (E14 of Specs/gui-lab-evolution-2.md): a tween moves one property of a node
// toward a value on its GUI's clock, eased by a CSS easing or a named curve. A property a sheet
// names composes over the cascade, as CSS's animation origin does: the tween writes its progress
// into the node's animated layer and the style pass interpolates there, through the typed values
// the sheets' transitions use, from the start given or the value underneath. Any other name is a
// reflected property, read and written through its accessors (numbers, colours and points move;
// what cannot switches halfway). A tween may wait, repeat and run back and forth; at its end it
// holds its value until stopped or replaced. It holds its node weakly (the action's weak target).
// A tween of a GUI's data value (K3: GUIContext::AnimateData) has no node: it moves a number in the
// data model, which whatever is bound to it follows (a score counting up), keeping the value's
// type (a whole number counts in whole numbers).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:tween;

import foundation.core;
import foundation.script; // IScriptDelegate: a script's callback at the end
import :action;
import :node;
import :ui_node;
import :css_values;
import :style_value;
import :style_properties;
import :style_sheet;   // ResolvedStyle::ParseLonghand
import :style_applier; // the reflected properties' lookup and parsing, as a sheet's
import :style_interpolation;
import :easing;
import :data_model; // a data value's tween (K3)

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// A mark no other tween has had (in the library, so every binary draws from one count).
    [[nodiscard]] u64 NextTweenOwner() noexcept;

    class Tween;
    /// Another tween of `tween`'s property on its node, running on its own or in a group, gives
    /// way to it (defined in TweenImpl.cpp, which sees the action manager).
    void ReplaceOthersOf(Tween& tween);

    class Tween : public Action
    {
        RTTI_OBJECT(Tween, Action)
    public:
        Tween(core::String property, core::String to, f32 seconds, Easing easing)
            : m_property(core::Move(property)), m_toText(core::Move(to)), m_seconds(core::Max(0.0f, seconds)), m_easing(easing)
        {
            m_owner = NextTweenOwner();
        }

        /// Moves the data value its property names in `model`, rather than a node's property (K3).
        void TargetData(RefPtr<DataModel> model) { m_data = core::Move(model); }
        [[nodiscard]] bool MovesData() const noexcept { return m_data.Get() != nullptr; }

        // === Shaping (before its first frame) ===
        /// Where it starts, as a value of its property (else the value showing).
        Tween& From(core::StringView text)
        {
            m_fromText = core::String(text);
            m_hasFrom = true;
            return *this;
        }
        /// How long it waits first, in seconds.
        Tween& Delay(f32 seconds)
        {
            m_delay = core::Max(0.0f, seconds);
            return *this;
        }
        /// How many times it runs (1 by default; a negative count runs until stopped).
        Tween& Repeat(i32 count)
        {
            m_iterations = count;
            return *this;
        }
        /// Every other run goes back from the end to the start.
        Tween& PingPong(bool on = true)
        {
            m_pingPong = on;
            return *this;
        }
        Tween& Ease(const Easing& easing)
        {
            m_easing = easing;
            return *this;
        }
        /// A data value's tween (K3) counts in whole numbers: each value it writes rounded to the
        /// nearest (a score; a script's numbers all arrive as fractions, so its type cannot say).
        Tween& Whole(bool on = true)
        {
            m_whole = on;
            return *this;
        }
        /// Moves as a damped spring toward its end rather than over a time (GPUI's and react-spring's
        /// springs): `stiffness` pulls, `damping` slows, `mass` resists; little damping overshoots and
        /// rings. Its duration, easing, repeats and ping-pong no longer apply; it ends once settled.
        Tween& Spring(f32 stiffness = 170.0f, f32 damping = 26.0f, f32 mass = 1.0f)
        {
            m_spring = true;
            m_stiffness = core::Max(0.0f, stiffness);
            m_damping = core::Max(0.0f, damping);
            m_mass = core::Max(1e-4f, mass);
            return *this;
        }
        [[nodiscard]] bool IsSpring() const noexcept { return m_spring; }
        /// Sends it toward another end from where it is now, its speed carried over: a drag that
        /// settles, a menu that follows the pointer, without a jolt.
        void Retarget(core::StringView to);
        /// Called once it reaches its end (not when stopped or replaced).
        Tween& OnFinished(core::Function<void()> callback)
        {
            m_onFinished = core::Move(callback);
            return *this;
        }

        // === The script surface (reflected in GUIReflectionImpl.cpp): each returns the tween, so a
        // script chains them as native code does.
        RefPtr<Tween> FromScript(core::StringView text) { return Self(From(text)); }
        RefPtr<Tween> DelayScript(f32 seconds) { return Self(Delay(seconds)); }
        RefPtr<Tween> RepeatScript(i32 count) { return Self(Repeat(count)); }
        RefPtr<Tween> PingPongScript(bool on) { return Self(PingPong(on)); }
        RefPtr<Tween> EaseScript(core::StringView easing) { return Self(Ease(ParseEasing(easing).ValueOr(Easing::Ease()))); }
        RefPtr<Tween> WholeScript(bool on) { return Self(Whole(on)); }
        RefPtr<Tween> SpringScript(f32 stiffness, f32 damping, f32 mass) { return Self(Spring(stiffness, damping, mass)); }
        RefPtr<Tween> OnFinishedScript(RefPtr<foundation::script::IScriptDelegate> handler)
        {
            if (handler)
                OnFinished([handler]() { (void)handler->Invoke(Span<core::Variant>{}); });
            return RefPtr<Tween>(this);
        }
        [[nodiscard]] bool IsFinished() { return IsDone(); }

        [[nodiscard]] core::StringView GetProperty() const noexcept { return m_property.AsView(); }
        /// Whether it composes over the cascade (a property a sheet names) rather than through a
        /// reflected property. Known once it has run a frame.
        [[nodiscard]] bool MovesStyle() const noexcept { return m_route == Route::Style; }

        /// Stops it and gives its property back to the sheet (a reflected property keeps the
        /// value it has).
        void Cancel()
        {
            if (m_data && m_data->TweenOwnerOf(m_property.AsView()) == m_owner)
                m_data->ClaimTween(m_property.AsView(), 0); // the value stays as it is
            if (m_route == Route::Style)
                if (UINode* node = core::Cast<UINode>(ResolveTarget()))
                    if (const MotionValue* motion = node->FindMotion(m_property.AsView()); motion != nullptr && motion->Owner == m_owner)
                        (void)node->RemoveMotion(m_property.AsView());
            m_done = true;
        }
        /// Another tween took its property: it stops where it is, leaving the value to the new one.
        void Replace() noexcept { m_done = true; }

        // === Action ===
        /// Starting (run, or reached in its group, or again for a group's next run) it takes its
        /// property from any other tween moving it, and reads its values afresh at its first frame.
        void Start() override
        {
            m_elapsed = 0.0f;
            m_overrun = 0.0f;
            m_done = false;
            m_route = Route::Unbound;
            m_springX = 0.0f;
            m_springV = 0.0f;
            if (m_data)
                m_data->ClaimTween(m_property.AsView(), m_owner); // the one moving it gives way
            else
                ReplaceOthersOf(*this);
        }
        void Stop() override { m_done = true; }
        void Update(core::Duration elapsed) override
        {
            if (m_done)
                return;
            Node* target = ResolveTarget();
            if (target == nullptr && !m_data)
            {
                m_done = true;
                return;
            }
            m_elapsed += elapsed.AsSecondsF();
            const f32 active = m_elapsed - m_delay;
            if (active < 0.0f)
                return; // waiting: the property shows what it did
            if (m_route == Route::Unbound && !(m_data ? BindData() : Bind(*target)))
            {
                m_done = true;
                return;
            }
            // Another tween took the data value: stop where it is.
            if (m_route == Route::Data && m_data->TweenOwnerOf(m_property.AsView()) != m_owner)
            {
                m_done = true;
                return;
            }
            // Superseded through the layer (another writer took the property): stop.
            if (m_route == Route::Style)
            {
                const MotionValue* motion = core::Cast<UINode>(target)->FindMotion(m_property.AsView());
                if (motion == nullptr || motion->Owner != m_owner)
                {
                    m_done = true;
                    return;
                }
            }
            if (m_spring)
            {
                StepSpring(core::Min(active, elapsed.AsSecondsF()));
                const bool settled = Abs(1.0f - m_springX) < 1e-3f && Abs(m_springV) < 1e-3f;
                if (settled)
                    m_springX = 1.0f;
                m_progress = core::Clamp(m_springX, 0.0f, 1.0f);
                Write(target, m_springX);
                if (settled)
                {
                    m_done = true;
                    if (m_onFinished)
                        m_onFinished();
                    FireDone();
                }
                return;
            }
            bool finished = false;
            f32 local = 1.0f;
            u32 run = 0;
            if (m_seconds <= 0.0f)
            {
                finished = true;
                run = m_iterations > 0 ? static_cast<u32>(m_iterations - 1) : 0;
                m_overrun = active;
            }
            else
            {
                const f32 runs = active / m_seconds;
                if (m_iterations >= 0 && runs >= static_cast<f32>(core::Max(m_iterations, 1)))
                {
                    finished = true;
                    run = static_cast<u32>(core::Max(m_iterations, 1) - 1);
                    m_overrun = active - m_seconds * static_cast<f32>(core::Max(m_iterations, 1));
                }
                else
                {
                    run = static_cast<u32>(Floor(runs));
                    local = runs - static_cast<f32>(run);
                }
            }
            if (m_pingPong && (run % 2u) == 1u)
                local = 1.0f - local;
            m_progress = local;
            Write(target, m_easing.Evaluate(local));
            if (finished)
            {
                m_done = true;
                if (m_onFinished)
                    m_onFinished();
                FireDone();
            }
        }
        [[nodiscard]] bool IsDone() override { return m_done; }
        [[nodiscard]] f32 GetCurrentProgress() override { return m_progress; }
        [[nodiscard]] core::Duration GetTotalTime() override
        {
            return core::Duration::FromSeconds(static_cast<f64>(m_delay + m_seconds * static_cast<f32>(core::Max(m_iterations, 1))));
        }
        [[nodiscard]] bool CanMoveTarget() const override { return !IsPaintOnlyStyleProperty(m_property.AsView()); }
        [[nodiscard]] core::Duration GetOverrun() const override { return core::Duration::FromSeconds(static_cast<f64>(m_overrun)); }

    private:
        enum class Route : u8
        {
            Unbound,
            Style,
            Reflected,
            Data, // a data model's value (K3)
        };

        [[nodiscard]] RefPtr<Tween> Self(Tween& self) { return RefPtr<Tween>(&self); }

        // The spring's progress toward 1 over `seconds`, in small steps (semi-implicit Euler holds
        // a stiff spring steady where one big step would fly off).
        void StepSpring(f32 seconds)
        {
            constexpr f32 kStep = 1.0f / 240.0f;
            while (seconds > 0.0f)
            {
                const f32 h = core::Min(seconds, kStep);
                const f32 force = -m_stiffness * (m_springX - 1.0f) - m_damping * m_springV;
                m_springV += force / m_mass * h;
                m_springX += m_springV * h;
                seconds -= h;
            }
        }
        // How far apart two values are, where that has a measure (a number, a length of one unit,
        // a colour, a point); 0 where it has none.
        [[nodiscard]] static f32 Distance(const StyleValue& a, const StyleValue& b)
        {
            if (a.Kind != b.Kind)
                return 0.0f;
            switch (a.Kind)
            {
            case StyleValueKind::Number:
                return Abs(b.Number - a.Number);
            case StyleValueKind::Length:
                return a.Length.Unit == b.Length.Unit ? Abs(b.Length.Value - a.Length.Value) : 0.0f;
            case StyleValueKind::ColorValue:
            {
                const Color d{b.ColorValue.r - a.ColorValue.r, b.ColorValue.g - a.ColorValue.g, b.ColorValue.b - a.ColorValue.b,
                              b.ColorValue.a - a.ColorValue.a};
                return Sqrt(d.r * d.r + d.g * d.g + d.b * d.b + d.a * d.a);
            }
            default:
                return 0.0f;
            }
        }
        [[nodiscard]] static f32 Distance(const Variant& a, const Variant& b)
        {
            if (const f32* x = a.TryGet<f32>())
                if (const f32* y = b.TryGet<f32>())
                    return Abs(*y - *x);
            if (const f64* x = a.TryGet<f64>())
                if (const f64* y = b.TryGet<f64>())
                    return static_cast<f32>(*y > *x ? *y - *x : *x - *y);
            if (const i32* x = a.TryGet<i32>())
                if (const i32* y = b.TryGet<i32>())
                    return Abs(static_cast<f32>(*y - *x));
            if (const core::Float2* x = a.TryGet<core::Float2>())
                if (const core::Float2* y = b.TryGet<core::Float2>())
                    return core::Length(core::Float2{y->x - x->x, y->y - x->y});
            return 0.0f;
        }
        // The speed carried to a new span: the same speed in the value's own units where both
        // spans have a measure, the same speed in progress where not.
        void CarrySpeed(f32 before, f32 after) noexcept
        {
            if (before > 0.0f && after > 0.0f)
                m_springV *= before / after;
            m_springX = 0.0f;
        }

        // The property a sheet does not name, by its CSS name or its reflected one.
        [[nodiscard]] static const PropertyInfo* FindReflected(const Node& node, core::StringView name)
        {
            for (const TypeInfo* type = node.GetType(); type != nullptr; type = type->base)
                for (usize i = 0; i < PropertyCount(*type); ++i)
                {
                    const PropertyInfo& property = PropertyAt(*type, i);
                    const Attribute* css = FindAttribute(property, u8"css");
                    const core::String* cssName = css != nullptr ? css->value.TryGet<core::String>() : nullptr;
                    if ((cssName != nullptr && cssName->AsView() == name) ||
                        core::StringView(reinterpret_cast<const char8_t*>(property.name)) == name)
                        return &property;
                }
            return nullptr;
        }

        // Its first frame: which way it writes, and its values parsed.
        bool Bind(Node& target)
        {
            // A sheet's property on a node a sheet styles; on any other node, its reflected one (a
            // plain node's opacity, x, y).
            if (UINode* node = core::Cast<UINode>(&target); node != nullptr && FindStyleProperty(m_property.AsView()) != nullptr)
            {
                MotionValue motion;
                motion.Property = m_property;
                motion.To = ResolvedStyle::ParseLonghand(m_property.AsView(), m_toText.AsView());
                if (motion.To.Kind == StyleValueKind::None)
                    return false;
                if (m_hasFrom)
                {
                    motion.From = ResolvedStyle::ParseLonghand(m_property.AsView(), m_fromText.AsView());
                    motion.HasFrom = motion.From.Kind != StyleValueKind::None;
                }
                else if (const MotionValue* before = node->FindMotion(m_property.AsView()); before != nullptr && before->HasShown)
                {
                    // From where the tween before it is now: its progress may have moved since the
                    // style pass last showed it (it ended this frame, before the pass).
                    motion.From = before->HasUnder ? InterpolateStyleValue(before->Under, before->To, before->Progress) : before->Shown;
                    motion.HasFrom = true;
                }
                motion.Owner = m_owner;
                (void)node->SetMotion(core::Move(motion));
                m_route = Route::Style;
                return true;
            }
            m_reflected = FindReflected(target, m_property.AsView());
            if (m_reflected == nullptr || m_reflected->set == nullptr)
                return false;
            const Instance instance = Instance::From(&target);
            m_to = detail::ParseForProperty(*m_reflected, m_toText.AsView(), LengthContext{});
            if (m_to.IsEmpty())
                return false;
            m_from = m_hasFrom ? detail::ParseForProperty(*m_reflected, m_fromText.AsView(), LengthContext{})
                               : core::GetProperty(*m_reflected, instance);
            if (m_from.IsEmpty())
                m_from = core::GetProperty(*m_reflected, instance);
            m_route = Route::Reflected;
            return true;
        }

        // Its first frame, for a data value: from the value now (or the start given), toward its
        // end, both numbers; the value's own type kept (a number when it has none yet).
        bool BindData()
        {
            const Optional<f64> to = ParseFloat(core::Trim(m_toText.AsView()));
            if (!to.HasValue())
                return false;
            const Variant now = m_data->Peek(m_property.AsView());
            f64 from = 0.0;
            (void)detail::NumberOf(now, from);
            if (m_hasFrom)
                from = ParseFloat(core::Trim(m_fromText.AsView())).ValueOr(from);
            f64 probe = 0.0;
            m_dataType = !now.IsEmpty() && detail::NumberOf(now, probe) && now.TryGet<bool>() == nullptr ? now.Type() : &TypeOf<f64>();
            m_from = Variant::From<f64>(from);
            m_to = Variant::From<f64>(to.Value());
            m_route = Route::Data;
            return true;
        }

        // The value at eased progress `t`.
        void Write(Node* target, f32 t)
        {
            if (m_route == Route::Data)
            {
                Variant value = Mix(m_from, m_to, t);
                if (m_whole)
                    if (const f64* n = value.TryGet<f64>())
                        value = Variant::From<f64>(*n < 0.0 ? -Floor(-*n + 0.5) : Floor(*n + 0.5));
                const Variant typed = m_dataType != nullptr ? ConvertVariant(value, *m_dataType) : value;
                (void)m_data->Set(m_property.AsView(), typed.IsEmpty() ? value : typed);
                return;
            }
            if (target == nullptr)
                return;
            if (m_route == Route::Style)
            {
                UINode& node = *core::Cast<UINode>(target);
                if (MotionValue* motion = node.FindMotion(m_property.AsView()))
                {
                    motion->Progress = t;
                    node.MarkStyleMotionDirty();
                }
                return;
            }
            (void)core::SetProperty(*m_reflected, Instance::From(target), Mix(m_from, m_to, t));
        }

        // Numbers, colours and points move; anything else switches halfway, as CSS's discrete values.
        [[nodiscard]] static Variant Mix(const Variant& a, const Variant& b, f32 t)
        {
            const auto lerp = [t](f32 x, f32 y) { return x + (y - x) * t; };
            if (const f32* x = a.TryGet<f32>())
                if (const f32* y = b.TryGet<f32>())
                    return Variant::From<f32>(lerp(*x, *y));
            if (const f64* x = a.TryGet<f64>())
                if (const f64* y = b.TryGet<f64>())
                    return Variant::From<f64>(*x + (*y - *x) * static_cast<f64>(t));
            if (const i32* x = a.TryGet<i32>())
                if (const i32* y = b.TryGet<i32>())
                    return Variant::From<i32>(static_cast<i32>(Round(lerp(static_cast<f32>(*x), static_cast<f32>(*y)))));
            if (const Color* x = a.TryGet<Color>())
                if (const Color* y = b.TryGet<Color>())
                    return Variant::From<Color>(Color{lerp(x->r, y->r), lerp(x->g, y->g), lerp(x->b, y->b), lerp(x->a, y->a)});
            if (const core::Float2* x = a.TryGet<core::Float2>())
                if (const core::Float2* y = b.TryGet<core::Float2>())
                    return Variant::From<core::Float2>(core::Float2{lerp(x->x, y->x), lerp(x->y, y->y)});
            return t < 0.5f ? a : b;
        }

        core::String m_property;
        core::String m_toText;
        core::String m_fromText;
        bool m_hasFrom = false;
        f32 m_seconds = 0.0f;
        f32 m_delay = 0.0f;
        i32 m_iterations = 1;
        bool m_pingPong = false;
        Easing m_easing;
        core::Function<void()> m_onFinished;

        bool m_spring = false;
        f32 m_stiffness = 170.0f;
        f32 m_damping = 26.0f;
        f32 m_mass = 1.0f;
        f32 m_springX = 0.0f; // progress, past 1 when it overshoots
        f32 m_springV = 0.0f; // its speed, in progress per second

        Route m_route = Route::Unbound;
        const PropertyInfo* m_reflected = nullptr;
        RefPtr<DataModel> m_data;               // the model whose value it moves (K3), or none
        const TypeInfo* m_dataType = nullptr;   // the value's type, kept as it moves
        bool m_whole = false;                   // a data value's: whole numbers only
        Variant m_from;
        Variant m_to;
        u64 m_owner = 0; // its mark in the layer
        f32 m_elapsed = 0.0f;
        f32 m_overrun = 0.0f;
        f32 m_progress = 0.0f;
        bool m_done = false;
    };

    // StaticType: REFLECT_MEMBERS(Tween) in Scene/GUIReflectionImpl.cpp (the script surface).

    inline void Tween::Retarget(core::StringView to)
    {
        m_toText = core::String(to);
        Node* target = ResolveTarget();
        if ((target == nullptr && !m_data) || m_route == Route::Unbound)
            return; // it reads its end at its first frame
        if (!m_spring)
            m_elapsed = m_delay; // a timed tween runs its time again, from where it is
        if (m_route == Route::Style)
        {
            UINode* node = core::Cast<UINode>(target);
            MotionValue* motion = node != nullptr ? node->FindMotion(m_property.AsView()) : nullptr;
            const StyleValue next = ResolvedStyle::ParseLonghand(m_property.AsView(), to);
            if (motion == nullptr || motion->Owner != m_owner || next.Kind == StyleValueKind::None)
                return;
            const StyleValue now = motion->HasUnder ? InterpolateStyleValue(motion->Under, motion->To, motion->Progress) : motion->Shown;
            const f32 before = motion->HasUnder ? Distance(motion->Under, motion->To) : 0.0f;
            CarrySpeed(before, Distance(now, next));
            motion->From = now;
            motion->HasFrom = true;
            motion->To = next;
            motion->Progress = 0.0f;
            node->MarkStyleMotionDirty();
            return;
        }
        if (m_route == Route::Data)
        {
            const Optional<f64> end = ParseFloat(core::Trim(to));
            if (!end.HasValue())
                return;
            // From the value showing (a whole number's rounding aside, where it is).
            const Variant now = Mix(m_from, m_to, m_spring ? m_springX : m_easing.Evaluate(m_progress));
            const Variant next = Variant::From<f64>(end.Value());
            CarrySpeed(Distance(m_from, m_to), Distance(now, next));
            m_from = now;
            m_to = next;
            return;
        }
        const Variant next = detail::ParseForProperty(*m_reflected, to, LengthContext{});
        if (next.IsEmpty())
            return;
        const Variant now = Mix(m_from, m_to, m_springX);
        CarrySpeed(Distance(m_from, m_to), Distance(now, next));
        m_from = now;
        m_to = next;
    }

    // === Groups (E14) ===

    /// A step of a group that waits.
    class TweenWait : public Action
    {
        RTTI_OBJECT(TweenWait, Action)
    public:
        explicit TweenWait(f32 seconds) noexcept : m_seconds(core::Max(0.0f, seconds)) {}
        void Start() override
        {
            m_elapsed = 0.0f;
            m_done = false;
        }
        void Stop() override { m_done = true; }
        void Update(core::Duration elapsed) override
        {
            if (m_done)
                return;
            m_elapsed += elapsed.AsSecondsF();
            m_done = m_elapsed >= m_seconds;
        }
        [[nodiscard]] bool IsDone() override { return m_done; }
        [[nodiscard]] f32 GetCurrentProgress() override { return m_seconds > 0.0f ? core::Min(1.0f, m_elapsed / m_seconds) : 1.0f; }
        [[nodiscard]] core::Duration GetTotalTime() override { return core::Duration::FromSeconds(static_cast<f64>(m_seconds)); }
        [[nodiscard]] bool CanMoveTarget() const override { return false; }
        [[nodiscard]] core::Duration GetOverrun() const override
        {
            return core::Duration::FromSeconds(static_cast<f64>(core::Max(0.0f, m_elapsed - m_seconds)));
        }

    private:
        f32 m_seconds;
        f32 m_elapsed = 0.0f;
        bool m_done = false;
    };
    RTTI_DEFINE_OBJECT(TweenWait, "rtti::gui")

    /// A step of a group that calls back, taking no time.
    class TweenCall : public Action
    {
        RTTI_OBJECT(TweenCall, Action)
    public:
        explicit TweenCall(core::Function<void()> callback) : m_callback(core::Move(callback)) {}
        void Start() override
        {
            m_done = false;
            m_overrun = 0.0f;
        }
        void Stop() override { m_done = true; }
        void Update(core::Duration elapsed) override
        {
            if (m_done)
                return;
            m_done = true;
            m_overrun = elapsed.AsSecondsF();
            if (m_callback)
                m_callback();
        }
        [[nodiscard]] bool IsDone() override { return m_done; }
        [[nodiscard]] f32 GetCurrentProgress() override { return m_done ? 1.0f : 0.0f; }
        [[nodiscard]] core::Duration GetTotalTime() override { return core::Duration{}; }
        [[nodiscard]] bool CanMoveTarget() const override { return false; }
        [[nodiscard]] core::Duration GetOverrun() const override { return core::Duration::FromSeconds(static_cast<f64>(m_overrun)); }

    private:
        core::Function<void()> m_callback;
        f32 m_overrun = 0.0f;
        bool m_done = false;
    };
    RTTI_DEFINE_OBJECT(TweenCall, "rtti::gui")

    /// Steps run as one (Zero's action groups, Godot's chained and parallel tweens, foundation.ui's
    /// storyboards): tweens of any nodes, waits, calls and other groups, one after another
    /// (TweenSequence) or together (TweenParallel), repeated as a whole, calling back at the end.
    /// Run it on a node (RunAction): the node's GUI keeps its time; each step keeps its own target.
    class TweenGroup : public Action
    {
        RTTI_OBJECT(TweenGroup, Action)
    public:
        TweenGroup& Add(RefPtr<Action> step)
        {
            if (step)
                m_steps.PushBack(core::Move(step));
            return *this;
        }
        TweenGroup& Wait(f32 seconds) { return Add(core::MakeRef<TweenWait>(MemoryAllocator(), seconds)); }
        TweenGroup& Call(core::Function<void()> callback)
        {
            return Add(core::MakeRef<TweenCall>(MemoryAllocator(), core::Move(callback)));
        }
        /// How many times it runs (1 by default; a negative count runs until stopped).
        TweenGroup& Repeat(i32 count)
        {
            m_iterations = count;
            return *this;
        }
        TweenGroup& OnFinished(core::Function<void()> callback)
        {
            m_onFinished = core::Move(callback);
            return *this;
        }
        [[nodiscard]] usize StepCount() const noexcept { return m_steps.Size(); }

        // === The script surface (reflected in GUIReflectionImpl.cpp), chaining as Add and the rest do.
        RefPtr<TweenGroup> AddScript(RefPtr<Tween> tween) { return Self(Add(core::Move(tween))); }
        RefPtr<TweenGroup> AddGroupScript(RefPtr<TweenGroup> group) { return Self(Add(core::Move(group))); }
        RefPtr<TweenGroup> WaitScript(f32 seconds) { return Self(Wait(seconds)); }
        RefPtr<TweenGroup> CallScript(RefPtr<foundation::script::IScriptDelegate> handler)
        {
            return Self(Call([handler]() { if (handler) (void)handler->Invoke(Span<core::Variant>{}); }));
        }
        RefPtr<TweenGroup> RepeatScript(i32 count) { return Self(Repeat(count)); }
        RefPtr<TweenGroup> OnFinishedScript(RefPtr<foundation::script::IScriptDelegate> handler)
        {
            if (handler)
                OnFinished([handler]() { (void)handler->Invoke(Span<core::Variant>{}); });
            return RefPtr<TweenGroup>(this);
        }
        [[nodiscard]] bool IsFinished() { return IsDone(); }

        /// Calls `f(step)` for each step running now (a replacement finds a tween inside a group).
        template <typename F>
        void ForEachRunning(F&& f)
        {
            for (const RefPtr<Action>& step : m_steps)
                if (IsRunning(*step))
                    f(*step);
        }

        void Start() override
        {
            m_run = 0;
            m_done = false;
            m_overrun = 0.0f;
            StartRun();
        }
        void Stop() override
        {
            for (const RefPtr<Action>& step : m_steps)
                step->Stop();
            m_done = true;
        }
        void Update(core::Duration elapsed) override
        {
            f32 seconds = elapsed.AsSecondsF();
            for (u32 guard = 0; !m_done && guard < 64; ++guard)
            {
                f32 over = 0.0f;
                if (!Advance(seconds, over))
                    return;
                ++m_run;
                if (m_iterations >= 0 && m_run >= static_cast<u32>(core::Max(m_iterations, 1)))
                {
                    m_done = true;
                    m_overrun = over;
                    if (m_onFinished)
                        m_onFinished();
                    FireDone();
                    return;
                }
                StartRun();
                if (over <= 0.0f)
                    return;
                seconds = over; // the next run takes what this one left
            }
        }
        [[nodiscard]] bool IsDone() override { return m_done; }
        [[nodiscard]] f32 GetCurrentProgress() override { return 0.0f; }
        [[nodiscard]] core::Duration GetTotalTime() override { return core::Duration{}; }
        [[nodiscard]] bool CanMoveTarget() const override
        {
            for (const RefPtr<Action>& step : m_steps)
                if (step->CanMoveTarget())
                    return true;
            return false;
        }
        [[nodiscard]] core::Duration GetOverrun() const override { return core::Duration::FromSeconds(static_cast<f64>(m_overrun)); }

    protected:
        [[nodiscard]] RefPtr<TweenGroup> Self(TweenGroup& self) { return RefPtr<TweenGroup>(&self); }
        virtual void StartRun() = 0;
        /// Runs the steps `seconds` on; true when this run has ended, with what it left over.
        virtual bool Advance(f32 seconds, f32& overrun) = 0;
        [[nodiscard]] virtual bool IsRunning(const Action& step) const = 0;

        Array<RefPtr<Action>> m_steps;

    private:
        i32 m_iterations = 1;
        u32 m_run = 0;
        f32 m_overrun = 0.0f;
        bool m_done = false;
        core::Function<void()> m_onFinished;
    };
    // StaticType: REFLECT_MEMBERS(TweenGroup) in Scene/GUIReflectionImpl.cpp (the script surface).

    /// Steps one after another: each starts as the last ends, with the time it left.
    class TweenSequence : public TweenGroup
    {
        RTTI_OBJECT(TweenSequence, TweenGroup)
    protected:
        void StartRun() override
        {
            m_index = 0;
            if (!m_steps.IsEmpty())
                m_steps[0]->Start();
        }
        bool Advance(f32 seconds, f32& overrun) override
        {
            while (m_index < m_steps.Size())
            {
                Action& step = *m_steps[m_index];
                step.Update(core::Duration::FromSeconds(static_cast<f64>(seconds)));
                if (!step.IsDone())
                    return false;
                seconds = step.GetOverrun().AsSecondsF();
                if (++m_index < m_steps.Size())
                    m_steps[m_index]->Start();
            }
            overrun = seconds;
            return true;
        }
        [[nodiscard]] bool IsRunning(const Action& step) const override
        {
            return m_index < m_steps.Size() && m_steps[m_index].Get() == &step;
        }

    private:
        usize m_index = 0;
    };
    // StaticType: REFLECT_MEMBERS(TweenSequence) in Scene/GUIReflectionImpl.cpp (the script surface).

    /// Steps together: the run ends with the last of them.
    class TweenParallel : public TweenGroup
    {
        RTTI_OBJECT(TweenParallel, TweenGroup)
    protected:
        void StartRun() override
        {
            for (const RefPtr<Action>& step : m_steps)
                step->Start();
        }
        bool Advance(f32 seconds, f32& overrun) override
        {
            bool all = true;
            f32 least = seconds;
            for (const RefPtr<Action>& step : m_steps)
            {
                if (step->IsDone())
                    continue;
                step->Update(core::Duration::FromSeconds(static_cast<f64>(seconds)));
                if (step->IsDone())
                    least = core::Min(least, step->GetOverrun().AsSecondsF());
                else
                    all = false;
            }
            overrun = least; // the time past the end of the step that ended last
            return all;
        }
        [[nodiscard]] bool IsRunning(const Action& step) const override { return !const_cast<Action&>(step).IsDone(); }
    };
    // StaticType: REFLECT_MEMBERS(TweenParallel) in Scene/GUIReflectionImpl.cpp (the script surface).
}
