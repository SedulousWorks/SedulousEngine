using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.Pipeline;
using Sedulous.Materials.Resource;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// A model's material as a material asset on the built-in its shading model names (Raptor's
/// phong-material spec), as its file authored it. Both cooks (the file import's and the direct
/// one) make their materials here.
static class ModelMaterialBuild
{
	/// `material` into `asset`, named `name`: PBR its factors and its five maps (FBX's separate metal
	/// and rough maps baked into one packed map by `packedMetallicRoughness`, the caller's, as each
	/// cook makes textures its own way); Phong its diffuse and highlight, Lambert its diffuse alone,
	/// each with its normal and emissive maps; Unlit its colour and map. Then the authored pipeline
	/// state and the samplers. Every texture the material reads is wired into its source, so a
	/// material picked on its own draws fully textured.
	public static void Build(Model model, ModelMaterial material, StringView name, List<Guid> textureGuids,
		delegate Guid(int32 roughIndex, int32 metalIndex) packedMetallicRoughness, MaterialAsset asset)
	{
		Material built;
		switch (material.Shading)
		{
		case .Phong, .Lambert:
			let highlight = material.Shading == .Phong;
			let specular = highlight ? Float4(material.SpecularColor.X, material.SpecularColor.Y, material.SpecularColor.Z, 1.0f)
				: Float4(0.0f, 0.0f, 0.0f, 1.0f);
			built = MaterialPresets.CreatePhong(name, material.BaseColorFactor, specular, material.Shininess);
		case .Unlit:
			built = MaterialPresets.CreateUnlit(name, material.BaseColorFactor);
		default:
			built = MaterialPresets.CreatePbr(name, material.BaseColorFactor, material.MetallicFactor, material.RoughnessFactor);
			built.SetDefaultFloat("OcclusionStrength", material.OcclusionStrength);
		}
		defer delete built;
		// What the built-ins share by name (a property a built-in lacks is passed by). A ColorHdr: the
		// sRGB colour, the intensity in w.
		built.SetDefaultColor("EmissiveColor", .(material.EmissiveFactor.X, material.EmissiveFactor.Y,
			material.EmissiveFactor.Z, material.EmissiveIntensity));
		built.SetDefaultFloat("NormalScale", material.NormalScale);
		built.SetDefaultFloat("AlphaCutoff", material.AlphaCutoff);
		MaterialSource.FromMaterial(built, .Empty, asset.Source); // no shader id: the built-in by name
		asset.Source.ShaderName.Set(built.ShaderName);

		let source = asset.Source;
		void Wire(int32 index, StringView slot)
		{
			if ((index < 0) || (index >= textureGuids.Count) || (textureGuids[index] == Guid.Empty))
				return;
			source.TextureSlots.Add(new String(slot));
			source.TextureIds.Add(textureGuids[index]);
		}

		Wire(material.BaseColorTextureIndex, "AlbedoMap");
		if (material.Shading != .Unlit)
		{
			Wire(material.NormalTextureIndex, "NormalMap");
			Wire(material.EmissiveTextureIndex, "EmissiveMap");
		}
		if (material.Shading == .Phong)
			Wire(material.SpecularTextureIndex, "SpecularMap");
		if (material.Shading == .Pbr)
		{
			Wire(material.OcclusionTextureIndex, "OcclusionMap");
			if (material.MetallicRoughnessTextureIndex >= 0)
			{
				// Already packed, which is what most formats supply.
				Wire(material.MetallicRoughnessTextureIndex, "MetallicRoughnessMap");
			}
			else if (((material.SeparateRoughnessTextureIndex >= 0) || (material.SeparateMetalnessTextureIndex >= 0))
				&& (packedMetallicRoughness != null))
			{
				// Two grayscale maps: feeding either into the packed slot as it stands would bleed
				// one channel's data across the others, so the pair bakes into a packed one.
				let packed = packedMetallicRoughness(material.SeparateRoughnessTextureIndex, material.SeparateMetalnessTextureIndex);
				if (packed != Guid.Empty)
				{
					source.TextureSlots.Add(new String("MetallicRoughnessMap"));
					source.TextureIds.Add(packed);
				}
			}
		}

		// The authored pipeline state. A masked material is an alpha tested cutout, which also
		// gives its shadow holes; a blended one goes to the transparent pass.
		if (material.AlphaMode == .Mask)
			source.BlendMode = .Masked;
		else if (material.AlphaMode == .Blend)
			source.BlendMode = .AlphaBlend;

		if (material.DoubleSided)
			source.CullMode = .None;

		ModelSamplerModes.For(model, material, let samplerU, let samplerV);
		source.SamplerU = (uint8)samplerU;
		source.SamplerV = (uint8)samplerV;
	}
}
