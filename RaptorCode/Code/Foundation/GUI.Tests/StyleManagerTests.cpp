// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - StyleManager tests: a StyleSheet applied live to a widget tree, including
// the end-to-end showcase where hovering re-resolves :hover rules and drives a CSS
// transition through the ActionManager.
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
    core::Duration Sec(double s) { return core::Duration::FromSeconds(s); }

    core::RefPtr<UIWidget> Widget(const char8_t* tag, core::Float2 pos, core::Float2 size)
    {
        auto w = Make<UIWidget>();
        w->SetTag(SV(tag));
        w->SetPosition(pos);
        w->SetSize(size);
        return w;
    }
}

TEST_CASE("style-manager: applies a sheet across the tree")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto btn = Widget(u8"button", core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    root->AddChild(btn.Get());

    StyleManager mgr(CSSParser::Parse(SV(u8"button { opacity: 0.5; background-color: red; }")));
    mgr.ApplyTree(*root.Get());

    CHECK(btn->GetAlpha() == doctest::Approx(0.5f));
    CHECK(btn->GetBox().BackgroundColor.r == doctest::Approx(1.0f));
}

TEST_CASE("style-manager: hover re-resolve drives a live transition")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto btn = Widget(u8"button", core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    root->AddChild(btn.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // transition on the base rule (applies both directions); :hover changes opacity.
    StyleManager mgr(CSSParser::Parse(
        SV(u8"button { opacity: 1; transition: opacity 0.5s linear; } button:hover { opacity: 0.4; }")));

    mgr.ApplyTree(*root.Get()); // first apply (snap)
    CHECK(btn->GetAlpha() == doctest::Approx(1.0f));

    d->InjectMouseMove(core::Float2{50.0f, 50.0f}); // hover the button
    CHECK(btn->IsHovered());

    mgr.ApplyTree(*root.Get()); // re-resolve: :hover now matches -> transition animates
    CHECK(root->GetActionManager()->Count() == 1);
    CHECK(btn->GetAlpha() == doctest::Approx(1.0f)); // starts where it was

    root->GetContext().Update(Sec(0.25));
    CHECK(btn->GetAlpha() == doctest::Approx(0.7f)); // 1 + (0.4-1)*0.5
    root->GetContext().Update(Sec(0.25));
    CHECK(btn->GetAlpha() == doctest::Approx(0.4f)); // arrived at :hover value
}

TEST_CASE("style-manager: media context gates what applies")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto btn = Widget(u8"button", core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    root->AddChild(btn.Get());

    StyleManager mgr(CSSParser::Parse(
        SV(u8"button { opacity: 1; } @media (min-width: 600px) { button { opacity: 0.2; } }")));

    mgr.SetMediaContext(MediaContext{400.0f, 0.0f, 96.0f}); // narrow
    mgr.ApplyTree(*root.Get());
    CHECK(btn->GetAlpha() == doctest::Approx(1.0f));

    mgr.Clear(); // forget cached styles so the re-apply is a fresh snap
    mgr.SetMediaContext(MediaContext{800.0f, 0.0f, 96.0f}); // wide
    mgr.ApplyTree(*root.Get());
    CHECK(btn->GetAlpha() == doctest::Approx(0.2f));
}

TEST_CASE("style-manager: SetStyleSheet swaps styles (hot-reload)")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto btn = Widget(u8"button", core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    root->AddChild(btn.Get());

    StyleManager mgr(CSSParser::Parse(SV(u8"button { opacity: 1; }")));
    mgr.ApplyTree(*root.Get());
    CHECK(btn->GetAlpha() == doctest::Approx(1.0f));

    mgr.SetStyleSheet(CSSParser::Parse(SV(u8"button { opacity: 0.3; }")));
    mgr.ApplyTree(*root.Get());
    CHECK(btn->GetAlpha() == doctest::Approx(0.3f));
}

// ===================== E3: origins =====================

namespace
{
    core::RefPtr<SceneRoot> NewRoot()
    {
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{200.0f, 200.0f});
        return root;
    }
    core::RefPtr<UIWidget> Tagged(Node& parent, const char8_t* tag, const char8_t* cls = u8"")
    {
        auto w = Make<UIWidget>();
        w->SetTag(SV(tag));
        if (cls[0] != 0)
            w->AddClass(SV(cls));
        parent.AddChild(w.Get());
        return w;
    }
}

TEST_CASE("style-manager: the GUI's sheet outranks the user agent's at any specificity")
{
    auto root = NewRoot();
    auto button = Tagged(*root.Get(), u8"button");
    button->SetId(SV(u8"ok"));
    StyleManager styles;
    styles.SetUserAgentSheet(CSSParser::Parse(SV(u8"#ok { opacity: 0.2; } button { padding: 9px; }")));
    styles.SetStyleSheet(CSSParser::Parse(SV(u8"* { opacity: 0.7; }")));
    styles.ApplyTree(*root.Get());
    CHECK(button->GetAlpha() == doctest::Approx(0.7f)); // a universal rule over an id one
    CHECK(button->GetPadding().Left == doctest::Approx(9.0f)); // what the GUI's sheet does not say
}

TEST_CASE("style-manager: a subtree's sheet applies inside it alone, over the GUI's; an inner one over an outer")
{
    auto root = NewRoot();
    auto page = Tagged(*root.Get(), u8"panel", u8"page");
    auto inside = Tagged(*page.Get(), u8"label", u8"note");
    auto inner = Tagged(*page.Get(), u8"panel", u8"card");
    auto deep = Tagged(*inner.Get(), u8"label", u8"note");
    auto outside = Tagged(*root.Get(), u8"label", u8"note");
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(SV(u8"label.note { opacity: 0.9; }")));
    REQUIRE(styles.SetSubtreeSheet(*page.Get(), CSSParser::Parse(SV(u8".note { opacity: 0.5; } @keyframes fade { from { opacity: 0; } to { opacity: 1; } }"))));
    REQUIRE(styles.SetSubtreeSheet(*inner.Get(), CSSParser::Parse(SV(u8"* { opacity: 0.3; }"))));
    styles.ApplyTree(*root.Get());
    CHECK(inside->GetAlpha() == doctest::Approx(0.5f));  // the page's, though less specific
    CHECK(deep->GetAlpha() == doctest::Approx(0.3f));    // the inner card's
    CHECK(outside->GetAlpha() == doctest::Approx(0.9f)); // outside the page: the GUI's alone

    styles.RemoveSubtreeSheet(*inner.Get());
    styles.ApplyTree(*root.Get());
    CHECK(deep->GetAlpha() == doctest::Approx(0.5f));
    // A node in no GUI cannot hold a subtree sheet.
    auto loose = Make<UIWidget>();
    CHECK_FALSE(styles.SetSubtreeSheet(*loose.Get(), StyleSheet{}));
}

TEST_CASE("style-manager: markup's inline properties outrank every sheet's normal ones, not !important")
{
    RegisterGuiElements();
    const ElementSet elements = ElementSet::All(); // the loader keeps a reference
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> markup = loader.LoadFromString(SV(u8R"(<Panel><Label class="chip" opacity="0.4"/><Label class="hard" opacity="0.4"/></Panel>)"));
    REQUIRE(markup);
    auto root = NewRoot();
    root->AddChild(markup.Get());
    auto* chip = core::Cast<UIWidget>(markup->GetChildAt(0));
    auto* hard = core::Cast<UIWidget>(markup->GetChildAt(1));
    StyleManager styles(CSSParser::Parse(SV(u8".chip { opacity: 0.9; } .hard { opacity: 0.8 !important; }")));
    styles.ApplyTree(*root.Get());
    CHECK(chip->GetAlpha() == doctest::Approx(0.4f));
    CHECK(hard->GetAlpha() == doctest::Approx(0.8f));
    // A script or code may set inline style too.
    chip->SetInlineStyle(SV(u8"opacity"), SV(u8"0.6"));
    styles.ApplyTree(*root.Get());
    CHECK(chip->GetAlpha() == doctest::Approx(0.6f));
}

TEST_CASE("style-manager: a markup property a restyle meets again is not written again; the tree settles")
{
    RegisterGuiElements();
    const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> markup = loader.LoadFromString(SV(u8R"(<Panel><ListBox items="One|Two|Three"/></Panel>)"));
    REQUIRE(markup);
    auto root = NewRoot();
    root->AddChild(markup.Get());
    auto* list = core::Cast<ListBox>(markup->GetChildAt(0));
    REQUIRE(list != nullptr);
    StyleManager styles(CSSParser::Parse(SV(u8"listbox { opacity: 1; }")));
    styles.ApplyTree(*root.Get());
    REQUIRE(list->ItemCount() == 3u);
    Node* firstRow = list->GetChildAt(0);
    styles.ApplyTree(*root.Get());
    styles.ApplyTree(*root.Get());
    CHECK(styles.LastRestyleCount() == 0u); // a list rebuilding its rows restyled itself every frame
    CHECK(list->GetChildAt(0) == firstRow);  // its rows were not made again
}

// ===================== E3: computed style =====================

TEST_CASE("style-manager: a rule that stops matching gives back everything it set")
{
    auto root = NewRoot();
    auto w = Tagged(*root.Get(), u8"box");
    StyleManager styles(CSSParser::Parse(SV(
        u8"box.on { opacity: 0.5; padding: 7px; width: 120px; margin-left: 4px; display: grid; overflow: hidden; "
        u8"visibility: hidden; enabled: false; flex-grow: 2; }")));
    styles.ApplyTree(*root.Get());
    const Thickness padding = w->GetPadding();
    const LayoutStyle layout = w->GetLayoutStyle();

    w->AddClass(SV(u8"on"));
    styles.ApplyTree(*root.Get());
    CHECK(w->GetAlpha() == doctest::Approx(0.5f));
    CHECK(w->GetPadding().Top == doctest::Approx(7.0f));
    CHECK(w->GetLayoutStyle().Width == LayoutLength::Px(120.0f));
    CHECK(w->GetLayoutStyle().Kind == Display::Grid);
    CHECK(w->ClipsChildren());
    CHECK_FALSE(w->IsVisible());
    CHECK_FALSE(w->IsEnabled());

    w->RemoveClass(SV(u8"on"));
    styles.ApplyTree(*root.Get());
    CHECK(w->GetAlpha() == doctest::Approx(1.0f));
    CHECK(w->GetPadding() == padding);
    CHECK_FALSE(ChangedLayoutSlots(w->GetLayoutStyle(), layout).Any());
    CHECK_FALSE(w->ClipsChildren());
    CHECK(w->IsVisible());
    CHECK(w->IsEnabled());
}

TEST_CASE("style-manager: a widget's own defaults are what a rule gives back to")
{
    auto root = NewRoot();
    auto tip = Make<Tooltip>(); // 6 by 3 padding of its own
    root->AddChild(tip.Get());
    const Thickness own = tip->GetPadding();
    StyleManager styles(CSSParser::Parse(SV(u8"tooltip.big { padding: 20px; }")));
    styles.ApplyTree(*root.Get());
    CHECK(tip->GetPadding() == own); // no rule: its own, not CSS's initial 0
    tip->AddClass(SV(u8"big"));
    styles.ApplyTree(*root.Get());
    CHECK(tip->GetPadding().Left == doctest::Approx(20.0f));
    tip->RemoveClass(SV(u8"big"));
    styles.ApplyTree(*root.Get());
    CHECK(tip->GetPadding() == own);
}

TEST_CASE("style-manager: what code sets is code's, over the sheet, before or after a restyle")
{
    auto root = NewRoot();
    auto early = Tagged(*root.Get(), u8"box");
    auto late = Tagged(*root.Get(), u8"box");
    early->SetAlpha(0.3f); // before any sheet
    StyleManager styles(CSSParser::Parse(SV(u8"box { opacity: 0.8; width: 50px; }")));
    styles.ApplyTree(*root.Get());
    CHECK(early->GetAlpha() == doctest::Approx(0.3f));
    CHECK(late->GetAlpha() == doctest::Approx(0.8f));

    late->SetAlpha(0.6f); // after the sheet styled it
    late->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(70.0f); });
    late->MarkStyleDirty(false);
    styles.ApplyTree(*root.Get());
    CHECK(late->GetAlpha() == doctest::Approx(0.6f));
    CHECK(late->GetLayoutStyle().Width == LayoutLength::Px(70.0f));
    CHECK(late->IsStylePinned(SlotWidth));
    CHECK_FALSE(late->IsStylePinned(SlotHeight)); // only what code changed

    // Given back, the sheet's value returns.
    late->UnpinStyle(SlotBit(SlotOpacity) | SlotBit(SlotWidth));
    styles.ApplyTree(*root.Get());
    CHECK(late->GetAlpha() == doctest::Approx(0.8f));
    CHECK(late->GetLayoutStyle().Width == LayoutLength::Px(50.0f));
}

TEST_CASE("style-manager: a reflected property the sheet set returns to its own value, unless code took it")
{
    RegisterGuiElements();
    auto root = NewRoot();
    auto field = Make<TextField>();
    field->SetPlaceholder(SV(u8"own"));
    root->AddChild(field.Get());
    StyleManager styles(CSSParser::Parse(SV(u8"textfield.hint { placeholder: from the sheet; }")));
    styles.ApplyTree(*root.Get());
    field->AddClass(SV(u8"hint"));
    styles.ApplyTree(*root.Get());
    CHECK(field->GetPlaceholder() == SV(u8"from the sheet"));
    field->RemoveClass(SV(u8"hint"));
    styles.ApplyTree(*root.Get());
    CHECK(field->GetPlaceholder() == SV(u8"own"));

    field->AddClass(SV(u8"hint"));
    styles.ApplyTree(*root.Get());
    field->SetPlaceholder(SV(u8"code's")); // code takes it
    field->RemoveClass(SV(u8"hint"));
    styles.ApplyTree(*root.Get());
    CHECK(field->GetPlaceholder() == SV(u8"code's"));
    field->AddClass(SV(u8"hint"));
    styles.ApplyTree(*root.Get());
    CHECK(field->GetPlaceholder() == SV(u8"code's"));
}

TEST_CASE("style-manager: a hover rule ends, and what it set returns")
{
    auto root = NewRoot();
    auto w = Tagged(*root.Get(), u8"button");
    w->SetSize(core::Float2{100.0f, 40.0f});
    StyleManager styles(CSSParser::Parse(SV(u8"button:hover { opacity: 0.7; padding-left: 12px; }")));
    styles.ApplyTree(*root.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseMove(core::Float2{50.0f, 20.0f});
    styles.ApplyTree(*root.Get());
    CHECK(w->GetAlpha() == doctest::Approx(0.7f));
    CHECK(w->GetPadding().Left == doctest::Approx(12.0f));
    d->InjectMouseMove(core::Float2{150.0f, 150.0f});
    styles.ApplyTree(*root.Get());
    CHECK(w->GetAlpha() == doctest::Approx(1.0f));
    CHECK(w->GetPadding().Left == doctest::Approx(0.0f));
}

// ===================== E3: parts take the box properties =====================


TEST_CASE("style-manager: a part takes a box: background, border, radii, shadow and opacity")
{
    auto root = NewRoot();
    auto slider = Make<Slider>();
    slider->SetSize(core::Float2{160.0f, 24.0f});
    root->AddChild(slider.Get());
    StyleManager styles(CSSParser::Parse(SV(
        u8"slider::thumb { background-color: #ff0000; border: 2px solid #0000ff; border-radius: 3px; box-shadow: 0 2px 4px #00ff00; opacity: 0.5; }")));
    styles.ApplyTree(*root.Get());
    const PartStyle& thumb = slider->GetPartStyle(u8"thumb");
    CHECK(thumb.HasBackground);
    CHECK(thumb.HasBorderWidth);
    CHECK(thumb.HasRadii);
    CHECK(thumb.HasShadows);
    CHECK(thumb.Opacity == doctest::Approx(0.5f));
    CHECK(thumb.Box.Radii.topLeft == doctest::Approx(3.0f));
    CHECK_FALSE(slider->GetPartStyle(u8"track").HasBackground); // the track keeps its own
}

TEST_CASE("style-manager: a part's border-color alone recolours its own outline")
{
    auto root = NewRoot();
    auto box = Make<CheckBox>();
    box->SetSize(core::Float2{20.0f, 20.0f});
    root->AddChild(box.Get());
    StyleManager styles(CSSParser::Parse(SV(u8"checkbox::box { border-color: #ff00ff; }")));
    styles.ApplyTree(*root.Get());
    const PartStyle& part = box->GetPartStyle(u8"box");
    CHECK(part.HasBorderColor);
    CHECK_FALSE(part.HasBorderWidth);
    CHECK_FALSE(part.HasBackground);
    const NodeBox drawn = part.Over(OutlinedBox(core::Color::White, 2.0f));
    CHECK(drawn.BorderWidths.top == doctest::Approx(2.0f)); // its own width
    CHECK(drawn.BorderColors.top.g == doctest::Approx(0.0f)); // the sheet's colour
    CHECK(drawn.BackgroundColor.a == doctest::Approx(0.0f)); // no fill
}

TEST_CASE("style-manager: a restyle that starts below the tree's top still sees the ancestors above it")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto page = Widget(u8"panel", core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    page->AddClass(SV(u8"page"));
    root->AddChild(page.Get());
    auto section = Widget(u8"panel", core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    page->AddChild(section.Get());
    auto cell = Widget(u8"cell", core::Float2{0.0f, 0.0f}, core::Float2{10.0f, 10.0f});
    section->AddChild(cell.Get());

    StyleManager mgr(CSSParser::Parse(SV(u8".page cell { opacity: 0.5; } .other cell { opacity: 0.25; }")));
    mgr.ApplyTree(*section.Get()); // .page is above where the walk starts
    CHECK(cell->GetAlpha() == doctest::Approx(0.5f));
}

TEST_CASE("style-manager: a forced state reads as set, restyling the node, and its subtree when a rule reads it through an ancestor")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto btn = Widget(u8"button", core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    root->AddChild(btn.Get());
    auto label = Widget(u8"label", core::Float2{0.0f, 0.0f}, core::Float2{50.0f, 20.0f});
    btn->AddChild(label.Get());
    StyleManager mgr(CSSParser::Parse(SV(
        u8"button { opacity: 1; } button:hover { opacity: 0.5; } button:disabled { opacity: 0.25; }"
        u8"button:enabled label { opacity: 0.9; } button:hover label { opacity: 0.75; }")));
    mgr.ApplyTree(*root.Get());
    CHECK(btn->GetAlpha() == doctest::Approx(1.0f));
    CHECK(label->GetAlpha() == doctest::Approx(0.9f));

    btn->SetForcedStyleStates(Node::StateHover);
    mgr.ApplyTree(*root.Get());
    CHECK(btn->GetAlpha() == doctest::Approx(0.5f));
    CHECK(label->GetAlpha() == doctest::Approx(0.75f)); // read through its ancestor
    CHECK_FALSE(btn->IsHovered());                      // only the style pass sees it

    btn->SetForcedStyleStates(Node::StateDisabled); // forced disabled is not enabled
    mgr.ApplyTree(*root.Get());
    CHECK(btn->GetAlpha() == doctest::Approx(0.25f));
    CHECK(label->GetAlpha() == doctest::Approx(1.0f)); // neither label rule matches now
    CHECK(btn->IsEnabled());

    btn->SetForcedStyleStates(0);
    mgr.ApplyTree(*root.Get());
    CHECK(btn->GetAlpha() == doctest::Approx(1.0f));
    CHECK(label->GetAlpha() == doctest::Approx(0.9f));
}

TEST_CASE("style-manager: a node says where each property's value came from: a rule, its inline style, code, an ancestor, or itself")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto panel = Widget(u8"panel", core::Float2{0.0f, 0.0f}, core::Float2{200.0f, 200.0f});
    root->AddChild(panel.Get());
    auto btn = Widget(u8"button", core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 40.0f});
    btn->SetId(SV(u8"ok"));
    btn->AddClass(SV(u8"primary"));
    panel->AddChild(btn.Get());
    StyleManager mgr(CSSParser::Parse(SV(
        u8"panel { color: #ff0000; }\n"                       // line 1
        u8"button { opacity: 0.8; padding: 4px; }\n"          // line 2
        u8".primary { opacity: 0.6 !important; }\n"           // line 3
        u8"#ok { opacity: 0.3; margin: 2px; height: 30px; }\n"), // line 4
        SV(u8"app.css")));
    btn->SetInlineStyle(SV(u8"margin-left"), SV(u8"9px")); // markup's attribute
    btn->SetPadding(Thickness{1.0f});                      // code: the padding is its own now
    mgr.ApplyTree(*root.Get());

    const StyleExplanation opacity = mgr.ExplainProperty(*btn.Get(), SV(u8"opacity"));
    CHECK(opacity.Origin == StyleOrigin::Sheet);
    CHECK(opacity.Value == SV(u8"0.6"));
    REQUIRE(opacity.Declarations.Size() == 3u); // the winner first, then by precedence
    CHECK(opacity.Declarations[0].Selector == SV(u8".primary"));
    CHECK(opacity.Declarations[0].Line == 3u);
    CHECK(opacity.Declarations[0].Important);
    CHECK(opacity.Declarations[0].Sheet == SV(u8"app.css"));
    CHECK(opacity.Declarations[1].Selector == SV(u8"#ok"));
    CHECK(opacity.Declarations[2].Selector == SV(u8"button"));
    CHECK(opacity.Declarations[2].Line == 2u);

    const StyleExplanation marginLeft = mgr.ExplainProperty(*btn.Get(), SV(u8"margin-left"));
    CHECK(marginLeft.Origin == StyleOrigin::Inline); // over the sheet's shorthand
    REQUIRE(marginLeft.Declarations.Size() == 2u);
    CHECK(marginLeft.Declarations[0].Inline);
    CHECK(marginLeft.Declarations[1].Selector == SV(u8"#ok")); // its margin's longhand
    CHECK(marginLeft.Declarations[1].Value == SV(u8"2px"));

    const StyleExplanation paddingTop = mgr.ExplainProperty(*btn.Get(), SV(u8"padding-top"));
    CHECK(paddingTop.Origin == StyleOrigin::Code); // the sheet's padding is overridden
    REQUIRE(paddingTop.Declarations.Size() == 1u);
    CHECK(paddingTop.Declarations[0].Selector == SV(u8"button"));

    const StyleExplanation color = mgr.ExplainProperty(*btn.Get(), SV(u8"color"));
    CHECK(color.Origin == StyleOrigin::Inherited);
    CHECK(color.InheritedFrom == panel.Get());
    CHECK(color.Declarations.IsEmpty());

    CHECK(mgr.ExplainProperty(*btn.Get(), SV(u8"z-index")).Origin == StyleOrigin::Own);

    // The whole list holds each of them once.
    const core::Array<StyleExplanation> all = mgr.ExplainStyle(*btn.Get());
    int found = 0;
    for (const StyleExplanation& e : all)
        found += (e.Property == SV(u8"opacity") || e.Property == SV(u8"color") || e.Property == SV(u8"padding-top") ||
                  e.Property == SV(u8"height")) ? 1 : 0;
    CHECK(found == 4);
}

TEST_CASE("style-manager: a child added restyles its siblings only when a rule reads siblings")
{
    const auto build = [](core::RefPtr<SceneRoot>& root, core::RefPtr<UIWidget>& column)
    {
        root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{200.0f, 400.0f});
        column = Widget(u8"column", core::Float2{0.0f, 0.0f}, core::Float2{200.0f, 400.0f});
        root->AddChild(column.Get());
        for (int i = 0; i < 20; ++i)
            column->AddChild(Widget(u8"row", core::Float2{0.0f, 0.0f}, core::Float2{200.0f, 10.0f}).Get());
    };
    {
        // No rule reads siblings: the new row and its column restyle, the other twenty do not.
        core::RefPtr<SceneRoot> root;
        core::RefPtr<UIWidget> column;
        build(root, column);
        StyleManager mgr(CSSParser::Parse(SV(u8"row { opacity: 0.5; }")));
        mgr.ApplyTree(*root.Get());
        column->AddChild(Widget(u8"row", core::Float2{0.0f, 0.0f}, core::Float2{200.0f, 10.0f}).Get());
        mgr.ApplyTree(*root.Get());
        CHECK(mgr.LastRestyleCount() == 2u);
    }
    {
        // :nth-child reads them: taking the first row away flips every other row's match.
        core::RefPtr<SceneRoot> root;
        core::RefPtr<UIWidget> column;
        build(root, column);
        StyleManager mgr(CSSParser::Parse(SV(u8"row { opacity: 1; } row:nth-child(odd) { opacity: 0.5; }")));
        mgr.ApplyTree(*root.Get());
        Node* second = column->GetChildAt(1);
        CHECK(second->GetAlpha() == doctest::Approx(1.0f));
        column->RemoveChild(column->GetChildAt(0));
        mgr.ApplyTree(*root.Get());
        CHECK(mgr.LastRestyleCount() >= 19u);
        CHECK(second->GetAlpha() == doctest::Approx(0.5f)); // first now: odd
    }
}

TEST_CASE("style-manager: a declaration edited in its rule restyles every node the rule matches")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto a = Widget(u8"button", core::Float2{0.0f, 0.0f}, core::Float2{50.0f, 20.0f});
    auto b = Widget(u8"button", core::Float2{0.0f, 30.0f}, core::Float2{50.0f, 20.0f});
    root->AddChild(a.Get());
    root->AddChild(b.Get());
    StyleManager mgr(CSSParser::Parse(SV(u8"button { opacity: 0.8; padding: 4px; }"), SV(u8"app.css")));
    mgr.ApplyTree(*root.Get());
    const StyleExplanation opacity = mgr.ExplainProperty(*a.Get(), SV(u8"opacity"));
    REQUIRE(opacity.Declarations.Size() == 1u);
    REQUIRE(opacity.Declarations[0].Rule != nullptr);
    CHECK(mgr.EditDeclaration(opacity.Declarations[0].Rule, SV(u8"opacity"), SV(u8"0.4")));
    // A longhand of the rule's shorthand: that side alone.
    CHECK(mgr.EditDeclaration(opacity.Declarations[0].Rule, SV(u8"padding-left"), SV(u8"9px")));
    mgr.ApplyTree(*root.Get());
    CHECK(a->GetAlpha() == doctest::Approx(0.4f));
    CHECK(b->GetAlpha() == doctest::Approx(0.4f)); // the rule's every node
    CHECK(a->GetPadding().Left == doctest::Approx(9.0f));
    CHECK(a->GetPadding().Top == doctest::Approx(4.0f));
    const StyleRule stranger(SV(u8"button"));
    CHECK_FALSE(mgr.EditDeclaration(&stranger, SV(u8"opacity"), SV(u8"1")));
}

TEST_CASE("style: em measures by the element's own font size, which takes em and percentages of its parent's")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto box = core::MakeRef<Panel>(core::DefaultAllocator());
    box->AddClass(core::StringView(u8"big"));
    root->AddChild(box.Get());
    auto pct = core::MakeRef<Panel>(core::DefaultAllocator());
    pct->AddClass(core::StringView(u8"pct"));
    root->AddChild(pct.Get());
    StyleManager styles(CSSParser::Parse(core::StringView(u8".big { font-size: 2em; padding-left: 1em; } .pct { font-size: 150%; padding-left: 1em; }")));
    styles.ApplyTree(*root.Get());
    CHECK(box->GetPadding().Left == doctest::Approx(32.0f)); // 2em of the root's 16, then 1em of that
    CHECK(pct->GetPadding().Left == doctest::Approx(24.0f));
}

TEST_CASE("style: a number property takes a percentage as a fraction and refuses a unit")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto half = core::MakeRef<Panel>(core::DefaultAllocator());
    half->AddClass(core::StringView(u8"half"));
    root->AddChild(half.Get());
    auto junk = core::MakeRef<Panel>(core::DefaultAllocator());
    junk->AddClass(core::StringView(u8"junk"));
    root->AddChild(junk.Get());
    StyleManager styles(CSSParser::Parse(core::StringView(u8".half { opacity: 50%; } .junk { opacity: 0.3px; }")));
    styles.ApplyTree(*root.Get());
    CHECK(half->GetAlpha() == doctest::Approx(0.5f)); // not 50
    CHECK(junk->GetAlpha() == doctest::Approx(1.0f)); // not a number: its own value
}
