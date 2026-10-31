// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// A surface shader's pick program (the editor's click on a mesh), after its text: the engine's
// pick vertex stage with the author's Vertex() in it, as VSMain, and the id-writing pixel stage,
// PSMain, which under ALPHA_TEST cuts out where Surface()'s alpha is below the material's cutoff
// (a hole in a leaf is not the leaf).
#ifndef SURFACE_PICK_HLSLI
#define SURFACE_PICK_HLSLI

#define PICK_IDS_VS_ENTRY VSMain
#include "pick_ids_vs.hlsli"

uint2 PSMain(PickVSOut input) : SV_Target0 {
#ifdef ALPHA_TEST
    SurfaceOutput s = SurfaceEvaluate(input.worldPos, input.normalWS, input.tangentWS, input.uv,
                                      input.color, PickCamera.xyz, input.pos, WindTime);
    if (s.alpha < SurfaceAlphaCutoff()) { discard; }
#endif
    return input.id;
}

#endif
