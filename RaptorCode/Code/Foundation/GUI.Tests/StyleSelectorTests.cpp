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

TEST_CASE("selector: specificity buckets")
{
    CHECK(Sel(u8"button").Specificity() == 1);      // tag
    CHECK(Sel(u8".primary").Specificity() == 1024); // class
    CHECK(Sel(u8"#ok").Specificity() == 1048576);   // id
    CHECK(Sel(u8"button.primary#ok").Specificity() == 1048576 + 1024 + 1);
    CHECK(Sel(u8"*").Specificity() == 0);                   // universal
    CHECK(Sel(u8"div .item").Specificity() == 1 + 1024);    // tag + class across two rules
    CHECK(Sel(u8"button:hover").Specificity() == 1 + 1024); // pseudo counts as a class
}

TEST_CASE("selector: tag / id / class matching")
{
    auto w = Widget(u8"button", u8"ok");
    w->AddClass(core::StringView(u8"primary"));

    CHECK(Sel(u8"button").Select(*w.Get()));
    CHECK_FALSE(Sel(u8"span").Select(*w.Get()));
    CHECK(Sel(u8"#ok").Select(*w.Get()));
    CHECK_FALSE(Sel(u8"#cancel").Select(*w.Get()));
    CHECK(Sel(u8".primary").Select(*w.Get()));
    CHECK_FALSE(Sel(u8".large").Select(*w.Get()));
    CHECK(Sel(u8"button.primary#ok").Select(*w.Get()));
    CHECK_FALSE(Sel(u8"button.large").Select(*w.Get()));
    CHECK(Sel(u8"*").Select(*w.Get())); // universal matches
}

TEST_CASE("selector: descendant vs child combinators")
{
    auto container = Make<UIWidget>();
    container->AddClass(core::StringView(u8"container"));
    auto mid = Make<UIWidget>();
    auto deep = Widget(u8"button");
    container->AddChild(mid.Get());
    mid->AddChild(deep.Get()); // container > mid > deep(button)

    // Descendant: container is an ancestor of the button.
    CHECK(Sel(u8".container button").Select(*deep.Get()));
    // Child: button's direct parent is `mid`, not `.container` -> no match.
    CHECK_FALSE(Sel(u8".container > button").Select(*deep.Get()));

    auto direct = Widget(u8"button");
    container->AddChild(direct.Get()); // container > direct(button)
    CHECK(Sel(u8".container > button").Select(*direct.Get()));
    CHECK(Sel(u8".container button").Select(*direct.Get()));
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

TEST_CASE("selector: sibling combinators, + right after and ~ anywhere after")
{
    Row row(u8"blbb"); // button label button button
    CHECK(Sel(u8"button + label").Select(row[1]));
    CHECK(Sel(u8"label + button").Select(row[2]));
    CHECK_FALSE(Sel(u8"label + button").Select(row[3])); // not right after the label
    CHECK(Sel(u8"label ~ button").Select(row[3]));
    CHECK_FALSE(Sel(u8"label ~ button").Select(row[0])); // before it
    CHECK(Sel(u8"button+label").Select(row[1]));          // no spaces
}

TEST_CASE("selector: structural pseudo-classes count widgets among their siblings")
{
    Row row(u8"blbbl");
    CHECK(Sel(u8":first-child").Select(row[0]));
    CHECK_FALSE(Sel(u8":first-child").Select(row[1]));
    CHECK(Sel(u8":last-child").Select(row[4]));
    CHECK(Sel(u8"button:first-of-type").Select(row[0]));
    CHECK(Sel(u8"label:first-of-type").Select(row[1]));
    CHECK(Sel(u8"button:last-of-type").Select(row[3]));
    CHECK(Sel(u8":nth-child(2n+1)").Select(row[2])); // 3rd
    CHECK_FALSE(Sel(u8":nth-child(odd)").Select(row[1]));
    CHECK(Sel(u8":nth-child(even)").Select(row[3]));
    CHECK(Sel(u8":nth-child(3)").Select(row[2]));
    CHECK(Sel(u8":nth-child(-n+2)").Select(row[1]));
    CHECK_FALSE(Sel(u8":nth-child(-n+2)").Select(row[2]));
    CHECK(Sel(u8":nth-last-child(1)").Select(row[4]));
    CHECK(Sel(u8"button:nth-of-type(2)").Select(row[2]));
    CHECK(Sel(u8"label:nth-last-of-type(1)").Select(row[4]));
    Row only(u8"b");
    CHECK(Sel(u8":only-child").Select(only[0]));
    CHECK_FALSE(Sel(u8":only-child").Select(row[0]));
    CHECK(Sel(u8":empty").Select(row[0]));
    CHECK_FALSE(Sel(u8":empty").Select(*row.parent.Get()));
}

TEST_CASE("selector: :not, :is and :where, with their specificity")
{
    auto w = Widget(u8"button", u8"ok");
    w->AddClass(core::StringView(u8"primary"));
    CHECK(Sel(u8"button:not(.large)").Select(*w.Get()));
    CHECK_FALSE(Sel(u8"button:not(.primary)").Select(*w.Get()));
    CHECK_FALSE(Sel(u8":not(label, .primary)").Select(*w.Get()));
    CHECK(Sel(u8":is(label, .primary)").Select(*w.Get()));
    CHECK_FALSE(Sel(u8":is(label, .large)").Select(*w.Get()));
    CHECK(Sel(u8":where(#ok)").Select(*w.Get()));
    // :not and :is add their most specific argument; :where adds nothing.
    CHECK(Sel(u8":is(.a, #b)").Specificity() == 1048576);
    CHECK(Sel(u8"button:not(.a)").Specificity() == 1 + 1024);
    CHECK(Sel(u8":where(#b) button").Specificity() == 1);
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

TEST_CASE("selector: an unknown pseudo-class or a stray character makes the rule match nothing")
{
    auto w = Widget(u8"button");
    CHECK_FALSE(Sel(u8"button:hovr").Select(*w.Get()));
    CHECK_FALSE(Sel(u8":frobnicate(2)").Select(*w.Get()));
    CHECK_FALSE(Sel(u8"button:nth-child(banana)").Select(*w.Get()));
    CHECK_FALSE(Sel(u8"button$").Select(*w.Get()));
    CHECK(Sel(u8"button").Select(*w.Get()));
}

TEST_CASE("selector: combinators try every candidate, not only the nearest")
{
    // a.x > b > c, and c's nearest `b` ancestor is not a child of .x: a greedy walk fails.
    auto x = Make<UIWidget>();
    x->AddClass(core::StringView(u8"x"));
    auto b1 = Widget(u8"b");
    auto b2 = Widget(u8"b");
    auto c = Widget(u8"c");
    x->AddChild(b1.Get());
    b1->AddChild(b2.Get());
    b2->AddChild(c.Get());
    CHECK(Sel(u8".x > b c").Select(*c.Get()));
    CHECK(Sel(u8".x > b > b > c").Select(*c.Get()));
    CHECK_FALSE(Sel(u8".x > c").Select(*c.Get()));
}

TEST_CASE("selector: a sheet's selector lists split only at their top level")
{
    const StyleSheet sheet = CSSParser::Parse(core::StringView(u8":is(.a, .b), label { opacity: 0.5; } [title=\"x, y\"] { opacity: 0.2; }"));
    REQUIRE(sheet.RuleCount() == 3u);
    auto w = Make<UIWidget>();
    w->AddClass(core::StringView(u8"b"));
    CHECK(sheet.Rules()[0].Selector().Select(*w.Get()));
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

TEST_CASE("selector: the ancestor keys come from compounds a child or descendant combinator reaches")
{
    const auto has = [](const StyleSelector& s, const char8_t* name)
    {
        for (const core::u64 key : s.AncestorKeys())
            if (key == core::HashText(core::StringView(name)))
                return true;
        return false;
    };
    const StyleSelector parentOfSibling(core::StringView(u8"panel > label + .note"));
    CHECK(has(parentOfSibling, u8"panel")); // label's parent is .note's parent too
    CHECK_FALSE(has(parentOfSibling, u8"label"));
    CHECK_FALSE(has(parentOfSibling, u8"note")); // the subject's own names are not an ancestor's

    const StyleSelector siblingOfParent(core::StringView(u8"panel + #box .cell"));
    CHECK(has(siblingOfParent, u8"box"));
    CHECK_FALSE(has(siblingOfParent, u8"panel")); // only a sibling of an ancestor

    CHECK(StyleSelector(core::StringView(u8".a.b .c.d .e .f")).AncestorKeys().Size() == StyleSelector::kAncestorKeys);
    CHECK(StyleSelector(core::StringView(u8"button:hover")).AncestorKeys().Size() == 0);
}

TEST_CASE("selector: the ancestor filter turns away a rule whose ancestor is missing, and never one that could match")
{
    auto top = Widget(u8"panel", u8"top");
    top->AddClass(core::StringView(u8"page"));
    auto deep = Widget(u8"panel");
    deep->AddClass(core::StringView(u8"deep"));
    const StyleSelector needsPage(core::StringView(u8".page .cell"));
    const StyleSelector needsTop(core::StringView(u8"#top > .cell"));
    const StyleSelector needsDeep(core::StringView(u8".deep .cell"));

    AncestorFilter filter;
    CHECK_FALSE(filter.MayMatch(needsPage));
    filter.Push(*top.Get());
    CHECK(filter.MayMatch(needsPage));
    CHECK(filter.MayMatch(needsTop));
    CHECK_FALSE(filter.MayMatch(needsDeep));

    // More of one name than a counter holds: popping all but one still says maybe.
    for (int i = 0; i < 300; ++i)
        filter.Push(*deep.Get());
    for (int i = 0; i < 299; ++i)
        filter.Pop();
    CHECK(filter.MayMatch(needsDeep));
    filter.Pop();
    filter.Pop();
    CHECK_FALSE(filter.MayMatch(needsPage));
}

TEST_CASE("selector: positions and siblings follow the children as they are added, moved and removed")
{
    Row row(u8"bbbb");
    CHECK(Sel(u8":nth-child(1)").Select(row[0]));
    CHECK(Sel(u8":nth-last-child(1)").Select(row[3]));
    row.parent->SetChildIndex(row.kids[3].Get(), 0); // the last goes first
    CHECK(Sel(u8":nth-child(1)").Select(row[3]));
    CHECK(Sel(u8":nth-child(2)").Select(row[0]));
    CHECK(Sel(u8":nth-last-child(1)").Select(row[2]));

    // A plain node among them is not counted, and a label added after changes the count.
    auto plain = core::MakeRef<Node>(core::DefaultAllocator());
    row.parent->AddChildAt(plain.Get(), 1);
    auto label = Widget(u8"label");
    row.parent->AddChild(label.Get());
    CHECK(Sel(u8":nth-child(2)").Select(row[0]));
    CHECK(Sel(u8":nth-last-child(1)").Select(*label.Get()));
    CHECK(Sel(u8"button + label").Select(*label.Get()));

    // Moved to another parent: numbered there, and gone from here.
    Row other(u8"ll");
    other.parent->AddChild(row.kids[3].Get());
    CHECK(Sel(u8":nth-child(3)").Select(row[3]));
    CHECK(Sel(u8":nth-child(1)").Select(row[0]));
    CHECK(Sel(u8"label + button").Select(row[3]));
    row.parent->RemoveChild(label.Get());
    CHECK(Sel(u8":nth-last-child(1)").Select(row[2]));
}

TEST_CASE("selector: a part's state counts as a pseudo-class of its own, beside the compound's")
{
    // :first-of-type and the part's :hover both count (they shared bits before).
    CHECK(Sel(u8"slider:first-of-type::thumb:hover").Specificity() == 2 * 1024 + 1 + 1);
    CHECK(Sel(u8"slider::thumb:hover").Specificity() == 1024 + 1 + 1);
    CHECK(Sel(u8"slider:hover::thumb:hover").Specificity() == 2 * 1024 + 1 + 1);
}
