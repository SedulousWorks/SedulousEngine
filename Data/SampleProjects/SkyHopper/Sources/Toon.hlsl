// Sky Hopper's toon shading: a low-level shader that lights the world in soft bands, after the
// Shader Gallery's Toon lesson. The engine's vertex stage, lights, shadows and deferred targets;
// its own response to the light: the lit side the albedo, the dark side the albedo in a cool
// shadow tint, the steps between them softened so the cartoon reads as painted rather than cut,
// a soft rim where a surface turns from the eye, and a small highlight on what asks for one.
// Every material of the game is on it (Tools/toon.py), its colour and map carried over from PBR.

// variants(vertex): SKINNED INSTANCED
// variants(fragment): ALPHA_TEST GBUFFER DITHER
// preserve-interface (the pixel stage keeps VSOutput's fade input when DITHER is off)

#define FORWARD_VS_ENTRY VSMain
#include "forward_vs.hlsli"

#include "lighting.hlsli"
#include "forward_ps.hlsli"

properties
{
    Color   BaseColor         = (1, 1, 1, 1);
    Color   ShadowColor       = (0.62, 0.68, 0.92, 1); // the dark side's tint: cool, as a sunny cartoon's
    Color   RimColor          = (1, 1, 1, 1);
    float   Bands             = 2    [1, 6];           // how many steps the light falls into
    float   BandSoftness      = 0.12 [0, 0.5];         // 0 cuts each step hard; 0.5 is a smooth ramp
    float   RimPower          = 4    [0.5, 16];        // how tight the rim is
    float   RimIntensity      = 0.18 [0, 2];
    float   SpecularPower     = 48   [4, 256];         // the highlight's size (larger is smaller)
    float   SpecularIntensity = 0    [0, 2];           // 0: no highlight
    float   AlphaCutoff       = 0.5  [0, 1];           // the ALPHA_TEST threshold
    Texture AlbedoMap;
    Sampler MainSampler;
}

// The light reaching a surface in `Bands` steps, each edge a smoothstep `BandSoftness` wide, so
// the bands keep their shape without the stair of a hard cut.
float SoftBands(float value, float bands, float softness) {
    float b = max(bands, 1.0);
    float x = saturate(value) * b;
    float s = max(softness, 0.001);
    return saturate((floor(x) + smoothstep(0.5 - s, 0.5 + s, frac(x))) / b);
}

// One light: banded between the tinted dark side and the albedo, its shadow a soft step of its
// own (banded with the facing, the shadow map's filtered edge would become a band).
float3 ToonLight(GpuLight light, float3 worldPos, float3 N, float3 V, float3 albedo, float shadow) {
    float atten;
    float3 L = LightDirection(light, worldPos, atten);
    float lit = SoftBands(dot(N, L), Bands, BandSoftness) * smoothstep(0.35, 0.65, shadow);
    float3 tone = lerp(ShadowColor.rgb * albedo, albedo, lit);
    float3 H = normalize(L + V);
    float highlight = smoothstep(0.45, 0.55, pow(saturate(dot(N, H)), SpecularPower)) * lit * SpecularIntensity;
    // Divided by pi as the engine's diffuse is, so a light and the exposure tuned for PBR
    // light toon to the same brightness.
    return (tone + highlight) * light.color * light.intensity * saturate(atten) * (1.0 / 3.14159265);
}

#ifdef GBUFFER
GBufferOutput PSMain(VSOutput input) {
#else
float4 PSMain(VSOutput input) : SV_Target0 {
#endif
#ifdef DITHER
    ScreenDoorFade(input.clip.xy, input.fade);
#endif
    float4 albedoTex = AlbedoMap.Sample(MainSampler, input.uv);
    float3 albedo = input.color.rgb * BaseColor.rgb * albedoTex.rgb;
    float  alpha  = saturate(input.color.a * BaseColor.a * albedoTex.a);
#ifdef ALPHA_TEST
    if (alpha < AlphaCutoff) { discard; }
#endif
    float3 N = normalize(input.normalWS);
    float3 V = normalize(CameraPos - input.worldPos);
    float  viewDepth = -mul(float4(input.worldPos, 1.0), View).z;

    // The scene's fill, in the shadow tint: what the sun does not reach is cool, not black.
    float3 color = Ambient * ShadowColor.rgb * albedo;

    LightList lights = LightsAt(input.clip.xy, viewDepth);
    for (uint i = 0; i < lights.count; ++i) {
        GpuLight L = LightAt(lights, i);
        color += ToonLight(L, input.worldPos, N, V, albedo, ShadowOf(L, input.worldPos, N, viewDepth));
    }

    float rim = pow(1.0 - saturate(dot(N, V)), max(RimPower, 0.01));
    color += RimColor.rgb * rim * RimIntensity;

#ifdef GBUFFER
    GBufferOutput o;
    o.color    = float4(color, alpha);
    o.normal   = OctEncode(normalize(mul(float4(N, 0.0), View).xyz));
    o.velocity = MotionVector(input.curClip, input.prevClip);
    o.material = float2(1.0, 0.0);                          // fully rough, not metal: SSR skips it
    o.albedo   = float4(albedo, 1.0);
    return o;
#else
    return float4(color, alpha);
#endif
}
