// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :picture_baker partition
//
// IPictureBaker: the seam through which the GUI asks for a vector picture drawn once, at the size
// it shows in device pixels, and kept as a texture, so that what would tessellate its paths every
// frame (an SVG skin's nine pieces, each the whole document clipped to its place) draws textured
// quads instead. The host's renderer bakes (a GPU texture, never read back): the GUI only asks.
// A picture asked for and not yet baked comes back null and is queued; the GUI draws it as paths
// meanwhile, and redraws when the baker's generation moves (a bake landed).

module;
#include "Core/Prelude.h"

export module foundation.gui:picture_baker;

import foundation.core;   // u32
import foundation.image;  // ImageData
import foundation.vg.svg; // SVGDocument

using namespace foundation::core;

export namespace foundation::gui
{
    class IPictureBaker
    {
    public:
        virtual ~IPictureBaker() = default;

        /// `document` drawn at `width` by `height` device pixels: the image the renderer samples
        /// its texture by (premultiplied colour: VGContext::DrawImagePremultiplied), or null while
        /// it is not baked yet, which asking queues. The document must outlive the bake (a
        /// resource provider's does).
        [[nodiscard]] virtual const foundation::image::ImageData* Baked(const foundation::vg::svg::SVGDocument& document,
                                                                        u32 width, u32 height) = 0;
        /// Counts the bakes that have landed: a GUI that drew a picture as paths while it waited
        /// redraws when this moves.
        [[nodiscard]] virtual u64 Generation() const = 0;
    };
}
