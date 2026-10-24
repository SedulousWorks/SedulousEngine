// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - module implementation unit: ActionManager's tick, which reads its targets (a Node, which
// its partition only names).

module;
#include "Core/Prelude.h"

module foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;

namespace foundation::gui
{
    void ActionManager::Update(core::Duration elapsed, const TimeScale& scaleOf)
    {
        for (usize i = 0; i < m_actions.Size();)
        {
            Node* target = m_actions[i]->ResolveTarget();
            if (target == nullptr && m_actions[i]->GetTarget() != nullptr)
            {
                m_actions.RemoveAt(i); // its target was destroyed
                continue;
            }
            const f32 scale = (scaleOf && target != nullptr) ? scaleOf(*target) : 1.0f;
            // Out of view, an action that cannot bring its target into view changes nothing
            // that shows: what it writes marks the target alone (E8b), asking for no frame.
            const bool quiet = target != nullptr && target->WasOutOfView() && !m_actions[i]->CanMoveTarget();
            if (quiet)
                target->BeginQuietInvalidation();
            if (scale == 1.0f)
                m_actions[i]->Update(elapsed);
            else if (scale > 0.0f)
                m_actions[i]->Update(core::Duration::FromSeconds(static_cast<f64>(elapsed.AsSecondsF()) * static_cast<f64>(scale)));
            if (quiet)
                target->EndQuietInvalidation();
            if (m_actions[i]->IsDone())
                m_actions.RemoveAt(i);
            else
                ++i;
        }
    }
}
