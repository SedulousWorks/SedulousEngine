// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :diagnostic partition
//
// What a loader or parser says about its input (E1 of Specs/gui-lab-evolution-3.md): a line (1-based;
// 0 when it is not known) and a message. The markup loader and the CSS parser fill a list of them
// when given one, so a cook can warn of what they dropped or fail on what they could not read;
// without one they log, as a running GUI does.

module;
#include "Core/Prelude.h"

export module foundation.gui:diagnostic;

import foundation.core; // String, u32

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    struct GuiDiagnostic
    {
        enum class Severity : u8
        {
            Warning, ///< something was dropped; the rest stands
            Error,   ///< the input could not be read
        };
        Severity Level = Severity::Warning;
        u32 Line = 0; ///< 1-based; 0 when not known
        core::String Message;
    };
}
