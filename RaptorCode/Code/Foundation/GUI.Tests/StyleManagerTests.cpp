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

// ===================== E3: parts take the box properties =====================
