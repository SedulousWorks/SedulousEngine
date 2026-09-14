using System;
using System.Collections;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// Working out what each of a model's textures is FOR, which decides how it is cooked.
static class ModelTextureClassify
{
	/// Marks every texture that must stay LINEAR.
	///
	/// A data map, being a normal, a metal and roughness pair packed or separate, or an
	/// occlusion map, carries values rather than colour: decoding one as sRGB corrupts it, a
	/// flat normal's half becoming about a fifth. Colour maps are sRGB encoded and stay that
	/// way.
	///
	/// A texture referenced BOTH ways classifies as linear, which is rare and is the safer of
	/// the two mistakes: correctness of data beats correctness of colour.
	public static void LinearTextures(Model model, List<bool> outLinear)
	{
		outLinear.Clear();
		outLinear.Count = model.Textures.Length;

		void Mark(int32 index)
		{
			if ((index >= 0) && (index < outLinear.Count))
				outLinear[index] = true;
		}

		for (let material in model.Materials)
		{
			if (material == null)
				continue;
			Mark(material.NormalTextureIndex);
			Mark(material.MetallicRoughnessTextureIndex);
			Mark(material.SeparateRoughnessTextureIndex);
			Mark(material.SeparateMetalnessTextureIndex);
			Mark(material.OcclusionTextureIndex);
		}
	}
}
