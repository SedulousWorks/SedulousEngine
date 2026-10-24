// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the Splitter (D0 of Specs/gui-lab-evolution-3.md): panes laid out by their weights with a
// handle between each two; minimums held (a sheet's, never the content's), the rest shared again;
// when even the minimums do not fit, each has its own and the end is clipped; a handle moves the two
// panes beside it alone, by the pointer and the keys; a pane that goes gives its share to its
// neighbours; vertical, right to left, markup, and a handle read as a separator.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::usize;

namespace
{
    core::RefPtr<Panel> Pane(f32 minWidth = -1.0f)
    {
        core::RefPtr<Panel> pane = core::MakeRef<Panel>(core::DefaultAllocator());
        if (minWidth >= 0.0f)
            pane->EditLayoutStyle([minWidth](LayoutStyle& s) { s.MinWidth = LayoutLength::Px(minWidth); });
        return pane;
    }

    // A root with a splitter 300 by 100 in it, its panes added.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Splitter> splitter = core::MakeRef<Splitter>(core::DefaultAllocator());
        core::Array<core::RefPtr<Panel>> panes;

        explicit Bed(usize count, f32 width = 300.0f)
        {
            root->SetSize(core::Float2{800.0f, 600.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            splitter->EditLayoutStyle([width](LayoutStyle& s) {
                s.Width = LayoutLength::Px(width);
                s.Height = LayoutLength::Px(100.0f);
            });
            for (usize i = 0; i < count; ++i)
            {
                panes.PushBack(Pane());
                splitter->AddChild(panes.Back().Get());
            }
            root->AddChild(splitter.Get());
            Lay();
        }
        void Lay() { root->UpdateLayout(); }
        [[nodiscard]] f32 X(usize pane) const { return panes[pane]->GetPosition().x; }
        [[nodiscard]] f32 W(usize pane) const { return panes[pane]->GetSize().x; }
    };
}

TEST_CASE("splitter: from markup, and each handle read as a separator with where it stands")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> loaded =
        loader.LoadFromString(core::StringView(u8R"(<Splitter axis="vertical" weights="1 3"><Panel/><Panel/></Splitter>)"));
    REQUIRE(loaded.Get() != nullptr);
    auto* splitter = Cast<Splitter>(loaded.Get());
    REQUIRE(splitter != nullptr);
    CHECK(splitter->GetAxis() == SplitterAxis::Vertical);
    REQUIRE(splitter->GetPaneCount() == 2u);
    CHECK(splitter->GetWeights()[1] == doctest::Approx(0.75f));

    core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 406.0f});
    splitter->EditLayoutStyle([](LayoutStyle& s) {
        s.Width = LayoutLength::Px(400.0f);
        s.Height = LayoutLength::Px(406.0f); // 400 for the panes, a quarter above the handle
    });
    root->AddChild(loaded.Get());
    root->UpdateLayout();
    const AccessTreeUpdate tree = root->GetContext().BuildAccessTree(*root.Get());
    const AccessNode* separator = nullptr;
    for (const AccessNode& n : tree.Nodes)
        if (n.Role == AccessRole::Separator)
            separator = &n;
    REQUIRE(separator != nullptr);
    CHECK(separator->Max == doctest::Approx(100.0));
    CHECK(separator->Value == core::StringView(u8"25"));
    CHECK((separator->States & AccessFocusable) != 0);
}
