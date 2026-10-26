// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Engine.GUI (E5 of Specs/gui-lab-evolution-3.md), what is left of its tests after the Engine.GUI
// port's third slice: the input (where it goes, what the action layer hears, the bound source,
// the keys and Back, a fitted tier's pointer, the overlay layer modal, a world panel's pointer: the
// port's E4) and the script surface (E5). The provider's, the domain's, the canvas's round trip and
// the billboard and panel math are in Code/Engine/Sedulous.Engine.GUI.Tests/src
// (GuiResourceProviderTests.bf, GuiDomainTests.bf, GuiComponentTests.bf, GuiWorldMathTests.bf), as
// are the subsystem core's (GuiSubsystemTests.bf: the screen and scene tiers, the game's sheets over
// the theme and their hot reload, both tiers drawn into the overlay passes, the fonts, the screen's
// placement, a render resolution, a tier per run, the overlay layer, an editor's preview, the
// default family) and the components' as the subsystem runs them (GuiComponentSyncTests.bf:
// canvases, their scaler and sheet, billboards, render textures, a world panel's sprite), on
// GuiTestEngine.bf.
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.vfs;
import foundation.runtime;
import foundation.scene;
import engine.scene;
import engine.render; // sprites and cameras (the textures, the panels' ray)
import foundation.content;
import foundation.resource;
import foundation.rhi;
import foundation.rhi.null;
import foundation.image;
import foundation.vg.resource;
import foundation.vg.svg;
import foundation.fonts;          // IFontService
import foundation.fonts.resource; // Font products (the project's fonts)
import foundation.texture.resource;
import foundation.render.api;
import foundation.shell;
import foundation.input;
import engine.input;
import engine.domain;
import foundation.script.facades; // the behaviour prelude's names
import foundation.gui;
import foundation.gui.gamekit;
import foundation.gui.resources;
import engine.gui;

using namespace foundation::core;
namespace scene = foundation::scene;
namespace runtime = foundation::runtime;
namespace rhi = foundation::rhi;
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

    // A mouse the test moves and presses; a press or release shows as an edge for one frame.
    struct FakeMouse final : foundation::shell::IMouse
    {
        f32 x = -100.0f;
        f32 y = -100.0f;
        bool down = false;
        bool wasDown = false;
        [[nodiscard]] f32 X() const override { return x; }
        [[nodiscard]] f32 Y() const override { return y; }
        [[nodiscard]] f32 GlobalX() const override { return x; }
        [[nodiscard]] f32 GlobalY() const override { return y; }
        [[nodiscard]] f32 DeltaX() const override { return 0.0f; }
        [[nodiscard]] f32 DeltaY() const override { return 0.0f; }
        [[nodiscard]] f32 ScrollX() const override { return 0.0f; }
        [[nodiscard]] f32 ScrollY() const override { return 0.0f; }
        [[nodiscard]] bool IsButtonDown(foundation::shell::MouseButton b) const override
        {
            return b == foundation::shell::MouseButton::Left && down;
        }
        [[nodiscard]] bool IsButtonPressed(foundation::shell::MouseButton b) const override
        {
            return b == foundation::shell::MouseButton::Left && down && !wasDown;
        }
        [[nodiscard]] bool IsButtonReleased(foundation::shell::MouseButton b) const override
        {
            return b == foundation::shell::MouseButton::Left && !down && wasDown;
        }
        [[nodiscard]] bool RelativeMode() const override { return false; }
        void SetRelativeMode(bool) override {}
        [[nodiscard]] bool CursorVisible() const override { return true; }
        void SetCursorVisible(bool) override {}
        void SetCursor(foundation::shell::CursorType) override {}
        void SetGlobalCapture(bool) override {}
    };

    // The engine's active input source as a test drives it: the mouse, and this frame's events.
    struct FakeDevices final : foundation::input::IInputSourceProvider
    {
        FakeMouse mouse;
        Array<foundation::shell::InputEvent> events;
        [[nodiscard]] foundation::shell::IKeyboard* Keyboard() override { return nullptr; }
        [[nodiscard]] foundation::shell::IMouse* Mouse() override { return &mouse; }
        [[nodiscard]] i32 GamepadCount() const override { return 0; }
        [[nodiscard]] foundation::shell::IGamepad* Gamepad(i32) override { return nullptr; }
        [[nodiscard]] Span<const foundation::shell::InputEvent> Events() override { return {events.Data(), events.Size()}; }
        void Key(foundation::shell::KeyCode key)
        {
            foundation::shell::InputEvent down;
            down.kind = foundation::shell::InputEventKind::KeyDown;
            down.key = key;
            events.PushBack(down);
            foundation::shell::InputEvent up = down;
            up.kind = foundation::shell::InputEventKind::KeyUp;
            events.PushBack(up);
        }
    };

    // What Engine.UI does in the same lane before the GUI: claims the pointer, when told to.
    class ClaimingSubsystem final : public runtime::Subsystem
    {
    public:
        explicit ClaimingSubsystem(engine::input::InputSubsystem& input) noexcept : m_input(input) {}
        [[nodiscard]] i32 UpdateOrder() const noexcept override { return -650; }
        void BeginFrame(f32) override
        {
            if (Claims)
                m_input.Runtime().SetConsumptionMask({true, false});
        }
        bool Claims = false;

    private:
        engine::input::InputSubsystem& m_input;
    };

    // A context with the scene subsystem and the GUI's (and the input subsystem's, on fake
    // devices), started.
    struct Engine
    {
        runtime::Context context{DefaultAllocator()};
        scene::SceneManager scenes{DefaultAllocator()};
        FakeDevices devices;
        engine::input::InputSubsystem* input = nullptr;
        ClaimingSubsystem* claiming = nullptr;
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
            input = context.AddSubsystem<engine::input::InputSubsystem>(nullptr);
            claiming = context.AddSubsystem<ClaimingSubsystem>(*input);
            gui = context.AddSubsystem<GuiSubsystem>(DefaultAllocator(), DataFs());
            context.Startup();
            input->SetSourceProvider(&devices);
        }
        ~Engine()
        {
            input->SetSourceProvider(nullptr);
            context.Shutdown();
        }
        // A frame as the application runs one: the last one's end (EndFrame), then this one's
        // BeginFrame lane, where the GUI pumps; the test reads what it did before its end.
        void Frame()
        {
            context.EndFrame();
            context.BeginFrame(1.0f / 60.0f);
            devices.events.Clear();
            devices.mouse.wasDown = devices.mouse.down;
        }
        [[nodiscard]] bool PointerClaimed() const { return input->Runtime().GetConsumptionMask().pointer; }
    };

    RefPtr<Button> MakeButton(StringView id, Float2 at)
    {
        RefPtr<Button> button = MakeRef<Button>(DefaultAllocator());
        button->SetId(id);
        button->SetPosition(at);
        button->SetSize(Float2{100.0f, 40.0f});
        return button;
    }
}

TEST_CASE("engine.gui: input goes to the root whose GUI is under the pointer, a click lands, and the action layer hears what the GUI took")
{
    Engine engine;
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    SceneRoot* hud = engine.gui->SceneRootFor(*level);
    REQUIRE(hud != nullptr);
    hud->SetViewportSize(Float2{800.0f, 600.0f});
    RefPtr<Button> button = MakeButton(u8"fire", Float2{20.0f, 20.0f});
    hud->AddChild(button.Get());
    i32 clicks = 0;
    (void)button->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });
    engine.gui->ScreenRoot()->SetViewportSize(Float2{800.0f, 600.0f});
    engine.Frame();

    // Over the button: the scene's root takes the input, and the pointer is the GUI's.
    engine.devices.mouse.x = 50.0f;
    engine.devices.mouse.y = 30.0f;
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == hud);
    CHECK(engine.gui->PointerOverGui());
    CHECK(engine.PointerClaimed());
    engine.devices.mouse.down = true;
    engine.Frame();
    engine.devices.mouse.down = false;
    engine.Frame();
    CHECK(clicks == 1);

    // Over empty space: the game's pointer; and the frame's end clears the claim.
    engine.devices.mouse.x = 500.0f;
    engine.Frame();
    CHECK_FALSE(engine.gui->PointerOverGui());
    CHECK_FALSE(engine.PointerClaimed());
    engine.devices.mouse.x = 50.0f;
    engine.Frame();
    CHECK(engine.PointerClaimed());
    engine.context.EndFrame();
    CHECK_FALSE(engine.PointerClaimed());

    // Engine.UI's claim (made first in the lane) stands though the GUI takes nothing.
    engine.claiming->Claims = true;
    engine.devices.mouse.x = 500.0f;
    engine.Frame();
    CHECK_FALSE(engine.gui->PointerOverGui());
    CHECK(engine.PointerClaimed());
    engine.claiming->Claims = false;
    engine.context.EndFrame();

    // A press stays with the root it began in until it is let go.
    engine.devices.mouse.x = 50.0f;
    engine.devices.mouse.down = true;
    engine.Frame();
    RefPtr<Button> menu = MakeButton(u8"menu", Float2{400.0f, 20.0f});
    RefPtr<UIWidget> screen = MakeRef<UIWidget>(DefaultAllocator());
    screen->AddChild(menu.Get());
    REQUIRE(engine.gui->Screens()->Push(*screen) != nullptr);
    engine.devices.mouse.x = 450.0f; // over the screen's button now, still held
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == hud);
    CHECK(engine.PointerClaimed()); // it began over the GUI
    engine.devices.mouse.down = false;
    engine.Frame();
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == engine.gui->ScreenRoot());
    engine.scenes.DestroyScene(level);
    CHECK(engine.gui->ActiveInputRoot() != hud);
}

TEST_CASE("engine.gui: with no GUI under the pointer the keys go to the screens a game pushed, and Back pops one")
{
    Engine engine;
    engine.gui->ScreenRoot()->SetViewportSize(Float2{800.0f, 600.0f});
    RefPtr<UIWidget> title = MakeRef<UIWidget>(DefaultAllocator());
    title->AddChild(MakeButton(u8"play", Float2{20.0f, 20.0f}).Get());
    RefPtr<UIWidget> settings = MakeRef<UIWidget>(DefaultAllocator());
    settings->AddChild(MakeButton(u8"back", Float2{20.0f, 20.0f}).Get());
    REQUIRE(engine.gui->Screens()->Push(*title) != nullptr);
    REQUIRE(engine.gui->Screens()->Push(*settings) != nullptr);
    engine.Frame();
    engine.Frame();
    CHECK(engine.gui->Screens()->Count() == 2u);
    engine.devices.Key(foundation::shell::KeyCode::Escape);
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == engine.gui->ScreenRoot());
    CHECK(engine.gui->Screens()->Count() == 1u);
}

TEST_CASE("engine.gui: a source bound to another scene never reaches this scene's GUI")
{
    Engine engine;
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    scene::Scene* other = engine.scenes.CreateScene(u8"other");
    SceneRoot* hud = engine.gui->SceneRootFor(*level);
    hud->SetViewportSize(Float2{800.0f, 600.0f});
    RefPtr<Button> button = MakeButton(u8"fire", Float2{20.0f, 20.0f});
    hud->AddChild(button.Get());
    engine.devices.mouse.x = 50.0f;
    engine.devices.mouse.y = 30.0f;
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == hud);
    engine.input->SetSourceProvider(&engine.devices, other); // an editor Game tab on the other scene
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() != hud);
    CHECK_FALSE(engine.gui->PointerOverGui());
    engine.input->SetSourceProvider(&engine.devices, level);
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == hud);
    engine.scenes.DestroyScene(other);
    engine.scenes.DestroyScene(level);
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

// Partly ported: its sprite (added for it, showing its texture, entity-oriented, after the tone
// mapping, grown by the transparent edge, its root laid out at its pixels) is
// AWorldPanelDrivesItsSprite in GuiComponentSyncTests.bf; what is left is the pointer reaching it by
// a ray (E4).
TEST_CASE("engine.gui: a world panel drives its sprite, and the pointer reaches it by a ray: hovered, clicked, the game told")
{
    rhi::null::NullDevice device{DefaultAllocator()}; // outlives the GUI that draws on it
    Engine engine;
    engine.gui->EnsureRenderReady(device, 2);
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    level->AddSystem<engine::render::SpriteComponentManager>();
    level->AddSystem<engine::render::CameraComponentManager>();
    const scene::EntityHandle camera = level->CreateEntity(u8"camera");
    level->SetLocalPosition(camera, Float3{0.0f, 2.0f, 10.0f});
    level->GetSystem<engine::render::CameraComponentManager>()->Add(camera);
    const scene::EntityHandle kiosk = level->CreateEntity(u8"kiosk");
    level->SetLocalPosition(kiosk, Float3{0.0f, 2.0f, 0.0f});
    level->UpdateTransforms();
    auto* panels = level->GetSystem<engine::gui::GuiWorldPanelComponentManager>();
    engine::gui::GuiWorldPanelComponent& added = panels->Add(kiosk);
    added.document = MakeDocument(u8"<Button id=\"tap\" text=\"Tap\"/>");
    added.sizeMeters = Float2{2.0f, 1.0f};
    added.pixelsPerMeter = 100.0f;
    engine.Frame();
    engine::gui::GuiWorldPanelComponent* c = panels->Get(kiosk);
    REQUIRE(c->renderRoot);
    i32 clicks = 0;
    (void)c->root->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });

    // The scene's GUI drew at 800 by 600: its camera's ray through the middle meets the panel.
    engine.gui->SceneRootFor(*level)->SetViewportSize(Float2{800.0f, 600.0f});
    engine.devices.mouse.x = 400.0f;
    engine.devices.mouse.y = 300.0f;
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == c->renderRoot.Get());
    CHECK(engine.gui->PointerOverGui());
    CHECK(engine.PointerClaimed());
    engine.devices.mouse.down = true;
    engine.Frame();
    engine.devices.mouse.down = false;
    engine.Frame();
    CHECK(clicks == 1);

    // Off the panel: the game's.
    engine.devices.mouse.x = 10.0f;
    engine.devices.mouse.y = 10.0f;
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() != c->renderRoot.Get());
    CHECK_FALSE(engine.gui->PointerOverGui());
    engine.scenes.DestroyScene(level);
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

// Partly ported: its layout at the game's resolution, its fitted draw and its return to the
// target's own size are AtARenderResolutionTheScreenTierLaysOutAtItAndDrawsFitted in
// GuiSubsystemTests.bf; what is left is the pointer taken to the tier's pixels (E4).
TEST_CASE("engine.gui: at a render resolution the screen tier lays out at it, draws fitted, and takes the pointer in render space")
{
    rhi::null::NullDevice device{DefaultAllocator()}; // outlives the GUI that draws on it
    Engine engine;
    engine.gui->EnsureRenderReady(device, 2);
    engine.gui->SetScreenResolution(400, 300, FitMode::Letterbox);
    RefPtr<UIWidget> menu = MakeRef<UIWidget>(DefaultAllocator());
    menu->AddChild(MakeButton(u8"play", Float2{20.0f, 20.0f}).Get());
    REQUIRE(engine.gui->Screens()->Push(*menu) != nullptr);

    foundation::render::ScreenOverlayView view;
    view.width = 800;
    view.height = 600;
    view.targetFormat = rhi::TextureFormat::RGBA8UnormSrgb;
    rhi::null::NullCommandEncoder encoder;
    engine.gui->PrepareOverlay(encoder, view); // the tier's target, which the pointer maps against
    SceneRoot* root = engine.gui->ScreenRoot();

    // The pointer arrives in render space (the game's fitted source): the tier takes it to its pixels.
    engine.devices.mouse.x = 50.0f;
    engine.devices.mouse.y = 30.0f;
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == root);
    CHECK(root->GetEventDispatcher()->GetMousePosition().x == doctest::Approx(100.0f));
    CHECK(root->GetEventDispatcher()->GetMousePosition().y == doctest::Approx(60.0f));
}

// Partly ported: a document pushed and taken off, a passive one's pointer-events, an empty one
// building nothing are ADocumentOnTheOverlayLayerShowsAboveEveryScreenUntilItIsTakenOff in
// GuiSubsystemTests.bf; what is left is where input goes while each shows (E4).
TEST_CASE("engine.gui: a document on the overlay layer shows above every screen, modal, until it is taken off")
{
    Engine engine;
    engine.gui->ScreenRoot()->SetViewportSize(Float2{800.0f, 600.0f});
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    SceneRoot* hud = engine.gui->SceneRootFor(*level);
    hud->SetViewportSize(Float2{800.0f, 600.0f});
    RefPtr<Button> fire = MakeButton(u8"fire", Float2{20.0f, 20.0f});
    hud->AddChild(fire.Get());
    engine.devices.mouse.x = 50.0f;
    engine.devices.mouse.y = 30.0f;
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == hud);

    RefPtr<GuiDocument> loading = MakeDocument(u8"<Panel id=\"loading\"/>");
    RefPtr<Node> splash = engine.gui->PushOverlay(*loading);
    REQUIRE(splash);
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == engine.gui->ScreenRoot()); // modal while it shows

    engine.gui->RemoveOverlay(*splash);
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == hud);

    // A passive overlay (a watermark: pointer-events none on its root) takes nothing.
    RefPtr<Node> badge = engine.gui->PushOverlay(*MakeDocument(u8"<Panel pointer-events=\"none\"><Label text=\"badge\"/></Panel>"));
    REQUIRE(badge);
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == hud);
    engine.gui->RemoveOverlay(*badge);
    engine.scenes.DestroyScene(level);
}
