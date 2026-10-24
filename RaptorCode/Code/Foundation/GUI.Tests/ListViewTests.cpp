// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - ListView tests: virtualization (only visible rows realized), single selection
// via mouse + keyboard, wheel/scroll-into-view, and reacting to model updates.
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

    core::Array<core::String> MakeItems(int count)
    {
        core::Array<core::String> items;
        for (int i = 0; i < count; ++i)
            items.PushBack(core::String(SV(u8"item")));
        return items;
    }
}

TEST_CASE("listview: virtualizes - only visible rows are realized")
{
    StringListModel model(MakeItems(1000));
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 100.0f});
    list->SetRowHeight(20.0f);
    root->AddChild(list.Get());
    list->SetModel(&model);
    (void)root->UpdateLayout();

    // A 100px view of 20px rows: rows 0 to 4, and row 5 past its bottom edge.
    CHECK(list->VisibleRowCount() == 6); // 5 in view and one past the edge, not 1000
    CHECK(list->GetModel() == &model);
}

TEST_CASE("listview: clicking a row selects it and fires the callback")
{
    StringListModel model(MakeItems(10));
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 100.0f});
    list->SetRowHeight(20.0f);
    root->AddChild(list.Get());
    list->SetModel(&model);
    (void)root->UpdateLayout();
    EventDispatcher* d = root->GetEventDispatcher();

    int selectedRow = -1;
    int calls = 0;
    list->SetOnSelectionChanged(
        [&](ModelIndex i)
        {
            selectedRow = i.Row;
            ++calls;
        });

    // Row 2 spans y in [40, 60); click it.
    d->InjectMouseDown(core::Float2{50.0f, 50.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{50.0f, 50.0f}, MouseButton::Left);
    CHECK(list->GetSelectedItem() == 2);
    CHECK(selectedRow == 2);
    CHECK(calls == 1);
    CHECK(list->GetSelectedIndex() == MakeModelIndex(2));
}

TEST_CASE("listview: keyboard navigation moves the selection")
{
    StringListModel model(MakeItems(10));
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 100.0f});
    list->SetRowHeight(20.0f);
    root->AddChild(list.Get());
    list->SetModel(&model);
    (void)root->UpdateLayout();
    EventDispatcher* d = root->GetEventDispatcher();
    list->RequestFocus();

    const auto key = [](KeyCode k) { return static_cast<core::u32>(k); };
    d->InjectKeyDown(key(KeyCode::Down)); // nothing selected -> row 0
    CHECK(list->GetSelectedItem() == 0);
    d->InjectKeyDown(key(KeyCode::Down));
    d->InjectKeyDown(key(KeyCode::Down));
    CHECK(list->GetSelectedItem() == 2);
    d->InjectKeyDown(key(KeyCode::Up));
    CHECK(list->GetSelectedItem() == 1);
    d->InjectKeyDown(key(KeyCode::End));
    CHECK(list->GetSelectedItem() == 9);
    d->InjectKeyDown(key(KeyCode::Home));
    CHECK(list->GetSelectedItem() == 0);
}

TEST_CASE("listview: selecting a far row scrolls it into view")
{
    StringListModel model(MakeItems(20)); // content 400, viewport 100 -> maxScroll 300
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 100.0f});
    list->SetRowHeight(20.0f);
    root->AddChild(list.Get());
    list->SetModel(&model);
    (void)root->UpdateLayout();

    CHECK(list->GetScrollOffset().y == doctest::Approx(0.0f));
    list->SetSelectedItem(19); // last row -> bottom (400) - viewport (100) = 300
    CHECK(list->GetScrollOffset().y == doctest::Approx(300.0f));
    CHECK(list->GetSelectedItem() == 19);
}

TEST_CASE("listview: wheel scrolls and clamps")
{
    StringListModel model(MakeItems(20));
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 100.0f});
    list->SetRowHeight(20.0f);
    root->AddChild(list.Get());
    list->SetModel(&model);
    (void)root->UpdateLayout();
    EventDispatcher* d = root->GetEventDispatcher();

    d->InjectMouseWheel(core::Float2{50.0f, 50.0f}, core::Float2{0.0f, -3.0f}); // down 3 rows
    CHECK(list->GetScrollOffset().y == doctest::Approx(60.0f));
    d->InjectMouseWheel(core::Float2{50.0f, 50.0f},
                        core::Float2{0.0f, -100.0f}); // clamps to maxScroll
    CHECK(list->GetScrollOffset().y == doctest::Approx(300.0f));
}

TEST_CASE("listview: reacts to model updates and clamps a stale selection")
{
    StringListModel model(MakeItems(5));
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 100.0f});
    list->SetRowHeight(20.0f);
    root->AddChild(list.Get());
    list->SetModel(&model);
    (void)root->UpdateLayout();

    list->SetSelectedItem(4);
    CHECK(list->GetSelectedItem() == 4);

    model.SetItems(MakeItems(2)); // notifies the view -> selection 4 is now out of range
    CHECK(list->GetSelectedItem() == -1);

    model.AddItem(SV(u8"more"));
    CHECK(list->GetModel()->RowCount() == 3);
}

// ===================== Multi-selection (ItemView) =====================

TEST_CASE("itemview: Ctrl-click toggles items in multi-selection mode")
{
    StringListModel model(MakeItems(10));
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 120.0f});
    list->SetRowHeight(20.0f);
    list->SetSelectionMode(SelectionMode::Multi);
    root->AddChild(list.Get());
    list->SetModel(&model);
    (void)root->UpdateLayout();
    EventDispatcher* d = root->GetEventDispatcher();
    const core::u32 ctrl = static_cast<core::u32>(KeyModCtrl);

    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left); // row 0 (plain)
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    d->InjectMouseDown(core::Float2{10.0f, 50.0f}, MouseButton::Left, ctrl); // row 2 (ctrl)
    d->InjectMouseUp(core::Float2{10.0f, 50.0f}, MouseButton::Left, ctrl);

    CHECK(list->GetSelectionCount() == 2);
    CHECK(list->IsItemSelected(0));
    CHECK(list->IsItemSelected(2));

    // Ctrl-click an already-selected item removes it.
    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left, ctrl);
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left, ctrl);
    CHECK_FALSE(list->IsItemSelected(0));
    CHECK(list->GetSelectionCount() == 1);
}

TEST_CASE("itemview: Shift-click selects a range from the anchor")
{
    StringListModel model(MakeItems(10));
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 120.0f});
    list->SetRowHeight(20.0f);
    list->SetSelectionMode(SelectionMode::Multi);
    root->AddChild(list.Get());
    list->SetModel(&model);
    (void)root->UpdateLayout();
    EventDispatcher* d = root->GetEventDispatcher();

    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left); // row 0 anchors
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    const core::u32 shift = static_cast<core::u32>(KeyModShift);
    d->InjectMouseDown(core::Float2{10.0f, 70.0f}, MouseButton::Left, shift); // row 3
    d->InjectMouseUp(core::Float2{10.0f, 70.0f}, MouseButton::Left, shift);

    CHECK(list->GetSelectionCount() == 4); // rows 0,1,2,3
    CHECK(list->IsItemSelected(1));
    CHECK(list->IsItemSelected(3));
}

TEST_CASE("itemview: single-selection mode ignores Ctrl (stays single)")
{
    StringListModel model(MakeItems(10));
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 120.0f});
    list->SetRowHeight(20.0f);
    root->AddChild(list.Get()); // default SelectionMode::Single
    list->SetModel(&model);
    (void)root->UpdateLayout();
    EventDispatcher* d = root->GetEventDispatcher();
    const core::u32 ctrl = static_cast<core::u32>(KeyModCtrl);

    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    d->InjectMouseDown(core::Float2{10.0f, 50.0f}, MouseButton::Left, ctrl); // ctrl ignored
    d->InjectMouseUp(core::Float2{10.0f, 50.0f}, MouseButton::Left, ctrl);
    CHECK(list->GetSelectionCount() == 1);
    CHECK(list->GetSelectedItem() == 2);
}
