// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - markup coverage (E6): every control is a markup element. The data views take their data
// from markup (a tree's nested items, a table's columns and rows), a scroll bar is a range like
// the slider, and a message box waits in its page until a script shows it.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    core::RefPtr<Node> Load(core::StringView markup)
    {
        RegisterGuiElements();
        static const ElementSet elements = ElementSet::All();
        MarkupLoader loader(elements, core::DefaultAllocator());
        return loader.LoadFromString(markup);
    }
}

TEST_CASE("markup: every control is an element")
{
    // The rest: EveryControlIsAnElement in Code/Foundation/Sedulous.GUI.Tests/src/MarkupCoverageTests.bf.
    const char8_t* controls[] = {
        u8"<ListView/>", u8"<TreeView/>", u8"<TableView/>",
    };
    for (const char8_t* markup : controls)
    {
        CAPTURE(reinterpret_cast<const char*>(markup));
        CHECK(Load(SV(markup)).Get() != nullptr);
    }
}

TEST_CASE("markup: a tree view's nested items become its model, open where they say")
{
    auto tree = Load(SV(u8R"(<TreeView>
        <TreeItem text="Code" expanded="true">
            <TreeItem text="GUI"/>
            <TreeItem text="Foundation"><TreeItem text="VG"/></TreeItem>
        </TreeItem>
        <TreeItem text="Data"/>
    </TreeView>)"));
    auto* view = core::Cast<TreeView>(tree.Get());
    REQUIRE(view != nullptr);
    REQUIRE(view->GetModel() != nullptr);
    CHECK(view->GetModel()->RowCount() == 2); // Code, Data
    CHECK(view->IsItemExpanded(0));
    CHECK(view->ItemDepth(1) == 1); // GUI, under the open Code
    CHECK_FALSE(view->IsItemExpanded(2)); // Foundation, closed
    CHECK(view->GetModel()->Data(view->GetModel()->Index(1)).ToString() == SV(u8"Data"));
}

TEST_CASE("markup: a table view's columns and rows become a model behind a sorting proxy")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 300.0f});
    auto tree = Load(SV(u8R"(<TableView width="300" height="200" columns="Name|Score|Rate" column-widths="50% auto" editable="true">
        <TableItem cells="Ada|42|0.5"/>
        <TableItem cells="Bo|7|1.25"/>
        <TableItem cells="Cara|100|-2"/>
    </TableView>)"));
    auto* table = core::Cast<TableView>(tree.Get());
    REQUIRE(table != nullptr);
    root->AddChild(table);
    (void)root->UpdateLayout();
    IModel* model = table->GetModel();
    REQUIRE(model != nullptr);
    CHECK(model->ColumnCount() == 3);
    CHECK(model->RowCount() == 3);
    CHECK(table->GetColumnsText() == SV(u8"Name|Score|Rate"));
    CHECK(model->Data(MakeModelIndex(0, 1)).GetType() == Variant::Type::Int);
    CHECK(model->Data(MakeModelIndex(1, 2)).GetType() == Variant::Type::Float);
    CHECK(model->Data(MakeModelIndex(2, 2)).GetType() == Variant::Type::Int);
    CHECK(table->GetColumnWidth(0) == doctest::Approx(150.0f));
    CHECK(table->IsEditable());
    CHECK(model->IsEditable(MakeModelIndex(0, 0)));

    // Its header sorts by value (100 after 42, not before).
    root->GetEventDispatcher()->InjectMouseDown(core::Float2{180.0f, 13.0f}, MouseButton::Left);
    root->GetEventDispatcher()->InjectMouseUp(core::Float2{180.0f, 13.0f}, MouseButton::Left);
    CHECK(table->GetSortColumn() == 1);
    CHECK(model->Data(MakeModelIndex(2, 1)).AsInt() == 100);
}

