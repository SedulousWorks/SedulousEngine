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
			..Scalar("Metallic", metallic)
			..Scalar("Roughness", roughness)
			// Black means none: the emissive map multiplies through this.
			..Color("EmissiveColor", .(0, 0, 0, 1))
			..Scalar("OcclusionStrength", 1.0f)
			..Scalar("NormalScale", 1.0f)
			..Scalar("AlphaCutoff", 0.5f)
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
}
