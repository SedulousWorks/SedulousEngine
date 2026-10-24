// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Image widget tests: object-fit and object-position place the picture as CSS places a
// replaced element's (fill, contain, cover, none, scale-down), sized by one axis it keeps its
// aspect ratio, `src` loads through the resource provider, and image-color tints it.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.image;
import foundation.vg.svg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace vg = foundation::vg;
namespace image = foundation::image;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    // A 4x2 (aspect 2:1) RGBA image.
    image::OwnedImageData MakeImage()
    {
        static const core::u8 pixels[32] = {
            255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255,
            255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255,
        };
        return image::OwnedImageData(4, 2, image::PixelFormat::RGBA8,
                                     core::Span<const core::u8>(pixels, 32));
    }
}

namespace
{
    struct OneImage : IResourceProvider
    {
        OneImage() : IResourceProvider(core::DefaultAllocator()) {}
        image::OwnedImageData img = MakeImage();
        int loads = 0;
        const image::ImageData* LoadImage(core::StringView path) override
        {
            ++loads;
            return path == core::StringView(u8"pic.png") ? &img : nullptr;
        }
        bool LoadText(core::StringView, core::String&) override { return false; }
        const foundation::vg::svg::SVGDocument* LoadSvg(core::StringView) override { return nullptr; }
    };

    // Counts how it is drawn, and with what tint.
    struct Probe : Drawable
    {
        int plain = 0, tinted = 0;
        core::Color tint{};
        void Draw(DrawContext&, const Rect&) override { ++plain; }
        void DrawTinted(DrawContext&, const Rect&, core::Color t) override
        {
            ++tinted;
            tint = t;
        }
        [[nodiscard]] core::Optional<core::Float2> IntrinsicSize() const override { return core::Float2{10.0f, 10.0f}; }
    };
}

TEST_CASE("image: src loads through the GUI's resources when first needed; markup and sheets set them all")
{
    OneImage resources;
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    root->GetContext().SetResourceProvider(&resources);
    auto w = Make<Image>();
    w->SetSource(core::String(u8"pic.png"));
    CHECK(resources.loads == 0); // not yet in a GUI
    root->AddChild(w.Get());
    (void)root->UpdateLayout();
    CHECK(resources.loads == 1);
    CHECK(w->GetSize().x == doctest::Approx(4.0f));
    (void)root->UpdateLayout();
    CHECK(resources.loads == 1); // once

    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    auto m = loader.LoadFromString(core::StringView(u8R"(<Image src="pic.png" object-fit="cover" object-position="right top" image-color="#ff000080"/>)"));
    REQUIRE(m.Get() != nullptr);
    auto* img = core::Cast<Image>(m.Get());
    REQUIRE(img != nullptr);
    CHECK(img->GetSource() == core::StringView(u8"pic.png"));
    CHECK(img->GetFit() == ObjectFit::Cover);
    CHECK(img->GetObjectPositionName() == core::StringView(u8"100% 0%"));
    CHECK(img->GetImageColor().a == doctest::Approx(128.0f / 255.0f));
}
