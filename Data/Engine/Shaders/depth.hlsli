// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The engine's depth convention, shader side: REVERSE-Z. The near plane is NDC depth 1, the far
// plane 0, a cleared (background) pixel reads 0, and the NEARER surface is the LARGER value.
// The twin of core::projection (C++) and rhi::depth (compare functions, clears, bias signs) -
// keep the three in step. A shader that reconstructs position through an inverse projection
// matrix (InvProj / InvViewProj) is convention-free and needs none of this; one that tests for
// background, walks depths, biases a compare or linearizes explicitly names these.
#ifndef DEPTH_HLSLI
#define DEPTH_HLSLI

#define DEPTH_REVERSE_Z 1
static const float kDepthNear = 1.0;   // what the near plane maps to
static const float kDepthFar  = 0.0;   // what the far plane maps to = the clear value

// Nothing was drawn here (the depth is at, or past, the far plane).
bool IsBackgroundDepth(float depth) { return depth <= kDepthFar; }
// The larger of two NDC depths is the nearer surface.
bool IsNearerDepth(float depth, float than) { return depth > than; }
// A depth NEARER than every real surface, for "closest in a neighborhood" searches: start here
// and keep the larger.
float FarthestDepth() { return kDepthFar; }
float NearerOf(float a, float b) { return max(a, b); }

// Shift an NDC depth TOWARD the viewer / light by `bias` NDC units (a receiver compared against a
// shadow map, a debug line pulled in front of the surface it traces): larger = nearer.
float BiasTowardViewer(float depth, float bias) { return depth + bias; }
// The same on a clip-space position (before the divide): z += bias * w.
float4 BiasClipTowardViewer(float4 clip, float bias) { clip.z += bias * clip.w; return clip; }

// Reverse-Z perspective NDC depth -> positive view-space distance (the inverse of the C++
// PerspectiveFovRH z row): d = n f / (ndc (f - n) + n). ndc 1 -> n, ndc 0 -> f.
float LinearizeDepth(float ndcDepth, float zNear, float zFar) {
    return (zNear * zFar) / max(ndcDepth * (zFar - zNear) + zNear, 1e-12);
}

#endif // DEPTH_HLSLI
