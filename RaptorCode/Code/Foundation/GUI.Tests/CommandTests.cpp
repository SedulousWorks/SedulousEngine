// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - commands (G7 of Specs/vg-and-gui-lab.md): one model controls bind to by id; running walks
// the focus path (capture down, bubble up, a bubble handler stopping it unless it propagates); a
// command is available when enabled with a handler on the focus path, and its state reaches a
// button, a checkbox and a menu item with no bookkeeping; a handler may end the nodes on its path.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    void Frame(SceneRoot& root) { root.GetContext().Update(core::Duration::FromSeconds(0.016)); }
}

TEST_CASE("command: markup binds a control to a command by id, before it is attached")
{
    RegisterGuiElements();
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    (void)root->OnCommand(SV(u8"play"), [](CommandEvent&) {});
    root->GetContext().DefineCommand(SV(u8"play")).SetEnabled(false);
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    auto tree = loader.LoadFromString(SV(u8R"(<Button command="play" text="Play"/>)"));
    REQUIRE(tree.Get() != nullptr);
    auto* play = core::Cast<Button>(tree.Get());
    REQUIRE(play != nullptr);
    CHECK(play->GetCommand() == SV(u8"play"));
    root->AddChild(tree.Get()); // joining the GUI reaches its binding
    Frame(*root.Get());
    CHECK_FALSE(play->IsEnabled());
    root->GetContext().DefineCommand(SV(u8"play")).SetEnabled(true);
    Frame(*root.Get());
    CHECK(play->IsEnabled());
}

namespace
{
    // A control that keeps the state its command's binding last told it.
    class StateProbe : public UIWidget
    {
    public:
        void OnBoundCommandState(const BoundCommandState& state) override
        {
            UIWidget::OnBoundCommandState(state);
            Available = state.Available;
            Reason = core::String(state.Reason);
        }
        bool Available = false;
        core::String Reason;
    };
}

