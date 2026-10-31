// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "ibl_common.hlsli"

static const float API = 3.14159265359;
float3 PreethamRGB(float cosTheta, float gamma, float thetaSun, float T) {
    cosTheta = max(cosTheta, 0.02);
    float cg = cos(gamma);
    // Perez distribution coefficients (per channel: Y, x, y), linear in turbidity T.
    float3 A = float3( 0.1787*T-1.4630, -0.0193*T-0.2592, -0.0167*T-0.2608);
    float3 B = float3(-0.3554*T+0.4275, -0.0665*T+0.0008, -0.0950*T+0.0092);
    float3 C = float3(-0.0227*T+5.3251, -0.0004*T+0.2125, -0.0079*T+0.2102);
    float3 D = float3( 0.1206*T-2.5771, -0.0641*T-0.8989, -0.0441*T-1.6537);
    float3 E = float3(-0.0670*T+0.3703, -0.0033*T+0.0452, -0.0109*T+0.0529);
    float3 num = (1.0 + A * exp(B / cosTheta)) * (1.0 + C * exp(D * gamma) + E * cg * cg);
    float cts = cos(thetaSun);
    float3 den = (1.0 + A * exp(B))          * (1.0 + C * exp(D * thetaSun) + E * cts * cts);
    float3 F = num / den;
    // Zenith luminance + chromaticity.
    float chi = (4.0/9.0 - T/120.0) * (API - 2.0*thetaSun);
    float Yz = (4.0453*T - 4.9710) * tan(chi) - 0.2155*T + 2.4192;
    float ts = thetaSun, ts2 = ts*ts, ts3 = ts2*ts, T2 = T*T;
    float xz = ( 0.00166*ts3-0.00375*ts2+0.00209*ts)*T2 + (-0.02903*ts3+0.06377*ts2-0.03202*ts+0.00394)*T + ( 0.11693*ts3-0.21196*ts2+0.06052*ts+0.25886);
    float yz = ( 0.00275*ts3-0.00610*ts2+0.00317*ts)*T2 + (-0.04214*ts3+0.08970*ts2-0.04153*ts+0.00516)*T + ( 0.15346*ts3-0.26756*ts2+0.06670*ts+0.26688);
    float Y = Yz * F.x, x = xz * F.y, y = yz * F.z;
    // xyY -> XYZ -> linear sRGB.
    float3 XYZ; XYZ.y = Y; XYZ.x = (x / max(y, 1e-4)) * Y; XYZ.z = ((1.0 - x - y) / max(y, 1e-4)) * Y;
    float3 rgb = float3(dot(XYZ, float3( 3.2404542,-1.5371385,-0.4985314)),
                        dot(XYZ, float3(-0.9692660, 1.8760108, 0.0415560)),
                        dot(XYZ, float3( 0.0556434,-0.2040259, 1.0572252)));
    return max(rgb, 0.0);
}
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float3 dir    = normalize(DirForFace(pc.FaceIndex, uv));
    float3 sunDir = normalize(-pc.Sun.xyz);
    float  T        = clamp(pc.Ground.a, 1.7, 10.0);
    float  thetaSun = acos(clamp(sunDir.y, 0.0, 1.0));
    float  gamma    = acos(clamp(dot(dir, sunDir), -1.0, 1.0));
    float3 sky = (dir.y >= 0.0) ? PreethamRGB(dir.y, gamma, thetaSun, T) * 0.05
                                : pc.Ground.rgb * 0.5;   // below horizon: dim ground tint
    return float4(sky * max(pc.SkyIntensity, 0.0), 1.0);
}
