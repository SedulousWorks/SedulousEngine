using System;
using Sedulous.Core;

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
			// The wind lanes, at offsets 24, 28 and 60: the block's spare slots, so it stays
			// sixty four bytes and a material without them reads nought, which is no sway.
			// Metres of sway at a full height mask, radians per second, and the local height
			// at which the sway is full. A strength above nought selects the WIND vertex
			// variant.
			..Float("WindStrength", 0.0f)
			..Float("WindSpeed", 0.0f)
			// Black means none: the emissive map multiplies through this, times the intensity
			// in w (a glow above white).
			..ColorHdr("EmissiveColor", .(0, 0, 0, 1))
			..Float("OcclusionStrength", 1.0f)
			..Float("NormalScale", 1.0f)
			..Float("AlphaCutoff", 0.5f)
			..Float("WindHeight", 1.0f)
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

	/// The builtin template a builtin shader's materials are made from (CreatePbr for
	/// "forward", CreateUnlit for "unlit"), or null for a custom shader: what a stored
	/// material's property table is checked against.
	///
	/// THE CALLER OWNS what comes back.
	public static Material BuiltinTemplate(StringView shaderName)
	{
		if (shaderName == "forward")
			return CreatePbr("__template", .(1, 1, 1, 1), 0.0f, 0.5f, shaderName);
		if (shaderName == "unlit")
			return CreateUnlit("__template", .(1, 1, 1, 1), shaderName);
		return null;
	}
}
