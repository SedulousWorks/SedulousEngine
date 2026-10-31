// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Scene-pass MSAA first-sample resolve - fullscreen triangle VS.
// Standard SV_VertexID fullscreen triangle; the PS does the sample-0 loads.
struct VSOut { float4 pos : SV_Position; float2 uv : TEXCOORD0; };
VSOut main(uint vid : SV_VertexID) {
    VSOut o;
    float2 raw = float2((vid << 1) & 2, vid & 2);
    o.pos = float4(raw * 2.0 - 1.0, 0.0, 1.0);
    o.uv  = float2(raw.x, 1.0 - raw.y);
    return o;
}
