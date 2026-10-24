// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - ListBox tests: add/clear items, click + keyboard selection, the selection
// callback, and scroll-into-view for an off-screen selection.
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

    core::RefPtr<ListBox> MakeList(SceneRoot* root, float w, float h)
    {
        auto lb = core::MakeRef<ListBox>(core::DefaultAllocator());
        lb->SetSize(core::Float2{w, h});
        lb->SetItemHeight(24.0f);
        root->AddChild(lb.Get());
        return lb;
    }
}

TEST_CASE("listbox: add / count / get / clear items")
{
    auto lb = Make<ListBox>();
    lb->SetSize(core::Float2{200.0f, 100.0f});
    lb->AddItem(core::StringView(u8"Alpha"));
    lb->AddItem(core::StringView(u8"Beta"));
    lb->AddItem(core::StringView(u8"Gamma"));

    CHECK(lb->ItemCount() == 3);
    CHECK(lb->GetItem(1) == core::StringView(u8"Beta"));
    CHECK(lb->GetSelectedIndex() == -1);

    lb->Clear();
    CHECK(lb->ItemCount() == 0);
    CHECK(lb->GetSelectedIndex() == -1);
}

TEST_CASE("listbox: SetSelectedIndex highlights and fires the callback, only on change")
{
    auto lb = Make<ListBox>();
    lb->SetSize(core::Float2{200.0f, 100.0f});
    for (int i = 0; i < 5; ++i)
        lb->AddItem(core::StringView(u8"item"));

    int changes = 0, last = -99;
    lb->SetOnSelectionChanged(
        [&](int i)
        {
            ++changes;
            last = i;
        });

    lb->SetSelectedIndex(2);
    CHECK(lb->GetSelectedIndex() == 2);
    CHECK(changes == 1);
    CHECK(last == 2);
    lb->SetSelectedIndex(2); // no change
    CHECK(changes == 1);
    lb->SetSelectedIndex(4);
    CHECK(changes == 2);
    CHECK(last == 4);

    lb->SetSelectedIndex(99); // out of range -> ignored
    CHECK(lb->GetSelectedIndex() == 4);
}

TEST_CASE("listbox: clicking a row selects it")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto lb = MakeList(root.Get(), 200.0f, 100.0f);
    for (int i = 0; i < 10; ++i)
        lb->AddItem(core::StringView(u8"row"));
    EventDispatcher* d = root->GetEventDispatcher();

    // Row 2 spans y in [48, 72); click it.
    d->InjectMouseDown(core::Float2{10.0f, 60.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{10.0f, 60.0f}, MouseButton::Left);
    CHECK(lb->GetSelectedIndex() == 2);
}

TEST_CASE("listbox: keyboard navigation moves the selection")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto lb = MakeList(root.Get(), 200.0f, 100.0f);
    for (int i = 0; i < 6; ++i)
        lb->AddItem(core::StringView(u8"row"));
    EventDispatcher* d = root->GetEventDispatcher();
    lb->RequestFocus();

    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Down)); // -1 -> 0
    CHECK(lb->GetSelectedIndex() == 0);
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Down)); // -> 1
    CHECK(lb->GetSelectedIndex() == 1);
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::End)); // -> last (5)
    CHECK(lb->GetSelectedIndex() == 5);
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Down)); // clamps at last
    CHECK(lb->GetSelectedIndex() == 5);
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Home)); // -> 0
    CHECK(lb->GetSelectedIndex() == 0);
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Up)); // clamps at 0
    CHECK(lb->GetSelectedIndex() == 0);
}

TEST_CASE("listbox: selecting an off-screen row scrolls it into view")
{
    auto lb = Make<ListBox>();
    lb->SetSize(core::Float2{200.0f, 100.0f}); // viewport 100 tall
    for (int i = 0; i < 10; ++i)
        lb->AddItem(core::StringView(u8"row")); // content 240 tall, range 140

    CHECK(lb->GetScrollOffset().y == doctest::Approx(0.0f));
    lb->SetSelectedIndex(
        9); // row 9 -> [216, 240]; scroll so bottom hits viewport bottom: 240-100 = 140
    CHECK(lb->GetScrollOffset().y == doctest::Approx(140.0f));

    lb->SetSelectedIndex(0); // back to top
    CHECK(lb->GetScrollOffset().y == doctest::Approx(0.0f));
}
