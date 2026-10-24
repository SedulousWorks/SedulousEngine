// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Hosting - the GPU picture baker on the Null RHI backend: a picture asked for is queued, baked
// when the frame records, and registered with every target renderer under its key; asked again it
// is that key; a size of its own is a bake of its own; one no draw asks for goes in time; a target
// added late learns the bakes, and one taken out forgets them.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.rhi;
import foundation.rhi.null;
import foundation.image;
import foundation.vg;
import foundation.vg.svg;
import foundation.vg.renderer;
import foundation.gui;
import foundation.gui.hosting;

using namespace foundation::core;
using namespace foundation::gui;
namespace rhi = foundation::rhi;
namespace vg = foundation::vg;

namespace
{
    rhi::ShaderModule* MakeModule(rhi::Device& d)
    {
        const u8 dummy[4] = {0, 0, 0, 0};
        rhi::ShaderModuleDesc desc{};
        desc.code = Span<const u8>(dummy, 4);
        desc.entryPoint = u8"main";
        rhi::ShaderModule* m = nullptr;
        (void)d.CreateShaderModule(desc, m);
        return m;
    }

    // A Null device, the GUI's renderer, a baker on it, and an encoder a frame records on.
    struct Bed
    {
        rhi::null::NullDevice device{DefaultAllocator()};
        rhi::ShaderModule* vs = MakeModule(device);
        rhi::ShaderModule* fs = MakeModule(device);
        vg::renderer::VGRenderer target{DefaultAllocator()};
        GpuPictureBaker baker{DefaultAllocator(), device, nullptr};
        rhi::CommandPool* pool = nullptr;
        vg::svg::SVGDocument document = vg::svg::SVGLoader::Load(
            StringView(u8"<svg width='24' height='12'><rect width='24' height='12' fill='red'/></svg>")).Value();

        Bed()
        {
            REQUIRE(target.Initialize(device, *vs, *fs, rhi::TextureFormat::BGRA8UnormSrgb, 2).IsOk());
            PictureBakerSetup setup;
            setup.VertexShader = vs;
            setup.FragmentShader = fs;
            setup.Format = rhi::TextureFormat::BGRA8UnormSrgb;
            REQUIRE(baker.Initialize(setup).IsOk());
            baker.AddTarget(target);
            REQUIRE(device.CreateCommandPool(rhi::QueueType::Graphics, pool).IsOk());
        }
        ~Bed()
        {
            baker.Dispose();
            target.Dispose();
            device.DestroyCommandPool(pool);
            device.DestroyShaderModule(fs);
            device.DestroyShaderModule(vs);
        }
        // One frame: the baker records on an encoder of its own.
        bool Frame(i32 frameIndex)
        {
            rhi::CommandEncoder* encoder = nullptr;
            REQUIRE(pool->CreateEncoder(encoder).IsOk());
            const bool baked = baker.Record(*encoder, frameIndex);
            (void)encoder->Finish();
            pool->DestroyEncoder(encoder);
            return baked;
        }
    };
}

TEST_CASE("gui.hosting.baker: a picture asked for is baked when the frame records, then drawn from its key")
{
    Bed bed;
    CHECK(bed.baker.Baked(bed.document, 48, 24) == nullptr); // queued
    CHECK(bed.baker.BakeCount() == 1u);
    CHECK(bed.baker.Generation() == 0u);
    CHECK(bed.Frame(0));
    CHECK(bed.baker.Generation() == 1u); // the GUI redraws
    const foundation::image::ImageData* key = bed.baker.Baked(bed.document, 48, 24);
    REQUIRE(key != nullptr);
    CHECK(key->Width() == 48u);
    CHECK(key->Height() == 24u);
    CHECK(bed.target.IsExternalTextureRegistered(key));
    CHECK_FALSE(bed.Frame(1)); // nothing new
    CHECK(bed.baker.Generation() == 1u);

    // Another size is a bake of its own.
    CHECK(bed.baker.Baked(bed.document, 24, 12) == nullptr);
    CHECK(bed.Frame(0));
    CHECK(bed.baker.Baked(bed.document, 24, 12) != nullptr);
    CHECK(bed.baker.Baked(bed.document, 24, 12) != key);
    CHECK(bed.baker.BakeCount() == 2u);
}

TEST_CASE("gui.hosting.baker: a bake no draw asks for goes, and the GUI's renderer forgets it")
{
    Bed bed;
    (void)bed.baker.Baked(bed.document, 48, 24);
    (void)bed.Frame(0);
    const foundation::image::ImageData* key = bed.baker.Baked(bed.document, 48, 24);
    REQUIRE(key != nullptr);
    for (u64 frame = 0; frame < GpuPictureBaker::kKeepFrames; ++frame)
    {
        if (frame % 100 == 0)
            CHECK(bed.baker.Baked(bed.document, 48, 24) == key); // still asked for: kept
        (void)bed.Frame(static_cast<i32>(frame % 2));
    }
    CHECK(bed.baker.BakeCount() == 1u);
    for (u64 frame = 0; frame <= GpuPictureBaker::kKeepFrames; ++frame)
        (void)bed.Frame(static_cast<i32>(frame % 2));
    CHECK(bed.baker.BakeCount() == 0u);
    CHECK_FALSE(bed.target.IsExternalTextureRegistered(key));
}

TEST_CASE("gui.hosting.baker: a renderer added late learns the bakes; one taken out forgets them")
{
    Bed bed;
    vg::renderer::VGRenderer second{DefaultAllocator()};
    REQUIRE(second.Initialize(bed.device, *bed.vs, *bed.fs, rhi::TextureFormat::BGRA8UnormSrgb, 2).IsOk());
    (void)bed.baker.Baked(bed.document, 48, 24);
    (void)bed.Frame(0);
    const foundation::image::ImageData* key = bed.baker.Baked(bed.document, 48, 24);
    REQUIRE(key != nullptr);
    CHECK_FALSE(second.IsExternalTextureRegistered(key));
    bed.baker.AddTarget(second); // a window opened after the bake
    CHECK(second.IsExternalTextureRegistered(key));
    (void)bed.baker.Baked(bed.document, 24, 12);
    (void)bed.Frame(1);
    CHECK(second.IsExternalTextureRegistered(bed.baker.Baked(bed.document, 24, 12)));
    bed.baker.RemoveTarget(second); // its window goes
    CHECK_FALSE(second.IsExternalTextureRegistered(key));
    CHECK(bed.target.IsExternalTextureRegistered(key));
    second.Dispose();
}
