// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - :controller partition: DockController, a layout and the panels it places (D3 of
// Specs/gui-lab-evolution-3.md).
//
// Panels are registered by id with a description: the title and icon their tab shows, a factory
// for their content, what closing them does, whether they can be closed, and where they go when a
// restored layout does not place them. The controller owns each panel's content once made, so a
// panel moved to another stack or window, or hidden, keeps it (foundation.ui's port destroyed a
// panel that had no id on close and crashed reaching it after). Closing a panel follows its policy:
// Hide keeps its content and its place, Rebuild lets its content go and keeps its place (the
// factory makes it again when shown), Destroy lets both go.
//
// The layout changes through the controller, which tells every DockSpace showing it to show it
// again. What the user already did in the widgets (a separator dragged, a tab chosen or dragged to
// another place in its strip) is noted into the layout quietly: the widgets already show it.

module;
#include "Core/Prelude.h"

export module foundation.gui.docking:controller;

import foundation.core;
import foundation.gui; // Node
import :layout;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    enum class DockClosePolicy : u8
    {
        Hide,    ///< content kept, place kept
        Rebuild, ///< content let go, place kept: made again when shown
        Destroy, ///< content and place let go
    };

    struct DockPanelDescription
    {
        String Id;
        String Title; ///< its tab's text (the id when empty)
        String Icon;  ///< its tab's icon, by path
        Function<RefPtr<Node>()> Factory;
        DockClosePolicy Close = DockClosePolicy::Hide;
        bool Closable = true;
        DockDefault Default; ///< where it goes when a restored layout does not place it (its Panel: the id)
    };

    /// What shows a controller's layout: told to show it again when it changed.
    class IDockView
    {
    public:
        virtual ~IDockView() = default;
        virtual void ShowLayout() = 0;
        /// The panel a page it shows is for; null for a page it does not show.
        [[nodiscard]] virtual const String* PanelOf(const Node& page) const = 0;
    };

    /// Where a dragged panel goes when dropped (D4): into a stack's strip at a tab's place, into a
    /// stack (its middle), beside a stack (its edge band) or along a whole surface's edge.
    enum class DockDropKind : u8
    {
        Tab,
        Middle,
        Beside,
        Edge,
    };
    struct DockDrop
    {
        DockDropKind Kind = DockDropKind::Middle;
        DockNodeId Stack = kNoDock;      ///< Tab, Middle, Beside: the stack dropped on
        DockSurfaceId Surface = kNoDock; ///< Edge: the surface
        i32 Index = -1;                  ///< Tab: its place among the stack's tabs, as they are now
        DockSide Side = DockSide::Start; ///< Beside, Edge
    };
    /// A docked panel dropped: the move it is, done on `layout` (a copy, to preview it and say why
    /// not, or the controller's).
    /// What a dock drag carries: a docked panel (a tab torn out), a whole floating surface (a
    /// float dragged by its title, D5) or a whole stack (its strip's grip).
    struct DockDragged
    {
        String Panel;
        DockSurfaceId Surface = kNoDock;
        DockNodeId Stack = kNoDock;
        [[nodiscard]] bool IsSurface() const noexcept { return Surface != kNoDock; }
        [[nodiscard]] bool IsStack() const noexcept { return Stack != kNoDock; }
    };
    /// The drag type of a whole floating surface; its value the surface's id.
    inline constexpr const char8_t* kDockSurfaceDragType = u8"gui/dock-surface";
    /// The drag type of a whole stack; its value the stack's id.
    inline constexpr const char8_t* kDockStackDragType = u8"gui/dock-stack";

    inline DockOutcome ApplyDrop(DockLayout& layout, core::StringView panel, const DockDrop& drop)
    {
        switch (drop.Kind)
        {
        case DockDropKind::Tab:
        {
            i32 index = drop.Index;
            // Among its own tabs: counted with it where it is, so a place past it is one less.
            if (const DockNode* stack = layout.FindNode(drop.Stack); stack != nullptr && layout.StackOf(panel) == drop.Stack)
                for (usize i = 0; i < stack->Panels.Size(); ++i)
                    if (stack->Panels[i].AsView() == panel && index > static_cast<i32>(i))
                        --index;
            return layout.MoveToTab(panel, drop.Stack, index);
        }
        case DockDropKind::Middle: return layout.MoveToTab(panel, drop.Stack);
        case DockDropKind::Beside: return layout.MoveBeside(panel, drop.Stack, drop.Side);
        case DockDropKind::Edge: return layout.MoveToEdge(panel, drop.Surface, drop.Side);
        }
        return DockOutcome::Refuse(u8"no such drop");
    }
    /// A drop of what a drag carries: a panel as above; a floating surface docked whole (into the
    /// stack over its strip or its middle, beside it, along the surface's edge); a stack moved whole
    /// the same ways (at a tab's place over a strip).
    inline DockOutcome ApplyDrop(DockLayout& layout, const DockDragged& dragged, const DockDrop& drop)
    {
        if (dragged.IsStack())
            switch (drop.Kind)
            {
            case DockDropKind::Tab: return layout.MoveStackInto(dragged.Stack, drop.Stack, drop.Index);
            case DockDropKind::Middle: return layout.MoveStackInto(dragged.Stack, drop.Stack);
            case DockDropKind::Beside: return layout.MoveStackBeside(dragged.Stack, drop.Stack, drop.Side);
            case DockDropKind::Edge: return layout.MoveStackToEdge(dragged.Stack, drop.Surface, drop.Side);
            }
        if (!dragged.IsSurface())
            return ApplyDrop(layout, dragged.Panel.AsView(), drop);
        switch (drop.Kind)
        {
        case DockDropKind::Tab:
        case DockDropKind::Middle: return layout.DockSurfaceInto(dragged.Surface, drop.Stack);
        case DockDropKind::Beside: return layout.DockSurfaceBeside(dragged.Surface, drop.Stack, drop.Side);
        case DockDropKind::Edge: return layout.DockSurfaceAtEdge(dragged.Surface, drop.Surface, drop.Side);
        }
        return DockOutcome::Refuse(u8"no such drop");
    }
    /// The panels a drag carries, as `layout` has them (a surface's, in its stacks' order).
    [[nodiscard]] inline Array<String> PanelsOf(const DockLayout& layout, const DockDragged& dragged)
    {
        Array<String> out;
        if (dragged.IsStack())
        {
            if (const DockNode* stack = layout.FindNode(dragged.Stack))
                for (const String& panel : stack->Panels)
                    out.PushBack(panel);
            return out;
        }
        if (!dragged.IsSurface())
        {
            out.PushBack(dragged.Panel);
            return out;
        }
        for (const DockNode& node : layout.Nodes())
            if (node.IsStack() && layout.SurfaceOf(node.Id) == dragged.Surface)
                for (const String& panel : node.Panels)
                    out.PushBack(panel);
        return out;
    }

    class DockController
    {
    public:
        explicit DockController(IAllocator& allocator) noexcept : m_panels(allocator), m_contents(allocator), m_views(allocator) {}
        DockController(const DockController&) = delete;
        DockController& operator=(const DockController&) = delete;

        /// A panel the layout may place; false when its id is empty or taken.
        bool Register(DockPanelDescription description)
        {
            if (description.Id.IsEmpty() || Describe(description.Id.AsView()) != nullptr)
                return false;
            description.Default.Panel = description.Id;
            m_panels.PushBack(core::Move(description));
            ShowEverywhere(); // a placeholder for it may show it now
            return true;
        }
        [[nodiscard]] const DockPanelDescription* Describe(core::StringView panel) const noexcept
        {
            for (const DockPanelDescription& description : m_panels)
                if (description.Id.AsView() == panel)
                    return &description;
            return nullptr;
        }

        [[nodiscard]] const DockLayout& GetLayout() const noexcept { return m_layout; }
        /// Changes the layout through `edit`; when it did something, every view shows it.
        DockOutcome Edit(const Function<DockOutcome(DockLayout&)>& edit)
        {
            DockOutcome outcome = edit(m_layout);
            if (outcome.Ok())
                ShowEverywhere();
            return outcome;
        }
        /// Closes a docked panel as its description says.
        DockOutcome Close(core::StringView panel)
        {
            const DockPanelDescription* description = Describe(panel);
            if (description != nullptr && !description->Closable)
                return DockOutcome::Refuse(u8"it cannot be closed");
            DockOutcome outcome = m_layout.Close(panel);
            if (!outcome.Ok())
                return outcome;
            const DockClosePolicy policy = description != nullptr ? description->Close : DockClosePolicy::Hide;
            if (policy != DockClosePolicy::Hide)
                ForgetContent(panel);
            if (policy == DockClosePolicy::Destroy)
                (void)m_layout.Forget(panel);
            ShowEverywhere();
            return outcome;
        }
        /// Shows a registered panel: where it was closed, else at its default place.
        DockOutcome Show(core::StringView panel)
        {
            if (m_layout.StackOf(panel) != kNoDock)
                return DockOutcome::Refuse(u8"it is docked");
            if (m_layout.FindHidden(panel) != nullptr)
                return Edit([panel](DockLayout& layout) { return layout.Show(panel); });
            const DockPanelDescription* description = Describe(panel);
            if (description == nullptr)
                return DockOutcome::Refuse(u8"it is not registered");
            const DockDefault where = description->Default;
            return Edit(
                [panel, where](DockLayout& layout)
                {
                    return where.Central ? layout.InsertTab(panel, layout.CentralStack())
                                         : layout.InsertAtEdge(panel, layout.MainSurface(), where.Side, where.Share);
                });
        }
        /// A restored layout taken (DockLayout::Adopt with the registered panels' default places).
        DockOutcome Adopt(DockLayout read, Span<const Rectangle> screens = {})
        {
            Array<DockDefault> defaults;
            for (const DockPanelDescription& description : m_panels)
                defaults.PushBack(description.Default);
            DockOutcome outcome = m_layout.Adopt(core::Move(read), Span<const DockDefault>(defaults.Data(), defaults.Size()), screens);
            if (outcome.Ok())
                ShowEverywhere();
            return outcome;
        }

        /// A registered panel's content: made by its factory the first time it is asked for, kept
        /// after; null for a panel not registered (or one whose factory makes none).
        RefPtr<Node> Content(core::StringView panel)
        {
            for (const Made& made : m_contents)
                if (made.Panel.AsView() == panel)
                    return made.Content;
            const DockPanelDescription* description = Describe(panel);
            if (description == nullptr || !description->Factory)
                return {};
            RefPtr<Node> content = description->Factory();
            if (content)
                m_contents.PushBack(Made{String(panel), content});
            return content;
        }
        /// Whether a panel's content is made (and kept).
        [[nodiscard]] bool HasContent(core::StringView panel) const noexcept
        {
            for (const Made& made : m_contents)
                if (made.Panel.AsView() == panel)
                    return true;
            return false;
        }

        // === What the widgets already show, noted quietly ===
        void NoteWeights(DockNodeId split, Span<const f32> weights) { (void)m_layout.SetWeights(split, weights); }
        void NoteActive(core::StringView panel) { (void)m_layout.Activate(panel); }
        void NoteTabPlace(core::StringView panel, DockNodeId stack, i32 index) { (void)m_layout.MoveToTab(panel, stack, index); }
        void NoteSurfaceBounds(DockSurfaceId surface, Rectangle bounds)
        {
            if (const DockSurface* found = m_layout.FindSurface(surface))
            {
                const String screen = found->Screen;
                (void)m_layout.SetSurfaceBounds(surface, bounds, screen.AsView(), found->Scale);
            }
        }

        /// The panel a page some view shows is for (a dragged tab's); null when none shows it.
        [[nodiscard]] const String* PanelShownBy(const Node& page) const
        {
            for (const IDockView* view : m_views)
                if (const String* panel = view->PanelOf(page))
                    return panel;
            return nullptr;
        }

        // === The views ===
        void AddView(IDockView& view)
        {
            for (IDockView* known : m_views)
                if (known == &view)
                    return;
            m_views.PushBack(&view);
        }
        void RemoveView(IDockView& view)
        {
            for (usize i = 0; i < m_views.Size(); ++i)
                if (m_views[i] == &view)
                {
                    m_views.RemoveAt(i);
                    if (m_showing && static_cast<i64>(i) <= m_showAt)
                        --m_showAt; // the pass goes on with the view that took its place
                    return;
                }
        }

    private:
        struct Made
        {
            String Panel;
            RefPtr<Node> Content;
        };
        void ForgetContent(core::StringView panel)
        {
            for (usize i = 0; i < m_contents.Size(); ++i)
                if (m_contents[i].Panel.AsView() == panel)
                {
                    m_contents[i].Content->RemoveFromParent();
                    m_contents.RemoveAt(i);
                    return;
                }
        }
        // Each view shows the layout. A view may make or end others as it does (a floating surface's
        // window and its dock space): one made joins the pass, one ended leaves it; a change asked
        // for during the pass runs it again after.
        void ShowEverywhere()
        {
            if (m_showing)
            {
                m_showAgain = true;
                return;
            }
            m_showing = true;
            do
            {
                m_showAgain = false;
                for (m_showAt = 0; m_showAt < static_cast<i64>(m_views.Size()); ++m_showAt)
                    m_views[static_cast<usize>(m_showAt)]->ShowLayout();
            } while (m_showAgain);
            m_showing = false;
        }

        DockLayout m_layout;
        Array<DockPanelDescription> m_panels;
        Array<Made> m_contents;
        Array<IDockView*> m_views;
        bool m_showing = false;   // a pass of ShowEverywhere is on
        bool m_showAgain = false; // the layout changed during it
        i64 m_showAt = 0;         // the view it is at
    };
}
