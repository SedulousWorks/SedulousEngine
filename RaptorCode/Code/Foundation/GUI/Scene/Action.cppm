// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :action partition
//
// Action: the base of what runs on a GUI's clock (the tweens of E14, a widget's TickAction).
// Ported from eepp's Scene::Action (include/eepp/scene/action.hpp): an abstract lifecycle
// (Start/Stop/Update/IsDone) driven by the ActionManager, targeting a Node, with a tag, an id
// and an OnDone callback. Object-derived, so actions are RefPtr-owned by the manager and
// Cast<T>-able. The base stores the target as a Node* (forward-declared) and never dereferences
// it; actions that touch the node live where the full Node is imported.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:action;

import foundation.core; // Object, Function, Duration, Max, Min

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class Node;

    enum class ActionType
    {
        OnStart,
        OnStop,
        OnUpdate,
        OnDone
    };

    class Action : public Object
    {
        RTTI_OBJECT(Action, Object)
    public:
        using Callback = core::Function<void(Action&)>;

        virtual void Start() = 0;
        virtual void Stop() = 0;
        virtual void Update(core::Duration elapsed) = 0;
        [[nodiscard]] virtual bool IsDone() = 0;
        [[nodiscard]] virtual f32 GetCurrentProgress() = 0;
        [[nodiscard]] virtual core::Duration GetTotalTime() = 0;
        /// Whether it can change where its target is, how big, or how far its drawing reaches (an
        /// animation that could bring a node out of view into view). One that cannot asks for no
        /// frames while its target is out of view (E8b); it still runs, so it is caught up when the
        /// target shows. True unless an action knows better.
        [[nodiscard]] virtual bool CanMoveTarget() const { return true; }
        /// How much of the time its last Update was given ran past its end (E14): a group's next
        /// step starts with it, so a sequence keeps time whatever the frames.
        [[nodiscard]] virtual core::Duration GetOverrun() const { return core::Duration{}; }

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

        void SetId(u64 id) noexcept { m_id = id; }
        [[nodiscard]] u64 GetId() const noexcept { return m_id; }
        void SetTag(u64 tag) noexcept { m_tag = tag; }
        [[nodiscard]] u64 GetTag() const noexcept { return m_tag; }

        void SetOnDone(Callback callback) { m_onDone = core::Move(callback); }

    protected:
        virtual void OnTargetChange() {}
        void FireDone()
        {
            if (m_onDone)
                m_onDone(*this);
        }

        Node* m_target = nullptr; // non-owning; read through ResolveTarget when held weakly
        WeakTarget m_weak{};
        Callback m_onDone;
        u64 m_id = 0;
        u64 m_tag = 0;
    };

    RTTI_DEFINE_OBJECT(Action, "rtti::gui")
}
