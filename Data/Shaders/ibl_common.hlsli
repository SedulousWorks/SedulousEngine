// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
struct IblPush {
    int FaceIndex; int Mode; float Roughness; float SkyIntensity;
    float4 Sun;        // xyz = direction, w = sun angular size (degrees)
    float4 Horizon;    // rgb, a = sun intensity
    float4 Zenith;     // rgb, a = sky rotation (radians)
    float4 Ground;     // rgb
};
PUSH_CONSTANT(IblPush, pc, space1);

// Canonical cube-face direction from a face index + [0,1] face uv. NOTE: no t.y negation - the cube
// faces are rendered through the RHI's negative-viewport (Y-flipped), so the stored texel already
// matches the standard cube-sampling convention; negating here would double-flip and break edge
// continuity. (Verified correct in-engine: the sky background samples this cube by world ray and the
// procedural gradient reads right-side-up.)
float3 DirForFace(int face, float2 uv) {
    float2 t = uv * 2.0 - 1.0;
    float3 d;
    if      (face == 0) d = float3( 1.0,  t.y, -t.x);   // +X
    else if (face == 1) d = float3(-1.0,  t.y,  t.x);   // -X
    else if (face == 2) d = float3( t.x,  1.0, -t.y);   // +Y
    else if (face == 3) d = float3( t.x, -1.0,  t.y);   // -Y
    else if (face == 4) d = float3( t.x,  t.y,  1.0);   // +Z
    else                d = float3(-t.x,  t.y, -1.0);   // -Z
    return normalize(d);
}
