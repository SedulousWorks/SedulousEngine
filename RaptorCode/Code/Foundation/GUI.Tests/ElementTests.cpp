// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - elements (G1 of Specs/vg-and-gui-lab.md): weak references through a GUI's own element
// table, the element registry any library adds to, and the element set one GUI may create from.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::RefPtr<SceneRoot> MakeGui()
    {
        RegisterGuiElements();
        return core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    }

    // A widget from outside the GUI's core (as a toolkit or a game kit adds one): reflected with
    // a creator and registered under a tag of its own.
    class HealthBar : public UIWidget
    {
        RTTI_OBJECT(HealthBar, UIWidget)
    public:
        core::f32 health = 1.0f;
    };

    // Reflected but with no creator: not an element type.
    class Uncreatable : public UIWidget
    {
        RTTI_OBJECT(Uncreatable, UIWidget)
    };

    // A second type claiming a tag the GUI's Label holds.
    class Impostor : public UIWidget
    {
        RTTI_OBJECT(Impostor, UIWidget)
    };
}

REFLECT_MEMBERS(HealthBar, "rtti::gui::tests")
{
    builder.Attribute("element", core::String(u8"game:HealthBar"));
    builder.Creator();
}
REFLECT_MEMBERS(Uncreatable, "rtti::gui::tests")
{
}
REFLECT_MEMBERS(Impostor, "rtti::gui::tests")
{
    builder.Attribute("element", core::String(u8"Label"));
    builder.Creator();
}

TEST_CASE("elements: a node adds children by tag through its GUI's set, from its own allocator")
{
    core::RefPtr<SceneRoot> gui = MakeGui();
    ElementSet buttonsOnly = ElementSet::None();
    buttonsOnly.Allow(u8"Button");
    gui->GetContext().SetElementSet(core::Move(buttonsOnly));

    CHECK_FALSE(gui->AddElement(u8"Label").IsResolving()); // not in this GUI's set
    const core::Variant handle = gui->AddElement(u8"Button");
    REQUIRE(handle.IsResolving());
    Node* added = Node::FromHandle(handle);
    REQUIRE(added != nullptr);
    CHECK(core::Cast<Button>(added) != nullptr);
    CHECK(added->GetParent() == gui.Get());
    CHECK(&added->MemoryAllocator() == &gui->MemoryAllocator());

    // A detached node has no GUI and no set: nothing is created.
    core::RefPtr<Label> loose = core::MakeRef<Label>(core::DefaultAllocator());
    CHECK_FALSE(loose->AddElement(u8"Button").IsResolving());
    CHECK(loose->ChildCount() == 0u);
}
