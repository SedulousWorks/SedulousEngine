// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// A surface shader's API (Specs/custom-shaders.md, phase 6): what its Surface() and Vertex() are
// written against. The engine includes this before the author's text in each of the shader's
// programs (forward, depth, pick), then its pass template after, which calls them. Only this API
// reaches every pass: the frame's own constants differ by pass (the forward View, the shadow and
// pick views), so a surface reads the camera and the time through its input and Time().
#ifndef SURFACE_HLSLI
#define SURFACE_HLSLI

// What Surface() is given about the point being shaded, in world space.
struct SurfaceInput {
    float3 worldPos;
    float3 normal;      // the interpolated geometric normal, unit length
    float4 tangent;     // xyz = tangent, w = the bitangent's handedness (+-1)
    float2 uv;
    float4 color;       // vertex colour times the mesh's tint
    float3 viewDir;     // from the point toward the camera, unit length
    float4 screenPos;   // SV_Position: xy in pixels
};

// What Surface() decides. It starts as a plain white surface: albedo 1, alpha 1, the geometric
// normal, not metal, roughness 0.5, no occlusion, no emission.
struct SurfaceOutput {
    float3 albedo;
    float  alpha;
    float3 normal;      // tangent space; (0, 0, 1) is the geometric normal
    float  metallic;
    float  roughness;
    float  occlusion;   // 1 = none
    float3 emissive;    // light the surface gives off, unlit, in addition (HDR)
};

SurfaceOutput DefaultSurfaceOutput() {
    SurfaceOutput s;
    s.albedo    = float3(1.0, 1.0, 1.0);
    s.alpha     = 1.0;
    s.normal    = float3(0.0, 0.0, 1.0);
    s.metallic  = 0.0;
    s.roughness = 0.5;
    s.occlusion = 1.0;
    s.emissive  = float3(0.0, 0.0, 0.0);
    return s;
}

// What Vertex() may move, in world space, before the point is projected.
struct VertexInput {
    float3 position;
    float3 normal;
    float3 tangent;
    float3 localPosition; // read only: the mesh's own position (after skinning), before the world
    float2 uv;            // read only
    float4 color;         // read only
};

// The view's clock in seconds. In Vertex() for the forward pass's previous position, last frame's,
// so a moving surface reprojects.
static float g_surfaceTime = 0.0;
float Time() { return g_surfaceTime; }

// What the depth and pick vertex stages hand a masked surface's Surface() (the forward pass has
// VSOutput).
struct SurfaceVSOut {
    float4 pos       : SV_Position;
    float3 worldPos  : TEXCOORD0;
    float3 normalWS  : TEXCOORD1;
    float4 tangentWS : TEXCOORD2;
    float2 uv        : TEXCOORD3;
    float4 color     : TEXCOORD4;
};

#endif
