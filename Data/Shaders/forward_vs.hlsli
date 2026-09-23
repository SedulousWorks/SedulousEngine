// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#define CASCADE_COUNT 4
cbuffer View : register(b0, space0) {
    row_major float4x4 ViewProj;   // Matrices are row-major; annotate so HLSL reads them right.
    row_major float4x4 View;       // for view-space depth (cluster lookup + CSM cascade select, PS only)
    row_major float4x4 CascadeViewProj[CASCADE_COUNT];   // CSM: world -> each cascade's light clip
    float3 CameraPos; float LightCount;
    uint   LightOffset; int ClusterVpX; int ClusterVpY; float IBLMaxLod;   // IBLMaxLod < 0 -> no IBL (flat ambient)
    uint   ClusterGridX; uint ClusterGridY; uint ClusterSliceCount; uint ClusterTileSize;
    float  ClusterNear;  float ClusterFar;  float ClusterLogScale;  float ClusterLogBias;
    float3 Ambient; float ShadowCascadeCount;          // 0 -> no shadow
    float4 CascadeSplitFar;        // view-space far depth of each cascade (cascade selection)
    float4 CascadeTexelSize;       // world units per shadow texel, per cascade (normal-offset bias)
    float  ShadowNormalBias; float ShadowDepthBias; float CascadeLayerBase; uint LocalShadowBase;
    row_major float4x4 PrevViewProj;   // last frame's world->clip (motion vectors)
    float4 Jitter;                     // xy = this frame's NDC jitter, zw = last frame's (TAA)
    float4 ProbeCenter;                // xyz = reflection-probe center (world), w = probe count (0 = none)
    float4 ProbeBoxMin;                // xyz = probe box min corner,  w = probe cube slice (index into ProbeArray)
    float4 ProbeBoxMax;                // xyz = probe box max corner,  w = probe intensity
    float4 ShadowParams;               // x = CSM far-fade width in WORLD UNITS, y = clip-space Y sign, zw = instance fade start/end (an instanced set's private view slot; 0 = none)
    float4 DebugParams;                // x = semantic debug-view mode (0 = off); yzw spare
    float4 IblParams;                  // x = IBL diffuse intensity, y = IBL specular intensity, z = time (s), w = last frame's time
};
#ifdef WIND
#include "wind.hlsli"
#endif
#ifdef SKINNED
// GPU skinning: per-bone skinning matrices (= inverseBind * worldPose), v * skin (row-vector).
// A per-frame pool shared by all skinned draws; BoneBase (Object cbuffer) selects this draw's run.
// Stored as 4 explicit float4 ROWS (Sedulous-faithful) so the major-ness is unambiguous - DXC's
// row_major modifier is unreliable on a StructuredBuffer matrix element.
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
#ifdef INSTANCED
struct InstanceData { row_major float4x4 World; row_major float4x4 PrevWorld; float4 Tint; };
StructuredBuffer<InstanceData> Instances : register(t0, space1);
#include "instance_fade.hlsli"
#else
cbuffer Object : register(b0, space1) {
    row_major float4x4 World;
    row_major float4x4 PrevWorld;   // last frame's world (motion vectors)
    float4             Tint;
    uint               BoneBase;      // first bone matrix for this draw (skinning); 0 otherwise
    uint               PrevBoneBase;  // last frame's bone base (skinned motion vectors)
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
    // Locations 6/7: skinned draws are always instanced, so dataOffsets (declared above) takes 5 and
    // DXC assigns these sequentially to 6/7. The skin stream's attribute layout matches.
    uint2  jointsPacked : TEXCOORD6;  // 4x u16 bone indices packed into 2x u32
    float4 weights      : TEXCOORD7;  // bone weights (sum 1)
#endif
};
struct VSOutput {
    float4 clip      : SV_Position;
    float3 normalWS  : TEXCOORD0;
    float4 color     : TEXCOORD1;
    float2 uv        : TEXCOORD2;
    float4 tangentWS : TEXCOORD3;   // xyz world tangent, w handedness
    float3 worldPos  : TEXCOORD4;
    float4 curClip   : TEXCOORD5;   // unjittered current clip pos (motion vectors)
    float4 prevClip  : TEXCOORD6;   // unjittered previous clip pos (motion vectors)
};
VSOutput main(VSInput input) {
    VSOutput o;
#ifdef INSTANCED
    float4x4 world     = Instances[input.dataOffsets.x].World;
    float4x4 prevWorld = Instances[input.dataOffsets.x].PrevWorld;
    float4   tint      = Instances[input.dataOffsets.x].Tint;
    // A faded set: Tint.a is the instance's rank and the window rides ShadowParams.zw, so the
    // alpha goes back to one once it has been read (instance_fade.hlsli).
    float    fadeKeep  = InstanceFadeKeep(world[3].xyz, CameraPos, tint.a, ShadowParams.zw);
    if (ShadowParams.w > 0.0) tint.a = 1.0;
#else
    float4x4 world     = World;
    float4x4 prevWorld = PrevWorld;
    float4   tint      = Tint;
#endif
    float3 lp = input.position;
    float3 ln = input.normal;
    float3 lt = input.tangent.xyz;
    float3 lpPrev = input.position;   // previous-frame local position (differs from lp only when skinned)
#ifdef SKINNED
    // Blend the four influencing bones (joint indices packed 4x u16 -> 2x u32) into a skin matrix. The
    // bone base is per-instance (DataOffsets.y) for the instanced path; the device pool holds [cur][prev]
    // per skeleton (DataOffsets.z = prev base, for motion vectors).
  #ifdef INSTANCED
    uint boneBase     = input.dataOffsets.y;
    uint prevBoneBase = input.dataOffsets.z;
  #else
    uint boneBase     = BoneBase;
    uint prevBoneBase = PrevBoneBase;
  #endif
    uint4 j = uint4(input.jointsPacked.x & 0xFFFFu, input.jointsPacked.x >> 16,
                    input.jointsPacked.y & 0xFFFFu, input.jointsPacked.y >> 16);
    float4x4 skin     = BlendBones(j, input.weights, boneBase);
    float4x4 skinPrev = BlendBones(j, input.weights, prevBoneBase);
    lpPrev = mul(float4(input.position, 1.0), skinPrev).xyz;   // deform with LAST frame's pose
    lp = mul(float4(lp, 1.0), skin).xyz;
    ln = mul(float4(ln, 0.0), skin).xyz;
    lt = mul(float4(lt, 0.0), skin).xyz;
#endif
#ifdef INSTANCED
    // A faded out instance collapses to its origin: zero area, so nothing is rasterised. Kept
    // under INSTANCED because a multiply by a literal one still emits an op, and a draw that
    // can never fade should not pay for one per vertex.
    lp *= fadeKeep;
    lpPrev *= fadeKeep;
#endif
    float4 worldPos     = mul(float4(lp, 1.0), world);
    float4 prevWorldPos = mul(float4(lpPrev, 1.0), prevWorld);
#ifdef WIND
    // IblParams.z = this frame's time, .w = last frame's: the previous position sways with it.
    worldPos.xyz     += WindSway(worldPos.xyz, lp.y, IblParams.z);
    prevWorldPos.xyz += WindSway(prevWorldPos.xyz, lpPrev.y, IblParams.w);
#endif
    o.clip      = mul(worldPos, ViewProj);
    o.normalWS  = normalize(mul(float4(ln, 0.0), world).xyz);
    o.color     = input.color * tint;                           // vertex color * per-instance tint
    o.uv        = input.uv;                                     // consume the full vertex layout
    o.tangentWS = float4(mul(float4(lt, 0.0), world).xyz, input.tangent.w);
    o.worldPos  = worldPos.xyz;
    o.curClip   = o.clip;                                        // (jitter is baked into ViewProj; PS unjitters)
    o.prevClip  = mul(prevWorldPos, PrevViewProj);
    return o;
}
