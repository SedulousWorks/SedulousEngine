// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the status bar (T0 of Specs/gui-lab-evolution-3.md): items by id in a start and an
// end zone, in their order; a message held until replaced or for its seconds on the GUI's clock;
// items with a title hidden and shown from the bar's menu, the application told; markup.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.gui.toolkit;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<StatusBar> bar = core::MakeRef<StatusBar>(core::DefaultAllocator());

        Bed()
        {
            root->SetSize(core::Float2{800.0f, 600.0f});
            bar->EditLayoutStyle([](LayoutStyle& s) {
                s.Width = LayoutLength::Px(600.0f);
                s.Height = LayoutLength::Px(24.0f);
            });
            root->AddChild(bar.Get());
        }
        // An item of a width of its own.
        core::RefPtr<StatusItem> Item(const char8_t* id, StatusZone zone, core::i32 order = 0, const char8_t* title = u8"")
        {
            auto item = core::MakeRef<StatusItem>(core::DefaultAllocator());
            item->SetId(SV(id));
            item->SetZone(zone);
            item->SetOrder(order);
            item->SetTitle(SV(title));
            item->EditLayoutStyle([](LayoutStyle& s) {
                s.Width = LayoutLength::Px(60.0f);
                s.Height = LayoutLength::Px(16.0f);
            });
            bar->AddItem(*item);
            return item;
        }
        void Frame(f32 seconds = 0.016f)
        {
            root->GetContext().Update(core::Duration::FromSeconds(seconds));
            root->UpdateLayout();
        }
    };
}

TEST_CASE("status bar: items by id in a start and an end zone, in their order; the end zone at the end")
{
    Bed bed;
    auto mode = bed.Item(u8"mode", StatusZone::Start, 1);
    auto branch = bed.Item(u8"branch", StatusZone::Start, 0);
    auto cursor = bed.Item(u8"cursor", StatusZone::End);
    bed.Frame();

    const core::Array<StatusItem*> start = bed.bar->GetItems(StatusZone::Start);
    REQUIRE(start.Size() == 2u);
    CHECK(start[0] == branch.Get()); // order 0 before order 1
    CHECK(start[1] == mode.Get());
    CHECK(branch->ConvertToWorldSpace(core::Float2{0.0f, 0.0f}).x < mode->ConvertToWorldSpace(core::Float2{0.0f, 0.0f}).x);
    CHECK(cursor->ConvertToWorldSpace(core::Float2{60.0f, 0.0f}).x == doctest::Approx(592.0f)); // inside the end padding
    CHECK(bed.bar->FindItem(SV(u8"cursor")) == cursor.Get());

    CHECK(bed.bar->RemoveItem(SV(u8"mode")));
    CHECK(bed.bar->FindItem(SV(u8"mode")) == nullptr);
    CHECK_FALSE(bed.bar->RemoveItem(SV(u8"mode")));

    // Moved to the other zone, it goes there.
    branch->SetZone(StatusZone::End);
    CHECK(bed.bar->GetItems(StatusZone::End).Size() == 2u);
    CHECK(bed.bar->GetItems(StatusZone::Start).IsEmpty());

    // Right to left, the end zone is at the left.
    bed.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    bed.Frame();
    CHECK(cursor->ConvertToWorldSpace(core::Float2{0.0f, 0.0f}).x < 300.0f);
}

TEST_CASE("status bar: a message holds until replaced, or for its seconds on the GUI's clock")
{
    Bed bed;
    (void)bed.Item(u8"branch", StatusZone::Start);
    bed.bar->ShowMessage(SV(u8"Saved"), 2.0f);
    bed.Frame();
    CHECK(bed.bar->GetMessage() == SV(u8"Saved"));
    CHECK(bed.bar->GetMessagePart()->IsDisplayed());
    bed.Frame(1.0f);
    CHECK(bed.bar->GetMessage() == SV(u8"Saved"));
    bed.Frame(1.5f);
    CHECK(bed.bar->GetMessage().Size() == 0u);
    CHECK_FALSE(bed.bar->GetMessagePart()->IsDisplayed());

    // A timed message replaced by one that holds: the first's time ends nothing.
    bed.bar->ShowMessage(SV(u8"Building"), 1.0f);
    bed.Frame();
    bed.bar->ShowMessage(SV(u8"Ready"));
    bed.Frame(2.0f);
    bed.Frame(2.0f);
    CHECK(bed.bar->GetMessage() == SV(u8"Ready"));
    bed.bar->ClearMessage();
    CHECK(bed.bar->GetMessage().Size() == 0u);
}

TEST_CASE("status bar: its menu lists the items with a title; picking one hides or shows it, and the application hears it")
{
    Bed bed;
    (void)bed.Item(u8"branch", StatusZone::Start, 0, u8"Branch");
    (void)bed.Item(u8"fps", StatusZone::End, 0, u8"Frame rate");
    (void)bed.Item(u8"fixed", StatusZone::End); // no title: not in the menu
    core::Array<core::String> heard(core::DefaultAllocator());
    bed.bar->SetOnItemShownChanged([&](core::StringView id, bool shown)
                                   { heard.PushBack(core::Format(u8"{}={}", id, shown ? u8"shown" : u8"hidden")); });
    bed.Frame();

    REQUIRE(bed.bar->OpenItemsMenu(core::Float2{100.0f, 20.0f}));
    bed.Frame();
    Menu* menu = bed.bar->GetItemsMenu();
    REQUIRE(menu != nullptr);
    core::Array<MenuItem*> rows(core::DefaultAllocator());
    const auto collect = [&rows](auto& self, Node& node) -> void
    {
        if (MenuItem* row = Cast<MenuItem>(&node))
            rows.PushBack(row);
        for (usize i = 0; i < node.ChildCount(); ++i)
            self(self, *node.GetChildAt(i));
    };
    collect(collect, *menu);
    REQUIRE(rows.Size() == 2u);
    CHECK(rows[0]->GetText() == SV(u8"Branch"));
    CHECK(rows[1]->GetText() == SV(u8"Frame rate"));
    CHECK(rows[1]->IsChecked());

    CHECK(rows[1]->HandleActivate());
    CHECK_FALSE(bed.bar->IsItemShown(SV(u8"fps")));
    REQUIRE(heard.Size() == 1u);
    CHECK(heard[0] == core::String(u8"fps=hidden"));

    CHECK(bed.bar->SetItemShown(SV(u8"fps"), true));
    CHECK(bed.bar->IsItemShown(SV(u8"fps")));
    CHECK(heard.Size() == 2u);
    CHECK(bed.bar->SetItemShown(SV(u8"fps"), true)); // as it is: nothing heard
    CHECK(heard.Size() == 2u);
    CHECK_FALSE(bed.bar->SetItemShown(SV(u8"none"), false));
}

TEST_CASE("status bar: markup's children are its items, each in its zone")
{
    RegisterGuiElements();
    RegisterToolkitElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> made = loader.LoadFromString(SV(u8R"(
        <StatusBar>
            <StatusItem id="cursor" zone="end" title="Cursor"><Label text="Ln 1, Col 1"/></StatusItem>
            <StatusItem id="branch" title="Branch"><Label text="main"/></StatusItem>
        </StatusBar>
    )"));
    StatusBar* bar = Cast<StatusBar>(made.Get());
    REQUIRE(bar != nullptr);
    REQUIRE(bar->FindItem(SV(u8"cursor")) != nullptr);
    CHECK(bar->FindItem(SV(u8"cursor"))->GetZone() == StatusZone::End);
    CHECK(bar->FindItem(SV(u8"cursor"))->GetTitle() == SV(u8"Cursor"));
    CHECK(bar->GetItems(StatusZone::Start).Size() == 1u);
}
