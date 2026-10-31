// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell
//
// INSTANCE FADE: a per instance distance dissolve for instanced sets, which is what vegetation
// is, applied in the forward, shadow depth and pick vertex shaders under INSTANCED.
//
// The draw's InstanceSet block (below; MeshInstanceSetData) carries the set's window, a start and
// an end in metres with an end at or below nought meaning no fade, and its instance count; each
// instance's RANK is its place in the set's random order, (index + 0.5) over the count. An
// instance whose rank is above the density at ITS OWN distance collapses to its origin, which
// is zero area and so nothing rasterised, after shrinking over the last eighth of its window,
// so a set dissolves instance by instance with no seam between chunks.
//
// The draw count prefix the CPU picks, from the chunk's NEAREST distance, is exactly the ranks
// a per instance test could still keep, so the two agree rather than fight. The density curve
// is the scatter's own DensityAtDistance: one inside the start, a smoothstep to nought at the
// end.

cbuffer InstanceSet : register(b1, space1) {
    float FadeStart;          // metres from the camera where the set starts to thin
    float FadeEnd;            // where none is left; <= 0: the set does not fade
    uint  InstanceCount;      // the whole list's count (a faded set draws a prefix of it)
    uint  _setPad0;
    uint  SetPickIndex;       // the pick pass: the entity the whole set picks as (index + 1), 0 = each its own
    uint  SetPickGeneration;
    uint  _setPad1;
    uint  _setPad2;
};

// How much of instance `index` (at `instanceOrigin`) is kept, seen from `cameraPos`: 1 whole,
// 0 collapsed. `fade` false (a pass with no camera to measure from) keeps every instance.
float InstanceFadeKeep(float3 instanceOrigin, float3 cameraPos, uint index, bool fade) {
    if (!fade || FadeEnd <= 0.0) return 1.0;
    float rank = (float(index) + 0.5) / float(max(InstanceCount, 1u));
    float d = distance(cameraPos, instanceOrigin);
    float t = saturate((d - FadeStart) / max(FadeEnd - FadeStart, 1e-3));
    float density = 1.0 - t * t * (3.0 - 2.0 * t);
    return saturate((density - rank) * 8.0);
}
