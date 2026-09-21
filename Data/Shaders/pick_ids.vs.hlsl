// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GPU picking VS: the depth-only caster path (shadow_depth.vs's layouts, bindings and skinning)
// that also carries the draw's entity id to the fragment. The pass renders with a CROPPED camera
// projection into a rect-sized RG32Uint target (PickSystem); the id is (entity index + 1,
// generation) - 0 = nothing. Sources, by draw kind:
//   - single object:   cbuffer Object's PickIndex/PickGeneration (the pads of the forward layout);
//   - instanced run:   the instance-stepped dataOffsets (.w = index + 1, .z = generation - the
//                      pick pass fills its own ramp, so these never collide with the forward's);
//   - MultiMesh set:   cbuffer PickView's SetPickId (one entity for the whole set; its instance
//                      buffer is persistent and its ramp shared, so the id rides the view slot).
// variants: SKINNED INSTANCED ALPHA_TEST
cbuffer PickView : register(b0, space0) {
    row_major float4x4 ViewProj;   // the cropped world->clip
    uint2              SetPickId;  // x != 0: every draw in this group is this entity
    uint2              _pvPad;
};
#ifdef SKINNED
struct BoneMatrix { float4 Row0, Row1, Row2, Row3; };
StructuredBuffer<BoneMatrix> BoneMatrices : register(t4, space0);
float4x4 BlendBones(uint4 j, float4 w, uint base) {
    BoneMatrix b0 = BoneMatrices[base + j.x];
    BoneMatrix b1 = BoneMatrices[base + j.y];
    BoneMatrix b2 = BoneMatrices[base + j.z];
    BoneMatrix b3 = BoneMatrices[base + j.w];
    return float4x4(b0.Row0 * w.x + b1.Row0 * w.y + b2.Row0 * w.z + b3.Row0 * w.w,
                    b0.Row1 * w.x + b1.Row1 * w.y + b2.Row1 * w.z + b3.Row1 * w.w,
                    b0.Row2 * w.x + b1.Row2 * w.y + b2.Row2 * w.z + b3.Row2 * w.w,
                    b0.Row3 * w.x + b1.Row3 * w.y + b2.Row3 * w.z + b3.Row3 * w.w);
}
#endif
// Layouts mirror the forward path's Object/InstanceData exactly (shared ring buffers).
#ifdef INSTANCED
struct InstanceData { row_major float4x4 World; row_major float4x4 PrevWorld; float4 Tint; };
StructuredBuffer<InstanceData> Instances : register(t0, space1);
#else
cbuffer Object : register(b0, space1) {
    row_major float4x4 World;
    row_major float4x4 PrevWorld;
    float4             Tint;
    uint               BoneBase;
    uint               PrevBoneBase;
    uint               PickIndex;       // entity index + 1
    uint               PickGeneration;
};
#endif
struct VSInput {
    float3 position : TEXCOORD0;
    float3 normal   : TEXCOORD1;
    float2 uv       : TEXCOORD2;
    float4 color    : TEXCOORD3;
    float4 tangent  : TEXCOORD4;
#ifdef INSTANCED
    uint4  dataOffsets : TEXCOORD5;   // .x = instance, .y = bone base, .z = generation, .w = index + 1
#endif
#ifdef SKINNED
    uint2  jointsPacked : TEXCOORD6;
    float4 weights      : TEXCOORD7;
#endif
};
struct PickVSOut {
    float4 pos : SV_Position;
    nointerpolation uint2 id : TEXCOORD0;
#ifdef ALPHA_TEST
    float2 uv : TEXCOORD1;
#endif
};
PickVSOut main(VSInput input) {
    PickVSOut o;
#ifdef INSTANCED
    float4x4 world = Instances[input.dataOffsets.x].World;
    uint2 drawId = uint2(input.dataOffsets.w, input.dataOffsets.z);
#else
    float4x4 world = World;
    uint2 drawId = uint2(PickIndex, PickGeneration);
#endif
    float3 lp = input.position;
#ifdef SKINNED
  #ifdef INSTANCED
    uint boneBase = input.dataOffsets.y;
  #else
    uint boneBase = BoneBase;
  #endif
    uint4 j = uint4(input.jointsPacked.x & 0xFFFFu, input.jointsPacked.x >> 16,
                    input.jointsPacked.y & 0xFFFFu, input.jointsPacked.y >> 16);
    lp = mul(float4(lp, 1.0), BlendBones(j, input.weights, boneBase)).xyz;
#endif
    float4 worldPos = mul(float4(lp, 1.0), world);
    o.pos = mul(worldPos, ViewProj);
    o.id  = (SetPickId.x != 0u) ? SetPickId : drawId;
#ifdef ALPHA_TEST
    o.uv  = input.uv;
#endif
    return o;
}
