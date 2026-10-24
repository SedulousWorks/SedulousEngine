// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Inspector - the queries (E8e of Specs/gui-lab-evolution.md): the tree in order with depths
// and labels, a node described, a selector query, a property set through markup's path.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.gui.inspector;

using namespace foundation::gui;
namespace inspector = foundation::gui::inspector;
namespace core = foundation::core;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // A root holding a panel (#page) with a button (#ok .primary) and a hidden label.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Panel> page = core::MakeRef<Panel>(core::DefaultAllocator());
        core::RefPtr<Button> ok = core::MakeRef<Button>(core::DefaultAllocator());
        core::RefPtr<Label> note = core::MakeRef<Label>(core::DefaultAllocator());

        Bed()
        {
            root->SetSize(core::Float2{300.0f, 200.0f});
            page->SetId(SV(u8"page"));
            root->AddChild(page.Get());
            ok->SetId(SV(u8"ok"));
            ok->AddClass(SV(u8"primary"));
            ok->SetText(SV(u8"OK"));
            page->AddChild(ok.Get());
            note->SetVisible(false);
            page->AddChild(note.Get());
            root->UpdateLayout();
        }
    };
}

TEST_CASE("inspector: the tree comes in document order with depths, labels and what shows")
{
    Bed bed;
    const core::Array<inspector::TreeEntry> tree = inspector::Tree(*bed.root.Get());
    REQUIRE(tree.Size() >= 4u); // the root, the page, the button (and its parts), the label
    CHECK(tree[0].Target == bed.root.Get());
    CHECK(tree[0].Depth == 0u);
    CHECK(tree[1].Target == bed.page.Get());
    CHECK(tree[1].Depth == 1u);
    CHECK(tree[1].Label == SV(u8"Panel #page"));
    CHECK(tree[2].Target == bed.ok.Get());
    CHECK(tree[2].Depth == 2u);
    CHECK(tree[2].Label == SV(u8"Button #ok .primary"));
    bool sawNote = false;
    for (const inspector::TreeEntry& e : tree)
        if (e.Target == bed.note.Get())
        {
            sawNote = true;
            CHECK_FALSE(e.Shown);
        }
    CHECK(sawNote);
}

TEST_CASE("inspector: a node described: identity, states (forced ones marked), box, reflected properties, commands and listeners")
{
    Bed bed;
    bed.ok->SetForcedStyleStates(Node::StateHover);
    bed.ok->SetPadding(Thickness{3.0f});
    (void)bed.ok->OnCommand(SV(u8"demo.go"), [](CommandEvent&) {});
    (void)bed.ok->AddEventListener(EventType::MouseClick, [](const Event&) {});
    const inspector::NodeDescription d = inspector::Describe(*bed.ok.Get());
    CHECK(d.Type == SV(u8"Button"));
    CHECK(d.Tag == SV(u8"button"));
    CHECK(d.Id == SV(u8"ok"));
    REQUIRE(d.Classes.Size() == 1u);
    CHECK(d.Classes[0] == SV(u8"primary"));
    REQUIRE(d.States.Size() == 1u);
    CHECK(d.States[0] == SV(u8"hover (forced)"));
    CHECK(d.Padding.Left == doctest::Approx(3.0f));
    CHECK(d.Shown);
    REQUIRE(d.Commands.Size() == 1u);
    CHECK(d.Commands[0] == SV(u8"demo.go"));
    REQUIRE(d.Listeners.Size() == 1u);
    CHECK(d.Listeners[0] == SV(u8"click"));
    bool sawText = false;
    for (const inspector::ReflectedValue& p : d.Properties)
        if (p.Name == SV(u8"text"))
        {
            sawText = true;
            CHECK(p.Value == SV(u8"OK"));
        }
    CHECK(sawText);
}

TEST_CASE("inspector: a selector query finds the widgets it matches, in order")
{
    Bed bed;
    const core::Array<Node*> buttons = inspector::Query(*bed.root.Get(), SV(u8"#page > .primary"));
    REQUIRE(buttons.Size() == 1u);
    CHECK(buttons[0] == bed.ok.Get());
    CHECK(inspector::Query(*bed.root.Get(), SV(u8"label")).Size() >= 1u);
    CHECK(inspector::Query(*bed.root.Get(), SV(u8".nothing")).IsEmpty());
}

TEST_CASE("inspector: a property set as markup sets it: the widget's own attribute, else inline style")
{
    Bed bed;
    CHECK(inspector::SetProperty(*bed.ok.Get(), SV(u8"text"), SV(u8"Go")));
    CHECK(bed.ok->GetText() == SV(u8"Go"));
    CHECK(inspector::SetProperty(*bed.ok.Get(), SV(u8"opacity"), SV(u8"0.5")));
    bool inlineSet = false;
    for (const InlineStyleDeclaration& d : bed.ok->GetInlineStyle())
        inlineSet = inlineSet || (d.Name == SV(u8"opacity") && d.Value == SV(u8"0.5"));
    CHECK(inlineSet);
    CHECK_FALSE(inspector::SetProperty(*bed.ok.Get(), SV(u8"no-such-property"), SV(u8"1")));
    CHECK_FALSE(inspector::SetProperty(*bed.root.Get(), SV(u8"opacity"), SV(u8"1"))); // no widget
}

TEST_CASE("inspector: what a screen reader is told of a node, and what in the GUI it would trip on")
{
    Bed bed;
    const inspector::AccessDescription ok = inspector::DescribeAccess(*bed.ok.Get());
    CHECK(ok.Own);
    CHECK(ok.Role == core::String(u8"button"));
    CHECK(ok.Name == core::String(u8"OK"));
    bool activates = false;
    for (const core::String& a : ok.Actions)
        activates = activates || a == core::String(u8"activate");
    CHECK(activates);
    const inspector::AccessDescription page = inspector::DescribeAccess(*bed.page.Get());
    CHECK_FALSE(page.Own); // a panel has no role: what it holds is the window's
    CHECK(page.ReadAs.Size() != 0);
    CHECK_FALSE(inspector::DescribeAccess(*bed.note.Get()).Own); // hidden

    CHECK(inspector::AuditAccess(*bed.root.Get()).IsEmpty());
    auto unnamed = core::MakeRef<Button>(core::DefaultAllocator());
    bed.page->AddChild(unnamed.Get());
    bed.ok->SetAccessLabelledBy(core::String(u8"nowhere"));
    const core::Array<inspector::AccessIssue> issues = inspector::AuditAccess(*bed.root.Get());
    REQUIRE(issues.Size() == 2u);
    CHECK(issues[0].Target == bed.ok.Get());
    CHECK(issues[0].Message == core::String(u8"aria-labelledby names no widget: #nowhere"));
    CHECK(issues[1].Target == unnamed.Get());
    CHECK(issues[1].Message == core::String(u8"a focusable button with no name"));
}
