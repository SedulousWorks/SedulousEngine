// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the SVG drawable: an SVG picture as image content, from its markup (an icon set compiled
// into the binary, owning its document) or by a path through the resource provider (borrowing
// the provider's); its intrinsic size is the document's, it draws paths at the size it lands, and
// a tint recolours it whole. PictureDrawable picks SVG or raster by the source (an SVG by a .svg
// ending or written inline as a data: URL, which the provider parses once and keeps), and an
// Image's src, a menu command's icon and a rich text's inline icon take either.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.image;
import foundation.vg.svg;
import foundation.vfs;
import foundation.fonts;
import foundation.fonts.truetype;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace vg = foundation::vg;
namespace image = foundation::image;
namespace fonts = foundation::fonts;

namespace
{
    // A red 24 by 12 rectangle.
    constexpr const char8_t* kBar = u8R"(<svg width="24" height="12"><rect width="24" height="12" fill="#ff0000"/></svg>)";

    // An SVG and a raster, each counted when asked for.
    class Pictures : public IResourceProvider
    {
    public:
        Pictures() : IResourceProvider(core::DefaultAllocator()) {}
        static inline core::u8 kPixels[40 * 20 * 4]{};
        image::OwnedImageData img{40, 20, image::PixelFormat::RGBA8, core::Span<const core::u8>(kPixels, sizeof(kPixels))};
        foundation::vg::svg::SVGDocument svg = foundation::vg::svg::SVGLoader::Load(core::StringView(kBar)).Value();
        int images = 0, svgs = 0;
        const image::ImageData* LoadImage(core::StringView path) override
        {
            ++images;
            return path == core::StringView(u8"missing.png") ? nullptr : &img;
        }
        bool LoadText(core::StringView, core::String&) override { return false; }
        const foundation::vg::svg::SVGDocument* LoadSvg(core::StringView path) override
        {
            ++svgs;
            return path == core::StringView(u8"missing.svg") ? nullptr : &svg;
        }
    };

    bool AllRed(vg::VGContext& ctx)
    {
        for (const vg::VGVertex& v : ctx.GetBatch().vertices)
            if (v.color.r < 0.99f || v.color.g > 0.01f)
                return false;
        return true;
    }
}

TEST_CASE("svg-drawable: an Image shows an SVG by its src or from markup, sized as the document")
{
    Pictures pictures;
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    root->GetContext().SetResourceProvider(&pictures);
    auto bySource = core::MakeRef<Image>(core::DefaultAllocator());
    bySource->SetSource(core::String(u8"bar.svg"));
    auto fromText = core::MakeRef<Image>(core::DefaultAllocator());
    fromText->SetDrawable(SvgDrawable::FromText(core::DefaultAllocator(), core::StringView(kBar)));
    root->AddChild(bySource.Get());
    root->AddChild(fromText.Get());
    (void)root->UpdateLayout();
    CHECK(pictures.svgs == 1);
    CHECK(pictures.images == 0);
    CHECK(bySource->GetSize().x == doctest::Approx(24.0f));
    CHECK(bySource->GetSize().y == doctest::Approx(12.0f));
    CHECK(fromText->GetSize().x == doctest::Approx(24.0f));
    CHECK(fromText->GetSize().y == doctest::Approx(12.0f));
}

TEST_CASE("svg-drawable: a rich text's inline icon by an .svg path is drawn as its paths")
{
    fonts::TrueTypeFonts::Initialize();
    fonts::TrueTypeFontService service{core::DefaultAllocator()};
    const core::String data = foundation::vfs::FindDataRoot();
    REQUIRE(service.LoadFont(u8"Roboto", foundation::vfs::DataPath(data.AsView(), u8"Assets/fonts/roboto/Roboto-Regular.ttf").AsView())
            == fonts::FontLoadResult::Success);
    Pictures pictures;
    Text text;
    text.SetFontService(&service);
    text.SetFont(service.GetFont(u8"Roboto", 16.0f));
    text.SetResourceProvider(&pictures);
    text.SetMarkup(core::StringView(u8"[icon=bar.svg]"));
    vg::VGContext ctx;
    DrawContext dc{ctx};
    text.Draw(dc, core::Float2{0.0f, 0.0f});
    CHECK(pictures.svgs == 1);
    CHECK(pictures.images == 0);
    REQUIRE(ctx.GetBatch().vertices.Size() > 0);
    CHECK(AllRed(ctx)); // the icon alone, as authored
}

TEST_CASE("svg-drawable: a menu command's icon by an .svg path")
{
    Pictures pictures;
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->GetContext().SetResourceProvider(&pictures);
    auto item = core::MakeRef<MenuItem>(core::DefaultAllocator());
    root->AddChild(item.Get());
    item->OnBoundCommandText(core::StringView(u8"Bar"), core::StringView(u8"bar.svg"), core::StringView());
    CHECK(pictures.svgs == 1);
    REQUIRE(item->GetIcon() != nullptr);
    CHECK(core::Cast<SvgDrawable>(item->GetIcon()) != nullptr);
}

namespace
{
    constexpr const char8_t* kBarBase64 =
        u8"PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMTIiPjxyZWN0IHdpZHRoPSIyNCIgaGVpZ2h0PSIxMiIgZmlsbD0iI2ZmMDAwMCIvPjwvc3ZnPg==";
    constexpr const char8_t* kBarPercent =
        u8"data:image/svg+xml,%3Csvg%20width%3D%2224%22%20height%3D%2212%22%3E%3Crect%20width%3D%2224%22%20height%3D%2212%22"
        u8"%20fill%3D%22%23ff0000%22%2F%3E%3C%2Fsvg%3E";
}

TEST_CASE("svg-drawable: an inline SVG as a sheet's background, an Image's src and a rich text's icon")
{
    Pictures pictures;
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    root->GetContext().SetResourceProvider(&pictures);
    core::RefPtr<Panel> panel = core::MakeRef<Panel>(core::DefaultAllocator());
    panel->AddClass(core::StringView(u8"card"));
    root->AddChild(panel.Get());
    StyleManager styles;
    styles.SetResourceProvider(&pictures);
    styles.SetStyleSheet(CSSParser::Parse(core::StringView(
        u8".card { background-image: url(\"data:image/svg+xml,<svg width='24' height='12'><rect width='24' height='12'"
        u8" fill='%23ff0000'/></svg>\"); }")));
    styles.ApplyTree(*root.Get());
    REQUIRE(panel->GetBox().Layers.Size() == 1u);
    REQUIRE(panel->GetBox().Layers[0].Svg != nullptr);
    CHECK(panel->GetBox().Layers[0].Svg->width == doctest::Approx(24.0f));

    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::String markup(u8"<Image src=\"");
    markup.Append(core::StringView(kBarPercent));
    markup.Append(core::StringView(u8"\"/>"));
    core::RefPtr<Node> image = loader.LoadFromString(markup.AsView());
    REQUIRE(image.Get() != nullptr);
    root->AddChild(image.Get());
    (void)root->UpdateLayout();
    CHECK(image->GetSize().x == doctest::Approx(24.0f));
    CHECK(image->GetSize().y == doctest::Approx(12.0f));
    CHECK(pictures.svgs == 0); // neither asked the provider for a file

    fonts::TrueTypeFonts::Initialize();
    fonts::TrueTypeFontService service{core::DefaultAllocator()};
    const core::String data = foundation::vfs::FindDataRoot();
    REQUIRE(service.LoadFont(u8"Roboto", foundation::vfs::DataPath(data.AsView(), u8"Assets/fonts/roboto/Roboto-Regular.ttf").AsView())
            == fonts::FontLoadResult::Success);
    Text text;
    text.SetFontService(&service);
    text.SetFont(service.GetFont(u8"Roboto", 16.0f));
    text.SetResourceProvider(&pictures);
    core::String rich(u8"[icon=");
    rich.Append(core::StringView(kBarPercent));
    rich.Append(core::StringView(u8"]"));
    text.SetMarkup(rich.AsView());
    vg::VGContext ctx;
    DrawContext dc{ctx};
    text.Draw(dc, core::Float2{0.0f, 0.0f});
    REQUIRE(ctx.GetBatch().vertices.Size() > 0);
    CHECK(AllRed(ctx));
    CHECK(pictures.svgs == 0);
}
