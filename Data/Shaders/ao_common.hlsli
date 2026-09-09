// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Octahedral decode -> view-space normal (matches the forward's OctEncode).
float3 OctDecode(float2 e) {
    float3 n = float3(e.xy, 1.0 - abs(e.x) - abs(e.y));
    float  t = saturate(-n.z);
    n.x += n.x >= 0.0 ? -t : t;
    n.y += n.y >= 0.0 ? -t : t;
    return normalize(n);
}
