// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - :dock_host_windows partition
//
// DockHostWindows: a DockArea's floats as OS windows (D6 of Specs/gui-lab-evolution-3.md), on the
// GUI's host. Each floating surface's content goes in a root of the host's GUI, in a window the host
// opens for it (through the application's opener), with the platform's own frame (the user's
// ruling): the system moves, sizes and snaps it. Where the shell's windows hold the places given
// them, a window opens at its surface's bounds and is placed again when the layout moves it; where
// they do not (Wayland), it opens of its size where the system puts it. What the user does to a
// window comes back to the area: moved or resized, its bounds (on screen); its close button, its
// panels closed as their policies say.

module;
#include "Core/Prelude.h"

export module foundation.gui.docking:dock_host_windows;

import foundation.core;
import foundation.shell;
import foundation.graphics;
import foundation.gui;
import foundation.gui.hosting;
import :layout;
import :dock_area;

using namespace foundation::core;
namespace core = foundation::core;
namespace shell = foundation::shell;
namespace graphics = foundation::graphics;

export namespace foundation::gui
{
    class DockHostWindows final : public IDockWindows
    {
    public:
        /// The floats of `area` in windows `host` opens; both outlive it. Give it to the area with
        /// DockArea::SetWindows, and take it back (SetWindows(nullptr)) before it goes.
        DockHostWindows(IAllocator& allocator, GuiHost& host, DockArea& area)
            : m_allocator(allocator), m_host(host), m_area(area), m_windows(allocator)
        {
            DockHostWindows* self = this;
            m_listener = host.AddWindowEventListener([self](SceneRoot& root, const shell::WindowEvent& event) { self->Heard(root, event); });
        }
        ~DockHostWindows() override
        {
            m_host.RemoveWindowEventListener(m_listener);
            while (!m_windows.IsEmpty())
                Close(m_windows.Back().Surface);
        }
        DockHostWindows(const DockHostWindows&) = delete;
        DockHostWindows& operator=(const DockHostWindows&) = delete;

        /// Whether it opens windows at all (an opener, and a shell that opens more than one): an
        /// application gives the area its floats as windows only then.
        [[nodiscard]] bool CanOpen() const noexcept { return m_host.CanOpenWindows(); }
        /// Told of each window's root as it is made, before its window opens: an application styles
        /// it as the page the area is on (a sheet scoped to that page reaches no other root).
        void SetOnRootMade(Function<void(SceneRoot& root)> made) { m_onRootMade = core::Move(made); }
        /// The root a floating surface's window shows; null when it shows none.
        [[nodiscard]] SceneRoot* RootOf(DockSurfaceId surface) const noexcept
        {
            for (const Shown& shown : m_windows)
                if (shown.Surface == surface)
                    return shown.Root.Get();
            return nullptr;
        }

        bool Open(DockSurfaceId surface, Node& content, const Rectangle& bounds, core::StringView title) override
        {
            RefPtr<SceneRoot> root = MakeRef<SceneRoot>(m_allocator, m_host.ContextRef());
            root->AddChild(&content);
            if (m_onRootMade)
                m_onRootMade(*root);
            const String text(title);
            shell::WindowSettings settings;
            settings.title = text.AsView();
            settings.width = static_cast<u32>(Max(1.0f, bounds.width));
            settings.height = static_cast<u32>(Max(1.0f, bounds.height));
            settings.positioned = m_host.PlacesWindows();
            settings.x = static_cast<i32>(bounds.x);
            settings.y = static_cast<i32>(bounds.y);
            settings.resizable = true;
            if (m_host.OpenWindow(root, settings) == nullptr)
            {
                root->RemoveAllChildren(); // its content goes back to the area
                return false;
            }
            m_windows.PushBack(Shown{surface, root});
            return true;
        }
        void Close(DockSurfaceId surface) override
        {
            for (usize i = 0; i < m_windows.Size(); ++i)
                if (m_windows[i].Surface == surface)
                {
                    const RefPtr<SceneRoot> root = m_windows[i].Root;
                    m_windows.RemoveAt(i);
                    m_host.CloseWindow(*root);
                    root->RemoveAllChildren(); // the content may show again (in the area)
                    return;
                }
        }
        void Place(DockSurfaceId surface, const Rectangle& bounds) override
        {
            shell::IWindow* window = WindowOf(surface);
            if (window == nullptr)
                return;
            if (m_host.PlacesWindows())
                window->SetPosition(static_cast<i32>(bounds.x), static_cast<i32>(bounds.y));
            window->SetSize(static_cast<u32>(Max(1.0f, bounds.width)), static_cast<u32>(Max(1.0f, bounds.height)));
        }
        void SetTitle(DockSurfaceId surface, core::StringView title) override
        {
            if (shell::IWindow* window = WindowOf(surface))
                window->SetTitle(title);
        }
        void Raise(DockSurfaceId surface) override
        {
            if (shell::IWindow* window = WindowOf(surface))
                window->Raise();
        }
        bool ToScreen(const Node& node, core::Float2 local, core::Float2& screen) override
        {
            const SceneRoot* root = Cast<SceneRoot>(const_cast<Node&>(node).GetRootNode());
            return root != nullptr && m_host.ToScreen(*root, node.ConvertToWorldSpace(local), screen);
        }

    private:
        struct Shown
        {
            DockSurfaceId Surface = kNoDock;
            RefPtr<SceneRoot> Root;
        };
        [[nodiscard]] shell::IWindow* WindowOf(DockSurfaceId surface) noexcept
        {
            SceneRoot* root = RootOf(surface);
            graphics::RenderWindow* window = root != nullptr ? m_host.WindowFor(root) : nullptr;
            return window != nullptr ? &window->Window() : nullptr;
        }
        // A window's event, by its root: a float's window moved or resized, or its close asked for.
        void Heard(SceneRoot& root, const shell::WindowEvent& event)
        {
            DockSurfaceId surface = kNoDock;
            for (const Shown& shown : m_windows)
                if (shown.Root.Get() == &root)
                    surface = shown.Surface;
            if (surface == kNoDock)
                return; // not a float's
            switch (event.type)
            {
            case shell::WindowEventType::Moved:
            case shell::WindowEventType::Resized:
                if (shell::IWindow* window = WindowOf(surface))
                {
                    const bool placed = m_host.PlacesWindows(); // else its place is not known
                    m_area.NoteWindowBounds(surface, Rectangle{placed ? static_cast<f32>(window->X()) : 0.0f, placed ? static_cast<f32>(window->Y()) : 0.0f,
                                                               static_cast<f32>(window->Width()), static_cast<f32>(window->Height())});
                }
                break;
            case shell::WindowEventType::CloseRequested:
                m_area.CloseFloat(surface); // its panels as their policies say; the window goes with the surface
                break;
            default:
                break;
            }
        }

        IAllocator& m_allocator;
        GuiHost& m_host;
        DockArea& m_area;
        Array<Shown> m_windows;
        Function<void(SceneRoot&)> m_onRootMade;
        u32 m_listener = 0;
    };
}
