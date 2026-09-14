using System;
using Sedulous.Model;
using Sedulous.RHI;

namespace Sedulous.ModelImporter;

/// Which sampler a material should use.
static class ModelSamplerModes
{
	/// A model's wrap mode as the renderer's.
	///
	/// Converted rather than cast: the two enumerations list the same three modes in a
	/// DIFFERENT order, so a cast would silently swap mirroring for clamping.
	public static AddressMode FromWrap(TextureWrap wrap)
	{
		switch (wrap)
		{
		case .ClampToEdge: return .ClampToEdge;
		case .MirroredRepeat: return .MirrorRepeat;
		default: return .Repeat;
		}
	}

	/// The modes a material's textures ask for, taken from the first slot that has a sampler.
	///
	/// The base colour is tried first, since it is the one a person notices tiling wrong. A
	/// material naming no sampler at all repeats, which is the format's own default.
	public static void For(Model model, ModelMaterial material, out AddressMode outU,
		out AddressMode outV)
	{
		outU = .Repeat;
		outV = .Repeat;

		let slots = scope int32[](material.BaseColorTextureIndex, material.NormalTextureIndex,
			material.MetallicRoughnessTextureIndex, material.EmissiveTextureIndex,
			material.OcclusionTextureIndex);

		for (let slot in slots)
		{
			if ((slot < 0) || (slot >= model.Textures.Length))
				continue;
			let samplerIndex = model.Textures[slot].SamplerIndex;
			if ((samplerIndex < 0) || (samplerIndex >= model.Samplers.Length))
				continue;

			outU = FromWrap(model.Samplers[samplerIndex].WrapS);
			outV = FromWrap(model.Samplers[samplerIndex].WrapT);
			return;
		}
	}
}
