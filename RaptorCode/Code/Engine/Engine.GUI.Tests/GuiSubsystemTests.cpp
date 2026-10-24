// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Engine.GUI (E5 of Specs/gui-lab-evolution-3.md): the resource provider answering asset guids
// (documents, sheets, vector images, textures) and following re-cooks; the subsystem's screen tier
// (the screen stack under the overlay layer) and scene tier (a root per scene); the game's sheets
// in order over the theme, restyled when one is cooked again; a document pushed by its guid; both
// tiers drawn into the engine's overlay passes (the Null device, the shaders from the data mount);
// the domain.
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
using engine::gui::GuiResourceProvider;
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

    String Braced(const Guid& id)
    {
        String braced(u8"{");
        braced.Append(Format(u8"{}", id).AsView());
        braced.Append(StringView(u8"}"));
        return braced;
    }

    // A content database of cooked GUI assets in a scratch folder, and a resource manager over it
    // with their factories.
    struct Project
    {
        rhi::null::NullDevice device{DefaultAllocator()};
        String folder;
        UniquePtr<foundation::vfs::NativeFileSystem> mount;
        UniquePtr<foundation::content::ContentDatabase> db;
        GuiDocumentFactory documents{DefaultAllocator()};
        GuiStyleSheetFactory sheets{DefaultAllocator()};
        foundation::vg::VectorImageFactory vectors{DefaultAllocator()};
        UniquePtr<foundation::texture::TextureFactory> textures;
        UniquePtr<foundation::resource::ResourceManager> resources;

        explicit Project(StringView name) : folder(name)
        {
            RegisterGuiResource();
            foundation::vg::RegisterVGResource();
            foundation::texture::RegisterTextureResource();
            Clean();
            mount = MakeUnique<foundation::vfs::NativeFileSystem>(DefaultAllocator(), folder.AsView(), DefaultAllocator());
            db = MakeUnique<foundation::content::ContentDatabase>(DefaultAllocator(), DefaultAllocator(), *mount, BinarySerializerFactory(), u8".rasset");
            textures = MakeUnique<foundation::texture::TextureFactory>(DefaultAllocator(), DefaultAllocator(), device);
            resources = MakeUnique<foundation::resource::ResourceManager>(DefaultAllocator(), DefaultAllocator(), *db);
            resources->AddFactory(&documents);
            resources->AddFactory(&sheets);
            resources->AddFactory(&vectors);
            resources->AddFactory(textures.Get());
        }
        ~Project()
        {
            resources.Reset();
            textures.Reset();
            db.Reset();
            mount.Reset();
            Clean();
        }
        void Clean()
        {
            const StringView files[] = {u8"menu", u8"base", u8"game", u8"icon", u8"map"};
            for (const StringView file : files)
                FileDelete(PathJoin(folder.AsView(), Format(u8"{}.rasset", file).AsView()).AsView());
            RemoveDirectory(folder.AsView());
        }
        Guid Document(StringView name, StringView markup)
        {
            auto* instance = db->RootGroup()->CreateInstance(name, GuiDocumentSource::StaticType());
            GuiDocumentSource source;
            source.markup = String(markup);
            REQUIRE(instance->WriteObject(source).IsOk());
            return instance->Id();
        }
        Guid Sheet(StringView name, StringView css)
        {
            auto* instance = db->RootGroup()->CreateInstance(name, GuiStyleSheetSource::StaticType());
            RewriteSheet(instance->Id(), css);
            return instance->Id();
        }
        // The sheet cooked again with `css`, and reloaded as the editor's re-cook does.
        void RewriteSheet(const Guid& id, StringView css)
        {
            GuiStyleSheetSource source;
            source.css = String(css);
            REQUIRE(db->GetInstance(id)->WriteObject(source).IsOk());
            (void)resources->Reload(id);
        }
        Guid Vector(StringView name, StringView svg)
        {
            auto* instance = db->RootGroup()->CreateInstance(name, foundation::vg::VectorImageSource::StaticType());
            foundation::vg::VectorImageSource source;
            source.svg = String(svg);
            REQUIRE(instance->WriteObject(source).IsOk());
            return instance->Id();
        }
        Guid Texture(StringView name, u32 width, u32 height)
        {
            auto* instance = db->RootGroup()->CreateInstance(name, foundation::texture::RenderTextureResource::StaticType());
            foundation::texture::RenderTextureResource record;
            record.width = width;
            record.height = height;
            REQUIRE(instance->WriteObject(record).IsOk());
            return instance->Id();
        }
    };

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

TEST_CASE("engine.gui: the provider answers documents, sheets, vector images and textures by guid, and only as what they are")
{
    Project project(u8"scratch_engine_gui_provider");
    const Guid menu = project.Document(u8"menu", u8"<Panel id=\"menu\"/>");
    const Guid sheet = project.Sheet(u8"game", u8"#menu { width: 10px; }");
    const Guid icon = project.Vector(u8"icon", u8"<svg width='8' height='8'><rect width='8' height='8'/></svg>");
    const Guid map = project.Texture(u8"map", 128, 64);

    GuiResourceProvider provider(DefaultAllocator());
    String text;
    CHECK_FALSE(provider.LoadText(Braced(menu).AsView(), text)); // no resource manager yet
    provider.SetResourceManager(project.resources.Get());
    Array<const foundation::image::ImageData*> told;
    provider.SetTextureSink([&](const foundation::image::ImageData* key, rhi::TextureView* view) { told.PushBack(view != nullptr ? key : nullptr); });

    REQUIRE(provider.LoadText(Braced(menu).AsView(), text));
    CHECK(text.AsView() == StringView(u8"<Panel id=\"menu\"/>"));
    REQUIRE(provider.LoadText(Format(u8"{}", sheet).AsView(), text)); // the bare guid too
    CHECK(text.AsView() == StringView(u8"#menu { width: 10px; }"));
    CHECK_FALSE(provider.LoadText(u8"menu.gml", text)); // a path is not a guid
    CHECK_FALSE(provider.LoadText(Braced(icon).AsView(), text)); // a vector image is no text

    const foundation::vg::svg::SVGDocument* picture = provider.LoadSvg(Braced(icon).AsView());
    REQUIRE(picture != nullptr);
    CHECK(provider.LoadSvg(Braced(icon).AsView()) == picture); // parsed once
    CHECK(provider.LoadSvg(Braced(sheet).AsView()) == nullptr);

    const foundation::image::ImageData* image = provider.LoadImage(Braced(map).AsView());
    REQUIRE(image != nullptr);
    CHECK(image->Width() == 128u);
    CHECK(image->Height() == 64u);
    CHECK(provider.LoadImage(Braced(map).AsView()) == image); // one key per texture
    REQUIRE(told.Size() == 1u);
    CHECK(told[0] == image); // the renderers learn it
    CHECK(provider.LoadImage(Braced(menu).AsView()) == nullptr);

    // Another project: what was bound goes, the renderers let the key go.
    provider.SetResourceManager(nullptr);
    REQUIRE(told.Size() == 2u);
    CHECK(told[1] == nullptr);
    CHECK_FALSE(provider.LoadText(Braced(menu).AsView(), text));
    CHECK(provider.LoadImage(Braced(map).AsView()) == nullptr);
}

TEST_CASE("engine.gui: a sheet cooked again is seen at the next poll, once")
{
    Project project(u8"scratch_engine_gui_poll");
    const Guid sheet = project.Sheet(u8"game", u8"#a { width: 1px; }");
    GuiResourceProvider provider(DefaultAllocator());
    provider.SetResourceManager(project.resources.Get());
    String text;
    REQUIRE(provider.LoadText(Braced(sheet).AsView(), text));
    CHECK_FALSE(provider.Poll());
    project.RewriteSheet(sheet, u8"#a { width: 2px; }");
    CHECK(provider.Poll());
    REQUIRE(provider.LoadText(Braced(sheet).AsView(), text));
    CHECK(text.AsView() == StringView(u8"#a { width: 2px; }"));
    CHECK_FALSE(provider.Poll());
}

TEST_CASE("engine.gui: the screen tier holds the screen stack under the overlay layer, and each scene a root of its own")
{
    Engine engine;
    SceneRoot* screen = engine.gui->ScreenRoot();
    REQUIRE(screen != nullptr);
    REQUIRE(screen->ChildCount() == 2u);
    CHECK(screen->GetChildAt(0) == engine.gui->Screens());
    CHECK(screen->GetChildAt(1) == engine.gui->OverlayLayer());
    CHECK(engine.gui->Context().GetResourceProvider() == &engine.gui->Resources());
    CHECK(engine.gui->Fonts() != nullptr);

    scene::Scene* level = engine.scenes.CreateScene(u8"level");
    SceneRoot* root = engine.gui->SceneRootFor(*level);
    REQUIRE(root != nullptr);
    CHECK(root != screen);
    engine.scenes.DestroyScene(level);
    CHECK(engine.gui->SceneRootFor(*level) == nullptr);
    CHECK(engine.gui->ScreenRoot() == screen); // the screen tier outlives a scene
}

TEST_CASE("engine.gui: the game's sheets apply in order over the theme, restyle when one is cooked again, and a document pushes by its guid")
{
    Project project(u8"scratch_engine_gui_sheets");
    const Guid base = project.Sheet(u8"base", u8"#box { width: 120px; height: 10px; }");
    const Guid game = project.Sheet(u8"game", u8"#box { width: 200px; }");
    const Guid menu = project.Document(u8"menu", u8"<Screen><Panel id=\"box\"/></Screen>");
    Engine engine;
    engine.gui->SetResourceManager(project.resources.Get());
    const Guid sheets[] = {base, game};
    engine.gui->SetStyleSheets(Span<const Guid>(sheets, 2));
    CHECK(engine.gui->StyleSheets().Size() == 2u);

    Screen* pushed = engine.gui->Screens()->PushDocument(Braced(menu).AsView());
    REQUIRE(pushed != nullptr);
    engine.gui->ScreenRoot()->SetViewportSize(Float2{800.0f, 600.0f});
    engine.Frame();
    Node* box = FindById(*engine.gui->ScreenRoot(), u8"box");
    REQUIRE(box != nullptr);
    CHECK(box->GetSize().x == doctest::Approx(200.0f)); // the game's over the shared one
    CHECK(box->GetSize().y == doctest::Approx(10.0f));  // what it leaves is the shared one's

    const u64 generation = engine.gui->SheetGeneration();
    engine.Frame();
    CHECK(engine.gui->SheetGeneration() == generation); // nothing changed: nothing re-applied
    project.RewriteSheet(game, u8"#box { width: 150px; }");
    engine.Frame();
    CHECK(engine.gui->SheetGeneration() == generation + 1);
    CHECK(box->GetSize().x == doctest::Approx(150.0f));

    engine.gui->SetResourceManager(nullptr); // before the project goes
}

TEST_CASE("engine.gui: both tiers draw into the engine's overlay passes, the screen's layers before its pass")
{
    rhi::null::NullDevice device{DefaultAllocator()}; // outlives the GUI that draws on it
    Engine engine;
    engine.gui->EnsureRenderReady(device, 2);
    REQUIRE(engine.gui->IsRenderReady());
    CHECK(engine.gui->Context().GetPictureBaker() != nullptr);

    // A faded group on a screen: its layer is drawn before the screen's pass.
    RefPtr<Panel> group = MakeRef<Panel>(DefaultAllocator());
    group->SetSize(Float2{60.0f, 40.0f});
    NodeBox look;
    look.BackgroundColor = Color{1.0f, 0.0f, 0.0f, 1.0f};
    group->SetBox(Move(look));
    group->SetAlpha(0.5f);
    RefPtr<Panel> inner = MakeRef<Panel>(DefaultAllocator());
    inner->SetSize(Float2{20.0f, 20.0f});
    NodeBox innerLook;
    innerLook.BackgroundColor = Color{0.0f, 0.0f, 1.0f, 1.0f};
    inner->SetBox(Move(innerLook));
    group->AddChild(inner.Get());
    REQUIRE(engine.gui->Screens()->Push(*group) != nullptr);
    engine.Frame();

    foundation::render::ScreenOverlayView view;
    view.width = 320;
    view.height = 180;
    view.targetFormat = rhi::TextureFormat::RGBA8UnormSrgb;
    rhi::null::NullCommandEncoder encoder;
    engine.gui->PrepareOverlay(encoder, view);
    const u64 layerPasses = encoder.counters->Snapshot().renderPasses;
    CHECK(layerPasses == 1u); // the faded group's layer, before the overlay pass opens
    CHECK(engine.gui->ScreenRoot()->GetViewportSize().x == doctest::Approx(320.0f));
    rhi::RenderPassEncoder* pass = encoder.BeginRenderPass(rhi::RenderPassDesc{});
    REQUIRE(pass != nullptr);
    const u64 drawsBefore = encoder.counters->Snapshot().draws;
    engine.gui->Render(*pass, view);
    CHECK(encoder.counters->Snapshot().draws > drawsBefore);
    CHECK(encoder.counters->Snapshot().renderPasses == layerPasses + 1); // Render opened none
    // Unprepared (another view): drawn in the pass all the same.
    const u64 drawsUnprepared = encoder.counters->Snapshot().draws;
    engine.gui->Render(*pass, view);
    CHECK(encoder.counters->Snapshot().draws > drawsUnprepared);

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

TEST_CASE("engine.gui: the domain brings the documents' and sheets' resource module")
{
    const engine::DomainModule& domain = engine::gui::GuiDomain();
    CHECK(domain.id == StringView(u8"gui"));
    bool documents = false;
    for (const foundation::resource::ResourceModule* module : domain.resources)
        documents = documents || module == &kGuiResourceModule;
    CHECK(documents);
    CHECK(domain.HasScene()); // its components
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

TEST_CASE("engine.gui: a canvas component round-trips through the scene format")
{
    engine::gui::RegisterGuiComponentReflection(); // versioned payloads read the type's data version
    engine::gui::GuiCanvasComponent a;
    a.document.SetId(Guid{1, 2});
    a.sheet.SetId(Guid{3, 4});
    a.order = 7;
    a.visible = false;
    a.interactive = false;
    a.scalerMode = engine::gui::GuiScalerMode::ReferenceResolution;
    a.referenceResolution = Float2{1280.0f, 800.0f};
    MemoryStream buffer;
    {
        BinarySerializer writer(buffer, SerializeMode::Write);
        BeginVersionedPayload(writer, TypeOf<engine::gui::GuiCanvasComponent>());
        Serialize(writer, a);
        EndVersionedPayload(writer);
    }
    (void)buffer.Seek(0, SeekOrigin::Begin);
    engine::gui::GuiCanvasComponent b;
    {
        BinarySerializer reader(buffer, SerializeMode::Read);
        BeginVersionedPayload(reader, TypeOf<engine::gui::GuiCanvasComponent>());
        Serialize(reader, b);
        EndVersionedPayload(reader);
    }
    CHECK(b.document.id == a.document.id);
    CHECK(b.sheet.id == a.sheet.id);
    CHECK(b.order == 7);
    CHECK_FALSE(b.visible);
    CHECK_FALSE(b.interactive);
    CHECK(b.scalerMode == engine::gui::GuiScalerMode::ReferenceResolution);
    CHECK(b.referenceResolution.x == doctest::Approx(1280.0f));
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

TEST_CASE("engine.gui: a billboard hangs from its entity's projected point, lifted by its offset, hidden behind the camera, scaled with distance")
{
    engine::gui::GuiBillboardComponent billboard;
    const Float4x4 projection = SimpleProjection();
    const Float2 viewport{200.0f, 100.0f};

    engine::gui::GuiBillboardPlacement placed = engine::gui::PlaceBillboard(billboard, At(Float3{0.0f, 0.0f, 1.0f}), projection, Float3{}, viewport);
    REQUIRE(placed.Shown);
    CHECK(placed.Anchor.x == doctest::Approx(100.0f)); // the view's centre
    CHECK(placed.Anchor.y == doctest::Approx(50.0f));
    CHECK(placed.Scale == doctest::Approx(1.0f));

    billboard.offset = Float3{0.0f, 0.5f, 0.0f}; // lifted half the view's height at that distance
    placed = engine::gui::PlaceBillboard(billboard, At(Float3{0.0f, 0.0f, 1.0f}), projection, Float3{}, viewport);
    CHECK(placed.Anchor.y == doctest::Approx(25.0f));

    // Screen orientation: the offset turns with the entity (a half turn about z flips the lift).
    billboard.orientation = engine::gui::GuiBillboardOrientation::Screen;
    Float4x4 turned = At(Float3{0.0f, 0.0f, 1.0f});
    turned.m[0][0] = -1.0f;
    turned.m[1][1] = -1.0f;
    placed = engine::gui::PlaceBillboard(billboard, turned, projection, Float3{}, viewport);
    CHECK(placed.Anchor.y == doctest::Approx(75.0f));

    CHECK_FALSE(engine::gui::PlaceBillboard(billboard, At(Float3{0.0f, 0.0f, -1.0f}), projection, Float3{}, viewport).Shown);

    billboard.offset = Float3{};
    billboard.scaleMode = engine::gui::GuiBillboardScale::Distance;
    billboard.referenceDistance = 10.0f;
    CHECK(engine::gui::PlaceBillboard(billboard, At(Float3{0.0f, 0.0f, 20.0f}), projection, Float3{}, viewport).Scale == doctest::Approx(0.5f));
    CHECK(engine::gui::PlaceBillboard(billboard, At(Float3{0.0f, 0.0f, 1.0f}), projection, Float3{}, viewport).Scale == doctest::Approx(2.0f)); // at most maxScale
    CHECK(engine::gui::PlaceBillboard(billboard, At(Float3{0.0f, 0.0f, 100.0f}), projection, Float3{}, viewport).Scale == doctest::Approx(0.3f)); // at least minScale
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

TEST_CASE("engine.gui: a ray crosses a world panel where it should, from either face, and misses past its edges")
{
    const Float4x4 panel = At(Float3{0.0f, 0.0f, 0.0f}); // in the xy plane, 2 by 1
    engine::gui::GuiPanelHit hit = engine::gui::RayHitGuiPanel(Float3{0.0f, 0.0f, 5.0f}, Float3{0.0f, 0.0f, -1.0f}, panel, Float2{2.0f, 1.0f});
    REQUIRE(hit.Hit);
    CHECK(hit.Distance == doctest::Approx(5.0f));
    CHECK(hit.Uv.x == doctest::Approx(0.5f));
    CHECK(hit.Uv.y == doctest::Approx(0.5f));
    hit = engine::gui::RayHitGuiPanel(Float3{0.5f, 0.25f, -5.0f}, Float3{0.0f, 0.0f, 1.0f}, panel, Float2{2.0f, 1.0f}); // from behind
    REQUIRE(hit.Hit);
    CHECK(hit.Uv.x == doctest::Approx(0.75f));
    CHECK(hit.Uv.y == doctest::Approx(0.25f)); // v down
    CHECK_FALSE(engine::gui::RayHitGuiPanel(Float3{1.5f, 0.0f, 5.0f}, Float3{0.0f, 0.0f, -1.0f}, panel, Float2{2.0f, 1.0f}).Hit); // past the edge
    CHECK_FALSE(engine::gui::RayHitGuiPanel(Float3{0.0f, 0.0f, 5.0f}, Float3{1.0f, 0.0f, 0.0f}, panel, Float2{2.0f, 1.0f}).Hit);  // along the plane
    CHECK_FALSE(engine::gui::RayHitGuiPanel(Float3{0.0f, 0.0f, 5.0f}, Float3{0.0f, 0.0f, 1.0f}, panel, Float2{2.0f, 1.0f}).Hit);  // away from it
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

namespace
{
    RefPtr<foundation::fonts::Font> MakeFontProduct(StringView family)
    {
        RefPtr<foundation::fonts::Font> font = MakeRef<foundation::fonts::Font>(DefaultAllocator());
        font->SetFamily(family);
        foundation::fonts::Font::Entry entry;
        entry.pixelHeight = 24.0f;
        font->AddEntry(Move(entry));
        return font;
    }
}

TEST_CASE("engine.gui: the project's fonts, a default and others each a family, else the built-in font")
{
    Engine engine;
    foundation::fonts::IFontService* builtIn = engine.gui->Fonts();
    REQUIRE(builtIn != nullptr);
    RefPtr<foundation::fonts::Font> body = MakeFontProduct(u8"Body");
    RefPtr<foundation::fonts::Font> title = MakeFontProduct(u8"Title");
    const foundation::fonts::Font* others[] = {title.Get()};

    engine.gui->SetFonts(nullptr, Span<const foundation::fonts::Font* const>(others, 1)); // others wait for a default
    CHECK(engine.gui->Fonts() == builtIn);

    engine.gui->SetFonts(body.Get(), Span<const foundation::fonts::Font* const>(others, 1));
    foundation::fonts::IFontService* project = engine.gui->Fonts();
    REQUIRE(project != builtIn);
    CHECK(engine.gui->Context().GetFontService() == project); // what text measures and draws with
    CHECK(project->DefaultFontFamily() == StringView(u8"Body"));
    foundation::fonts::CachedFont* bodyFont = project->GetFont(u8"Body", 24.0f);
    foundation::fonts::CachedFont* titleFont = project->GetFont(u8"Title", 24.0f);
    REQUIRE(bodyFont != nullptr);
    REQUIRE(titleFont != nullptr);
    CHECK(titleFont != bodyFont); // a label naming the title family gets the title face

    engine.gui->SetFonts(nullptr, {});
    CHECK(engine.gui->Fonts() == builtIn);
    CHECK(engine.gui->Context().GetFontService() == builtIn);
}

TEST_CASE("engine.gui: the screen is placed as the game's image is: fitted at its resolution, turned for its orientation")
{
    using engine::gui::GuiSubsystem;
    // No resolution, any orientation: the plain draw.
    CHECK_FALSE(GuiSubsystem::PlaceScreen(Float2{}, FitMode::Letterbox, ScreenOrientation::Any, Float2{1280.0f, 720.0f}).Fitted);

    // 320 by 180 fitted into 1280 by 800: letterboxed, laid out at 320 by 180 four times over.
    engine::gui::GuiScreenPlacement place =
        GuiSubsystem::PlaceScreen(Float2{320.0f, 180.0f}, FitMode::Letterbox, ScreenOrientation::Any, Float2{1280.0f, 800.0f});
    REQUIRE(place.Fitted);
    CHECK(place.Rect.x == doctest::Approx(0.0f));
    CHECK(place.Rect.y == doctest::Approx(40.0f));
    CHECK(place.Rect.width == doctest::Approx(1280.0f));
    CHECK(place.Rect.height == doctest::Approx(720.0f));
    CHECK(place.DrawSize.x == doctest::Approx(1280.0f));
    CHECK(place.DpiScale == doctest::Approx(4.0f)); // 1280 / 4 = 320 laid out

    // A landscape game on a portrait target: turned a quarter, laid out at its own shape.
    place = GuiSubsystem::PlaceScreen(Float2{}, FitMode::Letterbox, ScreenOrientation::Landscape, Float2{720.0f, 1280.0f});
    REQUIRE(place.Fitted);
    CHECK(place.Turn != ContentRotation::None);
    CHECK(place.DrawSize.x == doctest::Approx(1280.0f)); // the target's sides swapped
    CHECK(place.DrawSize.y == doctest::Approx(720.0f));
    CHECK(place.Transform.m[0][0] == doctest::Approx(0.0f)); // x runs down the target
}

TEST_CASE("engine.gui: at a render resolution the screen tier lays out at it, draws fitted, and takes the pointer in render space")
{
    rhi::null::NullDevice device{DefaultAllocator()}; // outlives the GUI that draws on it
    Engine engine;
    engine.gui->EnsureRenderReady(device, 2);
    engine.gui->SetScreenResolution(400, 300, FitMode::Letterbox);
    CHECK(engine.gui->HasScreenResolution());
    RefPtr<UIWidget> menu = MakeRef<UIWidget>(DefaultAllocator());
    menu->AddChild(MakeButton(u8"play", Float2{20.0f, 20.0f}).Get());
    REQUIRE(engine.gui->Screens()->Push(*menu) != nullptr);

    foundation::render::ScreenOverlayView view;
    view.width = 800;
    view.height = 600;
    view.targetFormat = rhi::TextureFormat::RGBA8UnormSrgb;
    rhi::null::NullCommandEncoder encoder;
    engine.gui->PrepareOverlay(encoder, view);
    SceneRoot* root = engine.gui->ScreenRoot();
    CHECK(root->GetSize().x == doctest::Approx(400.0f)); // laid out at the game's resolution
    CHECK(root->GetSize().y == doctest::Approx(300.0f));
    CHECK(root->GetDisplayScale() == doctest::Approx(2.0f)); // drawn crisp at the target's
    rhi::RenderPassEncoder* pass = encoder.BeginRenderPass(rhi::RenderPassDesc{});
    const u64 draws = encoder.counters->Snapshot().draws;
    engine.gui->Render(*pass, view);
    CHECK(encoder.counters->Snapshot().draws > draws);
    pass->End();

    // The pointer arrives in render space (the game's fitted source): the tier takes it to its pixels.
    engine.devices.mouse.x = 50.0f;
    engine.devices.mouse.y = 30.0f;
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == root);
    CHECK(root->GetEventDispatcher()->GetMousePosition().x == doctest::Approx(100.0f));
    CHECK(root->GetEventDispatcher()->GetMousePosition().y == doctest::Approx(60.0f));

    engine.gui->SetScreenResolution(0, 0, FitMode::Letterbox); // back to the target's own size
    CHECK_FALSE(engine.gui->HasScreenResolution());
    engine.gui->PrepareOverlay(encoder, view);
    CHECK(root->GetSize().x == doctest::Approx(800.0f));
    CHECK(root->GetDisplayScale() == doctest::Approx(1.0f));
}

TEST_CASE("engine.gui: with run screens on each run has its own screen tier, drawn for its tab and gone with its run")
{
    rhi::null::NullDevice device{DefaultAllocator()}; // outlives the GUI that draws on it
    Engine engine;
    engine.gui->EnsureRenderReady(device, 2);
    int runA = 0;
    int runB = 0;
    CHECK(engine.gui->ScreensFor(&runA) == engine.gui->Screens()); // off: one tier for every run
    engine.gui->SetRunScreens(true);
    ScreenStack* a = engine.gui->ScreensFor(&runA);
    ScreenStack* b = engine.gui->ScreensFor(&runB);
    REQUIRE(a != nullptr);
    CHECK(a != b);
    CHECK(a != engine.gui->Screens());
    CHECK(engine.gui->ScreensFor(&runA) == a); // made once
    CHECK(engine.gui->ScreensFor(nullptr) == engine.gui->Screens());
    CHECK(engine.gui->RunScreenCount() == 2u);
    CHECK(a->GetId() == StringView(u8"screens")); // what its scripts find under their root

    // A's tab draws A's screens under the shared tier; a run's resolution is its own.
    RefPtr<UIWidget> menu = MakeRef<UIWidget>(DefaultAllocator());
    menu->AddChild(MakeButton(u8"play", Float2{20.0f, 20.0f}).Get());
    REQUIRE(a->Push(*menu) != nullptr);
    engine.gui->SetScreenResolution(&runA, 320, 180, FitMode::Letterbox);
    CHECK_FALSE(engine.gui->HasScreenResolution()); // the shared tier's untouched
    foundation::render::ScreenOverlayView view;
    view.width = 640;
    view.height = 360;
    view.targetFormat = rhi::TextureFormat::RGBA8UnormSrgb;
    rhi::null::NullCommandEncoder encoder;
    engine.gui->SetRenderRun(&runA);
    engine.gui->PrepareOverlay(encoder, view);
    CHECK(engine.gui->ScreenRootFor(&runA)->GetSize().x == doctest::Approx(320.0f));
    rhi::RenderPassEncoder* pass = encoder.BeginRenderPass(rhi::RenderPassDesc{});
    const u64 draws = encoder.counters->Snapshot().draws;
    engine.gui->Render(*pass, view);
    CHECK(encoder.counters->Snapshot().draws > draws);
    pass->End();
    engine.gui->SetRenderRun(nullptr);

    engine.gui->EndRunScreens(&runA);
    CHECK(engine.gui->RunScreenCount() == 1u);
    engine.gui->EndRunScreens(&runB);
    CHECK(engine.gui->RunScreenCount() == 0u);
}

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
    CHECK(engine.gui->OverlayCount() == 1u);
    CHECK(FindById(*engine.gui->OverlayLayer(), u8"loading") != nullptr);
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == engine.gui->ScreenRoot()); // modal while it shows

    engine.gui->RemoveOverlay(*splash);
    CHECK(engine.gui->OverlayCount() == 0u);
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == hud);

    // A passive overlay (a watermark: pointer-events none on its root) takes nothing.
    RefPtr<Node> badge = engine.gui->PushOverlay(*MakeDocument(u8"<Panel pointer-events=\"none\"><Label text=\"badge\"/></Panel>"));
    REQUIRE(badge);
    CHECK_FALSE(badge->IsHitTestVisible());
    engine.Frame();
    CHECK(engine.gui->ActiveInputRoot() == hud);
    engine.gui->RemoveOverlay(*badge);

    RefPtr<GuiDocument> empty = MakeDocument(u8"");
    CHECK_FALSE(engine.gui->PushOverlay(*empty)); // nothing to build
    engine.scenes.DestroyScene(level);
}

TEST_CASE("engine.gui: an editor's preview builds in the GUI's context, a sheet over it alone, and draws into the editor's target")
{
    rhi::null::NullDevice device{DefaultAllocator()}; // outlives the GUI that draws on it
    Engine engine;
    engine.gui->EnsureRenderReady(device, 2);
    Array<GuiDiagnostic> found;
    CHECK_FALSE(engine.gui->CreatePreview(u8"<NoSuchElement/>", {}, &found)); // nothing builds
    CHECK_FALSE(found.IsEmpty());

    RefPtr<SceneRoot> preview =
        engine.gui->CreatePreview(u8"<Panel><Panel class=\"title\" id=\"t\"/></Panel>", u8".title { width: 66px; height: 4px; }");
    REQUIRE(preview);
    CHECK(engine.gui->ScreenRoot()->ChildCount() == 2u); // not in a tier: the screen's stack and overlays alone

    rhi::Texture* texture = nullptr;
    rhi::TextureView* target = nullptr;
    REQUIRE(device.CreateTexture(rhi::TextureDesc::RenderTarget(rhi::TextureFormat::RGBA8UnormSrgb, 320, 200), texture).IsOk());
    REQUIRE(device.CreateTextureView(texture, rhi::TextureViewDesc{}, target).IsOk());
    rhi::null::NullCommandEncoder encoder;
    const u64 passes = encoder.counters->Snapshot().renderPasses;
    engine.gui->RenderPreview(*preview, encoder, target, rhi::TextureFormat::RGBA8UnormSrgb, 320, 200, 0);
    CHECK(encoder.counters->Snapshot().renderPasses == passes + 1); // its own pass
    CHECK(preview->GetViewportSize().x == doctest::Approx(320.0f));
    Node* title = FindById(*preview, u8"t");
    REQUIRE(title != nullptr);
    CHECK(title->GetSize().x == doctest::Approx(66.0f)); // the sheet styled it

    preview = nullptr;
    device.DestroyTextureView(target);
    device.DestroyTexture(texture);
}

TEST_CASE("engine.gui: a game's text draws in the default family with no sheet naming one, and a sheet still chooses its own")
{
    // The style applier gives text a font only where a family is declared: the GUI's own sheet
    // declares the default family on every tree's top elements (the editor showed text missing
    // from a document's preview before it did).
    Engine engine;
    REQUIRE(engine.gui->Fonts() != nullptr);
    REQUIRE_FALSE(engine.gui->Fonts()->DefaultFontFamily().IsEmpty()); // the built-in font loaded
    RefPtr<SceneRoot> preview = engine.gui->CreatePreview(
        u8"<Panel flex-direction=\"column\" align-items=\"center\" padding=\"24\">"
        u8"<Label id=\"title\" text=\"New document\"/><Button id=\"ok\" text=\"OK\"/></Panel>");
    REQUIRE(preview);
    preview->SetViewportSize(Float2{800.0f, 500.0f});
    engine.gui->Styles().SetMediaContext(preview->GetMediaContext());
    engine.gui->Styles().ApplyTree(*preview);
    preview->UpdateLayout();
    Node* title = FindById(*preview, u8"title");
    Node* ok = FindById(*preview, u8"ok");
    REQUIRE(title != nullptr);
    REQUIRE(ok != nullptr); // (a button with no width fills its line: the GUI's Button, not this)
    CHECK(title->GetSize().x > 0.0f); // its text measured
    CHECK(title->GetSize().y > 0.0f);
    CHECK(ok->GetSize().y > 0.0f);
    CHECK(Cast<UINode>(title)->GetTextStyle().FontFamily.AsView() == engine.gui->Fonts()->DefaultFontFamily());
}
