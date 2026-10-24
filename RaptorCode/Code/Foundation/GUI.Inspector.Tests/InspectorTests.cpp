// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Inspector - the inspector (E8e of Specs/gui-lab-evolution.md): its tree follows the
// inspected one, its details show what a node is and where its styles came from, and picking
// walks out through what holds the node under the pointer and selects on a click; its details say
// what a screen reader is told (E9d).
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.gui.inspector;

using namespace foundation::gui;
namespace inspector = foundation::gui::inspector;
namespace core = foundation::core;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<GUIContext> context = core::MakeRef<GUIContext>(core::DefaultAllocator());
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), context);
        core::RefPtr<Panel> page = core::MakeRef<Panel>(core::DefaultAllocator());
        core::RefPtr<Button> ok = core::MakeRef<Button>(core::DefaultAllocator());
        StyleManager styles{CSSParser::Parse(SV(u8"#page { padding: 10px; }\nbutton { opacity: 0.8; }\n"), SV(u8"app.css"))};
        inspector::Inspector inspect{core::DefaultAllocator(), context, nullptr};

        Bed()
        {
            root->SetSize(core::Float2{300.0f, 200.0f});
            page->SetId(SV(u8"page"));
            page->SetSize(core::Float2{300.0f, 200.0f});
            root->AddChild(page.Get());
            ok->SetId(SV(u8"ok"));
            ok->SetSize(core::Float2{80.0f, 30.0f});
            page->AddChild(ok.Get());
            styles.ApplyTree(*root.Get());
            root->UpdateLayout();
            inspect.Inspect(root.Get(), &styles);
            inspect.Refresh();
        }
        [[nodiscard]] bool DetailsHave(core::StringView text) const
        {
            for (const core::String& line : inspect.DetailsText())
                if (line.AsView() == text)
                    return true;
            return false;
        }
    };
}

TEST_CASE("inspector: its tree lists the inspected one, and follows it when it changes")
{
    Bed bed;
    const usize before = bed.inspect.TreeRowCount();
    CHECK(before >= 3u);
    auto more = core::MakeRef<Panel>(core::DefaultAllocator());
    bed.page->AddChild(more.Get());
    for (int i = 0; i < 10; ++i) // the shape is checked every few refreshes
        bed.inspect.Refresh();
    CHECK(bed.inspect.TreeRowCount() == before + 1u);
}

TEST_CASE("inspector: the details show what the selected node is and where its styles came from")
{
    Bed bed;
    CHECK(bed.DetailsHave(SV(u8"Nothing selected: pick a node, choose one in the tree, or query a selector.")));
    bed.inspect.Select(bed.ok.Get());
    CHECK(bed.inspect.GetSelected() == bed.ok.Get());
    CHECK(bed.DetailsHave(SV(u8"Button #ok")));
    CHECK(bed.DetailsHave(SV(u8"button   app.css:2"))); // the rule, its sheet and line
    CHECK(bed.DetailsHave(SV(u8"opacity"))); // the declaration: its name, and its value in a field
    CHECK(bed.DetailsHave(SV(u8"0.8")));
    bed.inspect.Select(bed.page.Get());
    CHECK(bed.DetailsHave(SV(u8"#page   app.css:1")));
    CHECK(bed.DetailsHave(SV(u8"padding-top")));
    CHECK(bed.DetailsHave(SV(u8"10px")));
    bed.page->RemoveChild(bed.ok.Get());
    bed.inspect.Select(bed.ok.Get());
    bed.ok.Reset(); // gone: the selection lets it go
    CHECK(bed.inspect.GetSelected() == nullptr);
}

TEST_CASE("inspector: picking outlines what is under the pointer, the wheel walks out to what holds it, a click selects")
{
    Bed bed;
    bed.inspect.SetPicking(true);
    bed.inspect.PickHover(core::Float2{30.0f, 25.0f}); // inside the button (the page's padding is 10)
    CHECK(bed.inspect.GetHovered() == bed.ok.Get());
    bed.inspect.PickWheel(1.0f); // out to the page
    CHECK(bed.inspect.GetHovered() == bed.page.Get());
    bed.inspect.PickWheel(-1.0f); // back in
    CHECK(bed.inspect.GetHovered() == bed.ok.Get());
    bed.inspect.PickClick();
    CHECK_FALSE(bed.inspect.IsPicking());
    CHECK(bed.inspect.GetSelected() == bed.ok.Get());
    CHECK(bed.inspect.GetHovered() == nullptr);
}

TEST_CASE("inspector: frames recorded reach the frames tab")
{
    Bed bed;
    FrameStats stats;
    stats.DrawMs = 2.0;
    bed.inspect.RecordFrame(stats);
    bed.inspect.RecordFrame(stats);
    CHECK(bed.inspect.GetRoot().ChildCount() == 1u); // its shell
}

TEST_CASE("inspector: a branch folds out of the tree and opens again, and selecting inside it opens it")
{
    Bed bed;
    const usize all = bed.inspect.TreeRowCount();
    bed.inspect.SetCollapsed(bed.page.Get(), true);
    CHECK(bed.inspect.IsCollapsed(bed.page.Get()));
    CHECK(bed.inspect.TreeRowCount() < all); // the button and its parts are gone from the list
    const usize folded = bed.inspect.TreeRowCount();
    bed.inspect.Select(bed.ok.Get()); // inside the fold: it opens
    CHECK_FALSE(bed.inspect.IsCollapsed(bed.page.Get()));
    CHECK(bed.inspect.TreeRowCount() == all);
    bed.inspect.SetCollapsed(bed.page.Get(), true);
    CHECK(bed.inspect.TreeRowCount() == folded);
    bed.inspect.SetCollapsed(bed.page.Get(), false);
    CHECK(bed.inspect.TreeRowCount() == all);
}

TEST_CASE("inspector: a style value edited in its field changes the rule, and every node it matches follows")
{
    Bed bed;
    bed.inspect.Select(bed.ok.Get());
    // The field showing opacity's 0.8 (the button rule's).
    TextField* field = nullptr;
    const auto find = [&field](auto& self, Node& node) -> void
    {
        if (TextField* f = core::Cast<TextField>(&node); f != nullptr && f->GetText() == SV(u8"0.8"))
            field = f;
        for (usize i = 0; i < node.ChildCount(); ++i)
            self(self, *node.GetChildAt(i));
    };
    find(find, bed.inspect.GetRoot());
    REQUIRE(field != nullptr);
    EventDispatcher& d = *bed.inspect.GetRoot().GetEventDispatcher();
    d.SetFocusNode(field);
    field->SetText(SV(u8"0.3"));
    (void)d.InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    bed.styles.ApplyTree(*bed.root.Get());
    CHECK(bed.ok->GetAlpha() == doctest::Approx(0.3f));
    bed.inspect.Refresh(); // shown again, with the new value
    CHECK(bed.DetailsHave(SV(u8"0.3")));
}

TEST_CASE("inspector: the details say what a screen reader is told of the node")
{
    Bed bed;
    bed.ok->SetText(SV(u8"Save"));
    bed.inspect.Select(bed.ok.Get());
    CHECK(bed.DetailsHave(SV(u8"Accessibility")));
    CHECK(bed.DetailsHave(SV(u8"button \"Save\"")));
    CHECK(bed.DetailsHave(SV(u8"audit: nothing in this GUI a screen reader trips on")));
}
