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
