// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Scene-pass MSAA first-sample (sample 0) resolve.
//
// Reads the multisampled depth + G-buffer aux (normal / velocity / material) written by the MSAA
// forward pass and writes SAMPLE 0 into single-sample 1x targets that the post consumers
// (GTAO / SSR / TAA / motion reprojection) read unchanged. Depth goes through SV_Depth into a real
// depth-format target so no consumer's binding or shader declaration changes. Scene COLOR is
// resolved separately by the hardware resolve attachment (averaged - the real edge AA); this pass
// never touches color.
//
// SAMPLE-0 NUANCE: sample 0 of a standard MSAA pattern is NOT the pixel centre, so resolved
// depth/normals sit ~0.4px off where a 1x prepass would have sampled. It is consistent
// frame-to-frame and benign under TAA's own jitter. Depth is NEVER averaged: it is nonlinear, so an
// averaged edge depth is a point in empty space; taking one sample preserves usable depth values.

Texture2DMS<float2> gNormalMS   : register(t0, space0); // RG16Float octahedral view-space normal
Texture2DMS<float2> gVelocityMS : register(t1, space0); // RG16Float screen-space motion (UV delta)
Texture2DMS<float2> gMaterialMS : register(t2, space0); // RG8Unorm  R=roughness G=metallic
Texture2DMS<float>  gDepthMS    : register(t3, space0); // Depth32Float

struct PSIn { float4 pos : SV_Position; float2 uv : TEXCOORD0; };
struct PSOut {
    float2 normal   : SV_Target0;
    float2 velocity : SV_Target1;
    float2 material : SV_Target2;
    float  depth    : SV_Depth;
};

PSOut main(PSIn i) {
    int2 c = int2(i.pos.xy);
    PSOut o;
    o.normal   = gNormalMS.Load(c, 0);
    o.velocity = gVelocityMS.Load(c, 0);
    o.material = gMaterialMS.Load(c, 0);
    o.depth    = gDepthMS.Load(c, 0);
    return o;
}
