// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The GUI's game menu (the sandbox's showcase, K7 of Specs/gui-lab-evolution-3.md) played
// end to end from its real files: Data/Assets/ui/showcase's frame, sheet and screen documents, and
// its AngelScript, on the gamekit's stack. A player's keys and pad drive it: pages and Back, the
// quit question, loading into the game, the HUD's prompt following the device, the score counting
// up in whole numbers, pause from Escape and Start stopping the game, back to the menu, and leaving.
// The sandbox's sweeps click through it; this checks what each step does.
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.image;
import foundation.vg.svg;
import foundation.script;
import foundation.shell;
import foundation.input;
import foundation.gui;
import foundation.gui.gamekit;
#ifdef OPTION_HAS_ANGELSCRIPT
import foundation.script.angelscript;
#endif

#ifdef OPTION_HAS_ANGELSCRIPT
namespace gui = foundation::gui;
namespace core = foundation::core;
namespace script = foundation::script;
namespace input = foundation::input;
namespace shell = foundation::shell;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // The data folder's files, as the sandbox reads them (a path relative to Data/).
    [[nodiscard]] core::String ReadData(core::StringView relative)
    {
        core::String path(core::StringView(reinterpret_cast<const char8_t*>(GUI_SHOWCASE_DATA)));
        path += SV(u8"/");
        path += relative;
        core::Result<core::Array<core::byte>> bytes = core::ReadFile(path.AsView());
        if (!bytes.HasValue())
            return {};
        return core::String(core::StringView(reinterpret_cast<const char8_t*>(bytes.Value().Data()), bytes.Value().Size()));
    }

    class DataFiles final : public gui::IResourceProvider
    {
    public:
        DataFiles() : IResourceProvider(core::DefaultAllocator()) {}
        const foundation::image::ImageData* LoadImage(core::StringView) override { return nullptr; }
        bool LoadText(core::StringView path, core::String& out) override
        {
            out = ReadData(path);
            return out.Size() != 0;
        }
        const foundation::vg::svg::SVGDocument* LoadSvg(core::StringView) override { return nullptr; }
    };

    struct Errors final : script::IScriptErrorHandler
    {
        int count = 0;
        core::String last;
        void OnError(const script::ScriptError& error) override
        {
            ++count;
            last = core::String(error.message);
        }
    };

    // The menu as the sandbox hosts it: its frame filling a 960 x 820 root, its sheet over it,
    // the menu's actions given to its prompts, and its script running.
    struct Showcase
    {
        core::RefPtr<gui::SceneRoot> root =
            core::MakeRef<gui::SceneRoot>(core::DefaultAllocator(), core::MakeRef<gui::GUIContext>(core::DefaultAllocator()));
        gui::StyleManager styles;
        DataFiles files;
        input::ActionRuntime actions;
        gui::InputPrompts prompts;
        gui::GuiScriptBinding binding;
        Errors errors;
        core::RefPtr<script::IScriptManager> manager;
        core::RefPtr<script::IScriptContext> context;
        core::RefPtr<gui::Node> frame;
        gui::ScreenStack* stack = nullptr;

        Showcase()
        {
            core::RegisterCoreTypes();
            gui::RegisterGuiElements();
            gui::RegisterGamekitElements();
            gui::RegisterGuiScriptSurface();
            root->SetSize(core::Float2{960.0f, 820.0f});
            root->GetContext().SetResourceProvider(&files);
            root->GetContext().GetData().Set(SV(u8"name"), core::Variant::From(core::String(u8"Ada")));
            root->GetContext().GetData().Set(SV(u8"volume"), core::Variant::From<core::f64>(0.7));
            root->GetContext().GetData().Set(SV(u8"music"), core::Variant::From<bool>(true));
            // The menu's one action, which its HUD's prompt shows.
            input::InputMap map;
            input::ActionSet game;
            game.name = core::String(u8"Game");
            input::Action pause;
            pause.name = core::String(u8"pause");
            input::Binding escape;
            escape.source = input::BindingSource::Key;
            escape.code = static_cast<core::u32>(shell::KeyCode::Escape);
            pause.bindings.PushBack(escape);
            input::Binding start;
            start.source = input::BindingSource::GamepadButton;
            start.code = static_cast<core::u32>(shell::GamepadButton::Start);
            pause.bindings.PushBack(start);
            game.actions.PushBack(core::Move(pause));
            map.sets.PushBack(core::Move(game));
            actions.SetMap(map);
            prompts.SetRuntime(&actions);
            prompts.Install(root->GetContext());

            static const gui::ElementSet elements = gui::ElementSet::All();
            gui::MarkupLoader loader(elements, core::DefaultAllocator(), &files);
            loader.SetDataModel(root->GetContext().GetDataRef());
            frame = loader.LoadFromString(ReadData(SV(u8"Assets/ui/showcase/menu.xml")).AsView());
            REQUIRE(frame);
            root->AddChild(frame.Get());
            frame->SetSize(root->GetSize());
            for (core::usize i = 0; i < frame->ChildCount(); ++i)
                frame->GetChildAt(i)->SetSize(root->GetSize());
            (void)styles.SetSubtreeSheet(*frame, gui::CSSParser::Parse(ReadData(SV(u8"Assets/ui/showcase/menu.css")).AsView()));
            styles.ApplyTree(*root);
            stack = FindStack(*frame);
            REQUIRE(stack != nullptr);

            manager = script::angelscript::CreateScriptManager(core::DefaultAllocator());
            script::RegisterReflectedTypes(*manager);
            binding.root = root.Get();
            context = manager->CreateContext();
            context->SetErrorHandler(&errors);
            gui::InstallGuiScriptService(*context, binding);
            const core::Status loaded = context->Load(ReadData(SV(u8"Assets/ui/showcase/menu.as")).AsView(), SV(u8"menu.as"));
            INFO(doctest::String(reinterpret_cast<const char*>(errors.last.CStr())));
            REQUIRE(loaded.IsOk());
            Frame(0.0);
        }
        ~Showcase()
        {
            if (context)
            {
                gui::ClearGuiScriptService(*context);
                context->SetErrorHandler(nullptr);
            }
            gui::InputPrompts::Uninstall(root->GetContext());
        }

        static gui::ScreenStack* FindStack(gui::Node& node)
        {
            if (auto* found = core::Cast<gui::ScreenStack>(&node))
                return found;
            for (core::usize i = 0; i < node.ChildCount(); ++i)
                if (gui::ScreenStack* found = FindStack(*node.GetChildAt(i)))
                    return found;
            return nullptr;
        }

        // A host's frame: the GUI's clock, the style pass, the layout, and the script's update.
        void Frame(double seconds)
        {
            core::Variant dt[1] = {core::Variant::From<core::f64>(seconds)};
            (void)context->Call(SV(u8"update"), core::Span<core::Variant>(dt, 1));
            root->GetContext().Update(core::Duration::FromSeconds(seconds));
            styles.ApplyTree(*root);
            (void)root->UpdateLayout();
        }
        void Frames(double seconds, double step = 0.05)
        {
            for (double t = 0.0; t < seconds - 1e-6; t += step)
                Frame(step);
        }
        gui::EventDispatcher& D() { return *root->GetEventDispatcher(); }
        void Key(gui::KeyCode key)
        {
            (void)D().InjectKeyDown(static_cast<core::u32>(key));
            (void)D().InjectKeyUp(static_cast<core::u32>(key));
            Frame(0.0);
        }
        // Moves the focus to the button `id` on the top screen and presses Return, as a player would.
        void Choose(const char8_t* id)
        {
            gui::Node* target = Find(*stack->Top(), SV(id));
            REQUIRE(target != nullptr);
            D().SetFocusNode(target);
            Key(gui::KeyCode::Return);
        }
        static gui::Node* Find(gui::Node& node, core::StringView id)
        {
            if (const auto* w = core::Cast<gui::UIWidget>(&node); w != nullptr && w->GetId() == id)
                return &node;
            for (core::usize i = 0; i < node.ChildCount(); ++i)
                if (gui::Node* found = Find(*node.GetChildAt(i), id))
                    return found;
            return nullptr;
        }
        static gui::Prompt* FindPrompt(gui::Node& node)
        {
            if (auto* p = core::Cast<gui::Prompt>(&node))
                return p;
            for (core::usize i = 0; i < node.ChildCount(); ++i)
                if (gui::Prompt* found = FindPrompt(*node.GetChildAt(i)))
                    return found;
            return nullptr;
        }
        [[nodiscard]] core::StringView Focused()
        {
            const auto* w = core::Cast<gui::UIWidget>(D().GetFocusNode());
            return w != nullptr ? w->GetId() : SV(u8"");
        }
        [[nodiscard]] core::Variant Data(const char8_t* name) { return root->GetContext().GetData().Peek(SV(name)); }
        [[nodiscard]] bool StageShown() { return Find(*frame, SV(u8"stage"))->IsDisplayed(); }
    };
}

TEST_CASE("showcase: the menu's pages push and pop, Back goes back, and the title keeps its own Back")
{
    Showcase menu;
    REQUIRE(menu.errors.count == 0);
    CHECK(menu.stack->Count() == 1u);
    CHECK(menu.Focused() == SV(u8"play"));
    menu.Key(gui::KeyCode::Escape); // the title keeps its back
    CHECK(menu.stack->Count() == 1u);

    menu.Choose(u8"settings-btn");
    CHECK(menu.stack->Count() == 2u);
    CHECK(menu.stack->Top()->GetCovers());
    CHECK(menu.D().GetFocusNode() != nullptr); // the page took the focus
    menu.Frames(0.5); // its entrance; then Back
    menu.Key(gui::KeyCode::Escape);
    CHECK(menu.stack->Count() == 1u);
    CHECK(menu.Focused() == SV(u8"settings-btn")); // where the player left from

    menu.Choose(u8"controls-btn");
    CHECK(menu.stack->Count() == 2u);
    menu.Frames(0.5);
    menu.D().InjectPadButton(gui::PadButton::East); // Back from the pad
    menu.Frame(0.0);
    CHECK(menu.stack->Count() == 1u);
    CHECK(menu.errors.count == 0);
}

TEST_CASE("showcase: the quit question opens over the menu; Stay and Back close it; Leave sets quit for the host")
{
    Showcase menu;
    menu.Choose(u8"quit");
    REQUIRE(menu.stack->Count() == 2u);
    CHECK_FALSE(menu.stack->Top()->GetCovers()); // the menu shows behind it
    CHECK(menu.Focused() == SV(u8"confirm-no")); // Stay, the safe answer
    menu.Frames(0.5);
    menu.Key(gui::KeyCode::Return); // Stay
    CHECK(menu.stack->Count() == 1u);
    CHECK(menu.Focused() == SV(u8"quit"));
    menu.Choose(u8"quit");
    menu.Frames(0.5);
    menu.Key(gui::KeyCode::Escape); // Back is Stay too
    CHECK(menu.stack->Count() == 1u);

    menu.Choose(u8"quit");
    menu.Frames(0.5);
    menu.Choose(u8"confirm-yes"); // Leave
    // As the host reads it (a script's true may arrive as a number).
    const core::Variant quit = gui::ConvertVariant(menu.Data(u8"quit"), core::TypeOf<bool>());
    REQUIRE(quit.TryGet<bool>() != nullptr);
    CHECK(*quit.TryGet<bool>());
    CHECK(core::Cast<gui::UIWidget>(menu.frame.Get())->HasClass(SV(u8"closing")));
    CHECK(menu.errors.count == 0);
}

TEST_CASE("showcase: Play loads into the game; Back from loading returns to the menu")
{
    Showcase menu;
    menu.Choose(u8"play");
    CHECK(menu.stack->Count() == 2u);
    CHECK_FALSE(menu.StageShown()); // the loading screen replaces the menu
    menu.Frames(1.0);
    menu.Key(gui::KeyCode::Escape); // Back cancels the loading
    CHECK(menu.stack->Count() == 1u);
    CHECK(menu.StageShown());
    menu.Frames(4.0); // nothing goes on loading behind it
    CHECK(menu.stack->Count() == 1u);

    menu.Choose(u8"play");
    menu.Frames(3.5); // 2.5 s loading, a moment on Ready, then the game
    REQUIRE(menu.stack->Count() == 1u);
    CHECK(menu.stack->Top()->GetCovers());
    CHECK(menu.Find(*menu.stack->Top(), SV(u8"hud-score")) != nullptr);
    CHECK_FALSE(menu.StageShown());
    CHECK(menu.errors.count == 0);
}

TEST_CASE("showcase: in the game the score counts up in whole numbers, the prompt follows the device, and pause stops the game")
{
    Showcase menu;
    menu.Choose(u8"play");
    menu.Frames(3.5);
    gui::Screen* hud = menu.stack->Top();
    REQUIRE(hud != nullptr);
    gui::Prompt* prompt = Showcase::FindPrompt(*hud);
    REQUIRE(prompt != nullptr);
    CHECK(prompt->GetBinding() == SV(u8"escape"));
    menu.D().SetInputKind(gui::InputKind::Pad);
    menu.Frame(0.0);
    CHECK(prompt->GetBinding() == SV(u8"pad-start"));

    // The score: points every 1.4 s, counted up through a data tween, never a fraction on the way.
    bool sawRising = false;
    for (int i = 0; i < 80; ++i)
    {
        menu.Frame(0.05);
        const core::Variant score = menu.Data(u8"score");
        const core::f64* n = score.TryGet<core::f64>();
        REQUIRE(n != nullptr);
        CHECK(*n == static_cast<core::f64>(static_cast<core::i64>(*n)));
        sawRising = sawRising || (*n > 0.0 && static_cast<core::i64>(*n) % 10 != 0);
    }
    CHECK(sawRising); // it passed numbers between the tens: it counted, not jumped
    const core::Variant scored = menu.Data(u8"score");
    CHECK(*scored.TryGet<core::f64>() >= 20.0);

    // Escape pauses: the pause screen over the HUD, the game's clock standing still.
    menu.Key(gui::KeyCode::Escape);
    REQUIRE(menu.stack->Count() == 2u);
    CHECK(menu.stack->IsPaused());
    CHECK(menu.Focused() == SV(u8"resume"));
    const core::String clock(core::StringView(*menu.Data(u8"clock").TryGet<core::String>()));
    menu.Frames(2.0);
    CHECK(*menu.Data(u8"clock").TryGet<core::String>() == clock.AsView());
    menu.D().InjectPadButton(gui::PadButton::Start); // Start resumes
    menu.Frame(0.0);
    CHECK(menu.stack->Count() == 1u);
    CHECK_FALSE(menu.stack->IsPaused());
    menu.Frames(2.0);
    CHECK(*menu.Data(u8"clock").TryGet<core::String>() != clock.AsView());

    // Paused again, To menu: the title, alone.
    menu.D().InjectPadButton(gui::PadButton::Start);
    menu.Frames(0.5);
    REQUIRE(menu.stack->IsPaused());
    menu.Choose(u8"to-menu");
    CHECK(menu.stack->Count() == 1u);
    CHECK(menu.StageShown());
    CHECK(menu.Find(*menu.stack->Top(), SV(u8"play")) != nullptr);
    CHECK(menu.errors.count == 0);
}
#endif // OPTION_HAS_ANGELSCRIPT
