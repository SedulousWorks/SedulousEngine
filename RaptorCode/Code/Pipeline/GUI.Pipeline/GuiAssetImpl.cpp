// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Pipeline - the GUI assets' reflection (kept out of the interface: GCC module hygiene).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

module gui.pipeline;

import foundation.core;
import pipeline.core;

using namespace foundation::core;

namespace pipeline
{
    REFLECT_MEMBERS(GuiDocumentAsset, "rtti::pipeline::gui")
    {
        builder.Attribute("displayName", String(u8"GUI Document"))
            .Attribute("category", String(u8"GUI"))
            .DataVersion(0);
    }

    REFLECT_MEMBERS(GuiStyleSheetAsset, "rtti::pipeline::gui")
    {
        builder.Attribute("displayName", String(u8"GUI Style Sheet"))
            .Attribute("category", String(u8"GUI"))
            .DataVersion(0);
    }
}
