// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :panel partition
//
// Panel: the plain container element (`<Panel>` in markup, `add("Panel")` in a script). It lays
// out its children by its display kind (a flex column unless its sheet or markup says otherwise:
// `display`, `flex-direction`, `grid-template-columns`, ...); everything it does is the base
// node's (E2 of Specs/gui-lab-evolution.md).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:panel;

import foundation.core;
import :ui_widget;

export namespace foundation::gui
{
    class Panel : public UIWidget
    {
        RTTI_OBJECT(Panel, UIWidget)
    public:
        Panel() { SetTag(core::StringView(u8"panel")); }
    };
}
