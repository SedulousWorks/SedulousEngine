// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// engine.gui - the engine's GUI from a script (E8 of Specs/gui-lab-evolution-3.md), on both
// backends: the surface the GUI domain registers, installed in a script context by the subsystem;
// `gui::root()` is the screen tier's root, its `screens` the gamekit's stack, which pushes a cooked
// document by its asset guid through the engine's resource provider. Engine.GUI's own suite stays
// backend-neutral.
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.vfs;
import foundation.runtime;
import foundation.content;
import foundation.resource;
import foundation.script;
import foundation.script.facades; // the base behaviour facades (Entity, which a component's `of` takes)
import foundation.gui;
import foundation.gui.gamekit;
import foundation.gui.resources;
import engine.gui;
#ifdef OPTION_HAS_ANGELSCRIPT
import foundation.script.angelscript;
#endif
#ifdef OPTION_HAS_LUAU
import foundation.script.luau;
#endif

using namespace foundation::gui;
namespace core = foundation::core;
namespace script = foundation::script;
using namespace foundation::core;

namespace
{
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

    // A project holding one cooked document, the engine's GUI over it, and a script context the
    // subsystem gave its surface.
    struct Bed
    {
        String folder{u8"scratch_engine_gui_script"};
        UniquePtr<foundation::vfs::NativeFileSystem> mount;
        UniquePtr<foundation::content::ContentDatabase> db;
        GuiDocumentFactory documents{DefaultAllocator()};
        UniquePtr<foundation::resource::ResourceManager> resources;
        foundation::vfs::NativeFileSystem data{foundation::vfs::FindDataRoot(), DefaultAllocator()};
        foundation::runtime::Context context{DefaultAllocator()};
        engine::gui::GuiSubsystem* gui = nullptr;
        Guid menu;

        Bed()
        {
            RegisterGuiResource();
            Clean();
            mount = MakeUnique<foundation::vfs::NativeFileSystem>(DefaultAllocator(), folder.AsView(), DefaultAllocator());
            db = MakeUnique<foundation::content::ContentDatabase>(DefaultAllocator(), DefaultAllocator(), *mount, BinarySerializerFactory(), u8".rasset");
            auto* instance = db->RootGroup()->CreateInstance(u8"menu", GuiDocumentSource::StaticType());
            GuiDocumentSource source;
            source.markup = String(u8"<Screen pauses=\"true\"><Label id=\"status\" text=\"Ready\"/></Screen>");
            REQUIRE(instance->WriteObject(source).IsOk());
            menu = instance->Id();
            resources = MakeUnique<foundation::resource::ResourceManager>(DefaultAllocator(), DefaultAllocator(), *db);
            resources->AddFactory(&documents);
            gui = context.AddSubsystem<engine::gui::GuiSubsystem>(DefaultAllocator(), data);
            context.Startup();
            gui->SetResourceManager(resources.Get());
            core::RegisterCoreTypes();
            script::RegisterScriptFacadeReflection();
            engine::gui::RegisterGuiScriptFacades();
        }
        ~Bed()
        {
            gui->SetResourceManager(nullptr);
            context.Shutdown();
            resources.Reset();
            db.Reset();
            mount.Reset();
            Clean();
        }
        void Clean()
        {
            FileDelete(PathJoin(folder.AsView(), StringView(u8"menu.rasset")).AsView());
            RemoveDirectory(folder.AsView());
        }
        // The script's source with the document's guid where it says {MENU}.
        String WithMenu(StringView source) const
        {
            String braced(u8"{");
            braced.Append(Format(u8"{}", menu).AsView());
            braced.Append(StringView(u8"}"));
            String out;
            for (usize i = 0; i < source.Size();)
                if (source.SubStr(i, source.Size() - i).StartsWith(StringView(u8"{MENU}")))
                {
                    out.Append(braced.AsView());
                    i += 6;
                }
                else
                    out.PushBack(source[i++]);
            return out;
        }

        void Run(script::IScriptManager& manager, StringView source)
        {
            script::RegisterReflectedTypes(manager);
            RefPtr<script::IScriptContext> scripts = manager.CreateContext();
            Errors errors;
            scripts->SetErrorHandler(&errors);
            gui->ExposeToScript(*scripts);
            const String text = WithMenu(source);
            const Status loaded = scripts->Load(text.AsView(), u8"main");
            INFO(doctest::String(reinterpret_cast<const char*>(errors.last.CStr())));
            REQUIRE(loaded.IsOk());
            const auto number = [&](const char8_t* function)
            {
                Result<foundation::core::Variant> result = scripts->Call(function, Span<foundation::core::Variant>{});
                INFO(doctest::String(reinterpret_cast<const char*>(errors.last.CStr())));
                REQUIRE(result.HasValue());
                const double* value = result.Value().TryGet<double>();
                REQUIRE(value != nullptr);
                return *value;
            };
            CHECK(number(u8"isScreenRoot") == doctest::Approx(1.0)); // gui::root() is the screen tier's
            CHECK(number(u8"pushMenu") == doctest::Approx(1.0));     // the document by its guid
            CHECK(gui->Screens()->Count() == 1u);
            CHECK(gui->Screens()->IsPaused());
            CHECK(number(u8"hasStatus") == doctest::Approx(1.0));
            CHECK(errors.count == 0);
            ClearGuiScriptService(*scripts);
            scripts->SetErrorHandler(nullptr);
        }
    };
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("engine-gui-script: AngelScript finds the screen tier at gui::root() and pushes a cooked document by its guid")
{
    Bed bed;
    RefPtr<script::IScriptManager> manager = script::angelscript::CreateScriptManager(DefaultAllocator());
    bed.Run(*manager, StringView(u8"ScreenStack@ stack;\n"
                                 u8"Screen@ menu;\n"
                                 u8"void main() { @stack = ScreenStack::of(gui::root().find(\"screens\")); }\n"
                                 u8"double isScreenRoot() { return stack !is null ? 1 : 0; }\n"
                                 u8"double pushMenu() { @menu = stack.push(\"{MENU}\"); return menu !is null ? 1 : 0; }\n"
                                 u8"double hasStatus() { return menu.find(\"status\") !is null ? 1 : 0; }\n"));
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("engine-gui-script: Luau finds the screen tier at gui.root() and pushes a cooked document by its guid")
{
    Bed bed;
    RefPtr<script::IScriptManager> manager = script::CreateLuauScriptManager(DefaultAllocator());
    bed.Run(*manager, StringView(u8"local stack = ScreenStack.of(gui.root():find(\"screens\"))\n"
                                 u8"local menu = nil\n"
                                 u8"function isScreenRoot() return stack ~= nil and 1 or 0 end\n"
                                 u8"function pushMenu() menu = stack:push(\"{MENU}\"); return menu ~= nil and 1 or 0 end\n"
                                 u8"function hasStatus() return menu:find(\"status\") ~= nil and 1 or 0 end\n"));
}
#endif
