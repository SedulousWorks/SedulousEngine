// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - theme + resource-backed CSS props: text color, font-family/size and
// background-image resolve through the StyleManager (with an IResourceProvider), and the
// built-in default theme restyles the standard widgets.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.image;
import foundation.vg.svg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace image = foundation::image;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    // 6px advance / byte mock font (as in the Text tests).
    class MockFont : public fonts::IFont
    {
    public:
        core::StringView FamilyName() const override { return core::StringView(u8"mock"); }
        core::Span<const core::u8> SourceData() const override { return {}; }
        fonts::FontMetrics Metrics() const override
        {
            fonts::FontMetrics m;
            m.ascent = 10.0f;
            m.descent = -2.0f;
            m.lineGap = 0.0f;
            m.lineHeight = 12.0f;
            m.pixelHeight = 10.0f;
            m.scale = 1.0f;
            return m;
        }
        core::f32 PixelHeight() const override { return 10.0f; }
        fonts::GlyphInfo GetGlyphInfo(core::i32 cp) const override
        {
            fonts::GlyphInfo g;
            g.codepoint = cp;
            g.advanceWidth = 6.0f;
            return g;
        }
        core::f32 GetKerning(core::i32, core::i32) const override { return 0.0f; }
        bool HasGlyph(core::i32) const override { return true; }
        core::f32 MeasureString(core::StringView t) const override
        {
            return static_cast<core::f32>(t.Size()) * 6.0f;
        }
        core::f32 MeasureString(core::StringView t,
                                core::Array<fonts::GlyphPosition>& o) const override
        {
            (void)o;
            return static_cast<core::f32>(t.Size()) * 6.0f;
        }
    };

    // A resource provider that hands out one image, recording the requested path.
    class MockResources : public IResourceProvider
    {
    public:
        MockResources() : IResourceProvider(core::DefaultAllocator()) {}
        image::OwnedImageData img{2, 2, image::PixelFormat::RGBA8,
                                  core::Span<const core::u8>(kPixels, 16)};
        core::String lastPath;
        const image::ImageData* LoadImage(core::StringView path) override
        {
            lastPath = core::String(path);
            return &img;
        }

    private:
        static constexpr core::u8 kPixels[16] = {255, 0, 0,   255, 0,   255, 0,   255,
                                                 0,   0, 255, 255, 255, 255, 255, 255};
        bool LoadText(core::StringView, core::String&) override { return false; }
        const foundation::vg::svg::SVGDocument* LoadSvg(core::StringView) override { return nullptr; }
    };

    // A font service that hands out one font, recording the requested family + size.
    class MockFontService : public fonts::IFontService
    {
    public:
        fonts::CachedFont font{core::DefaultAllocator(), core::DefaultAllocator().New<MockFont>(),
                               nullptr, nullptr};
        core::String lastFamily;
        core::f32 lastSize = 0.0f;

        fonts::CachedFont* GetFont(core::f32) override { return &font; }
        fonts::CachedFont* GetFont(core::StringView family, core::f32 size) override
        {
            lastFamily = core::String(family);
            lastSize = size;
            return &font;
        }
        image::ImageData* GetAtlasTexture(fonts::CachedFont*) override { return nullptr; }
        image::ImageData* GetAtlasTexture(core::StringView, core::f32) override { return nullptr; }
        void ReleaseFont(fonts::CachedFont*) override {}
        core::StringView DefaultFontFamily() const override { return core::StringView(u8"mock"); }
        bool HasFamily(core::StringView) const override { return false; }
    };

    core::RefPtr<Label> ApplyCSS(const char8_t* css, IResourceProvider* res = nullptr)
    {
        auto label = core::MakeRef<Label>(core::DefaultAllocator());
        StyleManager mgr;
        mgr.SetStyleSheet(CSSParser::Parse(core::StringView(css)));
        if (res)
            mgr.SetResourceProvider(res);
        mgr.ApplyTo(*label.Get());
        return label;
    }
}

TEST_CASE("theme: the built-in default theme restyles the standard widgets")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto button = Make<Button>();
    auto textfield = Make<TextField>();
    root->AddChild(button.Get());
    root->AddChild(textfield.Get());

    StyleManager mgr;
    mgr.SetStyleSheet(CSSParser::Parse(DefaultThemeCSS()));
    mgr.ApplyTree(*root.Get());

    // The theme gives the button a background + padding and the textfield padding.
    CHECK(button->GetBox().BackgroundColor.a > 0.0f);
    CHECK(button->GetPadding().Left == doctest::Approx(9.0f));
    CHECK(textfield->GetBox().BackgroundColor.a > 0.0f);
    CHECK(textfield->GetPadding().Left == doctest::Approx(6.0f));

    // Its tokens: the dark accent, then (the user's scheme light) the light one, from the same sheet.
    CHECK(button->GetBox().BackgroundColor.r == doctest::Approx(0x33 / 255.0f).epsilon(0.01));
    MediaContext light;
    light.DarkScheme = false;
    mgr.SetMediaContext(light);
    mgr.ApplyTree(*root.Get());
    CHECK(button->GetBox().BackgroundColor.r == doctest::Approx(0xcd / 255.0f).epsilon(0.01));
}

TEST_CASE("theme: a skin's radius token rounds its control, so the focus ring follows the art")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto button = Make<Button>();
    auto field = Make<TextField>();
    auto combo = Make<ComboBox>();
    root->AddChild(button.Get());
    root->AddChild(field.Get());
    root->AddChild(combo.Get());
    StyleManager mgr;
    mgr.SetUserAgentSheet(CSSParser::Parse(DefaultThemeCSS()));
    mgr.ApplyTree(*root.Get());
    CHECK(button->GetBox().Radii.IsZero()); // square by default
    CHECK(field->GetBox().Radii.IsZero());

    mgr.SetStyleSheet(CSSParser::Parse(core::StringView(u8":root { --button-radius: 6px; --field-radius: 4px; }")));
    mgr.ApplyTree(*root.Get());
    CHECK(button->GetBox().Radii.topLeft == doctest::Approx(6.0f));
    CHECK(field->GetBox().Radii.bottomRight == doctest::Approx(4.0f));
    CHECK(combo->GetBox().Radii.topLeft == doctest::Approx(4.0f)); // a combo box follows the fields
}

namespace
{
    UIWidget* FindTagged(Node& node, core::StringView tag)
    {
        if (UIWidget* widget = core::Cast<UIWidget>(&node); widget != nullptr && widget->GetTag() == tag)
            return widget;
        for (core::usize i = 0; i < node.ChildCount(); ++i)
            if (UIWidget* found = FindTagged(*node.GetChildAt(i), tag))
                return found;
        return nullptr;
    }
}

TEST_CASE("theme: a list's rows show the pointer over them (a combo box's popup is a list box)")
{
    // The model first: the view unregisters from it when the tree lets the view go.
    core::Array<core::String> rows;
    rows.PushBack(core::String(u8"a"));
    rows.PushBack(core::String(u8"b"));
    StringListModel model(core::Move(rows));
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto box = Make<ListBox>();
    box->AddItem(core::StringView(u8"one"));
    box->AddItem(core::StringView(u8"two"));
    auto view = Make<ListView>();
    view->SetSize(core::Float2{200.0f, 100.0f});
    view->SetRowHeight(20.0f);
    root->AddChild(box.Get());
    root->AddChild(view.Get());
    view->SetModel(&model);
    (void)root->UpdateLayout();

    StyleManager mgr;
    mgr.SetStyleSheet(CSSParser::Parse(DefaultThemeCSS()));
    mgr.ApplyTree(*root.Get());
    UIWidget* item = FindTagged(*box.Get(), core::StringView(u8"listboxitem"));
    REQUIRE(item != nullptr);
    UIWidget* row = FindTagged(*view.Get(), core::StringView(u8"listviewrow"));
    REQUIRE(row != nullptr);
    CHECK(item->GetBox().BackgroundColor.a == doctest::Approx(0.0f));
    CHECK(row->GetBox().BackgroundColor.a == doctest::Approx(0.0f));

    item->SetHovered(true);
    row->SetHovered(true);
    mgr.ApplyTree(*root.Get());
    CHECK(item->GetBox().BackgroundColor.a > 0.0f);
    CHECK(row->GetBox().BackgroundColor.a > 0.0f);
    CHECK(item->GetTextColor().a > 0.0f); // still the label's text colour

    // A sheet retints the hover with one token.
    mgr.SetStyleSheet(CSSParser::Parse(core::StringView(u8":root { --list-hover: #ff0000; }")));
    mgr.SetUserAgentSheet(CSSParser::Parse(DefaultThemeCSS()));
    mgr.ApplyTree(*root.Get());
    CHECK(item->GetBox().BackgroundColor.r == doctest::Approx(1.0f));
}
