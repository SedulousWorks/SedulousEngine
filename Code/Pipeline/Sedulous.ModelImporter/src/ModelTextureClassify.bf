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

	/// Marks every texture a material binds in its NORMAL slot.
	///
	/// That is the usage a file backed texture asset carries; the other linear slots, the
	/// packed or separate metal and roughness ones and occlusion, are data masks instead.
	public static void NormalTextures(Model model, List<bool> outNormal)
	{
		outNormal.Clear();
		outNormal.Count = model.Textures.Length;

		for (let material in model.Materials)
		{
			if (material == null)
				continue;
			let index = material.NormalTextureIndex;
			if ((index >= 0) && (index < outNormal.Count))
				outNormal[index] = true;
		}
	}

	/// A transmissive (glass) surface that is otherwise opaque: the engine does not refract, so
	/// it draws blended, its base colour's alpha carrying the opacity (ModelMaterialBuild).
	public static bool DrawsTransmissive(ModelMaterial material) =>
		(material.Transmission > 0.0f) && (material.AlphaMode == .Opaque) && (material.Shading == .Pbr);

	/// The alpha a cutoff compares against, in the 1/255 steps the cook keeps coverage in. 0: a
	/// cutoff everything passes, which has no coverage to keep.
	public static uint8 AlphaCutoffStep(float cutoff) => (uint8)(Math.Clamp(cutoff, 0.0f, 1.0f) * 255.0f + 0.5f);

	/// How a material reads its base colour's alpha: tested against its cutoff (Mask), blended
	/// (Blend, or a transmissive surface the engine draws blended), or not at all (opaque).
	public static BaseAlphaUse BaseColorAlphaUse(ModelMaterial material)
	{
		if (material.AlphaMode == .Mask)
			return (AlphaCutoffStep(material.AlphaCutoff) > 0) ? .Tested : .Ignored;
		if ((material.AlphaMode == .Blend) || DrawsTransmissive(material))
			return .Blended;
		return .Ignored;
	}

	/// Per texture, what the materials taking it as their base colour need of its alpha
	/// (TextureAlphaUses), parallel to the model's textures. `outUses` OWNS its entries.
	public static void ClassifyBaseColorAlpha(Model model, List<TextureAlphaUses> outUses)
	{
		ClearAndDeleteItems(outUses);
		for (int i < model.Textures.Length)
			outUses.Add(new TextureAlphaUses());
		for (let material in model.Materials)
		{
			if ((material == null) || (material.BaseColorTextureIndex < 0) || (material.BaseColorTextureIndex >= outUses.Count))
				continue;
			let uses = outUses[material.BaseColorTextureIndex];
			switch (BaseColorAlphaUse(material))
			{
			case .Tested:
				let step = AlphaCutoffStep(material.AlphaCutoff);
				var at = 0;
				while ((at < uses.Cutoffs.Count) && (uses.Cutoffs[at] < step))
					at++;
				if ((at == uses.Cutoffs.Count) || (uses.Cutoffs[at] != step))
					uses.Cutoffs.Insert(at, step);
			case .Blended:
				uses.Blended = true;
			case .Ignored:
			}
		}
	}

	/// The key of a texture's copy that keeps `cutoff`'s coverage (TextureAlphaUses).
	public static uint64 AlphaCopyKey(int textureIndex, uint8 cutoff) => ((uint64)textureIndex << 8) | cutoff;

	/// The name suffix of that copy: the cutoff in thousandths, distinct for distinct steps.
	public static void AlphaCopySuffix(uint8 cutoff, String outSuffix)
	{
		outSuffix.AppendF("_cutoff{}", ((uint32)cutoff * 1000 + 127) / 255);
	}
}

/// How a material reads its base colour's alpha.
enum BaseAlphaUse
{
	Ignored,
	Tested,
	Blended
}

/// What the materials taking a texture as their base colour need of its alpha: the cutoffs
/// they test it at (distinct AlphaCutoffStep values, ascending), each needing mipmaps that keep
/// that cutoff's coverage (TextureAsset.PreserveAlphaCoverage), or leaves and grass thin out and
/// vanish with distance; and whether one blends with it, which needs the alpha as authored. An
/// opaque material reads no alpha and takes any of them.
class TextureAlphaUses
{
	public List<uint8> Cutoffs = new .() ~ delete _;
	public bool Blended = false;

	/// The cutoff whose coverage the texture's own asset keeps (0: none): the first tested one,
	/// unless a material blends with it, which keeps the plain asset. Every other cutoff gets an
	/// asset of its own.
	public uint8 OwnCutoff => (!Blended && !Cutoffs.IsEmpty) ? Cutoffs[0] : 0;
}
