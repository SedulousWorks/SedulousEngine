// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - direction (E9b of Specs/gui-lab-evolution.md): a node runs as the first ancestor that says
// does, else as the GUI's language is written; right to left mirrors flex rows, a column's cross
// start, grid columns and a stack's start, margins staying on the sides their style names; dock
// stays physical, its start and end sides following the direction; the logical margins, paddings
// and insets land on the sides the direction puts them on; a scroller's bar goes to the inline end;
// a slider, a tab strip and a menu bar take Left and Right along the way they run; mirror-on-rtl
// flips a node's drawing; text runs as its node does, and CSS's `direction` sets it.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.i18n;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace i18n = foundation::i18n;
using core::f32;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    template <typename... T>
    core::Array<GridTrack> Tracks(T... tracks)
    {
        core::Array<GridTrack> out;
        (out.PushBack(tracks), ...);
        return out;
    }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        Bed() { root->SetSize(core::Float2{100.0f, 100.0f}); }
        void Layout() { root->UpdateLayout(); }
    };
    template <typename F>
    core::RefPtr<Panel> Box(Node& parent, F&& style)
    {
        auto panel = core::MakeRef<Panel>(core::DefaultAllocator());
        panel->EditLayoutStyle(static_cast<F&&>(style));
        parent.AddChild(panel.Get());
        return panel;
    }
    core::RefPtr<Panel> Fixed(Node& parent, f32 w, f32 h)
    {
        return Box(parent, [w, h](LayoutStyle& s) {
            s.Width = LayoutLength::Px(w);
            s.Height = LayoutLength::Px(h);
        });
    }
}

TEST_CASE("direction: a node runs as the first ancestor that says, else as the GUI's language is written")
{
    i18n::StringTable table;
    REQUIRE(table.AddLocale(SV(u8"en")));
    REQUIRE(table.AddLocale(SV(u8"ar")));
    table.SetDirection(SV(u8"ar"), i18n::TextDirection::RightToLeft);
    i18n::Localization loc;
    loc.AddTable(&table);
    Bed bed;
    bed.root->GetContext().SetLocalization(&loc);
    auto page = Box(*bed.root.Get(), [](LayoutStyle&) {});
    auto fixedLtr = Box(*page.Get(), [](LayoutStyle&) {});
    fixedLtr->SetLayoutDirection(Node::LayoutDirection::LeftToRight);
    auto inside = Box(*fixedLtr.Get(), [](LayoutStyle&) {});
    CHECK_FALSE(page->IsRightToLeft());
    loc.SetLanguage(SV(u8"ar-EG"));
    CHECK(page->IsRightToLeft());
    CHECK_FALSE(inside->IsRightToLeft()); // its ancestor says
    fixedLtr->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    CHECK(inside->IsRightToLeft());
    CHECK(fixedLtr->GetDirectionName() == core::String(u8"rtl"));
}

TEST_CASE("direction: a right-to-left row runs from the right, its margins on the sides they name")
{
    Bed bed;
    auto row = Box(*bed.root.Get(), [](LayoutStyle& s) { s.Direction = FlexDirection::Row; s.ColumnGap = 5.0f; });
    auto a = Fixed(*row.Get(), 20.0f, 10.0f);
    auto b = Fixed(*row.Get(), 20.0f, 10.0f);
    b->SetMargin(Thickness{0.0f, 0.0f, 8.0f, 0.0f}); // left, top, right, bottom
    bed.Layout();
    CHECK(a->GetPosition().x == doctest::Approx(0.0f));
    CHECK(b->GetPosition().x == doctest::Approx(25.0f));
    row->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    bed.Layout();
    CHECK(a->GetPosition().x == doctest::Approx(80.0f));
    CHECK(b->GetPosition().x == doctest::Approx(80.0f - 5.0f - 8.0f - 20.0f)); // its right margin between it and a
    row->SetLayoutDirection(Node::LayoutDirection::Inherit);
    bed.Layout();
    CHECK(a->GetPosition().x == doctest::Approx(0.0f));
}

TEST_CASE("direction: a column's cross start, grid columns and a stack's start mirror; dock does not")
{
    Bed bed;
    auto page = Box(*bed.root.Get(), [](LayoutStyle&) {});
    page->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    auto column = Box(*page.Get(), [](LayoutStyle& s) { s.AlignItems = Align::Start; });
    auto inColumn = Fixed(*column.Get(), 30.0f, 10.0f);
    auto grid = Box(*page.Get(), [](LayoutStyle& s) {
        s.Kind = Display::Grid;
        s.Columns = Tracks(GridTrack::Fixed(40.0f), GridTrack::Fixed(40.0f));
    });
    auto first = Fixed(*grid.Get(), 40.0f, 10.0f);
    auto second = Fixed(*grid.Get(), 40.0f, 10.0f);
    auto stack = Box(*page.Get(), [](LayoutStyle& s) { s.Kind = Display::Stack; s.JustifyItems = Align::Start; });
    auto inStack = Fixed(*stack.Get(), 10.0f, 10.0f);
    auto dock = Box(*page.Get(), [](LayoutStyle& s) { s.Kind = Display::Dock; s.Height = LayoutLength::Px(20.0f); });
    auto docked = Box(*dock.Get(), [](LayoutStyle& s) { s.DockSide = Dock::Left; s.Width = LayoutLength::Px(15.0f); });
    bed.Layout();
    CHECK(inColumn->GetPosition().x == doctest::Approx(70.0f));
    CHECK(first->GetPosition().x == doctest::Approx(60.0f));
    CHECK(second->GetPosition().x == doctest::Approx(20.0f));
    CHECK(inStack->GetPosition().x == doctest::Approx(90.0f));
    CHECK(docked->GetPosition().x == doctest::Approx(0.0f)); // left is left
}

TEST_CASE("direction: CSS's direction sets it; text-align start and end follow it")
{
    Bed bed;
    auto page = core::MakeRef<Panel>(core::DefaultAllocator());
    page->AddClass(SV(u8"page"));
    bed.root->AddChild(page.Get());
    auto label = core::MakeRef<Label>(core::DefaultAllocator());
    label->AddClass(SV(u8"start"));
    page->AddChild(label.Get());
    auto other = core::MakeRef<Label>(core::DefaultAllocator());
    other->AddClass(SV(u8"end"));
    page->AddChild(other.Get());
    StyleManager styles(CSSParser::Parse(SV(u8".start { text-align: start; } .end { text-align: end; }")));
    styles.ApplyTree(*bed.root.Get());
    CHECK(label->GetTextAlignH() == TextHAlign::Start); // the paragraph's direction places them (E9c)
    CHECK(other->GetTextAlignH() == TextHAlign::End);
    CHECK(label->GetTextLayout().GetDirection().Direction == foundation::fonts::TextDirection::LeftToRight);
    styles.SetStyleSheet(CSSParser::Parse(SV(u8".page { direction: rtl; } .start { text-align: start; } .end { text-align: end; }")));
    styles.ApplyTree(*bed.root.Get());
    CHECK(page->GetLayoutDirection() == Node::LayoutDirection::RightToLeft);
    CHECK(label->GetTextLayout().GetDirection().Direction == foundation::fonts::TextDirection::RightToLeft); // its text runs as it does
    styles.SetStyleSheet(CSSParser::Parse(SV(u8".start { text-align: start; }")));
    styles.ApplyTree(*bed.root.Get());
    CHECK(page->GetLayoutDirection() == Node::LayoutDirection::Inherit); // the sheet no longer says
    CHECK(label->GetTextLayout().GetDirection().Direction == foundation::fonts::TextDirection::LeftToRight);
}

TEST_CASE("direction: inline start and end margins, paddings and insets land on the sides the direction puts them on")
{
    Bed bed;
    auto page = core::MakeRef<Panel>(core::DefaultAllocator());
    page->AddClass(SV(u8"page"));
    bed.root->AddChild(page.Get());
    auto item = core::MakeRef<Panel>(core::DefaultAllocator());
    item->AddClass(SV(u8"item"));
    page->AddChild(item.Get());
    auto pinned = core::MakeRef<Panel>(core::DefaultAllocator());
    pinned->AddClass(SV(u8"pinned"));
    page->AddChild(pinned.Get());
    const char8_t* const rules = u8".item { margin-inline: 4 6; padding-inline-start: 3; margin-left: 50; } "
                                 u8".pinned { position: absolute; inset-inline-start: 7; }";
    StyleManager styles(CSSParser::Parse(SV(rules)));
    styles.ApplyTree(*bed.root.Get());
    CHECK(item->GetMargin().Left == doctest::Approx(4.0f)); // the logical side wins over margin-left
    CHECK(item->GetMargin().Right == doctest::Approx(6.0f));
    CHECK(item->GetPadding().Left == doctest::Approx(3.0f));
    CHECK(pinned->GetLayoutStyle().Left.Resolve(0.0f).ValueOr(-1.0f) == doctest::Approx(7.0f));

    core::String rtl(u8".page { direction: rtl; } ");
    rtl.Append(SV(rules));
    styles.SetStyleSheet(CSSParser::Parse(rtl.AsView()));
    styles.ApplyTree(*bed.root.Get());
    CHECK(item->GetMargin().Right == doctest::Approx(4.0f));
    CHECK(item->GetMargin().Left == doctest::Approx(6.0f));
    CHECK(item->GetPadding().Right == doctest::Approx(3.0f));
    CHECK(item->GetPadding().Left == doctest::Approx(0.0f));
    CHECK(pinned->GetLayoutStyle().Right.Resolve(0.0f).ValueOr(-1.0f) == doctest::Approx(7.0f));
}

TEST_CASE("direction: dock's start and end are left and right, swapped in right to left")
{
    Bed bed;
    auto dock = Box(*bed.root.Get(), [](LayoutStyle& s) { s.Kind = Display::Dock; s.Height = LayoutLength::Px(20.0f); });
    auto start = Box(*dock.Get(), [](LayoutStyle& s) { s.DockSide = Dock::Start; s.Width = LayoutLength::Px(15.0f); });
    auto end = Box(*dock.Get(), [](LayoutStyle& s) { s.DockSide = Dock::End; s.Width = LayoutLength::Px(10.0f); });
    bed.Layout();
    CHECK(start->GetPosition().x == doctest::Approx(0.0f));
    CHECK(end->GetPosition().x == doctest::Approx(90.0f));
    dock->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    bed.Layout();
    CHECK(start->GetPosition().x == doctest::Approx(85.0f));
    CHECK(end->GetPosition().x == doctest::Approx(0.0f));
}

TEST_CASE("direction: a scroller's vertical bar goes to the inline end; a slider runs from it, by pointer and keys")
{
    Bed bed;
    bed.root->SetSize(core::Float2{300.0f, 300.0f});
    auto view = core::MakeRef<ScrollView>(core::DefaultAllocator());
    view->SetSize(core::Float2{100.0f, 100.0f});
    bed.root->AddChild(view.Get());
    for (int i = 0; i < 4; ++i)
        Fixed(*view.Get(), 80.0f, 50.0f);
    bed.Layout();
    CHECK(view->ScrollBarTrack(1).x == doctest::Approx(92.0f));
    view->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    bed.Layout();
    CHECK(view->ScrollBarTrack(1).x == doctest::Approx(0.0f));

    auto slider = core::MakeRef<Slider>(core::DefaultAllocator());
    slider->SetSize(core::Float2{100.0f, 20.0f}); // the thumb's centre within x 10 to 90
    slider->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    bed.root->AddChild(slider.Get());
    bed.Layout();
    slider->SetStep(0.05);
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    const core::Float2 at{slider->GetScreenBounds().x + 30.0f, slider->GetScreenBounds().y + 10.0f};
    d.InjectMouseDown(at, MouseButton::Left);
    d.InjectMouseUp(at, MouseButton::Left);
    CHECK(slider->GetValue() == doctest::Approx(0.75)); // a quarter in from the right end, its start
    slider->RequestFocus();
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Left));
    CHECK(slider->GetValue() == doctest::Approx(0.8)); // Left goes on, towards the end
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    CHECK(slider->GetValue() == doctest::Approx(0.75));
}

TEST_CASE("direction: a right-to-left tab strip runs from the right; Left goes on to the next tab")
{
    Bed bed;
    bed.root->SetSize(core::Float2{400.0f, 300.0f});
    auto bar = core::MakeRef<TabBar>(core::DefaultAllocator());
    bar->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    bed.root->AddChild(bar.Get());
    const char8_t* const names[] = {u8"A", u8"B", u8"C"};
    for (const char8_t* t : names)
    {
        Tab* tab = bar->AddTab(SV(t));
        tab->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(60.0f); s.Height = LayoutLength::Px(24.0f); });
    }
    bed.Layout();
    CHECK(bar->GetTab(0)->GetScreenBounds().x > bar->GetTab(1)->GetScreenBounds().x);
    bar->GetTab(0)->RequestFocus();
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Left));
    CHECK(bar->GetSelectedIndex() == 1);
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    CHECK(bar->GetSelectedIndex() == 0);
}

TEST_CASE("direction: mirror-on-rtl flips a node's drawing about its centre, only while it runs right to left")
{
    Bed bed;
    auto page = Box(*bed.root.Get(), [](LayoutStyle& s) { s.Direction = FlexDirection::Row; });
    auto icon = Fixed(*page.Get(), 20.0f, 10.0f);
    icon->SetMirrorOnRtl(true);
    bed.Layout();
    CHECK_FALSE(icon->IsMirrored());
    CHECK(icon->ConvertToWorldSpace(core::Float2{0.0f, 0.0f}).x == doctest::Approx(0.0f));
    page->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    bed.Layout();
    CHECK(icon->IsMirrored());
    // At x 80 to 100 now: its own left edge drawn at its right.
    CHECK(icon->ConvertToWorldSpace(core::Float2{0.0f, 0.0f}).x == doctest::Approx(100.0f));
    CHECK(icon->ConvertToWorldSpace(core::Float2{20.0f, 0.0f}).x == doctest::Approx(80.0f));
    page->SetLayoutDirection(Node::LayoutDirection::LeftToRight);
    bed.Layout();
    CHECK_FALSE(icon->IsMirrored());
}

TEST_CASE("direction: a right-to-left menu bar's Left goes on to the next menu")
{
    Bed bed;
    bed.root->SetSize(core::Float2{600.0f, 400.0f});
    auto bar = core::MakeRef<MenuBar>(core::DefaultAllocator());
    bar->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    bed.root->AddChild(bar.Get());
    const char8_t* const names[] = {u8"File", u8"Edit", u8"View"};
    for (const char8_t* name : names)
        bar->AddMenu(SV(name))->AddItem(SV(u8"Item"), [] {});
    bed.Layout();
    CHECK(bar->ButtonAt(0)->GetScreenBounds().x > bar->ButtonAt(1)->GetScreenBounds().x);
    bar->ButtonAt(0)->RequestFocus();
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Left));
    CHECK(bar->ButtonAt(1)->IsFocused());
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    CHECK(bar->ButtonAt(0)->IsFocused());
}

TEST_CASE("direction: the arrow toward the inline end is a step on, the other a step back")
{
    Bed bed;
    auto part = core::MakeRef<UIWidget>(core::DefaultAllocator());
    bed.root->AddChild(part.Get());
    CHECK(part->InlineStep(KeyCode::Right) == 1);
    CHECK(part->InlineStep(KeyCode::Left) == -1);
    CHECK(part->InlineStep(KeyCode::Up) == 0);
    part->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    CHECK(part->InlineStep(KeyCode::Left) == 1);
    CHECK(part->InlineStep(KeyCode::Right) == -1);
}

TEST_CASE("direction: a right-to-left submenu opens to the left; Left goes into it and Right comes back")
{
    Bed bed;
    bed.root->SetSize(core::Float2{600.0f, 400.0f});
    bed.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    auto anchor = core::MakeRef<UIWidget>(core::DefaultAllocator());
    bed.root->AddChild(anchor.Get());
    auto menu = core::MakeRef<Menu>(core::DefaultAllocator());
    menu->SetWidth(160.0f);
    menu->SetItemHeight(26.0f);
    Menu* sub = menu->AddSubMenu(SV(u8"More"));
    sub->AddItem(SV(u8"Deep"), [] {});
    menu->Open(*anchor, core::Float2{400.0f, 50.0f});
    bed.Layout();
    // A context menu at a point opens toward the left of it.
    CHECK(menu->ConvertToRootSpace(core::Float2{0.0f, 0.0f}).x == doctest::Approx(240.0f));
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    menu->FocusFirstItem();
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Left));
    REQUIRE(sub->IsOpen());
    bed.Layout();
    // At its item's inline end: the menu's left edge.
    CHECK(sub->ConvertToRootSpace(core::Float2{sub->GetSize().x, 0.0f}).x == doctest::Approx(240.0f));
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    CHECK_FALSE(sub->IsOpen());
}

TEST_CASE("direction: a right-to-left scroller starts at its inline start, its offset 0 there and negative toward the left")
{
    Bed bed;
    bed.root->SetSize(core::Float2{300.0f, 300.0f});
    bed.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    auto strip = Box(*bed.root.Get(), [](LayoutStyle& s) {
        s.Direction = FlexDirection::Row;
        s.OverflowX = Overflow::Auto;
        s.Width = LayoutLength::Px(100.0f);
        s.Height = LayoutLength::Px(60.0f);
    });
    core::RefPtr<Panel> cells[4];
    for (auto& cell : cells)
        cell = Box(*strip.Get(), [](LayoutStyle& s) { s.Width = LayoutLength::Px(80.0f); s.Shrink = 0.0f; });
    bed.Layout();
    const Rect box = strip->GetContentBounds();

    // At the start: the first cell against the right edge, the rest past the left (CSS's model).
    CHECK(strip->GetScrollOffset().x == doctest::Approx(0.0f));
    CHECK(strip->GetScrollMin().x == doctest::Approx(-220.0f));
    CHECK(strip->GetScrollMax().x == doctest::Approx(0.0f));
    CHECK(cells[0]->GetPosition().x + 80.0f == doctest::Approx(box.x + box.width));
    CHECK(cells[3]->GetPosition().x == doctest::Approx(box.x - 220.0f));
    // The thumb at the right, where the content starts.
    const Rect track = strip->ScrollBarTrack(0);
    const Rect thumb = strip->ScrollBarThumb(0);
    CHECK(thumb.x + thumb.width == doctest::Approx(track.x + track.width));

    // Clamped to [-range, 0]; the end is the left.
    strip->SetScrollOffset(core::Float2{50.0f, 0.0f});
    CHECK(strip->GetScrollOffset().x == doctest::Approx(0.0f));
    strip->SetScrollOffset(core::Float2{-1000.0f, 0.0f});
    CHECK(strip->GetScrollOffset().x == doctest::Approx(-220.0f));
    CHECK(strip->IsAtScrollEnd());
    CHECK(strip->ScrollBarThumb(0).x == doctest::Approx(track.x));
    strip->SetScrollOffset(core::Float2{0.0f, 0.0f});
    strip->ScrollToEnd(ScrollBehavior::Instant);
    CHECK(strip->GetScrollOffset().x == doctest::Approx(-220.0f));

    // A vertical wheel notch down goes toward the inline end.
    strip->SetScrollOffset(core::Float2{0.0f, 0.0f});
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    const core::Float2 over = strip->ConvertToRootSpace(core::Float2{50.0f, 20.0f});
    d.InjectMouseWheel(over, core::Float2{0.0f, -1.0f});
    CHECK(strip->GetScrollOffset().x < 0.0f);

    // Content added at the end leaves the start where it was.
    strip->SetScrollOffset(core::Float2{0.0f, 0.0f});
    auto more = Box(*strip.Get(), [](LayoutStyle& s) { s.Width = LayoutLength::Px(80.0f); s.Shrink = 0.0f; });
    bed.Layout();
    CHECK(strip->GetScrollOffset().x == doctest::Approx(0.0f));
    CHECK(strip->GetScrollMin().x == doctest::Approx(-300.0f));
    CHECK(cells[0]->GetPosition().x + 80.0f == doctest::Approx(box.x + box.width));
}

TEST_CASE("direction: a right-to-left scroller held at its end follows it as the content grows")
{
    Bed bed;
    bed.root->SetSize(core::Float2{300.0f, 300.0f});
    bed.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    auto strip = Box(*bed.root.Get(), [](LayoutStyle& s) {
        s.Direction = FlexDirection::Row;
        s.OverflowX = Overflow::Auto;
        s.Width = LayoutLength::Px(100.0f);
        s.Height = LayoutLength::Px(60.0f);
    });
    for (int i = 0; i < 3; ++i)
        Box(*strip.Get(), [](LayoutStyle& s) { s.Width = LayoutLength::Px(80.0f); s.Shrink = 0.0f; });
    bed.Layout();
    strip->ScrollToEnd(ScrollBehavior::Instant);
    strip->SetStickToEnd(true);
    REQUIRE(strip->IsLatchedToEnd());
    Box(*strip.Get(), [](LayoutStyle& s) { s.Width = LayoutLength::Px(80.0f); s.Shrink = 0.0f; });
    bed.Layout();
    CHECK(strip->GetScrollOffset().x == doctest::Approx(-220.0f));
}

TEST_CASE("direction: content wider than a right-to-left row overflows toward its inline end, the left")
{
    Bed bed;
    bed.root->SetSize(core::Float2{300.0f, 300.0f});
    bed.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    auto row = Box(*bed.root.Get(), [](LayoutStyle& s) {
        s.Direction = FlexDirection::Row;
        s.Width = LayoutLength::Px(100.0f);
        s.Height = LayoutLength::Px(20.0f);
    });
    auto wide = Box(*row.Get(), [](LayoutStyle& s) { s.Width = LayoutLength::Px(130.0f); s.Shrink = 0.0f; });
    bed.Layout();
    // As CSS has it: its start against the row's right edge, the 30 past it on the left.
    CHECK(wide->GetPosition().x == doctest::Approx(-30.0f));
}
