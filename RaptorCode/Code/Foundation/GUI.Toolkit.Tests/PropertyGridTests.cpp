// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the property grid (T1 of Specs/gui-lab-evolution-3.md): a source's properties as rows,
// categories first-seen and groups folded by path, a search keeping what holds a match, only the
// rows in view realised, one label split dragged at any row, the wheel scrolling and never editing,
// and an edit as the source's gesture, its row not rebound from its own previews.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.gui.toolkit;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::i32;
using core::i64;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<PropertyGrid> grid = core::MakeRef<PropertyGrid>(core::DefaultAllocator());
        PropertyBag bag;

        explicit Bed(usize objects = 1) : bag(core::DefaultAllocator(), objects)
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            grid->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(300.0f);
                s.Height = LayoutLength::Px(240.0f);
            });
            root->AddChild(grid.Get());
        }
        ~Bed() { grid->SetSource(nullptr); }
        PropertyInfo& Add(const char8_t* path, PropertyKind kind, const Variant& value = {}, const char8_t* category = u8"")
        {
            PropertyInfo& info = bag.Add(SV(path), kind, value);
            info.Category = core::String(category);
            return info;
        }
        void Show()
        {
            grid->SetSource(&bag);
            Frame();
        }
        void Frame() { (void)root->UpdateLayout(); }
        core::Array<core::String> Paths() const
        {
            core::Array<core::String> out(core::DefaultAllocator());
            for (usize i = 0; i < grid->GetRowCount(); ++i)
                out.PushBack(grid->GetRow(static_cast<i32>(i))->Path);
            return out;
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
    };

    core::String Join(const core::Array<core::String>& paths)
    {
        core::String out;
        for (const core::String& path : paths)
        {
            if (out.Size() != 0)
                out.Append(SV(u8" "));
            out.Append(path.AsView());
        }
        return out;
    }
    core::Float2 Centre(const Node& node)
    {
        const Rect r = node.GetScreenBounds();
        return core::Float2{r.x + r.width * 0.5f, r.y + r.height * 0.5f};
    }
}

TEST_CASE("property grid: what has no category first, then categories as they first come; groups start folded")
{
    Bed bed;
    bed.Add(u8"name", PropertyKind::String, Variant(SV(u8"Lamp")));
    bed.Add(u8"intensity", PropertyKind::Float, Variant(1.0), u8"Light");
    bed.Add(u8"position", PropertyKind::Group, {}, u8"Transform");
    bed.Add(u8"position.x", PropertyKind::Float, Variant(0.0));
    bed.Add(u8"position.y", PropertyKind::Float, Variant(0.0));
    bed.Add(u8"color", PropertyKind::Float, Variant(0.5), u8"Light");
    bed.Add(u8"secret", PropertyKind::Bool, Variant(false)).Visible = false;
    bed.Show();
    CHECK(Join(bed.Paths()) == core::String(u8"name #Light intensity color #Transform position"));
    CHECK(bed.grid->GetRow(1)->Category);
    CHECK(bed.grid->GetRow(5)->HasChildren);
    CHECK_FALSE(bed.grid->GetRow(5)->Open);
    CHECK(bed.grid->FindEditor(SV(u8"intensity")) != nullptr);

    // A group opened shows its parts a level in; the folding is by path, so it stays when the
    // source's properties are read again.
    bed.grid->SetOpen(SV(u8"position"), true);
    CHECK(Join(bed.Paths()) == core::String(u8"name #Light intensity color #Transform position position.x position.y"));
    CHECK(bed.grid->GetRow(6)->Depth == 1);
    bed.bag.Add(SV(u8"scale"), PropertyKind::Float, Variant(1.0)).Category = core::String(u8"Transform");
    bed.bag.PropertiesChanged(); // its category, set after it was added
    CHECK(Join(bed.Paths()) == core::String(u8"name #Light intensity color #Transform position position.x position.y scale"));

    // A category closed hides what is in it.
    bed.grid->SetOpen(SV(u8"#Light"), false);
    CHECK(Join(bed.Paths()) == core::String(u8"name #Light #Transform position position.x position.y scale"));
}

TEST_CASE("property grid: the chevron, a header's click and Left and Right fold and unfold")
{
    Bed bed;
    bed.Add(u8"offset", PropertyKind::Group, {}, u8"Physics");
    bed.Add(u8"offset.x", PropertyKind::Float, Variant(0.0));
    bed.Show();
    REQUIRE(bed.grid->GetRowCount() == 2u);

    ItemRow* header = bed.grid->RowForItem(0);
    REQUIRE(header != nullptr);
    bed.D().InjectMouseDown(Centre(*header), MouseButton::Left);
    bed.D().InjectMouseUp(Centre(*header), MouseButton::Left);
    CHECK_FALSE(bed.grid->IsOpen(SV(u8"#Physics")));
    CHECK(bed.grid->GetRowCount() == 1u);
    bed.grid->SetOpen(SV(u8"#Physics"), true);
    bed.Frame();

    // The group's row selected, Right opens it and Left closes it.
    bed.grid->SetSelectedItem(1);
    bed.grid->RequestFocus();
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    CHECK(bed.grid->IsOpen(SV(u8"offset")));
    CHECK(bed.grid->GetRowCount() == 3u);
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Left));
    CHECK_FALSE(bed.grid->IsOpen(SV(u8"offset")));
}

TEST_CASE("property grid: a search keeps matches by name or path, with what holds them opened; the folding stays")
{
    Bed bed;
    bed.Add(u8"name", PropertyKind::String, Variant(SV(u8"Lamp")));
    bed.Add(u8"position", PropertyKind::Group, {}, u8"Transform");
    bed.Add(u8"position.x", PropertyKind::Float, Variant(0.0)).DisplayName = core::String(u8"Along");
    bed.Add(u8"position.y", PropertyKind::Float, Variant(0.0));
    bed.Add(u8"intensity", PropertyKind::Float, Variant(1.0), u8"Light");
    bed.Show();
    bed.grid->SetOpen(SV(u8"#Light"), false);

    bed.grid->SetFilter(SV(u8"ALONG")); // by shown name, either case
    CHECK(Join(bed.Paths()) == core::String(u8"#Transform position position.x"));
    bed.grid->SetFilter(SV(u8"position.y")); // by path
    CHECK(Join(bed.Paths()) == core::String(u8"#Transform position position.y"));
    bed.grid->SetFilter(SV(u8"inten")); // in a closed category: opened while searching
    CHECK(Join(bed.Paths()) == core::String(u8"#Light intensity"));
    bed.grid->SetFilter(SV(u8"position")); // a group that matches keeps its own folding
    CHECK(Join(bed.Paths()) == core::String(u8"#Transform position"));
    bed.grid->SetFilter(SV(u8"nothing"));
    CHECK(bed.grid->GetRowCount() == 0u);

    bed.grid->SetFilter(SV(u8""));
    CHECK(Join(bed.Paths()) == core::String(u8"name #Transform position #Light"));
}

TEST_CASE("property grid: only the rows in view are realised")
{
    Bed bed;
    for (int i = 0; i < 500; ++i)
        bed.bag.Add(core::Format(u8"p{}", i).AsView(), PropertyKind::Float, Variant(static_cast<double>(i)));
    bed.Show();
    CHECK(bed.grid->GetRowCount() == 500u);
    CHECK(bed.grid->VisibleRowCount() > 5u);
    CHECK(bed.grid->VisibleRowCount() < 20u);
    CHECK(bed.grid->FindEditor(SV(u8"p0")) != nullptr);
    CHECK(bed.grid->FindEditor(SV(u8"p400")) == nullptr);
    bed.grid->ScrollToItem(400);
    bed.Frame();
    REQUIRE(bed.grid->FindEditor(SV(u8"p400")) != nullptr);
    NumberPropertyEditor* editor = core::Cast<NumberPropertyEditor>(bed.grid->FindEditor(SV(u8"p400")));
    REQUIRE(editor != nullptr);
    CHECK(editor->GetField()->GetValue() == doctest::Approx(400.0)); // a pooled editor shows its row's value
}

TEST_CASE("property grid: an edit is one gesture of the source; its row keeps its editor while it previews")
{
    Bed bed(2);
    PropertyInfo& info = bed.Add(u8"speed", PropertyKind::Float, Variant(2.0));
    info.Step = 1.0;
    bed.bag.SetValue(SV(u8"speed"), 1, Variant(5.0));
    core::Array<PropertyBag::Commit> commits(core::DefaultAllocator());
    bed.bag.SetOnCommit([&commits](const PropertyBag::Commit& commit) { commits.PushBack(commit); });
    bed.Show();

    NumberPropertyEditor* editor = core::Cast<NumberPropertyEditor>(bed.grid->FindEditor(SV(u8"speed")));
    REQUIRE(editor != nullptr);
    NumberField& field = *editor->GetField();
    CHECK(field.IsMixed());

    const core::Float2 at = Centre(field) - core::Float2{30.0f, 0.0f};
    bed.D().InjectMouseDown(at, MouseButton::Left);
    bed.D().InjectMouseMove(at + core::Float2{8.0f, 0.0f});
    bed.Frame();
    CHECK(bed.grid->GetEditPath() == SV(u8"speed"));
    CHECK(bed.bag.GetValue(SV(u8"speed"), 1).AsFloat() == doctest::Approx(4.0)); // previewed on both
    bed.D().InjectMouseMove(at + core::Float2{16.0f, 0.0f});
    bed.Frame();
    CHECK(field.GetValue() == doctest::Approx(6.0));
    bed.D().InjectMouseUp(at + core::Float2{16.0f, 0.0f}, MouseButton::Left);
    bed.Frame();
    CHECK(bed.grid->GetEditPath().Size() == 0u);
    REQUIRE(commits.Size() == 1u);
    CHECK(commits[0].Before[0].AsFloat() == doctest::Approx(2.0));
    CHECK(commits[0].Before[1].AsFloat() == doctest::Approx(5.0));
    CHECK(commits[0].After[1].AsFloat() == doctest::Approx(6.0));
    CHECK_FALSE(field.IsMixed());

    // A value changed elsewhere (an undo) shows.
    bed.bag.SetValue(SV(u8"speed"), 0, Variant(9.0));
    bed.Frame();
    CHECK(field.IsMixed());
}

TEST_CASE("property grid: the label split is dragged at any row, for every row, mirrored right to left")
{
    Bed bed;
    bed.root->SetPadding(Thickness{50.0f, 30.0f, 0.0f, 0.0f}); // the grid away from the origin
    bed.Add(u8"a", PropertyKind::Float, Variant(1.0));
    bed.Add(u8"b", PropertyKind::Float, Variant(2.0));
    bed.Show();
    PropertyEditor* a = bed.grid->FindEditor(SV(u8"a"));
    PropertyEditor* b = bed.grid->FindEditor(SV(u8"b"));
    REQUIRE(a != nullptr);
    REQUIRE(b != nullptr);
    const f32 before = a->GetScreenBounds().x;

    const PropertyRowContent* row = core::Cast<PropertyRowContent>(b->GetParent());
    REQUIRE(row != nullptr);
    const core::Float2 grip = Centre(*row->GetSplitHandle());
    bed.D().InjectMouseMove(grip);
    CHECK(bed.D().GetCursor() == Cursor::EwResize);
    bed.D().InjectMouseDown(grip, MouseButton::Left);
    bed.D().InjectMouseMove(grip + core::Float2{60.0f, 0.0f});
    bed.D().InjectMouseUp(grip + core::Float2{60.0f, 0.0f}, MouseButton::Left);
    bed.Frame();
    // The split follows the pointer: 60 pixels further along the rows' width.
    const f32 rows = bed.grid->GetContentBounds().width;
    CHECK(bed.grid->GetLabelRatio() == doctest::Approx(0.4f + 60.0f / rows).epsilon(0.02));
    CHECK(a->GetScreenBounds().x > before + 50.0f); // the other row's editor moved too

    bed.grid->SetLabelRatio(0.05f);
    CHECK(bed.grid->GetLabelRatio() == doctest::Approx(0.1f));

    // Right to left the labels are at the right, the editors at the left.
    bed.grid->SetLabelRatio(0.4f);
    bed.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    bed.Frame();
    const Rect box = bed.grid->GetScreenBounds();
    CHECK(a->GetScreenBounds().x < box.x + 10.0f);
}

TEST_CASE("property grid: the wheel over an editor scrolls the grid and never changes a value")
{
    Bed bed;
    for (int i = 0; i < 60; ++i)
        bed.bag.Add(core::Format(u8"p{}", i).AsView(), PropertyKind::Float, Variant(1.0));
    bed.Show();
    NumberPropertyEditor* editor = core::Cast<NumberPropertyEditor>(bed.grid->FindEditor(SV(u8"p0")));
    REQUIRE(editor != nullptr);
    editor->GetField()->RequestFocus();
    bed.D().InjectMouseWheel(Centre(*editor->GetField()), core::Float2{0.0f, -3.0f});
    bed.Frame();
    CHECK(bed.bag.GetValue(SV(u8"p0"), 0).AsFloat() == doctest::Approx(1.0));
    CHECK(bed.grid->GetScrollOffset().y > 0.0f);
}

TEST_CASE("property grid: an application's editor for a hint, a hint none takes, and markup makes a grid")
{
    Bed bed;
    bed.Add(u8"look", PropertyKind::Float, Variant(1.0)).Hint = core::String(u8"toggle");
    bed.Show();
    CHECK(core::Cast<NumberPropertyEditor>(bed.grid->FindEditor(SV(u8"look"))) != nullptr);
    bed.grid->GetEditors().RegisterHint(SV(u8"toggle"), [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<BoolPropertyEditor>(a); });
    bed.grid->Refresh();
    bed.Frame();
    CHECK(core::Cast<BoolPropertyEditor>(bed.grid->FindEditor(SV(u8"look"))) != nullptr);

    // A group hinted for an editor no one registered says so (a hinted group with rows of its own
    // shows them instead); one with no hint has no editor.
    bed.Add(u8"falloff", PropertyKind::Group).Hint = core::String(u8"curve");
    bed.Add(u8"plain", PropertyKind::Group);
    bed.Frame();
    UnknownPropertyEditor* unknown = core::Cast<UnknownPropertyEditor>(bed.grid->FindEditor(SV(u8"falloff")));
    REQUIRE(unknown != nullptr);
    CHECK(unknown->GetMessage() == SV(u8"No editor for curve"));
    CHECK(bed.grid->FindEditor(SV(u8"plain")) == nullptr);

    RegisterGuiElements();
    RegisterToolkitElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> made = loader.LoadFromString(SV(u8R"(<PropertyGrid label-ratio="0.3" indent-width="20"/>)"));
    PropertyGrid* grid = core::Cast<PropertyGrid>(made.Get());
    REQUIRE(grid != nullptr);
    CHECK(grid->GetLabelRatio() == doctest::Approx(0.3f));
    CHECK(grid->GetIndentWidth() == doctest::Approx(20.0f));
}

TEST_CASE("property grid: a Float3 is one row of a field per part, each mixed and edited on its own")
{
    Bed bed(2);
    bed.Add(u8"position", PropertyKind::Group, {}, u8"Transform").Hint = core::String(u8"Float3");
    bed.Add(u8"position.x", PropertyKind::Float, Variant(1.0)).DisplayName = core::String(u8"X");
    bed.Add(u8"position.y", PropertyKind::Float, Variant(2.0)).DisplayName = core::String(u8"Y");
    bed.Add(u8"position.z", PropertyKind::Float, Variant(3.0)).DisplayName = core::String(u8"Z");
    bed.bag.SetValue(SV(u8"position.y"), 1, Variant(7.0)); // the objects differ in Y alone
    core::Array<PropertyBag::Commit> commits(core::DefaultAllocator());
    bed.bag.SetOnCommit([&commits](const PropertyBag::Commit& commit) { commits.PushBack(commit); });
    bed.Show();

    // One row, no chevron, nothing under it.
    CHECK(Join(bed.Paths()) == core::String(u8"#Transform position"));
    CHECK_FALSE(bed.grid->GetRow(1)->HasChildren);
    FloatsPropertyEditor* editor = core::Cast<FloatsPropertyEditor>(bed.grid->FindEditor(SV(u8"position")));
    REQUIRE(editor != nullptr);
    REQUIRE(editor->GetPartCount() == 3u);
    CHECK(editor->GetPartLabel(0)->GetText() == SV(u8"X"));
    CHECK(editor->GetPartLabel(2)->GetText() == SV(u8"Z"));
    NumberField& x = *editor->GetPart(0)->GetField();
    CHECK_FALSE(x.IsMixed());
    CHECK(x.GetValue() == doctest::Approx(1.0));
    CHECK(editor->GetPart(1)->GetField()->IsMixed());
    CHECK_FALSE(editor->GetPart(2)->GetField()->IsMixed());

    // A scrub of X writes X alone, on both, and keeps the row while it goes.
    x.SetStep(1.0);
    const core::Float2 at = Centre(x) - core::Float2{10.0f, 0.0f};
    bed.D().InjectMouseDown(at, MouseButton::Left);
    bed.D().InjectMouseMove(at + core::Float2{8.0f, 0.0f});
    bed.Frame();
    CHECK(bed.grid->GetEditPath() == SV(u8"position.x"));
    CHECK(bed.grid->FindEditor(SV(u8"position")) == editor);
    bed.D().InjectMouseUp(at + core::Float2{8.0f, 0.0f}, MouseButton::Left);
    bed.Frame();
    REQUIRE(commits.Size() == 1u);
    CHECK(commits[0].Path == core::String(u8"position.x"));
    CHECK(bed.bag.GetValue(SV(u8"position.x"), 1).AsFloat() == doctest::Approx(3.0));
    CHECK(bed.bag.GetValue(SV(u8"position.y"), 1).AsFloat() == doctest::Approx(7.0)); // Y kept its differences
    CHECK(editor->GetPart(1)->GetField()->IsMixed());

    // A search for a part shows the row that holds it.
    bed.grid->SetFilter(SV(u8"position.z"));
    CHECK(Join(bed.Paths()) == core::String(u8"#Transform position"));
}

namespace
{
    core::String Elements(const PropertyBag& bag, core::StringView list, usize object)
    {
        core::String out;
        for (usize i = 0; i < bag.ElementCount(list, object); ++i)
        {
            if (out.Size() != 0)
                out.Append(SV(u8" "));
            out.Append(bag.GetValue(core::Format(u8"{}.{}", list, i).AsView(), object).ToString().AsView());
        }
        return out;
    }
    void Activate(Menu& menu, core::StringView text)
    {
        for (usize i = 0; i < menu.ChildCount(); ++i)
            if (MenuItem* item = core::Cast<MenuItem>(menu.GetChildAt(i)); item != nullptr && item->GetText() == text)
            {
                (void)item->HandleActivate();
                return;
            }
        FAIL("no such item");
    }
}

TEST_CASE("property grid: a list shows its elements, the fewest any object has, and its count mixed")
{
    Bed bed(2);
    bed.bag.AddList(SV(u8"weights"), PropertyKind::Float, Variant(0.5), 3);
    bed.Show();
    ListPropertyEditor* list = core::Cast<ListPropertyEditor>(bed.grid->FindEditor(SV(u8"weights")));
    REQUIRE(list != nullptr);
    CHECK(list->GetCountLabel()->GetText() == SV(u8"3 elements"));
    CHECK(Join(bed.Paths()) == core::String(u8"weights")); // a list starts folded
    bed.grid->SetOpen(SV(u8"weights"), true);
    CHECK(Join(bed.Paths()) == core::String(u8"weights weights.0 weights.1 weights.2"));
    CHECK(bed.grid->GetRow(1)->Element);
    CHECK(bed.grid->GetRow(1)->Depth == 1);

    // The second object with one more: the count is mixed, and the three both have show.
    bed.bag.ResizeList(SV(u8"weights"), 1, 4);
    bed.Frame();
    list = core::Cast<ListPropertyEditor>(bed.grid->FindEditor(SV(u8"weights")));
    REQUIRE(list != nullptr);
    CHECK(list->GetCountLabel()->GetText() == MixedValueText());
    CHECK(Join(bed.Paths()) == core::String(u8"weights weights.0 weights.1 weights.2"));
}

TEST_CASE("property grid: Add puts an element at the end of each object's list and opens it; a full list cannot")
{
    Bed bed(2);
    PropertyInfo& info = bed.bag.AddList(SV(u8"tags"), PropertyKind::String, Variant(SV(u8"new")), 1);
    info.MaxCount = 3;
    bed.Show();
    ListPropertyEditor* list = core::Cast<ListPropertyEditor>(bed.grid->FindEditor(SV(u8"tags")));
    REQUIRE(list != nullptr);
    CHECK(list->GetCountLabel()->GetText() == SV(u8"1 element"));
    bed.D().InjectMouseMove(Centre(*list->GetAddButton()));
    bed.D().InjectMouseDown(Centre(*list->GetAddButton()), MouseButton::Left);
    bed.D().InjectMouseUp(Centre(*list->GetAddButton()), MouseButton::Left);
    bed.Frame();
    CHECK(bed.bag.ElementCount(SV(u8"tags"), 0) == 2u);
    CHECK(bed.bag.ElementCount(SV(u8"tags"), 1) == 2u);
    CHECK(bed.grid->IsOpen(SV(u8"tags")));
    CHECK(bed.grid->FindRow(SV(u8"tags.1")) >= 0);

    list = core::Cast<ListPropertyEditor>(bed.grid->FindEditor(SV(u8"tags")));
    REQUIRE(list != nullptr);
    bed.D().InjectMouseDown(Centre(*list->GetAddButton()), MouseButton::Left);
    bed.D().InjectMouseUp(Centre(*list->GetAddButton()), MouseButton::Left);
    bed.Frame();
    list = core::Cast<ListPropertyEditor>(bed.grid->FindEditor(SV(u8"tags")));
    REQUIRE(list != nullptr);
    CHECK(bed.bag.ElementCount(SV(u8"tags"), 0) == 3u);
    CHECK_FALSE(list->GetAddButton()->IsEnabled()); // its most
}

TEST_CASE("property grid: a list of several types adds the one picked from a menu")
{
    Bed bed;
    PropertyInfo& info = bed.bag.AddList(SV(u8"effects"), PropertyKind::String, Variant(SV(u8"")));
    info.ElementTypes.PushBack(core::String(u8"Flicker"));
    info.ElementTypes.PushBack(core::String(u8"Pulse"));
    core::String asked;
    bed.bag.SetOnListEdited([&asked](core::StringView, const ListEdit& edit) { asked = edit.ElementType; });
    bed.Show();
    ListPropertyEditor* list = core::Cast<ListPropertyEditor>(bed.grid->FindEditor(SV(u8"effects")));
    REQUIRE(list != nullptr);
    bed.D().InjectMouseDown(Centre(*list->GetAddButton()), MouseButton::Left);
    bed.D().InjectMouseUp(Centre(*list->GetAddButton()), MouseButton::Left);
    bed.Frame();
    REQUIRE(list->GetTypeMenu() != nullptr);
    Activate(*list->GetTypeMenu(), SV(u8"Pulse"));
    CHECK(asked == core::String(u8"Pulse"));
    CHECK(bed.bag.ElementCount(SV(u8"effects"), 0) == 1u);
}

TEST_CASE("property grid: an element's menu inserts, removes and moves it")
{
    Bed bed;
    bed.bag.AddList(SV(u8"steps"), PropertyKind::Integer, Variant(core::i64{0}), 3);
    for (core::i64 i = 0; i < 3; ++i)
        bed.bag.SetValue(core::Format(u8"steps.{}", i).AsView(), 0, Variant(i + 1));
    bed.Show();
    bed.grid->SetOpen(SV(u8"steps"), true);
    bed.Frame();
    CHECK(Elements(bed.bag, SV(u8"steps"), 0) == core::String(u8"1 2 3"));

    REQUIRE(bed.grid->OpenRowMenu(bed.grid->FindRow(SV(u8"steps.0")), core::Float2{20.0f, 20.0f}));
    Activate(*bed.grid->GetRowMenu(), SV(u8"Move down"));
    CHECK(Elements(bed.bag, SV(u8"steps"), 0) == core::String(u8"2 1 3"));
    REQUIRE(bed.grid->OpenRowMenu(bed.grid->FindRow(SV(u8"steps.2")), core::Float2{20.0f, 20.0f}));
    Activate(*bed.grid->GetRowMenu(), SV(u8"Remove"));
    CHECK(Elements(bed.bag, SV(u8"steps"), 0) == core::String(u8"2 1"));
    REQUIRE(bed.grid->OpenRowMenu(bed.grid->FindRow(SV(u8"steps.1")), core::Float2{20.0f, 20.0f}));
    Activate(*bed.grid->GetRowMenu(), SV(u8"Insert above"));
    CHECK(Elements(bed.bag, SV(u8"steps"), 0) == core::String(u8"2 0 1"));

    // A list that may not move: its elements' Move items are disabled, and they show no grip.
    bed.bag.FindInfo(SV(u8"steps"))->ListOps = PropertyListAdd | PropertyListRemove;
    bed.bag.PropertiesChanged();
    bed.Frame();
    REQUIRE(bed.grid->OpenRowMenu(bed.grid->FindRow(SV(u8"steps.0")), core::Float2{20.0f, 20.0f}));
    for (usize i = 0; i < bed.grid->GetRowMenu()->ChildCount(); ++i)
        if (MenuItem* item = core::Cast<MenuItem>(bed.grid->GetRowMenu()->GetChildAt(i)); item != nullptr && item->GetText() == SV(u8"Move down"))
            CHECK_FALSE(item->IsEnabled());
    ItemRow* row = bed.grid->RowForItem(bed.grid->FindRow(SV(u8"steps.0")));
    REQUIRE(row != nullptr);
    CHECK_FALSE(core::Cast<PropertyRowContent>(row->GetContent())->GetGrip()->IsDisplayed());
}

TEST_CASE("property grid: an element's grip drags it to another place in its list")
{
    Bed bed;
    bed.bag.AddList(SV(u8"steps"), PropertyKind::Integer, Variant(core::i64{0}), 4);
    for (core::i64 i = 0; i < 4; ++i)
        bed.bag.SetValue(core::Format(u8"steps.{}", i).AsView(), 0, Variant(i + 1));
    bed.Show();
    bed.grid->SetOpen(SV(u8"steps"), true);
    bed.Frame();

    const auto grip = [&bed](const char8_t* path) -> PropertyGrip&
    {
        ItemRow* row = bed.grid->RowForItem(bed.grid->FindRow(SV(path)));
        REQUIRE(row != nullptr);
        return *core::Cast<PropertyRowContent>(row->GetContent())->GetGrip();
    };
    const auto lower = [&bed](const char8_t* path)
    {
        const Rect r = bed.grid->RowForItem(bed.grid->FindRow(SV(path)))->GetScreenBounds();
        return core::Float2{r.x + 100.0f, r.y + r.height * 0.75f};
    };
    PropertyGrip& first = grip(u8"steps.0");
    CHECK(first.IsDisplayed());
    const core::Float2 from = Centre(first);
    bed.D().InjectMouseMove(from);
    bed.D().InjectMouseDown(from, MouseButton::Left);
    bed.D().InjectMouseMove(lower(u8"steps.2")); // below the third: it goes third
    CHECK(bed.grid->GetReorderTarget() == 2);
    bed.D().InjectMouseUp(lower(u8"steps.2"), MouseButton::Left);
    bed.Frame();
    CHECK(Elements(bed.bag, SV(u8"steps"), 0) == core::String(u8"2 3 1 4"));

    // Let go off the list: nothing moves.
    PropertyGrip& last = grip(u8"steps.3");
    bed.D().InjectMouseDown(Centre(last), MouseButton::Left);
    bed.D().InjectMouseMove(core::Float2{Centre(last).x, 400.0f});
    CHECK(bed.grid->GetReorderTarget() == -1);
    bed.D().InjectMouseUp(core::Float2{Centre(last).x, 400.0f}, MouseButton::Left);
    CHECK(Elements(bed.bag, SV(u8"steps"), 0) == core::String(u8"2 3 1 4"));
}

TEST_CASE("property grid: a row differing from its default is marked, so is what holds it, and Revert puts each object's back")
{
    Bed bed(2);
    bed.Add(u8"size", PropertyKind::Float, Variant(1.0));
    bed.Add(u8"offset", PropertyKind::Group, {}, u8"Shape");
    bed.Add(u8"offset.x", PropertyKind::Float, Variant(0.0));
    bed.bag.SetDefault(SV(u8"size"), Variant(1.0));
    bed.bag.SetDefault(SV(u8"offset.x"), Variant(0.0), 0);
    bed.bag.SetDefault(SV(u8"offset.x"), Variant(4.0), 1); // the second's default differs
    bed.Show();
    CHECK_FALSE(bed.grid->IsRowChanged(SV(u8"size")));
    CHECK(bed.grid->IsRowChanged(SV(u8"offset"))); // the second object's x is not its default
    bed.grid->SetOpen(SV(u8"offset"), true);
    CHECK(bed.grid->IsRowChanged(SV(u8"offset.x")));

    // Changed, the row's content says so.
    bed.bag.SetValue(SV(u8"size"), 0, Variant(3.0));
    bed.Frame();
    CHECK(bed.grid->IsRowChanged(SV(u8"size")));
    ItemRow* row = bed.grid->RowForItem(bed.grid->FindRow(SV(u8"size")));
    REQUIRE(row != nullptr);
    CHECK(core::Cast<PropertyRowContent>(row->GetContent())->IsChanged());

    // The group's Revert puts back each object's own default.
    REQUIRE(bed.grid->OpenRowMenu(bed.grid->FindRow(SV(u8"offset")), core::Float2{20.0f, 20.0f}));
    Activate(*bed.grid->GetRowMenu(), SV(u8"Revert to default"));
    bed.Frame();
    CHECK(bed.bag.GetValue(SV(u8"offset.x"), 1).AsFloat() == doctest::Approx(4.0));
    CHECK_FALSE(bed.grid->IsRowChanged(SV(u8"offset")));

    // Unchanged, its Revert is disabled.
    REQUIRE(bed.grid->OpenRowMenu(bed.grid->FindRow(SV(u8"offset.x")), core::Float2{20.0f, 20.0f}));
    for (usize i = 0; i < bed.grid->GetRowMenu()->ChildCount(); ++i)
        if (MenuItem* item = core::Cast<MenuItem>(bed.grid->GetRowMenu()->GetChildAt(i)); item != nullptr)
            CHECK_FALSE(item->IsEnabled());
}

namespace
{
    class MemoryClipboard : public IClipboard
    {
    public:
        [[nodiscard]] bool HasText() const override { return m_text.Size() != 0; }
        [[nodiscard]] core::String GetText() const override { return m_text; }
        void SetText(core::StringView text) override { m_text = core::String(text); }

    private:
        core::String m_text;
    };
}

TEST_CASE("property grid: Copy and Paste go through the source, from the menu or the keys; a refusal says why")
{
    Bed bed(2);
    MemoryClipboard clipboard;
    bed.D().SetClipboard(&clipboard);
    bed.Add(u8"speed", PropertyKind::Float, Variant(2.5));
    bed.Add(u8"slow", PropertyKind::Float, Variant(0.5));
    bed.Add(u8"name", PropertyKind::String, Variant(SV(u8"Lamp")));
    core::String said;
    bed.grid->SetOnMessage([&said](core::StringView text) { said = core::String(text); });
    int commits = 0;
    bed.bag.SetOnCommit([&commits](const PropertyBag::Commit&) { ++commits; });
    bed.Show();

    REQUIRE(bed.grid->OpenRowMenu(bed.grid->FindRow(SV(u8"speed")), core::Float2{20.0f, 20.0f}));
    Activate(*bed.grid->GetRowMenu(), SV(u8"Copy"));
    CHECK(clipboard.GetText() == core::String(u8"2.5"));
    REQUIRE(bed.grid->OpenRowMenu(bed.grid->FindRow(SV(u8"slow")), core::Float2{20.0f, 20.0f}));
    Activate(*bed.grid->GetRowMenu(), SV(u8"Paste"));
    CHECK(bed.bag.GetValue(SV(u8"slow"), 1).AsFloat() == doctest::Approx(2.5)); // into each object
    CHECK(commits == 1); // one undo entry

    // The keys on the focused row: Ctrl+C on the name, Ctrl+V on the speed, which refuses it.
    bed.grid->SetSelectedItem(bed.grid->FindRow(SV(u8"name")));
    bed.grid->RequestFocus();
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::C), KeyModCtrl);
    CHECK(clipboard.GetText() == core::String(u8"Lamp"));
    bed.grid->SetSelectedItem(bed.grid->FindRow(SV(u8"speed")));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::V), KeyModCtrl);
    CHECK(bed.bag.GetValue(SV(u8"speed"), 0).AsFloat() == doctest::Approx(2.5));
    CHECK(said == core::String(u8"\"Lamp\" is no number"));
    CHECK(commits == 1);
}
