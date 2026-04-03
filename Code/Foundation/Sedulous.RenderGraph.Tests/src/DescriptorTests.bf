namespace Sedulous.RenderGraph.Tests;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;

class DescriptorTests
{
	[Test]
	public static void TextureDesc_FullSize_Resolves()
	{
		var desc = RGTextureDesc(.RGBA8Unorm, .FullSize);
		desc.Resolve(1920, 1080);

		Test.Assert(desc.Width == 1920);
		Test.Assert(desc.Height == 1080);
	}

	[Test]
	public static void TextureDesc_HalfSize_Resolves()
	{
		var desc = RGTextureDesc(.RGBA8Unorm, .HalfSize);
		desc.Resolve(1920, 1080);

		Test.Assert(desc.Width == 960);
		Test.Assert(desc.Height == 540);
	}

	[Test]
	public static void TextureDesc_QuarterSize_Resolves()
	{
		var desc = RGTextureDesc(.RGBA8Unorm, .QuarterSize);
		desc.Resolve(1920, 1080);

		Test.Assert(desc.Width == 480);
		Test.Assert(desc.Height == 270);
	}

	[Test]
	public static void TextureDesc_Custom_NoResolve()
	{
		var desc = RGTextureDesc(.RGBA8Unorm, 256, 256);
		desc.Resolve(1920, 1080);

		// Custom should not change
		Test.Assert(desc.Width == 256);
		Test.Assert(desc.Height == 256);
	}

	[Test]
	public static void TextureDesc_HalfSize_MinOne()
	{
		var desc = RGTextureDesc(.RGBA8Unorm, .HalfSize);
		desc.Resolve(1, 1);

		// Should be at least 1
		Test.Assert(desc.Width >= 1);
		Test.Assert(desc.Height >= 1);
	}

	[Test]
	public static void ColorTarget_Defaults()
	{
		let target = RGColorTarget(RGHandle(0, 1));
		Test.Assert(target.LoadOp == .Clear);
		Test.Assert(target.StoreOp == .Store);
	}

	[Test]
	public static void DepthTarget_Defaults()
	{
		let target = RGDepthTarget(RGHandle(0, 1));
		Test.Assert(target.DepthLoadOp == .Clear);
		Test.Assert(target.DepthStoreOp == .Store);
		Test.Assert(target.DepthClearValue == 1.0f);
		Test.Assert(!target.ReadOnly);
	}

	[Test]
	public static void Config_Defaults()
	{
		let config = RenderGraphConfig();
		Test.Assert(config.FrameBufferCount == 2);
	}
}
