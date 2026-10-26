// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Engine.GUI (E5 of Specs/gui-lab-evolution-3.md), what is left of its tests after the Engine.GUI
// port's second slice: the input (where it goes, what the action layer hears, the bound source,
// the keys and Back, a fitted tier's pointer, the overlay layer modal: the port's E4), the
// components as the subsystem runs them (canvases, billboards, render textures, world panels, and
// the scene half of the overlay draw: E3) and the script surface (E5). The provider's, the domain's,
// the canvas's round trip and the billboard and panel math are in
// Code/Engine/Sedulous.Engine.GUI.Tests/src (GuiResourceProviderTests.bf, GuiDomainTests.bf,
// GuiComponentTests.bf, GuiWorldMathTests.bf), as are the subsystem core's (GuiSubsystemTests.bf:
// the screen and scene tiers, the game's sheets over the theme and their hot reload, the screen
// tier drawn into the overlay pass, the fonts, the screen's placement, a render resolution, a tier
// per run, the overlay layer, an editor's preview, the default family), on GuiTestEngine.bf.
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

    Node* FindById(Node& node, StringView id)
    {
        if (const UIWidget* widget = Cast<UIWidget>(&node); widget != nullptr && widget->GetId() == id)
            return &node;
        for (usize i = 0; i < node.ChildCount(); ++i)
            if (Node* found = FindById(*node.GetChildAt(i), id))
                return found;
        return nullptr;
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

// Partly ported: its screen half (a faded group's layer drawn before the screen's pass, prepared
// and unprepared draws) is TheScreenTierDrawsIntoTheEnginesOverlayPassItsLayersBeforeItsPass in
// GuiSubsystemTests.bf; what is left is the scene half, which needs a canvas's live tree (E3).
TEST_CASE("engine.gui: both tiers draw into the engine's overlay passes, the screen's layers before its pass")
{
    rhi::null::NullDevice device{DefaultAllocator()}; // outlives the GUI that draws on it
    Engine engine;
    engine.gui->EnsureRenderReady(device, 2);
    REQUIRE(engine.gui->IsRenderReady());
    rhi::null::NullCommandEncoder encoder;
    rhi::RenderPassEncoder* pass = encoder.BeginRenderPass(rhi::RenderPassDesc{});
    REQUIRE(pass != nullptr);

    // The scene tier: the view's scene root, laid out at its viewport.
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    SceneRoot* root = engine.gui->SceneRootFor(*level);
    REQUIRE(root != nullptr);
    RefPtr<Panel> badge = MakeRef<Panel>(DefaultAllocator());
    badge->SetSize(Float2{30.0f, 30.0f});
    NodeBox badgeLook;
    badgeLook.BackgroundColor = Color{0.0f, 1.0f, 0.0f, 1.0f};
    badge->SetBox(Move(badgeLook));
    {
        // A canvas holds it: a scene's GUI draws while it shows something.
        auto* canvases = level->GetSystem<engine::gui::GuiCanvasComponentManager>();
        const scene::EntityHandle hudEntity = level->CreateEntity(u8"hud");
        RefPtr<GuiDocument> document = MakeRef<GuiDocument>(DefaultAllocator());
        document->markup = String(u8"<Panel/>");
        canvases->Add(hudEntity).document = document;
        engine.Frame();
        REQUIRE(canvases->Get(hudEntity)->root);
        canvases->Get(hudEntity)->root->AddChild(badge.Get());
    }
    foundation::render::SceneOverlayView sceneView;
    sceneView.sceneKey = level;
    sceneView.viewportX = 160;
    sceneView.viewportWidth = 160;
    sceneView.viewportHeight = 180;
    sceneView.targetWidth = 320;
    sceneView.targetHeight = 180;
    sceneView.targetFormat = rhi::TextureFormat::RGBA8Unorm;
    const u64 drawsScene = encoder.counters->Snapshot().draws;
    engine.gui->Render(*pass, sceneView);
    CHECK(encoder.counters->Snapshot().draws > drawsScene);
    CHECK(root->GetViewportSize().x == doctest::Approx(160.0f));
    // Another scene's view draws nothing of this one.
    sceneView.sceneKey = &engine;
    const u64 drawsOther = encoder.counters->Snapshot().draws;
    engine.gui->Render(*pass, sceneView);
    CHECK(encoder.counters->Snapshot().draws == drawsOther);
    pass->End();
    engine.scenes.DestroyScene(level);
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
    // The scene's GUI styled and laid out at `size`, as a frame's draw does.
    void LayOut(GuiSubsystem& gui, SceneRoot& root, Float2 size)
    {
        root.SetViewportSize(size);
        gui.Styles().SetMediaContext(root.GetMediaContext());
        gui.Styles().ApplyTree(root);
        root.UpdateLayout();
    }
}

TEST_CASE("engine.gui: a canvas shows its document in its scene's GUI, ordered, shown and taking input as it says, rebuilt when its document changes, gone when despawned")
{
    Engine engine;
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    auto* canvases = level->GetSystem<engine::gui::GuiCanvasComponentManager>();
    REQUIRE(canvases != nullptr); // installed by the scene composition
    const scene::EntityHandle hud = level->CreateEntity(u8"hud");
    const scene::EntityHandle pause = level->CreateEntity(u8"pause");
    {
        engine::gui::GuiCanvasComponent& c = canvases->Add(pause);
        c.document = MakeDocument(u8"<Panel id=\"pause-menu\"/>");
        c.order = 5;
    }
    {
        engine::gui::GuiCanvasComponent& c = canvases->Add(hud);
        c.document = MakeDocument(u8"<Panel id=\"score\"/>");
        c.order = 1;
    }
    engine.Frame();
    SceneRoot* root = engine.gui->SceneRootFor(*level);
    REQUIRE(root != nullptr);
    REQUIRE(root->ChildCount() == 3u); // the billboards' layer, then the canvases
    CHECK(Cast<UIWidget>(root->GetChildAt(0))->GetTag() == StringView(u8"billboards"));
    CHECK(FindById(*root->GetChildAt(1), u8"score") != nullptr); // order 1 under order 5
    CHECK(FindById(*root->GetChildAt(2), u8"pause-menu") != nullptr);
    CHECK(Cast<UIWidget>(root->GetChildAt(1))->GetTag() == StringView(u8"canvas"));

    // Reordered.
    canvases->Get(hud)->order = 9;
    engine.Frame();
    CHECK(FindById(*root->GetChildAt(2), u8"score") != nullptr);

    // Hidden, then its entity inactive; not interactive.
    engine::gui::GuiCanvasComponent* c = canvases->Get(hud);
    Node* tree = c->root.Get();
    REQUIRE(tree != nullptr);
    c->visible = false;
    engine.Frame();
    CHECK_FALSE(tree->IsDisplayed());
    c->visible = true;
    level->SetActive(hud, false);
    engine.Frame();
    CHECK_FALSE(tree->IsDisplayed());
    level->SetActive(hud, true);
    c->interactive = false;
    engine.Frame();
    CHECK(tree->IsDisplayed());
    CHECK(tree->IsTreeInert());

    // A new document product rebuilds the tree.
    c->document = MakeDocument(u8"<Panel id=\"lives\"/>");
    engine.Frame();
    CHECK(FindById(*root, u8"lives") != nullptr);
    CHECK(FindById(*root, u8"score") == nullptr);

    // Despawned: its host goes.
    level->DestroyEntity(hud);
    engine.Frame();
    CHECK(root->ChildCount() == 2u);
    CHECK(FindById(*root, u8"lives") == nullptr);
    engine.scenes.DestroyScene(level);
}

TEST_CASE("engine.gui: a canvas scaled from a reference resolution fits the view, centred; at constant pixels it fills it")
{
    Engine engine;
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    auto* canvases = level->GetSystem<engine::gui::GuiCanvasComponentManager>();
    const scene::EntityHandle hud = level->CreateEntity(u8"hud");
    engine::gui::GuiCanvasComponent& added = canvases->Add(hud);
    added.document = MakeDocument(u8"<Panel id=\"frame\"/>");
    added.scalerMode = engine::gui::GuiScalerMode::ReferenceResolution;
    added.referenceResolution = Float2{400.0f, 300.0f};
    engine.Frame();
    SceneRoot* root = engine.gui->SceneRootFor(*level);
    Node* tree = canvases->Get(hud)->root.Get();
    REQUIRE(tree != nullptr);

    LayOut(*engine.gui, *root, Float2{1000.0f, 600.0f});
    CHECK(tree->GetSize().x == doctest::Approx(400.0f)); // laid out at the reference
    CHECK(tree->GetSize().y == doctest::Approx(300.0f));
    CHECK(tree->GetScale().x == doctest::Approx(2.0f));  // scaled to fit the height
    CHECK(tree->GetPosition().x == doctest::Approx(100.0f)); // centred across
    CHECK(tree->GetPosition().y == doctest::Approx(0.0f));

    canvases->Get(hud)->scalerMode = engine::gui::GuiScalerMode::ConstantPixel;
    engine.Frame();
    LayOut(*engine.gui, *root, Float2{1000.0f, 600.0f});
    CHECK(tree->GetSize().x == doctest::Approx(1000.0f));
    CHECK(tree->GetScale().x == doctest::Approx(1.0f));
    engine.scenes.DestroyScene(level);
}

TEST_CASE("engine.gui: a canvas's own sheet styles its document alone, over the game's")
{
    Engine engine;
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    auto* canvases = level->GetSystem<engine::gui::GuiCanvasComponentManager>();
    const scene::EntityHandle styled = level->CreateEntity(u8"styled");
    const scene::EntityHandle plain = level->CreateEntity(u8"plain");
    RefPtr<GuiStyleSheet> sheet = MakeRef<GuiStyleSheet>(DefaultAllocator());
    sheet->css = String(u8".title { width: 77px; height: 5px; }");
    {
        engine::gui::GuiCanvasComponent& c = canvases->Add(styled);
        c.document = MakeDocument(u8"<Panel><Panel class=\"title\" id=\"a\"/></Panel>"); // the root is the canvas's area
        c.sheet = sheet;
    }
    canvases->Add(plain).document = MakeDocument(u8"<Panel><Panel class=\"title\" id=\"b\"/></Panel>");
    engine.Frame();
    SceneRoot* root = engine.gui->SceneRootFor(*level);
    LayOut(*engine.gui, *root, Float2{800.0f, 600.0f});
    Node* a = FindById(*root, u8"a");
    Node* b = FindById(*root, u8"b");
    REQUIRE(a != nullptr);
    REQUIRE(b != nullptr);
    CHECK(a->GetSize().x == doctest::Approx(77.0f));
    CHECK(b->GetSize().x != doctest::Approx(77.0f));
    engine.scenes.DestroyScene(level);
}

namespace
{
    // A projection a test reads at a glance: clip = (x, y, z, z), so a point's place on screen is
    // (x / z, y / z) and it is behind the camera when z <= 0.
    Float4x4 SimpleProjection()
    {
        Float4x4 m = Float4x4::Identity();
        m.m[2][3] = 1.0f;
        m.m[3][3] = 0.0f;
        return m;
    }
    Float4x4 At(Float3 position)
    {
        Float4x4 m = Float4x4::Identity();
        m.m[3][0] = position.x;
        m.m[3][1] = position.y;
        m.m[3][2] = position.z;
        return m;
    }
}

TEST_CASE("engine.gui: billboards live in a layer under the canvases, placed as each view draws, and go when despawned")
{
    rhi::null::NullDevice device{DefaultAllocator()}; // outlives the GUI that draws on it
    Engine engine;
    engine.gui->EnsureRenderReady(device, 2);
    REQUIRE(engine.gui->IsRenderReady());
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    auto* billboards = level->GetSystem<engine::gui::GuiBillboardComponentManager>();
    REQUIRE(billboards != nullptr);
    const scene::EntityHandle guard = level->CreateEntity(u8"guard");
    level->SetLocalPosition(guard, Float3{0.0f, 0.0f, 1.0f});
    level->UpdateTransforms();
    billboards->Add(guard).document = MakeDocument(u8"<Panel width=\"40\" height=\"20\" id=\"plate\"/>");
    engine.Frame();
    SceneRoot* root = engine.gui->SceneRootFor(*level);
    Node* layer = root->GetChildAt(0);
    REQUIRE(layer->ChildCount() == 1u);
    Node* plate = billboards->Get(guard)->root.Get();
    REQUIRE(plate == layer->GetChildAt(0));

    foundation::render::SceneOverlayView view;
    view.sceneKey = level;
    view.viewProjection = SimpleProjection();
    view.viewportWidth = 200;
    view.viewportHeight = 100;
    view.targetWidth = 200;
    view.targetHeight = 100;
    view.targetFormat = rhi::TextureFormat::RGBA8Unorm;
    rhi::null::NullCommandEncoder encoder;
    rhi::RenderPassEncoder* pass = encoder.BeginRenderPass(rhi::RenderPassDesc{});
    REQUIRE(pass != nullptr);
    engine.gui->Render(*pass, view); // its size is known after this layout
    engine.gui->Render(*pass, view);
    CHECK(plate->GetSize().x == doctest::Approx(40.0f));
    CHECK(plate->GetPosition().x == doctest::Approx(80.0f)); // centred on 100
    CHECK(plate->GetPosition().y == doctest::Approx(30.0f)); // its bottom on 50
    CHECK(plate->IsVisible());

    level->SetLocalPosition(guard, Float3{0.0f, 0.0f, -1.0f}); // behind the camera
    level->UpdateTransforms();
    engine.gui->Render(*pass, view);
    CHECK_FALSE(plate->IsVisible());
    pass->End();

    level->DestroyEntity(guard);
    engine.Frame();
    CHECK(layer->ChildCount() == 0u);
    engine.scenes.DestroyScene(level);
}

TEST_CASE("engine.gui: a render-texture canvas draws into a texture of its own, its entity's sprite shows it, and it goes with the canvas")
{
    rhi::null::NullDevice device{DefaultAllocator()}; // outlives the GUI that draws on it
    Engine engine;
    engine.gui->EnsureRenderReady(device, 2);
    REQUIRE(engine.gui->IsRenderReady());
    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    level->AddSystem<engine::render::SpriteComponentManager>();
    auto* canvases = level->GetSystem<engine::gui::GuiCanvasComponentManager>();
    const scene::EntityHandle screen = level->CreateEntity(u8"screen");
    engine::render::SpriteComponent& sprite = level->GetSystem<engine::render::SpriteComponentManager>()->Add(screen);
    engine::gui::GuiCanvasComponent& added = canvases->Add(screen);
    added.document = MakeDocument(u8"<Panel id=\"monitor\"/>");
    added.renderMode = engine::gui::GuiCanvasRenderMode::RenderTexture;
    added.renderTextureWidth = 128;
    added.renderTextureHeight = 64;
    engine.Frame();
    engine::gui::GuiCanvasComponent* c = canvases->Get(screen);
    REQUIRE(c->renderRoot);
    SceneRoot* root = engine.gui->SceneRootFor(*level);
    CHECK(root->ChildCount() == 1u); // the billboards' layer alone: not in the scene's GUI
    CHECK(FindById(*c->renderRoot, u8"monitor") != nullptr);

    rhi::null::NullCommandEncoder encoder;
    engine.gui->RenderTextures(encoder, 0);
    CHECK(engine.gui->TextureCount() == 1u);
    REQUIRE(c->renderTextureView != nullptr);
    CHECK(sprite.texture == c->renderTextureView);
    CHECK(c->renderRoot->GetViewportSize().x == doctest::Approx(128.0f));
    const u64 passes = encoder.counters->Snapshot().renderPasses;
    CHECK(passes >= 1u);
    engine.gui->RenderTextures(encoder, 0); // once a frame
    CHECK(encoder.counters->Snapshot().renderPasses == passes);

    // Back over the view: in the scene's GUI again, the texture let go next time.
    c->renderMode = engine::gui::GuiCanvasRenderMode::ScreenOverlay;
    engine.Frame();
    CHECK(FindById(*root, u8"monitor") != nullptr);
    engine.gui->RenderTextures(encoder, 1);
    CHECK(engine.gui->TextureCount() == 0u);
    CHECK(sprite.texture == nullptr);

    // Into a texture again, then despawned: the texture goes.
    c->renderMode = engine::gui::GuiCanvasRenderMode::RenderTexture;
    engine.Frame();
    engine.gui->RenderTextures(encoder, 0);
    CHECK(engine.gui->TextureCount() == 1u);
    level->DestroyEntity(screen);
    engine.Frame();
    engine.gui->RenderTextures(encoder, 1);
    CHECK(engine.gui->TextureCount() == 0u);
    engine.scenes.DestroyScene(level);
}

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

    rhi::null::NullCommandEncoder encoder;
    engine.gui->RenderTextures(encoder, 0);
    engine::render::SpriteComponent* sprite = level->GetSystem<engine::render::SpriteComponentManager>()->Get(kiosk);
    REQUIRE(sprite != nullptr); // added for it
    CHECK(sprite->texture == c->renderTextureView);
    CHECK(sprite->orientation == engine::render::SpriteOrientation::EntityOriented);
    CHECK(sprite->postTonemap);
    CHECK(sprite->size.x == doctest::Approx(2.0f * 204.0f / 200.0f)); // the transparent edge's share
    CHECK(c->renderRoot->GetViewportSize().x == doctest::Approx(200.0f));

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
