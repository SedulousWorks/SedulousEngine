// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// variants: GBUFFER
cbuffer View : register(b0, space0) {        // shared with the VS (same layout)
    row_major float4x4 ViewProj;
    row_major float4x4 View;
    row_major float4x4 CascadeViewProj[4];
    float3 CameraPos; float LightCount;
    uint   LightOffset; int ClusterVpX; int ClusterVpY; float IBLMaxLod;
    uint   ClusterGridX; uint ClusterGridY; uint ClusterSliceCount; uint ClusterTileSize;
    float  ClusterNear;  float ClusterFar;  float ClusterLogScale;  float ClusterLogBias;
    float3 Ambient; float ShadowCascadeCount;
    float4 CascadeSplitFar;
    float4 CascadeTexelSize;
    float  ShadowNormalBias; float ShadowDepthBias; float CascadeLayerBase; uint LocalShadowBase;
    row_major float4x4 PrevViewProj;
    float4 Jitter;
    float4 ProbeCenter;
    float4 ProbeBoxMin;
    float4 ProbeBoxMax;
    float4 ShadowParams;
};

cbuffer Material : register(b0, space2) {
    float4 BaseColor;
};
Texture2D    AlbedoMap   : register(t0, space2);
SamplerState MainSampler : register(s0, space2);

struct PSInput {
    float4 pos       : SV_Position;
    float3 normalWS  : TEXCOORD0;
    float4 color     : TEXCOORD1;
    float2 uv        : TEXCOORD2;
    float4 tangentWS : TEXCOORD3;   // xyz world tangent, w handedness
    float3 worldPos  : TEXCOORD4;
    float4 curClip   : TEXCOORD5;
    float4 prevClip  : TEXCOORD6;
};

float2 OctEncode(float3 n) {
    n /= (abs(n.x) + abs(n.y) + abs(n.z));
    float2 e = n.xy;
    if (n.z < 0.0) { e = (1.0 - abs(float2(e.y, e.x))) * float2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0); }
    return e;
}

#ifdef GBUFFER
struct PSOutput {
    float4 color    : SV_Target0;
    float2 normal   : SV_Target1;
    float2 velocity : SV_Target2;
    float2 material : SV_Target3;
};
PSOutput main(PSInput input) {
#else
float4 main(PSInput input) : SV_Target0 {
#endif
    float4 albedoTex = AlbedoMap.Sample(MainSampler, input.uv);
    float4 c = input.color * BaseColor * albedoTex;
#ifdef GBUFFER
    float2 curNDC  = input.curClip.xy  / input.curClip.w  + Jitter.xy;
    float2 prevNDC = input.prevClip.xy / input.prevClip.w + Jitter.zw;
    PSOutput o;
    o.color    = c;
    o.normal   = OctEncode(normalize(mul(float4(normalize(input.normalWS), 0.0), View).xyz));
    o.velocity = (curNDC - prevNDC) * float2(0.5, -0.5);
    o.material = float2(1.0, 0.0);   // fully rough, non-metallic: SSR/IBL-adjacent passes skip it
    return o;
#else
    return c;
#endif
}
