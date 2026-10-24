// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the accessibility tree (E9d of Specs/gui-lab-evolution.md): roles from the widget types,
// names, values, ranges and states from their reflected properties and selector states; a node
// with no role passes what it holds up, a leaf's parts are none; markup's role and aria attributes
// override; a bridge that listens gets the whole tree, then only what changed and the focus; a
// platform's requests run through the paths input takes, and one a node does not advertise is
// refused.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    core::Duration Frame() { return core::Duration::FromSeconds(1.0 / 60.0); }

    struct Recorder : IAccessibilityBridge
    {
        bool Listening = true;
        core::Array<AccessTreeUpdate> Updates;
        core::Array<core::String> Spoken;
        bool IsListening() const override { return Listening; }
        void Update(const AccessTreeUpdate& update) override { Updates.PushBack(update); }
        void Announce(core::StringView text, AnnouncePriority) override { Spoken.PushBack(core::String(text)); }
    };

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Node> page;
        explicit Bed(const char8_t* markup)
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            RegisterGuiElements();
            static const ElementSet elements = ElementSet::All();
            MarkupLoader loader(elements, core::DefaultAllocator());
            page = loader.LoadFromString(core::StringView(markup));
            REQUIRE(page);
            root->AddChild(page.Get());
            StyleManager styles(CSSParser::Parse(SV(u8"")));
            styles.ApplyTree(*root.Get()); // inline styles (aria attributes) apply in the style pass
            Step();
        }
        GUIContext& Context() { return root->GetContext(); }
        void Step() { Context().Update(Frame()); }
        Node* Find(core::StringView id) { return Find(*root.Get(), id); }
        static Node* Find(Node& node, core::StringView id)
        {
            if (const UIWidget* w = core::Cast<UIWidget>(&node); w != nullptr && w->GetId() == id)
                return &node;
            for (core::usize i = 0; i < node.ChildCount(); ++i)
                if (Node* found = Find(*node.GetChildAt(i), id))
                    return found;
            return nullptr;
        }
        core::u64 IdOf(core::StringView id)
        {
            const AccessTreeUpdate tree = Context().BuildAccessTree(*root.Get());
            const Node* node = Find(id);
            for (const AccessNode& n : tree.Nodes)
                if (Context().ResolveAccessId(n.Id) == node)
                    return n.Id;
            return 0;
        }
        const AccessNode* Described(const AccessTreeUpdate& tree, core::StringView id)
        {
            const Node* node = Find(id);
            for (const AccessNode& n : tree.Nodes)
                if (Context().ResolveAccessId(n.Id) == node)
                    return &n;
            return nullptr;
        }
    };

    constexpr const char8_t* kForm = u8R"(
        <Panel>
            <Label id="title" text="Settings"/>
            <Button id="save" text="Save"/>
            <CheckBox id="music" text="Music" checked="true"/>
            <Slider id="volume" min="0" max="10" step="1" value="4"/>
            <TextField id="name" placeholder="Your name"/>
            <TextField id="secret" password="true" text="hunter2"/>
        </Panel>)";
}

TEST_CASE("accessibility: roles from the widget types; a panel passes what it holds up; a leaf's parts are none")
{
    Bed bed(kForm);
    const AccessTreeUpdate tree = bed.Context().BuildAccessTree(*bed.root.Get());
    CHECK(tree.Full);
    const AccessNode* root = tree.Find(tree.Root);
    REQUIRE(root != nullptr);
    CHECK(root->Role == AccessRole::Window);
    CHECK(root->Children.Size() == 6u); // the panel has no role: its widgets are the window's
    const AccessNode* save = bed.Described(tree, SV(u8"save"));
    REQUIRE(save != nullptr);
    CHECK(save->Role == AccessRole::Button);
    CHECK(save->Name == core::String(u8"Save"));
    CHECK(save->Children.IsEmpty()); // its label part reads as the button
    CHECK(save->Takes(AccessAction::Activate));
    CHECK(save->Has(AccessFocusable));
    CHECK(bed.Described(tree, SV(u8"title"))->Role == AccessRole::Label);
    CHECK(bed.Described(tree, SV(u8"title"))->Name == core::String(u8"Settings"));
    CHECK_FALSE(bed.Described(tree, SV(u8"title"))->Takes(AccessAction::Activate));
    const AccessNode* music = bed.Described(tree, SV(u8"music"));
    CHECK(music->Role == AccessRole::CheckBox);
    CHECK(music->Has(AccessChecked));
    const AccessNode* volume = bed.Described(tree, SV(u8"volume"));
    CHECK(volume->Role == AccessRole::Slider);
    CHECK(volume->HasNumber);
    CHECK(volume->Number == doctest::Approx(4.0));
    CHECK(volume->Max == doctest::Approx(10.0));
    CHECK(volume->Step == doctest::Approx(1.0));
    CHECK(volume->Takes(AccessAction::Increment));
    const AccessNode* name = bed.Described(tree, SV(u8"name"));
    CHECK(name->Role == AccessRole::TextInput);
    CHECK(name->Description == core::String(u8"Your name")); // its placeholder
    CHECK(name->Has(AccessEditable));
    CHECK(name->Takes(AccessAction::SetValue));
    CHECK(bed.Described(tree, SV(u8"secret"))->Value.Size() == 0u); // a password is not read out
}

TEST_CASE("accessibility: markup's role and aria attributes override what the type says")
{
    Bed bed(u8R"(
        <Panel>
            <Label id="caption" text="Volume"/>
            <Panel id="box" role="group" aria-label="Sound">
                <Slider id="level" aria-labelledby="caption" aria-describedby="hint"/>
                <Label id="hint" text="From quiet to loud"/>
            </Panel>
            <Label id="deco" text="*" aria-hidden="true"/>
        </Panel>)");
    const AccessTreeUpdate tree = bed.Context().BuildAccessTree(*bed.root.Get());
    const AccessNode* box = bed.Described(tree, SV(u8"box"));
    REQUIRE(box != nullptr);
    CHECK(box->Role == AccessRole::Group);
    CHECK(box->Name == core::String(u8"Sound"));
    CHECK(box->Children.Size() == 2u);
    const AccessNode* level = bed.Described(tree, SV(u8"level"));
    CHECK(level->Name == core::String(u8"Volume")); // the label that names it
    CHECK(level->Description == core::String(u8"From quiet to loud"));
    CHECK(level->LabelledBy.Size() == 1u);
    CHECK(bed.Described(tree, SV(u8"deco")) == nullptr); // hidden from screen readers
}

TEST_CASE("accessibility: a listening bridge gets the whole tree, then what changed and the focus")
{
    Bed bed(kForm);
    Recorder bridge;
    bed.Context().SetAccessibilityBridge(&bridge);
    bed.Step();
    REQUIRE(bridge.Updates.Size() == 1u);
    CHECK(bridge.Updates[0].Full);
    CHECK(bridge.Updates[0].Nodes.Size() == 7u); // the window and its six
    bed.Step();
    CHECK(bridge.Updates.Size() == 1u); // nothing changed: nothing sent

    core::Cast<Button>(bed.Find(SV(u8"save")))->SetText(SV(u8"Save all"));
    bed.Step();
    REQUIRE(bridge.Updates.Size() == 2u);
    CHECK_FALSE(bridge.Updates[1].Full);
    const AccessNode* save = bed.Described(bridge.Updates[1], SV(u8"save"));
    REQUIRE(save != nullptr);
    CHECK(save->Name == core::String(u8"Save all"));
    CHECK(bridge.Updates[1].Nodes.Size() <= 3u); // the button and what holds it

    bed.Find(SV(u8"name"))->RequestFocus();
    bed.Step();
    REQUIRE(bridge.Updates.Size() == 3u);
    CHECK(bridge.Updates[2].Focus == bed.IdOf(SV(u8"name")));

    bridge.Listening = false;
    core::Cast<Button>(bed.Find(SV(u8"save")))->SetText(SV(u8"Save"));
    bed.Step();
    CHECK(bridge.Updates.Size() == 3u); // no one listens: nothing built
    bridge.Listening = true;
    bed.Step();
    REQUIRE(bridge.Updates.Size() == 4u);
    CHECK(bridge.Updates[3].Full); // listening again: from the whole tree
    bed.Context().SetAccessibilityBridge(nullptr);
}

TEST_CASE("accessibility: a platform's requests run as input does; what a node does not take is refused")
{
    Bed bed(kForm);
    int clicks = 0;
    core::Cast<Button>(bed.Find(SV(u8"save")))->SetOnClick([&clicks]() { ++clicks; });
    GUIContext& gui = bed.Context();
    CHECK(gui.RunAccessAction(AccessActionRequest{bed.IdOf(SV(u8"save")), AccessAction::Activate, {}, false, 0.0}));
    CHECK(clicks == 1);
    CHECK_FALSE(gui.RunAccessAction(AccessActionRequest{bed.IdOf(SV(u8"title")), AccessAction::Activate, {}, false, 0.0}));

    Slider* volume = core::Cast<Slider>(bed.Find(SV(u8"volume")));
    CHECK(gui.RunAccessAction(AccessActionRequest{bed.IdOf(SV(u8"volume")), AccessAction::Increment, {}, false, 0.0}));
    CHECK(volume->GetValue() == doctest::Approx(5.0));
    CHECK(gui.RunAccessAction(AccessActionRequest{bed.IdOf(SV(u8"volume")), AccessAction::SetValue, {}, true, 8.0}));
    CHECK(volume->GetValue() == doctest::Approx(8.0));

    TextField* name = core::Cast<TextField>(bed.Find(SV(u8"name")));
    CHECK(gui.RunAccessAction(AccessActionRequest{bed.IdOf(SV(u8"name")), AccessAction::SetValue, core::String(u8"Ana"), false, 0.0}));
    CHECK(name->GetText() == SV(u8"Ana"));
    CHECK(gui.RunAccessAction(AccessActionRequest{bed.IdOf(SV(u8"name")), AccessAction::Focus, {}, false, 0.0}));
    CHECK(name->IsFocused());

    // Queued from elsewhere, run in the next frame.
    gui.RequestAccessAction(AccessActionRequest{bed.IdOf(SV(u8"save")), AccessAction::Activate, {}, false, 0.0});
    CHECK(clicks == 1);
    bed.Step();
    CHECK(clicks == 2);
    CHECK_FALSE(gui.RunAccessAction(AccessActionRequest{0xFFFFFFFFull, AccessAction::Focus, {}, false, 0.0})); // no such node
}

TEST_CASE("accessibility: an expander reads expanded or collapsed and takes the other; announcements reach a listener")
{
    Bed bed(u8R"(<Panel><Expander id="more" title="More" open="false"/></Panel>)");
    AccessTreeUpdate tree = bed.Context().BuildAccessTree(*bed.root.Get());
    const AccessNode* more = bed.Described(tree, SV(u8"more"));
    REQUIRE(more != nullptr);
    CHECK(more->Name == core::String(u8"More"));
    CHECK(more->Has(AccessCollapsed));
    CHECK(more->Takes(AccessAction::Expand));
    CHECK(bed.Context().RunAccessAction(AccessActionRequest{more->Id, AccessAction::Expand, {}, false, 0.0}));
    CHECK(core::Cast<Expander>(bed.Find(SV(u8"more")))->IsOpen());
    tree = bed.Context().BuildAccessTree(*bed.root.Get());
    CHECK(bed.Described(tree, SV(u8"more"))->Has(AccessExpanded));

    Recorder bridge;
    bed.Context().Announce(SV(u8"unheard"));
    bed.Context().SetAccessibilityBridge(&bridge);
    bed.Context().Announce(SV(u8"Level 2"), AnnouncePriority::Assertive);
    REQUIRE(bridge.Spoken.Size() == 1u);
    CHECK(bridge.Spoken[0] == core::String(u8"Level 2"));
    bed.Context().SetAccessibilityBridge(nullptr);
}

TEST_CASE("accessibility: a node marked again but reading the same (an animation's frames) is not sent again")
{
    Bed bed(kForm);
    Recorder bridge;
    bed.Context().SetAccessibilityBridge(&bridge);
    bed.Step();
    REQUIRE(bridge.Updates.Size() == 1u);
    bed.Find(SV(u8"save"))->SetAlpha(0.5f); // drawn differently, read the same
    bed.Step();
    CHECK(bridge.Updates.Size() == 1u);
    core::Cast<Button>(bed.Find(SV(u8"save")))->SetText(SV(u8"Save now"));
    bed.Step();
    CHECK(bridge.Updates.Size() == 2u);
    bed.Context().SetAccessibilityBridge(nullptr);
}
