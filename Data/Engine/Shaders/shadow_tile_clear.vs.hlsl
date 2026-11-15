// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Clears one tile of the static shadow atlas layer to the far depth: a fullscreen triangle at the
// far plane, drawn with depth compare Always inside the tile's viewport and scissor, in a pass that
// loads the rest of the layer. Depth only: the pipeline has no fragment stage.
#include "depth.hlsli"

float4 main(uint vid : SV_VertexID) : SV_Position {
    float2 raw = float2((vid << 1) & 2, vid & 2);
    return float4(raw * 2.0 - 1.0, kDepthFar, 1.0);
}
