// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - directional navigation (G7 of Specs/vg-and-gui-lab.md): the geometric picker over grids
// and irregular layouts, focus scopes (pass, wrap, contain, focus memory, default focus), widgets
// that use the arrows and give them back at their ends, and activation by Return.
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

    // A focusable widget at (x, y), 40 x 20, id `id`.
    core::RefPtr<Button> Cell(Node& parent, const char8_t* id, float x, float y, float w = 40.0f, float h = 20.0f)
    {
        auto b = Make<Button>();
        b->SetId(SV(id));
        b->SetPosition(core::Float2{x, y});
        b->SetSize(core::Float2{w, h});
        parent.AddChild(b.Get());
        return b;
    }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        EventDispatcher& d = *root->GetEventDispatcher();
        Bed() { root->SetSize(core::Float2{400.0f, 400.0f}); }
        [[nodiscard]] core::StringView Focused() const
        {
            const UIWidget* w = core::Cast<UIWidget>(d.GetFocusNode());
            return w != nullptr ? w->GetId() : SV(u8"");
        }
        void Key(KeyCode key) { d.InjectKeyDown(static_cast<core::u32>(key)); }
    };
}

TEST_CASE("navigation: a grid moves by rows and columns, and stops at its edges")
{
    Bed bed;
    // a b c
    // d e f
    const char8_t* ids[6] = {u8"a", u8"b", u8"c", u8"d", u8"e", u8"f"};
    core::RefPtr<Button> cells[6];
    for (int i = 0; i < 6; ++i)
        cells[i] = Cell(*bed.root.Get(), ids[i], 10.0f + 60.0f * (i % 3), 10.0f + 40.0f * (i / 3));

    bed.Key(KeyCode::Down); // nothing focused: the first
    CHECK(bed.Focused() == SV(u8"a"));
    bed.Key(KeyCode::Right);
    CHECK(bed.Focused() == SV(u8"b"));
    bed.Key(KeyCode::Down);
    CHECK(bed.Focused() == SV(u8"e"));
    bed.Key(KeyCode::Right);
    CHECK(bed.Focused() == SV(u8"f"));
    bed.Key(KeyCode::Right); // the edge
    CHECK(bed.Focused() == SV(u8"f"));
    bed.Key(KeyCode::Up);
    CHECK(bed.Focused() == SV(u8"c"));
}

TEST_CASE("navigation: an overlapping neighbour beats a diagonally nearer one")
{
    Bed bed;
    auto from = Cell(*bed.root.Get(), u8"from", 100.0f, 100.0f);
    auto diagonal = Cell(*bed.root.Get(), u8"diagonal", 150.0f, 130.0f); // nearer, but off the row
    auto row = Cell(*bed.root.Get(), u8"row", 260.0f, 100.0f);           // farther, on the row
    bed.d.SetFocusNode(from.Get());
    bed.Key(KeyCode::Right);
    CHECK(bed.Focused() == SV(u8"row"));

    // Irregular: with nothing on the row, the nearest beyond wins.
    row->SetVisible(false);
    bed.d.SetFocusNode(from.Get());
    bed.Key(KeyCode::Right);
    CHECK(bed.Focused() == SV(u8"diagonal"));
}

TEST_CASE("navigation: hidden, disabled and clipped-away widgets are skipped")
{
    Bed bed;
    auto from = Cell(*bed.root.Get(), u8"from", 10.0f, 10.0f);
    auto hidden = Cell(*bed.root.Get(), u8"hidden", 10.0f, 40.0f);
    auto disabled = Cell(*bed.root.Get(), u8"disabled", 10.0f, 70.0f);
    auto box = Make<UIWidget>();
    box->SetPosition(core::Float2{0.0f, 100.0f});
    box->SetSize(core::Float2{60.0f, 30.0f});
    box->SetClipChildren(true);
    bed.root->AddChild(box.Get());
    auto clipped = Cell(*box.Get(), u8"clipped", 10.0f, 200.0f); // outside its parent's clip
    auto target = Cell(*bed.root.Get(), u8"target", 10.0f, 160.0f);
    hidden->SetVisible(false);
    disabled->SetEnabled(false);
    bed.d.SetFocusNode(from.Get());
    bed.Key(KeyCode::Down);
    CHECK(bed.Focused() == SV(u8"target"));
}

TEST_CASE("navigation: scopes pass, wrap and contain; coming back returns to the remembered widget")
{
    Bed bed;
    auto menu = Make<UIWidget>(); // a column on the left
    menu->SetSize(core::Float2{100.0f, 200.0f});
    bed.root->AddChild(menu.Get());
    menu->SetNavScope(NavScope::Wrap);
    auto one = Cell(*menu.Get(), u8"one", 10.0f, 10.0f);
    auto two = Cell(*menu.Get(), u8"two", 10.0f, 40.0f);
    auto three = Cell(*menu.Get(), u8"three", 10.0f, 70.0f);
    auto side = Cell(*bed.root.Get(), u8"side", 200.0f, 40.0f); // outside the menu, to its right

    bed.d.SetFocusNode(three.Get());
    bed.Key(KeyCode::Down); // wraps to the top
    CHECK(bed.Focused() == SV(u8"one"));
    bed.Key(KeyCode::Up); // and back round
    CHECK(bed.Focused() == SV(u8"three"));

    // A pass scope hands an edge on: Right finds nothing inside the menu, so the widget beside it.
    menu->SetNavScope(NavScope::Pass);
    bed.d.SetFocusNode(two.Get());
    bed.Key(KeyCode::Right);
    CHECK(bed.Focused() == SV(u8"side"));
    bed.Key(KeyCode::Left); // back into the menu: the remembered widget, not the nearest
    CHECK(bed.Focused() == SV(u8"two"));

    menu->SetNavScope(NavScope::Contain);
    bed.Key(KeyCode::Right); // a dialog's edge
    CHECK(bed.Focused() == SV(u8"two"));
}

TEST_CASE("navigation: entering a scope with no memory takes its default focus")
{
    Bed bed;
    auto start = Cell(*bed.root.Get(), u8"start", 10.0f, 10.0f);
    auto panel = Make<UIWidget>();
    panel->SetPosition(core::Float2{0.0f, 100.0f});
    panel->SetSize(core::Float2{300.0f, 100.0f});
    panel->SetNavScope(NavScope::Pass);
    panel->SetDefaultFocusId(SV(u8"ok"));
    bed.root->AddChild(panel.Get());
    auto cancel = Cell(*panel.Get(), u8"cancel", 10.0f, 10.0f); // nearest from above
    auto ok = Cell(*panel.Get(), u8"ok", 200.0f, 10.0f);
    bed.d.SetFocusNode(start.Get());
    bed.Key(KeyCode::Down);
    CHECK(bed.Focused() == SV(u8"ok"));
}

TEST_CASE("navigation: a modal confines it")
{
    Bed bed;
    auto behind = Cell(*bed.root.Get(), u8"behind", 10.0f, 10.0f);
    auto dialog = Make<UIWidget>();
    dialog->SetPosition(core::Float2{100.0f, 100.0f});
    dialog->SetSize(core::Float2{200.0f, 100.0f});
    auto yes = Cell(*dialog.Get(), u8"yes", 10.0f, 10.0f);
    auto no = Cell(*dialog.Get(), u8"no", 100.0f, 10.0f);
    PopupOptions modal;
    modal.Kind = PopupKind::Manual;
    modal.Modal = true;
    bed.d.OpenPopup(*bed.root, *dialog, core::Move(modal));
    CHECK(bed.Focused() == SV(u8"yes")); // focus moves in: the modal's first
    bed.Key(KeyCode::Right);
    CHECK(bed.Focused() == SV(u8"no"));
    bed.Key(KeyCode::Up); // the widget behind is out of reach
    CHECK(bed.Focused() == SV(u8"no"));
}

TEST_CASE("navigation: a slider keeps its arrows at its ends; a list gives them back")
{
    Bed bed;
    auto slider = Make<Slider>();
    slider->SetPosition(core::Float2{10.0f, 10.0f});
    slider->SetSize(core::Float2{100.0f, 20.0f});
    bed.root->AddChild(slider.Get());
    auto after = Cell(*bed.root.Get(), u8"after", 200.0f, 10.0f);
    bed.d.SetFocusNode(slider.Get());
    slider->SetValue(0.9f);
    bed.Key(KeyCode::Right);
    CHECK(slider->GetValue() == doctest::Approx(0.95f));
    bed.Key(KeyCode::Right);
    bed.Key(KeyCode::Right); // at 1: still the slider's (holding to the end must not leave it)
    CHECK(slider->GetValue() == doctest::Approx(1.0f));
    CHECK(bed.d.GetFocusNode() == slider.Get());

    auto list = Make<ListBox>();
    list->SetPosition(core::Float2{10.0f, 100.0f});
    list->SetSize(core::Float2{100.0f, 80.0f});
    list->AddItem(SV(u8"x"));
    list->AddItem(SV(u8"y"));
    bed.root->AddChild(list.Get());
    auto below = Cell(*bed.root.Get(), u8"below", 10.0f, 250.0f);
    bed.d.SetFocusNode(list.Get());
    list->SetSelectedIndex(0);
    bed.Key(KeyCode::Down);
    CHECK(list->GetSelectedIndex() == 1);
    CHECK(bed.d.GetFocusNode() == list.Get());
    bed.Key(KeyCode::Down); // at the end: given back
    CHECK(bed.Focused() == SV(u8"below"));
}

TEST_CASE("navigation: Return activates the focused button as a click does")
{
    Bed bed;
    auto go = Cell(*bed.root.Get(), u8"go", 10.0f, 10.0f);
    int clicks = 0;
    (void)go->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });
    auto check = Make<CheckBox>();
    check->SetPosition(core::Float2{10.0f, 60.0f});
    check->SetSize(core::Float2{20.0f, 20.0f});
    bed.root->AddChild(check.Get());

    bed.d.SetFocusNode(go.Get());
    bed.Key(KeyCode::Return);
    CHECK(clicks == 1);
    bed.d.SetFocusNode(check.Get());
    bed.Key(KeyCode::Space);
    CHECK(check->IsChecked());
}

TEST_CASE("navigation: overrides from a sheet, markup and native code come first")
{
    Bed bed;
    auto a = Cell(*bed.root.Get(), u8"a", 10.0f, 10.0f);
    auto b = Cell(*bed.root.Get(), u8"b", 10.0f, 40.0f);
    auto c = Cell(*bed.root.Get(), u8"c", 300.0f, 300.0f);
    // A sheet: down from a goes to c (geometry would say b); right from b stops.
    StyleManager styles(CSSParser::Parse(SV(u8"#a { nav-down: c; } #b { nav-right: none; nav-next: a; }")));
    styles.ApplyTree(*bed.root.Get());
    CHECK(a->GetNavDown() == SV(u8"c"));
    bed.d.SetFocusNode(a.Get());
    bed.Key(KeyCode::Down);
    CHECK(bed.Focused() == SV(u8"c"));
    bed.d.SetFocusNode(b.Get());
    bed.Key(KeyCode::Right);
    CHECK(bed.Focused() == SV(u8"b"));
    bed.Key(KeyCode::Tab); // nav-next
    CHECK(bed.Focused() == SV(u8"a"));

    // An id that is not there, or auto: the picker as usual.
    a->SetNavDown(SV(u8"nowhere"));
    bed.d.SetFocusNode(a.Get());
    bed.Key(KeyCode::Down);
    CHECK(bed.Focused() == SV(u8"b"));

    // A scope's kind and default focus from a sheet.
    auto panel = Make<UIWidget>();
    panel->SetId(SV(u8"panel"));
    bed.root->AddChild(panel.Get());
    StyleManager scopes(CSSParser::Parse(SV(u8"#panel { nav-scope: contain; nav-default: c; }")));
    scopes.ApplyTree(*bed.root.Get());
    CHECK(panel->GetNavScope() == NavScope::Contain);
    CHECK(panel->GetDefaultFocusId() == SV(u8"c"));
}

TEST_CASE("navigation: a held direction repeats after a delay, faster the longer it is held")
{
    Bed bed;
    core::RefPtr<Button> cells[40];
    for (int i = 0; i < 40; ++i)
    {
        char8_t id[8] = {u8'c', static_cast<char8_t>(u8'0' + i / 10), static_cast<char8_t>(u8'0' + i % 10), 0};
        cells[i] = Cell(*bed.root.Get(), id, 10.0f, 10.0f + 25.0f * i, 40.0f, 20.0f);
    }
    bed.d.SetFocusNode(cells[0].Get());
    const auto index = [&]() {
        for (int i = 0; i < 40; ++i)
            if (bed.d.GetFocusNode() == cells[i].Get())
                return i;
        return -1;
    };
    bed.d.PressDirection(NavDirection::Down); // at once
    CHECK(index() == 1);
    CHECK(bed.root->NeedsFrame()); // held: frames keep coming
    bed.root->GetContext().Update(core::Duration::FromSeconds(0.39)); // not yet the delay
    CHECK(index() == 1);
    bed.root->GetContext().Update(core::Duration::FromSeconds(0.02)); // past it: the first repeat
    CHECK(index() == 2);
    // Over the first half second of repeats, slower; over a later half second, faster.
    bed.root->GetContext().Update(core::Duration::FromSeconds(0.5));
    const int early = index() - 2;
    for (int i = 0; i < 20; ++i)
        bed.root->GetContext().Update(core::Duration::FromSeconds(0.05)); // a second more
    const int before = index();
    bed.root->GetContext().Update(core::Duration::FromSeconds(0.5));
    const int late = index() - before;
    CHECK(late > early);
    bed.d.ReleaseDirection(NavDirection::Down);
    const int released = index();
    bed.root->GetContext().Update(core::Duration::FromSeconds(1.0));
    CHECK(index() == released);
}

TEST_CASE("navigation: the focus ring shows for the keyboard and a gamepad, not after a click")
{
    Bed bed;
    auto a = Cell(*bed.root.Get(), u8"a", 10.0f, 10.0f);
    auto b = Cell(*bed.root.Get(), u8"b", 10.0f, 40.0f);
    StyleManager styles(CSSParser::Parse(SV(u8"button:focus-visible { opacity: 0.5; }")));

    bed.d.InjectMouseDown(core::Float2{20.0f, 15.0f}, MouseButton::Left); // click-to-focus
    bed.d.InjectMouseUp(core::Float2{20.0f, 15.0f}, MouseButton::Left);
    CHECK(a->IsFocused());
    CHECK_FALSE(a->IsFocusVisible());
    styles.ApplyTree(*bed.root.Get());
    CHECK(a->GetAlpha() == doctest::Approx(1.0f));

    bed.Key(KeyCode::Down);
    CHECK(b->IsFocusVisible());
    styles.ApplyTree(*bed.root.Get());
    CHECK(b->GetAlpha() == doctest::Approx(0.5f));

    bed.d.InjectMouseDown(core::Float2{300.0f, 300.0f}, MouseButton::Left); // the pointer again
    CHECK_FALSE(b->IsFocusVisible());
}

TEST_CASE("navigation: focus moved into a scroller's hidden part scrolls it into view")
{
    Bed bed;
    auto scroll = Make<ScrollView>();
    scroll->SetSize(core::Float2{200.0f, 100.0f});
    bed.root->AddChild(scroll.Get());
    auto top = Make<Button>();
    top->SetId(SV(u8"top"));
    top->SetPosition(core::Float2{0.0f, 0.0f});
    top->SetSize(core::Float2{60.0f, 30.0f});
    auto far = Make<Button>();
    far->SetId(SV(u8"far"));
    far->SetPosition(core::Float2{0.0f, 300.0f});
    far->SetSize(core::Float2{60.0f, 30.0f});
    scroll->AddChild(top.Get());
    scroll->AddChild(far.Get());
    bed.root->UpdateLayout();
    bed.d.SetFocusNode(top.Get());
    bed.Key(KeyCode::Down);
    CHECK(bed.d.GetFocusNode() == far.Get());
    const Rect shown = far->GetScreenBounds();
    CHECK(shown.y >= 0.0f);
    CHECK(shown.y + shown.height <= 100.0f + 0.5f); // inside the 100-high viewport
}

TEST_CASE("navigation: focusing a page lands on its entry, and Tab stays in a dialog")
{
    Bed bed;
    auto page = Make<UIWidget>();
    page->SetNavScope(NavScope::Pass);
    page->SetDefaultFocusId(SV(u8"second"));
    bed.root->AddChild(page.Get());
    auto first = Cell(*page.Get(), u8"first", 10.0f, 10.0f);
    auto second = Cell(*page.Get(), u8"second", 10.0f, 40.0f);
    CHECK(page->FocusElement());
    CHECK(bed.Focused() == SV(u8"second")); // its default
    bed.d.SetFocusNode(first.Get());
    auto elsewhere = Cell(*bed.root.Get(), u8"elsewhere", 200.0f, 10.0f);
    bed.d.SetFocusNode(elsewhere.Get());
    CHECK(page->FocusElement());
    CHECK(bed.Focused() == SV(u8"first")); // what was last focused there

    page->SetNavScope(NavScope::Contain);
    bed.d.SetFocusNode(second.Get());
    bed.Key(KeyCode::Tab); // wraps inside the dialog, never reaching `elsewhere`
    CHECK(bed.Focused() == SV(u8"first"));
    bed.Key(KeyCode::Tab);
    CHECK(bed.Focused() == SV(u8"second"));
}

TEST_CASE("navigation: a held d-pad direction reaches the focused widget before navigation")
{
    // The showcase's slider: the d-pad must change its value, not move focus away from it.
    Bed bed;
    auto slider = Make<Slider>();
    slider->SetPosition(core::Float2{10.0f, 10.0f});
    slider->SetSize(core::Float2{100.0f, 20.0f});
    bed.root->AddChild(slider.Get());
    auto after = Cell(*bed.root.Get(), u8"after", 200.0f, 10.0f);
    bed.d.SetFocusNode(slider.Get());
    slider->SetValue(0.5f);
    bed.d.PressDirection(NavDirection::Right);
    CHECK(slider->GetValue() == doctest::Approx(0.55f));
    CHECK(bed.d.GetFocusNode() == slider.Get());
    bed.root->GetContext().Update(core::Duration::FromSeconds(0.45)); // a repeat steps it again
    CHECK(slider->GetValue() == doctest::Approx(0.6f));
    bed.d.ReleaseDirection(NavDirection::Right);
    // Down is not the slider's: focus moves.
    bed.d.PressDirection(NavDirection::Down);
    bed.d.ReleaseDirection(NavDirection::Down);
    CHECK(bed.d.GetFocusNode() == slider.Get()); // nothing below it: stays
    slider->SetValue(1.0f);
    bed.d.PressDirection(NavDirection::Right); // at its end: still the slider's
    CHECK(bed.d.GetFocusNode() == slider.Get());
    bed.d.ReleaseDirection(NavDirection::Right);
}

TEST_CASE("navigation: after a click on the backdrop, an arrow starts from the GUI's entry")
{
    // The showcase at launch: Play focused, a click on the backdrop, then Down. Down from the
    // full-window backdrop found nothing below it (and Up found Quit); it must enter again.
    Bed bed;
    auto backdrop = Make<UIWidget>();
    backdrop->SetSize(core::Float2{400.0f, 400.0f});
    bed.root->AddChild(backdrop.Get());
    auto play = Cell(*bed.root.Get(), u8"play", 100.0f, 100.0f);
    auto quit = Cell(*bed.root.Get(), u8"quit", 100.0f, 160.0f);
    bed.d.SetFocusNode(play.Get());
    CHECK(play->IsFocusVisible()); // before any pointer use, focus shows
    bed.d.InjectMouseDown(core::Float2{300.0f, 350.0f}, MouseButton::Left);
    bed.d.InjectMouseUp(core::Float2{300.0f, 350.0f}, MouseButton::Left);
    CHECK(bed.d.GetFocusNode() == nullptr);
    bed.Key(KeyCode::Down);
    CHECK(bed.Focused() == SV(u8"play"));

    // Focus left on something that does not take focus (a program's doing) also enters.
    bed.d.SetFocusNode(backdrop.Get());
    bed.Key(KeyCode::Down);
    CHECK(bed.Focused() == SV(u8"play"));
}

TEST_CASE("navigation: a wide widget across the row above is not to the right")
{
    // The showcase's settings: a text field (120..380) above a centred Back (200..300). Right from
    // Back has nothing to its right, so focus stays.
    Bed bed;
    auto field = Cell(*bed.root.Get(), u8"field", 120.0f, 100.0f, 260.0f, 30.0f);
    auto back = Cell(*bed.root.Get(), u8"back", 200.0f, 160.0f, 100.0f, 40.0f);
    bed.d.SetFocusNode(back.Get());
    bed.Key(KeyCode::Right);
    CHECK(bed.Focused() == SV(u8"back"));
    bed.Key(KeyCode::Up); // up is where the field is
    CHECK(bed.Focused() == SV(u8"field"));
    // Neighbours overlapping a little still count.
    auto beside = Cell(*bed.root.Get(), u8"beside", 290.0f, 160.0f, 60.0f, 40.0f); // overlaps back by 10
    bed.d.SetFocusNode(back.Get());
    bed.Key(KeyCode::Right);
    CHECK(bed.Focused() == SV(u8"beside"));
}
