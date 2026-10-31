// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The pick vertex stage as a library: pick_ids.vs.hlsl is it under `main`; a surface shader's pick
// program includes it under its own entry (PICK_IDS_VS_ENTRY) with SURFACE_PROGRAM, which runs its
// Vertex() and, under ALPHA_TEST, hands its Surface() everything it reads.
#ifndef PICK_IDS_VS_ENTRY
#define PICK_IDS_VS_ENTRY main
#endif
cbuffer PickView : register(b0, space0) {
    row_major float4x4 ViewProj;   // the cropped world->clip
    float              SceneTime;  // the scene clock (s): the WIND sway, a surface's Time()
    float              _pickPad0;
    float              _pickPad1;
    float              _pickPad2;
    float3             PickCamera; // the camera's position (the instance fade's distance)
    float              _pickPad3;
};
#ifdef WIND
#include "wind.hlsli"
#endif
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
// The forward path's InstanceData and Object block (shared ring buffers).
#ifdef INSTANCED
struct InstanceData { row_major float4x4 World; row_major float4x4 PrevWorld; float4 Tint; };
StructuredBuffer<InstanceData> Instances : register(t0, space1);
#include "instance_fade.hlsli"
#else
#include "object_block.hlsli"
#endif
// Every input pins its location (SPIR-V; the semantics give DXIL the same): without them DXC numbers
// them in order, and a non-instanced skinned variant's joints would take pickOffsets' 5.
struct VSInput {
    [[vk::location(0)]] float3 position : TEXCOORD0;
    [[vk::location(1)]] float3 normal   : TEXCOORD1;
    [[vk::location(2)]] float2 uv       : TEXCOORD2;
    [[vk::location(3)]] float4 color    : TEXCOORD3;
    [[vk::location(4)]] float4 tangent  : TEXCOORD4;
#ifdef INSTANCED
    // Instance-stepped (MeshPickDrawOffsets): x = index into Instances[], y = the bone base,
    // z = the entity's generation, w = the entity's index + 1 (0 for a MultiMesh set, whose id is
    // its InstanceSet's).
    [[vk::location(5)]] uint4  pickOffsets : TEXCOORD5;
#endif
#ifdef SKINNED
    [[vk::location(6)]] uint2  jointsPacked : TEXCOORD6;
    [[vk::location(7)]] float4 weights      : TEXCOORD7;
#endif
};
struct PickVSOut {
    float4 pos : SV_Position;
    nointerpolation uint2 id : TEXCOORD0;
#if defined(SURFACE_PROGRAM) && defined(ALPHA_TEST)
    // A surface shader's cut-out: everything its Surface() reads.
    float3 worldPos  : TEXCOORD1;
    float3 normalWS  : TEXCOORD2;
    float4 tangentWS : TEXCOORD3;
    float2 uv        : TEXCOORD4;
    float4 color     : TEXCOORD5;
#elif defined(ALPHA_TEST)
    float2 uv : TEXCOORD1;
#endif
};
PickVSOut PICK_IDS_VS_ENTRY(VSInput input) {
    PickVSOut o;
#ifdef INSTANCED
    float4x4 world = Instances[input.pickOffsets.x].World;
    uint2 drawId = uint2(input.pickOffsets.w, input.pickOffsets.z); // (index + 1, generation)
    float fadeKeep = InstanceFadeKeep(world[3].xyz, PickCamera, input.pickOffsets.x, true);
#else
    float4x4 world = World;
    uint2 drawId = uint2(PickIndex, PickGeneration);
#endif
    float3 lp = input.position;
#ifdef SURFACE_PROGRAM
    float3 ln = input.normal;
    float3 lt = input.tangent.xyz;
#endif
#ifdef INSTANCED
    lp *= fadeKeep; // a faded-out instance cannot be picked
#endif
#ifdef SKINNED
  #ifdef INSTANCED
    uint boneBase = input.pickOffsets.y;
  #else
    uint boneBase = BoneBase;
  #endif
    uint4 j = uint4(input.jointsPacked.x & 0xFFFFu, input.jointsPacked.x >> 16,
                    input.jointsPacked.y & 0xFFFFu, input.jointsPacked.y >> 16);
  #ifdef SURFACE_PROGRAM
    float4x4 skin = BlendBones(j, input.weights, boneBase);
    lp = mul(float4(lp, 1.0), skin).xyz;
    ln = mul(float4(ln, 0.0), skin).xyz;
    lt = mul(float4(lt, 0.0), skin).xyz;
  #else
    lp = mul(float4(lp, 1.0), BlendBones(j, input.weights, boneBase)).xyz;
  #endif
#endif
    float4 worldPos = mul(float4(lp, 1.0), world);
#ifdef WIND
    worldPos.xyz += WindSway(worldPos.xyz, lp.y, SceneTime);
#endif
#ifdef SURFACE_PROGRAM
    // A surface shader's Vertex() moves what this pass picks, as it does the forward pass's.
  #ifdef INSTANCED
    float4 tint = Instances[input.pickOffsets.x].Tint;
  #else
    float4 tint = Tint;
  #endif
    float3 nWS = mul(float4(ln, 0.0), world).xyz;
    float3 tWS = mul(float4(lt, 0.0), world).xyz;
    float4 color = input.color * tint;
    SurfaceVertexApply(worldPos.xyz, nWS, tWS, lp, input.uv, color, SceneTime);
#endif
    o.pos = mul(worldPos, ViewProj);
#ifdef INSTANCED
    o.id  = (SetPickIndex != 0u) ? uint2(SetPickIndex, SetPickGeneration) : drawId; // a MultiMesh set is one entity
#else
    o.id  = drawId;
#endif
#if defined(SURFACE_PROGRAM) && defined(ALPHA_TEST)
    o.worldPos  = worldPos.xyz;
    o.normalWS  = normalize(nWS);
    o.tangentWS = float4(tWS, input.tangent.w);
    o.uv        = input.uv;
    o.color     = color;
#elif defined(ALPHA_TEST)
    o.uv  = input.uv;
#endif
    return o;
}
