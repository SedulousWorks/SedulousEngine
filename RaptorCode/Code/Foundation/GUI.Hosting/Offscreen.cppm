// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Hosting - :offscreen partition: GuiOffscreen, a root drawn into a picture on the host's device.
//
// What a test or a tool draws with, not a window: the image tests' pictures, the bench's frames,
// a sweep's or an audit's. A target of a size and format of its own, a VG renderer and pass targets
// of its own (the bakes registered with it, as with a window's), drawn on an encoder and fence of its
// own and waited for, so a picture asked for is read back in the call. Each draw times its stages:
// the GUI's draw, the renderer's prepare, and the GPU's work with the wait.
//
// The device is idled before a draw: the host's windows may share the baker's frame slots.

module;
#include "Core/Prelude.h"

export module foundation.gui.hosting:offscreen;

import foundation.core;
import foundation.rhi;
import foundation.rhi.capture; // ScreenshotCapture: the read back
import foundation.image;
import foundation.graphics;
import foundation.vg;
import foundation.vg.renderer;
import foundation.gui;
import :vg_shaders;
import :picture_baker;
import :gui_host;

using namespace foundation::core;
namespace core = foundation::core;
namespace rhi = foundation::rhi;
namespace image = foundation::image;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    class GuiOffscreen
    {
    public:
        /// What a draw cost, in milliseconds.
        struct Times
        {
            f64 Draw = 0.0;    ///< the GUI's draw into the canvas
            f64 Prepare = 0.0; ///< the renderer's upload
            f64 Gpu = 0.0;     ///< the GPU's work, waited for
        };

        /// A `width` by `height` target in `format` (one a picture can be read back from: 8-bit
        /// RGBA or BGRA), blending in `space`.
        GuiOffscreen(IAllocator& allocator, GuiHost& host, u32 width, u32 height,
                     rhi::TextureFormat format = rhi::TextureFormat::RGBA8UnormSrgb, vg::VGBlendSpace space = vg::VGBlendSpace::Linear)
            : m_allocator(allocator), m_host(host), m_renderer(allocator), m_width(width), m_height(height), m_format(format), m_space(space)
        {
            rhi::Device* device = host.m_device.Raw();
            if (device == nullptr || !host.m_shaders.IsUsable() || width == 0 || height == 0)
                return;
            rhi::TextureDesc desc = rhi::TextureDesc::RenderTarget(format, width, height);
            desc.usage = desc.usage | rhi::TextureUsage::CopySrc;
            if (!device->CreateTexture(desc, m_texture).IsOk() || !device->CreateTextureView(m_texture, rhi::TextureViewDesc{}, m_view).IsOk() ||
                !device->CreateCommandPool(rhi::QueueType::Graphics, m_pool).IsOk() || !device->CreateFence(0, m_fence).IsOk())
                return;
            m_targets.Configure(*device);
            const bool targets = m_targets.Create(format, width, height);
            vg::renderer::VGTargetConfig config = targets ? m_targets.ConfigFor(space) : vg::renderer::VGTargetConfig{};
            config.blendSpace = space;
            const VgShaderSet& shaders = host.m_shaders;
            if (!m_renderer
                     .Initialize(*device, *shaders.Vertex, *shaders.Fragment, format, 1, shaders.DistanceField, shaders.GradientRadial,
                                 shaders.GradientConic, config, shaders.BoxShadow, shaders.BoxVertex, shaders.BoxFragment, shaders.Layer,
                                 shaders.BlurVertex, shaders.BlurFragment)
                     .IsOk())
                return;
            m_canvas = MakeUnique<vg::VGContext>(allocator, host.m_fonts);
            m_canvas->SetPerPixelGradients(shaders.GradientRadial != nullptr && shaders.GradientConic != nullptr);
            m_canvas->SetAnalyticBoxes(shaders.BoxVertex != nullptr && shaders.BoxFragment != nullptr);
            m_canvas->SetLayers(shaders.Layer != nullptr);
            m_canvas->SetStencilFills(m_renderer.StencilFillsSupported());
            if (host.EnsureBaker(format, space))
                host.m_baker->AddTarget(m_renderer);
            m_ready = true;
        }
        ~GuiOffscreen()
        {
            rhi::Device* device = m_host.m_device.Raw();
            if (device == nullptr)
                return;
            device->WaitIdle();
            m_capture.Release(*device); // its read back buffer
            if (m_host.m_baker)
                m_host.m_baker->RemoveTarget(m_renderer);
            if (m_renderer.IsInitialized())
                m_renderer.Dispose();
            m_targets.Destroy();
            if (m_fence != nullptr)
                device->DestroyFence(m_fence);
            if (m_pool != nullptr)
                device->DestroyCommandPool(m_pool);
            if (m_view != nullptr)
                device->DestroyTextureView(m_view);
            if (m_texture != nullptr)
                device->DestroyTexture(m_texture);
        }
        GuiOffscreen(const GuiOffscreen&) = delete;
        GuiOffscreen& operator=(const GuiOffscreen&) = delete;

        [[nodiscard]] bool IsReady() const noexcept { return m_ready; }
        [[nodiscard]] u32 Width() const noexcept { return m_width; }
        [[nodiscard]] u32 Height() const noexcept { return m_height; }
        /// The colour target the last draw went into (left in ShaderRead).
        [[nodiscard]] rhi::Texture* Texture() const noexcept { return m_texture; }

        /// `root` styled, laid out at this target's size (at its own display scale) and drawn, the
        /// GPU's work waited for, the stages timed into `times`. False when the target is not ready.
        bool Draw(SceneRoot& root, Times* times = nullptr) { return Render(root, {}, nullptr, times); }
        /// Draw, and the picture read back into `out` and written to `path` as a PNG.
        bool Picture(SceneRoot& root, StringView path, image::Image& out, Times* times = nullptr)
        {
            return Render(root, path, &out, times);
        }

    private:
        bool Render(SceneRoot& root, StringView path, image::Image* out, Times* times)
        {
            if (!m_ready)
                return false;
            rhi::Device& device = *m_host.m_device.Raw();
            device.WaitIdle(); // the baker's frame slots are the windows' too
            root.SetViewportSize(Float2{static_cast<f32>(m_width), static_cast<f32>(m_height)});
            m_host.StyleAndLayOut(root);
            (void)root.NeedsFrame(); // closes the frame's stats, as a window's frame does

            const Stopwatch drawWatch = Stopwatch::StartNew();
            m_canvas->Clear();
            {
                DrawContext context{*m_canvas};
                root.DrawFrame(context);
            }
            const f64 drawMs = drawWatch.Elapsed().AsMilliseconds();

            m_pool->Reset();
            rhi::CommandEncoder* encoder = nullptr;
            if (!m_pool->CreateEncoder(encoder).IsOk() || encoder == nullptr)
                return false;
            if (m_host.m_baker && m_host.m_bakerReady)
                (void)m_host.m_baker->Record(*encoder, 0);
            const Stopwatch prepareWatch = Stopwatch::StartNew();
            m_renderer.BeginFrame(0);
            const vg::renderer::VGRenderSlice slice = m_renderer.Prepare(m_canvas->GetBatch(), 0, m_width, m_height);
            const f64 prepareMs = prepareWatch.Elapsed().AsMilliseconds();
            const Stopwatch gpuWatch = Stopwatch::StartNew();
            m_renderer.RenderLayers(*encoder, 0, slice);
            encoder->TransitionTexture(m_texture, rhi::ResourceState::Undefined, rhi::ResourceState::RenderTarget);
            const Color background = m_host.m_clear;
            const rhi::ClearColor clear =
                m_space == vg::VGBlendSpace::Encoded
                    ? rhi::ClearColor(background.r, background.g, background.b, background.a)
                    : rhi::ClearColor(SrgbToLinear(background.r), SrgbToLinear(background.g), SrgbToLinear(background.b), background.a);
            rhi::RenderPassDesc pass{};
            if (m_targets.Matches(m_width, m_height))
                pass = m_targets.BeginPass(*encoder, m_view, clear, u8"GUI offscreen");
            else
            {
                rhi::ColorAttachment color{};
                color.view = m_view;
                color.loadOp = rhi::LoadOp::Clear;
                color.storeOp = rhi::StoreOp::Store;
                color.clearValue = clear;
                pass.colorAttachments.Add(color);
            }
            if (rhi::RenderPassEncoder* passEncoder = encoder->BeginRenderPass(pass))
            {
                m_renderer.Render(*passEncoder, m_width, m_height, 0, slice);
                passEncoder->End();
            }
            bool recorded = true;
            if (out != nullptr)
            {
                m_capture.Request(path);
                recorded = m_capture.Record(device, *encoder, m_texture, m_format, m_width, m_height);
            }
            encoder->TransitionTexture(m_texture, rhi::ResourceState::RenderTarget, rhi::ResourceState::ShaderRead);
            rhi::CommandBuffer* commands = encoder->Finish();
            rhi::CommandBuffer* const buffers[1] = {commands};
            device.GetQueue(rhi::QueueType::Graphics, 0)->Submit(Span<rhi::CommandBuffer* const>(buffers, 1), m_fence, ++m_fenceValue);
            m_fence->Wait(m_fenceValue, ~0ull);
            const f64 gpuMs = gpuWatch.Elapsed().AsMilliseconds();
            m_pool->DestroyEncoder(encoder);
            if (times != nullptr)
                *times = Times{drawMs, prepareMs, gpuMs};
            return out == nullptr || (recorded && m_capture.Complete(device, m_allocator, *out).IsOk());
        }

        IAllocator& m_allocator;
        GuiHost& m_host;
        vg::renderer::VGRenderer m_renderer;
        vg::renderer::VGPassTargets m_targets;
        UniquePtr<vg::VGContext> m_canvas;
        rhi::Texture* m_texture = nullptr;
        rhi::TextureView* m_view = nullptr;
        rhi::CommandPool* m_pool = nullptr;
        rhi::Fence* m_fence = nullptr;
        u64 m_fenceValue = 0;
        rhi::ScreenshotCapture m_capture;
        u32 m_width;
        u32 m_height;
        rhi::TextureFormat m_format;
        vg::VGBlendSpace m_space = vg::VGBlendSpace::Linear;
        bool m_ready = false;
    };
}
