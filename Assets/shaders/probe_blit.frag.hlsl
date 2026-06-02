// Probe Face Blit Fragment Shader
// Copies a rendered probe face to a cubemap layer with horizontal flip.
// CreateLookAt (right-handed) produces horizontally mirrored cubemap faces
// relative to the CubeUVToDirection convention. Sampling with 1-uv.x corrects this.
// Use with fullscreen.vert.hlsl.

Texture2D<float4> SourceFace : register(t0);
SamplerState LinearSampler : register(s0);

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target0
{
    // Horizontal flip to correct CreateLookAt right-handed mirroring
    return SourceFace.SampleLevel(LinearSampler, float2(1.0 - uv.x, uv.y), 0);
}
