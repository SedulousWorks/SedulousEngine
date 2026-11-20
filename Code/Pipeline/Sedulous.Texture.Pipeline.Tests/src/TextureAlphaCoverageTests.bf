using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Texture.Pipeline;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Sedulous.Texture.Pipeline.Tests;

/// An alpha tested texture's mipmaps keep its cutoff's coverage, and the asset keeps the
/// settings that ask for it.
class TextureAlphaCoverageTests
{
	/// A level nought RGBA8 image of thin opaque strokes (foliage like: a cutoff's worth of
	/// texels, the rest clear), at a density that varies across it, and its box chain as the
	/// cook builds it.
	private static uint32 FoliageChain(uint32 size, List<uint8> outPixels)
	{
		outPixels.Count = (int)size * (int)size * 4;
		uint32 seed = 12345;
		for (uint32 y < size)
		{
			for (uint32 x < size)
			{
				seed = seed * 1664525u + 1013904223u;
				// Denser toward the left: about 45% of texels there, 5% at the right.
				let density = 0.45f - 0.40f * (float)x / (float)size;
				let leaf = ((float)(seed >> 8) / 16777216.0f) < density;
				let at = ((int)y * (int)size + (int)x) * 4;
				outPixels[at] = 40;
				outPixels[at + 1] = 160;
				outPixels[at + 2] = 40;
				outPixels[at + 3] = leaf ? 255 : 0;
			}
		}
		return TextureMipChain.Append(outPixels, size, size, false);
	}

	/// The share of each level's texels at or above `cut` (0..255), level nought first.
	private static void CoverageByLevel(List<uint8> pixels, uint32 size, uint32 levels, uint32 cut, List<float> outShares)
	{
		var offset = 0;
		var w = size;
		for (uint32 level < levels)
		{
			let count = (int)w * (int)w;
			var passing = 0;
			for (int i < count)
				passing += (pixels[offset + i * 4 + 3] >= cut) ? 1 : 0;
			outShares.Add((float)passing / (float)count);
			offset += count * 4;
			w = (w > 1) ? w / 2 : 1;
		}
	}

	[Test]
	public static void AnAlphaTestedTexturesMipmapsKeepItsCutoffsCoverage()
	{
		// The box chain averages each stroke with the clear texels round it below the cutoff:
		// past a few levels almost nothing passes, which is foliage vanishing with distance.
		const uint32 cSize = 256;
		const uint32 cCut = 115; // 0.45 of 255
		let plain = scope List<uint8>();
		let levels = FoliageChain(cSize, plain);
		let before = scope List<float>();
		CoverageByLevel(plain, cSize, levels, cCut, before);
		let target = before[0];
		Test.Assert((target > 0.1f) && (target < 0.4f), scope String()..AppendF("{}", target));
		Test.Assert(before[4] < target * 0.5f, "16x16: most of it gone");

		// Preserved: every level down to 8x8 keeps level nought's share, within what its texel
		// count allows.
		let kept = scope List<uint8>();
		FoliageChain(cSize, kept);
		TextureMipChain.PreserveAlphaCoverage(kept, cSize, cSize, levels, (float)cCut / 255.0f);
		let after = scope List<float>();
		CoverageByLevel(kept, cSize, levels, cCut, after);
		Test.Assert(after[0] == target, "level nought is never touched");
		var w = cSize;
		for (uint32 level = 0; (level < levels) && (w >= 8); level++, w /= 2)
			Test.Assert(Math.Abs(after[level] - target) < 0.05f + 2.0f / (float)w, scope String()..AppendF("level {} ({}x{}): {} against {}", level, w, w, after[level], target));

		// Through the chain's own entry, the same, down to the 4x4 level where its chain stops.
		let appended = scope List<uint8>();
		appended.AddRange(Span<uint8>(kept.Ptr, (int)cSize * (int)cSize * 4));
		Test.Assert(TextureMipChain.Append(appended, cSize, cSize, false, (float)cCut / 255.0f) == levels - 2);
		Test.Assert(appended.Count == kept.Count - (2 * 2 + 1 * 1) * 4);
		for (int i < appended.Count)
		{
			if (appended[i] != kept[i])
			{
				Test.Assert(false, "Append keeps the coverage too");
				break;
			}
		}

		// Opaque everywhere: nothing to keep, the chain is left as it is.
		let solid = scope List<uint8>();
		for (int i < 16 * 4 + 4 * 4 + 4)
			solid.Add(255);
		let solidBefore = scope List<uint8>()..AddRange(solid);
		TextureMipChain.PreserveAlphaCoverage(solid, 4, 4, 3, 0.5f);
		for (int i < solid.Count)
			Test.Assert(solid[i] == solidBefore[i]);
	}

	/// Leaves on a near-white background (a leaf atlas is mostly clear, and near white there). A
	/// plain average drags every smaller level toward the background, so distant leaves turn pale;
	/// weighted by alpha, each level is the leaves' own green, and no clear texel at any level
	/// keeps the background to fringe an edge with. Without a cutoff the plain average stays.
	[Test]
	public static void AnAlphaTestedTexturesMipmapsKeepItsVisibleTexelsColor()
	{
		const uint32 size = 64;
		let tested = scope List<uint8>();
		let plain = scope List<uint8>();
		for (let pixels in scope List<uint8>[](tested, plain))
		{
			pixels.Count = (int)size * (int)size * 4;
			for (uint32 y < size)
			{
				for (uint32 x < size)
				{
					let leaf = (((x / 3) + (y / 5)) % 3) == 0; // about a third, in strokes
					let at = ((int)y * (int)size + (int)x) * 4;
					pixels[at] = leaf ? 60 : 236;
					pixels[at + 1] = leaf ? 150 : 222;
					pixels[at + 2] = leaf ? 40 : 215;
					pixels[at + 3] = leaf ? 255 : 0;
				}
			}
		}

		let levels = TextureMipChain.Append(tested, size, size, true, 0.45f);
		Test.Assert(levels == 5); // 64 down to 4x4: an alpha-tested chain stops there
		let last = tested.Count - 4; // the 4x4 level's last texel
		Test.Assert(Math.Abs((int)tested[last] - 60) <= 2, scope String()..AppendF("{}", tested[last]));
		Test.Assert(Math.Abs((int)tested[last + 1] - 150) <= 2, scope String()..AppendF("{}", tested[last + 1]));
		Test.Assert(Math.Abs((int)tested[last + 2] - 40) <= 2, scope String()..AppendF("{}", tested[last + 2]));
		var clear = 0;
		for (int i = 0; i < tested.Count; i += 4)
		{
			if (tested[i + 3] == 0)
			{
				clear++;
				Test.Assert(tested[i] < 120, scope String()..AppendF("texel {}: {}", i / 4, tested[i]));
			}
		}
		Test.Assert(clear > 0);

		// Without a cutoff, the full chain too.
		Test.Assert(TextureMipChain.Append(plain, size, size, true, 0.0f) == 7);
		Test.Assert(plain[plain.Count - 4] > 150);
	}

	/// Below 4x4 a level cannot hold a cutoff's coverage: at 1x1 the whole texture is one alpha,
	/// so a distant card wholly passes or wholly fails. The chain stops at four texels across its
	/// short side, and its last level still holds level nought's coverage.
	[Test]
	public static void AnAlphaTestedTexturesChainStopsWhereItStillHoldsItsCoverage()
	{
		const uint32 size = 256;
		const uint32 cut = 115;
		let full = scope List<uint8>();
		Test.Assert(FoliageChain(size, full) == 9);
		let chain = scope List<uint8>();
		chain.AddRange(Span<uint8>(full.Ptr, (int)size * (int)size * 4)); // level nought alone
		let levels = TextureMipChain.Append(chain, size, size, true, (float)cut / 255.0f);
		Test.Assert(levels == 7); // 256 .. 4
		Test.Assert(chain.Count == (256 * 256 + 128 * 128 + 64 * 64 + 32 * 32 + 16 * 16 + 8 * 8 + 4 * 4) * 4);
		let shares = scope List<float>();
		CoverageByLevel(chain, size, levels, cut, shares);
		Test.Assert(Math.Abs(shares[levels - 1] - shares[0]) < 0.1f, scope String()..AppendF("{} vs {}", shares[levels - 1], shares[0]));

		// A wide texture stops on its short side: 64x16 keeps 64x16, 32x8 and 16x4.
		let wide = scope List<uint8>();
		wide.Count = 64 * 16 * 4;
		for (int i < wide.Count)
			wide[i] = ((i % 4) == 3) ? ((((i / 4) % 3) == 0) ? 255 : 0) : 100;
		Test.Assert(TextureMipChain.Append(wide, 64, 16, true, 0.5f) == 3);
	}

	/// The settings round-trip through text, and a texture saved before them reads with its
	/// coverage off: a project's textures must not stop loading for a new field.
	[Test]
	public static void AnAssetKeepsItsAlphaCoverageSettings()
	{
		TexturePipeline.RegisterAll();
		Test.Assert(!scope TextureAsset().PreserveAlphaCoverage, "off by default");
		let asset = scope TextureAsset();
		asset.FileName.Set("leaves.png");
		asset.PreserveAlphaCoverage = true;
		asset.AlphaCoverageReference = 0.45f;
		Test.Assert(Math.Abs(asset.CoverageReference - 0.45f) < 0.0001f);
		let text = scope String();
		{
			let writer = scope XmlSerializer();
			((ISerializable)asset).Serialize(writer);
			writer.GetOutput(text);
		}
		{
			let document = scope XmlDocument();
			Test.Assert(document.Parse(text) == .Ok, text);
			let reader = scope XmlSerializer(document);
			let back = scope TextureAsset();
			((ISerializable)back).Serialize(reader);
			Test.Assert(reader.IsOk);
			Test.Assert(back.PreserveAlphaCoverage, text);
			Test.Assert(Math.Abs(back.AlphaCoverageReference - 0.45f) < 0.0001f);
			Test.Assert(back.FileName.Value == "leaves.png");
		}
		// Saved before them: the appended keys, last in the asset's object, cut off.
		let older = scope String(text);
		let cut = older.IndexOf("name=\"preserveAlphaCoverage\"");
		Test.Assert(cut > 0, text);
		older.RemoveToEnd(older.LastIndexOf('<', cut));
		older.Append("</object></root>");
		let document = scope XmlDocument();
		Test.Assert(document.Parse(older) == .Ok, older);
		let reader = scope XmlSerializer(document);
		let back = scope TextureAsset();
		((ISerializable)back).Serialize(reader);
		Test.Assert(reader.IsOk);
		Test.Assert(!back.PreserveAlphaCoverage);
		Test.Assert(back.CoverageReference == 0.0f);
		Test.Assert(back.FileName.Value == "leaves.png", "what came before them still reads");
	}
}
