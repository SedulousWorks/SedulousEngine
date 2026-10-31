// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "ibl_common.hlsli"

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float3 dir = DirForFace(pc.FaceIndex, uv);
    // Yaw the sample direction by the sky rotation (matters for HDR/cubemap; harmless on the gradient).
    float rot = pc.SkyRotation;
    float cr = cos(rot), sr = sin(rot);
    dir = float3(cr * dir.x + sr * dir.z, dir.y, -sr * dir.x + cr * dir.z);

    float3 sky;
    if (pc.Mode == 2) {                              // Color mode (SkyMode ordinal 2): uniform zenith color
        sky = pc.Zenith;
    } else {                                         // Procedural gradient (also HDR/cubemap fallback)
        sky = (dir.y >= 0.0) ? lerp(pc.Horizon, pc.Zenith, pow(saturate(dir.y), 0.5))
                             : lerp(pc.Horizon, pc.Ground, pow(saturate(-dir.y), 0.8));
        // A soft, broad sun GLOW only (no sharp disc) - the crisp sun is drawn analytically at screen
        // resolution by the sky pass; baking a sub-texel disc into the 256^2 cube would alias to a square.
        float3 sunDir = normalize(-pc.SunDirection);
        float  d      = max(dot(dir, sunDir), 0.0);
        sky += pow(d, 64.0) * max(pc.SunIntensity, 0.0) * 0.3;
    }
    return float4(sky * max(pc.SkyIntensity, 0.0), 1.0);
}
