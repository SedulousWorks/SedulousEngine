// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :disclosure partition
//
// The disclosure chevron (E6 of Specs/gui-lab-evolution.md): the triangle that says whether
// something is open, pointing right when closed and down when open. An expander's header and a
// tree's rows draw the same one.

module;
#include "Core/Prelude.h"

export module foundation.gui:disclosure;

import foundation.core; // Color, Min
import foundation.vg;   // PathBuilder
import :rect;
import :draw_context;

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// Draws the chevron centred in `box`, as large as fits up to 8 pixels across; closed, it points
    /// toward the inline end (left in right to left).
    inline void DrawDisclosure(DrawContext& ctx, const Rect& box, bool open, Color color, bool rightToLeft)
    {
        const f32 s = core::Min(4.0f, core::Min(box.width, box.height) * 0.4f); // half its size
        const f32 cx = box.x + box.width * 0.5f;
        const f32 cy = box.y + box.height * 0.5f;
        vg::PathBuilder pb;
        if (open)
        {
            pb.MoveTo(cx - s, cy - s * 0.5f);
            pb.LineTo(cx + s, cy - s * 0.5f);
            pb.LineTo(cx, cy + s * 0.75f);
        }
        else
        {
            const f32 way = rightToLeft ? -1.0f : 1.0f;
            pb.MoveTo(cx - way * s * 0.5f, cy - s);
            pb.LineTo(cx + way * s * 0.75f, cy);
            pb.LineTo(cx - way * s * 0.5f, cy + s);
        }
        pb.Close();
        ctx.VG().FillPath(pb.ToPath(), color);
    }
}
