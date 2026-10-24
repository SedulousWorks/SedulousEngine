// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :frame_stats partition
//
// FrameStats: what a root's last frame cost and why it was needed (E8a of
// Specs/gui-lab-evolution.md). The phases write it as they run: the style pass its time and the
// widgets it restyled, the layout pass its time and the containers it laid out, the draw its time,
// the nodes it drew and culled and the VG geometry they made. NeedsFrame writes the reasons it
// found, so an idle GUI that is not idle says what keeps it awake. Read by a host's frame stats,
// the inspector's frames tab and tests.

module;
#include "Core/Prelude.h"

export module foundation.gui:frame_stats;

import foundation.core; // String

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// Why a root asked for a frame (each true when it did, as NeedsFrame last found).
    struct FrameReasons
    {
        bool Redraw = false;        ///< something shown was invalidated
        bool Layout = false;        ///< a layout waits
        bool Pending = false;       ///< a binding or a queued mutation waits
        bool HeldDirection = false; ///< a held direction repeats
        bool Animation = false;     ///< an action runs on a node it shows (AnimatedNode names the first)
        bool Overlay = false;       ///< the debug overlay's redraw flashes are fading

        [[nodiscard]] bool Any() const noexcept { return Redraw || Layout || Pending || HeldDirection || Animation || Overlay; }
    };

    struct FrameStats
    {
        FrameReasons Reasons;
        core::String AnimatedNode; ///< the first shown node an action runs on, when Reasons.Animation

        f64 StyleMs = 0.0;
        u32 Restyled = 0; ///< widgets the style pass restyled
        f64 LayoutMs = 0.0;
        u32 LaidOut = 0;  ///< containers the layout pass laid out
        f64 DrawMs = 0.0;
        u32 NodesDrawn = 0;
        u32 NodesCulled = 0; ///< skipped as outside the clip (E8b)
        u32 Vertices = 0;    ///< the VG geometry the draw made
        u32 Commands = 0;
        u64 FramesDrawn = 0; ///< how many frames this root has drawn through DrawFrame

        /// One line: the phases' times and counts, then the reasons.
        [[nodiscard]] core::String Describe() const
        {
            const auto us = [](f64 ms) { return static_cast<u64>(ms * 1000.0 + 0.5); }; // microseconds read better than ms here
            core::String text = core::Format(u8"style {} us ({} restyled), layout {} us ({} laid out), draw {} us ({} drawn, {} culled, {} vertices, {} commands)",
                                             us(StyleMs), Restyled, us(LayoutMs), LaidOut, us(DrawMs), NodesDrawn, NodesCulled, Vertices, Commands);
            text += core::StringView(u8"; asked by:");
            if (!Reasons.Any())
                text += core::StringView(u8" nothing");
            if (Reasons.Redraw)
                text += core::StringView(u8" redraw");
            if (Reasons.Layout)
                text += core::StringView(u8" layout");
            if (Reasons.Pending)
                text += core::StringView(u8" pending");
            if (Reasons.HeldDirection)
                text += core::StringView(u8" held-direction");
            if (Reasons.Animation)
            {
                text += core::StringView(u8" animation (");
                text += AnimatedNode.AsView();
                text += core::StringView(u8")");
            }
            if (Reasons.Overlay)
                text += core::StringView(u8" overlay");
            return text;
        }
    };
}
