// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell
//
// WIND: a vertex sway for vegetation cards and tufts, included by the forward, shadow depth and
// pick vertex shaders under the WIND variant, which each stage declares in its variants line.
// The sway is a world space offset, sin(time * Speed + hash(world XZ)) * Strength scaled by the
// vertex's height mask (local y over Height, squared: the roots stay put and the tips move). The
// parameters are the effect's own: the block below becomes `ConstantBuffer<WindEffect> Wind :
// register(b1, space2)`, read as `Wind.Strength`, and a material whose shader declares WIND
// carries them as its Wind group, which the material system binds at that binding whatever the
// material's own layout is. The renderer selects this variant only for a material whose gate
// (Strength) is above nought, so every other material is byte identical to what it was. The same
// offset applies to the previous frame's position at the previous time, so the motion vectors
// follow the sway.

effect Wind : WIND
{
    float Strength = 0 [0, 2] (gate);   // metres of sway at a full height mask (nought = off)
    float Speed = 1 [0, 20];            // radians per second
    float Height = 1 [0.01, 100];       // the local y at which the sway reaches full strength
}

#include "wind_sway.hlsli"

float3 WindSway(float3 worldPos, float localY, float time) {
    return WindSwayOf(worldPos, localY, time, Wind.Strength, Wind.Speed, Wind.Height);
}
