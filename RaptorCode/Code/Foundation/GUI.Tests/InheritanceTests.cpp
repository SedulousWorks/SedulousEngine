// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - inheritance and the CSS-wide keywords (E3 of Specs/gui-lab-evolution.md): colour, the
// font and text-align pass from a node to what it holds, through nodes that draw no text; a
// declared value wins; vertical-align does not inherit; inherit, initial and unset settle as
// CSS's do; what code sets on a parent reaches the subtree.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.image;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace image = foundation::image;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // A face that answers to the family and size it was made for.
    class NamedFont : public fonts::IFont
    {
    public:
        NamedFont(core::StringView family, core::f32 size) : m_family(family), m_size(size) {}
        core::StringView FamilyName() const override { return m_family.AsView(); }
        core::Span<const core::u8> SourceData() const override { return {}; }
        fonts::FontMetrics Metrics() const override
        {
            fonts::FontMetrics m;
            m.ascent = m_size * 0.8f;
            m.descent = -m_size * 0.2f;
            m.lineHeight = m_size;
            m.pixelHeight = m_size;
            m.scale = 1.0f;
            return m;
        }
        core::f32 PixelHeight() const override { return m_size; }
        fonts::GlyphInfo GetGlyphInfo(core::i32 cp) const override
        {
            fonts::GlyphInfo g;
            g.codepoint = cp;
            g.advanceWidth = m_size * 0.5f;
            return g;
        }
        core::f32 GetKerning(core::i32, core::i32) const override { return 0.0f; }
        bool HasGlyph(core::i32) const override { return true; }
        core::f32 MeasureString(core::StringView t) const override { return static_cast<core::f32>(t.Size()) * m_size * 0.5f; }
        core::f32 MeasureString(core::StringView t, core::Array<fonts::GlyphPosition>&) const override { return MeasureString(t); }

    private:
        core::String m_family;
        core::f32 m_size;
    };

    // One cached font per family and size asked for.
    class Fonts : public fonts::IFontService
    {
    public:
        ~Fonts() override
        {
            for (fonts::CachedFont* f : m_fonts)
                core::DefaultAllocator().Delete(f);
        }
        fonts::CachedFont* GetFont(core::f32 size) override { return GetFont(SV(u8"default"), size); }
        fonts::CachedFont* GetFont(core::StringView family, core::f32 size) override
        {
            for (fonts::CachedFont* f : m_fonts)
                if (f->font->FamilyName() == family && f->font->PixelHeight() == size)
                    return f;
            m_fonts.PushBack(core::DefaultAllocator().New<fonts::CachedFont>(core::DefaultAllocator(),
                                                                               core::DefaultAllocator().New<NamedFont>(family, size), nullptr, nullptr));
            return m_fonts[m_fonts.Size() - 1];
        }
        image::ImageData* GetAtlasTexture(fonts::CachedFont*) override { return nullptr; }
        image::ImageData* GetAtlasTexture(core::StringView, core::f32) override { return nullptr; }
        void ReleaseFont(fonts::CachedFont*) override {}
        core::StringView DefaultFontFamily() const override { return SV(u8"default"); }
        bool HasFamily(core::StringView) const override { return true; }

    private:
        core::Array<fonts::CachedFont*> m_fonts;
    };

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Panel> panel = core::MakeRef<Panel>(core::DefaultAllocator());
        core::RefPtr<Panel> inner = core::MakeRef<Panel>(core::DefaultAllocator());
        core::RefPtr<Label> label = core::MakeRef<Label>(core::DefaultAllocator());
        Fonts fonts;
        StyleManager styles;
        explicit Bed(const char8_t* css)
        {
            root->AddChild(panel.Get());
            panel->AddChild(inner.Get());
            inner->AddChild(label.Get());
            panel->AddClass(SV(u8"outer"));
            styles.SetFontService(&fonts);
            styles.SetStyleSheet(CSSParser::Parse(SV(css)));
            styles.ApplyTree(*root.Get());
        }
        void Restyle() { styles.ApplyTree(*root.Get()); }
    };
    bool Same(core::Color a, core::Color b) { return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a; }
}

TEST_CASE("inheritance: colour, the font and text-align pass down through nodes that draw no text")
{
    Bed bed(u8".outer { color: #ff0000; font-family: Serif; font-size: 20px; text-align: center; vertical-align: bottom; }");
    CHECK(Same(bed.label->GetTextColor(), core::Color{1.0f, 0.0f, 0.0f, 1.0f}));
    REQUIRE(bed.label->GetFont() != nullptr);
    CHECK(bed.label->GetFont()->font->FamilyName() == SV(u8"Serif"));
    CHECK(bed.label->GetFont()->font->PixelHeight() == doctest::Approx(20.0f));
    CHECK(bed.label->GetTextAlignH() == TextHAlign::Center);
    CHECK(bed.label->GetTextAlignV() == TextVAlign::Middle); // vertical-align does not inherit: the label's own
}

TEST_CASE("inheritance: a declared value wins, a size alone keeps the inherited family, and it all goes when the rule does")
{
    Bed bed(u8".outer { color: #ff0000; font-family: Serif; font-size: 20px; } label.big { font-size: 30px; } label.blue { color: #0000ff; }");
    const core::Color own = core::Color::White;
    bed.label->AddClass(SV(u8"big"));
    bed.label->AddClass(SV(u8"blue"));
    bed.Restyle();
    CHECK(Same(bed.label->GetTextColor(), core::Color{0.0f, 0.0f, 1.0f, 1.0f}));
    CHECK(bed.label->GetFont()->font->FamilyName() == SV(u8"Serif"));
    CHECK(bed.label->GetFont()->font->PixelHeight() == doctest::Approx(30.0f));

    bed.label->RemoveClass(SV(u8"blue"));
    bed.Restyle();
    CHECK(Same(bed.label->GetTextColor(), core::Color{1.0f, 0.0f, 0.0f, 1.0f})); // the parent's again

    bed.panel->RemoveClass(SV(u8"outer"));
    bed.label->RemoveClass(SV(u8"big"));
    bed.Restyle();
    CHECK(Same(bed.label->GetTextColor(), own)); // nobody sets it: the label's own
    CHECK(bed.label->GetFont() == nullptr);
}

TEST_CASE("inheritance: a parent's change reaches its subtree, from the sheet or from code")
{
    Bed bed(u8".outer { color: #ff0000; } .outer.cool { color: #00ffff; }");
    bed.panel->AddClass(SV(u8"cool"));
    bed.Restyle();
    CHECK(Same(bed.label->GetTextColor(), core::Color{0.0f, 1.0f, 1.0f, 1.0f}));

    // Code's colour on the middle panel is its own, and the label below takes it.
    bed.inner->SetTextColor(core::Color{0.0f, 1.0f, 0.0f, 1.0f});
    bed.Restyle();
    CHECK(Same(bed.label->GetTextColor(), core::Color{0.0f, 1.0f, 0.0f, 1.0f}));
    bed.panel->RemoveClass(SV(u8"cool"));
    bed.Restyle();
    CHECK(Same(bed.inner->GetTextColor(), core::Color{0.0f, 1.0f, 0.0f, 1.0f}));
}

TEST_CASE("inheritance: inherit, initial and unset")
{
    Bed bed(u8".outer { color: #ff0000; padding: 6px; } "
            u8"label.mine { color: initial; } "
            u8"label.pass { color: unset; } "
            u8"panel.copy { padding: inherit; } "
            u8"panel.grow { padding: 4px; width: 50px; } panel.grow.reset { width: initial; padding: unset; }");
    bed.label->AddClass(SV(u8"mine"));
    bed.Restyle();
    CHECK(Same(bed.label->GetTextColor(), core::Color::White)); // initial: its own, not the parent's
    bed.label->RemoveClass(SV(u8"mine"));
    bed.label->AddClass(SV(u8"pass"));
    bed.Restyle();
    CHECK(Same(bed.label->GetTextColor(), core::Color{1.0f, 0.0f, 0.0f, 1.0f})); // unset on an inherited property: inherit

    bed.inner->AddClass(SV(u8"copy"));
    bed.Restyle();
    CHECK(bed.inner->GetPadding().Left == doctest::Approx(6.0f)); // inherit on one that does not: the parent's

    bed.inner->RemoveClass(SV(u8"copy"));
    bed.inner->AddClass(SV(u8"grow"));
    bed.Restyle();
    CHECK(bed.inner->GetLayoutStyle().Width == LayoutLength::Px(50.0f));
    bed.inner->AddClass(SV(u8"reset"));
    bed.Restyle();
    CHECK(bed.inner->GetLayoutStyle().Width.IsAuto());                // initial: the table's (auto)
    CHECK(bed.inner->GetPadding().Left == doctest::Approx(0.0f));     // unset: initial, the node's own
}

TEST_CASE("inheritance: white-space, line-height and letter-spacing pass down; text-overflow and line-clamp do not")
{
    Bed bed(u8".outer { font-family: Serif; font-size: 20px; white-space: pre-wrap; line-height: 1.5; letter-spacing: 2px; "
            u8"text-overflow: ellipsis; line-clamp: 2; } "
            u8"label.fixed { line-height: 24px; white-space: nowrap; } label.cut { text-overflow: ellipsis-middle; line-clamp: 3; }");
    const UINode::TextStyle& text = bed.label->GetTextStyle();
    CHECK(text.WhiteSpace == TextWhiteSpace::PreWrap);
    CHECK(text.LineHeightFactor);
    CHECK(text.LineHeightPixels() == doctest::Approx(30.0f)); // 1.5 of its own 20px
    CHECK(text.LetterSpacing == doctest::Approx(2.0f));
    CHECK(bed.label->GetTextOverflow() == TextOverflow::Clip); // not inherited
    CHECK(bed.label->GetLineClamp() == 0);

    bed.label->AddClass(SV(u8"fixed"));
    bed.label->AddClass(SV(u8"cut"));
    bed.Restyle();
    CHECK(bed.label->GetTextStyle().WhiteSpace == TextWhiteSpace::NoWrap);
    CHECK(bed.label->GetTextStyle().LineHeightPixels() == doctest::Approx(24.0f));
    CHECK(bed.label->GetTextOverflow() == TextOverflow::EllipsisMiddle);
    CHECK(bed.label->GetLineClamp() == 3);

    bed.label->RemoveClass(SV(u8"cut"));
    bed.panel->RemoveClass(SV(u8"outer"));
    bed.Restyle();
    CHECK(bed.label->GetTextOverflow() == TextOverflow::Clip); // the rule went: its own again
    CHECK(bed.label->GetLineClamp() == 0);
    CHECK(bed.label->GetTextStyle().LetterSpacing == doctest::Approx(0.0f));

    // Code's value is code's.
    bed.label->RemoveClass(SV(u8"fixed"));
    bed.label->SetWhiteSpace(TextWhiteSpace::Pre);
    bed.panel->AddClass(SV(u8"outer"));
    bed.Restyle();
    CHECK(bed.label->GetTextStyle().WhiteSpace == TextWhiteSpace::Pre);
}
