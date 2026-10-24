// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - `foundation.gui.gamekit`: a game's screens (Specs/gui-lab-evolution-3.md, section K):
// the screen stack (K4) and button prompts (K6), with the core's leaving (K0), back command (K1), input kind (K2) and data
// tweens (K3) under it. foundation.ui's counterpart: UI.Gamekit.

module;
#include "Core/Prelude.h"

export module foundation.gui.gamekit;

export import :screen_stack; // K4: screens on a stack, covering, blocking, pausing, focus, back
export import :prompt;       // K6: button prompts by input kind, glyphs from the sheet

export namespace foundation::gui
{
    /// Registers the gamekit's element types (Screens, Screen, Prompt), once: a host calls it at start-up
    /// beside RegisterGuiElements, so markup and scripts can make them.
    void RegisterGamekitElements();
}
