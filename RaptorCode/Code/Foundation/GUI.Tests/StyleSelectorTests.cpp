// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - CSS StyleSelector tests: parsing, specificity, and matching against the
// UIWidget identity (tag/#id/.class), pseudo-classes via control state, and descendant /
// child combinators. Derived from eepp css selector semantics (common subset).
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
    StyleSelector Sel(const char8_t* s) { return StyleSelector(core::StringView(s)); }

    core::RefPtr<UIWidget> Widget(const char8_t* tag, const char8_t* id = u8"")
    {
        auto w = Make<UIWidget>();
        w->SetTag(core::StringView(tag));
        if (id[0] != 0)
            w->SetId(core::StringView(id));
        return w;
    }
}

TEST_CASE("selector: pseudo-classes track control state")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto w = Widget(u8"button");
    w->SetSize(core::Float2{100.0f, 100.0f});
    w->SetTabFocusable(true); // a click focuses what takes focus
    root->AddChild(w.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    CHECK_FALSE(Sel(u8"button:hover").Select(*w.Get()));                  // not hovered yet
    CHECK(Sel(u8"button:hover").Select(*w.Get(), /*applyPseudo*/ false)); // pseudo ignored

    d->InjectMouseMove(core::Float2{50.0f, 50.0f}); // hover w
    CHECK(Sel(u8"button:hover").Select(*w.Get()));

    d->InjectMouseDown(core::Float2{50.0f, 50.0f}, MouseButton::Left); // press + focus
    CHECK(Sel(u8"button:active").Select(*w.Get()));
    CHECK(Sel(u8"button:focus").Select(*w.Get()));

    w->SetEnabled(false);
    CHECK(Sel(u8":disabled").Select(*w.Get()));
    CHECK(Sel(u8"button:disabled").Select(*w.Get()));
}

// ===================== E3: the selector forms =====================

namespace
{
    // A parent widget holding `count` children tagged by the letters of `tags` ('b' button, 'l'
    // label), in order.
    struct Row
    {
        core::RefPtr<UIWidget> parent = Make<UIWidget>();
        core::Array<core::RefPtr<UIWidget>> kids;
        explicit Row(const char8_t* tags)
        {
            for (const char8_t* t = tags; *t != 0; ++t)
            {
                auto w = Widget(*t == u8'b' ? u8"button" : u8"label");
                parent->AddChild(w.Get());
                kids.PushBack(w);
            }
        }
        const UIWidget& operator[](core::usize i) const { return *kids[i].Get(); }
    };
}

TEST_CASE("selector: attributes read the id, classes and reflected properties by their CSS names")
{
    auto box = Make<CheckBox>();
    auto field = Make<TextField>();
    field->SetPlaceholder(core::StringView(u8"search the list"));
    field->SetId(core::StringView(u8"q"));
    field->AddClass(core::StringView(u8"wide"));
    field->AddClass(core::StringView(u8"dark-mode"));
    CHECK(Sel(u8"[placeholder]").Select(*field.Get()));
    CHECK_FALSE(Sel(u8"[placeholder]").Select(*box.Get()));
    CHECK(Sel(u8"[placeholder=\"search the list\"]").Select(*field.Get()));
    CHECK(Sel(u8"[placeholder^=search]").Select(*field.Get()));
    CHECK(Sel(u8"[placeholder$='list']").Select(*field.Get()));
    CHECK(Sel(u8"[placeholder*=the]").Select(*field.Get()));
    CHECK(Sel(u8"[placeholder~=the]").Select(*field.Get()));
    CHECK_FALSE(Sel(u8"[placeholder~=th]").Select(*field.Get()));
    CHECK(Sel(u8"[class|=dark]").Select(*field.Get()) == false); // "wide dark-mode" is not dark or dark-...
    CHECK(Sel(u8"[class~=wide]").Select(*field.Get()));
    CHECK(Sel(u8"[id=q]").Select(*field.Get()));
    CHECK(Sel(u8"checkbox[checked=false]").Select(*box.Get()));
    box->SetChecked(true);
    CHECK(Sel(u8"checkbox[checked=true]").Select(*box.Get()));
    CHECK(Sel(u8"[placeholder=\"a, b\"]").Specificity() == 1024); // an attribute counts as a class
}

TEST_CASE("selector: the widgets' own states, and :focus-within and :enabled")
{
    auto box = Make<CheckBox>();
    CHECK_FALSE(Sel(u8":checked").Select(*box.Get()));
    box->SetChecked(true);
    CHECK(Sel(u8"checkbox:checked").Select(*box.Get()));
    box->SetIndeterminate(true);
    CHECK(Sel(u8":indeterminate").Select(*box.Get()));
    box->Toggle(); // a choice settles it
    CHECK_FALSE(Sel(u8":indeterminate").Select(*box.Get()));

    auto field = Make<TextField>();
    CHECK(Sel(u8":read-write").Select(*field.Get()));
    CHECK(Sel(u8"label:read-only").Select(*Widget(u8"label").Get())); // what the user cannot edit
    field->SetReadOnly(true);
    CHECK(Sel(u8"textfield:read-only").Select(*field.Get()));
    CHECK_FALSE(Sel(u8":placeholder-shown").Select(*field.Get()));
    field->SetPlaceholder(core::StringView(u8"name"));
    CHECK(Sel(u8":placeholder-shown").Select(*field.Get()));
    field->SetText(core::StringView(u8"Ada"));
    CHECK_FALSE(Sel(u8":placeholder-shown").Select(*field.Get()));

    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto panel = Widget(u8"panel");
    auto input = Make<TextField>();
    panel->AddChild(input.Get());
    root->AddChild(panel.Get());
    CHECK(Sel(u8":enabled").Select(*panel.Get()));
    CHECK_FALSE(Sel(u8"panel:focus-within").Select(*panel.Get()));
    input->RequestFocus();
    CHECK(Sel(u8"panel:focus-within").Select(*panel.Get()));
    CHECK(Sel(u8"textfield:focus-within").Select(*input.Get()));
    input->ReleaseFocus();
    CHECK_FALSE(Sel(u8"panel:focus-within").Select(*panel.Get()));
}

TEST_CASE("selector: what changes a structural or state match restyles the widgets it touches")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto list = Widget(u8"list");
    root->AddChild(list.Get());
    auto first = Widget(u8"item");
    list->AddChild(first.Get());
    StyleManager styles(CSSParser::Parse(core::StringView(u8"item:last-child { opacity: 0.5; } checkbox:checked { opacity: 0.25; }")));
    styles.ApplyTree(*root.Get());
    CHECK(first->GetAlpha() == doctest::Approx(0.5f));

    // A new last child: the old one is no longer last.
    auto second = Widget(u8"item");
    list->AddChild(second.Get());
    styles.ApplyTree(*root.Get());
    CHECK(second->GetAlpha() == doctest::Approx(0.5f));

    auto box = Make<CheckBox>();
    root->AddChild(box.Get());
    styles.ApplyTree(*root.Get());
    CHECK(box->GetAlpha() == doctest::Approx(1.0f));
    box->SetChecked(true);
    styles.ApplyTree(*root.Get());
    CHECK(box->GetAlpha() == doctest::Approx(0.25f));
}
