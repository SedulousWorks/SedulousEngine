using System;
using System.Collections;
using Sedulous.Models;
using Sedulous.Core.Mathematics;

namespace Sedulous.Geometry.Tooling;

/// Converts ModelMaterial to ImportedMaterial.
static class MaterialConverter
{
	/// Creates an ImportedMaterial from a ModelMaterial.
	public static ImportedMaterial Convert(ModelMaterial modelMat, Model model)
	{
		if (modelMat == null)
			return null;

		let mat = new ImportedMaterial();
		mat.Name.Set(modelMat.Name);
		mat.BaseColor = modelMat.BaseColorFactor;
		mat.Metallic = modelMat.MetallicFactor;
		mat.Roughness = modelMat.RoughnessFactor;
		mat.AlphaCutoff = modelMat.AlphaCutoff;
		mat.EmissiveFactor = modelMat.EmissiveFactor;
		mat.DoubleSided = modelMat.DoubleSided;

		switch (modelMat.AlphaMode)
		{
		case .Opaque: mat.AlphaMode = .Opaque;
		case .Mask:   mat.AlphaMode = .Mask;
		case .Blend:  mat.AlphaMode = .Blend;
		}

		// Set texture slots with sampler info from the model
		mat.Albedo = MakeTexSlot(model, modelMat.BaseColorTextureIndex);
		mat.Normal = MakeTexSlot(model, modelMat.NormalTextureIndex);
		mat.MetallicRoughness = MakeTexSlot(model, modelMat.MetallicRoughnessTextureIndex);
		mat.Occlusion = MakeTexSlot(model, modelMat.OcclusionTextureIndex);
		mat.Emissive = MakeTexSlot(model, modelMat.EmissiveTextureIndex);

		return mat;
	}

	/// Builds a MaterialTexture from a model texture index, reading sampler settings.
	private static MaterialTexture MakeTexSlot(Model model, int32 textureIndex)
	{
		MaterialTexture slot = .();
		slot.TextureIndex = textureIndex;

		if (model == null || textureIndex < 0 || textureIndex >= model.Textures.Count)
			return slot;

		let tex = model.Textures[textureIndex];
		if (tex.SamplerIndex >= 0 && tex.SamplerIndex < model.Samplers.Count)
		{
			let sampler = model.Samplers[tex.SamplerIndex];
			slot.WrapU = WrapToMode(sampler.WrapS);
			slot.WrapV = WrapToMode(sampler.WrapT);
			slot.MinFilter = MinFilterToMode(sampler.MinFilter);
			slot.MagFilter = MagFilterToMode(sampler.MagFilter);
		}

		return slot;
	}

	private static TextureWrapMode WrapToMode(TextureWrap wrap)
	{
		switch (wrap)
		{
		case .Repeat:         return .Repeat;
		case .MirroredRepeat: return .MirroredRepeat;
		case .ClampToEdge:    return .ClampToEdge;
		}
	}

	private static TextureFilterMode MinFilterToMode(TextureMinFilter filter)
	{
		switch (filter)
		{
		case .Nearest:              return .Nearest;
		case .Linear:               return .Linear;
		case .NearestMipmapNearest: return .NearestMipmapNearest;
		case .LinearMipmapNearest:  return .LinearMipmapNearest;
		case .NearestMipmapLinear:  return .NearestMipmapLinear;
		case .LinearMipmapLinear:   return .LinearMipmapLinear;
		}
	}

	private static TextureFilterMode MagFilterToMode(TextureMagFilter filter)
	{
		switch (filter)
		{
		case .Nearest: return .Nearest;
		case .Linear:  return .Linear;
		}
	}
}
