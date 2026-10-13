using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.Shaders.Pipeline;

/// The custom shaders' New Asset creators (File > New, asset_create): a starter .hlsl in the
/// sources folder linked to a new shader asset named like its instance, the name materials find it
/// by. Lit and Unlit Surface Shader start from a Surface() the engine wraps (the lava, a coloured
/// texture); Low-Level Shader from the shortest correct low-level shader: the engine's vertex
/// stage, a properties block, and a pixel stage lit by the engine's lighting library that keeps
/// the forward pass's contract (the DITHER fade, the ALPHA_TEST cut-out, the five GBUFFER
/// targets), ready to be made one's own.
static class ShaderCreators
{
	/// The starter a new lit surface shader's .hlsl holds: the lava of the custom shaders docs.
	public const String cLitSurfaceStarter = """
		// A surface shader: say what the surface is, and the engine lights it, with every light,
		// shadow and reflection probe, in every pass (shadows and picking included).
		// surface: lit

		// The material's parameters: the material page shows these as its rows.
		properties
		{
		    Color   CrackColor = (1.0, 0.35, 0.05, 1.0);
		    float   Speed      = 0.2 [0, 2];
		    float   Glow       = 4.0 [0, 20];
		    Texture Cracks;
		    Sampler MainSampler;
		}

		// Glowing cracks scrolling over dark rock. Give the material a Cracks texture (white = crack).
		void Surface(SurfaceInput input, inout SurfaceOutput surface)
		{
		    float2 uv = input.uv + float2(0.0, Time() * Speed);
		    float crack = Cracks.Sample(MainSampler, uv).r;
		    surface.albedo = lerp(float3(0.08, 0.05, 0.04), CrackColor.rgb, crack);
		    surface.roughness = 0.9;
		    surface.emissive = CrackColor.rgb * crack * Glow;
		}

		// Optional: move the surface's vertices, in world space (its shadow and depth follow), e.g. waves:
		// void Vertex(inout VertexInput v)
		// {
		//     v.position.y += sin(v.position.x * 2.0 + Time()) * 0.1;
		// }

		""";

	/// The starter a new unlit surface shader's .hlsl holds: a colour and a texture, unaffected by
	/// light.
	public const String cUnlitSurfaceStarter = """
		// An unlit surface shader: the surface's colour as it is, unaffected by light (it still casts
		// shadows and can be picked).
		// surface: unlit

		properties
		{
		    Color   BaseColor   = (1, 1, 1, 1);
		    float   AlphaCutoff = 0.5 [0, 1];   // where a masked material cuts out
		    Texture AlbedoMap;
		    Sampler MainSampler;
		}

		void Surface(SurfaceInput input, inout SurfaceOutput surface)
		{
		    float4 c = AlbedoMap.Sample(MainSampler, input.uv) * BaseColor * input.color;
		    surface.albedo = c.rgb;
		    surface.alpha = c.a;
		}

		""";

	/// The starter a new low-level shader's .hlsl holds.
	public const String cStarter = """
		// A low-level shader: the whole pixel stage is yours. This one shades the engine's way, with
		// every light, shadow and reflection probe; change the pixel stage to make it your own.
		// variants(vertex): SKINNED INSTANCED
		// variants(fragment): ALPHA_TEST GBUFFER DITHER
		// preserve-interface (the pixel stage keeps VSOutput's fade input when DITHER is off)

		// The vertex stage: the engine's, under the name VSMain.
		#define FORWARD_VS_ENTRY VSMain
		#include "forward_vs.hlsli"

		// The frame's lights, shadows and image-based light, and what the forward pass writes.
		#include "lighting.hlsli"
		#include "forward_ps.hlsli"

		// The material's parameters: the material page shows these as its rows.
		properties
		{
		    Color   BaseColor   = (1, 1, 1, 1);
		    float   Roughness   = 0.5 [0, 1];
		    float   Metallic    = 0   [0, 1];
		    float   AlphaCutoff = 0.5 [0, 1];   // the ALPHA_TEST threshold
		    Texture AlbedoMap;
		    Sampler MainSampler;
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
		    float  roughness = clamp(Roughness, 0.045, 1.0);
		    float  metallic  = saturate(Metallic);
		    float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedo, metallic);

		    uint lightCount;
		    float3 color = DirectLight(input.clip.xy, input.worldPos, viewDepth, N, V, albedo, roughness,
		                               metallic, F0, lightCount)
		                 + AmbientLight(input.worldPos, N, V, albedo, roughness, metallic, F0, 1.0);

		#ifdef GBUFFER
		    GBufferOutput o;
		    o.color    = float4(color, alpha);
		    o.normal   = OctEncode(normalize(mul(float4(N, 0.0), View).xyz));
		    o.velocity = MotionVector(input.curClip, input.prevClip);
		    o.material = float2(roughness, metallic);
		    o.albedo   = float4(albedo * (1.0 - metallic), 1.0);
		    return o;
		#else
		    return float4(color, alpha);
		#endif
		}

		""";

	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Lit Surface Shader", "Materials", typeof(ShaderAsset),
			new (context) => Create(context, "SurfaceShader", cLitSurfaceStarter)).Under("Shaders"));
		registry.Register(new AssetCreator("Unlit Surface Shader", "Materials", typeof(ShaderAsset),
			new (context) => Create(context, "UnlitShader", cUnlitSurfaceStarter)).Under("Shaders"));
		registry.Register(new AssetCreator("Low-Level Shader", "Materials", typeof(ShaderAsset),
			new (context) => Create(context, "Shader", cStarter)).Under("Shaders"));
	}

	/// `starter` in a new .hlsl under the sources folder, named like the instance, and the shader
	/// asset linking it. Refused without a sources folder.
	private static Instance Create(AssetCreationContext context, StringView baseName, StringView starter)
	{
		let target = context.Target;
		if ((target == null) || context.SourcesRoot.IsEmpty)
			return null;
		let name = target.UniqueInstanceName(context.NameOr(baseName), .. scope .());
		let fileName = scope $"{name}.hlsl";
		if (WriteFile(PathJoin(context.SourcesRoot, fileName, .. scope .()), Span<uint8>((uint8*)starter.Ptr, starter.Length)) case .Err)
			return null;
		let instance = target.CreateInstance(name, typeof(ShaderAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let asset = scope ShaderAsset();
		asset.FileName.Set(fileName);
		// Materials find a shader by its name: the instance's, unique in its group.
		asset.Name.Set(name);
		if (instance.WriteObject(asset) case .Err)
			return null;
		return instance;
	}
}
