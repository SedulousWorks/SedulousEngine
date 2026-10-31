// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The per-draw block of a single (non-instanced) object, set 1 binding 0, one declaration for the
// forward, shadow depth and pick vertex stages, which share one ring of MeshObjectData
// (MeshGpuData.bf). Each pass reads the fields it needs by their names: the forward pass all but
// the pick id, the depth pass World, BoneBase (and Tint for a surface's Vertex()), the pick pass
// World, BoneBase and the pick id (and Tint likewise).
cbuffer Object : register(b0, space1) {
    row_major float4x4 World;
    row_major float4x4 PrevWorld;      // last frame's world (motion vectors)
    float4             Tint;
    uint               BoneBase;       // first bone matrix for this draw (skinning); 0 otherwise
    uint               PrevBoneBase;   // last frame's bone base (skinned motion vectors)
    uint               PickIndex;      // the pick pass: the entity's index + 1, 0 = nothing
    uint               PickGeneration; // the pick pass: the entity's generation
    float              Fade;           // the screen-door fade, 0 = solid (forward.ps DITHER)
    uint               _objectPad0;    // scalars: a uint3 here breaks WGSL's 16-byte vec3 alignment
    uint               _objectPad1;
    uint               _objectPad2;
};
