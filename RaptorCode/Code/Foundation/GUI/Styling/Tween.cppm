// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :tween partition, what is left of it after slice S12: the script surface of Tween and
// TweenGroup (reflected in Scene/GUIReflectionImpl.cpp, S19). The rest is
// Code/Foundation/Sedulous.GUI/src/Styling/Tween.bf (Tween, TweenWait, TweenCall, TweenGroup,
// TweenSequence, TweenParallel; Node's and GUIContext's tweens and the tweens' count in
// Styling/TweenImpl.bf).

export namespace foundation::gui
{
    class Tween : public Action
    {
    public:
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

    private:
        [[nodiscard]] RefPtr<Tween> Self(Tween& self) { return RefPtr<Tween>(&self); }
    };

    // StaticType: REFLECT_MEMBERS(Tween) in Scene/GUIReflectionImpl.cpp (the script surface).

    class TweenGroup : public Action
    {
    public:
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

    protected:
        [[nodiscard]] RefPtr<TweenGroup> Self(TweenGroup& self) { return RefPtr<TweenGroup>(&self); }
    };
    // StaticType: REFLECT_MEMBERS(TweenGroup) in Scene/GUIReflectionImpl.cpp (the script surface).
    // StaticType: REFLECT_MEMBERS(TweenSequence) in Scene/GUIReflectionImpl.cpp (the script surface).
    // StaticType: REFLECT_MEMBERS(TweenParallel) in Scene/GUIReflectionImpl.cpp (the script surface).
}
