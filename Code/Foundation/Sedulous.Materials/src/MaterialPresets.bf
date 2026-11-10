using System;
using Sedulous.Core;
using Sedulous.Shaders;

namespace Sedulous.Materials;

/// The material shapes the importers build, so an imported model does not depend on
/// whichever importer happened to declare its properties.
static class MaterialPresets
{
	/// The standard physically based material: the three factors, the five maps, and one
	/// sampler, IN THE ORDER the forward pass's bind group contract expects.
	///
	/// An unset map is not an error: the renderer substitutes a neutral texture, which is
	/// what lets an importer assign only the maps its source file actually had.
	///
	/// THE CALLER OWNS what comes back.
	public static Material CreatePbr(StringView name, Float4 baseColor = .(1, 1, 1, 1),
		float metallic = 0.0f, float roughness = 0.5f, StringView shaderName = "forward")
	{
		let builder = scope MaterialBuilder(name);
		return builder
			..Shader(shaderName)
			..VertexLayout(.Mesh)
			..Color("BaseColor", baseColor)
			..Float("Metallic", metallic)
			..Float("Roughness", roughness)
			// Offsets 24 and 60 are padding (forward.ps.hlsl's `_materialPad*`): the cbuffer packs
			// EmissiveColor at 32 and stays sixty four bytes. The wind, which once lived there,
			// is an effect with a buffer of its own (the material's Wind group,
			// MaterialBuilder.Effect).
			// Black means none: the emissive map multiplies through this, times the intensity
			// in w (a glow above white).
			..ColorHdr("EmissiveColor", .(0, 0, 0, 1))
			..Float("OcclusionStrength", 1.0f)
			..Float("NormalScale", 1.0f)
			..Float("AlphaCutoff", 0.5f)
			..Texture("AlbedoMap")
			..Texture("NormalMap")
			..Texture("MetallicRoughnessMap")
			..Texture("OcclusionMap")
			..Texture("EmissiveMap")
			..Sampler("MainSampler")
			.Build();
	}

	/// Albedo times a base colour, with no lighting.
	///
	/// The SAME vertex path as the lit one, so an unlit object still casts shadows and
	/// still moves through the post stack normally.
	///
	/// THE CALLER OWNS what comes back.
	public static Material CreateUnlit(StringView name, Float4 baseColor = .(1, 1, 1, 1),
		StringView shaderName = "unlit")
	{
		let builder = scope MaterialBuilder(name);
		return builder
			..Shader(shaderName)
			..VertexLayout(.Mesh)
			..Color("BaseColor", baseColor)
			..Texture("AlbedoMap")
			..Sampler("MainSampler")
			.Build();
	}

	/// The standard PHONG material (the "phong" builtin shader): what a
	/// model authored with Phong or Lambert is made of. Each light shaded Blinn-Phong: the diffuse
	/// (BaseColor x AlbedoMap) by N.L, the specular (SpecularColor x SpecularMap, black: none) as a
	/// highlight as tight as Shininess, its exponent; the scene's diffuse ambient; the emission added.
	/// Its colour, map, emission, normal map and cutoff take the names PBR and Unlit give them, so a
	/// material moved between built-ins keeps them. Same vertex path as forward, so it casts shadows
	/// and moves through the post stack normally. The order lays the cbuffer out in 64 bytes, as
	/// phong.ps.hlsl declares it.
	///
	/// THE CALLER OWNS what comes back.
	public static Material CreatePhong(StringView name, Float4 baseColor = .(1, 1, 1, 1),
		Float4 specularColor = .(0, 0, 0, 1), float shininess = 20.0f, StringView shaderName = "phong")
	{
		let builder = scope MaterialBuilder(name);
		return builder
			..Shader(shaderName)
			..VertexLayout(.Mesh)
			..Color("BaseColor", baseColor)
			..Color("SpecularColor", specularColor)
			// Black = none; rgb x EmissiveMap, times the intensity in w (glow above white).
			..ColorHdr("EmissiveColor", .(0, 0, 0, 1))
			..Float("Shininess", shininess)
			..Float("NormalScale", 1.0f)
			..Float("AlphaCutoff", 0.5f)
			..Texture("AlbedoMap")
			..Texture("SpecularMap")
			..Texture("NormalMap")
			..Texture("EmissiveMap")
			..Sampler("MainSampler")
			.Build();
	}

	/// The builtin shaders a material may be drawn with, and how each is known: by its shader's
	/// name (what a material source stores), a short name (what an agent types) and a label (what
	/// the editor shows), in BuiltinShading's order. The one list every place that offers or
	/// recognises a builtin reads.
	public const int cBuiltinShadingCount = 3;
	public static readonly BuiltinShadingInfo[cBuiltinShadingCount] BuiltinShadings = .(
		.(.Pbr, "forward", "pbr", "PBR", cBuiltinVertexVariants),
		.(.Unlit, "unlit", "unlit", "Unlit", cBuiltinVertexVariants),
		.(.Phong, "phong", "phong", "Phong", cBuiltinVertexVariants));

	/// What every builtin's vertex stage declares (its `// variants` line, which the tests pin
	/// against the shader files).
	public const ShaderFlags cBuiltinVertexVariants = .Skinned | .Instanced | .Wind;

	public static BuiltinShadingInfo BuiltinShadingOf(BuiltinShading shading) => BuiltinShadings[(int)shading];

	/// The builtin whose shader is `shaderName`, or null (a custom shader's name).
	public static BuiltinShadingInfo? FindBuiltinShadingByShader(StringView shaderName)
	{
		for (let info in BuiltinShadings)
		{
			if (info.ShaderName == shaderName)
				return info;
		}
		return null;
	}

	/// The builtin an agent names ("pbr", "unlit", "phong"), or null.
	public static BuiltinShadingInfo? FindBuiltinShadingByShortName(StringView shortName)
	{
		for (let info in BuiltinShadings)
		{
			if (info.ShortName == shortName)
				return info;
		}
		return null;
	}

	/// A material on `shading`'s builtin, its defaults. THE CALLER OWNS what comes back.
	public static Material CreateBuiltin(BuiltinShading shading, StringView name)
	{
		switch (shading)
		{
		case .Unlit: return CreateUnlit(name);
		case .Phong: return CreatePhong(name);
		default: return CreatePbr(name);
		}
	}

	/// The builtin template a builtin shader's materials are made from, or null for a custom shader:
	/// what a stored material's property table is checked against.
	///
	/// THE CALLER OWNS what comes back.
	public static Material BuiltinTemplate(StringView shaderName)
	{
		let builtin = FindBuiltinShadingByShader(shaderName);
		return builtin.HasValue ? CreateBuiltin(builtin.Value.Shading, "__template") : null;
	}
}

/// The builtin shaders a material may be drawn with (MaterialPresets.BuiltinShadings).
enum BuiltinShading : uint8
{
	Pbr,
	Unlit,
	Phong,
}

/// How a builtin is known.
struct BuiltinShadingInfo
{
	public BuiltinShading Shading;
	/// The material source's ShaderName.
	public StringView ShaderName;
	/// "pbr", "unlit", "phong".
	public StringView ShortName;
	/// "PBR", "Unlit", "Phong".
	public StringView Label;
	/// What the builtin's vertex stage declares: the effects a material on it may carry where no
	/// shader system is at hand to ask (a material moved between shaders in the editor keeps its
	/// Wind group when both declare WIND).
	public ShaderFlags VertexVariants;

	public this(BuiltinShading shading, StringView shaderName, StringView shortName, StringView label,
		ShaderFlags vertexVariants)
	{
		Shading = shading;
		ShaderName = shaderName;
		ShortName = shortName;
		Label = label;
		VertexVariants = vertexVariants;
	}
}
