// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

struct VSOut { float4 pos : SV_Position; float2 ndc : TEXCOORD0; };
VSOut main(uint vid : SV_VertexID) {
    float2 ndc = float2((vid << 1) & 2, vid & 2) * 2.0 - 1.0;
    VSOut o;
    o.pos = float4(ndc, 0.0, 1.0);
    o.ndc = ndc;
    return o;
}
