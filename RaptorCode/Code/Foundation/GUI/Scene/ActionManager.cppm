// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :action_manager partition
//
// ActionManager: owns and ticks running Actions. Ported from eepp's Scene::ActionManager
// (include/eepp/scene/actionmanager.hpp). Owned by the SceneRoot; Node::RunAction forwards
// here. Actions are RefPtr-owned; a finished action is dropped after Update.

module;
#include "Core/Prelude.h"

export module foundation.gui:action_manager;

import foundation.core; // RefPtr, Array, Duration, Move
import :action;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class Node;

    class ActionManager
    {
    public:
        // Adds and starts an action.
        void AddAction(RefPtr<Action> action)
        {
            if (!action)
                return;
            action->Start();
            m_actions.PushBack(core::Move(action));
        }

        /// How fast an action's time runs (its target's root may be paused, 0, or slowed).
        using TimeScale = core::Function<f32(Node& target)>;

        // Ticks all actions, each by `elapsed` times its target's time scale (1 without one);
        // drops finished ones and those whose target is gone.
        /// An action that cannot bring its target into view, on a target out of view at the last
        /// frame, writes quietly (E8b): its target's invalidations mark it alone, asking for no frame.
        void Update(core::Duration elapsed, const TimeScale& scaleOf = {});

        /// Whether an action is running that `matches(action, target)` takes (a root asks for its frames).
        template <typename Predicate>
        [[nodiscard]] bool AnyAction(Predicate&& matches) const
        {
            for (const RefPtr<Action>& a : m_actions)
                if (Node* target = a->ResolveTarget(); target != nullptr && matches(*a, *target))
                    return true;
            return false;
        }

        /// Calls `f(action)` for each running action.
        template <typename F>
        void ForEachAction(F&& f)
        {
            for (const RefPtr<Action>& a : m_actions)
                f(*a);
        }

        bool RemoveAllActionsFromTarget(Node* target)
        {
            bool removed = false;
            for (usize i = 0; i < m_actions.Size();)
            {
                if (m_actions[i]->GetTarget() == target)
                {
                    m_actions.RemoveAt(i);
                    removed = true;
                }
                else
                    ++i;
            }
            return removed;
        }

        [[nodiscard]] Action* GetActionByTag(u64 tag) const
        {
            for (const RefPtr<Action>& a : m_actions)
                if (a->GetTag() == tag)
                    return a.Get();
            return nullptr;
        }

        [[nodiscard]] usize Count() const noexcept { return m_actions.Size(); }
        [[nodiscard]] bool IsEmpty() const noexcept { return m_actions.Size() == 0; }
        void Clear() { m_actions.Clear(); }

    private:
        Array<RefPtr<Action>> m_actions;
    };
}
