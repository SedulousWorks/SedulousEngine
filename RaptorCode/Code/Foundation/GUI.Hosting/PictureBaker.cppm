// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Hosting - :picture_baker partition: GpuPictureBaker, the GUI's IPictureBaker on the GPU.
//
// A picture the GUI asks for (an SVG at a size in device pixels) is queued; the host's frame
// records the queue (Record, on the frame's own command encoder, before the passes that sample
// it): each picture drawn through a VG renderer of its own into a texture of its own, which every
// window's renderer (its targets) is told to sample under the picture's key
// (RegisterExternalTexture), so a picture baked once shows in any window. Nothing is
// read back, so nothing waits: the frame that asked draws the picture as paths, and the next one
// draws it from the texture. The texture holds premultiplied colour in the canvas's blend space,
// as a layer's target does, so the GUI draws it with VGContext::DrawImagePremultiplied.
//
// A bake no draw has asked for in kKeepFrames frames goes (the GUI's renderer forgets it first):
// that long unasked, no frame still in flight samples it. A window that goes takes its renderer
// out of the targets first (RemoveTarget), which forgets every bake. Bakes draw without stencil fills (the
// bake targets have no depth-stencil), as a context without a stencil-capable renderer does.

module;
#include "Core/Prelude.h"

export module foundation.gui.hosting:picture_baker;

import foundation.core;
import foundation.rhi;
import foundation.image;
import foundation.fonts;
import foundation.vg;
import foundation.vg.svg;
import foundation.vg.renderer;
import foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;
namespace rhi = foundation::rhi;
namespace image = foundation::image;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// What a baker's renderer draws with: the VG shaders the GUI's renderer has (gradients and
    /// boxes as it draws them; none of them but the first two required), the format and blend
    /// space of the GUI's target (a bake holds colour as that target's layers do), and the frames
    /// in flight.
    struct PictureBakerSetup
    {
        rhi::ShaderModule* VertexShader = nullptr;
        rhi::ShaderModule* FragmentShader = nullptr;
        rhi::ShaderModule* GradientRadialShader = nullptr;
        rhi::ShaderModule* GradientConicShader = nullptr;
        rhi::ShaderModule* DistanceFieldShader = nullptr;
        rhi::TextureFormat Format = rhi::TextureFormat::RGBA8UnormSrgb;
        vg::VGBlendSpace BlendSpace = vg::VGBlendSpace::Linear;
        i32 FrameCount = 2;
    };

    class GpuPictureBaker final : public IPictureBaker
    {
    public:
        /// Frames a bake stays after a draw last asked for it.
        static constexpr u64 kKeepFrames = 600;

        /// `fonts` draws an SVG's text. The renderers that sample the bakes are its targets.
        GpuPictureBaker(IAllocator& allocator, rhi::Device& device, foundation::fonts::IFontService* fonts) noexcept
            : m_allocator(allocator), m_device(device), m_renderer(allocator), m_canvas(fonts), m_targets(allocator),
              m_entries(allocator)
        {
        }
        ~GpuPictureBaker() override { Dispose(); }
        GpuPictureBaker(const GpuPictureBaker&) = delete;
        GpuPictureBaker& operator=(const GpuPictureBaker&) = delete;

        [[nodiscard]] Status Initialize(const PictureBakerSetup& setup)
        {
            if (setup.VertexShader == nullptr || setup.FragmentShader == nullptr)
                return Status{ErrorCode::InvalidArgument};
            m_format = setup.Format;
            vg::renderer::VGTargetConfig config;
            config.blendSpace = setup.BlendSpace;
            if (Status status = m_renderer.Initialize(m_device, *setup.VertexShader, *setup.FragmentShader, setup.Format,
                                                      setup.FrameCount, setup.DistanceFieldShader, setup.GradientRadialShader,
                                                      setup.GradientConicShader, config);
                !status.IsOk())
                return status;
            m_canvas.SetPerPixelGradients(setup.GradientRadialShader != nullptr && setup.GradientConicShader != nullptr);
            return Status{ErrorCode::Ok};
        }

        /// Forgets every bake (its targets first) and releases the renderer. The GPU must be done
        /// with them (a host disposes after its device is idle).
        void Dispose()
        {
            for (const UniquePtr<Entry>& entry : m_entries)
                Release(*entry);
            m_entries.Clear();
            m_targets.Clear();
            if (m_renderer.IsInitialized())
                m_renderer.Dispose();
        }

        /// A renderer that samples the bakes (a window's): every bake drawn is registered with it,
        /// those drawn before too.
        /// The fonts an SVG's text draws with from now on (the host's changed: a project's own).
        void SetFontService(foundation::fonts::IFontService* fonts) noexcept { m_canvas.SetFontService(fonts); }

        void AddTarget(vg::renderer::VGRenderer& target)
        {
            for (vg::renderer::VGRenderer* known : m_targets)
                if (known == &target)
                    return;
            m_targets.PushBack(&target);
            for (const UniquePtr<Entry>& entry : m_entries)
                if (entry->View != nullptr)
                    target.RegisterExternalTexture(entry->Key.Get(), entry->View);
        }
        /// A renderer that goes (its window's): it forgets every bake, and is told of no more.
        void RemoveTarget(vg::renderer::VGRenderer& target)
        {
            for (usize i = 0; i < m_targets.Size(); ++i)
                if (m_targets[i] == &target)
                {
                    for (const UniquePtr<Entry>& entry : m_entries)
                        if (entry->View != nullptr)
                            target.UnregisterExternalTexture(entry->Key.Get());
                    m_targets.RemoveAt(i);
                    return;
                }
        }

        const image::ImageData* Baked(const foundation::vg::svg::SVGDocument& document, u32 width, u32 height) override
        {
            for (const UniquePtr<Entry>& entry : m_entries)
                if (entry->Document == &document && entry->Width == width && entry->Height == height)
                {
                    entry->LastAsked = m_frame;
                    return entry->View != nullptr ? entry->Key.Get() : nullptr;
                }
            UniquePtr<Entry> entry = MakeUnique<Entry>(m_allocator);
            entry->Document = &document;
            entry->Width = width;
            entry->Height = height;
            entry->LastAsked = m_frame;
            entry->Key = MakeUnique<image::ImageDataRef>(m_allocator, width, height);
            m_entries.PushBack(Move(entry));
            return nullptr;
        }

        [[nodiscard]] u64 Generation() const override { return m_generation; }

        /// Draws the pictures asked for since the last frame into textures, on `encoder` before the
        /// frame's passes that sample them, after the host waited for `frameIndex`'s last use (as
        /// it does before its own renderer's BeginFrame); and lets the bakes go that no draw has
        /// asked for in kKeepFrames frames. True when any baked: the GUI redraws (Generation).
        bool Record(rhi::CommandEncoder& encoder, i32 frameIndex)
        {
            ++m_frame;
            for (usize i = m_entries.Size(); i > 0; --i)
                if (m_frame - m_entries[i - 1]->LastAsked > kKeepFrames)
                {
                    Release(*m_entries[i - 1]);
                    m_entries.RemoveAt(i - 1);
                }
            bool begun = false;
            bool baked = false;
            for (const UniquePtr<Entry>& entry : m_entries)
            {
                if (entry->View != nullptr || !m_renderer.IsInitialized())
                    continue;
                if (!begun)
                {
                    m_renderer.BeginFrame(frameIndex);
                    begun = true;
                }
                baked = Bake(encoder, frameIndex, *entry) || baked;
            }
            if (baked)
                ++m_generation;
            return baked;
        }

        /// The bakes kept (drawn or waiting).
        [[nodiscard]] usize BakeCount() const noexcept { return m_entries.Size(); }

    private:
        struct Entry
        {
            const foundation::vg::svg::SVGDocument* Document = nullptr; // the key, with the size
            u32 Width = 0;
            u32 Height = 0;
            u64 LastAsked = 0;
            UniquePtr<image::ImageDataRef> Key; // what the GUI's renderer knows the texture by
            rhi::Texture* Texture = nullptr;
            rhi::TextureView* View = nullptr; // set once drawn
        };

        bool Bake(rhi::CommandEncoder& encoder, i32 frameIndex, Entry& entry)
        {
            rhi::TextureDesc desc{};
            desc.dimension = rhi::TextureDimension::Texture2D;
            desc.format = m_format;
            desc.width = entry.Width;
            desc.height = entry.Height;
            desc.depth = 1;
            desc.usage = rhi::TextureUsage::RenderTarget | rhi::TextureUsage::Sampled;
            desc.label = u8"picture bake";
            if (!m_device.CreateTexture(desc, entry.Texture).IsOk() || entry.Texture == nullptr ||
                !m_device.CreateTextureView(entry.Texture, rhi::TextureViewDesc{}, entry.View).IsOk() || entry.View == nullptr)
            {
                Release(entry);
                return false;
            }
            m_canvas.Clear();
            vg::svg::SVGRenderer::Render(m_canvas, *entry.Document,
                                         Rectangle{0.0f, 0.0f, static_cast<f32>(entry.Width), static_cast<f32>(entry.Height)});
            const vg::renderer::VGRenderSlice slice = m_renderer.Prepare(m_canvas.GetBatch(), frameIndex, entry.Width, entry.Height);
            encoder.TransitionTexture(entry.Texture, rhi::ResourceState::Undefined, rhi::ResourceState::RenderTarget);
            rhi::ColorAttachment color{};
            color.view = entry.View;
            color.loadOp = rhi::LoadOp::Clear;
            color.storeOp = rhi::StoreOp::Store;
            color.clearValue = rhi::ClearColor(0.0f, 0.0f, 0.0f, 0.0f);
            rhi::RenderPassDesc pass{};
            pass.colorAttachments.Add(color);
            pass.label = u8"picture bake";
            if (rhi::RenderPassEncoder* encoderPass = encoder.BeginRenderPass(pass))
            {
                if (slice.isValid)
                    m_renderer.Render(*encoderPass, entry.Width, entry.Height, frameIndex, slice);
                encoderPass->End();
            }
            encoder.TransitionTexture(entry.Texture, rhi::ResourceState::RenderTarget, rhi::ResourceState::ShaderRead);
            for (vg::renderer::VGRenderer* target : m_targets)
                target->RegisterExternalTexture(entry.Key.Get(), entry.View);
            return true;
        }

        void Release(Entry& entry)
        {
            if (entry.View != nullptr)
            {
                for (vg::renderer::VGRenderer* target : m_targets)
                    target->UnregisterExternalTexture(entry.Key.Get());
                m_device.DestroyTextureView(entry.View);
                entry.View = nullptr;
            }
            if (entry.Texture != nullptr)
            {
                m_device.DestroyTexture(entry.Texture);
                entry.Texture = nullptr;
            }
        }

        IAllocator& m_allocator;
        rhi::Device& m_device;
        vg::renderer::VGRenderer m_renderer; // the bakes' own: its frame buffers are not the GUI's
        vg::VGContext m_canvas;
        rhi::TextureFormat m_format = rhi::TextureFormat::RGBA8UnormSrgb;
        Array<vg::renderer::VGRenderer*> m_targets; // the windows' renderers, which sample the bakes
        Array<UniquePtr<Entry>> m_entries;
        u64 m_frame = 0;
        u64 m_generation = 0;
    };
}
