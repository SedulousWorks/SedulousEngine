// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :action_manager partition, what is left of it after slice S4: what reads an action's
// target, ported with Node (S8); Update's body is ActionManagerImpl.cpp. The rest is
// Code/Foundation/Sedulous.GUI/src/Scene/ActionManager.bf.

export namespace foundation::gui
{
    class ActionManager
    {
    public:
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
    };
}
