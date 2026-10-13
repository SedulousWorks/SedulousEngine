// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The wind sway (wind.hlsli) as a function of its parameters, for a shader whose material declares
// them itself (a surface shader's Vertex()): sin(time * speed + hash(world XZ)) * strength, scaled
// by the vertex's height mask (local y over `height`, squared: roots stay put, tips move).
#ifndef WIND_SWAY_HLSLI
#define WIND_SWAY_HLSLI

float3 WindSwayOf(float3 worldPos, float localY, float time, float strength, float speed,
                  float height) {
    float mask  = saturate(localY / max(height, 1e-3));
    float phase = time * speed + dot(worldPos.xz, float2(0.37, 0.61));
    float sway  = sin(phase) * 0.7 + sin(phase * 2.3 + 1.7) * 0.3;
    return float3(sway, 0.0, 0.6 * sway) * (strength * mask * mask);
}

#endif
