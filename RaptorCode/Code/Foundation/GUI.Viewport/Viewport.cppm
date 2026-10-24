// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - `foundation.gui.viewport`: Viewport, a widget that shows content drawn into a colour
// target (and depth) of its own: a 3D scene, a game in an editor's panel.
//
// The application fills OnRender, which records into the targets on the frame's encoder (the
// barriers around it are the widget's). The widget is hosted content (GUI.Hosting's IHostedContent):
// handed to the host once (HostIn), it is bound to the renderer of the window its node is in and
// bound again when the node moves to another window, its targets follow the node's size in that
// window's device pixels (or a fixed resolution), its drawing is recorded on that window's frame
// before the GUI samples the colour target, and its input surface is placed over the node, so the
// content's keyboard and mouse (Mouse(), Keyboard(), Touch()) are gated to it: a camera reads them
// while the node is hovered or focused (IsActive), and a drag begun in it keeps them past its edge.
//
// From foundation.ui's ViewportView (UI.Viewport): its fit (core::ContentFit, for the picture and
// the pointer alike), its formats (RGBA16Float and Depth32Float by default), a fixed resolution, a
// clear when there is nothing to draw. Not carried: the editor's game-in-a-panel keyboard capture
// and hosted text input, which wait for an embedded GUI to need them.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.viewport;

import foundation.core;
import foundation.rhi;
import foundation.image;
import foundation.shell;
import foundation.vg;
import foundation.vg.renderer;
import foundation.gui;
import foundation.gui.hosting; // IHostedContent, GuiHost

using namespace foundation::core;
namespace core = foundation::core;
namespace rhi = foundation::rhi;
namespace image = foundation::image;
namespace shell = foundation::shell;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    class Viewport : public UIWidget, public IHostedContent
    {
        RTTI_OBJECT(Viewport, UIWidget)
    public:
        /// Records the content into the targets (a pass on ColorView() and DepthView(), cleared to
        /// LinearClearColor()); the targets are in their render states while it runs.
        using RenderHandler = Function<void(Viewport& viewport, rhi::CommandEncoder& encoder, i32 frameIndex)>;
        RenderHandler OnRender;
        /// The targets were made again, at this size (a camera's aspect follows it).
        Function<void(u32 width, u32 height)> OnResized;
        /// What shows where the content draws nothing, as authored (sRGB).
        Color ClearColor{0.347f, 0.347f, 0.377f, 1.0f};

        Viewport()
        {
            SetTag(core::StringView(u8"viewport"));
            SetTabFocusable(true); // a click focuses it: the content then has the keyboard
        }
        ~Viewport() override
        {
            if (m_host != nullptr)
                m_host->RemoveContent(*this);
            ReleaseTargets();
        }
        Viewport(const Viewport&) = delete;
        Viewport& operator=(const Viewport&) = delete;

        /// Hosted by `host` from now on: bound, placed and drawn each frame while it is in a window.
        void HostIn(GuiHost& host)
        {
            if (m_host == &host)
                return;
            if (m_host != nullptr)
                m_host->RemoveContent(*this);
            m_host = &host;
            host.AddContent(*this);
        }

        [[nodiscard]] rhi::ClearColor LinearClearColor() const noexcept
        {
            return rhi::ClearColor{SrgbToLinear(ClearColor.r), SrgbToLinear(ClearColor.g), SrgbToLinear(ClearColor.b), ClearColor.a};
        }
        /// How the targets' picture fits the node (and the pointer maps back into it).
        [[nodiscard]] FitMode GetFitMode() const noexcept { return m_fit; }
        void SetFitMode(FitMode mode)
        {
            m_fit = mode;
            Invalidate();
        }
        /// The targets' formats, which the content's pipelines are built for.
        [[nodiscard]] rhi::TextureFormat ColorFormat() const noexcept { return m_colorFormat; }
        [[nodiscard]] rhi::TextureFormat DepthFormat() const noexcept { return m_depthFormat; }
        void SetFormats(rhi::TextureFormat color, rhi::TextureFormat depth)
        {
            if (color == m_colorFormat && depth == m_depthFormat)
                return;
            m_colorFormat = color;
            m_depthFormat = depth;
            if (m_width > 0 && m_height > 0)
                Resize(m_width, m_height);
        }
        /// A resolution of its own, whatever the node's size (0 by 0: the node's device pixels).
        void SetFixedResolution(u32 width, u32 height)
        {
            m_fixedWidth = width;
            m_fixedHeight = height;
            if (width > 0 && height > 0)
                Resize(width, height);
        }

        [[nodiscard]] bool IsReady() const noexcept { return m_colorView != nullptr && m_depthView != nullptr; }
        [[nodiscard]] rhi::TextureView* ColorView() const noexcept { return m_colorView; }
        [[nodiscard]] rhi::TextureView* DepthView() const noexcept { return m_depthView; }
        [[nodiscard]] rhi::Texture* ColorTexture() const noexcept { return m_colorTexture; }
        [[nodiscard]] u32 RenderWidth() const noexcept { return m_width; }
        [[nodiscard]] u32 RenderHeight() const noexcept { return m_height; }
        /// The window it is bound to (0: none).
        [[nodiscard]] u32 WindowId() const noexcept { return m_windowId; }

        /// The content's input, gated to the node: read it while IsActive().
        [[nodiscard]] shell::IMouse* Mouse() const noexcept { return m_surface ? m_surface->Mouse() : nullptr; }
        [[nodiscard]] shell::IKeyboard* Keyboard() const noexcept { return m_surface ? m_surface->Keyboard() : nullptr; }
        [[nodiscard]] shell::ITouch* Touch() const noexcept { return m_surface ? m_surface->Touch() : nullptr; }
        /// Whether the content should take input now: the node is hovered or focused.
        [[nodiscard]] bool IsActive() const noexcept { return IsHovered() || IsFocused(); }

        // === IHostedContent ===
        Node* HostedNode() override { return this; }
        void Bind(rhi::Device& device, vg::renderer::VGRenderer* renderer, shell::IInputManager* input, u32 windowId) override
        {
            m_device = &device;
            if (renderer != m_renderer)
            {
                if (m_registered && m_renderer != nullptr)
                {
                    m_device->WaitIdle(); // frames in flight sample it through the old one
                    m_renderer->UnregisterExternalTexture(m_key.Get());
                    m_registered = false;
                }
                m_renderer = renderer;
                if (m_renderer != nullptr && m_colorView != nullptr)
                {
                    m_renderer->RegisterExternalTexture(m_key.Get(), m_colorView);
                    m_registered = true;
                }
            }
            m_windowId = windowId;
            if (input != nullptr && !m_surface)
                m_surface = MakeUnique<shell::InputSurface>(MemoryAllocator(), input, windowId,
                                                            ContentFit{Rectangle{0.0f, 0.0f, 1.0f, 1.0f}, Float2{1.0f, 1.0f}, m_fit});
            else if (m_surface)
                m_surface->SetWindow(windowId);
            Invalidate();
        }
        void Place(Rectangle windowPixels, Float2 windowSize) override
        {
            // The targets follow the node in device pixels, unless the content has a size of its own.
            const u32 width = m_fixedWidth > 0 ? m_fixedWidth : static_cast<u32>(Max(1.0f, windowPixels.width + 0.5f));
            const u32 height = m_fixedHeight > 0 ? m_fixedHeight : static_cast<u32>(Max(1.0f, windowPixels.height + 0.5f));
            if (width != m_width || height != m_height || (!IsReady() && m_device != nullptr))
                Resize(width, height);
            if (!m_surface)
                return;
            m_surface->SetRegion(windowPixels);
            m_surface->SetWindowSize(windowSize);
            m_surface->SetContentSize(Float2{static_cast<f32>(m_width), static_cast<f32>(m_height)});
            m_surface->SetFitMode(m_fit);
        }
        void Record(rhi::CommandEncoder& encoder, i32 frameIndex) override
        {
            if (!IsReady())
                return;
            encoder.TransitionTexture(m_colorTexture, m_colorState, rhi::ResourceState::RenderTarget);
            if (!OnRender)
            {
                // Nothing to draw: the colour target still holds something defined to sample.
                rhi::RenderPassDesc pass;
                rhi::ColorAttachment color;
                color.view = m_colorView;
                color.loadOp = rhi::LoadOp::Clear;
                color.storeOp = rhi::StoreOp::Store;
                color.clearValue = LinearClearColor();
                pass.colorAttachments.Add(color);
                if (rhi::RenderPassEncoder* passEncoder = encoder.BeginRenderPass(pass))
                    passEncoder->End();
            }
            else
            {
                if (m_depthState != rhi::ResourceState::DepthStencilWrite)
                {
                    encoder.TransitionTexture(m_depthTexture, m_depthState, rhi::ResourceState::DepthStencilWrite);
                    m_depthState = rhi::ResourceState::DepthStencilWrite;
                }
                OnRender(*this, encoder, frameIndex);
            }
            encoder.TransitionTexture(m_colorTexture, rhi::ResourceState::RenderTarget, rhi::ResourceState::ShaderRead);
            m_colorState = rhi::ResourceState::ShaderRead;
        }
        shell::InputSurface* HostedSurface() override { return m_surface.Get(); }

    protected:
        /// 256 by 256 when nothing sizes it.
        [[nodiscard]] Float2 MeasureContent(Float2 available) override
        {
            (void)available;
            return Float2{256.0f, 256.0f};
        }
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            (void)localBounds;
            const Rect box = GetContentBounds();
            if (!m_registered || m_width == 0 || m_height == 0)
            {
                ctx.VG().FillRect(box.ToRectangle(), Color{0.098f, 0.098f, 0.118f, 1.0f}); // not bound yet
                return;
            }
            // Live content changes outside the GUI's knowledge: a shown viewport asks for every frame.
            Invalidate();
            const ContentFit fit{box.ToRectangle(), Float2{static_cast<f32>(m_width), static_cast<f32>(m_height)}, m_fit};
            const Rectangle at = fit.DstRect();
            if (at.width < box.width || at.height < box.height)
                ctx.VG().FillRect(box.ToRectangle(), Color{0.0f, 0.0f, 0.0f, 1.0f}); // a letterbox's bars
            ctx.VG().DrawImage(m_key.Get(), at, fit.SrcRect(), Color::White);
        }

    private:
        void Resize(u32 width, u32 height)
        {
            if (m_device == nullptr)
            {
                m_width = width;
                m_height = height;
                return;
            }
            if (m_colorTexture != nullptr || m_depthTexture != nullptr)
                m_device->WaitIdle(); // frames in flight sample the old ones
            if (m_registered && m_renderer != nullptr)
            {
                m_renderer->UnregisterExternalTexture(m_key.Get());
                m_registered = false;
            }
            DestroyTargets();
            m_width = width;
            m_height = height;
            m_colorState = rhi::ResourceState::Undefined;
            m_depthState = rhi::ResourceState::Undefined;
            m_key = MakeUnique<image::ImageDataRef>(MemoryAllocator(), width, height); // what the renderer knows it by
            rhi::TextureDesc colorDesc = rhi::TextureDesc::RenderTarget(m_colorFormat, width, height, 1, u8"ViewportColor");
            colorDesc.usage = colorDesc.usage | rhi::TextureUsage::CopySrc; // a capture copies it out
            if (!m_device->CreateTexture(colorDesc, m_colorTexture).IsOk() ||
                !m_device->CreateTextureView(m_colorTexture, rhi::TextureViewDesc{}, m_colorView).IsOk())
            {
                DestroyTargets();
                return;
            }
            rhi::TextureDesc depthDesc = rhi::TextureDesc::DepthBuffer(m_depthFormat, width, height, 1, u8"ViewportDepth");
            if (!m_device->CreateTexture(depthDesc, m_depthTexture).IsOk() ||
                !m_device->CreateTextureView(m_depthTexture, rhi::TextureViewDesc{}, m_depthView).IsOk())
            {
                DestroyTargets();
                return;
            }
            if (m_renderer != nullptr)
            {
                m_renderer->RegisterExternalTexture(m_key.Get(), m_colorView);
                m_registered = true;
            }
            Invalidate();
            if (OnResized)
                OnResized(width, height);
        }
        void DestroyTargets()
        {
            if (m_device == nullptr)
                return;
            if (m_depthView != nullptr)
                m_device->DestroyTextureView(m_depthView);
            if (m_depthTexture != nullptr)
                m_device->DestroyTexture(m_depthTexture);
            if (m_colorView != nullptr)
                m_device->DestroyTextureView(m_colorView);
            if (m_colorTexture != nullptr)
                m_device->DestroyTexture(m_colorTexture);
            m_depthView = nullptr;
            m_depthTexture = nullptr;
            m_colorView = nullptr;
            m_colorTexture = nullptr;
        }
        void ReleaseTargets()
        {
            if (m_device != nullptr && (m_colorTexture != nullptr || m_depthTexture != nullptr))
                m_device->WaitIdle();
            if (m_registered && m_renderer != nullptr)
                m_renderer->UnregisterExternalTexture(m_key.Get());
            m_registered = false;
            DestroyTargets();
        }

        GuiHost* m_host = nullptr;
        rhi::Device* m_device = nullptr;
        vg::renderer::VGRenderer* m_renderer = nullptr; // its window's
        UniquePtr<image::ImageDataRef> m_key;
        rhi::Texture* m_colorTexture = nullptr;
        rhi::TextureView* m_colorView = nullptr;
        rhi::Texture* m_depthTexture = nullptr;
        rhi::TextureView* m_depthView = nullptr;
        rhi::ResourceState m_colorState = rhi::ResourceState::Undefined;
        rhi::ResourceState m_depthState = rhi::ResourceState::Undefined;
        rhi::TextureFormat m_colorFormat = rhi::TextureFormat::RGBA16Float;
        rhi::TextureFormat m_depthFormat = rhi::TextureFormat::Depth32Float;
        UniquePtr<shell::InputSurface> m_surface;
        FitMode m_fit = FitMode::Stretch;
        u32 m_width = 0;
        u32 m_height = 0;
        u32 m_fixedWidth = 0;
        u32 m_fixedHeight = 0;
        u32 m_windowId = 0;
        bool m_registered = false;
    };

    RTTI_DEFINE_OBJECT(Viewport, "rtti::gui")
}
