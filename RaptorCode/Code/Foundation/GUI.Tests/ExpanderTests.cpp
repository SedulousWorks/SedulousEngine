// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Expander (E6): HTML's <details>. Its header toggles `open` and reports `toggle`; one of a
// name per GUI open at a time; content built on first open; an optional eased height.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
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

    core::RefPtr<SceneRoot> MakeRoot()
    {
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{300.0f, 400.0f});
        return root;
    }

    core::RefPtr<Expander> AddExpander(SceneRoot& root, float contentHeight)
    {
        auto e = Make<Expander>();
        e->SetTitle(core::StringView(u8"Advanced"));
        auto body = Make<Panel>();
        body->EditLayoutStyle([contentHeight](LayoutStyle& s) { s.Height = LayoutLength::Px(contentHeight); });
        e->GetContent()->AddChild(body.Get());
        root.AddChild(e.Get());
        return e;
    }
}

TEST_CASE("expander: markup's children are its content; open, name, title and animate are attributes")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    auto tree = loader.LoadFromString(core::StringView(u8R"(<Expander title="More" open="true" name="g" animate="true"><Label text="inside"/></Expander>)"));
    REQUIRE(tree.Get() != nullptr);
    auto* e = core::Cast<Expander>(tree.Get());
    REQUIRE(e != nullptr);
    CHECK(e->IsOpen());
    CHECK(e->IsAnimated());
    CHECK(e->GetName() == core::StringView(u8"g"));
    CHECK(e->GetTitle() == core::StringView(u8"More"));
    CHECK(e->GetContent()->ChildCount() == 1);
}
