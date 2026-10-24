// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :actions partition
//
// The action a widget times itself with: TickAction, a function called each frame on its
// target's clock. What moves properties is the tweens' (Styling/Tween.cppm, E14), which took
// the place of eepp's Move, Fade, Scale, Delay, Runnable and Sequence actions.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:actions;

import foundation.core; // Duration, Function, Move
import :action;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    // Calls a function with each frame's elapsed time on its target's clock until the function
    // returns false (or the action is stopped): a widget's own timing with nothing to animate, a
    // caret's blink.
    class TickAction : public Action
    {
        RTTI_OBJECT(TickAction, Action)
    public:
        using Tick = core::Function<bool(core::Duration)>;
        explicit TickAction(Tick tick) noexcept : m_tick(core::Move(tick)) {}

        void Start() override { m_done = false; }
        void Stop() override { m_done = true; }
        void Update(core::Duration elapsed) override
        {
            if (!m_done && (!m_tick || !m_tick(elapsed)))
            {
                m_done = true;
                FireDone();
            }
        }
        [[nodiscard]] bool IsDone() override { return m_done; }
        [[nodiscard]] f32 GetCurrentProgress() override { return m_done ? 1.0f : 0.0f; }
        [[nodiscard]] core::Duration GetTotalTime() override { return core::Duration{}; }

    private:
        Tick m_tick;
        bool m_done = false;
    };
    RTTI_DEFINE_OBJECT(TickAction, "rtti::gui")
}
