// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the image drawable, the one kind of drawable (image content: an Image widget's picture, an
// icon); a node's look is its box. Its tint state, its intrinsic size and the geometry it draws
// (GPU-free: a VGContext tessellates into a CPU vertex batch).
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.image;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace vg = foundation::vg;
namespace image = foundation::image;

namespace
{
    // A tiny 2x2 RGBA image (owns its pixels).
    image::OwnedImageData MakeImage()
    {
        static const core::u8 pixels[16] = {
            255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255,
        };
        return image::OwnedImageData(2, 2, image::PixelFormat::RGBA8, core::Span<const core::u8>(pixels, 16));
    }
}

TEST_CASE("image-drawable: its tint, colour and alpha")
{
    ImageDrawable d;
    CHECK(d.GetColor().r == doctest::Approx(1.0f)); // white: drawn as it is
    d.SetColor(core::Color::Blue);
    CHECK(d.GetColor().b == doctest::Approx(1.0f));
    d.SetAlpha(0.5f);
    CHECK(d.GetAlpha() == doctest::Approx(0.5f));
    CHECK(d.GetColor().a == doctest::Approx(0.5f));
}

TEST_CASE("image-drawable: no image has no intrinsic size and draws nothing")
{
    ImageDrawable d;
    CHECK_FALSE(d.IntrinsicSize().HasValue());
    vg::VGContext ctx;
    DrawContext dc{ctx};
    d.Draw(dc, Rect{0.0f, 0.0f, 10.0f, 10.0f});
    CHECK(ctx.GetBatch().vertices.Size() == 0);
}

TEST_CASE("image-drawable: an image's intrinsic size, and the geometry it draws")
{
    image::OwnedImageData img = MakeImage();
    ImageDrawable d{&img};
    REQUIRE(d.IntrinsicSize().HasValue());
    CHECK(d.IntrinsicSize().Value().x == doctest::Approx(2.0f));
    CHECK(d.IntrinsicSize().Value().y == doctest::Approx(2.0f));
    vg::VGContext ctx;
    DrawContext dc{ctx};
    d.Draw(dc, Rect{0.0f, 0.0f, 32.0f, 32.0f});
    CHECK(ctx.GetBatch().vertices.Size() > 0);
}
