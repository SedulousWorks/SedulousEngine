// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The popup stack, a top layer on the retained tree (E5 of Specs/gui-lab-evolution.md): a popup
// stays in its owner's subtree yet draws and takes the pointer above everything, unclipped; nesting
// comes from the tree; a press that closes an auto popup is consumed; Escape reaches the focused
// widget first; a modal popup makes what is below it inert, bindings included, while popups opened
// inside it work; focus comes back to what it was taken from, or the nearest holder still there;
// placement flips, shrinks and clamps, and follows a scrolled anchor; every close says why; input in
// another root closes this one's light popups.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace vg = foundation::vg;

namespace
{
    template <typename T, typename... A>
    core::RefPtr<T> Make(A&&... args)
    {
        return core::MakeRef<T>(core::DefaultAllocator(), static_cast<A&&>(args)...);
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    core::Array<core::String>& DrawLog()
    {
        static core::Array<core::String> log;
        return log;
    }
    // Records that it drew.
    class Probe : public UIWidget
    {
    public:
        explicit Probe(const char8_t* name) : m_name(SV(name)) {}

    protected:
        void OnDraw(DrawContext&, const Rect&) override { DrawLog().PushBack(m_name); }

    private:
        core::String m_name;
    };

    core::RefPtr<Probe> MakeProbe(Node& parent, const char8_t* name, core::Float2 at, core::Float2 size)
    {
        auto p = Make<Probe>(name);
        p->SetPosition(at);
        p->SetSize(size);
        parent.AddChild(p.Get());
        return p;
    }
    core::RefPtr<Button> MakeButton(Node& parent, core::Float2 at, core::Float2 size = core::Float2{40.0f, 20.0f})
    {
        auto b = Make<Button>();
        b->SetPosition(at);
        b->SetSize(size);
        parent.AddChild(b.Get());
        return b;
    }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = Make<SceneRoot>(Make<GUIContext>());
        Bed() { root->SetSize(core::Float2{400.0f, 300.0f}); }
        EventDispatcher& d() { return *root->GetEventDispatcher(); }
        void Click(core::Float2 at)
        {
            d().InjectMouseDown(at, MouseButton::Left);
            d().InjectMouseUp(at, MouseButton::Left);
        }
        void Draw()
        {
            DrawLog().Clear();
            vg::VGContext canvas;
            DrawContext ctx{canvas};
            root->Draw(ctx);
        }
    };

    PopupOptions At(core::Float2 point, PopupKind kind = PopupKind::Auto)
    {
        PopupOptions o;
        o.Kind = kind;
        o.AnchorRect = Rect{point.x, point.y, 0.0f, 0.0f};
        o.HasAnchorRect = true;
        return o;
    }
}

TEST_CASE("popups: an open popup draws after the whole tree and takes the pointer first, unclipped by its owner")
{
    Bed bed;
    auto owner = Make<UIWidget>();
    owner->SetSize(core::Float2{50.0f, 50.0f});
    owner->SetClipChildren(true); // a clipping owner (a scroller)
    bed.root->AddChild(owner.Get());
    auto later = MakeProbe(*bed.root, u8"later", core::Float2{0.0f, 0.0f}, core::Float2{400.0f, 300.0f}); // over everything
    auto popup = Make<Probe>(u8"popup");
    popup->SetSize(core::Float2{100.0f, 80.0f});
    bed.d().OpenPopup(*owner, *popup, At(core::Float2{40.0f, 40.0f}));
    CHECK(popup->GetParent() == owner.Get());
    CHECK(popup->GetPosition().x == doctest::Approx(40.0f)); // in the root's space
    bed.Draw();
    REQUIRE(DrawLog().Size() == 2u);
    CHECK(DrawLog()[0] == SV(u8"later"));
    CHECK(DrawLog()[1] == SV(u8"popup")); // last, over the later sibling
    // Outside its clipping owner, over the later sibling: the pointer finds it.
    int pressed = 0;
    (void)popup->AddEventListener(EventType::MouseDown, [&](const Event&) { ++pressed; });
    bed.d().InjectMouseDown(core::Float2{120.0f, 100.0f}, MouseButton::Left);
    CHECK(pressed == 1);
    // Its events reach its owner on their way up.
    int bubbled = 0;
    (void)owner->AddEventListener(EventType::MouseDown, [&](const Event&) { ++bubbled; });
    bed.d().InjectMouseUp(core::Float2{120.0f, 100.0f}, MouseButton::Left);
    bed.d().InjectMouseDown(core::Float2{120.0f, 100.0f}, MouseButton::Left);
    CHECK(bubbled == 1);
}

TEST_CASE("popups: an open popup inherits its owner's styles where it is in the tree")
{
    Bed bed;
    auto owner = Make<UIWidget>();
    owner->AddClass(SV(u8"warm"));
    bed.root->AddChild(owner.Get());
    auto popup = Make<Label>();
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(SV(u8".warm { color: #ff8000; } .warm > label { padding: 4px; }")));
    bed.d().OpenPopup(*owner, *popup, At(core::Float2{10.0f, 10.0f}));
    styles.ApplyTree(*bed.root);
    CHECK(popup->GetTextColor().r == doctest::Approx(1.0f));
    CHECK(popup->GetTextColor().g == doctest::Approx(0x80 / 255.0f));
    CHECK(popup->GetPadding().Left == doctest::Approx(4.0f)); // `.warm > label` matches it in place
}

TEST_CASE("popups: nesting comes from the tree; opening another closes what does not hold it; closing takes its children")
{
    Bed bed;
    auto a = Make<Probe>(u8"a");
    a->SetSize(core::Float2{100.0f, 100.0f});
    auto item = MakeProbe(*a, u8"item", core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 20.0f});
    auto b = Make<Probe>(u8"b");
    b->SetSize(core::Float2{80.0f, 80.0f});
    auto c = Make<Probe>(u8"c");
    c->SetSize(core::Float2{80.0f, 80.0f});
    core::Array<core::String> closed;
    const auto watch = [&](PopupOptions o, const char8_t* name)
    {
        o.OnClosed = [&closed, name](PopupCloseReason reason)
        {
            core::String entry(SV(name));
            entry.Append(SV(u8":"));
            entry.Append(PopupCloseReasonName(reason));
            closed.PushBack(core::Move(entry));
        };
        return o;
    };
    bed.d().OpenPopup(*bed.root, *a, watch(At(core::Float2{10.0f, 10.0f}), u8"a"));
    bed.d().OpenPopup(*item, *b, watch(At(core::Float2{110.0f, 10.0f}), u8"b")); // inside a: a stays
    CHECK(bed.d().PopupCount() == 2u);
    bed.d().OpenPopup(*bed.root, *c, watch(At(core::Float2{200.0f, 150.0f}), u8"c")); // holds neither: both go
    REQUIRE(closed.Size() == 2u);
    CHECK(closed[0] == SV(u8"b:replaced")); // the inner first
    CHECK(closed[1] == SV(u8"a:replaced"));
    CHECK(bed.d().PopupCount() == 1u);

    closed.Clear();
    (void)bed.d().ClosePopup(*c);
    bed.d().OpenPopup(*bed.root, *a, watch(At(core::Float2{10.0f, 10.0f}), u8"a"));
    bed.d().OpenPopup(*item, *b, watch(At(core::Float2{110.0f, 10.0f}), u8"b"));
    closed.Clear();
    CHECK(bed.d().ClosePopup(*a));
    REQUIRE(closed.Size() == 2u);
    CHECK(closed[0] == SV(u8"b:code"));
    CHECK(closed[1] == SV(u8"a:code"));
    CHECK(a->GetParent() == nullptr); // a closed popup leaves the tree
}

TEST_CASE("popups: a press outside closes those above the one it is in, and is consumed with its release")
{
    Bed bed;
    auto opener = MakeButton(*bed.root, core::Float2{300.0f, 250.0f});
    int clicks = 0;
    opener->SetOnClick([&] { ++clicks; });
    auto a = Make<Probe>(u8"a");
    a->SetSize(core::Float2{100.0f, 100.0f});
    auto inner = MakeProbe(*a, u8"inner", core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 20.0f});
    auto b = Make<Probe>(u8"b");
    b->SetSize(core::Float2{50.0f, 50.0f});
    bed.d().OpenPopup(*opener, *a, At(core::Float2{10.0f, 10.0f}));
    bed.d().OpenPopup(*inner, *b, At(core::Float2{150.0f, 10.0f}));
    // A press in a closes b only, and goes on to a.
    int pressedA = 0;
    (void)a->AddEventListener(EventType::MouseDown, [&](const Event&) { ++pressedA; });
    bed.d().InjectMouseDown(core::Float2{50.0f, 80.0f}, MouseButton::Left);
    CHECK(pressedA == 1);
    CHECK_FALSE(bed.d().IsPopupOpen(*b));
    CHECK(bed.d().IsPopupOpen(*a));
    bed.d().InjectMouseUp(core::Float2{50.0f, 80.0f}, MouseButton::Left);
    // The opener pressed again: a closes, and the press does nothing more (no reopening click).
    CHECK(clicks == 0); // the click in a, bubbling to its opener, is not a click on the opener
    bed.Click(core::Float2{310.0f, 260.0f});
    CHECK_FALSE(bed.d().IsPopupOpen(*a));
    CHECK(clicks == 0);
    bed.Click(core::Float2{310.0f, 260.0f}); // nothing open: an ordinary click
    CHECK(clicks == 1);
}

TEST_CASE("popups: Escape goes to the focused widget first; untaken, it closes the topmost auto popup")
{
    Bed bed;
    auto taker = MakeButton(*bed.root, core::Float2{0.0f, 0.0f});
    bool take = true;
    (void)taker->AddEventListener(EventType::KeyDown, [&](const Event& e)
                                  {
                                      if (take)
                                          e.Handled = true;
                                  });
    bed.d().SetFocusNode(taker.Get());
    auto popup = Make<Probe>(u8"popup");
    popup->SetSize(core::Float2{50.0f, 50.0f});
    PopupCloseReason why = PopupCloseReason::Code;
    PopupOptions o = At(core::Float2{100.0f, 100.0f});
    o.OnClosed = [&](PopupCloseReason r) { why = r; };
    bed.d().OpenPopup(*bed.root, *popup, core::Move(o));
    bed.d().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(bed.d().IsPopupOpen(*popup)); // the focused widget took it
    take = false;
    bed.d().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(bed.d().IsPopupOpen(*popup));
    CHECK(why == PopupCloseReason::Escape);
}

TEST_CASE("popups: a modal makes what is below it inert, bindings too, while popups opened in it work")
{
    Bed bed;
    auto behind = MakeButton(*bed.root, core::Float2{0.0f, 0.0f});
    int behindClicks = 0;
    behind->SetOnClick([&] { ++behindClicks; });
    int rootCommands = 0;
    (void)bed.root->OnCommand(SV(u8"save"), [&](CommandEvent&) { ++rootCommands; });
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"ctrl-s"), SV(u8"save")));
    bed.d().SetFocusNode(behind.Get());

    auto dialog = Make<UIWidget>();
    dialog->SetSize(core::Float2{200.0f, 150.0f});
    dialog->SetPosition(core::Float2{100.0f, 100.0f});
    auto inside = MakeButton(*dialog, core::Float2{10.0f, 10.0f});
    PopupOptions modal;
    modal.Kind = PopupKind::Manual;
    modal.Modal = true;
    bed.d().OpenPopup(*bed.root, *dialog, core::Move(modal));
    CHECK(inside->IsFocused()); // focus moved in

    bed.Click(core::Float2{10.0f, 10.0f});
    CHECK(behindClicks == 0); // inert
    CHECK(bed.d().IsPopupOpen(*dialog)); // and a dialog is not light-dismissed
    bed.d().InjectKeyDown(static_cast<core::u32>(KeyCode::S), KeyModCtrl);
    CHECK(rootCommands == 0); // the root's binding does not reach past the modal
    CHECK_FALSE(bed.root->IsCommandAvailable(SV(u8"save")));

    // A list opened from inside the dialog stacks above it and takes presses; a press elsewhere
    // in the dialog closes it.
    auto list = Make<Probe>(u8"list");
    list->SetSize(core::Float2{60.0f, 60.0f});
    PopupOptions drop;
    drop.Anchor = inside.Get();
    bed.d().OpenPopup(*inside, *list, core::Move(drop));
    int listPresses = 0;
    (void)list->AddEventListener(EventType::MouseDown, [&](const Event&) { ++listPresses; });
    bed.Click(core::Float2{130.0f, 140.0f}); // in the list, below the button
    CHECK(listPresses == 1);
    bed.Click(core::Float2{250.0f, 200.0f}); // in the dialog, outside the list
    CHECK_FALSE(bed.d().IsPopupOpen(*list));
    CHECK(bed.d().IsPopupOpen(*dialog));

    (void)bed.d().ClosePopup(*dialog);
    CHECK(behind->IsFocused()); // focus back
    bed.d().InjectKeyDown(static_cast<core::u32>(KeyCode::S), KeyModCtrl);
    CHECK(rootCommands == 1);
}

TEST_CASE("popups: focus comes back to what it was taken from, else the nearest holder still there and enabled")
{
    Bed bed;
    auto holder = MakeButton(*bed.root, core::Float2{0.0f, 0.0f}, core::Float2{200.0f, 100.0f});
    auto start = MakeButton(*holder, core::Float2{10.0f, 10.0f});
    const auto openFocusing = [&](Node& popup)
    {
        PopupOptions o = At(core::Float2{250.0f, 150.0f});
        o.TakesFocus = true;
        bed.d().OpenPopup(*bed.root, popup, core::Move(o));
    };
    auto popup = Make<UIWidget>();
    popup->SetSize(core::Float2{100.0f, 60.0f});
    auto field = MakeButton(*popup, core::Float2{5.0f, 5.0f});

    bed.d().SetFocusNode(start.Get());
    openFocusing(*popup);
    CHECK(field->IsFocused());
    (void)bed.d().ClosePopup(*popup);
    CHECK(start->IsFocused());

    openFocusing(*popup);
    start->SetEnabled(false); // what it came from is disabled meanwhile
    (void)bed.d().ClosePopup(*popup);
    CHECK(holder->IsFocused()); // the nearest holder that can take it
    start->SetEnabled(true);

    bed.d().SetFocusNode(start.Get());
    openFocusing(*popup);
    holder->RemoveChild(start.Get()); // gone meanwhile
    (void)bed.d().ClosePopup(*popup);
    CHECK(holder->IsFocused());

    // Focus that moved out of the popup meanwhile is left where it went.
    bed.d().SetFocusNode(holder.Get());
    openFocusing(*popup);
    auto elsewhere = MakeButton(*bed.root, core::Float2{300.0f, 0.0f});
    bed.d().SetFocusNode(elsewhere.Get());
    (void)bed.d().ClosePopup(*popup);
    CHECK(elsewhere->IsFocused());
}

TEST_CASE("popups: placement flips, shrinks and clamps at every edge")
{
    const Rect bounds{0.0f, 0.0f, 400.0f, 300.0f};
    // Below fits.
    PlacedPopup p = PlacePopup(Rect{10.0f, 10.0f, 50.0f, 20.0f}, core::Float2{100.0f, 80.0f}, bounds, PopupPlacement{}, false);
    CHECK(p.Side == PopupSide::Below);
    CHECK(p.Position.y == doctest::Approx(30.0f));
    // Near the bottom: flipped above.
    p = PlacePopup(Rect{10.0f, 260.0f, 50.0f, 20.0f}, core::Float2{100.0f, 80.0f}, bounds, PopupPlacement{}, false);
    CHECK(p.Side == PopupSide::Above);
    CHECK(p.Position.y == doctest::Approx(180.0f));
    // Too tall for either side: the larger side, shrunk to it.
    p = PlacePopup(Rect{10.0f, 100.0f, 50.0f, 20.0f}, core::Float2{100.0f, 400.0f}, bounds, PopupPlacement{}, false);
    CHECK(p.Side == PopupSide::Below);
    CHECK(p.Size.y == doctest::Approx(180.0f));
    CHECK(p.Position.y + p.Size.y <= 300.0f + 0.01f);
    // Past the right edge: slid back in.
    p = PlacePopup(Rect{380.0f, 10.0f, 20.0f, 20.0f}, core::Float2{100.0f, 50.0f}, bounds, PopupPlacement{}, false);
    CHECK(p.Position.x == doctest::Approx(300.0f));
    // A submenu at the right edge flips to its item's inline start; at the bottom it slides up.
    p = PlacePopup(Rect{300.0f, 250.0f, 80.0f, 20.0f}, core::Float2{120.0f, 100.0f}, bounds,
                   PopupPlacement{PopupSide::InlineEnd, PopupAlign::Start, 0.0f, true}, false);
    CHECK(p.Side == PopupSide::InlineStart);
    CHECK(p.Position.x == doctest::Approx(180.0f));
    CHECK(p.Position.y == doctest::Approx(200.0f));
    // Centred under its anchor, past the left edge: clamped to it.
    p = PlacePopup(Rect{0.0f, 10.0f, 20.0f, 20.0f}, core::Float2{100.0f, 50.0f}, bounds,
                   PopupPlacement{PopupSide::Below, PopupAlign::Center, 4.0f, true}, false);
    CHECK(p.Position.x == doctest::Approx(0.0f));
    CHECK(p.Position.y == doctest::Approx(34.0f));
}

TEST_CASE("popups: in right to left the inline sides and the start alignment mirror")
{
    const Rect bounds{0.0f, 0.0f, 400.0f, 300.0f};
    // A dropdown's start is the right: the right edges line up.
    PlacedPopup p = PlacePopup(Rect{200.0f, 10.0f, 150.0f, 20.0f}, core::Float2{100.0f, 80.0f}, bounds,
                               PopupPlacement{}, true);
    CHECK(p.Side == PopupSide::Below);
    CHECK(p.Position.x == doctest::Approx(250.0f));
    // End lines up the left edges; centred is the same either way.
    p = PlacePopup(Rect{200.0f, 10.0f, 150.0f, 20.0f}, core::Float2{100.0f, 80.0f}, bounds,
                   PopupPlacement{PopupSide::Below, PopupAlign::End, 0.0f, true}, true);
    CHECK(p.Position.x == doctest::Approx(200.0f));
    p = PlacePopup(Rect{200.0f, 10.0f, 150.0f, 20.0f}, core::Float2{100.0f, 80.0f}, bounds,
                   PopupPlacement{PopupSide::Below, PopupAlign::Center, 0.0f, true}, true);
    CHECK(p.Position.x == doctest::Approx(225.0f));
    // A submenu goes to its item's inline end, the left, its top with the item's.
    p = PlacePopup(Rect{200.0f, 40.0f, 80.0f, 20.0f}, core::Float2{120.0f, 100.0f}, bounds,
                   PopupPlacement{PopupSide::InlineEnd, PopupAlign::Start, 0.0f, true}, true);
    CHECK(p.Side == PopupSide::InlineEnd);
    CHECK(p.Position.x == doctest::Approx(80.0f));
    CHECK(p.Position.y == doctest::Approx(40.0f));
    // At the left edge it flips to the inline start, the right.
    p = PlacePopup(Rect{20.0f, 40.0f, 80.0f, 20.0f}, core::Float2{120.0f, 100.0f}, bounds,
                   PopupPlacement{PopupSide::InlineEnd, PopupAlign::Start, 0.0f, true}, true);
    CHECK(p.Side == PopupSide::InlineStart);
    CHECK(p.Position.x == doctest::Approx(100.0f));
    // A context menu at a point opens toward the left of it.
    p = PlaceAtPoint(core::Float2{300.0f, 50.0f}, core::Float2{100.0f, 80.0f}, bounds, true);
    CHECK(p.Position.x == doctest::Approx(200.0f));
    CHECK(p.Position.y == doctest::Approx(50.0f));
}

TEST_CASE("popups: one opened in a right-to-left part of a page places itself in that direction")
{
    Bed bed; // the page runs left to right; a part of it right to left
    auto part = Make<UIWidget>();
    part->SetSize(core::Float2{400.0f, 300.0f});
    part->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    bed.root->AddChild(part.Get());
    auto field = MakeButton(*part, core::Float2{200.0f, 10.0f}, core::Float2{150.0f, 20.0f});
    (void)bed.root->UpdateLayout();
    const core::Float2 fieldAt = field->ConvertToRootSpace(core::Float2{0.0f, 0.0f});

    // Below its anchor, the right edges lined up (a combo box's list).
    auto list = Make<Probe>(u8"list");
    list->SetSize(core::Float2{100.0f, 80.0f});
    PopupOptions below;
    below.Anchor = field.Get();
    bed.d().OpenPopup(*field, *list, core::Move(below));
    (void)bed.root->UpdateLayout();
    const core::Float2 listAt = list->ConvertToRootSpace(core::Float2{0.0f, 0.0f});
    CHECK(listAt.x + 100.0f == doctest::Approx(fieldAt.x + 150.0f));
    CHECK(listAt.y == doctest::Approx(fieldAt.y + 20.0f));
    (void)bed.d().ClosePopup(*list);

    // At a point, owned there: toward the left of it (a context menu).
    auto menu = Make<Probe>(u8"menu");
    menu->SetSize(core::Float2{100.0f, 80.0f});
    bed.d().OpenPopup(*part, *menu, At(core::Float2{300.0f, 50.0f}));
    (void)bed.root->UpdateLayout();
    CHECK(menu->ConvertToRootSpace(core::Float2{0.0f, 0.0f}).x == doctest::Approx(200.0f));
}

TEST_CASE("popups: an anchored popup follows its anchor when what holds it scrolls")
{
    Bed bed;
    auto scroller = Make<UIWidget>();
    scroller->SetSize(core::Float2{200.0f, 200.0f});
    scroller->EditLayoutStyle([](LayoutStyle& s) { s.OverflowY = Overflow::Scroll; s.Direction = FlexDirection::Column; });
    bed.root->AddChild(scroller.Get());
    auto filler = Make<UIWidget>();
    filler->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(100.0f); });
    scroller->AddChild(filler.Get());
    auto anchor = Make<Button>();
    anchor->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(20.0f); });
    scroller->AddChild(anchor.Get());
    auto rest = Make<UIWidget>();
    rest->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(400.0f); });
    scroller->AddChild(rest.Get());
    bed.root->UpdateLayout();
    auto popup = Make<Probe>(u8"popup");
    popup->SetSize(core::Float2{80.0f, 40.0f});
    PopupOptions o;
    o.Anchor = anchor.Get();
    bed.d().OpenPopup(*anchor, *popup, core::Move(o));
    CHECK(popup->GetPosition().y == doctest::Approx(120.0f));
    scroller->SetScrollOffset(core::Float2{0.0f, 50.0f});
    bed.root->UpdateLayout();
    CHECK(popup->GetPosition().y == doctest::Approx(70.0f));
}

TEST_CASE("popups: opening and closing are toggle events at the popup, which reach its owner")
{
    Bed bed;
    auto owner = MakeButton(*bed.root, core::Float2{0.0f, 0.0f});
    auto popup = Make<Probe>(u8"popup");
    popup->SetSize(core::Float2{50.0f, 50.0f});
    core::Array<core::String> heard;
    (void)owner->AddEventListener(EventType::Toggle, [&](const Event& e)
                                  {
                                      const ToggleEvent& t = static_cast<const ToggleEvent&>(e);
                                      heard.PushBack(core::String(t.Open ? SV(u8"open") : PopupCloseReasonName(t.Reason)));
                                  });
    bed.d().OpenPopup(*owner, *popup, At(core::Float2{100.0f, 100.0f}));
    bed.d().InjectMouseDown(core::Float2{350.0f, 250.0f}, MouseButton::Left);
    REQUIRE(heard.Size() == 2u);
    CHECK(heard[0] == SV(u8"open"));
    CHECK(heard[1] == SV(u8"outside-press"));
}

TEST_CASE("popups: a hint never takes the pointer and closes on any press or key, leaving the others")
{
    Bed bed;
    auto menu = Make<Probe>(u8"menu");
    menu->SetSize(core::Float2{100.0f, 100.0f});
    bed.d().OpenPopup(*bed.root, *menu, At(core::Float2{0.0f, 0.0f}));
    auto tip = Make<Probe>(u8"tip");
    tip->SetSize(core::Float2{100.0f, 100.0f});
    bed.d().OpenPopup(*bed.root, *tip, At(core::Float2{0.0f, 0.0f}, PopupKind::Hint));
    CHECK(bed.d().IsPopupOpen(*menu)); // a hint closes no one
    int menuPresses = 0;
    (void)menu->AddEventListener(EventType::MouseDown, [&](const Event&) { ++menuPresses; });
    bed.d().InjectMouseDown(core::Float2{50.0f, 50.0f}, MouseButton::Left); // through the hint
    CHECK(menuPresses == 1);
    CHECK_FALSE(bed.d().IsPopupOpen(*tip));
    CHECK(bed.d().IsPopupOpen(*menu));
}

TEST_CASE("popups: input in another root of the GUI closes this root's light popups, not its dialogs")
{
    auto gui = Make<GUIContext>();
    auto a = Make<SceneRoot>(gui);
    auto b = Make<SceneRoot>(gui);
    a->SetSize(core::Float2{200.0f, 200.0f});
    b->SetSize(core::Float2{200.0f, 200.0f});
    auto menu = Make<Probe>(u8"menu");
    menu->SetSize(core::Float2{50.0f, 50.0f});
    a->GetEventDispatcher()->OpenPopup(*a, *menu, At(core::Float2{10.0f, 10.0f}));
    auto dialog = Make<Probe>(u8"dialog");
    dialog->SetSize(core::Float2{50.0f, 50.0f});
    PopupOptions manual = At(core::Float2{100.0f, 100.0f}, PopupKind::Manual);
    a->GetEventDispatcher()->OpenPopup(*a, *dialog, core::Move(manual));
    auto menu2 = Make<Probe>(u8"menu2");
    menu2->SetSize(core::Float2{50.0f, 50.0f});
    a->GetEventDispatcher()->OpenPopup(*a, *menu2, At(core::Float2{60.0f, 10.0f}));
    b->GetEventDispatcher()->InjectMouseDown(core::Float2{5.0f, 5.0f}, MouseButton::Left);
    CHECK_FALSE(a->GetEventDispatcher()->IsPopupOpen(*menu2)); // above the dialog: closed
    CHECK(a->GetEventDispatcher()->IsPopupOpen(*dialog));
    CHECK(a->GetEventDispatcher()->IsPopupOpen(*menu)); // below the dialog: kept
}

TEST_CASE("popups: a popup whose old parent held the only reference to it survives the move to its owner")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 300.0f});
    auto page = core::MakeRef<Panel>(core::DefaultAllocator());
    root->AddChild(page.Get());
    Node* popup = nullptr;
    {
        auto made = core::MakeRef<Panel>(core::DefaultAllocator());
        made->SetSize(core::Float2{80.0f, 40.0f});
        page->AddChild(made.Get());
        popup = made.Get(); // the page holds the only reference now
    }
    auto owner = core::MakeRef<Panel>(core::DefaultAllocator());
    root->AddChild(owner.Get());
    EventDispatcher& d = *root->GetEventDispatcher();
    d.OpenPopup(*owner, *popup, PopupOptions{});
    CHECK(d.IsPopupOpen(*popup));
    CHECK(popup->GetParent() == owner.Get());
    CHECK(page->ChildCount() == 0);
}

TEST_CASE("popups: one sized by its content grows when its content does (a tooltip whose font arrives late)")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 300.0f});
    auto popup = core::MakeRef<Panel>(core::DefaultAllocator());
    auto content = core::MakeRef<Panel>(core::DefaultAllocator());
    content->EditLayoutStyle([](LayoutStyle& s)
    {
        s.Width = LayoutLength::Px(20.0f);
        s.Height = LayoutLength::Px(10.0f);
    });
    popup->AddChild(content.Get());
    EventDispatcher& d = *root->GetEventDispatcher();
    PopupOptions options;
    options.Kind = PopupKind::Hint;
    options.AnchorRect = Rect{50.0f, 50.0f, 0.0f, 0.0f};
    options.HasAnchorRect = true;
    options.FitContent = true;
    d.OpenPopup(*root, *popup, core::Move(options));
    (void)root->UpdateLayout();
    CHECK(popup->GetSize().x == doctest::Approx(20.0f));
    content->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(150.0f); }); // what it shows grew
    (void)root->UpdateLayout();
    CHECK(popup->GetSize().x == doctest::Approx(150.0f));
}

TEST_CASE("popups: one placed against a rectangle follows it when its owner moves it")
{
    Bed bed;
    auto popup = Make<Panel>();
    popup->SetSize(core::Float2{60.0f, 40.0f});
    PopupOptions options = At(core::Float2{50.0f, 50.0f}, PopupKind::Manual);
    bed.d().OpenPopup(*bed.root, *popup, core::Move(options));
    CHECK(popup->GetPosition().x == doctest::Approx(50.0f));
    // A code editor's caret, scrolled: its list goes with it.
    CHECK(bed.d().SetPopupAnchorRect(*popup, Rect{120.0f, 80.0f, 0.0f, 16.0f}));
    CHECK(popup->GetPosition().x == doctest::Approx(120.0f));
    CHECK(popup->GetPosition().y == doctest::Approx(96.0f)); // below it
    (void)bed.d().ClosePopup(*popup);
    CHECK_FALSE(bed.d().SetPopupAnchorRect(*popup, Rect{0.0f, 0.0f, 0.0f, 0.0f})); // not open
}

TEST_CASE("popups: one open that goes back home on close does not keep its root alive")
{
    // Its home is the root itself, which owns the dispatcher holding the entry: a strong reference
    // there would make a cycle, and a GUI closed with the popup open would never be freed.
    auto root = Make<SceneRoot>(Make<GUIContext>());
    const core::WeakRefPtr<SceneRoot> weak(root);
    auto screen = Make<Panel>();
    root->AddChild(screen.Get());
    PopupOptions options;
    options.Kind = PopupKind::Manual;
    options.Modal = true;
    options.ReturnHome = true;
    root->GetEventDispatcher()->OpenPopup(*root, *screen, core::Move(options));
    REQUIRE(root->GetEventDispatcher()->IsPopupOpen(*screen));
    root = core::RefPtr<SceneRoot>{};
    CHECK(weak.Expired());
}
