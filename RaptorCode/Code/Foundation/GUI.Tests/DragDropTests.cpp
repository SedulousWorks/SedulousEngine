// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - drag and drop (E7): a press past the threshold offers the drag up from the pressed node,
// a node owning its press ending the walk; every move, modifier change and requery asks the node
// under the pointer and up its ancestors what a drop would do (an effect, a reason, a place); the
// cursor, the preview and a hint show it; a release drops, Escape, a right press or the source
// leaving cancels; the source is told how it ended; a finger drags after a long press; a source
// may follow the drag itself, with no preview. Across roots of one GUI (D6), where a host tells where
// they are: a drag goes on over another root, its targets asked there, and one let go over none ends
// outside, where on the screen said; a root gone mid-drag is forgotten.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    // A box at a place of its own in the root.
    core::RefPtr<Panel> Box(SceneRoot& root, float x, float y, float w, float h)
    {
        auto box = core::MakeRef<Panel>(core::DefaultAllocator());
        box->EditLayoutStyle([=](LayoutStyle& s)
        {
            s.Placement = Position::Absolute;
            s.Left = LayoutLength::Px(x);
            s.Top = LayoutLength::Px(y);
            s.Width = LayoutLength::Px(w);
            s.Height = LayoutLength::Px(h);
        });
        root.AddChild(box.Get());
        return box;
    }

    struct Scene
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Panel> source;
        core::RefPtr<Panel> target;
        DragResult ended;
        int ends = 0;

        Scene()
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            source = Box(*root, 10.0f, 10.0f, 80.0f, 40.0f);
            target = Box(*root, 200.0f, 10.0f, 100.0f, 100.0f);
            source->SetDragSource([](DragRequest& r)
            {
                r.Payload.Type = core::String(u8"card");
                r.Payload.Value = core::Variant::From<core::String>(core::String(u8"ace"));
                r.Payload.Label = core::String(u8"Ace of spades");
                return true;
            });
            source->SetOnDragEnd([this](const DragResult& r)
            {
                ended = r;
                ++ends;
            });
            (void)root->UpdateLayout();
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        // Presses the source and moves `to`, in steps.
        void DragTo(core::Float2 to, core::u32 modifiers = 0)
        {
            D().InjectMouseDown(core::Float2{30.0f, 30.0f}, MouseButton::Left);
            D().InjectMouseMove(core::Float2{40.0f, 30.0f}, modifiers);
            D().InjectMouseMove(to, modifiers);
        }
    };
}

TEST_CASE("dnd: a drag resting a moment opens a closed tree node and selects a tab")
{
    TreeModel model; // outlives the scene, whose tree is its client
    Scene s;
    const core::i32 a = model.AddNode(TreeModel::kRoot, core::StringView(u8"A"));
    (void)model.AddNode(a, core::StringView(u8"A1"));
    auto tree = core::MakeRef<TreeView>(core::DefaultAllocator());
    tree->EditLayoutStyle([](LayoutStyle& st)
    {
        st.Placement = Position::Absolute;
        st.Left = LayoutLength::Px(200.0f);
        st.Top = LayoutLength::Px(150.0f);
        st.Width = LayoutLength::Px(150.0f);
        st.Height = LayoutLength::Px(100.0f);
    });
    tree->SetRowHeight(20.0f);
    s.root->AddChild(tree.Get());
    tree->SetModel(&model);
    (void)s.root->UpdateLayout();

    s.DragTo(core::Float2{260.0f, 160.0f}); // over row 0, A (closed)
    s.D().Tick(0.3f);
    CHECK_FALSE(tree->IsItemExpanded(0));
    s.D().Tick(0.4f);
    CHECK(tree->IsItemExpanded(0));
    s.D().CancelDrag();
    s.D().InjectMouseUp(core::Float2{260.0f, 160.0f}, MouseButton::Left);

    auto bar = core::MakeRef<TabBar>(core::DefaultAllocator());
    bar->EditLayoutStyle([](LayoutStyle& st)
    {
        st.Placement = Position::Absolute;
        st.Left = LayoutLength::Px(10.0f);
        st.Top = LayoutLength::Px(250.0f);
    });
    s.root->AddChild(bar.Get());
    const char8_t* const names[] = {u8"One", u8"Two"};
    for (const char8_t* name : names)
        bar->AddTab(core::StringView(name))->EditLayoutStyle([](LayoutStyle& st)
        {
            st.Width = LayoutLength::Px(60.0f);
            st.Height = LayoutLength::Px(24.0f);
        });
    (void)s.root->UpdateLayout();
    const Rect two = bar->GetTab(1)->GetScreenBounds();
    s.DragTo(core::Float2{two.x + 20.0f, two.y + 10.0f});
    s.D().Tick(0.7f);
    CHECK(bar->GetSelectedIndex() == 1);
    s.D().CancelDrag();
    s.D().InjectMouseUp(core::Float2{two.x + 20.0f, two.y + 10.0f}, MouseButton::Left);
}

TEST_CASE("dnd: a drag resting on a closed expander's header opens it")
{
    Scene s;
    auto expander = core::MakeRef<Expander>(core::DefaultAllocator());
    expander->SetTitle(core::StringView(u8"More"));
    expander->EditLayoutStyle([](LayoutStyle& st)
    {
        st.Placement = Position::Absolute;
        st.Left = LayoutLength::Px(10.0f);
        st.Top = LayoutLength::Px(150.0f);
        st.Width = LayoutLength::Px(150.0f);
    });
    s.root->AddChild(expander.Get());
    (void)s.root->UpdateLayout();
    const Rect header = expander->GetHeader()->GetScreenBounds();
    s.DragTo(core::Float2{header.x + 40.0f, header.y + header.height * 0.5f});
    s.D().Tick(0.7f);
    CHECK(expander->IsOpen());
    s.D().CancelDrag();
    s.D().InjectMouseUp(core::Float2{header.x + 40.0f, header.y + 5.0f}, MouseButton::Left);
}

namespace
{

    struct Lists
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        StringListModel left;
        StringListModel right;
        core::RefPtr<ListView> a;
        core::RefPtr<ListView> b;

        Lists()
        {
            root->SetSize(core::Float2{500.0f, 300.0f});
            const char8_t* letters[5] = {u8"A", u8"B", u8"C", u8"D", u8"E"};
            for (const char8_t* l : letters)
                left.AddItem(core::StringView(l));
            right.AddItem(core::StringView(u8"X"));
            a = View(10.0f, left);
            b = View(250.0f, right);
            (void)root->UpdateLayout();
        }
        core::RefPtr<ListView> View(float x, StringListModel& model)
        {
            auto view = core::MakeRef<ListView>(core::DefaultAllocator());
            view->EditLayoutStyle([x](LayoutStyle& st)
            {
                st.Placement = Position::Absolute;
                st.Left = LayoutLength::Px(x);
                st.Top = LayoutLength::Px(10.0f);
                st.Width = LayoutLength::Px(200.0f);
                st.Height = LayoutLength::Px(200.0f);
            });
            view->SetRowHeight(20.0f);
            view->SetDragType(core::String(u8"row"));
            root->AddChild(view.Get());
            view->SetModel(&model);
            return view;
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        // A row's centre (y of row `item` in view `v`), and a point `frac` down it.
        static core::Float2 Row(ListView& v, int item, float frac = 0.5f)
        {
            const Rect r = v.GetScreenBounds();
            return core::Float2{r.x + 50.0f, r.y + 20.0f * (static_cast<float>(item) + frac)};
        }
        void Drag(ListView& from, int item, core::Float2 to, core::u32 modifiers = 0)
        {
            const core::Float2 at = Row(from, item);
            D().InjectMouseDown(at, MouseButton::Left, modifiers);
            D().InjectMouseMove(core::Float2{at.x + 10.0f, at.y}, modifiers);
            D().InjectMouseMove(to, modifiers);
        }
        static core::String Items(const StringListModel& m)
        {
            core::String text;
            for (core::usize i = 0; i < m.RowCount(); ++i)
                text.Append(m.ItemAt(i));
            return text;
        }
    };
}

TEST_CASE("dnd: a list's rows drag; a drop between rows reorders them, the line showing where")
{
    Lists l;
    l.Drag(*l.a, 0, Lists::Row(*l.a, 2, 0.9f)); // A, past C's middle: after C
    CHECK(l.D().GetDropTarget() == l.a.Get());
    CHECK(l.a->IsDropOver());
    CHECK(l.a->GetDropItem() == 2);
    CHECK(l.a->GetDropPlace() == DropPlace::After);
    CHECK(l.D().GetDragPayload().Label == core::StringView(u8"A"));
    // The middle of a row: a list takes nothing onto a row, so the halves decide.
    l.D().InjectMouseMove(Lists::Row(*l.a, 3, 0.4f));
    CHECK(l.a->GetDropItem() == 3);
    CHECK(l.a->GetDropPlace() == DropPlace::Before);
    l.D().InjectMouseUp(Lists::Row(*l.a, 3, 0.4f), MouseButton::Left);
    CHECK(Lists::Items(l.left) == core::StringView(u8"BCADE"));
    CHECK_FALSE(l.a->IsDropOver());
    CHECK(l.a->GetSelectedItem() == 2); // the moved row keeps its id, and its selection
}

TEST_CASE("dnd: a multi-selection drags as one, in order; a plain press on it alone selects it on the click")
{
    Lists l;
    l.a->SetSelectionMode(SelectionMode::Multi);
    l.D().InjectMouseDown(Lists::Row(*l.a, 0), MouseButton::Left);
    l.D().InjectMouseUp(Lists::Row(*l.a, 0), MouseButton::Left);
    l.D().InjectMouseDown(Lists::Row(*l.a, 2), MouseButton::Left, KeyModCtrl);
    l.D().InjectMouseUp(Lists::Row(*l.a, 2), MouseButton::Left, KeyModCtrl);
    CHECK(l.a->GetSelectionCount() == 2);
    l.Drag(*l.a, 2, Lists::Row(*l.a, 4, 0.9f)); // A and C, after E
    CHECK(l.a->GetSelectionCount() == 2); // the press kept them
    CHECK(l.D().GetDragPayload().Label == core::StringView(u8"2 items"));
    l.D().InjectMouseUp(Lists::Row(*l.a, 4, 0.9f), MouseButton::Left);
    CHECK(Lists::Items(l.left) == core::StringView(u8"BDEAC"));

    // A plain click on one of a multi-selection: that row alone.
    l.D().InjectMouseDown(Lists::Row(*l.a, 3), MouseButton::Left);
    l.D().InjectMouseUp(Lists::Row(*l.a, 3), MouseButton::Left);
    CHECK(l.a->GetSelectionCount() == 1);
    CHECK(l.a->GetSelectedItem() == 3);
}

TEST_CASE("dnd: rows moved to another list leave the source; copied (Ctrl) they stay")
{
    Lists l;
    l.Drag(*l.a, 1, Lists::Row(*l.b, 0, 0.9f)); // B after X
    CHECK(l.D().GetDropTarget() == l.b.Get());
    CHECK(l.D().GetDropEffect() == DropEffect::Move);
    l.D().InjectMouseUp(Lists::Row(*l.b, 0, 0.9f), MouseButton::Left);
    CHECK(Lists::Items(l.right) == core::StringView(u8"XB"));
    CHECK(Lists::Items(l.left) == core::StringView(u8"ACDE"));

    l.Drag(*l.a, 0, Lists::Row(*l.b, 0, 0.1f), KeyModCtrl); // A before X, copied
    CHECK(l.D().GetDropEffect() == DropEffect::Copy);
    l.D().InjectMouseUp(Lists::Row(*l.b, 0, 0.1f), MouseButton::Left, KeyModCtrl); // released with Ctrl held
    CHECK(Lists::Items(l.right) == core::StringView(u8"AXB"));
    CHECK(Lists::Items(l.left) == core::StringView(u8"ACDE"));

    // Below the last row: the end.
    l.Drag(*l.a, 3, core::Float2{300.0f, 180.0f});
    CHECK(l.b->GetDropItem() == -1);
    l.D().InjectMouseUp(core::Float2{300.0f, 180.0f}, MouseButton::Left);
    CHECK(Lists::Items(l.right) == core::StringView(u8"AXBE"));
}

TEST_CASE("dnd: a tree takes a node onto another (its child) or beside it, and refuses one inside itself")
{
    TreeModel model;
    const core::i32 a = model.AddNode(TreeModel::kRoot, core::StringView(u8"A"));
    const core::i32 a1 = model.AddNode(a, core::StringView(u8"A1"));
    const core::i32 b = model.AddNode(TreeModel::kRoot, core::StringView(u8"B"));
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 300.0f});
    auto tree = core::MakeRef<TreeView>(core::DefaultAllocator());
    tree->SetSize(core::Float2{300.0f, 200.0f});
    tree->SetRowHeight(20.0f);
    tree->SetDragType(core::String(u8"node"));
    root->AddChild(tree.Get());
    tree->SetModel(&model);
    tree->ExpandItem(0); // A, A1, B
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    const auto row = [](int item, float frac) { return core::Float2{100.0f, 20.0f * (static_cast<float>(item) + frac)}; };

    // A onto A1 (its own child): refused, with the reason.
    d.InjectMouseDown(row(0, 0.5f), MouseButton::Left);
    d.InjectMouseMove(row(0, 0.8f));
    d.InjectMouseMove(row(1, 0.5f));
    CHECK(d.GetDropTarget() == nullptr);
    CHECK(d.GetDropReason() == core::StringView(u8"A node cannot go inside itself"));
    d.CancelDrag();
    d.InjectMouseUp(row(1, 0.5f), MouseButton::Left);

    // B onto A: B becomes A's last child.
    d.InjectMouseDown(row(2, 0.5f), MouseButton::Left);
    d.InjectMouseMove(row(2, 0.2f));
    d.InjectMouseMove(row(0, 0.5f));
    CHECK(tree->GetDropPlace() == DropPlace::On);
    d.InjectMouseUp(row(0, 0.5f), MouseButton::Left);
    CHECK(model.RowCount() == 1); // A alone at the top
    CHECK(model.RowCount(model.IndexOfNode(a)) == 2);
    CHECK(model.IdOf(model.Index(1, 0, model.IndexOfNode(a))) == static_cast<ItemId>(b));

    // A1 before A: back to the top level, first.
    (void)root->UpdateLayout();
    d.InjectMouseDown(row(1, 0.5f), MouseButton::Left);
    d.InjectMouseMove(row(1, 0.8f));
    d.InjectMouseMove(row(0, 0.1f));
    CHECK(tree->GetDropPlace() == DropPlace::Before);
    d.InjectMouseUp(row(0, 0.1f), MouseButton::Left);
    CHECK(model.RowCount() == 2);
    CHECK(model.IdOf(model.Index(0)) == static_cast<ItemId>(a1));
}

TEST_CASE("dnd: from the keys a list's rows move: the arrows move the keyboard's row, not the selection")
{
    Lists l;
    l.a->RequestFocus();
    l.a->SetSelectedItem(0); // A
    CHECK(l.D().PickDrag());
    CHECK(l.D().GetDragPayload().Label == core::StringView(u8"A"));
    l.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Down));
    l.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Down)); // the keyboard on C
    CHECK(l.a->GetSelectedItem() == -1); // the keyboard moved; A stays selected, not current
    CHECK(l.a->IsItemSelected(0));
    CHECK(l.a->GetDropItem() == 2);
    CHECK(l.a->GetDropPlace() == DropPlace::After); // a list takes nothing onto a row
    l.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK(Lists::Items(l.left) == core::StringView(u8"BCADE"));
}

TEST_CASE("dnd: in markup, drag-type, drag-value and drag-label make a source; drop-types and drop-reason a target")
{
    RegisterGuiElements();
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 300.0f});
    MarkupLoader loader(*root->GetElementSet(), core::DefaultAllocator());
    auto page = loader.LoadFromString(core::StringView(u8R"(<Panel width="400" height="300" flex-direction="row" align-items="start">
        <Panel id="swatch" width="80" height="40" drag-type="color" drag-value="red" drag-label="Red">
            <Label id="grip" text="grip" width="30" height="20" drag="block"/>
            <Label id="quiet" text="quiet" width="30" height="20" drag="none" drag-type="other"/>
        </Panel>
        <Panel id="canvas" width="200" height="200" drop-types="color" drop-reason="Paint it"/>
    </Panel>)"));
    REQUIRE(page.Get() != nullptr);
    root->AddChild(page.Get());
    (void)root->UpdateLayout();
    Node* swatch = page->GetChildAt(0);
    Node* canvas = page->GetChildAt(1);
    Node* grip = swatch->GetChildAt(0);
    Node* quiet = swatch->GetChildAt(1);
    core::String painted;
    (void)canvas->AddEventListener(EventType::Drop, [&](const Event& e)
    {
        const core::String* v = static_cast<const DragEvent&>(e).Payload.Value.TryGet<core::String>();
        painted = v != nullptr ? *v : core::String{};
    });
    EventDispatcher& d = *root->GetEventDispatcher();
    const auto drag = [&](Node& from, core::Float2 to)
    {
        const Rect r = from.GetScreenBounds();
        const core::Float2 at{r.x + 5.0f, r.y + 5.0f};
        d.InjectMouseDown(at, MouseButton::Left);
        d.InjectMouseMove(core::Float2{at.x + 10.0f, at.y});
        d.InjectMouseMove(to);
    };
    const Rect c = canvas->GetScreenBounds();
    const core::Float2 onCanvas{c.x + 50.0f, c.y + 50.0f};

    // A press on the block child: the walk ends there, nothing drags.
    drag(*grip, onCanvas);
    CHECK_FALSE(d.IsDragging());
    d.InjectMouseUp(onCanvas, MouseButton::Left);
    // A press on the none child (with a type of its own): it passes the press up to the swatch.
    drag(*quiet, onCanvas);
    REQUIRE(d.IsDragging());
    CHECK(d.GetDragPayload().Type == core::StringView(u8"color"));
    CHECK(d.GetDragPayload().Label == core::StringView(u8"Red"));
    CHECK(d.GetDropTarget() == canvas);
    CHECK(d.GetDropReason() == core::StringView(u8"Paint it"));
    d.InjectMouseUp(onCanvas, MouseButton::Left);
    CHECK(painted == core::StringView(u8"red"));
}

namespace
{
    // Two roots of one GUI side by side on a screen: the scene's at 0,0 (400 by 300) and another at
    // 500,0 (300 by 300), as a host that places its windows would tell.
    struct TwoPlaces final : IRootPlaces
    {
        EventDispatcher* first = nullptr;
        EventDispatcher* second = nullptr;
        EventDispatcher* DispatcherAt(core::Float2 screen, core::Float2& local) override
        {
            if (screen.y < 0.0f || screen.y >= 300.0f)
                return nullptr;
            if (screen.x >= 0.0f && screen.x < 400.0f)
            {
                local = screen;
                return first;
            }
            if (second != nullptr && screen.x >= 500.0f && screen.x < 800.0f)
            {
                local = core::Float2{screen.x - 500.0f, screen.y};
                return second;
            }
            return nullptr;
        }
        bool ToScreen(const EventDispatcher& d, core::Float2 local, core::Float2& screen) override
        {
            if (&d == first)
                screen = local;
            else if (second != nullptr && &d == second)
                screen = core::Float2{local.x + 500.0f, local.y};
            else
                return false;
            return true;
        }
    };
}
