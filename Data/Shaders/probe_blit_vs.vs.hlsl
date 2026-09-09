// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

struct VSOut { float4 pos : SV_Position; float2 uv : TEXCOORD0; };
VSOut main(uint vid : SV_VertexID) {
    float2 uv = float2((vid << 1) & 2, vid & 2);
    VSOut o; o.uv = uv; o.pos = float4(uv * 2.0 - 1.0, 0.0, 1.0); return o;
}
