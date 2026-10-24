// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :action partition, what is left of it after slice S4: the target, ported with Node (S8).
// The rest is Code/Foundation/Sedulous.GUI/src/Scene/Action.bf.

export namespace foundation::gui
{
    class Action
    {

        void SetTarget(Node* target)
        {
            m_target = target;
            OnTargetChange();
        }
        [[nodiscard]] Node* GetTarget() const noexcept { return m_target; }

        /// A weak hold on the target, resolved through its GUI's element table (Node::RunAction
        /// sets it): an action whose target is gone is dropped rather than run on freed memory.
        struct WeakTarget
        {
            const void* table = nullptr;
            u32 slot = 0;
            u32 generation = 0;
            Node* (*resolve)(const WeakTarget&) = nullptr;
        };
        void SetWeakTarget(const WeakTarget& weak) noexcept { m_weak = weak; }
        /// The target when it is alive (or when none was held weakly), null once it is gone.
        [[nodiscard]] Node* ResolveTarget() const { return m_weak.resolve != nullptr ? m_weak.resolve(m_weak) : m_target; }

        Node* m_target = nullptr; // non-owning; read through ResolveTarget when held weakly
        WeakTarget m_weak{};
    };
}
