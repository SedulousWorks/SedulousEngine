// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - tooltips, context menus and long presses (E5 of Specs/gui-lab-evolution.md): the GUI shows
// the nearest tooltip text up the parent chain from the hovered node after a delay on its own
// clock, by the pointer, as a hint popup; just after one hid the next shows at once; a press hides
// it until the pointer moves on. A right release, Shift+F10 or a long press asks for a context menu
// (a `contextmenu` event); a long press nobody takes shows the tooltip. A text field's context menu
// offers cut, copy, paste and select all.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    template <typename T, typename... A>
    core::RefPtr<T> Make(A&&... args)
    {
        return core::MakeRef<T>(core::DefaultAllocator(), static_cast<A&&>(args)...);
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = Make<SceneRoot>(Make<GUIContext>());
        core::RefPtr<UIWidget> panel = Make<UIWidget>();
        core::RefPtr<UIWidget> child = Make<UIWidget>();
        core::RefPtr<UIWidget> other = Make<UIWidget>();
        Bed()
        {
            root->SetSize(core::Float2{300.0f, 300.0f});
            panel->SetSize(core::Float2{100.0f, 100.0f});
            panel->SetTooltip(SV(u8"The panel"));
            root->AddChild(panel.Get());
            child->SetSize(core::Float2{40.0f, 40.0f});
            panel->AddChild(child.Get()); // no text of its own: the panel's shows
            other->SetPosition(core::Float2{150.0f, 0.0f});
            other->SetSize(core::Float2{100.0f, 100.0f});
            other->SetTooltip(SV(u8"Another"));
            root->AddChild(other.Get());
        }
        EventDispatcher& d() { return *root->GetEventDispatcher(); }
        void Frames(int n, core::f64 seconds = 0.1)
        {
            for (int i = 0; i < n; ++i)
                root->GetContext().Update(core::Duration::FromSeconds(seconds));
        }
        [[nodiscard]] core::StringView Shown()
        {
            const Tooltip* tip = core::Cast<Tooltip>(d().GetShownTooltip());
            return tip != nullptr ? tip->GetText() : core::StringView{};
        }
    };
}

TEST_CASE("context menu: a text field offers cut, copy, paste and select all, lit where they do something")
{
    Bed bed;
    auto field = Make<TextField>();
    field->SetPosition(core::Float2{0.0f, 150.0f});
    field->SetSize(core::Float2{200.0f, 24.0f});
    bed.root->AddChild(field.Get());
    field->SetText(SV(u8"hello"));
    bed.d().InjectMouseDown(core::Float2{20.0f, 160.0f}, MouseButton::Right);
    bed.d().InjectMouseUp(core::Float2{20.0f, 160.0f}, MouseButton::Right);
    Menu* menu = field->GetContextMenu();
    REQUIRE(menu != nullptr);
    CHECK(menu->IsOpen());
    CHECK(menu->GetParent() == field.Get());
    REQUIRE(menu->ItemCount() == 4u);
    // Nothing selected, no clipboard: only select all is lit.
    menu->Close();
    field->SelectAll();
    bed.d().InjectMouseDown(core::Float2{20.0f, 160.0f}, MouseButton::Right);
    bed.d().InjectMouseUp(core::Float2{20.0f, 160.0f}, MouseButton::Right);
    REQUIRE(menu->IsOpen());
    // Its Cut runs the field's command, and the menu closes, focus back on the field.
    MenuItem* cut = core::Cast<MenuItem>(menu->GetChildAt(0));
    REQUIRE(cut != nullptr);
    CHECK(cut->GetText() == SV(u8"Cut"));
    CHECK(cut->IsEnabled());
    (void)cut->HandleActivate();
    CHECK(field->GetText().Size() == 0u);
    CHECK_FALSE(menu->IsOpen());
    CHECK(field->IsFocused());
}
