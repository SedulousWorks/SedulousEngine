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

TEST_CASE("elements: a weak reference resolves while the element lives and not after")
{
    core::RefPtr<SceneRoot> gui = MakeGui();
    core::RefPtr<Button> button = core::MakeRef<Button>(core::DefaultAllocator());
    // Detached, an element has no GUI a reference could resolve through.
    CHECK_FALSE(Element<Button>(*button).IsValid());
    gui->AddChild(button.Get());
    Element<Button> weak(*button);
    REQUIRE(weak.IsValid());
    CHECK(weak.Get() == button.Get());

    button->RemoveFromParent();
    CHECK(weak.IsValid()); // still alive (the test holds it), so still itself
    button = core::RefPtr<Button>{};
    CHECK_FALSE(weak.IsValid()); // destroyed: gone, not freed memory
}

TEST_CASE("elements: a freed slot taken by a new element does not answer to the old reference")
{
    core::RefPtr<SceneRoot> gui = MakeGui();
    core::RefPtr<Label> first = core::MakeRef<Label>(core::DefaultAllocator());
    gui->AddChild(first.Get());
    Element<Label> old(*first);
    const Node::ElementRef firstRef = first->TakeElementRef();
    gui->RemoveChild(first.Get());
    first = core::RefPtr<Label>{};

    core::RefPtr<Label> second = core::MakeRef<Label>(core::DefaultAllocator());
    gui->AddChild(second.Get());
    Element<Label> fresh(*second);
    const Node::ElementRef secondRef = second->TakeElementRef();
    CHECK(secondRef.slot == firstRef.slot);             // the slot is reused...
    CHECK(secondRef.generation != firstRef.generation); // ...under a new generation
    CHECK_FALSE(old.IsValid());
    CHECK(fresh.Get() == second.Get());
}

TEST_CASE("elements: two GUIs keep their own tables, and a GUI going leaves its references gone")
{
    core::RefPtr<SceneRoot> a = MakeGui();
    core::RefPtr<SceneRoot> b = MakeGui();
    CHECK(a->GetElementTable() != b->GetElementTable());
    core::RefPtr<Label> inA = core::MakeRef<Label>(core::DefaultAllocator());
    core::RefPtr<Label> inB = core::MakeRef<Label>(core::DefaultAllocator());
    a->AddChild(inA.Get());
    b->AddChild(inB.Get());
    Element<Label> weakA(*inA);
    Element<Label> weakB(*inB);
    CHECK(inA->TakeElementRef().table == a->GetElementTable());
    CHECK(inB->TakeElementRef().table == b->GetElementTable());

    // A's GUI goes while its label lives on elsewhere and a reference to it is held: the table
    // closes (held alive by the reference), so the reference reads as gone; B is untouched.
    a = core::RefPtr<SceneRoot>{};
    CHECK_FALSE(weakA.IsValid());
    CHECK(weakB.Get() == inB.Get());
}

TEST_CASE("elements: the registry takes a library's widgets and refuses what is not an element")
{
    RegisterGuiElements();
    CHECK(ElementTypes::Find(u8"Button") == &Button::StaticType());
    CHECK(ElementTypes::Find(u8"Panel") == &Panel::StaticType());

    // A library's widget under its namespaced tag.
    REQUIRE(ElementTypes::Register(HealthBar::StaticType()));
    CHECK(ElementTypes::TagOf(HealthBar::StaticType()) == core::StringView(u8"game:HealthBar"));
    CHECK(ElementTypes::Find(u8"game:HealthBar") == &HealthBar::StaticType());
    CHECK(ElementTypes::Register(HealthBar::StaticType())); // again: already there, fine

    // No creator, or another type's tag: refused, and the tag keeps its type.
    CHECK_FALSE(ElementTypes::Register(Uncreatable::StaticType()));
    CHECK(ElementTypes::Find(u8"Uncreatable") == nullptr);
    CHECK_FALSE(ElementTypes::Register(Impostor::StaticType()));
    CHECK(ElementTypes::Find(u8"Label") == &Label::StaticType());

    // A library unloading takes its widgets out.
    ElementTypes::Unregister(HealthBar::StaticType());
    CHECK(ElementTypes::Find(u8"game:HealthBar") == nullptr);
}

TEST_CASE("elements: a GUI's element set decides what its markup may create")
{
    RegisterGuiElements();
    REQUIRE(ElementTypes::Register(HealthBar::StaticType()));
    const char8_t* markup = u8R"(<Panel><Label text="hp"/><game:HealthBar/><Hp/></Panel>)";

    // Everything registered, a library's widget included; an unknown tag is left out.
    {
        const ElementSet all = ElementSet::All();
        MarkupLoader loader(all, core::DefaultAllocator());
        core::RefPtr<Node> root = loader.LoadFromString(core::StringView(markup));
        REQUIRE(root);
        REQUIRE(root->ChildCount() == 2u);
        CHECK(core::Cast<HealthBar>(root->GetChildAt(1)) != nullptr);
    }
    // Only what the set allows, under its own aliases.
    {
        ElementSet limited = ElementSet::None();
        limited.Allow(u8"Panel");
        limited.Allow(u8"game:HealthBar");
        limited.Alias(u8"Hp", u8"game:HealthBar");
        MarkupLoader loader(limited, core::DefaultAllocator());
        core::RefPtr<Node> root = loader.LoadFromString(core::StringView(markup));
        REQUIRE(root);
        REQUIRE(root->ChildCount() == 2u); // the Label is not allowed; Hp is a HealthBar
        CHECK(core::Cast<HealthBar>(root->GetChildAt(0)) != nullptr);
        CHECK(core::Cast<HealthBar>(root->GetChildAt(1)) != nullptr);
    }
    ElementTypes::Unregister(HealthBar::StaticType());
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
