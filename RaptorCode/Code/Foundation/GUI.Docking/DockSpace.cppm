// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - :dock_space partition: DockSpace, the widget that shows one surface of a
// controller's layout (D3 of Specs/gui-lab-evolution-3.md).
//
// Its widgets are made from the layout, each kept by the id of the node it shows, so showing the
// layout again changes only what changed: a split is the core's Splitter (round three's ruling 6),
// a stack a TabView whose strip's group is `dock`, each panel a page whose content the controller
// makes the first time its tab is shown. A panel the layout names that is not registered shows a
// placeholder, filled when it is. A maximized stack is shown alone. What the user does in the
// widgets goes back into the layout: a separator dragged, a tab chosen or dragged to another place,
// a tab's close (through the controller, which closes it as its description says).
//
// Docking's default sheet (DockingSheetCSS) styles them through the theme's tokens: a theme or an
// application restyles docking by setting `--dock-*` (round three's ruling 4).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.docking:dock_space;

import foundation.core;
import foundation.gui;
import :layout;
import :controller;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// Docking's default sheet, written against the theme's tokens (an application puts it after the
    /// theme in its user agent sheet).
    [[nodiscard]] inline core::StringView DockingSheetCSS() noexcept
    {
        return core::StringView(u8R"(
            dockspace { background-color: var(--dock-background, var(--surface)); }
            tabview.dock-stack { background-color: var(--dock-stack-background, var(--panel)); }
            tabview.dock-central { background-color: var(--dock-central-background, var(--surface)); }
            label.dock-placeholder { color: var(--dock-placeholder, var(--muted)); padding: 16px; }
            dockspace { edge-band: var(--dock-edge, 64px); surface-band: var(--dock-surface-edge, 20px);
                        torn-tab: var(--dock-torn-tab, dim); }
            tab.dock-torn, tabview.dock-torn { opacity: var(--dock-torn-opacity, 0.45); }
            tabview.dock-stack tablist, tabview.dock-stack closeall { color: var(--dock-strip-button, var(--text-dim)); }
            tabview.dock-stack tablist:hover, tabview.dock-stack closeall:hover {
                background-color: var(--dock-strip-button-hover, var(--control-hover));
            }
            window.dock-float.dock-dragging { opacity: var(--dock-dragging-opacity, 0.6); }
            panel.dock-preview {
                background-color: var(--dock-preview, rgba(80, 150, 255, 0.25));
                border: 2px solid var(--dock-preview-border, var(--accent));
                border-radius: 4px;
            }
        )");
    }

    /// Docking's commands: `dock.focus-*` and `dock.move-*` (left, right, up, down) focus the stack
    /// that way, or move the focused stack's panel into it (past the surface's edge into what lies
    /// beyond it, in a DockArea; else along that edge); `dock.maximize` shows the focused stack alone
    /// or all again; `dock.close` closes its panel; `dock.move-to` opens the menu of where it may go
    /// (what a tab's context menu opens too, with Close); `dock.float` floats it. A DockSpace takes them for the
    /// stack the focus is in. `dock.next-surface` and `dock.previous-surface` take the focus to a
    /// DockArea's next surface (its main one, then its floats), to the stack last focused there.
    ///
    /// None is bound to a key: docking is the pointer's (a drag, Shift to float), and the keys a
    /// desktop leaves free differ (Ctrl+Alt and an arrow is GNOME's, Ctrl+Alt is AltGr on many
    /// layouts). The keyboard's way in is a tab's context menu (Shift+F10, the Menu key), which is
    /// Move to, and `drag.pick` (Ctrl+Shift+D); an application binds these where it wants keys, or
    /// shows them in a menu.
    inline void DefineDockingCommands(GUIContext& context)
    {
        struct Named
        {
            const char8_t* Id;
            const char8_t* Label;
        };
        static constexpr Named kCommands[] = {
            {u8"dock.focus-left", u8"Focus the Stack to the Left"},
            {u8"dock.focus-right", u8"Focus the Stack to the Right"},
            {u8"dock.focus-up", u8"Focus the Stack Above"},
            {u8"dock.focus-down", u8"Focus the Stack Below"},
            {u8"dock.move-left", u8"Move the Panel Left"},
            {u8"dock.move-right", u8"Move the Panel Right"},
            {u8"dock.move-up", u8"Move the Panel Up"},
            {u8"dock.move-down", u8"Move the Panel Down"},
            {u8"dock.maximize", u8"Maximize the Stack"},
            {u8"dock.close", u8"Close the Panel"},
            {u8"dock.move-to", u8"Move the Panel To..."},
            {u8"dock.float", u8"Float the Panel"},
            {u8"dock.next-surface", u8"Focus the Next Dock Surface"},
            {u8"dock.previous-surface", u8"Focus the Previous Dock Surface"},
        };
        for (const Named& named : kCommands)
            if (context.GetCommands().Find(core::StringView(named.Id)) == nullptr)
                context.DefineCommand(core::StringView(named.Id)).SetLabel(core::StringView(named.Label));
    }

    /// What a tab torn out of its stack leaves while it is dragged (DockSpace::SetTornTab).
    enum class DockTornTab : u8
    {
        Dim,   ///< it stays, dimmed (the default)
        Close, ///< its strip closes up, a neighbour's panel shown
    };

    /// A way on the screen, for the directional commands.
    enum class DockDirection : u8
    {
        Left,
        Right,
        Up,
        Down,
    };

    class DockSpace;

    /// What a DockSpace's keys and its Move to menu reach past its own surface: the other surfaces
    /// shown with it (a DockArea's main surface and its floats).
    class IDockSurroundings
    {
    public:
        virtual ~IDockSurroundings() = default;
        /// The stack of another surface past `stack`'s surface the way `way` goes (what lies just
        /// beyond its edge there); kNoDock when none does.
        [[nodiscard]] virtual DockNodeId StackBeyond(const DockSpace& from, DockNodeId stack, DockDirection way) const = 0;
        /// The stacks the other surfaces show, for the Move to menu.
        virtual void OtherStacks(const DockSpace& from, Array<DockNodeId>& out) const = 0;
        /// Focuses a stack any of them shows (its chosen tab); false when none does.
        virtual bool FocusStackAnywhere(DockNodeId stack) = 0;
    };

    /// A stack as a DockSpace shows it: a TabView whose drops are the layout's to decide (its
    /// middle tabs a dragged panel in, an edge band puts it beside).
    class DockStack : public TabView
    {
        RTTI_OBJECT(DockStack, TabView)
    public:
        DockStack(DockSpace& space, DockNodeId node) : m_space(&space), m_node(node)
        {
            // Its splitter gives it the room the user left it: a panel wider or taller than that
            // wraps or is clipped here, never spilling onto its neighbours.
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.OverflowX = Overflow::Hidden;
                s.OverflowY = Overflow::Hidden;
            });
            // A closable panel's close part on the chosen tab and the one hovered (as Visual Studio's
            // and Godot's docks show it), and a middle click closes one; a sheet's `close-display`
            // says otherwise.
            GetBar()->SetCloseDisplay(TabCloseDisplay::Hover);
            // Its strip's end, as Dear ImGui's: the list button always (clicked it lists the tabs,
            // dragged it carries the stack), and past it a cross closing every closable tab.
            GetBar()->SetListDisplay(TabListDisplay::Always);
            GetBar()->SetCloseAll(true);
        }
        [[nodiscard]] DockNodeId GetNode() const noexcept { return m_node; }
        [[nodiscard]] DockSpace* GetSpace() const noexcept { return m_space; }

    protected:
        void OnDragQuery(DropQuery& query) override;
        void OnDragLeave(const DragEvent& event) override;
        void OnDrop(const DragEvent& event) override;
        void OnContextMenu(const MouseEvent& event) override;

    private:
        DockSpace* m_space;
        DockNodeId m_node;
    };

    class DockSpace : public UIWidget, public IDockView
    {
        RTTI_OBJECT(DockSpace, UIWidget)
        friend class DockStack;
    public:
        DockSpace()
        {
            SetTag(core::StringView(u8"dockspace"));
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Column;
                s.AlignItems = Align::Stretch;
            });
            const struct
            {
                const char8_t* Id;
                DockDirection Way;
                bool Move;
            } directional[] = {
                {u8"dock.focus-left", DockDirection::Left, false},  {u8"dock.focus-right", DockDirection::Right, false},
                {u8"dock.focus-up", DockDirection::Up, false},      {u8"dock.focus-down", DockDirection::Down, false},
                {u8"dock.move-left", DockDirection::Left, true},    {u8"dock.move-right", DockDirection::Right, true},
                {u8"dock.move-up", DockDirection::Up, true},        {u8"dock.move-down", DockDirection::Down, true},
            };
            DockSpace* self = this;
            for (const auto& d : directional)
            {
                const DockDirection way = d.Way;
                if (d.Move)
                    (void)OnCommand(core::StringView(d.Id), [self, way](CommandEvent& e) { e.Propagate = !self->MoveFocused(way).Ok(); });
                else
                    (void)OnCommand(core::StringView(d.Id), [self, way](CommandEvent& e) { e.Propagate = !self->FocusToward(way); });
            }
            (void)OnCommand(core::StringView(u8"dock.maximize"), [self](CommandEvent& e) { e.Propagate = !self->ToggleMaximized().Ok(); });
            (void)OnCommand(core::StringView(u8"dock.close"), [self](CommandEvent& e) { e.Propagate = !self->CloseFocused().Ok(); });
            (void)OnCommand(core::StringView(u8"dock.move-to"), [self](CommandEvent& e) { e.Propagate = self->OpenMoveToFocused() == nullptr; });
            (void)OnCommand(core::StringView(u8"dock.float"), [self](CommandEvent& e) { e.Propagate = !self->FloatFocused().Ok(); });
        }
        ~DockSpace() override
        {
            if (m_controller != nullptr)
                m_controller->RemoveView(*this);
        }
        DockSpace(const DockSpace&) = delete;
        DockSpace& operator=(const DockSpace&) = delete;

        /// Shows `surface` of `controller`'s layout, now and whenever it changes.
        void Show(DockController& controller, DockSurfaceId surface)
        {
            if (m_controller != nullptr)
                m_controller->RemoveView(*this);
            m_controller = &controller;
            m_surface = surface;
            controller.AddView(*this);
            ShowLayout();
        }
        [[nodiscard]] DockSurfaceId GetSurface() const noexcept { return m_surface; }

        /// The widget showing a node (a Splitter or a TabView); null when it shows none.
        [[nodiscard]] UIWidget* WidgetOf(DockNodeId node) const noexcept
        {
            for (const Shown& shown : m_shown)
                if (shown.Node == node)
                    return shown.Widget.Get();
            return nullptr;
        }
        /// The page showing a panel; null when none does.
        [[nodiscard]] TabPage* PageOf(core::StringView panel) const noexcept
        {
            for (const Shown& shown : m_shown)
                for (const Page& page : shown.Pages)
                    if (page.Panel.AsView() == panel)
                        return page.Widget.Get();
            return nullptr;
        }

        [[nodiscard]] const String* PanelOf(const Node& page) const override
        {
            for (const Shown& shown : m_shown)
                for (const Page& p : shown.Pages)
                    if (p.Widget.Get() == &page)
                        return &p.Panel;
            return nullptr;
        }

        // === The keyboard's moves (D4) ===
        /// The stack the focus is in, among those this widget shows; kNoDock when it is in none.
        [[nodiscard]] DockNodeId FocusedStack() const
        {
            const EventDispatcher* d = const_cast<DockSpace*>(this)->GetEventDispatcher();
            for (const Node* n = d != nullptr ? d->GetFocusNode() : nullptr; n != nullptr; n = n->GetParent())
                if (const DockStack* stack = Cast<DockStack>(const_cast<Node*>(n)); stack != nullptr && stack->GetSpace() == this)
                    return stack->GetNode();
            return kNoDock;
        }
        /// The stack shown nearest `stack` the way `way` goes (overlapping it across); kNoDock when
        /// none is.
        [[nodiscard]] DockNodeId StackToward(DockNodeId stack, DockDirection way) const
        {
            const UIWidget* from = WidgetOf(stack);
            if (from == nullptr)
                return kNoDock;
            const Rect a = from->GetScreenBounds();
            DockNodeId best = kNoDock;
            f32 bestGap = 0.0f;
            f32 bestOverlap = 0.0f;
            for (const Shown& shown : m_shown)
            {
                if (shown.Kind != DockNodeKind::Stack || shown.Node == stack || !Holds(*shown.Widget))
                    continue;
                const Rect b = shown.Widget->GetScreenBounds();
                const bool across = way == DockDirection::Left || way == DockDirection::Right;
                f32 gap = 0.0f;
                switch (way)
                {
                case DockDirection::Left: gap = a.x - (b.x + b.width); break;
                case DockDirection::Right: gap = b.x - (a.x + a.width); break;
                case DockDirection::Up: gap = a.y - (b.y + b.height); break;
                case DockDirection::Down: gap = b.y - (a.y + a.height); break;
                }
                const f32 overlap = across ? Min(a.y + a.height, b.y + b.height) - Max(a.y, b.y)
                                           : Min(a.x + a.width, b.x + b.width) - Max(a.x, b.x);
                if (gap < -1.0f || overlap <= 0.0f)
                    continue; // not that way, or not beside it
                if (best == kNoDock || gap < bestGap - 0.5f || (gap <= bestGap + 0.5f && overlap > bestOverlap))
                {
                    best = shown.Node;
                    bestGap = gap;
                    bestOverlap = overlap;
                }
            }
            return best;
        }
        /// The stack this widget shows at `screenPoint`, or the one nearest it; kNoDock when it shows
        /// none.
        [[nodiscard]] DockNodeId StackAt(core::Float2 screenPoint) const
        {
            DockNodeId best = kNoDock;
            f32 bestDistance = 0.0f;
            for (const Shown& shown : m_shown)
            {
                if (shown.Kind != DockNodeKind::Stack || !Holds(*shown.Widget))
                    continue;
                const Rect b = shown.Widget->GetScreenBounds();
                const f32 dx = Max(0.0f, Max(b.x - screenPoint.x, screenPoint.x - (b.x + b.width)));
                const f32 dy = Max(0.0f, Max(b.y - screenPoint.y, screenPoint.y - (b.y + b.height)));
                const f32 distance = dx * dx + dy * dy;
                if (best == kNoDock || distance < bestDistance)
                {
                    best = shown.Node;
                    bestDistance = distance;
                }
            }
            return best;
        }
        /// The stacks this widget shows (a maximized one alone), in the layout's order.
        void StacksShown(Array<DockNodeId>& out) const
        {
            for (const Shown& shown : m_shown)
                if (shown.Kind == DockNodeKind::Stack && Holds(*shown.Widget))
                    out.PushBack(shown.Node);
        }
        /// A stack's chosen tab focused; false when this widget shows none of it.
        bool FocusStack(DockNodeId stack)
        {
            TabView* view = Cast<TabView>(WidgetOf(stack));
            if (view == nullptr || !Holds(*view))
                return false;
            Tab* tab = view->GetBar()->GetSelectedTab();
            if (tab == nullptr)
                return false;
            tab->RequestFocus();
            return true;
        }
        /// What its keys and Move to menu reach past its own surface (a DockArea sets it); none, they
        /// stay in it.
        void SetSurroundings(IDockSurroundings* surroundings) noexcept { m_surroundings = surroundings; }
        [[nodiscard]] IDockSurroundings* GetSurroundings() const noexcept { return m_surroundings; }
        /// Focuses the stack the way `way` goes from the focused one (its chosen tab), past the
        /// surface's edge into the surroundings when none of its own is; false when there is none.
        bool FocusToward(DockDirection way)
        {
            const DockNodeId from = FocusedStack();
            if (const DockNodeId to = StackToward(from, way); to != kNoDock)
                return FocusStack(to);
            const DockNodeId beyond = from != kNoDock && m_surroundings != nullptr ? m_surroundings->StackBeyond(*this, from, way) : kNoDock;
            return beyond != kNoDock && m_surroundings->FocusStackAnywhere(beyond);
        }
        /// The focused stack's chosen panel moved the way `way` goes: into the stack there, else into
        /// the stack beyond the surface's edge (the surroundings'), else along that edge. The focus
        /// goes with it.
        DockOutcome MoveFocused(DockDirection way)
        {
            const DockNodeId stack = FocusedStack();
            const DockNode* node = stack != kNoDock ? m_controller->GetLayout().FindNode(stack) : nullptr;
            if (node == nullptr || node->Panels.IsEmpty())
                return DockOutcome::Refuse(u8"no stack is focused");
            const String panel = node->Panels[Min(static_cast<usize>(node->Active), node->Panels.Size() - 1)];
            const RefPtr<DockSpace> keep(this); // a float this empties ends with the edit
            DockNodeId to = StackToward(stack, way);
            if (to == kNoDock && m_surroundings != nullptr)
                to = m_surroundings->StackBeyond(*this, stack, way);
            DockDrop drop;
            if (to != kNoDock)
                drop = DockDrop{DockDropKind::Middle, to, kNoDock, -1, DockSide::Start};
            else
                drop = DockDrop{DockDropKind::Edge, kNoDock, m_surface, -1, SideOf(way)};
            const DockOutcome outcome = m_controller->Edit([&](DockLayout& layout) { return ApplyDrop(layout, panel.AsView(), drop); });
            if (outcome.Ok())
                (void)FocusLanded(m_controller->GetLayout().StackOf(panel.AsView()));
            return outcome;
        }
        /// The focused stack shown alone, or every stack again when one is.
        DockOutcome ToggleMaximized()
        {
            const DockSurface* surface = m_controller != nullptr ? m_controller->GetLayout().FindSurface(m_surface) : nullptr;
            if (surface == nullptr)
                return DockOutcome::Refuse(u8"no surface is shown");
            if (surface->Maximized != kNoDock)
            {
                const DockNodeId was = surface->Maximized;
                const DockOutcome outcome = m_controller->Edit([this](DockLayout& layout) { return layout.Restore(m_surface); });
                (void)FocusStack(was);
                return outcome;
            }
            const DockNodeId stack = FocusedStack();
            if (stack == kNoDock)
                return DockOutcome::Refuse(u8"no stack is focused");
            const DockOutcome outcome = m_controller->Edit([stack](DockLayout& layout) { return layout.Maximize(stack); });
            (void)FocusStack(stack);
            return outcome;
        }
        /// Closes the focused stack's chosen panel (as its description says).
        DockOutcome CloseFocused()
        {
            const DockNodeId stack = FocusedStack();
            const DockNode* node = stack != kNoDock ? m_controller->GetLayout().FindNode(stack) : nullptr;
            if (node == nullptr || node->Panels.IsEmpty())
                return DockOutcome::Refuse(u8"no stack is focused");
            const String panel = node->Panels[Min(static_cast<usize>(node->Active), node->Panels.Size() - 1)];
            return m_controller->Close(panel.AsView());
        }

        // === Floating (D5) ===
        /// A drag asks for a float rather than a dock: Shift held (the pointer's; the keyboard drops
        /// where the focus is).
        [[nodiscard]] static bool AsksToFloat(const DropQuery& query) noexcept
        {
            return !query.FromKeyboard && (query.Modifiers & KeyModShift) != 0;
        }
        /// Told of a panel or a stack dragged from here and let go outside every window (a DockArea
        /// floats it there, in OS windows, D6).
        void SetOnDraggedOutside(Function<void(const DockDragged&, const DragResult&)> handler) { m_onDraggedOutside = core::Move(handler); }
        /// Where a panel floated from here (the menu, `dock.float`) stands: what the area it is in
        /// says (a DockArea sets it); none, a float placed where the area cascades them.
        void SetFloatPlacer(Function<Rectangle(core::StringView panel)> placer) { m_floatPlacer = core::Move(placer); }
        /// A panel docked here floated into a surface of its own.
        DockOutcome FloatPanel(core::StringView panel)
        {
            if (m_controller == nullptr)
                return DockOutcome::Refuse(u8"it shows no layout");
            const Rectangle bounds = m_floatPlacer ? m_floatPlacer(panel) : Rectangle{0.0f, 0.0f, 0.0f, 0.0f};
            const String moving(panel);
            return m_controller->Edit([&](DockLayout& layout) { return layout.Float(moving.AsView(), bounds); });
        }
        /// The focused stack's chosen panel floated.
        DockOutcome FloatFocused()
        {
            const DockNodeId stack = FocusedStack();
            const DockNode* node = stack != kNoDock ? m_controller->GetLayout().FindNode(stack) : nullptr;
            if (node == nullptr || node->Panels.IsEmpty())
                return DockOutcome::Refuse(u8"no stack is focused");
            const String panel = node->Panels[Min(static_cast<usize>(node->Active), node->Panels.Size() - 1)];
            return FloatPanel(panel.AsView());
        }

        // === The "Move to" menu (D4) ===
        /// Opens the menu of the places `panel` may go, at `at` (root space) for `owner`: into each
        /// other stack, beside one (on each side), its own and then the surroundings', along the
        /// surface's edges, floated; a place the layout refuses is shown disabled. Then Close (disabled
        /// for a panel that cannot be closed). Null when the panel is not docked here.
        Menu* OpenMoveTo(core::StringView panel, Node& owner, core::Float2 at)
        {
            if (m_controller == nullptr || m_controller->GetLayout().SurfaceOf(m_controller->GetLayout().StackOf(panel)) != m_surface)
                return nullptr;
            const DockNodeId from = m_controller->GetLayout().StackOf(panel);
            m_moveMenu = MakeRef<Menu>(MemoryAllocator());
            Menu& menu = *m_moveMenu;
            DockSpace* self = this;
            const String moving(panel);
            const auto add = [&](Menu& into, core::StringView text, const DockDrop& drop)
            {
                DockLayout after = m_controller->GetLayout();
                const bool can = ApplyDrop(after, panel, drop).Ok();
                MenuItem* item = into.AddItem(text, [self, moving, drop]()
                {
                    const RefPtr<DockSpace> keep(self); // a float this empties ends with the edit
                    if (self->m_controller->Edit([&](DockLayout& layout) { return ApplyDrop(layout, moving.AsView(), drop); }).Ok())
                        (void)self->FocusLanded(self->m_controller->GetLayout().StackOf(moving.AsView()));
                });
                item->SetEnabled(can);
            };
            const DockDirection ways[] = {DockDirection::Left, DockDirection::Right, DockDirection::Up, DockDirection::Down};
            const char8_t* const besideNames[] = {u8"Left", u8"Right", u8"Above", u8"Below"};
            const char8_t* const edgeNames[] = {u8"Left", u8"Right", u8"Top", u8"Bottom"};
            Menu* into = menu.AddSubMenu(core::StringView(u8"Into"));
            Menu* beside = menu.AddSubMenu(core::StringView(u8"Beside"));
            // Its own stacks, then the other surfaces' (named for where they are).
            Array<DockNodeId> stacks;
            StacksShown(stacks);
            const usize own = stacks.Size();
            if (m_surroundings != nullptr)
                m_surroundings->OtherStacks(*this, stacks);
            for (usize s = 0; s < stacks.Size(); ++s)
            {
                const DockNodeId stack = stacks[s];
                const DockSurface* surface = s < own ? nullptr : m_controller->GetLayout().FindSurface(m_controller->GetLayout().SurfaceOf(stack));
                const bool floating = surface != nullptr && surface->Kind == DockSurfaceKind::Floating;
                const String name = s < own ? StackName(stack)
                                  : floating ? Format(u8"{} (floating)", StackName(stack))
                                             : Format(u8"{} (main)", StackName(stack));
                if (stack != from)
                    add(*into, name.AsView(), DockDrop{DockDropKind::Middle, stack, kNoDock, -1, DockSide::Start});
                Menu* sides = beside->AddSubMenu(name.AsView());
                for (usize i = 0; i < 4; ++i)
                    add(*sides, core::StringView(besideNames[i]), DockDrop{DockDropKind::Beside, stack, kNoDock, -1, SideOf(ways[i])});
            }
            Menu* edge = menu.AddSubMenu(core::StringView(u8"Along the Edge"));
            for (usize i = 0; i < 4; ++i)
                add(*edge, core::StringView(edgeNames[i]), DockDrop{DockDropKind::Edge, kNoDock, m_surface, -1, SideOf(ways[i])});
            {
                DockLayout after = m_controller->GetLayout();
                const bool can = after.Float(panel, Rectangle{0.0f, 0.0f, 0.0f, 0.0f}).Ok();
                MenuItem* item = menu.AddItem(core::StringView(u8"Float"), [self, moving]() { (void)self->FloatPanel(moving.AsView()); });
                item->SetEnabled(can);
            }
            menu.AddSeparator();
            {
                const DockPanelDescription* description = m_controller->Describe(panel);
                MenuItem* item = menu.AddItem(core::StringView(u8"Close"), [self, moving]()
                {
                    const RefPtr<DockSpace> keep(self); // a float this empties ends with the close
                    (void)self->m_controller->Close(moving.AsView());
                });
                item->SetEnabled(description == nullptr || description->Closable);
            }
            menu.Open(owner, at);
            return m_moveMenu.Get();
        }
        /// The "Move to" menu for the focused stack's chosen panel, below its tab.
        Menu* OpenMoveToFocused()
        {
            const DockNodeId stack = FocusedStack();
            const DockNode* node = stack != kNoDock ? m_controller->GetLayout().FindNode(stack) : nullptr;
            TabView* view = Cast<TabView>(WidgetOf(stack));
            Tab* tab = view != nullptr ? view->GetBar()->GetSelectedTab() : nullptr;
            if (node == nullptr || node->Panels.IsEmpty() || tab == nullptr)
                return nullptr;
            const String panel = node->Panels[Min(static_cast<usize>(node->Active), node->Panels.Size() - 1)];
            return OpenMoveTo(panel.AsView(), *tab, tab->ConvertToWorldSpace(core::Float2{0.0f, tab->GetSize().y}));
        }
        /// The menu last opened (open or not); null before one is.
        [[nodiscard]] Menu* GetMoveMenu() const noexcept { return m_moveMenu.Get(); }

        // === Drops (D4) ===
        /// How far into a stack its edge band reaches (a third of it at most); the sheet's
        /// `edge-band`, the theme's `--dock-edge`.
        [[nodiscard]] f32 GetEdgeBand() const noexcept { return m_edgeBand; }
        void SetEdgeBand(f32 band) noexcept { m_edgeBand = Max(0.0f, band); }
        /// How far into the surface its own edge band reaches (`surface-band`, `--dock-surface-edge`);
        /// over a strip along the edge, its outer third (the rest is the strip's).
        [[nodiscard]] f32 GetSurfaceBand() const noexcept { return m_surfaceBand; }
        void SetSurfaceBand(f32 band) noexcept { m_surfaceBand = Max(0.0f, band); }

        /// What a tab torn out of its stack leaves while it is dragged (`torn-tab`, the theme's
        /// `--dock-torn-tab`): `dim` (the default), it stays where it is, dimmed; `close`, its strip
        /// closing up and its stack showing a neighbour's panel. Nothing moves in the layout until the drop,
        /// and a drag that ends without one shows the stack as it was. A stack's only tab, or a tab
        /// picked up from the keyboard (the focus stays on it), is dimmed either way.
        [[nodiscard]] DockTornTab GetTornTab() const noexcept { return m_tornTab; }
        void SetTornTab(DockTornTab torn) noexcept { m_tornTab = torn; }
        [[nodiscard]] String GetTornTabName() const { return String(m_tornTab == DockTornTab::Close ? u8"close" : u8"dim"); }
        void SetTornTabName(const String& name) { m_tornTab = name.AsView() == core::StringView(u8"close") ? DockTornTab::Close : DockTornTab::Dim; }

        /// The docked panel a drag carries (a torn-out tab of a page some view of the controller
        /// shows); null for anything else.
        [[nodiscard]] const String* DraggedPanel(const DragPayload& payload) const
        {
            if (m_controller == nullptr || payload.Type.AsView() != core::StringView(u8"gui/tab"))
                return nullptr;
            const Tab* tab = Cast<Tab>(Node::FromHandle(payload.Value));
            const Node* page = tab != nullptr ? tab->GetPage() : nullptr;
            return page != nullptr ? m_controller->PanelShownBy(*page) : nullptr;
        }
        /// The floating surface a drag carries whole (a float dragged by its title); kNoDock for
        /// anything else.
        [[nodiscard]] DockSurfaceId DraggedSurface(const DragPayload& payload) const
        {
            if (m_controller == nullptr || payload.Type.AsView() != core::StringView(kDockSurfaceDragType))
                return kNoDock;
            const u64* id = payload.Value.TryGet<u64>();
            const DockSurface* surface = id != nullptr ? m_controller->GetLayout().FindSurface(static_cast<DockSurfaceId>(*id)) : nullptr;
            return surface != nullptr && surface->Kind == DockSurfaceKind::Floating ? surface->Id : kNoDock;
        }
        /// The stack a drag carries whole (its strip's grip dragged); kNoDock for anything else.
        [[nodiscard]] DockNodeId DraggedStack(const DragPayload& payload) const
        {
            if (m_controller == nullptr || payload.Type.AsView() != core::StringView(kDockStackDragType))
                return kNoDock;
            const u64* id = payload.Value.TryGet<u64>();
            const DockNode* stack = id != nullptr ? m_controller->GetLayout().FindNode(static_cast<DockNodeId>(*id)) : nullptr;
            return stack != nullptr && stack->IsStack() ? stack->Id : kNoDock;
        }
        /// What a dock drag carries (a panel, a floating surface or a stack); false for any other drag.
        [[nodiscard]] bool Dragged(const DragPayload& payload, DockDragged& out) const
        {
            if (const String* panel = DraggedPanel(payload))
            {
                out = DockDragged{*panel, kNoDock};
                return true;
            }
            if (const DockNodeId stack = DraggedStack(payload); stack != kNoDock)
            {
                out = DockDragged{String{}, kNoDock, stack};
                return true;
            }
            const DockSurfaceId surface = DraggedSurface(payload);
            out = DockDragged{String{}, surface};
            return surface != kNoDock;
        }
        /// The drop a point means (in this widget's space), over `stack` (kNoDock: over none): the
        /// surface's edge within its band, else the stack's edge within its band, else its middle;
        /// false when it means none.
        [[nodiscard]] bool DropAt(core::Float2 at, DockNodeId stack, DockDrop& drop, f32 surfaceShare = 1.0f) const
        {
            const Rect bounds = GetScreenBounds();
            const f32 w = bounds.width;
            const f32 h = bounds.height;
            DockSide side{};
            if (NearestEdge(at, Rect{0.0f, 0.0f, w, h}, Min(m_surfaceBand, Min(w, h) / 3.0f) * surfaceShare, side))
            {
                drop = DockDrop{DockDropKind::Edge, kNoDock, m_surface, -1, side};
                return true;
            }
            const UIWidget* widget = stack != kNoDock ? WidgetOf(stack) : nullptr;
            if (widget == nullptr)
                return false;
            const Rect sb = widget->GetScreenBounds();
            const Rect r{sb.x - bounds.x, sb.y - bounds.y, sb.width, sb.height};
            if (NearestEdge(at, r, Min(m_edgeBand, Min(r.width, r.height) / 3.0f), side))
                drop = DockDrop{DockDropKind::Beside, stack, kNoDock, -1, side};
            else
                drop = DockDrop{DockDropKind::Middle, stack, kNoDock, -1, DockSide::Start};
            return true;
        }
        /// Where the preview of the drop being offered stands (this widget's space); false when none
        /// shows.
        [[nodiscard]] bool GetPreviewBounds(Rect& out) const
        {
            if (!m_preview || !m_preview->IsVisible())
                return false;
            out = m_previewBounds;
            return true;
        }

        /// The layout shown again: the widgets of nodes still there kept and brought in step, those of
        /// nodes gone let go.
        void ShowLayout() override
        {
            if (m_controller == nullptr)
                return;
            const DockLayout& layout = m_controller->GetLayout();
            const DockSurface* surface = layout.FindSurface(m_surface);
            for (Shown& shown : m_shown)
                shown.Used = false;
            RefPtr<UIWidget> top;
            if (surface != nullptr)
            {
                top = Build(surface->Maximized != kNoDock ? surface->Maximized : surface->Root);
                Keep(surface->Root); // a stack maximized: the rest kept for its restore
            }
            Node* const shown = ChildCount() > 0 && GetChildAt(0) != m_preview.Get() ? GetChildAt(0) : nullptr;
            if (shown != top.Get())
            {
                if (shown != nullptr)
                    RemoveChild(shown);
                if (top)
                {
                    top->EditLayoutStyle([](LayoutStyle& s) { s.Grow = 1.0f; });
                    if (top->GetParent() != nullptr)
                        top->RemoveFromParent();
                    AddChildAt(top.Get(), 0); // under the preview
                }
            }
            for (usize i = m_shown.Size(); i > 0; --i)
                if (!m_shown[i - 1].Used)
                {
                    m_shown[i - 1].Widget->RemoveFromParent();
                    m_shown.RemoveAt(i - 1);
                }
        }

    protected:
        void OnDragQuery(DropQuery& query) override
        {
            // Reached over a separator, or past a stack that left it the surface's band.
            DockDragged dragged;
            DockDrop drop;
            if (Dragged(query.Payload, dragged) && !query.FromKeyboard && !AsksToFloat(query) && DropAt(query.Local, kNoDock, drop))
                Offer(*this, query, dragged, drop);
        }
        void OnDragLeave(const DragEvent&) override { Withdraw(*this); }
        void OnDrop(const DragEvent&) override { TakeOffer(*this); }

    private:
        struct Page
        {
            String Panel;
            RefPtr<TabPage> Widget;
            bool Registered = false; ///< made for a registered panel, not a placeholder
        };
        struct Shown
        {
            DockNodeId Node = kNoDock;
            DockNodeKind Kind = DockNodeKind::Stack;
            RefPtr<UIWidget> Widget;
            Array<Page> Pages; // a stack's, by panel
            bool Used = false;
        };

        // A tab of `stack` torn out (`torn`) or its drag over: closed up or dimmed meanwhile, then
        // shown again and the stack's panel as the layout has it (where the drop left it).
        void NoteTorn(DockNodeId stack, Tab& tab, bool torn)
        {
            Shown* shown = Find(stack);
            TabView* view = shown != nullptr ? Cast<TabView>(shown->Widget.Get()) : nullptr;
            if (!torn)
            {
                tab.SetDisplayed(true);
                tab.RemoveClass(core::StringView(u8"dock-torn"));
                if (view == nullptr)
                    return;
                view->RemoveClass(core::StringView(u8"dock-torn"));
                const DockNode* node = m_controller != nullptr ? m_controller->GetLayout().FindNode(stack) : nullptr;
                if (node != nullptr && node->Kind == DockNodeKind::Stack && !node->Panels.IsEmpty())
                    view->SetSelectedIndex(static_cast<i32>(Min(static_cast<usize>(node->Active), node->Panels.Size() - 1)));
                return;
            }
            if (view == nullptr)
                return;
            TabBar& bar = *view->GetBar();
            const EventDispatcher* d = GetEventDispatcher();
            const bool keyboard = d != nullptr && d->IsKeyboardDrag();
            if (bar.GetTabCount() <= 1)
            {
                view->AddClass(core::StringView(u8"dock-torn")); // its stack goes with it: dimmed whole
                return;
            }
            if (m_tornTab == DockTornTab::Dim || keyboard)
            {
                tab.AddClass(core::StringView(u8"dock-torn"));
                return;
            }
            // Closed up: a neighbour's panel shown in its place (the view's selection, not the layout's).
            const i32 at = bar.IndexOf(&tab);
            if (bar.GetSelectedIndex() == at)
                view->SetSelectedIndex(at + 1 < bar.GetTabCount() ? at + 1 : at - 1);
            tab.SetDisplayed(false);
        }

        // A drag of the whole stack from its grip: the pointer's (the keyboard moves a stack's panels
        // by its tab menu), of a stack that has panels.
        bool StartStackDrag(DockNodeId stack, DragRequest& request) const
        {
            const DockNode* node = m_controller != nullptr ? m_controller->GetLayout().FindNode(stack) : nullptr;
            if (request.FromKeyboard || node == nullptr || !node->IsStack() || node->Panels.IsEmpty())
                return false;
            request.Payload.Type = String(kDockStackDragType);
            request.Payload.Value = core::Variant::From<u64>(static_cast<u64>(stack));
            request.Payload.Label = StackName(stack);
            request.Payload.Allowed = DropEffectsMove;
            return true;
        }
        // The stack holding `grip` dimmed while it is carried (the grip's ancestors asked: a drop may
        // have moved it into another widget, or let it go).
        static void DimStackOf(Node& grip, bool dim)
        {
            for (Node* n = &grip; n != nullptr; n = n->GetParent())
                if (DockStack* stack = Cast<DockStack>(n))
                {
                    if (dim)
                        stack->AddClass(core::StringView(u8"dock-torn"));
                    else
                        stack->RemoveClass(core::StringView(u8"dock-torn"));
                    return;
                }
        }

        [[nodiscard]] Shown* Find(DockNodeId node) noexcept
        {
            for (Shown& shown : m_shown)
                if (shown.Node == node)
                    return &shown;
            return nullptr;
        }

        // The widgets of `id` and its descendants that are made stay, shown or not.
        void Keep(DockNodeId id)
        {
            const DockNode* node = m_controller->GetLayout().FindNode(id);
            if (node == nullptr)
                return;
            if (Shown* shown = Find(id))
                shown->Used = true;
            for (const DockNodeId child : node->Children)
                Keep(child);
        }

        // The widget for `id`, made or kept, brought in step with the layout.
        RefPtr<UIWidget> Build(DockNodeId id)
        {
            const DockNode* node = m_controller->GetLayout().FindNode(id);
            if (node == nullptr)
                return {};
            Shown* shown = Find(id);
            if (shown != nullptr && shown->Kind != node->Kind)
            {
                shown->Widget->RemoveFromParent();
                shown->Widget = {};
            }
            if (shown == nullptr)
            {
                m_shown.PushBack(Shown{id, node->Kind, {}, {}, false});
                shown = &m_shown.Back();
            }
            shown->Used = true;
            if (node->IsStack())
                return BuildStack(id);
            return BuildSplit(id);
        }

        RefPtr<UIWidget> BuildSplit(DockNodeId id)
        {
            if (!Find(id)->Widget)
            {
                RefPtr<Splitter> made = MakeRef<Splitter>(MemoryAllocator());
                DockSpace* self = this;
                made->SetOnResized(
                    [self, id, splitter = made.Get()]()
                    {
                        const Array<f32> weights = splitter->GetWeights();
                        self->m_controller->NoteWeights(id, Span<const f32>(weights.Data(), weights.Size()));
                    });
                Find(id)->Widget = made;
            }
            // Its children first (building them may grow the table and move entries).
            const DockNode node = *m_controller->GetLayout().FindNode(id);
            Array<RefPtr<UIWidget>> children;
            for (const DockNodeId child : node.Children)
                children.PushBack(Build(child));
            Splitter& splitter = *Cast<Splitter>(Find(id)->Widget.Get());
            splitter.SetAxis(node.Axis == DockAxis::Vertical ? SplitterAxis::Vertical : SplitterAxis::Horizontal);
            // Its panes, in order (the handles between them are the splitter's own).
            bool inOrder = splitter.GetPaneCount() == children.Size();
            for (usize i = 0; inOrder && i < children.Size(); ++i)
                inOrder = splitter.GetPane(i) == children[i].Get();
            if (!inOrder)
            {
                while (splitter.GetPaneCount() > 0)
                    splitter.RemoveChild(splitter.GetPane(splitter.GetPaneCount() - 1));
                for (const RefPtr<UIWidget>& child : children)
                {
                    if (child->GetParent() != nullptr)
                        child->RemoveFromParent();
                    splitter.AddChild(child.Get());
                }
            }
            // Its shares, unless they are what it shows already (a drag just noted them).
            const Array<f32> now = splitter.GetWeights();
            bool same = now.Size() == node.Weights.Size();
            for (usize i = 0; same && i < now.Size(); ++i)
                same = Abs(now[i] - node.Weights[i]) < 1.0e-4f;
            if (!same)
                splitter.SetWeights(Span<const f32>(node.Weights.Data(), node.Weights.Size()));
            return Find(id)->Widget;
        }

        RefPtr<UIWidget> BuildStack(DockNodeId id)
        {
            DockSpace* self = this;
            if (!Find(id)->Widget)
            {
                RefPtr<DockStack> made = MakeRef<DockStack>(MemoryAllocator(), *this, id);
                made->AddClass(core::StringView(u8"dock-stack"));
                // Its strip: a tab dropped there is the layout's move too.
                TabBar* bar = made->GetBar();
                bar->SetOnTabOffered([self, id, bar](DropQuery& query, Tab&, i32 index)
                {
                    if (AsksToFloat(query))
                        query.Effect = DropEffect::None; // passed on: a float, the area's
                    else if (DockDragged dragged; self->Dragged(query.Payload, dragged))
                    {
                        // The outer third of the surface's band wins over a strip along the surface's
                        // edge; the rest of the strip is the strip's (a tab moved along it reorders).
                        DockDrop drop{DockDropKind::Tab, id, kNoDock, index, DockSide::Start};
                        DockDrop edge;
                        if (!query.FromKeyboard && self->DropAt(self->FromNode(*bar, query.Local), kNoDock, edge, 1.0f / 3.0f))
                            drop = edge;
                        self->Offer(*bar, query, dragged, drop);
                    }
                    else
                        query.Refuse(core::StringView(u8"it is not a docked panel"));
                });
                bar->SetTabTaker([self, bar](Tab&, i32) { self->TakeOffer(*bar); });
                // A whole stack over the strip goes in as tabs (the bar asks only of tabs); the outer
                // third of the surface's band wins, as for a tab.
                bar->SetOnDragQuery([self, id, bar](DropQuery& query)
                {
                    DockDragged dragged;
                    if (AsksToFloat(query) || !self->Dragged(query.Payload, dragged) || !dragged.IsStack())
                        return;
                    DockDrop drop{DockDropKind::Middle, id, kNoDock, -1, DockSide::Start};
                    DockDrop edge;
                    if (self->DropAt(self->FromNode(*bar, query.Local), kNoDock, edge, 1.0f / 3.0f))
                        drop = edge;
                    self->Offer(*bar, query, dragged, drop);
                });
                (void)bar->AddEventListener(EventType::Drop, [self, bar](const Event& event)
                {
                    if (self->DraggedStack(static_cast<const DragEvent&>(event).Payload) != kNoDock)
                        self->TakeOffer(*bar);
                });
                // Its grip: the list button, dragged, carries the whole stack (dimmed meanwhile).
                Node* grip = bar->GetListButton();
                grip->SetDragSource([self, id](DragRequest& request) { return self->StartStackDrag(id, request); });
                (void)grip->AddEventListener(EventType::DragStart, [grip](const Event&) { DimStackOf(*grip, true); });
                grip->SetOnDragEnd([self, id, grip](const DragResult& result)
                {
                    DimStackOf(*grip, false);
                    if (result.Outside && self->m_onDraggedOutside)
                    {
                        const RefPtr<DockSpace> keep(self);
                        self->m_onDraggedOutside(DockDragged{String{}, kNoDock, id}, result);
                    }
                });
                bar->SetOnTabTorn([self, id](Tab& tab, bool torn) { self->NoteTorn(id, tab, torn); });
                // A tab let go outside every window: its panel, to whoever floats it there (D6).
                bar->SetOnTabDragEnded([self](Tab& tab, const DragResult& result)
                {
                    if (!result.Outside || !self->m_onDraggedOutside)
                        return;
                    const Node* page = tab.GetPage();
                    const String* panel = page != nullptr ? self->PanelOf(*page) : nullptr;
                    if (panel == nullptr)
                        return;
                    const DockDragged dragged{*panel, kNoDock, kNoDock};
                    const RefPtr<DockSpace> keep(self); // the float it makes may end this space's surface
                    self->m_onDraggedOutside(dragged, result);
                });
                (void)bar->AddEventListener(EventType::DragLeave, [self, bar](const Event&) { self->Withdraw(*bar); });
                made->SetGroup(String(u8"dock"));
                made->SetReorderable(true);
                TabView* view = made.Get();
                made->SetOnSelected([self, id, view](i32 index) { self->NoteActive(id, *view, index); });
                made->SetOnPageMoved([self, id, view](i32 to) { self->NoteMoved(id, *view, to); });
                made->GetBar()->SetCloseHandler([self, id, view](i32 index) { self->CloseTab(id, *view, index); });
                Find(id)->Widget = made;
            }
            const DockNode node = *m_controller->GetLayout().FindNode(id);
            Shown& shown = *Find(id);
            TabView& view = *Cast<TabView>(shown.Widget.Get());
            if (node.Has(DockStackCentral))
                view.AddClass(core::StringView(u8"dock-central"));
            // Its pages: one a panel, in the panels' order; a panel gone takes its page with it.
            Array<Page> pages;
            for (const String& panel : node.Panels)
            {
                const bool registered = m_controller->Describe(panel.AsView()) != nullptr;
                RefPtr<TabPage> page;
                for (const Page& had : shown.Pages)
                    if (had.Panel == panel && (had.Registered || !registered)) // a placeholder whose panel came is made again
                        page = had.Widget;
                if (!page)
                    page = MakePage(panel.AsView());
                pages.PushBack(Page{panel, page, registered});
            }
            bool inOrder = view.GetPageCount() == static_cast<i32>(pages.Size());
            for (usize i = 0; inOrder && i < pages.Size(); ++i)
                inOrder = view.GetPage(static_cast<i32>(i)) == pages[i].Widget.Get();
            if (!inOrder)
            {
                while (view.GetPageCount() > 0)
                    view.RemovePage(view.GetPageCount() - 1);
                // The active tab chosen before the pages come, so the first to come is not shown
                // (and its content made) on the way.
                view.SetSelectedIndex(static_cast<i32>(node.Active));
                for (const Page& page : pages)
                {
                    if (page.Widget->GetParent() != nullptr)
                        page.Widget->RemoveFromParent();
                    view.AddPage(*page.Widget);
                }
            }
            shown.Pages = core::Move(pages);
            if (!node.Panels.IsEmpty() && view.GetSelectedIndex() != static_cast<i32>(node.Active))
                view.SetSelectedIndex(static_cast<i32>(node.Active));
            return shown.Widget;
        }
        // A panel's page: its title, icon and close from its description; its content made when its
        // tab is first shown, or a placeholder for a panel not registered.
        RefPtr<TabPage> MakePage(core::StringView panel)
        {
            RefPtr<TabPage> page = MakeRef<TabPage>(MemoryAllocator());
            const DockPanelDescription* description = m_controller->Describe(panel);
            page->SetTitle(description != nullptr && !description->Title.IsEmpty() ? description->Title.AsView() : panel);
            if (description != nullptr && !description->Icon.IsEmpty())
                page->SetIconSource(description->Icon);
            page->SetClosable(description == nullptr || description->Closable);
            DockController* controller = m_controller;
            IAllocator* allocator = &MemoryAllocator();
            const String id(panel);
            page->SetContentFactory(
                [controller, allocator, id](TabPage& into)
                {
                    RefPtr<Node> content = controller->Content(id.AsView());
                    if (!content)
                    {
                        RefPtr<Label> placeholder = MakeRef<Label>(*allocator);
                        placeholder->AddClass(core::StringView(u8"dock-placeholder"));
                        placeholder->SetText(Format(u8"{} is not available", id).AsView());
                        content = placeholder;
                    }
                    if (content->GetParent() != nullptr)
                        content->RemoveFromParent(); // it was shown elsewhere
                    into.AddChild(content.Get());
                });
            return page;
        }

        [[nodiscard]] const String* PanelAt(DockNodeId stack, TabView& view, i32 index) const
        {
            const Node* page = view.GetPage(index);
            for (const Shown& shown : m_shown)
                if (shown.Node == stack)
                    for (const Page& p : shown.Pages)
                        if (p.Widget.Get() == page)
                            return &p.Panel;
            return nullptr;
        }
        void NoteActive(DockNodeId stack, TabView& view, i32 index)
        {
            if (const String* panel = PanelAt(stack, view, index))
                m_controller->NoteActive(panel->AsView());
        }
        void NoteMoved(DockNodeId stack, TabView& view, i32 to)
        {
            if (const String* panel = PanelAt(stack, view, to))
            {
                const String moved = *panel;
                m_controller->NoteTabPlace(moved.AsView(), stack, to);
                // The pages' order is the strip's now: kept so, without showing the layout again.
                if (Shown* shown = Find(stack))
                {
                    Array<Page> ordered;
                    for (i32 i = 0; i < view.GetPageCount(); ++i)
                        for (const Page& p : shown->Pages)
                            if (p.Widget.Get() == view.GetPage(i))
                                ordered.PushBack(p);
                    shown->Pages = core::Move(ordered);
                }
            }
        }
        void CloseTab(DockNodeId stack, TabView& view, i32 index)
        {
            if (const String* panel = PanelAt(stack, view, index))
            {
                const String closing = *panel;
                (void)m_controller->Close(closing.AsView());
            }
        }

        [[nodiscard]] bool Holds(const Node& node) const
        {
            for (const Node* n = &node; n != nullptr; n = n->GetParent())
                if (n == this)
                    return true;
            return false;
        }
        // The stack a panel moved to focused, here or in the surroundings. A float the move emptied
        // has left the tree still holding its old widgets: only the surface it shows is asked of it.
        bool FocusLanded(DockNodeId stack)
        {
            if (m_controller->GetLayout().SurfaceOf(stack) == m_surface && FocusStack(stack))
                return true;
            return m_surroundings != nullptr && m_surroundings->FocusStackAnywhere(stack);
        }
        // The side a way goes to, as the surface runs (right to left: left is its end).
        [[nodiscard]] DockSide SideOf(DockDirection way) const
        {
            const bool rtl = IsRightToLeft();
            switch (way)
            {
            case DockDirection::Left: return rtl ? DockSide::End : DockSide::Start;
            case DockDirection::Right: return rtl ? DockSide::Start : DockSide::End;
            case DockDirection::Up: return DockSide::Top;
            case DockDirection::Down: return DockSide::Bottom;
            }
            return DockSide::Start;
        }

        // A stack as the menu names it: its panels' titles.
        [[nodiscard]] String StackName(DockNodeId stack) const
        {
            String name;
            if (const DockNode* node = m_controller->GetLayout().FindNode(stack))
                for (const String& panel : node->Panels)
                {
                    const DockPanelDescription* description = m_controller->Describe(panel.AsView());
                    const core::StringView title = description != nullptr && !description->Title.IsEmpty() ? description->Title.AsView() : panel.AsView();
                    name = name.IsEmpty() ? String(title) : Format(u8"{}, {}", name, title);
                }
            return name.IsEmpty() ? String(u8"(empty)") : name;
        }

        // A point in `node`'s space, in this widget's.
        [[nodiscard]] core::Float2 FromNode(const Node& node, core::Float2 local) const
        {
            const Rect space = GetScreenBounds();
            const Rect from = node.GetScreenBounds();
            return core::Float2{local.x + from.x - space.x, local.y + from.y - space.y};
        }

        // The side of `r` whose band of `band` holds `at`, nearest first; false when none does.
        [[nodiscard]] bool NearestEdge(core::Float2 at, const Rect& r, f32 band, DockSide& side) const
        {
            if (band <= 0.0f || at.x < r.x || at.y < r.y || at.x > r.x + r.width || at.y > r.y + r.height)
                return false;
            const f32 left = at.x - r.x;
            const f32 right = r.x + r.width - at.x;
            const f32 top = at.y - r.y;
            const f32 bottom = r.y + r.height - at.y;
            const f32 nearest = Min(Min(left, right), Min(top, bottom));
            if (nearest > band)
                return false;
            const bool rtl = IsRightToLeft();
            if (nearest == left)
                side = rtl ? DockSide::End : DockSide::Start;
            else if (nearest == right)
                side = rtl ? DockSide::Start : DockSide::End;
            else
                side = nearest == top ? DockSide::Top : DockSide::Bottom;
            return true;
        }

        // A drop offered by `owner` (a stack, its strip, or this widget): tried on a copy of the
        // layout, refused with the layout's reason, or accepted with the preview where the panel
        // would be.
        void Offer(Node& owner, DropQuery& query, const DockDragged& dragged, const DockDrop& drop)
        {
            DockLayout after = m_controller->GetLayout();
            const Array<String> panels = PanelsOf(after, dragged); // where they are now
            const DockOutcome outcome = ApplyDrop(after, dragged, drop);
            m_offerOwner = &owner;
            if (!outcome.Ok())
            {
                m_offer = {};
                query.Refuse(outcome.Refused.AsView());
                HidePreview();
                return;
            }
            query.Accept(DropEffect::Move);
            m_offer = Offered{dragged, drop, true};
            // Where what it carries would stand: its stacks' bounds together, in this surface.
            Rect at;
            bool any = false;
            for (const String& panel : panels)
            {
                Rect each;
                if (!BoundsIn(after, after.StackOf(panel.AsView()), each))
                    continue;
                if (!any)
                    at = each;
                else
                {
                    const f32 right = Max(at.x + at.width, each.x + each.width), bottom = Max(at.y + at.height, each.y + each.height);
                    at.x = Min(at.x, each.x);
                    at.y = Min(at.y, each.y);
                    at.width = right - at.x;
                    at.height = bottom - at.y;
                }
                any = true;
            }
            if (any)
                ShowPreview(at);
            else
                HidePreview(); // it would go to another surface
        }
        void Withdraw(Node& owner)
        {
            if (m_offerOwner != &owner)
                return; // another took the drag over already
            m_offerOwner = nullptr;
            m_offer = {};
            HidePreview();
        }
        void TakeOffer(Node& owner)
        {
            const Offered offer = m_offerOwner == &owner ? m_offer : Offered{};
            m_offerOwner = nullptr;
            m_offer = {};
            HidePreview();
            if (offer.Valid && m_controller != nullptr)
                (void)m_controller->Edit([&offer](DockLayout& layout) { return ApplyDrop(layout, offer.Dragged, offer.Drop); });
        }

        // Where `node` stands in `layout`'s surface as this widget would show it: the shares of each
        // split from its root (the separators' room left out).
        [[nodiscard]] bool BoundsIn(const DockLayout& layout, DockNodeId node, Rect& out) const
        {
            const DockSurface* surface = layout.FindSurface(m_surface);
            if (surface == nullptr || node == kNoDock || layout.SurfaceOf(node) != m_surface)
                return false;
            const Rect bounds = GetScreenBounds();
            const Rect whole{0.0f, 0.0f, bounds.width, bounds.height};
            if (surface->Maximized != kNoDock)
            {
                out = whole;
                return node == surface->Maximized;
            }
            return BoundsUnder(layout, surface->Root, node, whole, out);
        }
        [[nodiscard]] bool BoundsUnder(const DockLayout& layout, DockNodeId at, DockNodeId node, const Rect& r, Rect& out) const
        {
            if (at == node)
            {
                out = r;
                return true;
            }
            const DockNode* split = layout.FindNode(at);
            if (split == nullptr || split->IsStack())
                return false;
            const bool vertical = split->Axis == DockAxis::Vertical;
            const bool mirrored = !vertical && IsRightToLeft();
            const f32 extent = vertical ? r.height : r.width;
            f32 from = 0.0f;
            for (usize i = 0; i < split->Children.Size(); ++i)
            {
                const f32 size = extent * split->Weights[i];
                Rect part = r;
                if (vertical)
                {
                    part.y = r.y + from;
                    part.height = size;
                }
                else
                {
                    part.x = mirrored ? r.x + r.width - from - size : r.x + from;
                    part.width = size;
                }
                if (BoundsUnder(layout, split->Children[i], node, part, out))
                    return true;
                from += size;
            }
            return false;
        }

        void ShowPreview(const Rect& at)
        {
            if (!m_preview)
            {
                m_preview = MakeRef<Panel>(MemoryAllocator());
                m_preview->AddClass(core::StringView(u8"dock-preview"));
                m_preview->SetHitTestVisible(false); // the drag sees what is under it
                AddChild(m_preview.Get());
            }
            m_previewBounds = at;
            m_preview->EditLayoutStyle([at](LayoutStyle& s)
            {
                s.Placement = Position::Absolute;
                s.Left = LayoutLength::Px(at.x);
                s.Top = LayoutLength::Px(at.y);
                s.Width = LayoutLength::Px(at.width);
                s.Height = LayoutLength::Px(at.height);
            });
            m_preview->SetVisible(true);
        }
        void HidePreview()
        {
            if (m_preview)
                m_preview->SetVisible(false);
        }

        struct Offered
        {
            DockDragged Dragged;
            DockDrop Drop;
            bool Valid = false;
        };

        DockController* m_controller = nullptr;
        DockSurfaceId m_surface = kNoDock;
        Array<Shown> m_shown;
        f32 m_edgeBand = 64.0f;
        f32 m_surfaceBand = 20.0f;
        DockTornTab m_tornTab = DockTornTab::Dim;
        Function<Rectangle(core::StringView)> m_floatPlacer;
        IDockSurroundings* m_surroundings = nullptr; // its DockArea's (non-owning; the area holds this)
        RefPtr<Panel> m_preview;
        RefPtr<Menu> m_moveMenu;
        Rect m_previewBounds{};
        Function<void(const DockDragged&, const DragResult&)> m_onDraggedOutside;
        Node* m_offerOwner = nullptr; // what offered the drop shown (non-owning; compared only)
        Offered m_offer;
    };

    // A stack's drops: the surface's band is the DockSpace's (left for the walk to reach it), the
    // rest the stack's own edge bands and middle.
    inline void DockStack::OnDragQuery(DropQuery& query)
    {
        DockDragged dragged;
        if (!m_space->Dragged(query.Payload, dragged) || DockSpace::AsksToFloat(query))
            return; // a drag of another kind (not the layout's), or a float asked for (the area's)
        DockDrop drop{DockDropKind::Middle, m_node, kNoDock, -1, DockSide::Start};
        // The keyboard aims at no band (the focus's middle is no aim): into the stack it is in.
        if (!query.FromKeyboard && (!m_space->DropAt(m_space->FromNode(*this, query.Local), m_node, drop) || drop.Kind == DockDropKind::Edge))
            return;
        m_space->Offer(*this, query, dragged, drop);
    }
    inline void DockStack::OnDragLeave(const DragEvent&) { m_space->Withdraw(*this); }
    inline void DockStack::OnDrop(const DragEvent&) { m_space->TakeOffer(*this); }
    // A tab's context menu: where its panel may go.
    inline void DockStack::OnContextMenu(const MouseEvent& event)
    {
        for (Node* n = event.Target; n != nullptr && n != this; n = n->GetParent())
            if (Tab* tab = Cast<Tab>(n); tab != nullptr && tab->GetBar() == GetBar())
            {
                const Node* page = tab->GetPage();
                const String* panel = page != nullptr ? m_space->PanelOf(*page) : nullptr;
                if (panel != nullptr)
                {
                    const String moving = *panel;
                    event.Handled = m_space->OpenMoveTo(moving.AsView(), *tab, event.Position) != nullptr;
                }
                return;
            }
    }
}
