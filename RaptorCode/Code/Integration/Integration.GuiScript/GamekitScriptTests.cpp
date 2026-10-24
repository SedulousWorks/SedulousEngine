// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// foundation.gui.gamekit - the screen stack's script surface (K4 of
// Specs/gui-lab-evolution-3.md) exercised end-to-end on both backends: a script makes a stack,
// pushes a node and a document, reads the top's covering and the pause, hears a screen leave and
// pops. The gamekit's own suite stays backend-neutral.
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.image;
import foundation.vg.svg;
import foundation.script;
import foundation.gui;
import foundation.gui.gamekit;
#ifdef OPTION_HAS_ANGELSCRIPT
import foundation.script.angelscript;
#endif
#ifdef OPTION_HAS_LUAU
import foundation.script.luau;
#endif

namespace gui = foundation::gui;
namespace core = foundation::core;
namespace script = foundation::script;

namespace
{
    // The one document a script pushes: a covering, pausing screen.
    class Documents final : public gui::IResourceProvider
    {
    public:
        Documents() : IResourceProvider(core::DefaultAllocator()) {}
        const foundation::image::ImageData* LoadImage(core::StringView) override { return nullptr; }
        bool LoadText(core::StringView path, core::String& out) override
        {
            if (path != core::StringView(u8"pause.xml"))
                return false;
            out = core::String(u8"<Screen pauses=\"true\" covers=\"true\"><Button id=\"resume\"/></Screen>");
            return true;
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

    // Runs `source` against a GUI the script finds as gui.root(), then the story's checks: the
    // script has made a stack under the root and pushed a node and pause.xml, listening for the
    // pause screen's `screenleave`; it offers count(), paused(), covers(), popIt() and left().
    void CheckStack(script::IScriptManager& manager, const char8_t* source)
    {
        core::RegisterCoreTypes();
        gui::RegisterGuiScriptSurface();
        gui::RegisterGamekitElements();
        script::RegisterReflectedTypes(manager);
        auto root = core::MakeRef<gui::SceneRoot>(core::DefaultAllocator(), core::MakeRef<gui::GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{400.0f, 300.0f});
        Documents documents;
        root->GetContext().SetResourceProvider(&documents);
        gui::GuiScriptBinding binding;
        binding.root = root.Get();
        core::RefPtr<script::IScriptContext> context = manager.CreateContext();
        Errors errors;
        context->SetErrorHandler(&errors);
        gui::InstallGuiScriptService(*context, binding);
        const core::Status loaded = context->Load(source, u8"main");
        INFO(doctest::String(reinterpret_cast<const char*>(errors.last.CStr())));
        REQUIRE(loaded.IsOk());
        const auto number = [&](const char8_t* function)
        {
            core::Result<core::Variant> result = context->Call(function, core::Span<core::Variant>{});
            INFO(doctest::String(reinterpret_cast<const char*>(errors.last.CStr())));
            REQUIRE(result.HasValue());
            const double* value = result.Value().TryGet<double>();
            REQUIRE(value != nullptr);
            return *value;
        };
        CHECK(number(u8"count") == doctest::Approx(2.0));
        CHECK(number(u8"paused") == doctest::Approx(1.0));
        CHECK(number(u8"covers") == doctest::Approx(1.0));
        CHECK(number(u8"popIt") == doctest::Approx(1.0));
        CHECK(number(u8"count") == doctest::Approx(1.0));
        CHECK(number(u8"paused") == doctest::Approx(0.0));
        CHECK(number(u8"left") == doctest::Approx(1.0));
        CHECK(errors.count == 0);
        gui::ClearGuiScriptService(*context);
        context->SetErrorHandler(nullptr);
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gamekit script: AngelScript pushes, reads and pops screens, and hears one leave")
{
    core::RefPtr<script::IScriptManager> manager = script::angelscript::CreateScriptManager(core::DefaultAllocator());
    CheckStack(*manager,
               u8"funcdef bool EventHandler(GuiEvent e);\n"
               u8"ScreenStack@ stack;\n"
               u8"double leaves = 0;\n"
               u8"bool onLeave(GuiEvent e) { leaves += 1; return false; }\n"
               u8"void main() {\n"
               u8"  Node@ root = gui::root();\n"
               u8"  @stack = ScreenStack::of(root.add(\"Screens\"));\n"
               u8"  stack.pushNode(root.add(\"Panel\"));\n"
               u8"  Screen@ pause = stack.push(\"pause.xml\");\n"
               u8"  pause.on(\"screenleave\", EventHandler(onLeave));\n"
               u8"}\n"
               u8"double count() { return stack.count(); }\n"
               u8"double paused() { return stack.isPaused() ? 1 : 0; }\n"
               u8"double covers() { return stack.top().covers ? 1 : 0; }\n"
               u8"double popIt() { return stack.pop() ? 1 : 0; }\n"
               u8"double left() { return leaves; }\n");
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gamekit script: Luau pushes, reads and pops screens, and hears one leave")
{
    core::RefPtr<script::IScriptManager> manager = script::CreateLuauScriptManager(core::DefaultAllocator());
    CheckStack(*manager,
               u8"local root = gui.root()\n"
               u8"local stack = ScreenStack.of(root:add(\"Screens\"))\n"
               u8"local leaves = 0\n"
               u8"stack:pushNode(root:add(\"Panel\"))\n"
               u8"local pause = stack:push(\"pause.xml\")\n"
               u8"pause:on(\"screenleave\", function(e) leaves = leaves + 1; return false end)\n"
               u8"function count() return stack:count() end\n"
               u8"function paused() return stack:isPaused() and 1 or 0 end\n"
               u8"function covers() return Screen.of(stack:top()).covers and 1 or 0 end\n"
               u8"function popIt() return stack:pop() and 1 or 0 end\n"
               u8"function left() return leaves end\n");
}
#endif
