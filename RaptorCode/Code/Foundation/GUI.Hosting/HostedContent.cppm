// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Hosting - :hosted_content partition: IHostedContent, what a node shows that is drawn outside
// the GUI's batch (a 3D scene into a target of its own, GUI.Viewport's Viewport).
//
// The host drives it each frame, so an application wires none of it: it binds the content to the
// renderer of the window its node is in (again when the node moves to another window, a panel
// floated or docked back), places its input surface over the node in that window's pixels, and on
// that window's frame records its drawing before the GUI's pass samples it. Its input surfaces go
// through a router of their own, so the GUI still sees the pointer (the node's hover and focus)
// while the content reads its own, gated to the node.

module;
#include "Core/Prelude.h"

export module foundation.gui.hosting:hosted_content;

import foundation.core;
import foundation.rhi;
import foundation.shell;
import foundation.vg.renderer;
import foundation.gui;

using namespace foundation::core;
namespace rhi = foundation::rhi;
namespace shell = foundation::shell;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    class IHostedContent
    {
    public:
        virtual ~IHostedContent() = default;

        /// The node it shows in: its root says which window it is in.
        [[nodiscard]] virtual Node* HostedNode() = 0;
        /// Bound to the window it is in: `renderer` draws that window's GUI (null: in no window, its
        /// last let go), `input` and `windowId` its input surface's.
        virtual void Bind(rhi::Device& device, vg::renderer::VGRenderer* renderer, shell::IInputManager* input, u32 windowId) = 0;
        /// Where its node lies in its window, in the window's pixels, and the window's size.
        virtual void Place(Rectangle windowPixels, Float2 windowSize) = 0;
        /// Its drawing, on its window's frame, before that window's GUI is drawn.
        virtual void Record(rhi::CommandEncoder& encoder, i32 frameIndex) = 0;
        /// The input surface the host's content router gates (null until bound).
        [[nodiscard]] virtual shell::InputSurface* HostedSurface() = 0;
    };
}
