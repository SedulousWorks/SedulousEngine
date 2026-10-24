// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - an item view's items in the accessibility tree (E17b of Specs/gui-lab-evolution-2.md): each
// item that has a node (the rows made and a page each side, the current and the selected) is a node
// of its own, in item order, under an id that follows the item, saying where it stands among them
// all; the focus is the current item; a screen reader's actions on an item run through its view.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::i32;
using core::u64;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    core::Duration Frame() { return core::Duration::FromSeconds(1.0 / 60.0); }

    struct Recorder : IAccessibilityBridge
    {
        core::Array<AccessTreeUpdate> Updates;
        bool IsListening() const override { return true; }
        void Update(const AccessTreeUpdate& update) override { Updates.PushBack(update); }
        void Announce(core::StringView, AnnouncePriority) override {}
        // The node as the bridge last heard it.
        const AccessNode* Last(u64 id) const
        {
            for (usize u = Updates.Size(); u-- > 0;)
                if (const AccessNode* n = Updates[u].Find(id))
                    return n;
            return nullptr;
        }
    };

    core::Array<core::String> Numbered(int count)
    {
        core::Array<core::String> items;
        for (int i = 0; i < count; ++i)
            items.PushBack(core::Format(u8"item {}", i));
        return items;
    }

    struct ListBed
    {
        StringListModel model; // first: it outlives the view that registers with it
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<ListView> list = core::MakeRef<ListView>(core::DefaultAllocator());
        explicit ListBed(int count) : model(Numbered(count))
        {
            root->SetSize(core::Float2{400.0f, 400.0f});
            list->SetSize(core::Float2{200.0f, 200.0f}); // ten rows of 20
            list->SetRowHeight(20.0f);
            root->AddChild(list.Get());
            list->SetModel(&model);
            (void)root->UpdateLayout();
        }
        GUIContext& Context() { return root->GetContext(); }
        AccessTreeUpdate Tree() { return Context().BuildAccessTree(*root.Get()); }
        const AccessNode* ListNode(const AccessTreeUpdate& tree)
        {
            for (const AccessNode& n : tree.Nodes)
                if (n.Role == AccessRole::List)
                    return &n;
            return nullptr;
        }
        const AccessNode* ItemNode(const AccessTreeUpdate& tree, i32 position)
        {
            for (const AccessNode& n : tree.Nodes)
                if (n.Role == AccessRole::ListItem && n.PositionInSet == position)
                    return &n;
            return nullptr;
        }
    };
}

TEST_CASE("item-access: a list of a hundred thousand items sends a few dozen nodes, each knowing its place among all")
{
    ListBed bed(100000);
    const AccessTreeUpdate tree = bed.Tree();
    const AccessNode* list = bed.ListNode(tree);
    REQUIRE(list != nullptr);
    CHECK(list->Children.Size() > 10u);
    CHECK(list->Children.Size() < 60u); // the made rows and a page past them, not every item
    const AccessNode* first = bed.ItemNode(tree, 1);
    REQUIRE(first != nullptr);
    CHECK(first->Id == list->Children[0]);
    CHECK(first->SetSize == 100000);
    CHECK(first->Name == core::String(u8"item 0"));
    CHECK_FALSE(first->Has(AccessOffscreen));
    CHECK(first->Bounds.height == doctest::Approx(20.0f));
    // Past the rows made, within the page beyond: a node, off screen, its bounds estimated below.
    const AccessNode* below = bed.ItemNode(tree, 15);
    REQUIRE(below != nullptr);
    CHECK(below->Has(AccessOffscreen));
    CHECK(below->Bounds.y > first->Bounds.y + 200.0f);
    // The rows' own labels are no longer the list's children.
    for (const u64 child : list->Children)
        CHECK(IsAccessItemId(child));
}

TEST_CASE("item-access: the focus is the current item; End reaches the last of a hundred thousand")
{
    ListBed bed(100000);
    Recorder recorder;
    bed.Context().SetAccessibilityBridge(&recorder);
    bed.list->RequestFocus();
    bed.list->SetSelectedItem(0);
    bed.Context().Update(Frame());
    REQUIRE(!recorder.Updates.IsEmpty());
    const AccessNode* focused = recorder.Last(recorder.Updates.Back().Focus);
    REQUIRE(focused != nullptr);
    CHECK(focused->Role == AccessRole::ListItem);
    CHECK(focused->PositionInSet == 1);

    bed.root->GetEventDispatcher()->InjectKeyDown(static_cast<core::u32>(KeyCode::End));
    (void)bed.root->UpdateLayout();
    bed.Context().Update(Frame());
    focused = recorder.Last(recorder.Updates.Back().Focus);
    REQUIRE(focused != nullptr);
    CHECK(focused->PositionInSet == 100000);
    CHECK(focused->Name == core::String(u8"item 99999"));
    CHECK(focused->Has(AccessSelected));
    CHECK(focused->Has(AccessFocused));
    CHECK_FALSE(focused->Has(AccessOffscreen));
    bed.Context().SetAccessibilityBridge(nullptr);
}

TEST_CASE("item-access: an item's id follows it through scrolling away and back, and rows inserted above")
{
    ListBed bed(1000);
    // Each tree held while its nodes are read (they live in it).
    AccessTreeUpdate tree = bed.Tree();
    REQUIRE(bed.ItemNode(tree, 5) != nullptr);
    const u64 fifth = bed.ItemNode(tree, 5)->Id;
    bed.list->ScrollToItem(500);
    (void)bed.root->UpdateLayout();
    tree = bed.Tree();
    CHECK(bed.ItemNode(tree, 5) == nullptr); // far from the rows made: no node now
    bed.list->ScrollToItem(0);
    (void)bed.root->UpdateLayout();
    tree = bed.Tree();
    REQUIRE(bed.ItemNode(tree, 5) != nullptr);
    CHECK(bed.ItemNode(tree, 5)->Id == fifth);
    bed.model.InsertItem(0, SV(u8"new"));
    (void)bed.root->UpdateLayout();
    tree = bed.Tree();
    const AccessNode* moved = bed.ItemNode(tree, 6);
    REQUIRE(moved != nullptr);
    CHECK(moved->Id == fifth); // the same item, a place further down
    CHECK(moved->Name == core::String(u8"item 4"));

    // Children in item order, whatever order the rows were made in.
    bed.list->ScrollToItem(300);
    (void)bed.root->UpdateLayout();
    bed.list->ScrollToItem(290);
    (void)bed.root->UpdateLayout();
    tree = bed.Tree();
    i32 last = 0;
    for (const u64 child : bed.ListNode(tree)->Children)
    {
        const AccessNode* item = tree.Find(child);
        REQUIRE(item != nullptr);
        CHECK(item->PositionInSet > last);
        last = item->PositionInSet;
    }
}

TEST_CASE("item-access: a screen reader focuses an item off screen, scrolling to it; a removed item refuses")
{
    ListBed bed(1000);
    const AccessTreeUpdate tree = bed.Tree();
    const AccessNode* below = bed.ItemNode(tree, 16);
    REQUIRE(below != nullptr);
    REQUIRE(below->Has(AccessOffscreen));
    AccessActionRequest focus;
    focus.Target = below->Id;
    focus.Action = AccessAction::Focus;
    CHECK(bed.Context().RunAccessAction(focus));
    (void)bed.root->UpdateLayout();
    CHECK(bed.list->IsFocused());
    CHECK(bed.list->GetCurrentItem() == 15);
    CHECK(bed.list->IsItemSelected(15));
    CHECK(bed.list->RowForItem(15) != nullptr); // made: scrolled into view

    const AccessTreeUpdate before = bed.Tree();
    REQUIRE(bed.ItemNode(before, 3) != nullptr);
    const u64 gone = bed.ItemNode(before, 3)->Id;
    bed.model.RemoveItem(2);
    bed.model.RemoveItem(2); // "item 2", then "item 3"
    (void)bed.root->UpdateLayout();
    AccessActionRequest stale;
    stale.Target = gone;
    stale.Action = AccessAction::Focus;
    CHECK_FALSE(bed.Context().RunAccessAction(stale));
}

TEST_CASE("item-access: a tree's items say their level and place among their siblings, and expand")
{
    RegisterGuiElements();
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    MarkupLoader loader(*root->GetElementSet(), core::DefaultAllocator());
    auto tree = loader.LoadFromString(SV(u8R"(<TreeView width="300" height="300" row-height="20">
        <TreeItem text="Code"><TreeItem text="GUI"/><TreeItem text="VG"/><TreeItem text="Fonts"/></TreeItem>
        <TreeItem text="Data"/>
    </TreeView>)"));
    auto* view = core::Cast<TreeView>(tree.Get());
    REQUIRE(view != nullptr);
    root->AddChild(view);
    (void)root->UpdateLayout();
    GUIContext& gui = root->GetContext();
    const auto find = [&](const AccessTreeUpdate& t, const char8_t* name) -> const AccessNode*
    {
        for (const AccessNode& n : t.Nodes)
            if (n.Role == AccessRole::TreeItem && n.Name == core::String(name))
                return &n;
        return nullptr;
    };
    AccessTreeUpdate t = gui.BuildAccessTree(*root.Get());
    const AccessNode* code = find(t, u8"Code");
    REQUIRE(code != nullptr);
    CHECK(code->Level == 1);
    CHECK(code->PositionInSet == 1);
    CHECK(code->SetSize == 2);
    CHECK(code->Has(AccessCollapsed));
    CHECK(code->Takes(AccessAction::Expand));
    CHECK(find(t, u8"VG") == nullptr); // closed: its children are not items

    AccessActionRequest expand;
    expand.Target = code->Id;
    expand.Action = AccessAction::Expand;
    CHECK(gui.RunAccessAction(expand));
    (void)root->UpdateLayout();
    t = gui.BuildAccessTree(*root.Get());
    const AccessNode* vg = find(t, u8"VG");
    REQUIRE(vg != nullptr);
    CHECK(vg->Level == 2);
    CHECK(vg->PositionInSet == 2);
    CHECK(vg->SetSize == 3);
    CHECK(find(t, u8"Code")->Has(AccessExpanded));
}

TEST_CASE("item-access: a table's rows say their index; the table its rows and columns")
{
    TableModel model; // first: it outlives the view that registers with it
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    core::Array<core::String> columns;
    columns.PushBack(core::String(u8"Name"));
    columns.PushBack(core::String(u8"Age"));
    columns.PushBack(core::String(u8"City"));
    model.SetColumns(core::Move(columns));
    for (int i = 0; i < 40; ++i)
    {
        core::Array<Variant> row;
        row.PushBack(Variant(SV(u8"Person")));
        row.PushBack(Variant(static_cast<core::i64>(20 + i)));
        row.PushBack(Variant(SV(u8"Town")));
        model.AddRow(core::Move(row));
    }
    auto table = core::MakeRef<TableView>(core::DefaultAllocator());
    table->SetSize(core::Float2{300.0f, 200.0f});
    table->SetRowHeight(24.0f);
    root->AddChild(table.Get());
    table->SetModel(&model);
    (void)root->UpdateLayout();
    const AccessTreeUpdate t = root->GetContext().BuildAccessTree(*root.Get());
    const AccessNode* tableNode = nullptr;
    const AccessNode* third = nullptr;
    for (const AccessNode& n : t.Nodes)
    {
        if (n.Role == AccessRole::Table)
            tableNode = &n;
        if (n.Role == AccessRole::Row && n.RowIndex == 3)
            third = &n;
    }
    REQUIRE(tableNode != nullptr);
    CHECK(tableNode->RowCount == 40);
    CHECK(tableNode->ColumnCount == 3);
    REQUIRE(third != nullptr);
    CHECK(third->SetSize == 40);
}
