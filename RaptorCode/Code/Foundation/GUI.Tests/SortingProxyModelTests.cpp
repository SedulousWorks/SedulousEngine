// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - SortingProxyModel tests: reorder a source model's rows by a column (numeric by
// value, strings lexically), toggle asc/desc, map proxy rows to source, and re-sort + notify on
// source changes. Also the TableView header-click -> ToggleSort wiring.
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

    struct CountingClient : public IModelClient
    {
        int updates = 0;
        void OnModelReset() override { ++updates; }
    };

    // Rows: (name, value) = (b,2) (a,10) (c,1).
    void FillBAC(TableModel& model)
    {
        core::Array<core::String> cols;
        cols.PushBack(core::String(SV(u8"Name")));
        cols.PushBack(core::String(SV(u8"Value")));
        model.SetColumns(core::Move(cols));
        const char8_t* names[3] = {u8"b", u8"a", u8"c"};
        const core::i64 values[3] = {2, 10, 1};
        for (int i = 0; i < 3; ++i)
        {
            core::Array<Variant> row;
            row.PushBack(Variant(core::StringView(names[i])));
            row.PushBack(Variant(values[i]));
            model.AddRow(core::Move(row));
        }
    }
}

TEST_CASE("sorting-proxy: numeric column sorts by value, ascending and descending")
{
    TableModel source;
    FillBAC(source);
    SortingProxyModel proxy(&source);

    (void)proxy.Sort(1, SortOrder::Ascending); // values 2,10,1 -> 1,2,10
    CHECK(proxy.RowCount() == 3);
    CHECK(proxy.Data(MakeModelIndex(0, 1)).AsInt() == 1);
    CHECK(proxy.Data(MakeModelIndex(1, 1)).AsInt() == 2);
    CHECK(proxy.Data(MakeModelIndex(2, 1)).AsInt() == 10);
    CHECK(proxy.Data(MakeModelIndex(0, 0)).AsString() == SV(u8"c")); // row with value 1
    CHECK(proxy.SourceRow(0) == 2);

    (void)proxy.Sort(1, SortOrder::Descending); // 10,2,1
    CHECK(proxy.Data(MakeModelIndex(0, 1)).AsInt() == 10);
    CHECK(proxy.Data(MakeModelIndex(2, 1)).AsInt() == 1);
}

TEST_CASE("sorting-proxy: string column sorts lexically")
{
    TableModel source;
    FillBAC(source);
    SortingProxyModel proxy(&source);

    (void)proxy.Sort(0, SortOrder::Ascending); // b,a,c -> a,b,c
    CHECK(proxy.Data(MakeModelIndex(0, 0)).AsString() == SV(u8"a"));
    CHECK(proxy.Data(MakeModelIndex(1, 0)).AsString() == SV(u8"b"));
    CHECK(proxy.Data(MakeModelIndex(2, 0)).AsString() == SV(u8"c"));
}

TEST_CASE("sorting-proxy: ToggleSort cycles order and switches columns")
{
    TableModel source;
    FillBAC(source);
    SortingProxyModel proxy(&source);

    proxy.ToggleSort(1);
    CHECK(proxy.GetSortColumn() == 1);
    CHECK(proxy.GetSortOrder() == SortOrder::Ascending);
    proxy.ToggleSort(1); // same column -> descending
    CHECK(proxy.GetSortOrder() == SortOrder::Descending);
    proxy.ToggleSort(0); // new column -> ascending
    CHECK(proxy.GetSortColumn() == 0);
    CHECK(proxy.GetSortOrder() == SortOrder::Ascending);
}

TEST_CASE("sorting-proxy: a source change re-sorts and notifies the proxy's clients")
{
    TableModel source;
    FillBAC(source);
    SortingProxyModel proxy(&source);
    (void)proxy.Sort(1, SortOrder::Ascending);

    CountingClient client;
    proxy.AddClient(&client);

    core::Array<Variant> row; // value 0 -> should sort to the front
    row.PushBack(Variant(SV(u8"z")));
    row.PushBack(Variant(static_cast<core::i64>(0)));
    source.AddRow(core::Move(row));

    CHECK(client.updates == 1); // source change propagated
    CHECK(proxy.RowCount() == 4);
    CHECK(proxy.Data(MakeModelIndex(0, 1)).AsInt() == 0); // re-sorted with the new row first
}

TEST_CASE("sorting-proxy: TableView header click wired to ToggleSort re-sorts the view")
{
    TableModel source;
    FillBAC(source);
    SortingProxyModel proxy(&source);

    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto table = Make<TableView>();
    table->SetSize(core::Float2{300.0f, 200.0f});
    table->SetHeaderHeight(26.0f);
    root->AddChild(table.Get());
    table->SetModel(&proxy);
    (void)root->UpdateLayout();
    table->SetOnColumnHeaderClicked([&](core::usize col) { proxy.ToggleSort(col); });
    EventDispatcher* d = root->GetEventDispatcher();

    // Click the "Value" header (column 1, x in [150, 300)).
    d->InjectMouseDown(core::Float2{200.0f, 13.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{200.0f, 13.0f}, MouseButton::Left);
    CHECK(proxy.GetSortColumn() == 1);
    CHECK(proxy.GetSortOrder() == SortOrder::Ascending);
    CHECK(proxy.Data(MakeModelIndex(0, 1)).AsInt() == 1); // ascending: smallest first
}

TEST_CASE("sorting-proxy: a row keeps its source row's id when sorted, so a selection follows it")
{
    TableModel source;
    FillBAC(source);
    SortingProxyModel proxy(&source);
    const ItemId first = proxy.IdOf(MakeModelIndex(0));
    const Variant name = proxy.Data(MakeModelIndex(0, 0));
    CHECK(proxy.Sort(1, SortOrder::Descending));
    const ModelIndex moved = proxy.IndexOfId(first);
    REQUIRE(moved.IsValid());
    CHECK(proxy.Data(MakeModelIndex(moved.Row, 0)).Compare(name) == 0);
}
