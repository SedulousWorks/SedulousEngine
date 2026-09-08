using System;
using Sedulous.RHI;
using Sedulous.Texture;
using Sedulous.Texture.Resource;

namespace Sedulous.Texture.Resource.Tests;

/// The sampler a record asks for. No device needed, which is the point of it having its
/// own place.
class TextureSamplerTests
{
	private static TextureResource Record(TextureFilter min = .Linear, TextureFilter mag = .Linear,
		uint32 mipLevels = 1, float anisotropy = 1.0f)
	{
		let record = new TextureResource();
		record.MinFilter = min;
		record.MagFilter = mag;
		record.MipLevels = mipLevels;
		record.Anisotropy = anisotropy;
		return record;
	}

	/// The mip half of an asset's filter is carried separately, so the texel filters read
	/// only what the name says about texels.
	[Test]
	public static void TheTexelFiltersIgnoreTheMipHalfOfTheName()
	{
		Test.Assert(TextureSamplers.ToFilterMode(.Nearest) == .Nearest);
		Test.Assert(TextureSamplers.ToFilterMode(.MipmapNearest) == .Nearest);
		Test.Assert(TextureSamplers.ToFilterMode(.Linear) == .Linear);
		Test.Assert(TextureSamplers.ToFilterMode(.MipmapLinear) == .Linear);
	}

	[Test]
	public static void EveryWrapModeMaps()
	{
		Test.Assert(TextureSamplers.ToAddressMode(.Repeat) == .Repeat);
		Test.Assert(TextureSamplers.ToAddressMode(.ClampToEdge) == .ClampToEdge);
		Test.Assert(TextureSamplers.ToAddressMode(.ClampToBorder) == .ClampToBorder);
		Test.Assert(TextureSamplers.ToAddressMode(.MirroredRepeat) == .MirrorRepeat);
	}

	[Test]
	public static void TheWrapModesLandOnTheirOwnAxes()
	{
		let record = scope TextureResource();
		record.WrapU = .ClampToEdge;
		record.WrapV = .MirroredRepeat;
		record.WrapW = .ClampToBorder;

		let desc = TextureSamplers.Describe(record);
		Test.Assert(desc.AddressU == .ClampToEdge);
		Test.Assert(desc.AddressV == .MirrorRepeat);
		Test.Assert(desc.AddressW == .ClampToBorder);
	}

	/// Trilinear whenever a chain exists. A model import says Linear and means it about
	/// texels, and nearest mip banding on a real chain is never what anybody wanted.
	[Test]
	public static void AChainTurnsOnTrilinearEvenWhenTheAssetOnlySaidLinear()
	{
		let single = Record(.Linear, .Linear, 1);
		defer delete single;
		Test.Assert(TextureSamplers.Describe(single).MipmapFilter == .Nearest,
			"no chain, nothing to filter between");

		let chained = Record(.Linear, .Linear, 8);
		defer delete chained;
		Test.Assert(TextureSamplers.Describe(chained).MipmapFilter == .Linear);
	}

	/// And an asset that ASKS for mipmap linear gets it, even with no chain yet: the
	/// request is about intent, and a chain may arrive on the next cook.
	[Test]
	public static void AskingForMipmapLinearIsHonouredWithoutAChain()
	{
		let record = Record(.MipmapLinear, .Linear, 1);
		defer delete record;
		Test.Assert(TextureSamplers.Describe(record).MipmapFilter == .Linear);
	}

	[Test]
	public static void MipmapNearestOnAChainlessTextureStaysNearest()
	{
		let record = Record(.MipmapNearest, .Linear, 1);
		defer delete record;
		let desc = TextureSamplers.Describe(record);
		Test.Assert(desc.MipmapFilter == .Nearest);
		Test.Assert(desc.MinFilter == .Nearest);
	}

	/// One is off, and below one is meaningless, so it clamps rather than disabling
	/// filtering outright.
	[Test]
	public static void AnisotropyClampsAtOne()
	{
		let none = Record(.Linear, .Linear, 1, 0.0f);
		defer delete none;
		Test.Assert(TextureSamplers.Describe(none).MaxAnisotropy == 1);

		let negative = Record(.Linear, .Linear, 1, -4.0f);
		defer delete negative;
		Test.Assert(TextureSamplers.Describe(negative).MaxAnisotropy == 1);

		let sixteen = Record(.Linear, .Linear, 1, 16.0f);
		defer delete sixteen;
		Test.Assert(TextureSamplers.Describe(sixteen).MaxAnisotropy == 16);
	}
}
