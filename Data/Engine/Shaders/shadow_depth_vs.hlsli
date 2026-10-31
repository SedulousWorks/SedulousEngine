// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The depth vertex stage (the camera depth prepass, the cascades, the local-light atlas) as a
// library: shadow_depth.vs.hlsl is it under `main`; a surface shader's depth program includes it
// under its own entry (SHADOW_DEPTH_VS_ENTRY) with SURFACE_PROGRAM, which runs its Vertex() and,
// under ALPHA_TEST, hands its Surface() everything it reads.
#ifndef SHADOW_DEPTH_VS_ENTRY
#define SHADOW_DEPTH_VS_ENTRY main
#endif
cbuffer ShadowView : register(b0, space0) {
    row_major float4x4 LightViewProj;
    float3             ShadowCamera; // the CAMERA's position (the fade is by camera distance, not the light's)
    uint               ShadowFadeFromCamera; // 1: the pass couples to a camera, so a faded set fades
    float              SceneTime;    // the scene clock (s): the WIND sway, a surface's Time()
    float              _shadowPad0;
    float              _shadowPad1;
    float              _shadowPad2;
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
// The forward path's InstanceData and Object block (shared ring buffers): the depth pass reads fewer
// of their fields, declared in full so the strides and offsets are the forward's.
#ifdef INSTANCED
struct InstanceData { row_major float4x4 World; row_major float4x4 PrevWorld; float4 Tint; };
StructuredBuffer<InstanceData> Instances : register(t0, space1);
#include "instance_fade.hlsli"
#else
#include "object_block.hlsli"
#endif
// Every input pins its location (SPIR-V; the semantics give DXIL the same): without them DXC numbers
// them in order, and a non-instanced skinned variant's joints would take drawOffsets' 5.
struct VSInput {
    [[vk::location(0)]] float3 position : TEXCOORD0;
    [[vk::location(1)]] float3 normal   : TEXCOORD1;
    [[vk::location(2)]] float2 uv       : TEXCOORD2;
    [[vk::location(3)]] float4 color    : TEXCOORD3;
    [[vk::location(4)]] float4 tangent  : TEXCOORD4;   // xyz = tangent, w = TBN handedness (+-1)
#ifdef INSTANCED
    // Instance-stepped (MeshDrawOffsets, the forward pass's): x = index into Instances[],
    // y = the bone base, z = last frame's bone base, w = the draw's fade, a float by its bits (read
    // with asfloat). This pass reads x and y.
    [[vk::location(5)]] uint4  drawOffsets : TEXCOORD5;
#endif
#ifdef SKINNED
    [[vk::location(6)]] uint2  jointsPacked : TEXCOORD6;
    [[vk::location(7)]] float4 weights      : TEXCOORD7;
#endif
};
// ALPHA_TEST (masked casters): pass UV so the fragment can sample the cutout alpha (a surface
// shader's program: everything its Surface() reads, SurfaceVSOut). Otherwise the depth pass is
// vertex-only (no fragment) and outputs just clip position.
#if defined(SURFACE_PROGRAM) && defined(ALPHA_TEST)
SurfaceVSOut SHADOW_DEPTH_VS_ENTRY(VSInput input) {
    SurfaceVSOut o;
#elif defined(ALPHA_TEST)
struct ShadowVSOut { float4 pos : SV_Position; float2 uv : TEXCOORD0; };
ShadowVSOut SHADOW_DEPTH_VS_ENTRY(VSInput input) {
    ShadowVSOut o;
#else
float4 SHADOW_DEPTH_VS_ENTRY(VSInput input) : SV_Position {
#endif
#ifdef INSTANCED
    float4x4 world = Instances[input.drawOffsets.x].World;
    float fadeKeep = InstanceFadeKeep(world[3].xyz, ShadowCamera, input.drawOffsets.x,
                                      ShadowFadeFromCamera != 0u);
#else
    float4x4 world = World;
#endif
    float3 lp = input.position;
#ifdef SURFACE_PROGRAM
    float3 ln = input.normal;
    float3 lt = input.tangent.xyz;
#endif
#ifdef INSTANCED
    lp *= fadeKeep; // a faded-out instance casts nothing
#endif
#ifdef SKINNED
  #ifdef INSTANCED
    uint boneBase = input.drawOffsets.y;
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
    // A surface shader's Vertex() moves what this pass draws, as it does the forward pass's.
  #ifdef INSTANCED
    float4 tint = Instances[input.drawOffsets.x].Tint;
  #else
    float4 tint = Tint;
  #endif
    float3 nWS = mul(float4(ln, 0.0), world).xyz;
    float3 tWS = mul(float4(lt, 0.0), world).xyz;
    float4 color = input.color * tint;
    SurfaceVertexApply(worldPos.xyz, nWS, tWS, lp, input.uv, color, SceneTime);
#endif
#if defined(SURFACE_PROGRAM) && defined(ALPHA_TEST)
    o.pos       = mul(worldPos, LightViewProj);
    o.worldPos  = worldPos.xyz;
    o.normalWS  = normalize(nWS);
    o.tangentWS = float4(tWS, input.tangent.w);
    o.uv        = input.uv;
    o.color     = color;
    return o;
#elif defined(ALPHA_TEST)
    o.pos = mul(worldPos, LightViewProj);
    o.uv  = input.uv;
    return o;
#else
    return mul(worldPos, LightViewProj);
#endif
}
