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

TEST_CASE("image: stretch fills the content box")
{
    image::OwnedImageData img = MakeImage();
    auto drawable = Make<ImageDrawable>();
    drawable->Image = &img;

    auto w = Make<Image>();
    w->SetSize(core::Float2{100.0f, 100.0f});
    w->SetDrawable(drawable);
    w->SetFit(ObjectFit::Fill);

    const Rect r = w->DrawnBounds();
    CHECK(r.x == doctest::Approx(0.0f));
    CHECK(r.y == doctest::Approx(0.0f));
    CHECK(r.width == doctest::Approx(100.0f));
    CHECK(r.height == doctest::Approx(100.0f));
}

TEST_CASE("image: contain preserves aspect inside the box, centered")
{
    image::OwnedImageData img = MakeImage(); // 4x2 -> aspect 2:1
    auto drawable = Make<ImageDrawable>();
    drawable->Image = &img;

    auto w = Make<Image>();
    w->SetSize(core::Float2{100.0f, 100.0f});
    w->SetDrawable(drawable);
    w->SetFit(ObjectFit::Contain); // scale = min(100/4, 100/2) = 25 -> 100x50

    const Rect r = w->DrawnBounds();
    CHECK(r.width == doctest::Approx(100.0f));
    CHECK(r.height == doctest::Approx(50.0f));
    CHECK(r.x == doctest::Approx(0.0f));
    CHECK(r.y == doctest::Approx(25.0f)); // centered vertically
}

TEST_CASE("image: cover covers the box, centered (overflow negative)")
{
    image::OwnedImageData img = MakeImage(); // 4x2
    auto drawable = Make<ImageDrawable>();
    drawable->Image = &img;

    auto w = Make<Image>();
    w->SetSize(core::Float2{100.0f, 100.0f});
    w->SetDrawable(drawable);
    w->SetFit(ObjectFit::Cover); // scale = max(25, 50) = 50 -> 200x100

    const Rect r = w->DrawnBounds();
    CHECK(r.width == doctest::Approx(200.0f));
    CHECK(r.height == doctest::Approx(100.0f));
    CHECK(r.x == doctest::Approx(-50.0f)); // centered -> overflows horizontally
    CHECK(r.y == doctest::Approx(0.0f));
}

TEST_CASE("image: none uses its natural size, centred, or where object-position puts it")
{
    image::OwnedImageData img = MakeImage(); // 4x2
    auto drawable = Make<ImageDrawable>();
    drawable->Image = &img;

    auto w = Make<Image>();
    w->SetSize(core::Float2{100.0f, 100.0f});
    w->SetDrawable(drawable);

    w->SetFit(ObjectFit::None); // natural, centred
    Rect r = w->DrawnBounds();
    CHECK(r.width == doctest::Approx(4.0f));
    CHECK(r.height == doctest::Approx(2.0f));
    CHECK(r.x == doctest::Approx(48.0f)); // (100-4)/2
    CHECK(r.y == doctest::Approx(49.0f)); // (100-2)/2

    w->SetObjectPositionName(core::String(u8"left top"));
    r = w->DrawnBounds();
    CHECK(r.x == doctest::Approx(0.0f));
    CHECK(r.y == doctest::Approx(0.0f));
    CHECK(r.width == doctest::Approx(4.0f));
    CHECK(r.height == doctest::Approx(2.0f));
}

TEST_CASE("image: no drawable falls back to the content box and draws nothing")
{
    auto w = Make<Image>();
    w->SetSize(core::Float2{60.0f, 40.0f});
    w->SetFit(ObjectFit::Contain);

    const Rect r = w->DrawnBounds(); // no intrinsic -> the box
    CHECK(r.width == doctest::Approx(60.0f));
    CHECK(r.height == doctest::Approx(40.0f));
    CHECK_FALSE(w->IntrinsicSize().HasValue());

    vg::VGContext ctx;
    DrawContext dc{ctx};
    w->Draw(dc);
    CHECK(ctx.GetBatch().vertices.Size() == 0); // nothing drawn
}

TEST_CASE("image: object-position places it by keyword, percentage or pixels; scale-down never enlarges")
{
    image::OwnedImageData img = MakeImage(); // 4x2
    auto drawable = Make<ImageDrawable>();
    drawable->Image = &img;
    auto w = Make<Image>();
    w->SetSize(core::Float2{100.0f, 100.0f});
    w->SetDrawable(drawable);
    w->SetFit(ObjectFit::Contain); // 100x50

    w->SetObjectPositionName(core::String(u8"bottom"));
    CHECK(w->DrawnBounds().y == doctest::Approx(50.0f));
    CHECK(w->DrawnBounds().x == doctest::Approx(0.0f));
    w->SetObjectPositionName(core::String(u8"0% 25%"));
    CHECK(w->DrawnBounds().y == doctest::Approx(12.5f));
    w->SetObjectPositionName(core::String(u8"10px 4px"));
    CHECK(w->DrawnBounds().x == doctest::Approx(10.0f));
    CHECK(w->DrawnBounds().y == doctest::Approx(4.0f));

    w->SetObjectPositionName(core::String(u8"center"));
    w->SetFitName(core::String(u8"scale-down")); // 4x2 fits: its own size
    CHECK(w->GetFit() == ObjectFit::ScaleDown);
    CHECK(w->DrawnBounds().width == doctest::Approx(4.0f));
    w->SetSize(core::Float2{2.0f, 2.0f}); // too small: contained
    CHECK(w->DrawnBounds().width == doctest::Approx(2.0f));
    CHECK(w->DrawnBounds().height == doctest::Approx(1.0f));
}

TEST_CASE("image: sized by one axis, it keeps its picture's aspect ratio on the other")
{
    image::OwnedImageData img = MakeImage(); // 2:1
    auto drawable = Make<ImageDrawable>();
    drawable->Image = &img;
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    auto wide = Make<Image>();
    wide->SetDrawable(drawable);
    wide->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(120.0f); });
    root->AddChild(wide.Get());
    auto tall = Make<Image>();
    tall->SetDrawable(drawable);
    tall->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(30.0f); });
    root->AddChild(tall.Get());
    auto natural = Make<Image>();
    natural->SetDrawable(drawable);
    root->AddChild(natural.Get());
    (void)root->UpdateLayout();
    CHECK(wide->GetSize().y == doctest::Approx(60.0f));
    CHECK(tall->GetSize().x == doctest::Approx(60.0f));
    CHECK(natural->GetSize().x == doctest::Approx(4.0f));
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

TEST_CASE("image: image-color draws it tinted; white draws it as it is")
{
    auto probe = Make<Probe>();
    auto w = Make<Image>();
    w->SetSize(core::Float2{20.0f, 20.0f});
    w->SetDrawable(probe);
    vg::VGContext ctx;
    DrawContext dc{ctx};
    w->Draw(dc);
    CHECK(probe->plain == 1);
    CHECK(probe->tinted == 0);
    w->SetImageColor(core::Color::Red);
    w->Draw(dc);
    CHECK(probe->tinted == 1);
    CHECK(probe->tint == core::Color::Red);
}
