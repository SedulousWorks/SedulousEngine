// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - MVC data-core tests: Variant (typed value + ToString + Compare), ModelIndex,
// and StringListModel (row/column/data + client notification on mutation).
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // Counts model-update notifications.
    struct CountingClient : public IModelClient
    {
        int updates = 0;
        void OnModelReset() override { ++updates; }
    };
}

TEST_CASE("variant: types, accessors, ToString")
{
    CHECK(Variant{}.IsEmpty());
    CHECK(Variant(true).GetType() == Variant::Type::Bool);
    CHECK(Variant(static_cast<core::i64>(42)).AsInt() == 42);
    CHECK(Variant(SV(u8"hi")).AsString() == SV(u8"hi"));

    CHECK(Variant(static_cast<core::i64>(-7)).ToString() == SV(u8"-7"));
    CHECK(Variant(static_cast<core::i64>(0)).ToString() == SV(u8"0"));
    CHECK(Variant(true).ToString() == SV(u8"true"));
    CHECK(Variant(SV(u8"text")).ToString() == SV(u8"text"));
    CHECK(Variant(1.5).ToString() == SV(u8"1.5"));
    CHECK(Variant(3.0).ToString() == SV(u8"3")); // trailing zeros trimmed
}

TEST_CASE("variant: Compare orders numbers and strings")
{
    CHECK(Variant(static_cast<core::i64>(1)).Compare(Variant(static_cast<core::i64>(2))) < 0);
    CHECK(Variant(static_cast<core::i64>(5)).Compare(Variant(static_cast<core::i64>(5))) == 0);
    CHECK(Variant(SV(u8"apple")).Compare(Variant(SV(u8"banana"))) < 0);
    CHECK(Variant(SV(u8"pear")).Compare(Variant(SV(u8"peach"))) > 0);
    // An int against a float by value, not by type (a mixed numeric column sorts as numbers).
    CHECK(Variant(static_cast<core::i64>(3)).Compare(Variant(2.5)) > 0);
    CHECK(Variant(1.5).Compare(Variant(static_cast<core::i64>(2))) < 0);
    CHECK(Variant(static_cast<core::i64>(2)).Compare(Variant(2.0)) == 0);
}

TEST_CASE("variant: a colour is written as its hex code, and differing colours never compare equal")
{
    CHECK(Variant(core::Color{1.0f, 0.5f, 0.0f, 1.0f}).ToString() == SV(u8"#FF8000FF"));
    CHECK(Variant(core::Color{0.1f, 0.2f, 0.3f, 1.0f}).Compare(Variant(core::Color{0.1f, 0.2f, 0.3f, 1.0f})) == 0);
    CHECK(Variant(core::Color{0.1f, 0.2f, 0.3f, 1.0f}).Compare(Variant(core::Color{0.1f, 0.25f, 0.3f, 1.0f})) < 0);
    CHECK(Variant(core::Color{0.1f, 0.2f, 0.3f, 1.0f}).Compare(Variant(core::Color{0.1f, 0.2f, 0.3f, 0.5f})) > 0);
}

TEST_CASE("variant: a curve's keys and a gradient are one value each, equal only when every field is")
{
    core::CurveKey keys[2]{};
    keys[0].time = 0.0f;
    keys[1].time = 1.0f;
    keys[1].value = 2.0f;
    const Variant curve = Variant::FromCurve(keys);
    CHECK(curve.GetType() == Variant::Type::Curve);
    REQUIRE(curve.AsCurve().Size() == 2);
    CHECK(curve.AsCurve()[1].value == 2.0f);
    CHECK(curve.ToString() == SV(u8"2 keys"));
    CHECK(curve.Compare(Variant::FromCurve(keys)) == 0);
    keys[1].tangentMode = core::CurveTangentMode::Flat;
    CHECK(curve.Compare(Variant::FromCurve(keys)) != 0);
    CHECK(curve.Compare(Variant::FromCurve(core::Span<const core::CurveKey>(keys, 1))) > 0); // more keys after
    CHECK(Variant(1.0).AsCurve().IsEmpty());

    ColorGradient gradient;
    gradient.Colors.PushBack(core::GradientColorStop{0.0f, core::Color{1.0f, 0.0f, 0.0f, 1.0f}});
    gradient.Alphas.PushBack(core::GradientAlphaStop{0.0f, 1.0f});
    gradient.Alphas.PushBack(core::GradientAlphaStop{1.0f, 0.0f});
    const Variant value(gradient);
    CHECK(value.GetType() == Variant::Type::Gradient);
    CHECK(value.ToString() == SV(u8"1 colours, 2 alphas"));
    CHECK(value.AsGradient() == gradient);
    CHECK(value.Compare(Variant(gradient)) == 0);
    ColorGradient other = gradient;
    other.Interpolation = core::GradientInterpolation::OkLab;
    CHECK(value.Compare(Variant(other)) != 0);
    other = gradient;
    other.Alphas[1].alpha = 0.5f;
    CHECK(value.Compare(Variant(other)) < 0);
    CHECK(gradient.Evaluate(0.5f).a == doctest::Approx(0.5f));
}

TEST_CASE("model-index: validity + equality")
{
    CHECK_FALSE(ModelIndex{}.IsValid()); // default row -1
    CHECK(MakeModelIndex(0, 0).IsValid());
    CHECK(MakeModelIndex(3, 1) == MakeModelIndex(3, 1));
    CHECK_FALSE(MakeModelIndex(3, 1) == MakeModelIndex(3, 2));
}

TEST_CASE("string-list-model: rows/columns/data")
{
    core::Array<core::String> items;
    items.PushBack(core::String(SV(u8"Alpha")));
    items.PushBack(core::String(SV(u8"Beta")));
    StringListModel model(core::Move(items));

    CHECK(model.RowCount() == 2);
    CHECK(model.ColumnCount() == 1);
    CHECK(model.Data(MakeModelIndex(0)).AsString() == SV(u8"Alpha"));
    CHECK(model.Data(MakeModelIndex(1), ModelRole::Sort).AsString() == SV(u8"Beta"));

    // Out-of-range -> empty variant.
    CHECK(model.Data(MakeModelIndex(5)).IsEmpty());
    CHECK_FALSE(model.IsValidIndex(MakeModelIndex(2)));
}

TEST_CASE("model: mutating notifies registered clients")
{
    StringListModel model;
    CountingClient client;
    model.AddClient(&client);

    model.AddItem(SV(u8"one"));
    CHECK(client.updates == 1);
    CHECK(model.RowCount() == 1);

    model.SetItems({});
    CHECK(client.updates == 2);
    CHECK(model.RowCount() == 0);

    model.RemoveClient(&client);
    model.AddItem(SV(u8"ignored")); // no longer notified
    CHECK(client.updates == 2);
}

namespace
{
    // Records each range a model reports, as text.
    struct RangeClient : public IModelClient
    {
        core::Array<core::String> seen;
        void OnModelReset() override { seen.PushBack(core::String(SV(u8"reset"))); }
        void OnRowsInserted(const ModelIndex& parent, core::i32 first, core::i32 count) override
        {
            seen.PushBack(core::Format(u8"insert {} {} {}", parent.InternalId, first, count));
        }
        void OnRowsRemoved(const ModelIndex& parent, core::i32 first, core::i32 count) override
        {
            seen.PushBack(core::Format(u8"remove {} {} {}", parent.InternalId, first, count));
        }
        void OnRowsMoved(const ModelIndex& parent, core::i32 first, core::i32 count, core::i32 to) override
        {
            seen.PushBack(core::Format(u8"move {} {} {} {}", parent.InternalId, first, count, to));
        }
        void OnRowsChanged(const ModelIndex& parent, core::i32 first, core::i32 count) override
        {
            seen.PushBack(core::Format(u8"change {} {} {}", parent.InternalId, first, count));
        }
    };
}

TEST_CASE("model: a list reports inserted, removed, moved and changed rows, and resets for the rest")
{
    StringListModel model;
    RangeClient client;
    model.AddClient(&client);
    model.AddItem(SV(u8"a"));
    model.AddItem(SV(u8"c"));
    model.InsertItem(1, SV(u8"b"));
    model.SetItem(2, SV(u8"C"));
    model.MoveItem(0, 2);
    model.RemoveItem(1);
    model.Clear();
    REQUIRE(client.seen.Size() == 7);
    CHECK(client.seen[0] == SV(u8"insert -1 0 1"));
    CHECK(client.seen[1] == SV(u8"insert -1 1 1"));
    CHECK(client.seen[2] == SV(u8"insert -1 1 1"));
    CHECK(client.seen[3] == SV(u8"change -1 2 1"));
    CHECK(client.seen[4] == SV(u8"move -1 0 1 2"));
    CHECK(client.seen[5] == SV(u8"remove -1 1 1"));
    CHECK(client.seen[6] == SV(u8"reset"));
}

TEST_CASE("model: a client that follows no ranges takes each as a reset")
{
    StringListModel model;
    CountingClient client;
    model.AddClient(&client);
    model.AddItem(SV(u8"a"));
    model.SetItem(0, SV(u8"b"));
    model.RemoveItem(0);
    CHECK(client.updates == 3);
}

TEST_CASE("model: a row keeps its id while rows are inserted, moved and removed around it")
{
    StringListModel model;
    model.AddItem(SV(u8"a"));
    model.AddItem(SV(u8"b"));
    const ItemId b = model.IdOf(MakeModelIndex(1));
    model.InsertItem(0, SV(u8"first"));
    CHECK(model.IdOf(MakeModelIndex(2)) == b);
    model.MoveItem(2, 0);
    CHECK(model.IdOf(MakeModelIndex(0)) == b);
    model.RemoveItem(1);
    CHECK(model.IndexOfId(b).Row == 0);
    CHECK(model.IdOf(MakeModelIndex(1)) != b);
    CHECK_FALSE(model.IndexOfId(12345).IsValid());
}

TEST_CASE("model: editing is a capability; a table cell keeps its kind")
{
    StringListModel list;
    list.AddItem(SV(u8"a"));
    CHECK_FALSE(list.IsEditable(MakeModelIndex(0)));
    CHECK_FALSE(list.SetData(MakeModelIndex(0), Variant(SV(u8"b"))));
    list.SetEditable(true);
    CHECK(list.SetData(MakeModelIndex(0), Variant(SV(u8"b"))));
    CHECK(list.ItemAt(0) == SV(u8"b"));

    TableModel table;
    core::Array<core::String> columns;
    columns.PushBack(core::String(SV(u8"Name")));
    columns.PushBack(core::String(SV(u8"Score")));
    table.SetColumns(core::Move(columns));
    core::Array<Variant> row;
    row.PushBack(Variant(SV(u8"Ada")));
    row.PushBack(Variant(static_cast<core::i64>(3)));
    table.AddRow(core::Move(row));
    table.SetEditable(true);
    CHECK(table.SetData(MakeModelIndex(0, 1), Variant(SV(u8"42"))));
    CHECK(table.Cell(0, 1).GetType() == Variant::Type::Int);
    CHECK(table.Cell(0, 1).AsInt() == 42);
    CHECK_FALSE(table.SetData(MakeModelIndex(0, 1), Variant(SV(u8"many")))); // not a number: refused
    CHECK(table.Cell(0, 1).AsInt() == 42);
    CHECK_FALSE(table.Sort(1, SortOrder::Ascending)); // a table alone cannot sort; a proxy can
}

TEST_CASE("model: a tree reports rows under their parent, and a removed node's id is not reused")
{
    TreeModel tree;
    RangeClient client;
    tree.AddClient(&client);
    const core::i32 a = tree.AddNode(TreeModel::kRoot, SV(u8"A"));
    const core::i32 a1 = tree.AddNode(a, SV(u8"A1"));
    const core::i32 a2 = tree.AddNode(a, SV(u8"A2"));
    tree.SetText(a2, SV(u8"A two"));
    tree.RemoveNode(a1);
    REQUIRE(client.seen.Size() == 5);
    CHECK(client.seen[0] == SV(u8"insert -1 0 1"));
    CHECK(client.seen[1] == core::Format(u8"insert {} 0 1", a));
    CHECK(client.seen[2] == core::Format(u8"insert {} 1 1", a));
    CHECK(client.seen[3] == core::Format(u8"change {} 1 1", a));
    CHECK(client.seen[4] == core::Format(u8"remove {} 0 1", a));
    CHECK(tree.RowCount(tree.IndexOfNode(a)) == 1);
    CHECK(tree.IdOf(tree.Index(0, 0, tree.IndexOfNode(a))) == static_cast<ItemId>(a2));
    const core::i32 b = tree.AddNode(TreeModel::kRoot, SV(u8"B"));
    CHECK(b != a1);
    CHECK_FALSE(tree.IndexOfNode(a1).IsValid());
}

TEST_CASE("row-ids: an id's row is found after rows are inserted, moved and removed")
{
    RowIds ids;
    ids.Reset(5); // ids 0..4 in rows 0..4
    CHECK(ids.RowOf(3) == 3);
    ids.Insert(0); // id 5 at the top
    CHECK(ids.RowOf(5) == 0);
    CHECK(ids.RowOf(3) == 4);
    ids.Move(4, 1); // id 3 to row 1
    CHECK(ids.RowOf(3) == 1);
    CHECK(ids.RowOf(1) == 3);
    ids.Remove(1);
    CHECK(ids.RowOf(3) == -1);
    CHECK(ids.RowOf(4) == 4);
    ids.InsertId(2, 3); // back, keeping its id
    CHECK(ids.RowOf(3) == 2);
    CHECK(ids.RowOf(99) == -1);
}
