// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Engine.GUI (E5 of Specs/gui-lab-evolution-3.md), what is left of its tests after the Engine.GUI
// port's fourth slice: the script surface (E5). The provider's, the domain's, the canvas's round
// trip and the billboard and panel math are in Code/Engine/Sedulous.Engine.GUI.Tests/src
// (GuiResourceProviderTests.bf, GuiDomainTests.bf, GuiComponentTests.bf, GuiWorldMathTests.bf), as
// are the subsystem core's (GuiSubsystemTests.bf: the screen and scene tiers, the game's sheets over
// the theme and their hot reload, both tiers drawn into the overlay passes, the fonts, the screen's
// placement, a render resolution, a tier per run, the overlay layer, an editor's preview, the
// default family; a fitted tier's pointer and the overlay layer modal with them) and the
// components' as the subsystem runs them (GuiComponentSyncTests.bf: canvases, their scaler and
// sheet, billboards, render textures, a world panel's sprite and its pointer by a ray), as is the
// input (GuiInputTests.bf: where it goes, a press kept, what the action layer hears, the keys and
// Back, the bound source), on GuiTestEngine.bf (its fake devices GuiFakeDevices.bf and
// GuiFakeMouse.bf, Engine.UI's claim GuiClaimingSubsystem.bf).
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.vfs;
import foundation.runtime;
import foundation.scene;
import engine.scene;
import foundation.content;
import foundation.resource;
import foundation.image;
import foundation.vg.resource;
import foundation.vg.svg;
import foundation.fonts;          // IFontService
import foundation.fonts.resource; // Font products (the project's fonts)
import foundation.texture.resource;
import engine.domain;
import foundation.script.facades; // the behaviour prelude's names
import foundation.gui;
import foundation.gui.gamekit;
import foundation.gui.resources;
import engine.gui;

using namespace foundation::core;
namespace scene = foundation::scene;
namespace runtime = foundation::runtime;
using namespace foundation::gui;
using engine::gui::GuiSubsystem;

namespace
{
    // The data mount the subsystem reads its shaders and built-in font through.
    foundation::vfs::IFileSystem& DataFs()
    {
        static foundation::vfs::NativeFileSystem fs(foundation::vfs::FindDataRoot(), DefaultAllocator());
        return fs;
    }

    // Braced and the cooked project (Project) are GuiTestProject.bf.

    // A context with the scene subsystem and the GUI's, started. Its input (the input subsystem on
    // fake devices, Engine.UI's claim) is GuiTestEngine.bf's.
    struct Engine
    {
        runtime::Context context{DefaultAllocator()};
        scene::SceneManager scenes{DefaultAllocator()};
        GuiSubsystem* gui = nullptr;

        Engine()
        {
            auto* sceneSubsystem = context.AddSubsystem<engine::scene::SceneSubsystem>();
            sceneSubsystem->RegisterManager(&scenes);
            {
                const scene::SceneModule guiModule{u8"gui", &engine::gui::AddGuiSceneManagers, nullptr};
                const scene::SceneModule* modules[] = {&guiModule};
                sceneSubsystem->SetComposition(scene::SceneComposition::Build(modules));
            }
            gui = context.AddSubsystem<GuiSubsystem>(DefaultAllocator(), DataFs());
            context.Startup();
        }
        ~Engine() { context.Shutdown(); }
        // A frame as the application runs one: the last one's end (EndFrame), then this one's
        // BeginFrame lane.
        void Frame()
        {
            context.EndFrame();
            context.BeginFrame(1.0f / 60.0f);
        }
    };
}

namespace
{
    RefPtr<GuiDocument> MakeDocument(StringView markup)
    {
        RefPtr<GuiDocument> document = MakeRef<GuiDocument>(DefaultAllocator());
        document->markup = String(markup);
        return document;
    }
}

TEST_CASE("engine.gui: the script surface names gui and the components, and a component reaches its tree as a node")
{
    engine::gui::RegisterGuiScriptFacades();
    engine::gui::RegisterGuiScriptFacades(); // idempotent
    const auto named = [](StringView name)
    {
        usize found = 0;
        for (const StringView known : foundation::script::ExtraFacadeNames())
            found += known == name ? 1u : 0u;
        return found;
    };
    CHECK(named(u8"gui") == 1u);
    CHECK(named(u8"GuiCanvasComponent") == 1u);
    CHECK(named(u8"GuiBillboardComponent") == 1u);
    CHECK(named(u8"GuiWorldPanelComponent") == 1u);

    Engine engine;
    CHECK(engine.gui->Screens()->GetId() == StringView(u8"screens")); // what a script finds
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    const scene::EntityHandle hud = level->CreateEntity(u8"hud");
    auto* canvases = level->GetSystem<engine::gui::GuiCanvasComponentManager>();
    engine::gui::GuiCanvasComponent& c = canvases->Add(hud);
    CHECK(c.rootNode().IsEmpty()); // not built yet
    c.document = MakeDocument(u8"<Panel id=\"hud-root\"/>");
    engine.Frame();
    CHECK_FALSE(canvases->Get(hud)->rootNode().IsEmpty());
    engine.scenes.DestroyScene(level);
}
