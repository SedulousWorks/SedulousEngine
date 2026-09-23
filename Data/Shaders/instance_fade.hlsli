// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell
//
// INSTANCE FADE: a per instance distance dissolve for instanced sets, which is what vegetation
// is, applied in the forward, shadow depth and pick vertex shaders under INSTANCED.
//
// The set's window, a start and an end in metres with an end at or below nought meaning no
// fade, rides the pass's view block on one private slot per faded set; each instance's RANK,
// its place in the set's random order as (i + 0.5) over the count, rides its tint's alpha. An
// instance whose rank is above the density at ITS OWN distance collapses to its origin, which
// is zero area and so nothing rasterised, after shrinking over the last eighth of its window,
// so a set dissolves instance by instance with no seam between chunks.
//
// The draw count prefix the CPU picks, from the chunk's NEAREST distance, is exactly the ranks
// a per instance test could still keep, so the two agree rather than fight. The density curve
// is the scatter's own DensityAtDistance: one inside the start, a smoothstep to nought at the
// end.

float InstanceFadeKeep(float3 instanceOrigin, float3 cameraPos, float rank, float2 fade) {
    if (fade.y <= 0.0) return 1.0;
    float d = distance(cameraPos, instanceOrigin);
    float t = saturate((d - fade.x) / max(fade.y - fade.x, 1e-3));
    float density = 1.0 - t * t * (3.0 - 2.0 * t);
    return saturate((density - rank) * 8.0);
}
