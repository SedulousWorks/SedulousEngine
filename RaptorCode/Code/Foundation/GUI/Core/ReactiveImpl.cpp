// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the reactive layer's one piece of per-thread state (G5 of Specs/vg-and-gui-lab.md): the
// observer evaluating on this thread. Defined in the library, not in the interface, so every
// binary sees one slot per thread.

module;
#include "Core/Prelude.h"

module foundation.gui;

using namespace foundation::core;

namespace foundation::gui
{
    Observer*& CurrentObserverSlot() noexcept
    {
        thread_local Observer* current = nullptr;
        return current;
    }
}
