// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG layer composite fragment shader (the Layer draw mode, VGContext::PopLayer): samples the
// offscreen target a layer was drawn into, which already holds PREMULTIPLIED colour in the
// canvas's own blend space (an Encoded canvas's layer is a UNORM target, so its samples are
// encoded values, never decoded), and scales it by the quad's alpha, the layer's opacity. No
// premultiply and no re-encode, unlike vg.ps. Shares VGUniforms (b0) and the vertex stage with
// vg.vs. Resolved via ShaderSystem::GetVariant("vg_layer", Fragment).
cbuffer VGUniforms : register(b0) { float4x4 Projection; float DistanceFieldPixelRange; float DistanceFieldAtlasWidth; float DistanceFieldAtlasHeight; float BlendSpace; };
struct PSInput { float4 Position:SV_Position; float2 TexCoord:TEXCOORD0; float4 Color:COLOR0; float Coverage:COVERAGE; };
Texture2D VGTexture : register(t0);
SamplerState VGSampler : register(s0);
float4 main(PSInput input) : SV_Target {
    return VGTexture.Sample(VGSampler, input.TexCoord) * (input.Color.a * input.Coverage);
}
