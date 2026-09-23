// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// variants: SKINNED INSTANCED ALPHA_TEST WIND
cbuffer ShadowView : register(b0, space0) {
    row_major float4x4 LightViewProj;
    float4             ShadowWind;   // x = time (s) for the WIND sway, y/z = the instance fade start/end (a faded set's private slot; 0 = none)
    float4             ShadowCamera; // xyz = the CAMERA's position: the fade is by camera distance, not the light's
};
#ifdef WIND
#include "wind.hlsli"
#endif
#ifdef SKINNED
// Same skinning pool as the forward path (set-0 t4 SRV); skinned casters deform their shadow too.
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
// Layouts mirror the forward path's Object/InstanceData exactly (shared C++ ring buffers) - the extra
// PrevWorld/PrevBoneBase fields keep the strides/offsets aligned even though the depth pass ignores them.
#ifdef INSTANCED
struct InstanceData { row_major float4x4 World; row_major float4x4 PrevWorld; float4 Tint; };
StructuredBuffer<InstanceData> Instances : register(t0, space1);
#include "instance_fade.hlsli"
#else
cbuffer Object : register(b0, space1) {
    row_major float4x4 World;
    row_major float4x4 PrevWorld;
    float4             Tint;
    uint               BoneBase;
    uint               PrevBoneBase;
    uint2              _objPad;
};
#endif
struct VSInput {
    float3 position : TEXCOORD0;
    float3 normal   : TEXCOORD1;
    float2 uv       : TEXCOORD2;
    float4 color    : TEXCOORD3;
    float4 tangent  : TEXCOORD4;   // xyz = tangent, w = TBN handedness (+-1)
#ifdef INSTANCED
    uint4  dataOffsets : TEXCOORD5;   // .x = index into Instances[] (instance-stepped)
#endif
#ifdef SKINNED
    uint2  jointsPacked : TEXCOORD6;  // locations 6/7 (dataOffsets took 5; skinned is always instanced)
    float4 weights      : TEXCOORD7;
#endif
};
// ALPHA_TEST (masked casters): pass UV so the fragment can sample the cutout alpha. Otherwise the
// depth pass is vertex-only (no fragment) and outputs just clip position.
#ifdef ALPHA_TEST
struct ShadowVSOut { float4 pos : SV_Position; float2 uv : TEXCOORD0; };
ShadowVSOut main(VSInput input) {
    ShadowVSOut o;
#else
float4 main(VSInput input) : SV_Position {
#endif
#ifdef INSTANCED
    float4x4 world = Instances[input.dataOffsets.x].World;
    float fadeKeep = InstanceFadeKeep(world[3].xyz, ShadowCamera.xyz,
                                      Instances[input.dataOffsets.x].Tint.a, ShadowWind.yz);
#else
    float4x4 world = World;
#endif
    float3 lp = input.position;
#ifdef INSTANCED
    lp *= fadeKeep; // a faded out instance casts nothing
#endif
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
#ifdef WIND
    worldPos.xyz += WindSway(worldPos.xyz, lp.y, ShadowWind.x);
#endif
#ifdef ALPHA_TEST
    o.pos = mul(worldPos, LightViewProj);
    o.uv  = input.uv;
    return o;
#else
    return mul(worldPos, LightViewProj);
#endif
}
