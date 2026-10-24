// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Hosting - GuiPassRenderer on the Null RHI backend (E4 of Specs/gui-lab-evolution-3.md): a root
// drawn into a pass its caller opened, at a region of the target; a renderer per kind of pass,
// rewound once a frame so a frame's roots keep their slices; the bakes recorded once a frame and
// learned by renderers made later, as the images registered by key are.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.rhi;
import foundation.rhi.null;
import foundation.image;
import foundation.vg.svg;
import foundation.vg.renderer;
import foundation.gui;
import foundation.gui.hosting;

using namespace foundation::core;
using namespace foundation::gui;
namespace rhi = foundation::rhi;
namespace image = foundation::image;

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

    // A Null device, the two VG shaders, a pass renderer on them, a colour target the caller's pass
    // draws into, and a root showing a red box.
    struct Bed
    {
        rhi::null::NullDevice device{DefaultAllocator()};
        rhi::ShaderModule* vs = MakeModule(device);
        rhi::ShaderModule* fs = MakeModule(device);
        UniquePtr<GuiPassRenderer> renderer;
        rhi::CommandPool* pool = nullptr;
        rhi::Texture* target = nullptr;
        rhi::TextureView* view = nullptr;
        RefPtr<GUIContext> context = MakeRef<GUIContext>(DefaultAllocator());

        Bed()
        {
            VgShaderSet shaders;
            shaders.Vertex = vs;
            shaders.Fragment = fs;
            renderer = MakeUnique<GuiPassRenderer>(DefaultAllocator(), DefaultAllocator(), device, 2u, nullptr, shaders);
            REQUIRE(device.CreateCommandPool(rhi::QueueType::Graphics, pool).IsOk());
            REQUIRE(device.CreateTexture(rhi::TextureDesc::RenderTarget(rhi::TextureFormat::BGRA8Unorm, 640, 360), target).IsOk());
            REQUIRE(device.CreateTextureView(target, rhi::TextureViewDesc{}, view).IsOk());
        }
        ~Bed()
        {
            renderer.Reset();
            device.DestroyTextureView(view);
            device.DestroyTexture(target);
            device.DestroyCommandPool(pool);
            device.DestroyShaderModule(fs);
            device.DestroyShaderModule(vs);
        }
        RefPtr<SceneRoot> MakeRoot()
        {
            RefPtr<SceneRoot> root = MakeRef<SceneRoot>(DefaultAllocator(), context);
            root->SetViewportSize(Float2{320.0f, 180.0f});
            RefPtr<Panel> box = MakeRef<Panel>(DefaultAllocator());
            box->SetSize(Float2{40.0f, 20.0f});
            NodeBox look;
            look.BackgroundColor = Color{1.0f, 0.0f, 0.0f, 1.0f};
            box->SetBox(Move(look));
            root->AddChild(box.Get());
            return root;
        }
        // The caller's pass on its target, as an engine's overlay pass is: already open, loading
        // what the frame drew before.
        template <typename DrawFn>
        void InPass(rhi::CommandEncoder& encoder, DrawFn&& draw)
        {
            rhi::RenderPassDesc pass{};
            rhi::ColorAttachment color{};
            color.view = view;
            color.loadOp = rhi::LoadOp::Load;
            color.storeOp = rhi::StoreOp::Store;
            pass.colorAttachments.Add(color);
            rhi::RenderPassEncoder* passEncoder = encoder.BeginRenderPass(pass);
            REQUIRE(passEncoder != nullptr);
            draw(*passEncoder);
            passEncoder->End();
        }
        rhi::CommandEncoder* Encoder()
        {
            rhi::CommandEncoder* encoder = nullptr;
            REQUIRE(pool->CreateEncoder(encoder).IsOk());
            return encoder;
        }
        void Done(rhi::CommandEncoder* encoder)
        {
            (void)encoder->Finish();
            pool->DestroyEncoder(encoder);
        }
    };

    GuiPassView ViewOf(u32 frame, rhi::TextureFormat format = rhi::TextureFormat::BGRA8Unorm, bool encoded = false)
    {
        GuiPassView view;
        view.X = 320; // the right half of the target, a split screen's second view
        view.Y = 0;
        view.Width = 320;
        view.Height = 180;
        view.Format = format;
        view.Encoded = encoded;
        view.FrameIndex = frame;
        return view;
    }
}

TEST_CASE("gui.hosting.pass: a root is drawn into a pass its caller opened, at the view's region")
{
    Bed bed;
    REQUIRE(bed.renderer->IsUsable());
    RefPtr<SceneRoot> root = bed.MakeRoot();
    bed.renderer->BeginFrame();
    rhi::CommandEncoder* encoder = bed.Encoder();
    const GuiPassRenderer::Prepared prepared = bed.renderer->Prepare(*root, ViewOf(0), encoder);
    REQUIRE(prepared.Renderer != nullptr);
    CHECK(prepared.Slice.isValid);
    CHECK(prepared.Slice.drawCommandCount > 0);
    CHECK(prepared.View.X == 320);
    bed.InPass(*encoder, [&](rhi::RenderPassEncoder& pass) { bed.renderer->Draw(pass, prepared); });
    bed.Done(encoder);
    CHECK(bed.renderer->RendererCount() == 1u);

    // Nothing to draw into: an empty region.
    GuiPassView empty = ViewOf(0);
    empty.Width = 0;
    CHECK(bed.renderer->Prepare(*root, empty).Renderer == nullptr);
}

TEST_CASE("gui.hosting.pass: a renderer per kind of pass, rewound once a frame, so a frame's roots keep their slices")
{
    Bed bed;
    RefPtr<SceneRoot> first = bed.MakeRoot();
    RefPtr<SceneRoot> second = bed.MakeRoot();
    bed.renderer->BeginFrame();
    rhi::CommandEncoder* encoder = bed.Encoder();
    const GuiPassRenderer::Prepared a = bed.renderer->Prepare(*first, ViewOf(0));
    const GuiPassRenderer::Prepared b = bed.renderer->Prepare(*second, ViewOf(0));
    REQUIRE(a.Renderer != nullptr);
    CHECK(a.Renderer == b.Renderer); // the same kind of pass: one renderer
    CHECK(b.Slice.drawCommandStart >= a.Slice.drawCommandStart + a.Slice.drawCommandCount); // the first's draws kept
    CHECK(b.Slice.uniformByteOffset > a.Slice.uniformByteOffset);
    bed.InPass(*encoder,
               [&](rhi::RenderPassEncoder& pass)
               {
                   bed.renderer->Draw(pass, a);
                   bed.renderer->Draw(pass, b);
               });
    bed.Done(encoder);

    // Another kind of pass (the screen's, encoded, on an sRGB target's UNORM view): another renderer.
    const GuiPassRenderer::Prepared c = bed.renderer->Prepare(*first, ViewOf(0, rhi::TextureFormat::BGRA8Unorm, true));
    CHECK(c.Renderer != nullptr);
    CHECK(c.Renderer != a.Renderer);
    CHECK(bed.renderer->RendererCount() == 2u);

    // The next frame rewinds each renderer once: the first root's draws start over.
    bed.renderer->BeginFrame();
    const GuiPassRenderer::Prepared again = bed.renderer->Prepare(*first, ViewOf(1));
    CHECK(again.Renderer == a.Renderer);
    CHECK(again.Slice.drawCommandStart == 0);
}

TEST_CASE("gui.hosting.pass: the bakes record once a frame, and a renderer made later learns them and the registered images")
{
    Bed bed;
    GpuPictureBaker* baker = bed.renderer->Baker();
    REQUIRE(baker != nullptr);
    RefPtr<SceneRoot> root = bed.MakeRoot();

    // The first kind of pass, then a picture asked for and baked on the frame's encoder.
    bed.renderer->BeginFrame();
    (void)bed.renderer->Prepare(*root, ViewOf(0));
    const foundation::vg::svg::SVGDocument document =
        foundation::vg::svg::SVGLoader::Load(StringView(u8"<svg width='8' height='8'><rect width='8' height='8'/></svg>")).Value();
    CHECK(baker->Baked(document, 16, 16) == nullptr); // queued
    rhi::CommandEncoder* encoder = bed.Encoder();
    CHECK(bed.renderer->RecordBakes(*encoder, 0));
    CHECK_FALSE(bed.renderer->RecordBakes(*encoder, 0)); // once a frame
    bed.Done(encoder);
    const image::ImageData* key = baker->Baked(document, 16, 16);
    REQUIRE(key != nullptr);
    CHECK(bed.renderer->FindRenderer(ViewOf(0))->IsExternalTextureRegistered(key));

    // An image the caller's provider answers by key, sampled from a texture of its own.
    image::ImageDataRef picture{4, 4};
    bed.renderer->RegisterTexture(&picture, bed.view);
    CHECK(bed.renderer->FindRenderer(ViewOf(0))->IsExternalTextureRegistered(&picture));

    // A renderer made after both learns both.
    const GuiPassView encoded = ViewOf(0, rhi::TextureFormat::RGBA8Unorm, true);
    (void)bed.renderer->Prepare(*root, encoded);
    foundation::vg::renderer::VGRenderer* later = bed.renderer->FindRenderer(encoded);
    REQUIRE(later != nullptr);
    CHECK(later->IsExternalTextureRegistered(key));
    CHECK(later->IsExternalTextureRegistered(&picture));

    // Let go: every renderer forgets the image.
    bed.renderer->UnregisterTexture(&picture);
    CHECK_FALSE(later->IsExternalTextureRegistered(&picture));
    CHECK_FALSE(bed.renderer->FindRenderer(ViewOf(0))->IsExternalTextureRegistered(&picture));

    // The next frame records again.
    bed.renderer->BeginFrame();
    encoder = bed.Encoder();
    (void)bed.renderer->RecordBakes(*encoder, 1);
    CHECK_FALSE(bed.renderer->RecordBakes(*encoder, 1));
    bed.Done(encoder);
}

TEST_CASE("gui.hosting.pass: without the shaders every draw needs, nothing is drawn and nothing bakes")
{
    rhi::null::NullDevice device{DefaultAllocator()};
    GuiPassRenderer renderer{DefaultAllocator(), device, 2u, nullptr, VgShaderSet{}};
    CHECK_FALSE(renderer.IsUsable());
    CHECK(renderer.Baker() == nullptr);
    RefPtr<GUIContext> context = MakeRef<GUIContext>(DefaultAllocator());
    RefPtr<SceneRoot> root = MakeRef<SceneRoot>(DefaultAllocator(), context);
    renderer.BeginFrame();
    CHECK(renderer.Prepare(*root, ViewOf(0)).Renderer == nullptr);
    CHECK(renderer.RendererCount() == 0u);
}
