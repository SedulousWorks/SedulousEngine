using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// The descriptors, and how a relative size resolves.
class RGDescriptorTests
{
	[Test]
	public static void FullSizeTakesTheOutputSize()
	{
		var desc = RGTextureDesc(TextureFormat.RGBA8Unorm, SizeMode.FullSize);
		desc.Resolve(1920, 1080);
		Test.Assert((desc.Width == 1920) && (desc.Height == 1080));
	}

	[Test]
	public static void HalfAndQuarterDivideIt()
	{
		var half = RGTextureDesc(TextureFormat.RGBA8Unorm, SizeMode.HalfSize);
		half.Resolve(1920, 1080);
		Test.Assert((half.Width == 960) && (half.Height == 540));

		var quarter = RGTextureDesc(TextureFormat.RGBA8Unorm, SizeMode.QuarterSize);
		quarter.Resolve(1920, 1080);
		Test.Assert((quarter.Width == 480) && (quarter.Height == 270));
	}

	/// A custom size is the caller's, and the output size does not touch it.
	[Test]
	public static void ACustomSizeIsLeftAlone()
	{
		var desc = RGTextureDesc(TextureFormat.RGBA8Unorm, 256, 128);
		Test.Assert(desc.SizeMode == .Custom);

		desc.Resolve(1920, 1080);
		Test.Assert((desc.Width == 256) && (desc.Height == 128));
	}

	/// NEVER zero in either axis: a target with no extent is not a target, and dividing a
	/// small output down produces one.
	[Test]
	public static void ADimensionNeverResolvesToNothing()
	{
		var custom = RGTextureDesc(TextureFormat.RGBA8Unorm, 0, 0);
		custom.Resolve(1920, 1080);
		Test.Assert((custom.Width == 1) && (custom.Height == 1));

		var full = RGTextureDesc(TextureFormat.RGBA8Unorm, SizeMode.FullSize);
		full.Resolve(0, 0);
		Test.Assert((full.Width == 1) && (full.Height == 1));

		var half = RGTextureDesc(TextureFormat.RGBA8Unorm, SizeMode.HalfSize);
		half.Resolve(1, 1);
		Test.Assert((half.Width == 1) && (half.Height == 1));
	}

	/// The graph texture description becomes an RHI one, which is what the device is handed.
	[Test]
	public static void ItConvertsToATextureDescription()
	{
		var desc = RGTextureDesc(TextureFormat.RGBA8Unorm, 64, 32);
		desc.MipLevelCount = 3;
		desc.ArrayLayerCount = 4;
		desc.SampleCount = 4;
		desc.Usage = .RenderTarget;

		let converted = desc.ToTextureDesc("Scene");
		Test.Assert(converted.Format == .RGBA8Unorm);
		Test.Assert((converted.Width == 64) && (converted.Height == 32));
		Test.Assert(converted.MipLevelCount == 3);
		Test.Assert(converted.ArrayLayerCount == 4);
		Test.Assert(converted.SampleCount == 4);
		Test.Assert(converted.Usage == .RenderTarget);
		Test.Assert(converted.Label == "Scene");
	}

	/// A colour target CLEARS and STORES by default, which is what most passes want and what
	/// makes forgetting to say so harmless.
	[Test]
	public static void AColorTargetDefaultsToClearAndStore()
	{
		let target = RGColorTarget();
		Test.Assert(target.LoadOp == .Clear);
		Test.Assert(target.StoreOp == .Store);
		Test.Assert(!target.Handle.IsValid);
		Test.Assert(!target.ResolveHandle.IsValid, "no resolve unless one is asked for");
		Test.Assert(target.Subresource.IsAll);
	}

	/// Depth clears to the FAR plane, and its stencil is left alone unless asked for.
	[Test]
	public static void ADepthTargetDefaultsToTheFarPlane()
	{
		let target = RGDepthTarget();
		Test.Assert(target.DepthLoadOp == .Clear);
		Test.Assert(target.DepthStoreOp == .Store);
		Test.Assert(target.DepthClearValue == 1.0f);
		Test.Assert(!target.ReadOnly);
		Test.Assert(target.StencilLoadOp == .DontCare);
		Test.Assert(target.StencilStoreOp == .DontCare);
		Test.Assert(target.StencilClearValue == 0);
	}

	[Test]
	public static void TheConfigDefaultsToDoubleBuffering()
	{
		Test.Assert(RenderGraphConfig().FrameBufferCount == 2);
		Test.Assert(RenderGraphConfig(3).FrameBufferCount == 3);
	}

	[Test]
	public static void ABufferDescriptionCarriesItsSizeAndUsage()
	{
		let desc = RGBufferDesc(1024, .Storage);
		Test.Assert(desc.Size == 1024);
		Test.Assert(desc.Usage == .Storage);
		Test.Assert(RGBufferDesc().Size == 0);
	}
}
