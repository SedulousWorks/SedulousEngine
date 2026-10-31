// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)
cbuffer ParticleView : register(b0, space0) {
    float4x4 ViewProj;
    float4x4 View;
    // The projection terms that turn a sampled NDC depth back into view depth (soft particles).
    float    ProjZScale;    // Proj[2][2]
    float    ProjZOffset;   // Proj[3][2]
    float    ProjWScale;    // Proj[2][3]: -1 perspective, 0 orthographic
    float    _particleViewPad0;
};
// The instance (ParticleBillboardInstance) arrives as five float4 attributes, each named for the
// fields it carries; Unpack gives every field its name before anything reads it.
struct VSIn {
    float4 PositionWidth                   : TEXCOORD0;
    float4 HeightRotationModeSoftDistance  : TEXCOORD1;
    float4 Color                           : TEXCOORD2;
    float4 UVRect                          : TEXCOORD3;   // xy uv min, zw uv size
    float4 VelocityStretch                 : TEXCOORD4;
    uint   VertexID                        : SV_VertexID;
};
struct ParticleInstance {
    float3 Position;      // world centre
    float  Width;
    float  Height;
    float  Rotation;      // radians, the camera-facing roll
    float  Mode;          // the orientation mode's ordinal
    float  SoftDistance;  // the soft-particle fade band (0 = off)
    float3 Velocity;      // world velocity
    float  Stretch;       // the stretch scale (0 = plain billboard)
};
ParticleInstance Unpack(VSIn i) {
    ParticleInstance p;
    p.Position     = i.PositionWidth.xyz;
    p.Width        = i.PositionWidth.w;
    p.Height       = i.HeightRotationModeSoftDistance.x;
    p.Rotation     = i.HeightRotationModeSoftDistance.y;
    p.Mode         = i.HeightRotationModeSoftDistance.z;
    p.SoftDistance = i.HeightRotationModeSoftDistance.w;
    p.Velocity     = i.VelocityStretch.xyz;
    p.Stretch      = i.VelocityStretch.w;
    return p;
}
struct VSOut { float4 pos : SV_Position; float2 uv : TEXCOORD0; float4 col : COLOR0; float linZ : TEXCOORD1; float softDist : TEXCOORD2; };

static const float2 CORNERS[6] = {
    float2(-0.5, -0.5), float2(0.5, -0.5), float2(-0.5, 0.5),
    float2(-0.5,  0.5), float2(0.5, -0.5), float2( 0.5, 0.5)
};
static const float2 UVS[6] = {
    float2(0, 1), float2(1, 1), float2(0, 0),
    float2(0, 0), float2(1, 1), float2(1, 0)
};

VSOut main(VSIn i) {
    VSOut o;
    ParticleInstance p = Unpack(i);
    float3 worldPos = p.Position;
    float2 size     = float2(p.Width, p.Height);
    int    mode     = (int)(p.Mode + 0.5);
    float  rot      = p.Rotation;

    float3 camRight = float3(View._m00, View._m10, View._m20);
    float3 camUp    = float3(View._m01, View._m11, View._m21);
    float3 camFwd   = float3(View._m02, View._m12, View._m22);

    float3 right, up;
    if (p.Stretch > 0.0 && dot(p.Velocity, p.Velocity) > 1e-8) {
        // Stretched billboard: length axis follows velocity, width axis perpendicular in view.
        float3 v = p.Velocity;
        float speed = length(v);
        up = v / speed;
        right = normalize(cross(up, camFwd));
        size.y *= (1.0 + speed * p.Stretch);
    } else if (mode == 2) {              // ground-flat (XZ plane, +Y normal) - horizontal billboard
        right = float3(1, 0, 0); up = float3(0, 0, 1);
    } else if (mode == 1) {              // camera-facing about world Y
        right = normalize(float3(camRight.x, 0, camRight.z));
        up    = float3(0, 1, 0);
    } else {                             // full camera-facing, with per-particle roll
        float s = sin(rot), c = cos(rot);
        right = camRight * c + camUp * s;
        up    = camUp * c - camRight * s;
    }

    float2 local = CORNERS[i.VertexID];
    float3 cornerWS = worldPos + right * (local.x * size.x) + up * (local.y * size.y);
    o.pos = mul(float4(cornerWS, 1.0), ViewProj);
    o.uv  = i.UVRect.xy + UVS[i.VertexID] * i.UVRect.zw;
    o.col = i.Color;
    o.linZ = -mul(float4(cornerWS, 1.0), View).z;   // positive view-space depth (soft particles)
    o.softDist = p.SoftDistance;                     // per-system soft-particle fade band (0 = off)
    return o;
}
