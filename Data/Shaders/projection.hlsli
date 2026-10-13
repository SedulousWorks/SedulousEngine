// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#ifndef PROJECTION_HLSLI
#define PROJECTION_HLSLI

// The two projections, for a pass that works in view space: a perspective view's rays fan out
// from the eye, an orthographic one's are parallel along -Z. Each helper takes the view's
// `orthographic` flag (the pass's push constants carry it), so an effect asks once instead of
// growing its own branch. Rebuilding a view position from depth goes through the inverse
// projection and needs none of this (it is right for both).

#include "depth.hlsli"

// How much a view-space x or y shrinks on its way to NDC: by the view depth under perspective,
// not at all under orthographic.
float ProjectionDivide(float3 viewPos, bool orthographic) {
    return orthographic ? 1.0 : max(-viewPos.z, 1e-4);
}

// View space -> NDC xy, the diagonal only (projXY = projection(0,0), (1,1)); a pass subtracts
// the TAA jitter itself (projection::JitterOf: the same NDC shift for both projections).
float2 ViewToNdcXY(float3 viewPos, float2 projXY, bool orthographic) {
    return viewPos.xy * projXY / ProjectionDivide(viewPos, orthographic);
}

// The unit direction from a view-space point towards the viewer: to the eye under perspective,
// straight back along +Z under orthographic.
float3 ViewDirToViewer(float3 viewPos, bool orthographic) {
    return orthographic ? float3(0.0, 0.0, 1.0) : normalize(-viewPos);
}

// Reverse-Z orthographic NDC depth -> view-space distance along the view (the inverse of the
// C++ OrthographicRH z row, linear): d = f - ndc (f - n).
float LinearizeDepthOrthographic(float ndcDepth, float zNear, float zFar) {
    return zFar - ndcDepth * (zFar - zNear);
}

// Whether an inverse projection (row-major, row-vector: ndc -> view) undoes an orthographic one:
// its w column is exactly zero then (w stays 1), and never for a perspective one (w carries the
// depth). For a pass that has the inverse in hand and no room for a flag.
bool InverseIsOrthographic(float4x4 invProj) {
    return invProj[0][3] == 0.0 && invProj[1][3] == 0.0 && invProj[2][3] == 0.0;
}

// A screen-space march's depth along its segment. A perspective ray's 1/depth is linear in screen
// space (perspective-correct interpolation), an orthographic ray's depth itself is: DepthKey turns
// a depth into what interpolates linearly, KeyDepth back.
float DepthKey(float linearDepth, bool orthographic) {
    return orthographic ? linearDepth : 1.0 / max(linearDepth, 1e-4);
}
float KeyDepth(float key, bool orthographic) {
    return orthographic ? key : 1.0 / key;
}

// NDC depth -> view-space distance along the view, for either projection.
float LinearViewDepth(float ndcDepth, float zNear, float zFar, bool orthographic) {
    return orthographic ? LinearizeDepthOrthographic(ndcDepth, zNear, zFar)
                        : LinearizeDepth(ndcDepth, zNear, zFar);
}

#endif // PROJECTION_HLSLI
