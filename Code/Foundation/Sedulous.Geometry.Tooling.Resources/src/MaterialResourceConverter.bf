using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Resources;
using Sedulous.Geometry.Tooling;

namespace Sedulous.Geometry.Tooling.Resources;

/// Converts ImportedMaterial to MaterialResource.
static class MaterialResourceConverter
{
	/// Creates a MaterialResource from an ImportedMaterial.
	/// importedTextures contains already-converted TextureResources (with assigned GUIDs).
	public static MaterialResource Convert(ImportedMaterial imported, List<TextureResource> importedTextures)
	{
		if (imported == null)
			return null;

		// Create PBR material
		let mat = Materials.CreatePBR(imported.Name, "forward");

		// Set PBR properties
		mat.SetDefaultFloat4("BaseColor", .(imported.BaseColor.X, imported.BaseColor.Y,
			imported.BaseColor.Z, imported.BaseColor.W));
		mat.SetDefaultFloat("Metallic", imported.Metallic);
		mat.SetDefaultFloat("Roughness", imported.Roughness);
		mat.SetDefaultFloat4("EmissiveColor", .(imported.EmissiveFactor.X, imported.EmissiveFactor.Y,
			imported.EmissiveFactor.Z, 1.0f));
		mat.SetDefaultFloat("AlphaCutoff", imported.AlphaCutoff);

		// Set pipeline config based on alpha mode
		switch (imported.AlphaMode)
		{
		case .Opaque:
			mat.PipelineConfig.BlendMode = .Opaque;
			mat.PipelineConfig.DepthMode = .ReadWrite;
		case .Mask:
			mat.PipelineConfig.BlendMode = .Opaque;
			mat.PipelineConfig.DepthMode = .ReadWrite;
			mat.ShaderFlags |= .AlphaTest;
			mat.PipelineConfig.ShaderFlags |= .AlphaTest;
		case .Blend:
			mat.PipelineConfig.BlendMode = .AlphaBlend;
			mat.PipelineConfig.DepthMode = .ReadOnly;
		}

		mat.PipelineConfig.CullMode = imported.DoubleSided ? .None : .Back;
		if (imported.DoubleSided)
		{
			mat.ShaderFlags |= .DoubleSided;
			mat.PipelineConfig.ShaderFlags |= .DoubleSided;
		}

		// Enable normal mapping if the model has a normal texture
		if (imported.Normal.HasTexture)
		{
			mat.ShaderFlags |= .NormalMap;
			mat.PipelineConfig.ShaderFlags |= .NormalMap;
		}

		// Enable emissive if the model has an emissive texture
		if (imported.Emissive.HasTexture)
		{
			mat.ShaderFlags |= .Emissive;
			mat.PipelineConfig.ShaderFlags |= .Emissive;
		}

		// Create resource wrapper
		let matRes = new MaterialResource(mat, true);
		matRes.Name.Set(imported.Name);

		// Set sampler from the albedo texture slot
		if (imported.Albedo.HasTexture)
		{
			matRes.WrapU = ConvertWrapMode(imported.Albedo.WrapU);
			matRes.WrapV = ConvertWrapMode(imported.Albedo.WrapV);
			matRes.MinFilter = ConvertMinFilter(imported.Albedo.MinFilter);
			matRes.MagFilter = ConvertMagFilter(imported.Albedo.MagFilter);
		}

		// Set texture references
		SetTextureSlot(matRes, "AlbedoMap", imported.Albedo, importedTextures);
		SetTextureSlot(matRes, "NormalMap", imported.Normal, importedTextures);
		SetTextureSlot(matRes, "MetallicRoughnessMap", imported.MetallicRoughness, importedTextures);
		SetTextureSlot(matRes, "OcclusionMap", imported.Occlusion, importedTextures);
		SetTextureSlot(matRes, "EmissiveMap", imported.Emissive, importedTextures);

		return matRes;
	}

	/// Helper to set texture ResourceRef in MaterialResource from a MaterialTexture slot.
	private static void SetTextureSlot(MaterialResource matRes, StringView slot, MaterialTexture texSlot, List<TextureResource> importedTextures)
	{
		if (!texSlot.HasTexture)
			return;

		Guid texGuid = .();
		String texPath = scope .();

		if (importedTextures != null && texSlot.TextureIndex < importedTextures.Count)
		{
			let importedTex = importedTextures[texSlot.TextureIndex];
			texGuid = importedTex.Id;
			texPath.AppendF("{}.texture", importedTex.Name);
		}
		else
		{
			texPath.AppendF("texture_{}", texSlot.TextureIndex);
		}

		matRes.SetTextureRef(slot, ResourceRef(texGuid, texPath));
	}

	private static SamplerAddressMode ConvertWrapMode(TextureWrapMode mode)
	{
		switch (mode)
		{
		case .Repeat:         return .Repeat;
		case .MirroredRepeat: return .MirrorRepeat;
		case .ClampToEdge:    return .ClampToEdge;
		}
	}

	private static SamplerMinFilter ConvertMinFilter(TextureFilterMode mode)
	{
		switch (mode)
		{
		case .Nearest:              return .Nearest;
		case .Linear:               return .Linear;
		case .NearestMipmapNearest: return .NearestMipmapNearest;
		case .LinearMipmapNearest:  return .LinearMipmapNearest;
		case .NearestMipmapLinear:  return .NearestMipmapLinear;
		case .LinearMipmapLinear:   return .LinearMipmapLinear;
		}
	}

	private static SamplerMagFilter ConvertMagFilter(TextureFilterMode mode)
	{
		switch (mode)
		{
		case .Nearest: return .Nearest;
		case .Linear:  return .Linear;
		default:       return .Linear;
		}
	}
}
