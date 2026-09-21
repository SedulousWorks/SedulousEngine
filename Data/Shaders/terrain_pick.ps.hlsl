// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Terrain GPU-pick PS: the terrain entity's id into the RG32Uint id target (see pick_ids.ps).
struct PickVSOut {
    float4 pos : SV_Position;
    nointerpolation uint2 id : TEXCOORD0;
};

uint2 main(PickVSOut input) : SV_Target0 {
    return input.id;
}
