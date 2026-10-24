// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the parts a widget places or draws itself mirror in right to left (E17a of
// Specs/gui-lab-evolution-2.md). Each widget is drawn running left to right and right to left, and
// what it draws in each colour must cover, in right to left, the mirror of what it covers in left to
// right: a part at the inline start moves to the other edge with its shape mirrored, and text
// aligned to its start goes with it.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace vg = foundation::vg;
using core::f32;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    // What one colour covers.
    struct Ink
    {
        core::u32 colour = 0;
        Rect bounds{};
    };

    core::u32 Key(const core::Color& c)
    {
        const auto q = [](f32 v) { return static_cast<core::u32>(core::Clamp(v, 0.0f, 1.0f) * 255.0f + 0.5f); };
        return q(c.r) << 24 | q(c.g) << 16 | q(c.b) << 8 | q(c.a);
    }
    void Cover(core::Array<Ink>& inks, const core::Color& colour, core::Float2 p)
    {
        if (colour.a <= 0.0f)
            return;
        const core::u32 key = Key(colour);
        for (Ink& ink : inks)
            if (ink.colour == key)
            {
                ink.bounds = Rect::Merge(ink.bounds, Rect{p.x, p.y, 0.0f, 0.0f});
                return;
            }
        inks.PushBack(Ink{key, Rect{p.x, p.y, 0.0f, 0.0f}});
    }

    using Factory = core::RefPtr<UIWidget> (*)();

    // A widget `make` makes, drawn in a root running as `rightToLeft` says: what each colour covers.
    core::Array<Ink> Drawn(Factory make, core::Float2 size, bool rightToLeft)
    {
        const core::RefPtr<UIWidget> widget = make();
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{400.0f, 300.0f});
        root->SetLayoutDirection(rightToLeft ? Node::LayoutDirection::RightToLeft : Node::LayoutDirection::LeftToRight);
        widget->SetSize(size);
        root->AddChild(widget.Get());
        // Styled by the default theme either way, so its colours are its theme's in both.
        StyleManager styles;
        styles.SetStyleSheet(CSSParser::Parse(DefaultThemeCSS()));
        styles.ApplyTree(*root.Get());
        (void)root->UpdateLayout();
        vg::VGContext canvas;
        DrawContext dc{canvas};
        widget->Draw(dc);
        // In the widget's own space: the root's layout places it at the other side too.
        const core::Float2 at = widget->ConvertToRootSpace(core::Float2{0.0f, 0.0f});
        core::Array<Ink> inks;
        for (const vg::VGVertex& v : canvas.GetBatch().vertices)
            Cover(inks, v.color, core::Float2{v.position.x - at.x, v.position.y - at.y});
        for (const vg::VGBoxVertex& v : canvas.GetBatch().boxVertices)
            Cover(inks, v.fill, core::Float2{v.position.x - at.x, v.position.y - at.y});
        root->RemoveChild(widget.Get());
        return inks;
    }

    // Every colour's ink in right to left is the mirror of its ink in left to right across the
    // widget; and there is something mirrored to see (`asymmetric`: at least one ink not centred).
    void CheckMirrored(Factory make, core::Float2 size)
    {
        const core::Array<Ink> ltr = Drawn(make, size, false);
        const core::Array<Ink> rtl = Drawn(make, size, true);
        REQUIRE(ltr.Size() == rtl.Size());
        const Rect box{0.0f, 0.0f, size.x, size.y};
        bool asymmetric = false;
        for (const Ink& a : ltr)
        {
            const Ink* b = nullptr;
            for (const Ink& c : rtl)
                if (c.colour == a.colour)
                    b = &c;
            REQUIRE(b != nullptr);
            const Rect mirrored = MirroredIn(a.bounds, box, true);
            CAPTURE(a.colour);
            CHECK(b->bounds.x == doctest::Approx(mirrored.x).epsilon(0.02));
            CHECK(b->bounds.width == doctest::Approx(mirrored.width).epsilon(0.02));
            CHECK(b->bounds.y == doctest::Approx(a.bounds.y));
            CHECK(b->bounds.height == doctest::Approx(a.bounds.height));
            if (core::Abs(a.bounds.x - mirrored.x) > 1.0f)
                asymmetric = true;
        }
        CHECK(asymmetric);
    }
}

TEST_CASE("mirror: a number field's arrows and its text room are at its inline end")
{
    CheckMirrored(
        []() -> core::RefPtr<UIWidget>
        {
            auto field = Make<NumberField>();
            field->SetValue(42.0);
            return field;
        },
        core::Float2{120.0f, 24.0f});
}

TEST_CASE("mirror: a tree row is indented from the inline start, its arrow before its text")
{
    CheckMirrored(
        []() -> core::RefPtr<UIWidget>
        {
            auto row = Make<TreeRowContent>();
            row->GetLabel()->SetText(core::StringView(u8"Node"));
            row->Configure(32.0f, 16.0f, true, false);
            return row;
        },
        core::Float2{200.0f, 20.0f});
}
