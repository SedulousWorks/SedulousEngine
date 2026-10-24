// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Hosting - :pass_renderer partition: GuiPassRenderer, a root drawn into a render pass its
// caller owns (E4 of Specs/gui-lab-evolution-3.md).
//
// The window host owns its windows' backbuffers and opens its own passes; an engine owns its frame
// and hands its overlays a pass that is already open, on a target of its own format, maybe with a
// depth-stencil attachment, maybe a region of it (a split screen's view). This draws a root there:
// on a device the caller gives (no window, no shell), with the VG shaders and a picture baker of
// its own. A renderer per kind of pass it is asked to draw into (format, depth-stencil, samples,
// blend space), each rewound once a frame however many roots draw through it, so a frame's
// overlays never overwrite each other's slices.
//
// A frame: BeginFrame; RecordBakes on the frame's encoder before any pass that samples them; then
// per root, Prepare (its offscreen layers recorded on the encoder when one is given, else drawn in
// place) before the pass opens, and Draw inside it; or DrawInPass where only the pass is at hand.
// The root is styled and laid out at the view's size by its owner first: this only draws.
//
// The bakes hold colour in one blend space (the constructor's), as a window host's do: a pass in
// the other space shows them a little off at their soft edges.

module;
#include "Core/Prelude.h"

export module foundation.gui.hosting:pass_renderer;

import foundation.core;
import foundation.rhi;
import foundation.image;
import foundation.fonts;
import foundation.vg;
import foundation.vg.renderer;
import foundation.gui;
import :vg_shaders;
import :picture_baker;

using namespace foundation::core;
namespace rhi = foundation::rhi;
namespace image = foundation::image;
namespace vg = foundation::vg;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    /// The pass a root draws into, and where in it.
    struct GuiPassView
    {
        i32 X = 0; ///< the region's corner in the pass's target, in pixels
        i32 Y = 0;
        u32 Width = 0; ///< the region's size: the root's content maps to it
        u32 Height = 0;
        rhi::TextureFormat Format = rhi::TextureFormat::BGRA8Unorm;
        /// The pass's depth-stencil attachment (Undefined: colour only); with one, fills that need
        /// it use the stencil.
        rhi::TextureFormat DepthStencilFormat = rhi::TextureFormat::Undefined;
        u32 SampleCount = 1;
        /// The pass draws through a UNORM view of an sRGB target, colours kept encoded (VG's
        /// Encoded blend space); false: linear light.
        bool Encoded = false;
        u32 FrameIndex = 0;
        /// The root's pixels onto the region's: identity, or a quarter turn when the content is
        /// presented turned (a landscape game on a portrait target).
        Float4x4 Transform = Float4x4::Identity();
    };

    class GuiPassRenderer
    {
    public:
        /// A root's batch uploaded for one pass, drawn into it by Draw (this frame only).
        struct Prepared
        {
            vg::renderer::VGRenderer* Renderer = nullptr; ///< null: nothing to draw
            vg::renderer::VGRenderSlice Slice{};
            GuiPassView View{};
        };

        /// Draws on `device` with `framesInFlight` frame slots, `fonts` the GUI's text and an SVG's,
        /// `shaders` (borrowed, outliving this); bakes in `bakeFormat` and `bakeSpace`.
        GuiPassRenderer(IAllocator& allocator, rhi::Device& device, u32 framesInFlight, fonts::IFontService* fonts, const VgShaderSet& shaders,
                        rhi::TextureFormat bakeFormat = rhi::TextureFormat::RGBA8UnormSrgb, vg::VGBlendSpace bakeSpace = vg::VGBlendSpace::Linear)
            : m_allocator(allocator), m_device(device), m_framesInFlight(framesInFlight == 0 ? 1 : framesInFlight),
              m_shaders(shaders), m_canvas(fonts), m_renderers(allocator), m_textures(allocator)
        {
            if (!m_shaders.IsUsable())
                return;
            m_canvas.SetPerPixelGradients(m_shaders.GradientRadial != nullptr && m_shaders.GradientConic != nullptr);
            m_canvas.SetAnalyticBoxes(m_shaders.BoxVertex != nullptr && m_shaders.BoxFragment != nullptr);
            m_baker = MakeUnique<GpuPictureBaker>(allocator, allocator, device, fonts);
            PictureBakerSetup setup;
            setup.VertexShader = m_shaders.Vertex;
            setup.FragmentShader = m_shaders.Fragment;
            setup.GradientRadialShader = m_shaders.GradientRadial;
            setup.GradientConicShader = m_shaders.GradientConic;
            setup.DistanceFieldShader = m_shaders.DistanceField;
            setup.Format = bakeFormat;
            setup.BlendSpace = bakeSpace;
            setup.FrameCount = static_cast<i32>(m_framesInFlight);
            if (!m_baker->Initialize(setup).IsOk())
                m_baker.Reset();
        }
        ~GuiPassRenderer()
        {
            if (m_renderers.IsEmpty() && !m_baker)
                return;
            m_device.WaitIdle(); // frames in flight sample the bakes and read the renderers' rings
            for (const UniquePtr<Entry>& entry : m_renderers)
            {
                if (m_baker)
                    m_baker->RemoveTarget(entry->Renderer);
                entry->Renderer.Dispose();
            }
            m_renderers.Clear();
            if (m_baker)
                m_baker->Dispose();
        }
        GuiPassRenderer(const GuiPassRenderer&) = delete;
        GuiPassRenderer& operator=(const GuiPassRenderer&) = delete;

        /// Whether anything can be drawn: the shaders every draw needs are there.
        [[nodiscard]] bool IsUsable() const noexcept { return m_shaders.IsUsable(); }
        /// The baker its roots' SVG skins draw from (the GUI's, GUIContext::SetPictureBaker); null
        /// without shaders.
        [[nodiscard]] GpuPictureBaker* Baker() noexcept { return m_baker.Get(); }

        /// The fonts its roots' text and an SVG's draw with from now on (the GUI's changed: a
        /// project's own): what made a text's glyphs is what draws them.
        void SetFontService(fonts::IFontService* fonts) noexcept
        {
            m_canvas.SetFontService(fonts);
            if (m_baker)
                m_baker->SetFontService(fonts);
        }

        /// A frame begins: each renderer rewinds at its first use in it, and the bakes may record.
        void BeginFrame() noexcept
        {
            ++m_frame;
            m_bakesRecorded = false;
        }
        /// The bakes queued since the last frame, recorded on `encoder` before any pass that samples
        /// them; once a frame (false after the first, or with nothing recorded).
        bool RecordBakes(rhi::CommandEncoder& encoder, u32 frameIndex)
        {
            if (!m_baker || m_bakesRecorded)
                return false;
            m_bakesRecorded = true;
            return m_baker->Record(encoder, static_cast<i32>(frameIndex));
        }

        /// `root` drawn for `view` and uploaded, before the pass opens: its offscreen layers recorded
        /// on `layers` when given (passes do not nest), else drawn in place.
        Prepared Prepare(SceneRoot& root, const GuiPassView& view, rhi::CommandEncoder* layers = nullptr)
        {
            Prepared prepared;
            prepared.View = view;
            if (!m_shaders.IsUsable() || view.Width == 0 || view.Height == 0)
                return prepared;
            vg::renderer::VGRenderer* renderer = RendererFor(view);
            if (renderer == nullptr)
                return prepared;
            const bool stencil = view.DepthStencilFormat != rhi::TextureFormat::Undefined && renderer->StencilFillsSupported();
            const bool layered = layers != nullptr && m_shaders.Layer != nullptr;
            m_canvas.SetStencilFills(stencil); // what the batch emits matches the pass it draws into
            m_canvas.SetLayers(layered);
            m_canvas.Clear();
            m_canvas.SetTransform(view.Transform);
            {
                DrawContext context{m_canvas};
                root.DrawFrame(context);
            }
            vg::VGBatch& batch = m_canvas.GetBatch();
            if (batch.commands.IsEmpty())
                return prepared;
            const i32 slot = static_cast<i32>(view.FrameIndex % m_framesInFlight);
            prepared.Slice = renderer->Prepare(batch, slot, view.Width, view.Height);
            prepared.Renderer = renderer;
            if (layered)
                renderer->RenderLayers(*layers, slot, prepared.Slice);
            return prepared;
        }
        /// What Prepare uploaded, drawn into the open pass at its view's region.
        void Draw(rhi::RenderPassEncoder& pass, const Prepared& prepared)
        {
            if (prepared.Renderer == nullptr)
                return;
            const GuiPassView& view = prepared.View;
            prepared.Renderer->Render(pass, view.X, view.Y, view.Width, view.Height, static_cast<i32>(view.FrameIndex % m_framesInFlight),
                                      prepared.Slice);
        }
        /// Prepare and Draw where only the open pass is at hand: its layers drawn in place.
        void DrawInPass(SceneRoot& root, rhi::RenderPassEncoder& pass, const GuiPassView& view) { Draw(pass, Prepare(root, view)); }

        /// An image the GUI draws by `key` (an image source the caller's resource provider answers)
        /// sampled from `view`: told to every renderer, those made later too.
        void RegisterTexture(const image::ImageData* key, rhi::TextureView* view)
        {
            if (key == nullptr || view == nullptr)
                return;
            UnregisterTexture(key);
            m_textures.PushBack(Texture{key, view});
            for (const UniquePtr<Entry>& entry : m_renderers)
                entry->Renderer.RegisterExternalTexture(key, view);
        }
        void UnregisterTexture(const image::ImageData* key)
        {
            for (usize i = 0; i < m_textures.Size(); ++i)
                if (m_textures[i].Key == key)
                {
                    for (const UniquePtr<Entry>& entry : m_renderers)
                        entry->Renderer.UnregisterExternalTexture(key);
                    m_textures.RemoveAt(i);
                    return;
                }
        }

        /// The renderers made so far, one per kind of pass drawn into.
        [[nodiscard]] usize RendererCount() const noexcept { return m_renderers.Size(); }
        /// The renderer drawing into passes like `view`'s; null before one was drawn into.
        [[nodiscard]] vg::renderer::VGRenderer* FindRenderer(const GuiPassView& view) noexcept
        {
            Entry* entry = Find(view);
            return entry != nullptr ? &entry->Renderer : nullptr;
        }

    private:
        struct Entry
        {
            explicit Entry(IAllocator& allocator) noexcept : Renderer(allocator) {}
            vg::renderer::VGRenderer Renderer;
            rhi::TextureFormat Format = rhi::TextureFormat::Undefined;
            rhi::TextureFormat DepthStencilFormat = rhi::TextureFormat::Undefined;
            u32 SampleCount = 1;
            bool Encoded = false;
            u64 BegunFrame = ~0ull; // the frame its ring last rewound in
        };
        struct Texture
        {
            const image::ImageData* Key = nullptr;
            rhi::TextureView* View = nullptr;
        };

        [[nodiscard]] Entry* Find(const GuiPassView& view) noexcept
        {
            for (const UniquePtr<Entry>& entry : m_renderers)
                if (entry->Format == view.Format && entry->DepthStencilFormat == view.DepthStencilFormat &&
                    entry->SampleCount == view.SampleCount && entry->Encoded == view.Encoded)
                    return entry.Get();
            return nullptr;
        }
        // The renderer for passes like `view`'s, made at its first use, rewound once a frame (a
        // rewind clears what the frame's earlier roots uploaded).
        vg::renderer::VGRenderer* RendererFor(const GuiPassView& view)
        {
            Entry* entry = Find(view);
            if (entry == nullptr)
            {
                UniquePtr<Entry> made = MakeUnique<Entry>(m_allocator, m_allocator);
                vg::renderer::VGTargetConfig config;
                config.sampleCount = view.SampleCount == 0 ? 1 : view.SampleCount;
                config.depthStencilFormat = view.DepthStencilFormat;
                config.blendSpace = view.Encoded ? vg::VGBlendSpace::Encoded : vg::VGBlendSpace::Linear;
                if (!made->Renderer
                         .Initialize(m_device, *m_shaders.Vertex, *m_shaders.Fragment, view.Format, static_cast<i32>(m_framesInFlight),
                                     m_shaders.DistanceField, m_shaders.GradientRadial, m_shaders.GradientConic, config, m_shaders.BoxShadow,
                                     m_shaders.BoxVertex, m_shaders.BoxFragment, m_shaders.Layer, m_shaders.BlurVertex, m_shaders.BlurFragment)
                         .IsOk())
                    return nullptr;
                made->Format = view.Format;
                made->DepthStencilFormat = view.DepthStencilFormat;
                made->SampleCount = view.SampleCount;
                made->Encoded = view.Encoded;
                if (m_baker)
                    m_baker->AddTarget(made->Renderer);
                for (const Texture& texture : m_textures)
                    made->Renderer.RegisterExternalTexture(texture.Key, texture.View);
                entry = made.Get();
                m_renderers.PushBack(Move(made));
            }
            if (entry->BegunFrame != m_frame)
            {
                entry->Renderer.BeginFrame(static_cast<i32>(view.FrameIndex % m_framesInFlight));
                entry->BegunFrame = m_frame;
            }
            return &entry->Renderer;
        }

        IAllocator& m_allocator;
        rhi::Device& m_device;
        u32 m_framesInFlight;
        VgShaderSet m_shaders; // borrowed modules
        vg::VGContext m_canvas;
        UniquePtr<GpuPictureBaker> m_baker;
        Array<UniquePtr<Entry>> m_renderers;
        Array<Texture> m_textures;
        u64 m_frame = 0;
        bool m_bakesRecorded = false;
    };
}
