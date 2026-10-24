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

TEST_CASE("dnd: a press starts a drag only past the threshold, and the press is cancelled (no click)")
{
    Scene s;
    int clicks = 0;
    (void)s.source->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });
    bool started = false;
    (void)s.source->AddEventListener(EventType::DragStart, [&](const Event&) { started = true; });
    s.D().InjectMouseDown(core::Float2{30.0f, 30.0f}, MouseButton::Left);
    s.D().InjectMouseMove(core::Float2{33.0f, 31.0f}); // 4 px: short of the 6
    CHECK_FALSE(s.D().IsDragging());
    s.D().InjectMouseMove(core::Float2{38.0f, 31.0f});
    CHECK(s.D().IsDragging());
    CHECK(started);
    CHECK(s.D().GetDragSource() == s.source.Get());
    CHECK(s.source->IsDragSource()); // `:drag-source`
    CHECK(s.D().GetDragPayload().Type == core::StringView(u8"card"));
    s.D().InjectMouseUp(core::Float2{38.0f, 31.0f}, MouseButton::Left);
    CHECK_FALSE(s.D().IsDragging());
    CHECK(clicks == 0);
    CHECK(s.ends == 1);
    CHECK(s.ended.Effect == DropEffect::None); // dropped where nothing takes it
    CHECK_FALSE(s.source->IsDragSource());

    // A press too short to drag still clicks.
    s.D().InjectMouseDown(core::Float2{30.0f, 30.0f}, MouseButton::Left);
    s.D().InjectMouseUp(core::Float2{31.0f, 30.0f}, MouseButton::Left);
    CHECK(clicks == 1);
}

TEST_CASE("dnd: the drag is offered up from the pressed node; one owning its press ends the walk")
{
    Scene s;
    // A plain child of the source: the source above it gives the drag.
    auto child = core::MakeRef<Panel>(core::DefaultAllocator());
    child->EditLayoutStyle([](LayoutStyle& st)
    {
        st.Width = LayoutLength::Px(20.0f);
        st.Height = LayoutLength::Px(20.0f);
    });
    s.source->AddChild(child.Get());
    (void)s.root->UpdateLayout();
    const Rect c = child->GetScreenBounds();
    const core::Float2 at{c.x + 5.0f, c.y + 5.0f};
    s.D().InjectMouseDown(at, MouseButton::Left);
    s.D().InjectMouseMove(core::Float2{at.x + 20.0f, at.y});
    CHECK(s.D().IsDragging());
    CHECK(s.D().GetDragSource() == s.source.Get());
    s.D().CancelDrag();
    s.D().InjectMouseUp(at, MouseButton::Left);

    // A slider inside the source owns its press: no drag, the slider moves instead.
    child->RemoveFromParent();
    auto slider = core::MakeRef<Slider>(core::DefaultAllocator());
    slider->EditLayoutStyle([](LayoutStyle& st)
    {
        st.Width = LayoutLength::Px(70.0f);
        st.Height = LayoutLength::Px(20.0f);
    });
    s.source->AddChild(slider.Get());
    (void)s.root->UpdateLayout();
    const Rect sl = slider->GetScreenBounds();
    s.D().InjectMouseDown(core::Float2{sl.x + 10.0f, sl.y + 10.0f}, MouseButton::Left);
    s.D().InjectMouseMove(core::Float2{sl.x + 50.0f, sl.y + 10.0f});
    CHECK_FALSE(s.D().IsDragging());
    CHECK(slider->GetValue() > 0.0);
    s.D().InjectMouseUp(core::Float2{sl.x + 50.0f, sl.y + 10.0f}, MouseButton::Left);
}

TEST_CASE("dnd: each move asks the node under the pointer and up its ancestors; the first that takes it is the target")
{
    Scene s;
    auto inner = Box(*s.root, 220.0f, 30.0f, 40.0f, 40.0f); // over the target, not its child
    s.root->RemoveChild(inner.Get());
    s.target->AddChild(inner.Get());
    (void)s.root->UpdateLayout();
    s.target->SetDropTypes(core::String(u8"card chip"));
    int enters = 0, leaves = 0, overs = 0;
    (void)s.target->AddEventListener(EventType::DragEnter, [&](const Event&) { ++enters; });
    (void)s.target->AddEventListener(EventType::DragLeave, [&](const Event&) { ++leaves; });
    (void)s.target->AddEventListener(EventType::DragOver, [&](const Event&) { ++overs; });

    s.DragTo(core::Float2{100.0f, 200.0f}); // over nothing that takes it
    CHECK(s.D().GetDropTarget() == nullptr);
    CHECK(s.D().GetDropEffect() == DropEffect::None);
    CHECK(s.D().GetCursor() == Cursor::NoDrop);

    // Over the inner box, inside the target: the target (its ancestor) takes it.
    const Rect in = inner->GetScreenBounds();
    s.D().InjectMouseMove(core::Float2{in.x + 10.0f, in.y + 10.0f});
    CHECK(s.D().GetDropTarget() == s.target.Get());
    CHECK(s.target->IsDropTarget()); // `:drop-target`
    CHECK(enters == 1);
    CHECK(overs == 1);
    CHECK(s.D().GetDropEffect() == DropEffect::Move);
    CHECK(s.D().GetCursor() == Cursor::Move);
    s.D().InjectMouseMove(core::Float2{in.x + 12.0f, in.y + 10.0f});
    CHECK(overs == 2);
    CHECK(enters == 1);

    // Off it: left.
    s.D().InjectMouseMove(core::Float2{100.0f, 200.0f});
    CHECK(leaves == 1);
    CHECK_FALSE(s.target->IsDropTarget());
    s.D().InjectMouseUp(core::Float2{100.0f, 200.0f}, MouseButton::Left);
}

TEST_CASE("dnd: the modifiers choose the effect among those the source allows, asked again as they change")
{
    Scene s;
    s.target->SetDropTypes(core::String(u8"card"));
    s.DragTo(core::Float2{250.0f, 50.0f});
    CHECK(s.D().GetDropEffect() == DropEffect::Move);
    s.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Unknown), KeyModCtrl); // Ctrl held
    CHECK(s.D().GetDropEffect() == DropEffect::Copy);
    CHECK(s.D().GetCursor() == Cursor::Copy);
    s.D().InjectMouseMove(core::Float2{252.0f, 50.0f}, KeyModCtrl | KeyModShift);
    CHECK(s.D().GetDropEffect() == DropEffect::Link);
    CHECK(s.D().GetCursor() == Cursor::Alias);
    s.D().InjectKeyUp(static_cast<core::u32>(KeyCode::Unknown), 0);
    CHECK(s.D().GetDropEffect() == DropEffect::Move);
    s.D().CancelDrag();
    s.D().InjectMouseUp(core::Float2{252.0f, 50.0f}, MouseButton::Left);

    // A source allowing copy alone: Shift asks for a move, gets a copy.
    s.source->SetDragSource([](DragRequest& r)
    {
        r.Payload.Type = core::String(u8"card");
        r.Payload.Allowed = DropEffectsCopy;
        return true;
    });
    s.DragTo(core::Float2{250.0f, 50.0f}, KeyModShift);
    CHECK(s.D().GetDropEffect() == DropEffect::Copy);
    s.D().CancelDrag();
    s.D().InjectMouseUp(core::Float2{250.0f, 50.0f}, MouseButton::Left);
}

TEST_CASE("dnd: a target says what a drop would do, or refuses with a reason that ends the walk; the hint shows it")
{
    Scene s;
    s.target->SetDropTypes(core::String(u8"card")); // would take it, but a child refuses first
    auto picky = Box(*s.root, 0.0f, 0.0f, 50.0f, 50.0f);
    s.root->RemoveChild(picky.Get());
    s.target->AddChild(picky.Get());
    picky->SetOnDragQuery([](DropQuery& q)
    {
        if (q.Modifiers & KeyModShift)
            q.Refuse(u8"The discard pile takes no aces");
        else
        {
            q.Accept(DropEffect::Copy);
            q.Reason = core::String(u8"Copy to the discard pile");
            q.Place = 3;
        }
    });
    (void)s.root->UpdateLayout();
    const Rect p = picky->GetScreenBounds();
    s.DragTo(core::Float2{p.x + 10.0f, p.y + 10.0f});
    CHECK(s.D().GetDropTarget() == picky.Get());
    CHECK(s.D().GetDropEffect() == DropEffect::Copy);
    CHECK(s.D().GetDropReason() == core::StringView(u8"Copy to the discard pile"));
    REQUIRE(s.D().GetDropHint() != nullptr);
    CHECK_FALSE(core::Cast<UIWidget>(s.D().GetDropHint())->HasClass(core::StringView(u8"refused")));

    s.D().InjectMouseMove(core::Float2{p.x + 11.0f, p.y + 10.0f}, KeyModShift);
    CHECK(s.D().GetDropTarget() == nullptr); // refused: not passed on to the target above
    CHECK(s.D().GetDropEffect() == DropEffect::None);
    CHECK(s.D().GetDropReason() == core::StringView(u8"The discard pile takes no aces"));
    REQUIRE(s.D().GetDropHint() != nullptr);
    CHECK(core::Cast<UIWidget>(s.D().GetDropHint())->HasClass(core::StringView(u8"refused")));

    // Dropped with the place the target gave.
    core::i32 place = -1;
    DropEffect effect = DropEffect::None;
    (void)picky->AddEventListener(EventType::Drop, [&](const Event& e)
    {
        place = static_cast<const DragEvent&>(e).Place;
        effect = static_cast<const DragEvent&>(e).Effect;
    });
    s.D().InjectMouseMove(core::Float2{p.x + 12.0f, p.y + 10.0f}, 0);
    s.D().InjectMouseUp(core::Float2{p.x + 12.0f, p.y + 10.0f}, MouseButton::Left);
    CHECK(place == 3);
    CHECK(effect == DropEffect::Copy);
    CHECK(s.ended.Effect == DropEffect::Copy); // the source told
    CHECK(s.ended.Target == picky.Get());
    CHECK_FALSE(s.ended.Cancelled);
    CHECK(s.D().GetDropHint() == nullptr);
}

TEST_CASE("dnd: the preview follows the pointer, held where the press was, and shows the effect")
{
    Scene s;
    s.target->SetDropTypes(core::String(u8"card"));
    s.DragTo(core::Float2{120.0f, 150.0f});
    auto* preview = core::Cast<DragPreview>(s.D().GetDragPreview());
    REQUIRE(preview != nullptr);
    CHECK(preview->GetText() == core::StringView(u8"Ace of spades"));
    CHECK(preview->GetEffect() == DropEffect::None);
    (void)s.root->UpdateLayout();
    CHECK(preview->GetScreenBounds().x == doctest::Approx(120.0f + 14.0f)); // beside the pointer
    s.D().InjectMouseMove(core::Float2{250.0f, 50.0f});
    CHECK(preview->GetEffect() == DropEffect::Move);
    // It takes no hits: the target under it is still what is asked.
    CHECK(s.D().GetDropTarget() == s.target.Get());
    s.D().CancelDrag();
    s.D().InjectMouseUp(core::Float2{250.0f, 50.0f}, MouseButton::Left);
    CHECK(s.D().GetDragPreview() == nullptr);

    // A preview of the source's own keeps the grab point.
    s.source->SetDragSource([](DragRequest& r)
    {
        r.Payload.Type = core::String(u8"card");
        auto own = core::MakeRef<Panel>(core::DefaultAllocator());
        own->EditLayoutStyle([](LayoutStyle& st)
        {
            st.Width = LayoutLength::Px(80.0f);
            st.Height = LayoutLength::Px(40.0f);
        });
        r.Preview = own;
        return true;
    });
    s.DragTo(core::Float2{150.0f, 150.0f});
    (void)s.root->UpdateLayout();
    // Pressed at (30, 30), 20 in from the source's corner (10, 10): the preview's corner 20 back.
    CHECK(s.D().GetDragPreview()->GetScreenBounds().x == doctest::Approx(130.0f));
    CHECK(s.D().GetDragPreview()->GetScreenBounds().y == doctest::Approx(130.0f));
    s.D().CancelDrag();
    s.D().InjectMouseUp(core::Float2{150.0f, 150.0f}, MouseButton::Left);
}

TEST_CASE("dnd: a source that follows the drag itself has no preview; it moves first, and what it leaves is asked")
{
    Scene s;
    s.target->SetDropTypes(core::String(u8"card"));
    core::Array<core::Float2> followed;
    s.source->SetDragSource([&](DragRequest& r)
    {
        r.Payload.Type = core::String(u8"card");
        r.Follow = [&](core::Float2 at)
        {
            followed.PushBack(at);
            s.source->SetHitTestVisible(false); // what a following source does: the drop is asked of what is below
            s.source->SetPosition(core::Float2{at.x - 20.0f, at.y - 20.0f}); // the source under the pointer
        };
        return true;
    });
    s.DragTo(core::Float2{250.0f, 50.0f});
    REQUIRE(s.D().IsDragging());
    CHECK(s.D().GetDragPreview() == nullptr);
    REQUIRE(followed.Size() >= 2u);
    CHECK(followed.Back().x == doctest::Approx(250.0f));
    CHECK(s.source->GetPosition().x == doctest::Approx(230.0f));
    CHECK(s.D().GetDropTarget() == s.target.Get()); // under the source, the target answered
    s.D().InjectMouseUp(core::Float2{250.0f, 50.0f}, MouseButton::Left);
    CHECK_FALSE(s.D().IsDragging());
    const core::usize calls = followed.Size();
    s.D().InjectMouseMove(core::Float2{260.0f, 50.0f}); // over: no more calls
    CHECK(followed.Size() == calls);
}

TEST_CASE("dnd: Escape, a right press and the source leaving the tree cancel; the source hears it cancelled")
{
    Scene s;
    s.target->SetDropTypes(core::String(u8"card"));
    s.DragTo(core::Float2{250.0f, 50.0f});
    s.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(s.D().IsDragging());
    CHECK(s.ended.Cancelled);
    CHECK(s.ended.Effect == DropEffect::None);
    CHECK_FALSE(s.target->IsDropTarget());
    int drops = 0;
    (void)s.target->AddEventListener(EventType::Drop, [&](const Event&) { ++drops; });
    s.D().InjectMouseUp(core::Float2{250.0f, 50.0f}, MouseButton::Left);
    CHECK(drops == 0); // the release after a cancel drops nothing

    s.DragTo(core::Float2{250.0f, 50.0f});
    s.D().InjectMouseDown(core::Float2{250.0f, 50.0f}, MouseButton::Right);
    CHECK_FALSE(s.D().IsDragging());
    CHECK(s.ends == 2);
    s.D().InjectMouseUp(core::Float2{250.0f, 50.0f}, MouseButton::Right);
    s.D().InjectMouseUp(core::Float2{250.0f, 50.0f}, MouseButton::Left);
    CHECK(drops == 0);

    s.DragTo(core::Float2{250.0f, 50.0f});
    s.source->RemoveFromParent();
    CHECK_FALSE(s.D().IsDragging());
    CHECK(s.ends == 2); // a source gone hears nothing
}

TEST_CASE("dnd: a finger drags after a long press over a source, and opens no context menu")
{
    Scene s;
    s.target->SetDropTypes(core::String(u8"card"));
    int menus = 0;
    (void)s.source->AddEventListener(EventType::ContextMenu, [&](const Event&) { ++menus; });
    // A quick move is no drag (a finger's move pans first).
    s.D().InjectTouchDown(1, core::Float2{30.0f, 30.0f});
    s.D().InjectTouchMove(1, core::Float2{50.0f, 30.0f});
    CHECK_FALSE(s.D().IsDragging());
    s.D().InjectTouchUp(1, core::Float2{50.0f, 30.0f});

    s.D().InjectTouchDown(1, core::Float2{30.0f, 30.0f});
    s.D().Tick(0.6f); // held still
    CHECK(menus == 0);
    s.D().InjectTouchMove(1, core::Float2{60.0f, 30.0f});
    CHECK(s.D().IsDragging());
    s.D().InjectTouchMove(1, core::Float2{250.0f, 50.0f});
    CHECK(s.D().GetDropTarget() == s.target.Get());
    s.D().InjectTouchUp(1, core::Float2{250.0f, 50.0f});
    CHECK(s.ended.Effect == DropEffect::Move);
}

TEST_CASE("dnd: code can start a drag (no press of its own), and RequeryDrag asks again")
{
    Scene s;
    bool open = false;
    s.target->SetOnDragQuery([&](DropQuery& q)
    {
        if (open)
            q.Accept();
    });
    s.D().InjectMouseMove(core::Float2{250.0f, 50.0f});
    DragRequest request;
    request.Payload.Type = core::String(u8"card");
    s.D().StartDrag(*s.source, core::Move(request));
    CHECK(s.D().IsDragging());
    CHECK(s.D().GetDropTarget() == nullptr);
    open = true; // what is under the pointer changed with the pointer still
    s.D().RequeryDrag();
    CHECK(s.D().GetDropTarget() == s.target.Get());
    s.D().InjectMouseUp(core::Float2{250.0f, 50.0f}, MouseButton::Left);
    CHECK(s.ended.Effect == DropEffect::Move);
}

TEST_CASE("dnd: a drag near a scroller's edge scrolls it, faster deeper in, and asks the drop again")
{
    Scene s;
    auto list = Box(*s.root, 200.0f, 120.0f, 150.0f, 100.0f);
    list->EditLayoutStyle([](LayoutStyle& st) { st.OverflowY = Overflow::Auto; });
    for (int i = 0; i < 20; ++i)
    {
        auto row = core::MakeRef<Panel>(core::DefaultAllocator());
        row->EditLayoutStyle([](LayoutStyle& st)
        {
            st.Height = LayoutLength::Px(30.0f);
            st.Shrink = 0.0f;
        });
        list->AddChild(row.Get());
    }
    int queries = 0;
    list->SetOnDragQuery([&](DropQuery& q)
    {
        ++queries;
        q.Accept();
    });
    (void)s.root->UpdateLayout();
    s.DragTo(core::Float2{270.0f, 170.0f}); // the middle: no scroll
    s.D().Tick(0.1f);
    CHECK(list->GetScrollOffset().y == doctest::Approx(0.0f));
    const int before = queries;
    s.D().InjectMouseMove(core::Float2{270.0f, 210.0f}); // 10 into the bottom band of 24
    s.D().Tick(0.1f);
    const float slow = list->GetScrollOffset().y;
    CHECK(slow > 0.0f);
    CHECK(queries > before + 1); // asked again as the content moved
    s.D().InjectMouseMove(core::Float2{270.0f, 219.0f}); // at the edge
    s.D().Tick(0.1f);
    CHECK(list->GetScrollOffset().y - slow > slow);
    s.D().CancelDrag();
    s.D().InjectMouseUp(core::Float2{270.0f, 219.0f}, MouseButton::Left);
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

TEST_CASE("dnd: files the OS drops go through the same path, as a copy of their paths; none taking them, the GUI's handler has them")
{
    Scene s;
    s.target->SetDropTypes(core::String(u8"files"));
    core::Array<core::String> got;
    DropEffect effect = DropEffect::None;
    (void)s.target->AddEventListener(EventType::Drop, [&](const Event& e)
    {
        got = DroppedPaths(static_cast<const DragEvent&>(e).Payload);
        effect = static_cast<const DragEvent&>(e).Effect;
    });
    core::Array<core::String> leftover;
    s.D().SetOnFileDrop([&](const core::Array<core::String>& paths, core::Float2)
    {
        leftover = paths;
        return true;
    });
    core::Array<core::String> paths;
    paths.PushBack(core::String(u8"/tmp/a.png"));
    paths.PushBack(core::String(u8"/tmp/b.png"));
    CHECK(s.D().InjectFileDrop(core::Float2{250.0f, 50.0f}, paths));
    REQUIRE(got.Size() == 2);
    CHECK(got[1] == core::StringView(u8"/tmp/b.png"));
    CHECK(effect == DropEffect::Copy);
    CHECK_FALSE(s.D().IsDragging());
    CHECK(leftover.IsEmpty());

    CHECK(s.D().InjectFileDrop(core::Float2{100.0f, 250.0f}, paths)); // over nothing that takes files
    CHECK(leftover.Size() == 2);
    CHECK_FALSE(s.target->IsDropTarget());
}

TEST_CASE("dnd: from the keys, drag.pick picks up at the focus, the focus moving is asked, Return drops, Escape cancels")
{
    Scene s;
    s.source->SetTabFocusable(true);
    s.target->SetTabFocusable(true);
    s.target->SetDropTypes(core::String(u8"card"));
    s.source->RequestFocus();
    CHECK(s.D().PickDrag());
    CHECK(s.D().IsKeyboardDrag());
    CHECK(s.D().GetDropTarget() == nullptr); // the source itself takes no cards
    s.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Tab)); // the focus moves on
    CHECK(s.target->IsFocused());
    CHECK(s.D().GetDropTarget() == s.target.Get());
    REQUIRE(s.D().GetDragPreview() != nullptr);
    s.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK_FALSE(s.D().IsDragging());
    CHECK(s.ended.Effect == DropEffect::Move);
    CHECK(s.ended.Target == s.target.Get());

    // Ctrl+Shift+D (drag.pick in every GUI), then Escape.
    s.source->RequestFocus();
    s.D().InjectKeyDown(static_cast<core::u32>(KeyCode::D), KeyModCtrl | KeyModShift);
    CHECK(s.D().IsKeyboardDrag());
    s.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(s.D().IsDragging());
    CHECK(s.ended.Cancelled);

    // The pad: North picks up, South drops.
    s.source->RequestFocus();
    s.D().InjectPadButton(PadButton::North);
    CHECK(s.D().IsKeyboardDrag());
    s.target->RequestFocus();
    s.D().InjectPadButton(PadButton::South);
    CHECK_FALSE(s.D().IsDragging());
    CHECK(s.ended.Effect == DropEffect::Move);
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

TEST_CASE("dnd: a dragquery listener that takes the event takes the drop")
{
    Scene s;
    int asked = 0;
    (void)s.target->AddEventListener(EventType::DragQuery, [&](const Event& e)
    {
        ++asked;
        const auto& drag = static_cast<const DragEvent&>(e);
        if (drag.Payload.Type == core::StringView(u8"card"))
            e.Handled = true;
    });
    s.DragTo(core::Float2{250.0f, 50.0f});
    CHECK(asked >= 1);
    CHECK(s.D().GetDropTarget() == s.target.Get());
    s.D().InjectMouseUp(core::Float2{250.0f, 50.0f}, MouseButton::Left);
    CHECK(s.ended.Effect == DropEffect::Move);
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

TEST_CASE("dnd: across roots of one GUI, a drag goes on over another root; let go over none it ends outside, where said")
{
    Scene s;
    core::RefPtr<SceneRoot> other = core::MakeRef<SceneRoot>(core::DefaultAllocator(), s.root->GetContextRef());
    other->SetSize(core::Float2{300.0f, 300.0f});
    core::RefPtr<Panel> far = Box(*other, 50.0f, 20.0f, 100.0f, 100.0f);
    far->SetDropTypes(core::String(u8"card"));
    int enters = 0, drops = 0;
    (void)far->AddEventListener(EventType::DragEnter, [&](const Event&) { ++enters; });
    (void)far->AddEventListener(EventType::Drop, [&](const Event&) { ++drops; });
    (void)other->UpdateLayout();
    TwoPlaces places;
    places.first = &s.D();
    places.second = other->GetEventDispatcher();
    s.root->GetContext().SetRootPlaces(&places);
    CHECK(other->GetEventDispatcher() != nullptr);

    // Over the other root (its 100,50: the screen's 600,50, past this root's edge).
    s.DragTo(core::Float2{600.0f, 50.0f});
    REQUIRE(s.D().IsDragging());
    CHECK(s.D().GetDragOver() == other->GetEventDispatcher());
    CHECK(s.D().GetDropTarget() == far.Get());
    CHECK(enters == 1);
    s.D().InjectMouseUp(core::Float2{600.0f, 50.0f}, MouseButton::Left);
    CHECK(drops == 1);
    REQUIRE(s.ends == 1);
    CHECK(s.ended.Target == far.Get());
    CHECK_FALSE(s.ended.Outside);

    // Between the two: over no root, outside, at the screen's 450,50.
    s.DragTo(core::Float2{450.0f, 50.0f});
    CHECK(s.D().GetDragOver() == nullptr);
    CHECK(s.D().GetDropTarget() == nullptr);
    s.D().InjectMouseUp(core::Float2{450.0f, 50.0f}, MouseButton::Left);
    REQUIRE(s.ends == 2);
    CHECK(s.ended.Target == nullptr);
    CHECK(s.ended.Outside);
    CHECK(s.ended.ScreenKnown);
    CHECK(s.ended.Screen.x == doctest::Approx(450.0f));

    // The other root goes while the drag is over it: forgotten, and let go it is outside.
    s.DragTo(core::Float2{600.0f, 50.0f});
    REQUIRE(s.D().GetDropTarget() == far.Get());
    places.second = nullptr;
    far.Reset();
    other.Reset();
    CHECK(s.D().GetDropTarget() == nullptr);
    s.D().InjectMouseUp(core::Float2{600.0f, 50.0f}, MouseButton::Left);
    REQUIRE(s.ends == 3);
    CHECK(s.ended.Outside);
    s.root->GetContext().SetRootPlaces(nullptr);
}

TEST_CASE("dnd: where no host tells the roots' places, a drag let go past its root's edge ends outside, nowhere said")
{
    Scene s;
    s.DragTo(core::Float2{-30.0f, 20.0f});
    s.D().InjectMouseUp(core::Float2{-30.0f, 20.0f}, MouseButton::Left);
    REQUIRE(s.ends == 1);
    CHECK(s.ended.Outside);
    CHECK_FALSE(s.ended.ScreenKnown);
    // Let go over its own root where nothing takes it: not outside.
    s.DragTo(core::Float2{150.0f, 200.0f});
    s.D().InjectMouseUp(core::Float2{150.0f, 200.0f}, MouseButton::Left);
    REQUIRE(s.ends == 2);
    CHECK_FALSE(s.ended.Outside);
}
