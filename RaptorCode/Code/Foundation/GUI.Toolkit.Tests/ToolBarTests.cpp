// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the tool bar (T0 of Specs/gui-lab-evolution-3.md): its buttons name commands and
// show what the command says (label, keys, checked, why it is disabled) in their tooltips; what
// does not fit goes into an overflow menu, the lowest priority then the last first, separators only
// between shown items, a widget no menu row can stand for never going; drop-down and split menu
// buttons; a column, right to left, and markup.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.gui.toolkit;

using namespace foundation::gui;
namespace core = foundation::core;
using core::i32;
using core::usize;
using core::f32;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<ToolBar> bar = Make<ToolBar>();

        explicit Bed(f32 width = 200.0f)
        {
            root->SetSize(core::Float2{800.0f, 600.0f});
            root->AddChild(bar.Get());
            Width(width);
        }
        void Width(f32 width)
        {
            bar->EditLayoutStyle([width](LayoutStyle& s) {
                s.Width = LayoutLength::Px(width);
                s.Height = LayoutLength::Px(28.0f);
            });
            Lay();
        }
        void Lay() { root->UpdateLayout(); }
        void Frame()
        {
            root->GetContext().Update(core::Duration::FromSeconds(0.016));
            root->UpdateLayout();
        }
        // A button of a size of its own (no sheet, no font).
        core::RefPtr<ToolButton> Button(f32 width = 40.0f)
        {
            auto b = Make<ToolButton>();
            b->EditLayoutStyle([width](LayoutStyle& s) {
                s.Width = LayoutLength::Px(width);
                s.Height = LayoutLength::Px(24.0f);
            });
            bar->AddChild(b.Get());
            return b;
        }
        core::RefPtr<Separator> Line()
        {
            auto s = Make<Separator>();
            bar->AddChild(s.Get());
            return s;
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
    };

    template <typename T>
    void Collect(Node& node, core::Array<T*>& out)
    {
        if (T* found = Cast<T>(&node))
            out.PushBack(found);
        for (usize i = 0; i < node.ChildCount(); ++i)
            Collect(*node.GetChildAt(i), out);
    }
    core::Float2 Middle(const Node& node) { return node.ConvertToWorldSpace(core::Float2{node.GetSize().x * 0.5f, node.GetSize().y * 0.5f}); }
    void Click(Bed& bed, core::Float2 at)
    {
        (void)bed.D().InjectMouseMove(at);
        (void)bed.D().InjectMouseDown(at, MouseButton::Left);
        (void)bed.D().InjectMouseUp(at, MouseButton::Left);
    }
}

TEST_CASE("tool bar: a button bound to a command shows its icon alone, its tooltip the label, the keys and why it is disabled")
{
    Bed bed;
    auto save = bed.Button();
    save->SetIconSource(core::String(u8"save.svg"));
    (void)bed.root->OnCommand(SV(u8"file.save"), [](CommandEvent&) {});
    Command& command = bed.root->GetContext().DefineCommand(SV(u8"file.save"));
    command.SetLabel(SV(u8"Save"));
    command.SetDisabledReason(SV(u8"Nothing to save"));
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"ctrl-s"), SV(u8"file.save")));
    save->SetCommand(SV(u8"file.save"));
    bed.Frame();

    CHECK(save->GetLabel() == SV(u8"Save"));
    REQUIRE(save->GetTextPart() != nullptr);
    CHECK_FALSE(save->GetTextPart()->IsDisplayed()); // an icon: its text does not show
    CHECK(save->GetTooltipText() == SV(u8"Save (Ctrl+S)"));

    command.SetEnabled(false);
    bed.Frame();
    CHECK_FALSE(save->IsEnabled());
    CHECK(save->GetTooltipText() == SV(u8"Save (Ctrl+S)\nNothing to save"));

    save->SetShowsText(true); // asked: its text beside its icon
    CHECK(save->GetTextPart()->IsDisplayed());
    save->SetTooltip(SV(u8"Write the scene")); // its own tooltip wins
    CHECK(save->GetTooltipText() == SV(u8"Write the scene"));

    // With no icon its text shows.
    auto plain = bed.Button();
    plain->SetText(SV(u8"Build"));
    CHECK(plain->GetTextPart()->IsDisplayed());
    CHECK(plain->GetTooltipText() == SV(u8"Build"));
}

TEST_CASE("tool bar: what does not fit overflows, the lowest priority first, then the last; the overflow button at the end")
{
    Bed bed(200.0f); // 192 inside its padding
    core::Array<core::RefPtr<ToolButton>> b(core::DefaultAllocator());
    for (i32 i = 0; i < 6; ++i)
        b.PushBack(bed.Button());
    b[1]->SetOverflowPriority(-1);
    bed.Lay();

    // Six of 40 with gaps of 2 ask 250; four fit with the overflow button (12) after them.
    CHECK_FALSE(b[1]->IsVisible()); // the lowest priority went first
    CHECK_FALSE(b[5]->IsVisible()); // then the last
    CHECK(b[0]->IsVisible());
    CHECK(b[2]->IsVisible());
    CHECK(b[4]->IsVisible());
    REQUIRE(bed.bar->GetOverflowed().Size() == 2u);
    CHECK(bed.bar->GetOverflowed()[0] == b[1].Get()); // in bar order
    CHECK(bed.bar->GetOverflowed()[1] == b[5].Get());
    Node* overflow = bed.bar->GetOverflowButton();
    CHECK(overflow->IsVisible());
    CHECK(b[0]->GetPosition().x == doctest::Approx(4.0f));
    CHECK(b[2]->GetPosition().x == doctest::Approx(46.0f)); // the hidden one leaves no gap
    CHECK(overflow->GetPosition().x + overflow->GetSize().x == doctest::Approx(196.0f)); // at the end

    // Room again: everything shows, and no overflow button.
    bed.Width(400.0f);
    for (const auto& button : b)
        CHECK(button->IsVisible());
    CHECK(bed.bar->GetOverflowed().IsEmpty());
    CHECK_FALSE(overflow->IsVisible());
}

TEST_CASE("tool bar: a separator shows only between shown items; a widget no menu row stands for never overflows")
{
    Bed bed(400.0f);
    auto lead = bed.Line(); // nothing before it
    auto a = bed.Button();
    auto between = bed.Line();
    auto twice = bed.Line(); // right after another
    auto b = bed.Button();
    auto trailing = bed.Line(); // nothing after it
    bed.Lay();
    CHECK_FALSE(lead->IsVisible());
    CHECK(between->IsVisible());
    CHECK_FALSE(twice->IsVisible());
    CHECK_FALSE(trailing->IsVisible());
    CHECK(bed.bar->GetOverflowed().Size() == 3u); // the separators left out
    CHECK_FALSE(bed.bar->GetOverflowButton()->IsVisible()); // but no item: nothing overflows
    (void)a;
    (void)b;

    // A field wider than the bar: the buttons go, the field stays.
    Bed narrow(100.0f);
    auto button = narrow.Button();
    auto field = Make<Panel>();
    field->EditLayoutStyle([](LayoutStyle& s) {
        s.Width = LayoutLength::Px(150.0f);
        s.Height = LayoutLength::Px(20.0f);
    });
    narrow.bar->AddChild(field.Get());
    narrow.Lay();
    CHECK_FALSE(button->IsVisible());
    CHECK(field->IsVisible());
}

TEST_CASE("tool bar: the overflow menu stands for each button: a command's row with its checked state, a click's row")
{
    Bed bed(110.0f); // two fit with the overflow button
    auto first = bed.Button();
    auto second = bed.Button();
    auto grid = bed.Button();
    auto snap = bed.Button();
    int grids = 0;
    int snaps = 0;
    (void)bed.root->OnCommand(SV(u8"view.grid"), [&](CommandEvent&) { ++grids; });
    Command& command = bed.root->GetContext().DefineCommand(SV(u8"view.grid"));
    command.SetLabel(SV(u8"Grid"));
    command.SetChecked(true);
    grid->SetToggle(true);
    grid->SetCommand(SV(u8"view.grid"));
    snap->SetText(SV(u8"Snap"));
    snap->SetOnClick([&]() { ++snaps; });
    bed.Frame();
    REQUIRE_FALSE(grid->IsVisible());
    REQUIRE_FALSE(snap->IsVisible());
    (void)first;
    (void)second;

    const core::Float2 barSize = bed.bar->GetSize();
    const core::Float2 firstAt = first->GetPosition();
    Click(bed, Middle(*bed.bar->GetOverflowButton()));
    bed.Frame();
    Menu* menu = bed.bar->GetOverflowMenu();
    REQUIRE(menu != nullptr);
    // The open menu is the bar's child (in the top layer), not one of its items.
    CHECK(menu->GetParent() == bed.bar.Get());
    CHECK(bed.bar->GetSize().y == doctest::Approx(barSize.y));
    CHECK(first->GetPosition().x == doctest::Approx(firstAt.x));
    CHECK(first->IsVisible());
    CHECK(bed.bar->GetOverflowed().Size() == 2u);
    core::Array<MenuItem*> rows(core::DefaultAllocator());
    Collect(*menu, rows);
    REQUIRE(rows.Size() == 2u);
    CHECK(rows[0]->GetText() == SV(u8"Grid")); // the command's label
    CHECK(rows[0]->IsCheckable());
    CHECK(rows[0]->IsChecked());
    CHECK(rows[1]->GetText() == SV(u8"Snap"));

    Click(bed, Middle(*rows[0]));
    bed.Frame();
    CHECK(grids == 1);
    CHECK(bed.bar->GetOverflowMenu() == nullptr); // picked: it closed

    Click(bed, Middle(*bed.bar->GetOverflowButton()));
    bed.Frame();
    rows.Clear();
    Collect(*bed.bar->GetOverflowMenu(), rows);
    REQUIRE(rows.Size() == 2u);
    Click(bed, Middle(*rows[1]));
    CHECK(snaps == 1);
}

TEST_CASE("tool bar: a drop-down opens its menu on a click; a split button runs its command, its arrow opens the menu")
{
    Bed bed(400.0f);
    auto drop = Make<ToolMenuButton>();
    drop->SetText(SV(u8"Add"));
    (void)drop->GetMenu().AddItem(SV(u8"Cube"), []() {});
    bed.bar->AddChild(drop.Get());
    auto split = Make<ToolMenuButton>();
    split->SetText(SV(u8"Play"));
    split->SetSplit(true);
    int plays = 0;
    split->SetOnClick([&]() { ++plays; });
    (void)split->GetMenu().AddItem(SV(u8"Play from here"), []() {});
    bed.bar->AddChild(split.Get());
    ToolMenuButton* const both[] = {drop.Get(), split.Get()};
    for (ToolMenuButton* b : both)
        b->EditLayoutStyle([](LayoutStyle& s) {
            s.Width = LayoutLength::Px(80.0f);
            s.Height = LayoutLength::Px(24.0f);
        });
    bed.Frame();

    Click(bed, Middle(*drop));
    bed.Frame();
    CHECK(drop->GetOpenMenu() != nullptr);
    drop->GetMenu().Close();
    bed.Frame();

    // The body runs it; the arrow opens the menu.
    Click(bed, split->ConvertToWorldSpace(core::Float2{10.0f, 12.0f}));
    bed.Frame();
    CHECK(plays == 1);
    CHECK(split->GetOpenMenu() == nullptr);
    Click(bed, Middle(*split->GetArrowPart()));
    bed.Frame();
    CHECK(plays == 1);
    CHECK(split->GetOpenMenu() != nullptr);
}

TEST_CASE("tool bar: in a column its items run down and overflow at the bottom; right to left they start at the right")
{
    Bed bed(36.0f);
    bed.bar->SetVertical(true);
    bed.bar->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(100.0f); });
    auto a = bed.Button(28.0f);
    auto b = bed.Button(28.0f);
    auto c = bed.Button(28.0f);
    auto d = bed.Button(28.0f);
    bed.Lay();
    CHECK(a->GetPosition().y == doctest::Approx(2.0f));
    CHECK(b->GetPosition().y == doctest::Approx(28.0f)); // 24 tall and a gap of 2
    CHECK_FALSE(d->IsVisible());
    CHECK(bed.bar->GetOverflowButton()->IsVisible());
    (void)c;

    Bed rtl(400.0f);
    rtl.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    auto first = rtl.Button();
    auto second = rtl.Button();
    rtl.Lay();
    CHECK(first->GetPosition().x + first->GetSize().x == doctest::Approx(396.0f));
    CHECK(second->GetPosition().x + second->GetSize().x == doctest::Approx(354.0f));
}

TEST_CASE("tool bar: markup makes a bar of tool buttons, a separator and a menu button whose children are its menu's")
{
    RegisterGuiElements();
    RegisterToolkitElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> made = loader.LoadFromString(SV(u8R"(
        <ToolBar orientation="horizontal">
            <ToolButton command="file.save" icon="save.svg" overflow-priority="2"/>
            <Separator/>
            <ToolMenuButton text="Add" split="true">
                <MenuItem text="Cube"/>
                <MenuItem text="Sphere"/>
            </ToolMenuButton>
        </ToolBar>
    )"));
    ToolBar* bar = Cast<ToolBar>(made.Get());
    REQUIRE(bar != nullptr);
    core::Array<ToolButton*> buttons(core::DefaultAllocator());
    Collect(*bar, buttons);
    REQUIRE(buttons.Size() == 2u);
    CHECK(buttons[0]->GetCommand() == SV(u8"file.save"));
    CHECK(buttons[0]->GetOverflowPriority() == 2);
    ToolMenuButton* add = Cast<ToolMenuButton>(buttons[1]);
    REQUIRE(add != nullptr);
    CHECK(add->IsSplit());
    core::Array<MenuItem*> rows(core::DefaultAllocator());
    Collect(add->GetMenu(), rows);
    CHECK(rows.Size() == 2u);
}

TEST_CASE("tool bar: markup's vertical bar stays a column through a restyle, its separators lying across")
{
    RegisterGuiElements();
    RegisterToolkitElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> made = loader.LoadFromString(SV(u8R"(
        <ToolBar orientation="vertical" height="200">
            <ToolButton text="A"/>
            <Separator/>
            <ToolButton text="B"/>
        </ToolBar>
    )"));
    ToolBar* bar = Cast<ToolBar>(made.Get());
    REQUIRE(bar != nullptr);
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    root->AddChild(bar);
    StyleManager styles;
    styles.SetUserAgentSheet(CSSParser::Parse(ToolkitSheetCSS()));
    styles.ApplyTree(*root.Get());
    styles.ApplyTree(*root.Get()); // and again: a restyle keeps it
    root->UpdateLayout();
    CHECK(bar->IsVertical());
    CHECK(bar->GetOrientationName() == core::String(u8"vertical"));
    core::Array<ToolButton*> buttons(core::DefaultAllocator());
    Collect(*bar, buttons);
    REQUIRE(buttons.Size() == 2u);
    CHECK(buttons[1]->GetPosition().y > buttons[0]->GetPosition().y); // one below the other
    CHECK(buttons[1]->GetPosition().x == doctest::Approx(buttons[0]->GetPosition().x));
    core::Array<Separator*> lines(core::DefaultAllocator());
    Collect(*bar, lines);
    REQUIRE(lines.Size() == 1u);
    CHECK_FALSE(lines[0]->IsVertical()); // it lies across a column
}

