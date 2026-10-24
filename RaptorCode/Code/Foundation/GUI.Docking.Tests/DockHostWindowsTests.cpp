// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - a DockArea's floats in OS windows on foundation.gui's host (D6 of
// Specs/gui-lab-evolution-3.md), on the Null RHI backend and the null shell: a float opens a window
// of its own at its bounds, titled, its content a root of the host's GUI; retitled and placed as the
// layout has it; the user's moves come back to the layout and the window's close closes its panels;
// where the shell's windows hold no place, a window opens where the system puts it.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.rhi;
import foundation.shell;
import foundation.shell.null;
import foundation.graphics;
import foundation.graphics.null;
import foundation.gui;
import foundation.gui.hosting;
import foundation.gui.docking;

using namespace foundation::core;
using namespace foundation::gui;
namespace rhi = foundation::rhi;
namespace shell = foundation::shell;
namespace graphics = foundation::graphics;

namespace
{
    StringView SV(const char8_t* s) { return StringView(s); }

    rhi::ShaderModule* MakeModule(rhi::Device& d)
    {
        const u8 dummy[4] = {0, 0, 0, 0};
        rhi::ShaderModuleDesc desc{};
        desc.code = Span<const u8>(dummy, 4);
        desc.entryPoint = u8"main";
        rhi::ShaderModule* m = nullptr;
        (void)d.CreateShaderModule(desc, m);
        return m;
    }

    // A host on the null device and shell, its main window's root holding a DockArea of the profiler
    // and the memory panels; the application's opener makes null windows.
    struct Bed
    {
        shell::NullShell shell;
        UniquePtr<graphics::GraphicsDevice> device = graphics::CreateNullGraphicsDevice(2).Value();
        rhi::ShaderModule* vs = MakeModule(*device->Raw());
        rhi::ShaderModule* fs = MakeModule(*device->Raw());
        UniquePtr<graphics::RenderWindow> main = device->CreateRenderWindow(*shell.MainWindow(), graphics::RenderWindowDesc{}).Value();
        UniquePtr<GuiHost> host;
        Array<UniquePtr<graphics::RenderWindow>> opened;
        int closed = 0;
        DockController controller{DefaultAllocator()};
        RefPtr<SceneRoot> root;
        RefPtr<DockArea> area;

        Bed()
        {
            VgShaderSet shaders;
            shaders.Vertex = vs;
            shaders.Fragment = fs;
            host = MakeUnique<GuiHost>(DefaultAllocator(), DefaultAllocator(), *device, shell, nullptr, shaders);
            GuiHost::WindowOpener opener;
            opener.Open = [this](const shell::WindowSettings& settings) -> graphics::RenderWindow*
            {
                Result<shell::IWindow*> made = Windows().CreateWindow(settings);
                if (!made.HasValue())
                    return nullptr;
                opened.PushBack(device->CreateRenderWindow(*made.Value(), graphics::RenderWindowDesc{}).Value());
                return opened.Back().Get();
            };
            opener.Close = [this](graphics::RenderWindow& window)
            {
                ++closed;
                Windows().DestroyWindow(&window.Window());
            };
            host->SetWindowOpener(Move(opener));
            const char8_t* const ids[] = {u8"profiler", u8"memory"};
            const char8_t* const titles[] = {u8"Profiler", u8"Memory"};
            for (usize i = 0; i < 2; ++i)
            {
                DockPanelDescription description;
                description.Id = String(ids[i]);
                description.Title = String(titles[i]);
                description.Factory = []() { return RefPtr<Node>(MakeRef<Panel>(DefaultAllocator())); };
                REQUIRE(controller.Register(Move(description)));
            }
            root = MakeRef<SceneRoot>(DefaultAllocator(), host->ContextRef());
            area = MakeRef<DockArea>(DefaultAllocator());
            area->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Percent(100.0f);
                s.Height = LayoutLength::Percent(100.0f);
            });
            root->AddChild(area.Get());
            host->AttachWindow(*main, root);
            area->Show(controller);
        }
        ~Bed()
        {
            area.Reset();
            root.Reset();
            host.Reset();
            opened.Clear();
            main.Reset();
            device->Raw()->DestroyShaderModule(fs);
            device->Raw()->DestroyShaderModule(vs);
        }
        shell::NullWindowManager& Windows() { return *static_cast<shell::NullWindowManager*>(shell.WindowManager()); }
        void Frame()
        {
            host->Update(1.0f / 60.0f);
            device->AdvanceFrame();
        }
    };
}

TEST_CASE("dock host windows: a float opens a window of its own at its bounds, titled; placed and retitled as the layout has it; moved and closed by the user")
{
    Bed bed;
    DockSurfaceId floating = kNoDock;
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.Float(SV(u8"profiler"), Rectangle{100.0f, 80.0f, 300.0f, 200.0f}, &floating); }).Ok());
    bed.Frame();
    {
        DockHostWindows windows(DefaultAllocator(), *bed.host, *bed.area);
        REQUIRE(windows.CanOpen());
        const SceneRoot* made = nullptr;
        windows.SetOnRootMade([&](SceneRoot& root) { made = &root; });
        bed.area->SetWindows(&windows);
        REQUIRE(bed.host->WindowCount() == 2u);
        SceneRoot* root = windows.RootOf(floating);
        REQUIRE(root != nullptr);
        graphics::RenderWindow* window = bed.host->WindowFor(root);
        REQUIRE(window != nullptr);
        auto& os = static_cast<shell::NullWindow&>(window->Window());
        // The main window is at the screen's origin: the area's 100,80 is the screen's.
        CHECK(os.X() == 100);
        CHECK(os.Y() == 80);
        CHECK(os.Width() == 300u);
        CHECK(os.Title() == SV(u8"Profiler"));
        CHECK(bed.area->WindowSpaceOf(floating)->GetRootNode() == root);
        CHECK(made == root); // told, to style it
        bed.Frame();

        // Another panel in it: retitled. The layout moving it: placed there.
        REQUIRE(bed.controller.Edit([](DockLayout& l) { return l.InsertTab(SV(u8"memory"), l.StackOf(SV(u8"profiler"))); }).Ok());
        CHECK(os.Title() == SV(u8"Memory +1"));
        bed.controller.NoteSurfaceBounds(floating, Rectangle{400.0f, 300.0f, 320.0f, 240.0f});
        bed.area->ShowLayout();
        CHECK(os.X() == 400);
        CHECK(os.Height() == 240u);

        // Moved by the user (the system moves it): the layout hears where it is.
        os.SetPosition(500, 350);
        bed.Windows().PostEvent(shell::WindowEvent{shell::WindowEventType::Moved, os.Id(), 0, 0, 500, 350});
        bed.Frame();
        bed.Windows().ClearEvents();
        CHECK(bed.controller.GetLayout().FindSurface(floating)->Bounds.x == doctest::Approx(500.0f));

        // Its close button: its panels close, and the window with its surface.
        bed.Windows().PostEvent(shell::WindowEvent{shell::WindowEventType::CloseRequested, os.Id()});
        bed.Frame();
        bed.Windows().ClearEvents();
        CHECK(bed.controller.GetLayout().FindSurface(floating) == nullptr);
        CHECK(bed.controller.GetLayout().StackOf(SV(u8"profiler")) == kNoDock);
        CHECK(bed.closed == 1);
        CHECK(bed.host->WindowCount() == 1u);
        bed.area->SetWindows(nullptr);
    }
}

TEST_CASE("dock host windows: where the shell's windows hold no place, a float's window opens where the system puts it")
{
    Bed bed;
    bed.Windows().SetCapabilities(shell::WindowCapabilities{true, false}); // as Wayland is
    DockSurfaceId floating = kNoDock;
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.Float(SV(u8"profiler"), Rectangle{100.0f, 80.0f, 300.0f, 200.0f}, &floating); }).Ok());
    bed.Frame();
    DockHostWindows windows(DefaultAllocator(), *bed.host, *bed.area);
    bed.area->SetWindows(&windows);
    SceneRoot* root = windows.RootOf(floating);
    REQUIRE(root != nullptr);
    const shell::IWindow& os = bed.host->WindowFor(root)->Window();
    CHECK(os.X() == 0); // not positioned: where the system puts it (the null shell's origin)
    CHECK(os.Width() == 300u);
    // Its place is not known: the layout keeps its size alone.
    CHECK(bed.controller.GetLayout().FindSurface(floating)->Bounds.x == doctest::Approx(0.0f));
    CHECK(bed.controller.GetLayout().FindSurface(floating)->Bounds.width == doctest::Approx(300.0f));
    bed.area->SetWindows(nullptr);
    CHECK(bed.host->WindowCount() == 1u);
}
