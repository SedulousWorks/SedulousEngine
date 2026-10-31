// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// A surface shader's depth program (the camera depth prepass, the cascades, the local-light
// atlas), after its text: the engine's depth vertex stage with the author's Vertex() in it, as
// VSMain, and under ALPHA_TEST a pixel stage, PSMain, cutting out where Surface()'s alpha is below
// the material's cutoff. An opaque draw runs the vertex stage alone.
#ifndef SURFACE_DEPTH_HLSLI
#define SURFACE_DEPTH_HLSLI

#define SHADOW_DEPTH_VS_ENTRY VSMain
#include "shadow_depth_vs.hlsli"

#ifdef ALPHA_TEST
void PSMain(SurfaceVSOut input) {
    SurfaceOutput s = SurfaceEvaluate(input.worldPos, input.normalWS, input.tangentWS, input.uv,
                                      input.color, ShadowCamera.xyz, input.pos, ShadowWind.x);
    if (s.alpha < SurfaceAlphaCutoff()) { discard; }
}
#else
void PSMain() {}   // never drawn: an opaque depth draw has no pixel stage
#endif

#endif
