// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - scrolling: the ScrollBar control, and any node that scrolls (overflow: scroll or auto, E2
// of Specs/gui-lab-evolution.md): its range over the laid-out content, the content moving without a
// new layout, the wheel, the keys while focused, its bars (drag, page, over the content), a focused
// descendant brought into view, and the extent following the content.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace vg = foundation::vg;
using core::f32;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    // A 100 x 100 scroller at the root's corner holding `rows` 50-high rows.
    struct Scroller
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<ScrollView> view = Make<ScrollView>();
        core::Array<core::RefPtr<Panel>> rows;
        explicit Scroller(int count = 6)
        {
            root->SetSize(core::Float2{300.0f, 300.0f});
            view->SetPosition(core::Float2{0.0f, 0.0f});
            view->SetSize(core::Float2{100.0f, 100.0f});
            root->AddChild(view.Get());
            for (int i = 0; i < count; ++i)
            {
                rows.PushBack(Make<Panel>());
                rows[rows.Size() - 1]->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(50.0f); });
                rows[rows.Size() - 1]->SetTabFocusable(true);
                view->AddChild(rows[rows.Size() - 1].Get());
            }
            root->UpdateLayout();
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
    };
}

TEST_CASE("scrollbar: its value is an offset, kept within the range less the page; the thumb is the page's share")
{
    auto sb = Make<ScrollBar>();
    sb->SetMax(400.0);
    sb->SetPage(100.0); // a quarter shows
    CHECK(sb->GetThumbProportion() == doctest::Approx(0.25f));
    sb->SetValue(120.0);
    CHECK(sb->GetValue() == doctest::Approx(120.0));
    sb->SetValue(500.0);
    CHECK(sb->GetValue() == doctest::Approx(300.0)); // the maximum less the page
    sb->SetPage(1000.0);
    CHECK(sb->GetThumbProportion() == doctest::Approx(1.0f));
    CHECK(sb->GetValue() == doctest::Approx(0.0)); // nothing to scroll
}

TEST_CASE("scrollbar: drag keeps tracking after the cursor leaves it (capture + hover leave)")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 400.0f});
    auto sb = Make<ScrollBar>();
    sb->SetOrientation(Orientation::Vertical);
    sb->SetSize(core::Float2{16.0f, 200.0f}); // vertical track length 200
    sb->SetMax(200.0);
    sb->SetPage(100.0);                       // thumb 100 -> travel 100
    int inputs = 0, changes = 0;
    sb->SetOnValueChanging([&](core::f64) { ++inputs; });
    sb->SetOnValueChanged([&](core::f64) { ++changes; });
    root->AddChild(sb.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // Hover first (so a leave will fire when we drag off), then press near the top.
    d->InjectMouseMove(core::Float2{8.0f, 10.0f});
    CHECK(sb->IsHovered());
    d->InjectMouseDown(core::Float2{8.0f, 10.0f}, MouseButton::Left);

    // Drag well past the bottom edge -> the value saturates at the end (still tracking after leave).
    d->InjectMouseMove(core::Float2{8.0f, 500.0f});
    CHECK_FALSE(sb->IsHovered());
    CHECK(sb->GetValue() == doctest::Approx(100.0));
    CHECK(inputs == 1);
    CHECK(changes == 0); // committed on release

    // Release ends the drag.
    d->InjectMouseUp(core::Float2{8.0f, 500.0f}, MouseButton::Left);
    CHECK(changes == 1);
    d->InjectMouseMove(core::Float2{8.0f, 10.0f});
    CHECK(sb->GetValue() == doctest::Approx(100.0));
}

TEST_CASE("scrollbar: draws track + thumb")
{
    auto sb = Make<ScrollBar>();
    sb->SetSize(core::Float2{16.0f, 120.0f});
    sb->SetMax(100.0);
    sb->SetPage(30.0);
    sb->SetValue(35.0);

    vg::VGContext ctx;
    DrawContext dc{ctx};
    sb->Draw(dc);
    CHECK(ctx.GetBatch().vertices.Size() > 0);
}

TEST_CASE("scrollbar: clicking the track pages toward the click")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 400.0f});
    auto sb = Make<ScrollBar>();
    sb->SetOrientation(Orientation::Vertical);
    sb->SetSize(core::Float2{16.0f, 200.0f});
    sb->SetMax(200.0);
    sb->SetPage(50.0); // thumb 50 -> at value 0 occupies [0,50]
    root->AddChild(sb.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // Click below the thumb (y=150) -> page down by one page.
    d->InjectMouseDown(core::Float2{8.0f, 150.0f}, MouseButton::Left);
    CHECK(sb->GetValue() == doctest::Approx(50.0));
    d->InjectMouseUp(core::Float2{8.0f, 150.0f}, MouseButton::Left);
}

TEST_CASE("scrollbar: grabbing the thumb drags by cursor delta (no jump-to-center)")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 400.0f});
    auto sb = Make<ScrollBar>();
    sb->SetOrientation(Orientation::Vertical);
    sb->SetSize(core::Float2{16.0f, 200.0f});
    sb->SetMax(200.0);
    sb->SetPage(100.0); // thumb 100 -> travel 100, at value 0 occupies [0,100]
    root->AddChild(sb.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // Grab the thumb at y=40 (inside [0,100]); pressing there must NOT move the value.
    d->InjectMouseDown(core::Float2{8.0f, 40.0f}, MouseButton::Left);
    CHECK(sb->GetValue() == doctest::Approx(0.0));
    // Move the cursor down 20px -> thumb moves 20px -> a fifth of the travel: 20 of the 100 it can go.
    d->InjectMouseMove(core::Float2{8.0f, 60.0f});
    CHECK(sb->GetValue() == doctest::Approx(20.0));
}

TEST_CASE("scroll: a node that overflows scrolls over its laid-out content, the content moving with no layout")
{
    Scroller s;
    CHECK(s.view->IsScrollContainer());
    CHECK(s.view->GetContentExtent().y == doctest::Approx(300.0f));
    CHECK(s.view->GetScrollRange().x == doctest::Approx(0.0f)); // nothing wider than it
    CHECK(s.view->GetScrollRange().y == doctest::Approx(200.0f));
    s.view->SetScrollOffset(core::Float2{0.0f, 500.0f});
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(200.0f));
    s.view->SetScrollOffset(core::Float2{0.0f, 60.0f});
    s.root->UpdateLayout();
    CHECK(s.root->LastLayoutCount() == 0u);                         // scrolling lays nothing out
    CHECK(s.rows[2]->GetPosition().y == doctest::Approx(100.0f));     // where the layout put it
    CHECK(s.rows[2]->GetScreenBounds().y == doctest::Approx(40.0f));  // where it shows
    CHECK(s.root->GetEventDispatcher()->IsPointerOver(core::Float2{10.0f, 45.0f}));
}

TEST_CASE("scroll: the wheel scrolls it from the content; keys scroll it only while it is focused")
{
    Scroller s;
    CHECK(s.D().InjectMouseWheel(core::Float2{20.0f, 20.0f}, core::Float2{0.0f, -1.0f}));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(s.view->GetScrollStep()));
    s.D().SetFocusNode(s.rows[0].Get());
    const f32 before = s.view->GetScrollOffset().y;
    s.D().InjectKeyDown(static_cast<core::u32>(KeyCode::PageDown));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(before)); // the row's key, left to navigation
    s.D().SetFocusNode(s.view.Get());
    CHECK(s.D().InjectKeyDown(static_cast<core::u32>(KeyCode::End)));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(200.0f));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(200.0f)); // already at the end
}

TEST_CASE("scroll: one whose keys are its own does not scroll by them; the wheel still does")
{
    Scroller s;
    s.view->SetScrollsByKeys(false);
    s.D().SetFocusNode(s.view.Get());
    s.D().InjectKeyDown(static_cast<core::u32>(KeyCode::End));
    s.D().InjectKeyDown(static_cast<core::u32>(KeyCode::PageDown));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(0.0f));
    CHECK(s.D().InjectMouseWheel(core::Float2{20.0f, 20.0f}, core::Float2{0.0f, -1.0f}));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(s.view->GetScrollStep()));
}

TEST_CASE("scroll: its bar lies over the content; the thumb drags, the track pages")
{
    Scroller s;
    const Rect track = s.view->ScrollBarTrack(1);
    REQUIRE(track.height > 0.0f);
    CHECK(track.x == doctest::Approx(92.0f)); // over the right edge, on top of the rows
    const Rect thumb = s.view->ScrollBarThumb(1);
    CHECK(thumb.height == doctest::Approx(100.0f * 100.0f / 300.0f));
    int rowPresses = 0;
    (void)s.rows[0]->AddEventListener(EventType::MouseDown, [&](const Event&) { ++rowPresses; });
    const core::Float2 grab{96.0f, thumb.y + 5.0f};
    s.D().InjectMouseDown(grab, MouseButton::Left);
    CHECK(rowPresses == 0); // the bar's, not the row's under it
    CHECK(s.D().GetPointerCapture() == s.view.Get());
    s.D().InjectMouseMove(core::Float2{96.0f, grab.y + (100.0f - thumb.height) * 0.5f});
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(100.0f)); // half the travel: half the range
    s.D().InjectMouseUp(core::Float2{96.0f, 90.0f}, MouseButton::Left);
    s.view->SetScrollOffset(core::Float2{0.0f, 0.0f});
    s.D().InjectMouseDown(core::Float2{96.0f, 90.0f}, MouseButton::Left); // the track below the thumb
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(100.0f));        // a page down
    s.D().InjectMouseUp(core::Float2{96.0f, 90.0f}, MouseButton::Left);
}

TEST_CASE("scroll: a focused descendant comes into view, by the least that shows it")
{
    Scroller s;
    s.D().SetFocusNode(s.rows[4].Get()); // y 200..250
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(150.0f));
    s.D().SetFocusNode(s.rows[1].Get()); // y 50..100: above the view now
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(50.0f));
}

TEST_CASE("scroll: the extent follows the content as it grows and shrinks; the offset stays in range")
{
    Scroller s(2);
    CHECK(s.view->GetScrollRange().y == doctest::Approx(0.0f));
    s.rows[1]->EditLayoutStyle([](LayoutStyle& st) { st.Height = LayoutLength::Px(250.0f); }); // a child styled taller later
    s.root->UpdateLayout();
    CHECK(s.view->GetScrollRange().y == doctest::Approx(200.0f));
    s.view->SetScrollOffset(core::Float2{0.0f, 200.0f});
    s.rows[1]->SetDisplayed(false);
    s.root->UpdateLayout();
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(0.0f));
}

TEST_CASE("scroll: overflow from a sheet makes any node scroll; hidden clips without scrolling")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto panel = Make<Panel>();
    panel->AddClass(core::StringView(u8"list"));
    root->AddChild(panel.Get());
    auto tall = Make<Panel>();
    tall->EditLayoutStyle([](LayoutStyle& st) { st.Height = LayoutLength::Px(500.0f); st.Shrink = 0.0f; });
    panel->AddChild(tall.Get());
    StyleManager styles(CSSParser::Parse(core::StringView(u8".list { height: 120px; overflow-y: auto; }")));
    styles.ApplyTree(*root.Get());
    root->UpdateLayout();
    CHECK(panel->IsScrollContainer());
    CHECK(panel->ClipsChildren());
    CHECK(panel->GetScrollRange().y == doctest::Approx(380.0f));
    StyleManager hidden(CSSParser::Parse(core::StringView(u8".list { overflow: hidden; }")));
    hidden.ApplyTree(*root.Get());
    root->UpdateLayout();
    CHECK_FALSE(panel->IsScrollContainer());
    CHECK(panel->ClipsChildren());
}

TEST_CASE("scroll: a scroll reports to the scroller's own listeners, once per move")
{
    Scroller s;
    int scrolls = 0;
    s.view->AddEventListener(EventType::Scroll, [&](const Event&) { ++scrolls; });
    s.view->SetScrollOffset(core::Float2{0.0f, 40.0f});
    CHECK(scrolls == 1);
    s.view->SetScrollOffset(core::Float2{0.0f, 40.0f}); // no move
    CHECK(scrolls == 1);
    s.view->ScrollBy(core::Float2{0.0f, 1000.0f}); // to the end, clamped
    CHECK(scrolls == 2);
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(200.0f));
}

TEST_CASE("scroll: the handle scrolls to an offset, to the end, and a descendant to an alignment")
{
    Scroller s(10); // 500 tall in a 100 view: a range of 400
    s.view->ScrollToEnd();
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(400.0f));
    s.view->ScrollTo(core::Float2{0.0f, 0.0f});
    s.view->ScrollIntoView(*s.rows[4], ScrollAlign::Start); // row 4 at 200
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(200.0f));
    s.root->UpdateLayout();
    s.view->ScrollIntoView(*s.rows[4], ScrollAlign::End); // its bottom (250) at the view's
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(150.0f));
    s.root->UpdateLayout();
    s.view->ScrollIntoView(*s.rows[4], ScrollAlign::Center); // its middle (225) at the view's
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(175.0f));
    s.root->UpdateLayout();
    s.view->ScrollIntoView(*s.rows[4]); // already shown: no move
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(175.0f));
}

TEST_CASE("scroll: a smooth scroll eases there on the GUI's clock, and wheel notches add up")
{
    Scroller s(10);
    GUIContext& gui = s.root->GetContext();
    s.view->ScrollTo(core::Float2{0.0f, 200.0f}, ScrollBehavior::Smooth);
    CHECK(s.view->IsSmoothScrolling());
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(0.0f));
    CHECK(s.view->GetScrollTarget().y == doctest::Approx(200.0f));
    gui.Update(core::Duration::FromSeconds(0.06)); // one time constant: about 63% of the way
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(200.0f * (1.0f - 0.3679f)).epsilon(0.01));
    for (int i = 0; i < 20; ++i)
        gui.Update(core::Duration::FromSeconds(0.05));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(200.0f));
    CHECK_FALSE(s.view->IsSmoothScrolling());

    // `scroll-behavior: smooth` makes the wheel ease; two notches go twice as far.
    s.view->SetScrollOffset(core::Float2{0.0f, 0.0f});
    s.view->EditLayoutStyle([](LayoutStyle& st) { st.Scrolling = ScrollBehavior::Smooth; });
    s.root->UpdateLayout();
    s.D().InjectMouseWheel(core::Float2{50.0f, 50.0f}, core::Float2{0.0f, -1.0f});
    s.D().InjectMouseWheel(core::Float2{50.0f, 50.0f}, core::Float2{0.0f, -1.0f});
    CHECK(s.view->GetScrollTarget().y == doctest::Approx(80.0f));
    CHECK(s.view->GetScrollOffset().y < 80.0f);
    // An instant scroll ends the easing where it puts it.
    s.view->SetScrollOffset(core::Float2{0.0f, 10.0f});
    CHECK_FALSE(s.view->IsSmoothScrolling());
    gui.Update(core::Duration::FromSeconds(0.5));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(10.0f));
}

TEST_CASE("scroll: Shift turns the wheel across, and a scroller that only scrolls across takes it")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto strip = Make<Panel>();
    strip->SetSize(core::Float2{100.0f, 60.0f});
    strip->EditLayoutStyle([](LayoutStyle& st)
    {
        st.Direction = FlexDirection::Row;
        st.OverflowX = Overflow::Auto;
    });
    root->AddChild(strip.Get());
    core::RefPtr<Panel> cells[4];
    for (auto& cell : cells)
    {
        cell = Make<Panel>();
        cell->EditLayoutStyle([](LayoutStyle& st) { st.Width = LayoutLength::Px(80.0f); st.Shrink = 0.0f; });
        strip->AddChild(cell.Get());
    }
    root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    d.InjectMouseWheel(core::Float2{50.0f, 20.0f}, core::Float2{0.0f, -1.0f}); // a vertical notch
    CHECK(strip->GetScrollOffset().x == doctest::Approx(40.0f));

    Scroller s; // both axes may scroll; Shift and a vertical notch go across, and there is no room
    s.view->EditLayoutStyle([](LayoutStyle& st) { st.OverflowX = Overflow::Auto; });
    auto wide = Make<Panel>();
    wide->EditLayoutStyle([](LayoutStyle& st) { st.Width = LayoutLength::Px(300.0f); st.Height = LayoutLength::Px(10.0f); });
    s.view->AddChild(wide.Get());
    s.root->UpdateLayout();
    s.D().InjectMouseWheel(core::Float2{50.0f, 50.0f}, core::Float2{0.0f, -1.0f}, KeyModShift);
    CHECK(s.view->GetScrollOffset().x == doctest::Approx(40.0f));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(0.0f));
}

TEST_CASE("scroll: at its end a scroller passes the wheel on, unless it contains its overscroll")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto outer = Make<ScrollView>();
    outer->SetSize(core::Float2{200.0f, 200.0f});
    root->AddChild(outer.Get());
    auto inner = Make<ScrollView>();
    inner->EditLayoutStyle([](LayoutStyle& st)
    {
        st.Width = LayoutLength::Px(150.0f); // a scroller on both axes leaves its children their own width
        st.Height = LayoutLength::Px(100.0f);
        st.Shrink = 0.0f;
    });
    outer->AddChild(inner.Get());
    auto tall = Make<Panel>();
    tall->EditLayoutStyle([](LayoutStyle& st) { st.Height = LayoutLength::Px(150.0f); });
    inner->AddChild(tall.Get());
    auto after = Make<Panel>();
    after->EditLayoutStyle([](LayoutStyle& st) { st.Height = LayoutLength::Px(400.0f); st.Shrink = 0.0f; });
    outer->AddChild(after.Get());
    root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();

    inner->SetScrollOffset(core::Float2{0.0f, 50.0f}); // at its end
    d.InjectMouseWheel(core::Float2{50.0f, 50.0f}, core::Float2{0.0f, -1.0f});
    CHECK(outer->GetScrollOffset().y == doctest::Approx(40.0f)); // passed on

    outer->SetScrollOffset(core::Float2{0.0f, 0.0f});
    inner->EditLayoutStyle([](LayoutStyle& st) { st.Overscroll = OverscrollBehavior::Contain; });
    root->UpdateLayout();
    CHECK(d.InjectMouseWheel(core::Float2{50.0f, 50.0f}, core::Float2{0.0f, -1.0f}));
    CHECK(outer->GetScrollOffset().y == doctest::Approx(0.0f)); // kept
}

TEST_CASE("scroll: a sheet sets scroll-behavior and overscroll-behavior")
{
    Scroller s;
    s.view->AddClass(core::StringView(u8"soft"));
    StyleManager styles(CSSParser::Parse(core::StringView(u8".soft { scroll-behavior: smooth; overscroll-behavior: contain; }")));
    styles.ApplyTree(*s.root);
    CHECK(s.view->GetLayoutStyle().Scrolling == ScrollBehavior::Smooth);
    CHECK(s.view->GetLayoutStyle().Overscroll == OverscrollBehavior::Contain);
}

TEST_CASE("scroll: a selector may ask for a part's own state after it")
{
    const StyleSelector plain(core::StringView(u8"scrollview::scrollbar-thumb"));
    const StyleSelector hovered(core::StringView(u8"scrollview::scrollbar-thumb:hover"));
    const StyleSelector held(core::StringView(u8"::scrollbar-thumb:active"));
    CHECK(hovered.PseudoElement() == core::StringView(u8"scrollbar-thumb"));
    CHECK(hovered.PartPseudoClasses() == PseudoHover);
    CHECK(held.PartPseudoClasses() == PseudoActive);
    CHECK(plain.PartPseudoClasses() == 0u);
    CHECK(hovered.Specificity() > plain.Specificity());
    // A state a part does not have matches nothing.
    CHECK(StyleSelector(core::StringView(u8"::scrollbar-thumb:focus")).RuleAt(0).IsNever());
}

TEST_CASE("scroll: the bars are ::scrollbar and ::scrollbar-thumb, styled per their own hover and drag")
{
    Scroller s;
    StyleManager styles(CSSParser::Parse(core::StringView(
        u8"scrollview::scrollbar { background-color: #101010; }"
        u8"scrollview::scrollbar-thumb { background-color: #202020; }"
        u8"scrollview::scrollbar-thumb:hover { background-color: #303030; }"
        u8"scrollview::scrollbar-thumb:active { background-color: #404040; }")));
    styles.ApplyTree(*s.root);
    const auto thumb = [&]() { return s.view->FindPartStyle(u8"scrollbar-thumb")->Box.BackgroundColor; };
    REQUIRE(s.view->FindPartStyle(u8"scrollbar") != nullptr);
    CHECK(s.view->FindPartStyle(u8"scrollbar")->Box.BackgroundColor == ParseColor(core::StringView(u8"#101010")).Value());
    CHECK(thumb() == ParseColor(core::StringView(u8"#202020")).Value());

    const Rect bar = s.view->ScrollBarThumb(1);
    const core::Float2 onThumb{bar.x + bar.width * 0.5f, bar.y + 5.0f};
    s.D().InjectMouseMove(onThumb);
    CHECK((s.view->GetPartStates(u8"scrollbar-thumb") & Node::StateHover) != 0);
    styles.ApplyTree(*s.root);
    CHECK(thumb() == ParseColor(core::StringView(u8"#303030")).Value());

    s.D().InjectMouseDown(onThumb, MouseButton::Left);
    styles.ApplyTree(*s.root);
    CHECK(thumb() == ParseColor(core::StringView(u8"#404040")).Value());
    s.D().InjectMouseUp(onThumb, MouseButton::Left);

    s.D().InjectMouseMove(core::Float2{20.0f, 20.0f}); // over the content, off the bar
    CHECK(s.view->GetPartStates(u8"scrollbar-thumb") == 0u);
    styles.ApplyTree(*s.root);
    CHECK(thumb() == ParseColor(core::StringView(u8"#202020")).Value());
}

TEST_CASE("scroll: scrollbar-width thins or hides the bars; hidden, it still scrolls")
{
    Scroller s;
    CHECK(s.view->ScrollBarTrack(1).width == doctest::Approx(8.0f));
    s.view->EditLayoutStyle([](LayoutStyle& st) { st.BarWidth = ScrollbarWidth::Thin; });
    CHECK(s.view->ScrollBarTrack(1).width == doctest::Approx(5.0f));
    s.view->EditLayoutStyle([](LayoutStyle& st) { st.BarWidth = ScrollbarWidth::None; });
    CHECK(s.view->ScrollBarTrack(1).width == doctest::Approx(0.0f));
    s.root->UpdateLayout();
    s.D().InjectMouseWheel(core::Float2{95.0f, 50.0f}, core::Float2{0.0f, -1.0f});
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(40.0f));
}

TEST_CASE("scroll: overlay bars show while it scrolls or is hovered, then fade")
{
    Scroller s;
    s.view->EditLayoutStyle([](LayoutStyle& st) { st.BarVisibility = ScrollbarVisibility::Overlay; });
    s.root->UpdateLayout();
    GUIContext& gui = s.root->GetContext();
    CHECK(s.view->GetScrollbarOpacity() == doctest::Approx(0.0f));
    s.view->ScrollBy(core::Float2{0.0f, 30.0f});
    CHECK(s.view->GetScrollbarOpacity() == doctest::Approx(1.0f));
    gui.Update(core::Duration::FromSeconds(0.5)); // lingering
    CHECK(s.view->GetScrollbarOpacity() == doctest::Approx(1.0f));
    gui.Update(core::Duration::FromSeconds(0.45)); // past the linger, fading
    CHECK(s.view->GetScrollbarOpacity() < 1.0f);
    gui.Update(core::Duration::FromSeconds(0.5));
    CHECK(s.view->GetScrollbarOpacity() == doctest::Approx(0.0f));

    // Hovered, it shows and stays.
    s.D().InjectMouseMove(core::Float2{50.0f, 50.0f});
    gui.Update(core::Duration::FromSeconds(2.0));
    CHECK(s.view->GetScrollbarOpacity() == doctest::Approx(1.0f));

    // A sheet chooses it, and the width.
    Scroller t;
    t.view->AddClass(core::StringView(u8"slim"));
    StyleManager styles(CSSParser::Parse(core::StringView(u8".slim { scrollbar-width: thin; scrollbar-visibility: overlay; }")));
    styles.ApplyTree(*t.root);
    CHECK(t.view->GetLayoutStyle().BarWidth == ScrollbarWidth::Thin);
    CHECK(t.view->GetLayoutStyle().BarVisibility == ScrollbarVisibility::Overlay);
}

namespace
{
    // The fixture's rows are their content's width (none) in a scroller on both axes; a finger
    // test needs them under it.
    void WidenRows(Scroller& s)
    {
        for (auto& row : s.rows)
            row->EditLayoutStyle([](LayoutStyle& st) { st.Width = LayoutLength::Px(80.0f); });
        s.root->UpdateLayout();
    }
}

TEST_CASE("scroll: a finger that stays put taps; one that moves pans, cancelling the press")
{
    Scroller s(10);
    WidenRows(s);
    int clicks = 0, cancels = 0;
    s.rows[1]->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });
    s.rows[1]->AddEventListener(EventType::PointerCancel, [&](const Event&) { ++cancels; });
    EventDispatcher& d = s.D();

    d.InjectTouchDown(1, core::Float2{40.0f, 70.0f}); // row 1 (50..100)
    d.InjectTouchMove(1, core::Float2{42.0f, 74.0f}); // within the slop
    d.InjectTouchUp(1, core::Float2{42.0f, 74.0f});
    CHECK(clicks == 1);
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(0.0f));

    d.InjectTouchDown(1, core::Float2{40.0f, 90.0f});
    d.InjectTouchMove(1, core::Float2{40.0f, 75.0f}); // past the slop: a pan
    CHECK(d.IsPanning());
    CHECK(cancels == 1);
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(15.0f)); // the content keeps to the finger
    d.InjectTouchMove(1, core::Float2{40.0f, 50.0f});
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(40.0f));
    d.InjectTouchUp(1, core::Float2{40.0f, 50.0f}); // let go still: no fling, no click
    CHECK_FALSE(d.IsPanning());
    CHECK_FALSE(s.view->IsFlinging());
    CHECK(clicks == 1);
}

TEST_CASE("scroll: the pan slop is in DIPs: a finger's 12-pixel wobble taps on a display of scale 2, and pans at 1")
{
    {
        Scroller s(10);
        WidenRows(s);
        s.root->SetDisplayScale(2.0f); // device pixels twice the root's units: row 1 is 100..200 down
        (void)s.root->UpdateLayout();
        int clicks = 0;
        s.rows[1]->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });
        EventDispatcher& d = s.D();
        d.InjectTouchDown(1, core::Float2{80.0f, 140.0f});
        d.InjectTouchMove(1, core::Float2{80.0f, 152.0f}); // 6 DIPs: within the 8
        CHECK_FALSE(d.IsPanning());
        d.InjectTouchUp(1, core::Float2{80.0f, 152.0f});
        CHECK(clicks == 1);
    }
    {
        Scroller s(10);
        WidenRows(s);
        EventDispatcher& d = s.D();
        d.InjectTouchDown(1, core::Float2{40.0f, 70.0f});
        d.InjectTouchMove(1, core::Float2{40.0f, 82.0f}); // 12 DIPs: past it
        CHECK(d.IsPanning());
        d.InjectTouchUp(1, core::Float2{40.0f, 82.0f});
    }
}

TEST_CASE("scroll: let go moving, a pan flings on, slowing, and a new finger catches it")
{
    Scroller s(40); // 2000 tall: room to glide
    WidenRows(s);
    GUIContext& gui = s.root->GetContext();
    EventDispatcher& d = s.D();
    int clicks = 0;
    for (auto& row : s.rows)
        row->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });

    d.InjectTouchDown(1, core::Float2{40.0f, 95.0f});
    for (int i = 1; i <= 5; ++i) // 15 px a step at 60 Hz: 900 px a second upward
    {
        gui.Update(core::Duration::FromSeconds(1.0 / 60.0));
        d.InjectTouchMove(1, core::Float2{40.0f, 95.0f - 15.0f * static_cast<float>(i)});
    }
    d.InjectTouchUp(1, core::Float2{40.0f, 20.0f});
    CHECK(s.view->IsFlinging());
    const f32 released = s.view->GetScrollOffset().y;
    CHECK(released == doctest::Approx(75.0f));
    gui.Update(core::Duration::FromSeconds(0.1));
    const f32 early = s.view->GetScrollOffset().y - released;
    gui.Update(core::Duration::FromSeconds(0.1));
    const f32 later = s.view->GetScrollOffset().y - released - early;
    CHECK(early > 0.0f);
    CHECK(later < early); // slowing

    d.InjectTouchDown(2, core::Float2{40.0f, 50.0f}); // caught
    CHECK_FALSE(s.view->IsFlinging());
    const f32 caughtAt = s.view->GetScrollOffset().y;
    d.InjectTouchUp(2, core::Float2{40.0f, 50.0f});
    gui.Update(core::Duration::FromSeconds(0.5));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(caughtAt));
    CHECK(clicks == 0); // neither the pan nor the catch clicked a row

    // Left alone, a fling stops by itself (or at the end).
    d.InjectTouchDown(3, core::Float2{40.0f, 95.0f});
    for (int i = 1; i <= 5; ++i)
    {
        gui.Update(core::Duration::FromSeconds(1.0 / 60.0));
        d.InjectTouchMove(3, core::Float2{40.0f, 95.0f - 15.0f * static_cast<float>(i)});
    }
    d.InjectTouchUp(3, core::Float2{40.0f, 20.0f});
    for (int i = 0; i < 200 && s.view->IsFlinging(); ++i)
        gui.Update(core::Duration::FromSeconds(1.0 / 60.0));
    CHECK_FALSE(s.view->IsFlinging());
}

TEST_CASE("scroll: only a finger pans; a sideways finger over a scroller that cannot move across presses on")
{
    Scroller s(10);
    WidenRows(s);
    EventDispatcher& d = s.D();
    d.InjectMouseDown(core::Float2{40.0f, 90.0f}, MouseButton::Left);
    d.InjectMouseMove(core::Float2{40.0f, 40.0f});
    d.InjectMouseUp(core::Float2{40.0f, 40.0f}, MouseButton::Left);
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(0.0f));

    int cancels = 0;
    s.rows[1]->AddEventListener(EventType::PointerCancel, [&](const Event&) { ++cancels; });
    d.InjectTouchDown(1, core::Float2{20.0f, 70.0f});
    d.InjectTouchMove(1, core::Float2{60.0f, 72.0f}); // across: nothing scrolls that way
    CHECK_FALSE(d.IsPanning());
    CHECK(cancels == 0);
    d.InjectTouchUp(1, core::Float2{60.0f, 72.0f});
}

TEST_CASE("scroll: a pad's right stick scrolls the nearest scroller around the focus")
{
    Scroller s(40);
    GUIContext& gui = s.root->GetContext();
    EventDispatcher& d = s.D();
    d.SetFocusNode(s.rows[0].Get());

    d.SetScrollStick(core::Float2{0.0f, 0.15f}); // within the dead zone
    gui.Update(core::Duration::FromSeconds(0.1));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(0.0f));

    d.SetScrollStick(core::Float2{0.0f, 1.0f}); // all the way: 1400 px a second
    gui.Update(core::Duration::FromSeconds(0.1));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(140.0f));

    d.SetScrollStick(core::Float2{0.0f, -0.6f}); // half way past the dead zone, squared: a quarter
    gui.Update(core::Duration::FromSeconds(0.1));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(140.0f - 35.0f));

    d.SetScrollStick(core::Float2{0.0f, 0.0f}); // let go
    gui.Update(core::Duration::FromSeconds(0.1));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(105.0f));

    // With no focus, the scroller under the pointer.
    d.SetFocusNode(nullptr);
    d.InjectMouseMove(core::Float2{40.0f, 40.0f});
    d.SetScrollStick(core::Float2{0.0f, 1.0f});
    gui.Update(core::Duration::FromSeconds(0.05));
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(175.0f));
}

TEST_CASE("scroll: stuck to its end, it follows the content; scrolled away it lets go, and back it holds again")
{
    Scroller s(1); // 50 of content in a 100 view: at its end
    s.view->SetStickToEnd(true);
    CHECK(s.view->IsLatchedToEnd());
    const auto addRows = [&](int count)
    {
        for (int i = 0; i < count; ++i)
        {
            s.rows.PushBack(Make<Panel>());
            s.rows[s.rows.Size() - 1]->EditLayoutStyle([](LayoutStyle& st) { st.Height = LayoutLength::Px(50.0f); });
            s.view->AddChild(s.rows[s.rows.Size() - 1].Get());
        }
        s.root->UpdateLayout();
    };
    addRows(3); // 200 of content: the end is 100
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(100.0f));
    addRows(1);
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(150.0f));

    s.view->ScrollBy(core::Float2{0.0f, -60.0f}); // away: it lets go
    CHECK_FALSE(s.view->IsLatchedToEnd());
    addRows(1);
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(90.0f));

    s.view->ScrollToEnd(); // back: it holds again
    CHECK(s.view->IsLatchedToEnd());
    addRows(2);
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(300.0f));
}

TEST_CASE("scroll: content clipped away takes no press: a row below the view is not hit beneath it")
{
    Scroller s; // a 100 x 100 view of six 50-high rows: rows 2 to 5 lie below it, clipped
    WidenRows(s);
    Node* hit = s.root->OverFind(core::Float2{20.0f, 150.0f});
    CHECK(hit != s.rows[3].Get());
    CHECK(hit == s.root.Get()); // what lies beyond the view there: the root
    CHECK(s.root->OverFind(core::Float2{20.0f, 20.0f}) == s.rows[0].Get()); // inside, the row
}

TEST_CASE("scroll: a pan moves the content with the finger at a display scale, in the view's own units")
{
    Scroller s(10);
    WidenRows(s);
    s.root->SetDisplayScale(2.0f); // a finger moves in device pixels, twice the view's units
    s.root->UpdateLayout();
    EventDispatcher& d = s.D();
    d.InjectTouchDown(1, core::Float2{80.0f, 180.0f});
    d.InjectTouchMove(1, core::Float2{80.0f, 150.0f}); // 30 device pixels up: 15 of the view's
    REQUIRE(d.IsPanning());
    CHECK(s.view->GetScrollOffset().y == doctest::Approx(15.0f));
    d.InjectTouchUp(1, core::Float2{80.0f, 150.0f});
}
