// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - docking from the keyboard (D4 of Specs/gui-lab-evolution-3.md): a docked panel's
// tab picked up (`drag.pick`) and dropped on another stack's tab; `dock.focus-*` and `dock.move-*`
// by direction (into the stack that way, else along the surface's edge, the focus going with the
// panel); `dock.maximize` and back; `dock.close`; none bound to a key, the keyboard's way in a tab's
// context menu (Move to, Float, Close).
#include "DockingTestBed.h"

using namespace foundation::gui;
using namespace dockbed;

namespace
{
    struct KeyBed : Bed
    {
        KeyBed() { DefineDockingCommands(*root->GetGUIContext()); }
        bool Run(const char8_t* command) { return root->RunCommand(SV(command)); }
        DockNodeId Focused() const { return space->FocusedStack(); }
    };
}

TEST_CASE("dock keys: a tab picked up from the keyboard is dropped on another stack's tab")
{
    KeyBed bed;
    bed.TabOf(u8"inspector")->RequestFocus();
    REQUIRE(bed.D().PickDrag());
    bed.TabOf(u8"hierarchy")->RequestFocus();
    CHECK(bed.D().GetDropTarget() == bed.ViewOf(u8"hierarchy")->GetBar());
    Rect preview;
    CHECK(bed.Preview(preview));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK(bed.StackOf(u8"inspector") == bed.StackOf(u8"hierarchy"));
}

TEST_CASE("dock keys: focus and move by direction; into the stack that way, else along the edge")
{
    KeyBed bed;
    const DockNodeId central = bed.controller.GetLayout().CentralStack();
    const DockNodeId hierarchy = bed.StackOf(u8"hierarchy");
    const DockNodeId console = bed.StackOf(u8"console");
    bed.TabOf(u8"inspector")->RequestFocus();
    CHECK(bed.Focused() == central);
    CHECK(bed.Run(u8"dock.focus-down"));
    CHECK(bed.Focused() == console);
    CHECK(bed.Run(u8"dock.focus-left")); // the hierarchy spans the whole height
    CHECK(bed.Focused() == hierarchy);
    (void)bed.Run(u8"dock.focus-left"); // nothing that way: it stays
    CHECK(bed.Focused() == hierarchy);

    bed.TabOf(u8"inspector")->RequestFocus();
    CHECK(bed.Run(u8"dock.move-left")); // into the hierarchy's stack, the focus with it
    CHECK(bed.StackOf(u8"inspector") == hierarchy);
    CHECK(bed.Focused() == hierarchy);
    bed.Lay();
    CHECK(bed.Run(u8"dock.move-up")); // nothing above: along the surface's top
    const DockLayout& layout = bed.controller.GetLayout();
    const DockNode* root = layout.FindNode(layout.FindSurface(layout.MainSurface())->Root);
    CHECK(root->Axis == DockAxis::Vertical);
    CHECK(root->Children[0] == bed.StackOf(u8"inspector"));
    CHECK(bed.Focused() == bed.StackOf(u8"inspector"));
}

TEST_CASE("dock keys: maximize and back, close; no key bound to them")
{
    KeyBed bed;
    const DockNodeId central = bed.controller.GetLayout().CentralStack();
    bed.TabOf(u8"inspector")->RequestFocus();
    CHECK(bed.Run(u8"dock.maximize"));
    CHECK(bed.controller.GetLayout().FindSurface(bed.controller.GetLayout().MainSurface())->Maximized == central);
    CHECK(bed.Focused() == central);
    CHECK(bed.Run(u8"dock.maximize"));
    CHECK(bed.controller.GetLayout().FindSurface(bed.controller.GetLayout().MainSurface())->Maximized == kNoDock);

    CHECK(bed.Run(u8"dock.close"));
    CHECK(bed.StackOf(u8"inspector") == kNoDock);

    // No key is bound to them: docking is the pointer's, and the keys a desktop leaves free differ.
    const char8_t* const commands[] = {u8"dock.focus-left", u8"dock.move-down", u8"dock.maximize", u8"dock.close",
                                       u8"dock.move-to", u8"dock.float", u8"dock.next-surface", u8"dock.previous-surface"};
    for (const char8_t* command : commands)
    {
        CHECK(bed.root->GetGUIContext()->GetCommands().Find(SV(command)) != nullptr);
        CHECK(bed.root->GetGUIContext()->GetKeymap().ShortcutText(SV(command)).IsEmpty());
    }
}

TEST_CASE("dock keys: the keyboard's way in is a focused tab's context menu (Shift+F10), Move to")
{
    KeyBed bed;
    bed.TabOf(u8"inspector")->RequestFocus();
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::F10), KeyModShift);
    bed.root->GetGUIContext()->Update(core::Duration::FromSeconds(0.016)); // the binding runs in the frame
    Menu* menu = bed.space->GetMoveMenu();
    REQUIRE(menu != nullptr);
    CHECK(menu->IsOpen());
}

namespace
{
    MenuItem* Row(Menu& menu, const char8_t* text)
    {
        for (usize i = 0; i < menu.ChildCount(); ++i)
            if (MenuItem* item = Cast<MenuItem>(menu.GetChildAt(i)); item != nullptr && item->GetText() == SV(text))
                return item;
        return nullptr;
    }
    Menu* Sub(Menu& menu, const char8_t* text)
    {
        MenuItem* row = Row(menu, text);
        MenuSubItem* sub = row != nullptr ? Cast<MenuSubItem>(row) : nullptr;
        return sub != nullptr ? sub->GetSubMenu() : nullptr;
    }
}

TEST_CASE("dock keys: the Move to menu, from a tab's context menu or dock.move-to: each place, those refused disabled")
{
    KeyBed bed;
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.SetStackFlags(bed.StackOf(u8"console"), DockStackNoTabs); }).Ok());
    bed.Lay();
    const core::Float2 at = Bed::Centre(Bed::Bounds(*bed.TabOf(u8"inspector")));
    bed.D().InjectMouseDown(at, MouseButton::Right);
    bed.D().InjectMouseUp(at, MouseButton::Right);
    Menu* menu = bed.space->GetMoveMenu();
    REQUIRE(menu != nullptr);
    CHECK(menu->IsOpen());
    Menu* into = Sub(*menu, u8"Into");
    REQUIRE(into != nullptr);
    CHECK(Row(*into, u8"scene, inspector") == nullptr); // not its own stack
    REQUIRE(Row(*into, u8"console") != nullptr);
    CHECK_FALSE(Row(*into, u8"console")->IsEnabled()); // the console's stack takes no tabs
    REQUIRE(Row(*into, u8"hierarchy") != nullptr);
    CHECK(Row(*into, u8"hierarchy")->IsEnabled());
    Menu* beside = Sub(*menu, u8"Beside");
    REQUIRE(beside != nullptr);
    Menu* besideConsole = Sub(*beside, u8"console");
    REQUIRE(besideConsole != nullptr);
    REQUIRE(Row(*besideConsole, u8"Right") != nullptr);
    Row(*besideConsole, u8"Right")->HandleActivate(); // as Return on it
    CHECK_FALSE(menu->IsOpen());
    const DockNodeId inspector = bed.StackOf(u8"inspector");
    const DockNode* split = bed.controller.GetLayout().FindNode(bed.controller.GetLayout().FindNode(inspector)->Parent);
    REQUIRE(split != nullptr);
    CHECK(split->Children[1] == inspector);
    CHECK(split->Children[0] == bed.StackOf(u8"console"));
    CHECK(bed.Focused() == inspector); // the focus went with it

    bed.Lay();
    REQUIRE(bed.Run(u8"dock.move-to"));
    menu = bed.space->GetMoveMenu();
    REQUIRE(menu != nullptr);
    CHECK(menu->IsOpen());
    Menu* edge = Sub(*menu, u8"Along the Edge");
    REQUIRE(edge != nullptr);
    Row(*edge, u8"Top")->HandleActivate();
    const DockLayout& layout = bed.controller.GetLayout();
    const DockNode* root = layout.FindNode(layout.FindSurface(layout.MainSurface())->Root);
    CHECK(root->Axis == DockAxis::Vertical);
    CHECK(root->Children[0] == bed.StackOf(u8"inspector"));
}

TEST_CASE("dock keys: a tab's context menu ends with Close, disabled for a panel that cannot be closed")
{
    KeyBed bed;
    DockPanelDescription fixed;
    fixed.Id = core::String(u8"fixed");
    fixed.Closable = false;
    fixed.Factory = []() { return core::RefPtr<Node>(core::MakeRef<Panel>(core::DefaultAllocator())); };
    REQUIRE(bed.controller.Register(core::Move(fixed)));
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(u8"fixed"), bed.StackOf(u8"hierarchy")); }).Ok());
    bed.Lay();

    bed.TabOf(u8"inspector")->RequestFocus();
    REQUIRE(bed.Run(u8"dock.move-to"));
    Menu* menu = bed.space->GetMoveMenu();
    REQUIRE(menu != nullptr);
    MenuItem* close = Row(*menu, u8"Close");
    REQUIRE(close != nullptr);
    CHECK(close->IsEnabled());
    close->HandleActivate();
    CHECK_FALSE(menu->IsOpen());
    CHECK(bed.StackOf(u8"inspector") == kNoDock);

    bed.Lay();
    bed.TabOf(u8"fixed")->RequestFocus();
    REQUIRE(bed.Run(u8"dock.move-to"));
    menu = bed.space->GetMoveMenu();
    REQUIRE(menu != nullptr);
    REQUIRE(Row(*menu, u8"Close") != nullptr);
    CHECK_FALSE(Row(*menu, u8"Close")->IsEnabled());
}
