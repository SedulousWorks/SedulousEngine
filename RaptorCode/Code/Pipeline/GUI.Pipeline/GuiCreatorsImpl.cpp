// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Pipeline - the GUI's New Asset creators (agent-playtesting-and-asset-creation.md P1): what
// File > New and asset_create make, with no editor (the source database and the sources folder are
// all a creation needs).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

module gui.pipeline;

import foundation.core;
import foundation.content;
import pipeline.core;

using namespace foundation::core;

namespace pipeline
{
    void RegisterGuiCreators(AssetCreatorRegistry& registry)
    {
        // Each writes its starter text to a LINKED source file in Sources/ (.gml, .css) that the
        // asset references through fileName, like a script.
        {
            AssetCreator creator;
            creator.label = String(u8"GUI Document");
            creator.category = String(u8"GUI");
            creator.type = &GuiDocumentAsset::StaticType();
            creator.run = [](const AssetCreationContext& context) -> foundation::content::Instance*
            {
                GuiDocumentAsset asset;
                return CreateLinkedTextAsset(context, u8"GuiDocument", u8".gml", kGuiDocumentStarter, GuiDocumentAsset::StaticType(), asset);
            };
            registry.Register(Move(creator));
        }
        {
            AssetCreator creator;
            creator.label = String(u8"GUI Style Sheet");
            creator.category = String(u8"GUI");
            creator.type = &GuiStyleSheetAsset::StaticType();
            creator.run = [](const AssetCreationContext& context) -> foundation::content::Instance*
            {
                GuiStyleSheetAsset asset;
                return CreateLinkedTextAsset(context, u8"GuiStyleSheet", u8".css", kGuiStyleSheetStarter, GuiStyleSheetAsset::StaticType(),
                                             asset);
            };
            registry.Register(Move(creator));
        }
    }
}
