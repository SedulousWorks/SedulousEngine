// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - actions on a SceneRoot's clock: tweens of a plain node's reflected properties (x, y,
// opacity), a sequence of them, waits and calls, a run on a node in no GUI, and a target
// destroyed before its action ends. They moved here from eepp's Move, Fade, Delay, Runnable and
// Sequence actions, which the tweens took the place of (E14).
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::RefPtr<SceneRoot> MakeScene()
    {
        return core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    }
    core::RefPtr<Node> MakeNode() { return core::MakeRef<Node>(core::DefaultAllocator()); }
    core::Duration Sec(double s) { return core::Duration::FromSeconds(s); }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
}

TEST_CASE("action: a tween moves a plain node's position and is dropped once done")
{
    auto root = MakeScene();
    auto node = MakeNode();
    root->AddChild(node.Get());

    node->Animate(SV(u8"x"), SV(u8"100"), 1.0f, SV(u8"linear"));
    CHECK(root->GetActionManager()->Count() == 1);
    root->GetContext().Update(Sec(0.5));
    CHECK(node->GetPosition().x == doctest::Approx(50.0f));
    root->GetContext().Update(Sec(0.5));
    CHECK(node->GetPosition().x == doctest::Approx(100.0f));
    CHECK(root->GetActionManager()->IsEmpty()); // finished: dropped (a reflected property keeps its value)
}

TEST_CASE("action: a plain node's opacity is its reflected one")
{
    auto root = MakeScene();
    auto node = MakeNode();
    root->AddChild(node.Get());

    node->Animate(SV(u8"opacity"), SV(u8"0"), 1.0f, SV(u8"linear"))->From(SV(u8"1"));
    root->GetContext().Update(Sec(0.25));
    CHECK(node->GetAlpha() == doctest::Approx(0.75f));
    root->GetContext().Update(Sec(0.75));
    CHECK(node->GetAlpha() == doctest::Approx(0.0f));
}

TEST_CASE("action: a call after a wait fires once")
{
    auto root = MakeScene();
    auto node = MakeNode();
    root->AddChild(node.Get());

    int calls = 0;
    auto sequence = core::MakeRef<TweenSequence>(core::DefaultAllocator());
    sequence->Wait(0.5f).Call([&calls]() { ++calls; });
    node->RunAction(sequence);
    root->GetContext().Update(Sec(0.25));
    CHECK(calls == 0);
    root->GetContext().Update(Sec(0.25));
    CHECK(calls == 1);
    root->GetContext().Update(Sec(0.5));
    CHECK(calls == 1);
    CHECK(root->GetActionManager()->IsEmpty());
}

TEST_CASE("action: a sequence of moves runs them in order")
{
    auto root = MakeScene();
    auto node = MakeNode();
    root->AddChild(node.Get());

    auto sequence = core::MakeRef<TweenSequence>(core::DefaultAllocator());
    sequence->Add(node->CreateTween(SV(u8"x"), SV(u8"100"), 1.0f, SV(u8"linear")))
        .Add(node->CreateTween(SV(u8"y"), SV(u8"50"), 1.0f, SV(u8"linear")));
    node->RunAction(sequence);
    root->GetContext().Update(Sec(1.0));
    CHECK(node->GetPosition().x == doctest::Approx(100.0f));
    CHECK(node->GetPosition().y == doctest::Approx(0.0f));
    root->GetContext().Update(Sec(1.0));
    CHECK(node->GetPosition().y == doctest::Approx(50.0f));
    CHECK(root->GetActionManager()->IsEmpty());
}

TEST_CASE("action: a run on a node in no GUI does nothing")
{
    auto node = MakeNode();
    core::RefPtr<Tween> tween = node->Animate(SV(u8"x"), SV(u8"100"), 1.0f);
    CHECK(tween); // shaped like any, inert
    CHECK(node->GetActionManager() == nullptr);
    CHECK(node->GetPosition().x == doctest::Approx(0.0f));
}

TEST_CASE("action: one whose target is destroyed is dropped, not run on freed memory")
{
    auto root = MakeScene();
    int ticks = 0;
    {
        auto node = MakeNode();
        root->AddChild(node.Get());
        auto wait = core::MakeRef<TweenWait>(core::DefaultAllocator(), 10.0f);
        wait->SetOnDone([&](Action&) { ++ticks; });
        node->RunAction(wait);
        CHECK(root->GetActionManager()->Count() == 1u);
        root->RemoveChild(node.Get()); // the last reference goes with the scope
    }
    root->GetContext().Update(Sec(0.1));
    CHECK(root->GetActionManager()->Count() == 0u);
    CHECK(ticks == 0);
}
