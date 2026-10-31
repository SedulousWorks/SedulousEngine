// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// After the author's text, before a pass template: the calls every pass makes into Surface() and
// Vertex(). SURFACE_HAS_VERTEX (the cook defines it when the text has a Vertex()) and
// SURFACE_HAS_ALPHA_CUTOFF (when its properties declare a float AlphaCutoff) say what is there.
#ifndef SURFACE_GLUE_HLSLI
#define SURFACE_GLUE_HLSLI

// Runs the author's Vertex() at `time` on a world-space point; nothing without one.
void SurfaceVertexApply(inout float3 position, inout float3 normal, inout float3 tangent,
                        float3 localPosition, float2 uv, float4 color, float time) {
#ifdef SURFACE_HAS_VERTEX
    g_surfaceTime = time;
    VertexInput v;
    v.position      = position;
    v.normal        = normal;
    v.tangent       = tangent;
    v.localPosition = localPosition;
    v.uv            = uv;
    v.color    = color;
    Vertex(v);
    position = v.position;
    normal   = v.normal;
    tangent  = v.tangent;
#endif
}

// Runs the author's Surface() at `time` on a point.
SurfaceOutput SurfaceEvaluate(float3 worldPos, float3 normal, float4 tangent, float2 uv,
                              float4 color, float3 cameraPos, float4 screenPos, float time) {
    g_surfaceTime = time;
    SurfaceInput input;
    input.worldPos  = worldPos;
    input.normal    = normalize(normal);
    input.tangent   = tangent;
    input.uv        = uv;
    input.color     = color;
    input.viewDir   = normalize(cameraPos - worldPos);
    input.screenPos = screenPos;
    SurfaceOutput surface = DefaultSurfaceOutput();
    Surface(input, surface);
    surface.alpha = saturate(surface.alpha);
    return surface;
}

// The cut-out a masked material's surface makes: the material's AlphaCutoff when the shader
// declares one, else a half.
float SurfaceAlphaCutoff() {
#ifdef SURFACE_HAS_ALPHA_CUTOFF
    return AlphaCutoff;
#else
    return 0.5;
#endif
}

#endif
