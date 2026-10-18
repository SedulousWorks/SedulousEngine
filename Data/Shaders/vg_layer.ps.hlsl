// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG layer composite fragment shader (the Layer draw mode, VGContext::PopLayer): samples the
// offscreen target a layer was drawn into, which already holds PREMULTIPLIED colour in the
// canvas's own blend space (an Encoded canvas's layer is a UNORM target, so its samples are
// encoded values, never decoded), and scales it by the quad's alpha, the layer's opacity. No
// premultiply and no re-encode, unlike vg.ps. The layer's colour filters ride Effect, which the
// vertex stage passes through untouched: (1 - saturation, brightness - 1), zeros for a plain
// layer. Saturation mixes towards the colour's luma (Rec. 709 weights, as CSS's grayscale()
// and saturate() use), brightness scales it; both are linear in the colour, so they apply to the
// premultiplied sample as they would to its colour. Shares VGUniforms (b0) and the vertex stage
// with vg.vs. Resolved via ShaderSystem::GetVariant("vg_layer", Fragment).
cbuffer VGUniforms : register(b0) { float4x4 Projection; float DistanceFieldPixelRange; float DistanceFieldAtlasWidth; float DistanceFieldAtlasHeight; float BlendSpace; };
struct PSInput { float4 Position:SV_Position; float2 TexCoord:TEXCOORD0; float4 Color:COLOR0; float Coverage:COVERAGE; float2 Effect:EFFECT; };
Texture2D VGTexture : register(t0);
SamplerState VGSampler : register(s0);
float4 main(PSInput input) : SV_Target {
    float4 c = VGTexture.Sample(VGSampler, input.TexCoord);
    const float saturation = 1.0 - input.Effect.x;
    const float brightness = 1.0 + input.Effect.y;
    const float luma = dot(c.rgb, float3(0.2126, 0.7152, 0.0722));
    // Kept within 0 and the alpha: a premultiplied colour past it would be one past 1, and
    // saturation above 1 pushes a channel the colour lacks below 0.
    c.rgb = clamp(lerp(float3(luma, luma, luma), c.rgb, saturation) * brightness, 0.0, c.aaa);
    return c * (input.Color.a * input.Coverage);
}
