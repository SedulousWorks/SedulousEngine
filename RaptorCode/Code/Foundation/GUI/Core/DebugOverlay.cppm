// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :debug_overlay partition
//
// DebugOverlay: what a root draws over its tree to show its workings (E8c of
// Specs/gui-lab-evolution.md). The layout's (each node's border box, padding, margin and
// baseline) and the input's: the focus path, the tab order, the last directional move's
// candidates, the node under the pointer, and a flash on the nodes that asked for a redraw.

module;
#include "Core/Prelude.h"

export module foundation.gui:debug_overlay;


export namespace foundation::gui
{
    /// What a root's debug overlay shows (nothing by default).
    struct DebugOverlay
    {
        // The layout's, for working on a layout.
        bool Bounds = false;    ///< each node's border box (red)
        bool Padding = false;   ///< its padding (green)
        bool Margin = false;    ///< its margin (orange)
        bool Baselines = false; ///< a baseline of its own (magenta)
        // The input's.
        bool FocusPath = false;   ///< the focused node and each node holding it, named
        bool TabOrder = false;    ///< the tab stops in order, numbered and joined
        bool Navigation = false;  ///< the last directional move: each candidate, its score or why not, the one chosen
        bool Pointer = false;     ///< the node under the pointer, named, with its size
        bool RedrawFlash = false; ///< the nodes that invalidated themselves, fading after the frame

        [[nodiscard]] static constexpr DebugOverlay Layout() noexcept { return {true, true, true, true}; }
        [[nodiscard]] static constexpr DebugOverlay Input() noexcept
        {
            DebugOverlay o;
            o.FocusPath = o.TabOrder = o.Navigation = o.Pointer = o.RedrawFlash = true;
            return o;
        }
        [[nodiscard]] constexpr bool AnyLayout() const noexcept { return Bounds || Padding || Margin || Baselines; }
        [[nodiscard]] constexpr bool AnyInput() const noexcept { return FocusPath || TabOrder || Navigation || Pointer || RedrawFlash; }
        [[nodiscard]] constexpr bool Any() const noexcept { return AnyLayout() || AnyInput(); }
        [[nodiscard]] constexpr bool operator==(const DebugOverlay&) const noexcept = default;
    };
}
