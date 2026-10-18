// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG layer blur vertex shader: one triangle over the viewport (the layer's content region), its
// texcoord 0..1 across it with the origin top left. No vertex buffer. Resolved via
// ShaderSystem::GetVariant("vg_blur", Vertex).
struct VSOut { float4 Position : SV_Position; float2 TexCoord : TEXCOORD0; };
VSOut main(uint vid : SV_VertexID) {
    VSOut o;
    float2 raw = float2((vid << 1) & 2, vid & 2);
    o.Position = float4(raw * 2.0 - 1.0, 0.0, 1.0);
    o.TexCoord = float2(raw.x, 1.0 - raw.y);
    return o;
}
