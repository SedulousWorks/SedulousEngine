// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Separator and Spacer (E6): oriented by their parent's flex direction; a separator's line
// stretched across, as thick as its thickness; a spacer flexible or of a fixed size.
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

    core::RefPtr<Panel> Fixed(Node& parent, float w, float h)
    {
        auto p = Make<Panel>();
        p->EditLayoutStyle([w, h](LayoutStyle& s)
        {
            s.Width = LayoutLength::Px(w);
            s.Height = LayoutLength::Px(h);
        });
        parent.AddChild(p.Get());
        return p;
    }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Panel> line = Make<Panel>();
        explicit Bed(FlexDirection direction)
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            line->EditLayoutStyle([direction](LayoutStyle& s)
            {
                s.Direction = direction;
                s.Width = LayoutLength::Px(200.0f);
                s.Height = LayoutLength::Px(100.0f);
                s.AlignItems = Align::Center;
            });
            root->AddChild(line.Get());
        }
    };
}

TEST_CASE("separator: in a column it lies across the column; in a row it stands the row's height")
{
    Bed column(FlexDirection::Column);
    Fixed(*column.line, 50.0f, 20.0f);
    auto across = Make<Separator>();
    column.line->AddChild(across.Get());
    (void)column.root->UpdateLayout();
    CHECK_FALSE(across->IsVertical());
    CHECK(across->GetSize().x == doctest::Approx(200.0f));
    CHECK(across->GetSize().y == doctest::Approx(1.0f));

    Bed row(FlexDirection::Row);
    Fixed(*row.line, 50.0f, 20.0f);
    auto up = Make<Separator>();
    up->SetThickness(2.0f);
    row.line->AddChild(up.Get());
    (void)row.root->UpdateLayout();
    CHECK(up->IsVertical());
    CHECK(up->GetSize().x == doctest::Approx(2.0f));
    CHECK(up->GetSize().y == doctest::Approx(100.0f)); // stretched, though the row centres its items
}

TEST_CASE("spacer: flexible it takes the room left; sized it holds its length")
{
    Bed row(FlexDirection::Row);
    Fixed(*row.line, 40.0f, 20.0f);
    auto gap = Make<Spacer>();
    row.line->AddChild(gap.Get());
    auto last = Fixed(*row.line, 40.0f, 20.0f);
    (void)row.root->UpdateLayout();
    CHECK(gap->GetSize().x == doctest::Approx(120.0f));
    CHECK(last->GetPosition().x == doctest::Approx(160.0f)); // pushed to the end

    gap->SetSpace(12.0f);
    (void)row.root->UpdateLayout();
    CHECK(gap->GetSize().x == doctest::Approx(12.0f));
    CHECK(last->GetPosition().x == doctest::Approx(52.0f));

    Bed column(FlexDirection::Column);
    auto tall = Make<Spacer>();
    tall->SetSpace(30.0f);
    column.line->AddChild(tall.Get());
    (void)column.root->UpdateLayout();
    CHECK(tall->GetSize().y == doctest::Approx(30.0f));
}

TEST_CASE("separator and spacer: markup and sheets set thickness and size")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    auto tree = loader.LoadFromString(core::StringView(u8R"(<Panel flex-direction="row"><Separator thickness="3"/><Spacer size="8"/></Panel>)"));
    REQUIRE(tree.Get() != nullptr);
    REQUIRE(tree->ChildCount() == 2);
    CHECK(core::Cast<Separator>(tree->GetChildAt(0))->GetThickness() == doctest::Approx(3.0f));
    CHECK(core::Cast<Spacer>(tree->GetChildAt(1))->GetSpace() == doctest::Approx(8.0f));
}
