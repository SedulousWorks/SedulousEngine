// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - ItemView (E6): the engine behind the list, tree and table views. Row heights in a sum
// tree, measured on demand; scrolling anchored to an item; rows from a native factory, pooled by
// type and recycled; selection as a set of ids that survives inserts and sorting; `activate`,
// type-ahead and editing in place; and the view as a Node scroll container.
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

    core::Array<core::String> Numbered(int count)
    {
        core::Array<core::String> items;
        for (int i = 0; i < count; ++i)
            items.PushBack(core::Format(u8"item {}", i));
        return items;
    }

    struct Mounted
    {
        core::RefPtr<SceneRoot> root;
        core::RefPtr<ListView> list;
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        void Layout() { (void)root->UpdateLayout(); }
    };

    Mounted MountList(IModel& model, float rowHeight = 20.0f, float height = 100.0f)
    {
        Mounted m;
        m.root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        m.root->SetSize(core::Float2{300.0f, 300.0f});
        m.list = Make<ListView>();
        m.list->SetSize(core::Float2{200.0f, height});
        m.list->SetRowHeight(rowHeight);
        m.root->AddChild(m.list.Get());
        m.list->SetModel(&model);
        m.Layout();
        return m;
    }

    // A factory whose rows are as tall as the number in their text says (`item 3` is 30 high).
    RowFactory TallRows(int* created)
    {
        RowFactory f;
        f.Create = [created](core::u32)
        {
            ++*created;
            auto panel = Make<Panel>();
            return core::RefPtr<Node>(panel);
        };
        f.Bind = [](Node& content, const ModelIndex& index)
        {
            const float h = 10.0f * static_cast<float>(index.Row % 4 + 1);
            content.EditLayoutStyle([h](LayoutStyle& s) { s.Height = LayoutLength::Px(h); });
        };
        return f;
    }
}

TEST_CASE("itemview: row heights in a sum tree find a row by offset and an offset by row")
{
    RowHeights h;
    h.Reset(5, 10.0f);
    CHECK(h.Total() == doctest::Approx(50.0f));
    CHECK(h.Top(3) == doctest::Approx(30.0f));
    CHECK(h.Find(0.0f) == 0);
    CHECK(h.Find(29.9f) == 2);
    CHECK(h.Find(30.0f) == 3);
    CHECK(h.Find(500.0f) == 4); // past the end: the last
    CHECK(h.Set(1, 25.0f));
    CHECK(h.IsMeasured(1));
    CHECK(h.Top(2) == doctest::Approx(35.0f));
    CHECK(h.Find(34.0f) == 1);
    h.Insert(0, 2, 5.0f);
    CHECK(h.Size() == 7);
    CHECK(h.Top(3) == doctest::Approx(20.0f)); // 5, 5, 10, then the 25
    CHECK(h.Top(4) == doctest::Approx(45.0f));
    h.Remove(0, 2);
    CHECK(h.Top(2) == doctest::Approx(35.0f));
    h.Move(1, 1, 4); // the 25 row goes last
    CHECK(h.At(4) == doctest::Approx(25.0f));
    CHECK(h.Total() == doctest::Approx(65.0f));
}

TEST_CASE("itemview: measured rows take their own heights once realised, estimated until then")
{
    StringListModel model(Numbered(100));
    Mounted m = MountList(model, 20.0f);
    int created = 0;
    m.list->SetRowFactory(TallRows(&created));
    m.list->SetRowHeight(0.0f); // measured
    m.list->SetEstimatedRowHeight(25.0f);
    m.Layout();
    // Rows 0..: 10, 20, 30, 40, 10, ... The first rows are measured; the rest still estimated.
    const Rect r2 = m.list->ItemBounds(2);
    CHECK(r2.y == doctest::Approx(30.0f));
    CHECK(r2.height == doctest::Approx(30.0f));
    CHECK(m.list->ItemBounds(99).height == doctest::Approx(25.0f));
    CHECK(m.list->GetContentExtent().y > 100.0f * 10.0f);
    // A row's content fills it.
    ItemRow* row = m.list->RowForItem(3);
    REQUIRE(row != nullptr);
    CHECK(row->GetSize().y == doctest::Approx(40.0f));
}

TEST_CASE("itemview: rows come from a factory, one pool per type, recycled as they scroll")
{
    StringListModel model(Numbered(200));
    Mounted m = MountList(model);
    int created = 0;
    core::u32 boundTypes[2] = {0, 0};
    RowFactory f;
    f.TypeOf = [](const ModelIndex& index) { return static_cast<core::u32>(index.Row % 2); };
    f.Create = [&](core::u32 type)
    {
        ++created;
        auto label = Make<Label>();
        label->AddClass(type == 0 ? SV(u8"even") : SV(u8"odd"));
        return core::RefPtr<Node>(label);
    };
    f.Bind = [&](Node& content, const ModelIndex& index)
    {
        auto& label = static_cast<Label&>(content);
        CHECK(label.HasClass(index.Row % 2 == 0 ? SV(u8"even") : SV(u8"odd"))); // a row of its type
        ++boundTypes[index.Row % 2];
        label.SetText(model.ItemAt(static_cast<core::usize>(index.Row)));
    };
    m.list->SetRowFactory(core::Move(f));
    m.Layout();
    const int firstMade = created;
    CHECK(firstMade == 6);

    // Scrolling a long way makes no more rows: the ones that leave are taken again.
    for (int i = 0; i < 20; ++i)
    {
        m.D().InjectMouseWheel(core::Float2{50.0f, 50.0f}, core::Float2{0.0f, -3.0f});
        m.Layout();
    }
    CHECK(m.list->GetScrollOffset().y == doctest::Approx(1200.0f));
    CHECK(created <= firstMade + 2);
    CHECK(m.list->VisibleRowCount() <= 7);
    ItemRow* row = m.list->RowForItem(61);
    REQUIRE(row != nullptr);
    CHECK(static_cast<Label*>(row->GetContent())->GetText() == SV(u8"item 61"));
    CHECK(boundTypes[0] > 6);
    CHECK(boundTypes[1] > 6);
}

TEST_CASE("itemview: rows inserted above leave what is in view where it is")
{
    StringListModel model(Numbered(100));
    Mounted m = MountList(model);
    m.list->ScrollToItem(50, ScrollAlign::Start);
    m.Layout();
    CHECK(m.list->GetScrollOffset().y == doctest::Approx(1000.0f));
    for (int i = 0; i < 3; ++i)
        model.InsertItem(0, SV(u8"new"));
    m.Layout();
    // Item 50 is now item 53, still at the top of the view.
    CHECK(m.list->GetScrollOffset().y == doctest::Approx(53.0f * 20.0f));
    ItemRow* top = m.list->RowForItem(53);
    REQUIRE(top != nullptr);
    CHECK(static_cast<Label*>(top->GetContent())->GetText() == SV(u8"item 50"));
}

TEST_CASE("itemview: a row above measuring taller than its estimate leaves the view where it is")
{
    StringListModel model(Numbered(100));
    Mounted m = MountList(model);
    int created = 0;
    m.list->SetRowFactory(TallRows(&created));
    m.list->SetRowHeight(0.0f);
    m.list->SetEstimatedRowHeight(10.0f);
    m.Layout();
    // Jump to item 40: realised with the row above it (39), whose measuring is put back at once.
    m.list->ScrollToItem(40, ScrollAlign::Start);
    m.Layout();
    const float before = m.list->ItemBounds(40).y;
    CHECK(m.list->GetScrollOffset().y == doctest::Approx(before));
    // Five pixels up realises row 38 (30 high, estimated 10): everything below it moves down 20,
    // and the offset with it, so the view shows what it did, five pixels higher.
    m.list->ScrollBy(core::Float2{0.0f, -5.0f});
    m.Layout();
    CHECK(m.list->ItemBounds(40).y - before == doctest::Approx(20.0f));
    CHECK(m.list->ItemBounds(40).y - m.list->GetScrollOffset().y == doctest::Approx(5.0f));
}

TEST_CASE("itemview: the selection is a set of ids: it follows rows inserted above, and leaves with a removed row")
{
    StringListModel model(Numbered(10));
    Mounted m = MountList(model);
    m.list->SetSelectedItem(4);
    model.InsertItem(0, SV(u8"new"));
    CHECK(m.list->GetSelectedItem() == 5);
    CHECK(m.list->GetSelectedIndex().Row == 5);
    model.MoveItem(5, 0);
    CHECK(m.list->GetSelectedItem() == 0);
    model.RemoveItem(0);
    CHECK(m.list->GetSelectedItem() == -1);
    CHECK(m.list->GetSelectionCount() == 0);
}

TEST_CASE("itemview: a table's selection follows its row when a header click sorts it")
{
    TableModel model;
    core::Array<core::String> columns;
    columns.PushBack(core::String(SV(u8"Name")));
    columns.PushBack(core::String(SV(u8"Score")));
    model.SetColumns(core::Move(columns));
    const char8_t* names[3] = {u8"b", u8"a", u8"c"};
    const core::i64 scores[3] = {2, 10, 1};
    for (int i = 0; i < 3; ++i)
    {
        core::Array<Variant> row;
        row.PushBack(Variant(SV(names[i])));
        row.PushBack(Variant(scores[i]));
        model.AddRow(core::Move(row));
    }
    SortingProxyModel proxy(&model);
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto table = Make<TableView>();
    table->SetSize(core::Float2{300.0f, 200.0f});
    table->SetRowHeight(24.0f);
    root->AddChild(table.Get());
    table->SetModel(&proxy);
    (void)root->UpdateLayout();
    table->SetSelectedItem(0); // "b"

    // Nothing listening to the header: a click sorts through the model's capability.
    root->GetEventDispatcher()->InjectMouseDown(core::Float2{200.0f, 13.0f}, MouseButton::Left);
    root->GetEventDispatcher()->InjectMouseUp(core::Float2{200.0f, 13.0f}, MouseButton::Left);
    CHECK(proxy.GetSortColumn() == 1);
    CHECK(proxy.Data(MakeModelIndex(0, 0)).AsString() == SV(u8"c")); // 1, 2, 10
    CHECK(table->GetSelectedItem() == 1);                             // "b" is second now
    CHECK(proxy.Data(MakeModelIndex(table->GetSelectedItem(), 0)).AsString() == SV(u8"b"));
}

TEST_CASE("itemview: a selected row shows :selected; a context menu asked for over a row selects it")
{
    RegisterGuiElements();
    StringListModel model(Numbered(10));
    Mounted m = MountList(model);
    m.list->SetSelectedItem(1);
    m.Layout();
    ItemRow* row = m.list->RowForItem(1);
    REQUIRE(row != nullptr);
    CHECK((row->GetWidgetStates() & WidgetStateSelected) != 0);
    CHECK(row->IsSelected());
    CHECK_FALSE(m.list->RowForItem(2)->IsSelected());

    bool asked = false;
    (void)m.list->AddEventListener(EventType::ContextMenu, [&](const Event&) { asked = true; });
    m.D().InjectMouseDown(core::Float2{50.0f, 70.0f}, MouseButton::Right); // row 3
    m.D().InjectMouseUp(core::Float2{50.0f, 70.0f}, MouseButton::Right);
    CHECK(asked);
    CHECK(m.list->GetSelectedItem() == 3);
}

TEST_CASE("itemview: a double-click, Return and the pad's South report activate")
{
    StringListModel model(Numbered(10));
    Mounted m = MountList(model);
    int activations = 0;
    core::i32 lastItem = -1;
    ModelIndex lastIndex;
    (void)m.list->AddEventListener(EventType::ItemActivate, [&](const Event& e)
    {
        ++activations;
        lastItem = static_cast<const ItemEvent&>(e).Item;
    });
    m.list->SetOnActivated([&](ModelIndex index) { lastIndex = index; });

    m.D().InjectMouseDown(core::Float2{50.0f, 30.0f}, MouseButton::Left);
    m.D().InjectMouseUp(core::Float2{50.0f, 30.0f}, MouseButton::Left);
    CHECK(activations == 0);
    m.D().InjectMouseDown(core::Float2{50.0f, 30.0f}, MouseButton::Left); // the second press
    m.D().InjectMouseUp(core::Float2{50.0f, 30.0f}, MouseButton::Left);
    CHECK(activations == 1);
    CHECK(lastItem == 1);
    CHECK(lastIndex.Row == 1);

    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Down));
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK(activations == 2);
    CHECK(lastItem == 2);
}

TEST_CASE("itemview: typing letters jumps to the next row starting with them")
{
    StringListModel model;
    const char8_t* names[6] = {u8"Apple", u8"Banana", u8"blueberry", u8"Cherry", u8"Bilberry", u8"Date"};
    for (const char8_t* n : names)
        model.AddItem(SV(n));
    Mounted m = MountList(model, 20.0f, 200.0f);
    m.list->RequestFocus();
    int changes = 0;
    (void)m.list->AddEventListener(EventType::Changed, [&](const Event&) { ++changes; });
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::B));
    m.D().InjectText(SV(u8"b")); // the text it types: what type-ahead reads (E12)
    CHECK(m.list->GetSelectedItem() == 1);
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::L));
    m.D().InjectText(SV(u8"l")); // "bl"
    CHECK(m.list->GetSelectedItem() == 2);
    CHECK(changes == 2);
    // After a pause, "b" again cycles through the b's.
    m.root->GetContext().Update(core::Duration::FromSeconds(1.5));
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::B));
    m.D().InjectText(SV(u8"b"));
    CHECK(m.list->GetSelectedItem() == 4);
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::B));
    m.D().InjectText(SV(u8"b")); // "bb": one letter again, the next b
    CHECK(m.list->GetSelectedItem() == 1);
}

TEST_CASE("itemview: F2 edits a row in place; the hooks may refuse; Escape cancels; Return commits")
{
    StringListModel model(Numbered(5));
    Mounted m = MountList(model);
    m.list->RequestFocus();
    m.list->SetSelectedItem(1);

    // Not editable: F2 does nothing.
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::F2));
    CHECK_FALSE(m.list->IsEditing());

    model.SetEditable(true);
    bool allowBegin = false;
    m.list->SetOnEditBegin([&](const ModelIndex&) { return allowBegin; });
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::F2));
    CHECK_FALSE(m.list->IsEditing());
    allowBegin = true;
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::F2));
    REQUIRE(m.list->IsEditing());
    TextField* editor = m.list->GetEditor();
    CHECK(editor->IsFocused());
    CHECK(editor->GetText() == SV(u8"item 1"));
    CHECK(editor->GetParent() == m.list->RowForItem(1));

    // Escape cancels: the model keeps its text, the view the focus.
    int cancels = 0;
    m.list->SetOnEditCancel([&](const ModelIndex&) { ++cancels; });
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(m.list->IsEditing());
    CHECK(cancels == 1);
    CHECK(model.ItemAt(1) == SV(u8"item 1"));
    CHECK(m.list->IsFocused());

    // The commit hook refuses an empty name: it stays editing, marked invalid.
    m.list->SetOnEditCommit([](const ModelIndex&, core::StringView text) { return text.Size() != 0; });
    REQUIRE(m.list->BeginEdit(1));
    editor->SetText(SV(u8""));
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK(m.list->IsEditing());
    CHECK(editor->HasClass(SV(u8"invalid")));
    editor->SetText(SV(u8"renamed"));
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK_FALSE(m.list->IsEditing());
    CHECK(model.ItemAt(1) == SV(u8"renamed"));
    m.Layout();
    CHECK(static_cast<Label*>(m.list->RowForItem(1)->GetContent())->GetText() == SV(u8"renamed"));
}

TEST_CASE("itemview: the view is a Node scroll container, scrolled from code like any other")
{
    StringListModel model(Numbered(50));
    Mounted m = MountList(model);
    CHECK(m.list->IsScrollContainer());
    CHECK(m.list->GetScrollRange().y == doctest::Approx(50.0f * 20.0f - 100.0f));
    // Scrolled from code like any scroller: the rows follow.
    m.list->ScrollTo(core::Float2{0.0f, 400.0f}, ScrollBehavior::Instant);
    CHECK(m.list->RowForItem(20) != nullptr);
    CHECK(m.list->RowForItem(0) == nullptr);
    CHECK(m.list->ItemAt(core::Float2{50.0f, 5.0f}) == 20);
}

TEST_CASE("itemview: markup's <template> is made into each row, its {{item}} and {{index}} filled")
{
    RegisterGuiElements();
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    MarkupLoader loader(*root->GetElementSet(), core::DefaultAllocator());
    auto tree = loader.LoadFromString(SV(u8R"(<ListView width="200" height="100" row-height="20" items="Ada|Bo|Cara" selection-mode="multi">
        <template><Panel flex-direction="row"><Label class="name" text="{{item}}"/><Label class="nth" text="#{{index}}"/></Panel></template>
    </ListView>)"));
    REQUIRE(tree.Get() != nullptr);
    auto* list = core::Cast<ListView>(tree.Get());
    REQUIRE(list != nullptr);
    root->AddChild(list);
    (void)root->UpdateLayout();
    CHECK(list->GetModel()->RowCount() == 3);
    CHECK(list->GetSelectionMode() == SelectionMode::Multi);
    CHECK(list->GetItemsText() == SV(u8"Ada|Bo|Cara"));
    ItemRow* row = list->RowForItem(1);
    REQUIRE(row != nullptr);
    auto* content = core::Cast<TemplateRowContent>(row->GetContent());
    REQUIRE(content != nullptr);
    REQUIRE(content->ChildCount() == 1);
    Node* panel = content->GetChildAt(0);
    REQUIRE(panel->ChildCount() == 2);
    CHECK(core::Cast<Label>(panel->GetChildAt(0))->GetText() == SV(u8"Bo"));
    CHECK(core::Cast<Label>(panel->GetChildAt(1))->GetText() == SV(u8"#1"));
    CHECK(core::Cast<Label>(panel->GetChildAt(0))->HasClass(SV(u8"name")));

    // A changed row is filled again; selecting is bindable.
    list->SetItemsText(core::String(SV(u8"Ada|Bea|Cara")));
    (void)root->UpdateLayout();
    row = list->RowForItem(1);
    CHECK(core::Cast<Label>(row->GetContent()->GetChildAt(0)->GetChildAt(0))->GetText() == SV(u8"Bea"));
}

TEST_CASE("itemview: templates of a type are picked by the row-type-column's text, each type its own pool")
{
    RegisterGuiElements();
    TableModel model;
    core::Array<core::String> columns;
    columns.PushBack(core::String(SV(u8"Kind")));
    columns.PushBack(core::String(SV(u8"Title")));
    model.SetColumns(core::Move(columns));
    const char8_t* kinds[4] = {u8"header", u8"entry", u8"entry", u8"header"};
    const char8_t* titles[4] = {u8"Fruit", u8"Apple", u8"Pear", u8"Nuts"};
    for (int i = 0; i < 4; ++i)
    {
        core::Array<Variant> row;
        row.PushBack(Variant(SV(kinds[i])));
        row.PushBack(Variant(SV(titles[i])));
        model.AddRow(core::Move(row));
    }
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    MarkupLoader loader(*root->GetElementSet(), core::DefaultAllocator());
    auto tree = loader.LoadFromString(SV(u8R"(<ListView width="200" height="200" row-height="0" row-type-column="Kind">
        <template><Label class="entry" text="{{item.Title}}" height="20"/></template>
        <template type="header"><Label class="header" text="== {{item.Title}} ==" height="30"/></template>
    </ListView>)"));
    auto* list = core::Cast<ListView>(tree.Get());
    REQUIRE(list != nullptr);
    root->AddChild(list);
    list->SetModel(&model);
    (void)root->UpdateLayout();
    (void)root->UpdateLayout();
    const auto label = [&](core::i32 item) { return core::Cast<Label>(list->RowForItem(item)->GetContent()->GetChildAt(0)); };
    CHECK(label(0)->HasClass(SV(u8"header")));
    CHECK(label(0)->GetText() == SV(u8"== Fruit =="));
    CHECK(label(1)->HasClass(SV(u8"entry")));
    CHECK(label(1)->GetText() == SV(u8"Apple"));
    CHECK(label(3)->HasClass(SV(u8"header")));
    CHECK(list->RowForItem(0)->GetRowType() != list->RowForItem(1)->GetRowType());
}

TEST_CASE("itemview: a grid lays cells across then down, stretched to fill; the arrows move across and down")
{
    StringListModel model(Numbered(50));
    Mounted m = MountList(model, 20.0f, 100.0f);
    m.list->SetLayoutMode(ItemLayout::Grid);
    m.list->SetCellWidth(60.0f);
    m.list->SetCellHeight(40.0f);
    m.Layout();
    // 200 wide: 3 cells of 66.7 across; 17 lines of 40.
    CHECK(m.list->GetColumnsAcross() == 3);
    CHECK(m.list->GetScrollRange().y == doctest::Approx(17.0f * 40.0f - 100.0f));
    ItemRow* cell = m.list->RowForItem(4);
    REQUIRE(cell != nullptr);
    CHECK(cell->GetPosition().x == doctest::Approx(200.0f / 3.0f).epsilon(0.02));
    CHECK(cell->GetPosition().y == doctest::Approx(40.0f));
    CHECK(cell->GetSize().x == doctest::Approx(200.0f / 3.0f).epsilon(0.02));
    // Lines 0 to 2 in view and one past: 12 cells, not 50.
    CHECK(m.list->VisibleRowCount() == 12);
    CHECK(m.list->ItemAt(core::Float2{150.0f, 50.0f}) == 5);

    m.list->RequestFocus();
    m.list->SetSelectedItem(4);
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    CHECK(m.list->GetSelectedItem() == 5);
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Down));
    CHECK(m.list->GetSelectedItem() == 8);
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Up));
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Up));
    CHECK(m.list->GetSelectedItem() == 2);
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::End));
    m.Layout();
    CHECK(m.list->GetSelectedItem() == 49);
    CHECK(m.list->GetScrollOffset().y == doctest::Approx(m.list->GetScrollRange().y));
    CHECK(m.list->RowForItem(49) != nullptr);

    // Narrower: fewer across, more lines.
    m.list->SetSize(core::Float2{130.0f, 100.0f});
    m.Layout();
    CHECK(m.list->GetColumnsAcross() == 2);
    CHECK(m.list->GetLayoutModeName() == SV(u8"grid"));
}

TEST_CASE("itemview: in right to left a grid lays its cells from the right")
{
    StringListModel model(Numbered(50));
    Mounted m = MountList(model, 20.0f, 100.0f);
    m.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    m.list->SetLayoutMode(ItemLayout::Grid);
    m.list->SetCellWidth(60.0f);
    m.list->SetCellHeight(40.0f);
    m.Layout();
    REQUIRE(m.list->GetColumnsAcross() == 3);
    ItemRow* first = m.list->RowForItem(0);
    ItemRow* second = m.list->RowForItem(1);
    REQUIRE(first != nullptr);
    REQUIRE(second != nullptr);
    const Rect box = m.list->GetContentBounds();
    CHECK(first->GetPosition().x + first->GetSize().x == doctest::Approx(box.x + box.width).epsilon(0.01));
    CHECK(second->GetPosition().x < first->GetPosition().x);
    CHECK(m.list->ItemBounds(1).x == doctest::Approx(second->GetPosition().x).epsilon(0.01));
}

TEST_CASE("itemview: in right to left a grid's Left goes on to the next cell and Right back")
{
    StringListModel model(Numbered(50));
    Mounted m = MountList(model, 20.0f, 100.0f);
    m.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    m.list->SetLayoutMode(ItemLayout::Grid);
    m.list->SetCellWidth(60.0f);
    m.list->SetCellHeight(40.0f);
    m.Layout();
    m.list->RequestFocus();
    m.list->SetSelectedItem(4);
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Left));
    CHECK(m.list->GetSelectedItem() == 5);
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    m.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    CHECK(m.list->GetSelectedItem() == 3);
}

TEST_CASE("itemview: a template's root fills its row or a grid's cell, inside its margin")
{
    RegisterGuiElements();
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    MarkupLoader loader(*root->GetElementSet(), core::DefaultAllocator());
    auto tree = loader.LoadFromString(SV(u8R"(<ListView width="200" height="100" layout="grid" cell-width="100" cell-height="50" items="a|b|c">
        <template><Panel margin="4"><Label text="{{item}}"/></Panel></template>
    </ListView>)"));
    auto* list = core::Cast<ListView>(tree.Get());
    REQUIRE(list != nullptr);
    root->AddChild(list);
    (void)root->UpdateLayout();
    Node* tile = list->RowForItem(1)->GetContent()->GetChildAt(0);
    CHECK(tile->GetSize().x == doctest::Approx(92.0f));
    CHECK(tile->GetSize().y == doctest::Approx(42.0f));
    CHECK(tile->GetPosition().x == doctest::Approx(4.0f));
}

TEST_CASE("itemview: rows made before they are styled keep their estimate, and the view still starts at the first")
{
    // As a page shown after the GUI started: its list makes its rows before a sheet has styled
    // them, so they measure nothing; that must not stand as their height.
    RegisterGuiElements();
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 600.0f});
    MarkupLoader loader(*root->GetElementSet(), core::DefaultAllocator());
    auto tree = loader.LoadFromString(SV(u8R"(<ListView width="420" height="200" row-height="0" estimated-row-height="40" items="a|b|c|d|e|f">
        <template><Panel class="tall-row"/></template>
    </ListView>)"));
    auto* list = core::Cast<ListView>(tree.Get());
    REQUIRE(list != nullptr);
    root->AddChild(list);
    (void)root->UpdateLayout(); // the rows made, unstyled
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(SV(u8".tall-row { height: 30px; }")));
    for (int frame = 0; frame < 3; ++frame)
    {
        styles.ApplyTree(*root.Get());
        (void)root->UpdateLayout();
    }
    ItemRow* first = list->RowForItem(0);
    REQUIRE(first != nullptr);
    CHECK(first->GetPosition().y == doctest::Approx(0.0f));
    CHECK(first->GetSize().y == doctest::Approx(30.0f));
    ItemRow* fourth = list->RowForItem(3);
    REQUIRE(fourth != nullptr);
    CHECK(fourth->GetPosition().y == doctest::Approx(90.0f));
}
