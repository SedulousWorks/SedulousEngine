// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Node tree tests: ownership, reparenting, z-order, geometry, world-space
// conversion, hit testing, visibility, invalidation, and event listeners. Derived from
// eepp Scene::Node behavior, adapted to the RefPtr-owned child tree.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::RefPtr<Node> MakeNode() { return core::MakeRef<Node>(core::DefaultAllocator()); }
}

TEST_CASE("node: add child sets parent and count")
{
    auto root = MakeNode();
    auto child = MakeNode();
    root->AddChild(child.Get());

    CHECK(root->ChildCount() == 1);
    CHECK(root->GetChildAt(0) == child.Get());
    CHECK(child->GetParent() == root.Get());
    CHECK(root->HasChild(child.Get()));
}

TEST_CASE("node: reparenting removes from old parent")
{
    auto a = MakeNode();
    auto b = MakeNode();
    auto child = MakeNode();
    a->AddChild(child.Get());
    b->AddChild(child.Get());

    CHECK(a->ChildCount() == 0);
    CHECK(b->ChildCount() == 1);
    CHECK(child->GetParent() == b.Get());
}

TEST_CASE("node: remove child clears parent")
{
    auto root = MakeNode();
    auto child = MakeNode();
    root->AddChild(child.Get());
    root->RemoveChild(child.Get());

    CHECK(root->ChildCount() == 0);
    CHECK(child->GetParent() == nullptr);
}

TEST_CASE("node: child kept alive by tree after external ref drops")
{
    auto root = MakeNode();
    Node* raw = nullptr;
    {
        auto child = MakeNode();
        raw = child.Get();
        root->AddChild(child.Get());
    } // external RefPtr released; tree still owns it
    CHECK(root->ChildCount() == 1);
    CHECK(root->GetChildAt(0) == raw);
    CHECK(raw->GetParent() == root.Get());
}

TEST_CASE("node: a child held elsewhere outlives its parent and points at none")
{
    auto child = MakeNode();
    {
        auto parent = MakeNode();
        parent->AddChild(child.Get());
    } // the parent's last reference dropped
    CHECK(child->GetParent() == nullptr);
    auto other = MakeNode();
    other->AddChild(child.Get()); // it was reaching the freed parent to leave it
    CHECK(child->GetParent() == other.Get());
}

TEST_CASE("node: z-order and siblings")
{
    auto root = MakeNode();
    auto a = MakeNode();
    auto b = MakeNode();
    auto c = MakeNode();
    root->AddChild(a.Get());
    root->AddChild(b.Get());
    root->AddChild(c.Get());

    CHECK(root->GetFirstChild() == a.Get());
    CHECK(root->GetLastChild() == c.Get());
    CHECK(a->GetNextSibling() == b.Get());
    CHECK(b->GetPrevSibling() == a.Get());

    a->ToFront(); // move a to end (topmost)
    CHECK(root->GetLastChild() == a.Get());
    a->ToBack();
    CHECK(root->GetFirstChild() == a.Get());
}

TEST_CASE("node: size and local bounds")
{
    auto node = MakeNode();
    node->SetSize(core::Float2{120.0f, 40.0f});
    CHECK(node->GetSize() == core::Float2{120.0f, 40.0f});
    Rect b = node->GetLocalBounds();
    CHECK(b == Rect{0.0f, 0.0f, 120.0f, 40.0f});
}

TEST_CASE("node: world position accumulates parent chain")
{
    auto root = MakeNode();
    auto child = MakeNode();
    root->AddChild(child.Get());
    root->SetPosition(core::Float2{100.0f, 0.0f});
    child->SetPosition(core::Float2{10.0f, 5.0f});

    const core::Float2 screen = child->GetScreenPosition();
    CHECK(screen.x == doctest::Approx(110.0f));
    CHECK(screen.y == doctest::Approx(5.0f));
}

TEST_CASE("node: hit test returns topmost child")
{
    auto root = MakeNode();
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto a = MakeNode();
    auto b = MakeNode();
    a->SetSize(core::Float2{100.0f, 100.0f});
    b->SetSize(core::Float2{100.0f, 100.0f});
    root->AddChild(a.Get());
    root->AddChild(b.Get()); // b is topmost in the overlap

    CHECK(root->OverFind(core::Float2{50.0f, 50.0f}) == b.Get());
    CHECK(root->OverFind(core::Float2{150.0f, 150.0f}) == root.Get()); // only root there
    CHECK(root->OverFind(core::Float2{300.0f, 300.0f}) == nullptr);    // outside all
}

TEST_CASE("node: hidden node is not hit and hides subtree")
{
    auto root = MakeNode();
    root->SetSize(core::Float2{100.0f, 100.0f});
    root->SetVisible(false);
    CHECK_FALSE(root->IsVisible());
    CHECK(root->OverFind(core::Float2{50.0f, 50.0f}) == nullptr);
}

TEST_CASE("node: tree visibility follows parents")
{
    auto root = MakeNode();
    auto child = MakeNode();
    root->AddChild(child.Get());
    CHECK(child->IsTreeVisible());
    root->SetVisible(false);
    CHECK_FALSE(child->IsTreeVisible());
    CHECK(child->IsVisible()); // its own flag is still true
}

TEST_CASE("node: invalidation bubbles to ancestors")
{
    auto root = MakeNode();
    auto child = MakeNode();
    root->AddChild(child.Get());
    root->ClearNeedsRedraw();
    child->ClearNeedsRedraw();

    child->SetSize(core::Float2{10.0f, 10.0f});
    CHECK(child->NeedsRedraw());
    CHECK(root->NeedsRedraw()); // bubbled up
}

TEST_CASE("node: event listener fires on size change")
{
    auto node = MakeNode();
    int fired = 0;
    EventType seen = EventType::Close;
    const auto id = node->AddEventListener(EventType::SizeChanged,
                                           [&](const Event& e)
                                           {
                                               ++fired;
                                               seen = e.Type;
                                           });

    node->SetSize(core::Float2{10.0f, 10.0f});
    CHECK(fired == 1);
    CHECK(seen == EventType::SizeChanged);

    node->RemoveEventListener(id);
    node->SetSize(core::Float2{20.0f, 20.0f});
    CHECK(fired == 1); // no longer listening
}

TEST_CASE("node: a listener removes itself or adds another while listeners run (E16)")
{
    auto node = MakeNode();
    int first = 0, second = 0, added = 0;
    core::u32 firstId = 0;
    firstId = node->AddEventListener(EventType::SizeChanged,
                                     [&](const Event&)
                                     {
                                         ++first;
                                         CHECK(node->RemoveEventListener(firstId)); // its own: from inside it
                                         (void)node->AddEventListener(EventType::SizeChanged, [&](const Event&) { ++added; });
                                     });
    (void)node->AddEventListener(EventType::SizeChanged, [&](const Event&) { ++second; });
    node->SetSize(core::Float2{10.0f, 10.0f});
    CHECK(first == 1);
    CHECK(second == 1);  // the one after it still ran
    CHECK(added == 0);   // the one added waits for the next event
    node->SetSize(core::Float2{20.0f, 20.0f});
    CHECK(first == 1);   // gone
    CHECK(second == 2);
    CHECK(added == 1);
    CHECK_FALSE(node->RemoveEventListener(firstId)); // already gone
}

TEST_CASE("node: a command handler removes itself while it runs (E16)")
{
    auto node = MakeNode();
    int ran = 0;
    core::u32 token = 0;
    token = node->OnCommand(core::StringView(u8"go"), [&](CommandEvent&) { ++ran; CHECK(node->RemoveCommandHandler(token)); });
    CHECK(node->HandlesCommand(core::StringView(u8"go")));
    CommandEvent event;
    event.Id = core::StringView(u8"go");
    CHECK(node->RunCommandHandlers(event));
    CHECK(ran == 1);
    CHECK_FALSE(node->HandlesCommand(core::StringView(u8"go")));
    CHECK_FALSE(node->RunCommandHandlers(event));
}

TEST_CASE("node: setting same size does not notify")
{
    auto node = MakeNode();
    node->SetSize(core::Float2{10.0f, 10.0f});
    int fired = 0;
    node->AddEventListener(EventType::SizeChanged, [&](const Event&) { ++fired; });
    node->SetSize(core::Float2{10.0f, 10.0f}); // unchanged
    CHECK(fired == 0);
}

TEST_CASE("node: a child's index follows adds, moves, removes and a move to another parent")
{
    auto root = MakeNode();
    core::Array<core::RefPtr<Node>> kids;
    for (int i = 0; i < 5; ++i)
    {
        kids.PushBack(MakeNode());
        root->AddChild(kids[static_cast<core::usize>(i)].Get());
    }
    for (core::usize i = 0; i < 5; ++i)
        CHECK(root->GetChildIndex(kids[i].Get()) == i);
    root->SetChildIndex(kids[4].Get(), 1);
    CHECK(root->GetChildIndex(kids[4].Get()) == 1);
    CHECK(root->GetChildIndex(kids[1].Get()) == 2);
    root->RemoveChild(kids[0].Get());
    CHECK(root->GetChildIndex(kids[0].Get()) == Node::kInvalidIndex);
    CHECK(root->GetChildIndex(kids[4].Get()) == 0);
    CHECK(kids[1]->GetPrevSibling() == kids[4].Get());

    auto other = MakeNode();
    other->AddChild(MakeNode().Get());
    other->AddChild(kids[3].Get());
    CHECK(other->GetChildIndex(kids[3].Get()) == 1);
    CHECK(root->GetChildIndex(kids[3].Get()) == Node::kInvalidIndex);
    CHECK(root->GetChildIndex(kids[2].Get()) == 2);
    CHECK(root->GetChildIndex(nullptr) == Node::kInvalidIndex);
}
