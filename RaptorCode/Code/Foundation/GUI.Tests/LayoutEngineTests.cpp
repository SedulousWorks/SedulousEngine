// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - measure and arrange (E2 of Specs/gui-lab-evolution.md): a node asks for a size within
// constraints and its container places it; the display kinds (flex by CSS's rules, grid, stack,
// dock) and the out-of-flow children; sizes in lengths, percentages and auto, min and max, the
// box sizing; visibility against display; what a change lays out again; and the same from a sheet.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
using core::f32;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    template <typename... T>
    core::Array<GridTrack> Tracks(T... tracks)
    {
        core::Array<GridTrack> out;
        (out.PushBack(tracks), ...);
        return out;
    }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        Bed(f32 w = 400.0f, f32 h = 300.0f) { root->SetSize(core::Float2{w, h}); }
        void Layout() { root->UpdateLayout(); }
    };
    template <typename F>
    core::RefPtr<Panel> Box(Node& parent, F&& style)
    {
        auto panel = core::MakeRef<Panel>(core::DefaultAllocator());
        panel->EditLayoutStyle(static_cast<F&&>(style));
        parent.AddChild(panel.Get());
        return panel;
    }
    core::RefPtr<Panel> Fixed(Node& parent, f32 w, f32 h)
    {
        return Box(parent, [w, h](LayoutStyle& s) {
            s.Width = LayoutLength::Px(w);
            s.Height = LayoutLength::Px(h);
        });
    }
    void CheckRect(const Node& node, f32 x, f32 y, f32 w, f32 h)
    {
        CHECK(node.GetPosition().x == doctest::Approx(x));
        CHECK(node.GetPosition().y == doctest::Approx(y));
        CHECK(node.GetSize().x == doctest::Approx(w));
        CHECK(node.GetSize().y == doctest::Approx(h));
    }
}

namespace
{
    // 6px a byte, 12px a line.
    class SixFont : public fonts::IFont
    {
    public:
        core::StringView FamilyName() const override { return core::StringView(u8"six"); }
        core::Span<const core::u8> SourceData() const override { return {}; }
        fonts::FontMetrics Metrics() const override
        {
            fonts::FontMetrics m;
            m.ascent = 10.0f;
            m.descent = -2.0f;
            m.lineHeight = 12.0f;
            m.pixelHeight = 10.0f;
            m.scale = 1.0f;
            return m;
        }
        f32 PixelHeight() const override { return 10.0f; }
        fonts::GlyphInfo GetGlyphInfo(core::i32 cp) const override
        {
            fonts::GlyphInfo g;
            g.codepoint = cp;
            g.advanceWidth = 6.0f;
            return g;
        }
        f32 GetKerning(core::i32, core::i32) const override { return 0.0f; }
        bool HasGlyph(core::i32) const override { return true; }
        f32 MeasureString(core::StringView text) const override { return static_cast<f32>(text.Size()) * 6.0f; }
        f32 MeasureString(core::StringView text, core::Array<fonts::GlyphPosition>&) const override
        {
            return static_cast<f32>(text.Size()) * 6.0f;
        }
    };
}

TEST_CASE("layout: a label and a button size to their text, and follow it")
{
    fonts::CachedFont font(core::DefaultAllocator(), core::DefaultAllocator().New<SixFont>(), nullptr, nullptr);
    Bed bed;
    auto row = Box(*bed.root.Get(), [](LayoutStyle& s) { s.Direction = FlexDirection::Row; s.AlignItems = Align::Start; s.ColumnGap = 10.0f; });
    auto label = core::MakeRef<Label>(core::DefaultAllocator());
    label->SetFont(&font);
    label->SetText(SV(u8"Score"));
    label->SetPadding(Thickness{4.0f});
    row->AddChild(label.Get());
    auto button = core::MakeRef<Button>(core::DefaultAllocator());
    button->SetFont(&font);
    button->SetText(SV(u8"Play"));
    button->SetPadding(Thickness{10.0f, 6.0f});
    row->AddChild(button.Get());
    auto box = core::MakeRef<CheckBox>(core::DefaultAllocator());
    row->AddChild(box.Get());
    bed.Layout();
    CheckRect(*label, 0, 0, 5 * 6 + 8, 12 + 8);
    CheckRect(*button, 38 + 10, 0, 4 * 6 + 20, 12 + 12);
    CHECK(box->GetSize().x == doctest::Approx(20.0f));
    label->SetText(SV(u8"Score: 120"));
    bed.Layout();
    CHECK(label->GetSize().x == doctest::Approx(10 * 6 + 8));
    CHECK(button->GetPosition().x == doctest::Approx(68.0f + 10.0f)); // moved along with it
}


TEST_CASE("layout: a row aligned by baseline lines up its items' text, and grows to hold them")
{
    // SixFont's ascent is 10 on a 12 line. A label's baseline is its padding plus the ascent
    // (its line fills its content box); a button's the same; a plain box's the bottom of its
    // content box.
    fonts::CachedFont font(core::DefaultAllocator(), core::DefaultAllocator().New<SixFont>(), nullptr, nullptr);
    Bed bed;
    auto row = Box(*bed.root.Get(), [](LayoutStyle& s) { s.Direction = FlexDirection::Row; s.AlignItems = Align::Baseline; });
    auto label = core::MakeRef<Label>(core::DefaultAllocator());
    label->SetFont(&font);
    label->SetText(SV(u8"Name"));
    label->SetPadding(Thickness{4.0f}); // 20 tall, baseline 14
    row->AddChild(label.Get());
    auto button = core::MakeRef<Button>(core::DefaultAllocator());
    button->SetFont(&font);
    button->SetText(SV(u8"Go"));
    button->SetPadding(Thickness{10.0f, 6.0f}); // 24 tall, baseline 16
    row->AddChild(button.Get());
    auto box = Fixed(*row.Get(), 40.0f, 30.0f); // baseline 30
    auto pushed = core::MakeRef<Label>(core::DefaultAllocator());
    pushed->SetFont(&font);
    pushed->SetText(SV(u8"x"));
    pushed->SetPadding(Thickness{4.0f});
    pushed->SetMargin(Thickness{0.0f, 6.0f, 0.0f, 0.0f}); // its margin box's baseline at 20
    row->AddChild(pushed.Get());
    bed.Layout();

    // The baselines meet at 30, the deepest above it; each item sits so its baseline is there.
    CHECK(label->GetPosition().y == doctest::Approx(16.0f));
    CHECK(button->GetPosition().y == doctest::Approx(14.0f));
    CHECK(box->GetPosition().y == doctest::Approx(0.0f));
    CHECK(pushed->GetPosition().y == doctest::Approx(16.0f)); // 10 down, then its margin
    CHECK(label->GetPosition().y + label->GetBaseline() == doctest::Approx(30.0f));
    CHECK(button->GetPosition().y + button->GetBaseline() == doctest::Approx(30.0f));
    // The row holds what reaches furthest below the baseline too: the button's 8.
    CHECK(row->GetSize().y == doctest::Approx(38.0f));

    // In a column, baseline places as start.
    row->EditLayoutStyle([](LayoutStyle& s) { s.Direction = FlexDirection::Column; });
    bed.Layout();
    CHECK(label->GetPosition().x == doctest::Approx(0.0f));
    CHECK(box->GetPosition().x == doctest::Approx(0.0f));
}

namespace
{
    // The box the vertices of one colour cover (by its red, green and blue), and how many.
    struct Extent
    {
        core::usize count = 0;
        core::Float2 min{1.0e9f, 1.0e9f};
        core::Float2 max{-1.0e9f, -1.0e9f};
    };
    Extent ExtentOf(foundation::vg::VGContext& vg, core::Color color)
    {
        Extent e;
        for (const foundation::vg::VGVertex& v : vg.GetBatch().vertices)
            if (core::Abs(v.color.r - color.r) < 0.01f && core::Abs(v.color.g - color.g) < 0.01f &&
                core::Abs(v.color.b - color.b) < 0.01f)
            {
                ++e.count;
                e.min = core::Float2{core::Min(e.min.x, v.position.x), core::Min(e.min.y, v.position.y)};
                e.max = core::Float2{core::Max(e.max.x, v.position.x), core::Max(e.max.y, v.position.y)};
            }
        return e;
    }
}

namespace
{
    // A leaf that counts how often layout asks what it holds.
    class CountingLeaf : public Node
    {
    public:
        core::Float2 MeasureContent(core::Float2) override
        {
            ++Measures;
            return core::Float2{50.0f, 20.0f};
        }
        int Measures = 0;
    };
}

