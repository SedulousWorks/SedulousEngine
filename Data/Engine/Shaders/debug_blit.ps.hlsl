// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Editor debug-view blit: visualize ANY render-graph texture in the viewport. The source
// binds UnfilterableFloat and is read via Load (no sampler), so every format works - HDR,
// AO's R8, velocity RG16F, and depth (bound through its depth-only view; value lands in .r).
// Channel select + range remap + optional depth linearization happen here; the pass draws
// the view's sub-rect and overlays/gizmos still draw on top.

#include "push_constant.hlsli"
#include "depth.hlsli"
Texture2D Source : register(t0, space0);
struct DebugBlitPush {
    float2 UvScale;    // fullscreen uv -> view sub-rect
    float2 UvOffset;
    float2 SourceSize; // texels; source may not match the view size
    float  RangeMin;   // output = (value - min) / (max - min)
    float  RangeMax;
    float  NearZ;      // depth linearize (reversed or standard handled by the flag)
    float  FarZ;
    uint   Mode;       // bits 0-2 channel: 0 RGB, 1 R, 2 G, 3 B, 4 A, 5 luma; bit 4 linearize depth
    uint   _pad;
};
PUSH_CONSTANT(DebugBlitPush, pc, space1);

// Perspective depth -> view-space distance (depth.hlsli's convention), normalized by far.
float LinearizeDepthNormalized(float d) { return LinearizeDepth(d, pc.NearZ, pc.FarZ) / pc.FarZ; }

float4 main(float4 pos : SV_Position, float2 rawUv : TEXCOORD0) : SV_Target {
    float2 uv = pc.UvOffset + rawUv * pc.UvScale;
    int2 coord = int2(uv * pc.SourceSize);
    coord = clamp(coord, int2(0, 0), int2(pc.SourceSize) - int2(1, 1));
    float4 v = Source.Load(int3(coord, 0));

    uint channel = pc.Mode & 7u;
    bool linearize = (pc.Mode & 16u) != 0u;
    if (linearize) { v = LinearizeDepthNormalized(v.r).xxxx; }

    float3 rgb;
    if      (channel == 1u) { rgb = v.rrr; }
    else if (channel == 2u) { rgb = v.ggg; }
    else if (channel == 3u) { rgb = v.bbb; }
    else if (channel == 4u) { rgb = v.aaa; }
    else if (channel == 5u) { rgb = dot(v.rgb, float3(0.299, 0.587, 0.114)).xxx; }
    else                    { rgb = v.rgb; }

    float scale = 1.0 / max(pc.RangeMax - pc.RangeMin, 1e-6);
    rgb = saturate((rgb - pc.RangeMin.xxx) * scale);
    return float4(rgb, 1.0);
}
