namespace Sedulous.RenderGraph.Tests;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;

class TypeTests
{
	[Test]
	public static void Handle_Equality()
	{
		let a = RGHandle(1, 1);
		let b = RGHandle(1, 1);
		let c = RGHandle(2, 1);

		Test.Assert(a == b);
		Test.Assert(a != c);
	}

	[Test]
	public static void Handle_Invalid()
	{
		let invalid = RGHandle.Invalid;
		Test.Assert(!invalid.IsValid);

		let valid = RGHandle(0, 1);
		Test.Assert(valid.IsValid);
	}

	[Test]
	public static void Handle_Hashing()
	{
		let a = RGHandle(1, 1);
		let b = RGHandle(1, 1);
		Test.Assert(a.GetHashCode() == b.GetHashCode());
	}

	[Test]
	public static void PassHandle_Invalid()
	{
		let invalid = PassHandle.Invalid;
		Test.Assert(!invalid.IsValid);

		let valid = PassHandle(0);
		Test.Assert(valid.IsValid);
	}

	[Test]
	public static void AccessType_IsRead()
	{
		Test.Assert(RGAccessType.ReadTexture.IsRead);
		Test.Assert(RGAccessType.ReadBuffer.IsRead);
		Test.Assert(RGAccessType.ReadDepthStencil.IsRead);
		Test.Assert(RGAccessType.ReadCopySrc.IsRead);
		Test.Assert(RGAccessType.ReadWriteStorage.IsRead);

		Test.Assert(!RGAccessType.WriteColorTarget.IsRead);
		Test.Assert(!RGAccessType.WriteDepthTarget.IsRead);
		Test.Assert(!RGAccessType.WriteStorage.IsRead);
		Test.Assert(!RGAccessType.WriteCopyDst.IsRead);
	}

	[Test]
	public static void AccessType_IsWrite()
	{
		Test.Assert(RGAccessType.WriteColorTarget.IsWrite);
		Test.Assert(RGAccessType.WriteDepthTarget.IsWrite);
		Test.Assert(RGAccessType.WriteStorage.IsWrite);
		Test.Assert(RGAccessType.WriteCopyDst.IsWrite);
		Test.Assert(RGAccessType.ReadWriteStorage.IsWrite);

		Test.Assert(!RGAccessType.ReadTexture.IsWrite);
		Test.Assert(!RGAccessType.ReadBuffer.IsWrite);
	}

	[Test]
	public static void AccessType_ToResourceState()
	{
		Test.Assert(RGAccessType.ReadTexture.ToResourceState() == .ShaderRead);
		Test.Assert(RGAccessType.WriteColorTarget.ToResourceState() == .RenderTarget);
		Test.Assert(RGAccessType.WriteDepthTarget.ToResourceState() == .DepthStencilWrite);
		Test.Assert(RGAccessType.ReadDepthStencil.ToResourceState() == .DepthStencilRead);
		Test.Assert(RGAccessType.ReadCopySrc.ToResourceState() == .CopySrc);
		Test.Assert(RGAccessType.WriteCopyDst.ToResourceState() == .CopyDst);
		Test.Assert(RGAccessType.WriteStorage.ToResourceState() == .ShaderWrite);
	}

	[Test]
	public static void SubresourceRange_All()
	{
		let all = RGSubresourceRange.All;
		Test.Assert(all.IsAll);
		Test.Assert(all.BaseMipLevel == 0);
		Test.Assert(all.MipLevelCount == 0);
		Test.Assert(all.BaseArrayLayer == 0);
		Test.Assert(all.ArrayLayerCount == 0);
	}

	[Test]
	public static void SubresourceRange_Overlap()
	{
		let layer0 = RGSubresourceRange(0, 1, 0, 1);
		let layer1 = RGSubresourceRange(0, 1, 1, 1);
		let allLayers = RGSubresourceRange.All;

		// Different layers don't overlap
		Test.Assert(!layer0.Overlaps(layer1, 1, 4));
		// All overlaps with any specific layer
		Test.Assert(allLayers.Overlaps(layer0, 1, 4));
		Test.Assert(allLayers.Overlaps(layer1, 1, 4));
		// Same layer overlaps itself
		Test.Assert(layer0.Overlaps(layer0, 1, 4));
	}

	[Test]
	public static void SubresourceRange_MipOverlap()
	{
		let mip0 = RGSubresourceRange(0, 1, 0, 0);
		let mip1 = RGSubresourceRange(1, 1, 0, 0);

		Test.Assert(!mip0.Overlaps(mip1, 4, 1));
		Test.Assert(mip0.Overlaps(mip0, 4, 1));
	}

	[Test]
	public static void SizeMode_Values()
	{
		Test.Assert(SizeMode.FullSize != SizeMode.HalfSize);
		Test.Assert(SizeMode.Custom != SizeMode.QuarterSize);
	}
}
