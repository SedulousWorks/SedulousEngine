using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// The value types: handles, access maths and subresource ranges.
class RGTypeTests
{
	[Test]
	public static void HandlesCompareOnIndexAndGeneration()
	{
		Test.Assert(RGHandle(5, 1) == RGHandle(5, 1));
		Test.Assert(RGHandle(5, 1) != RGHandle(5, 2), "a reused slot is not the same resource");
		Test.Assert(RGHandle(5, 1) != RGHandle(6, 1));
	}

	[Test]
	public static void AnInvalidHandleSaysSo()
	{
		Test.Assert(!RGHandle.Invalid.IsValid);
		Test.Assert(RGHandle(0, 0).IsValid, "index zero is a real resource");
		Test.Assert(!PassHandle.Invalid.IsValid);
		Test.Assert(PassHandle(0).IsValid);
	}

	/// A pass handle carries no generation: passes are rebuilt from nothing every frame, so
	/// there is no stale one to catch.
	[Test]
	public static void PassHandlesCompareOnIndexAlone()
	{
		Test.Assert(PassHandle(3) == PassHandle(3));
		Test.Assert(PassHandle(3) != PassHandle(4));
	}

	[Test]
	public static void ReadsAndWritesAreToldApart()
	{
		Test.Assert(RGAccess.IsRead(.ReadTexture) && !RGAccess.IsWrite(.ReadTexture));
		Test.Assert(RGAccess.IsRead(.ReadBuffer) && !RGAccess.IsWrite(.ReadBuffer));
		Test.Assert(RGAccess.IsRead(.SampleDepthStencil));
		Test.Assert(RGAccess.IsRead(.ReadCopySrc));

		Test.Assert(RGAccess.IsWrite(.WriteColorTarget) && !RGAccess.IsRead(.WriteColorTarget));
		Test.Assert(RGAccess.IsWrite(.WriteDepthTarget));
		Test.Assert(RGAccess.IsWrite(.WriteStorage));
		Test.Assert(RGAccess.IsWrite(.WriteCopyDst));

		// The read write ones are BOTH, which is what makes them a hazard with themselves.
		Test.Assert(RGAccess.IsRead(.ReadWriteStorage) && RGAccess.IsWrite(.ReadWriteStorage));
		Test.Assert(RGAccess.IsRead(.ReadWriteDepthTarget) && RGAccess.IsWrite(.ReadWriteDepthTarget));
		Test.Assert(RGAccess.IsRead(.ReadWriteColorTarget) && RGAccess.IsWrite(.ReadWriteColorTarget));
	}

	[Test]
	public static void EachAccessNamesTheStateItNeeds()
	{
		Test.Assert(RGAccess.ToResourceState(.ReadTexture) == .ShaderRead);
		Test.Assert(RGAccess.ToResourceState(.ReadBuffer) == .ShaderRead);
		Test.Assert(RGAccess.ToResourceState(.ReadCopySrc) == .CopySrc);
		Test.Assert(RGAccess.ToResourceState(.WriteColorTarget) == .RenderTarget);
		Test.Assert(RGAccess.ToResourceState(.WriteDepthTarget) == .DepthStencilWrite);
		Test.Assert(RGAccess.ToResourceState(.WriteStorage) == .ShaderWrite);
		Test.Assert(RGAccess.ToResourceState(.WriteCopyDst) == .CopyDst);
		Test.Assert(RGAccess.ToResourceState(.ReadWriteDepthTarget) == .DepthStencilWrite);
		Test.Assert(RGAccess.ToResourceState(.ReadWriteColorTarget) == .RenderTarget);

		// A read write storage needs BOTH, and one barrier into the pair beats two.
		Test.Assert(RGAccess.ToResourceState(.ReadWriteStorage) == (ResourceState.ShaderWrite | .ShaderRead));
	}

	/// Sampling depth is a read like any other, but into the DEPTH read layout: a depth
	/// format cannot be sampled from the ordinary shader read one.
	[Test]
	public static void SamplingDepthNeedsTheDepthReadLayout()
	{
		Test.Assert(RGAccess.ToResourceState(.SampleDepthStencil) == .DepthStencilRead);
		Test.Assert(RGAccess.ToResourceState(.ReadDepthStencil) == .DepthStencilRead);
		Test.Assert(RGAccess.ToResourceState(.SampleDepthStencil) != RGAccess.ToResourceState(.ReadTexture));
	}

	/// A default range is EVERYTHING, so a caller that does not care about subresources never
	/// has to say so.
	[Test]
	public static void ADefaultRangeIsTheWholeResource()
	{
		Test.Assert(RGSubresourceRange.All.IsAll);
		Test.Assert(RGSubresourceRange().IsAll);
		Test.Assert(!RGSubresourceRange(0, 1, 0, 1).IsAll, "a count of one is not all of them");
	}

	[Test]
	public static void RangesOverlapWhenTheyShareASubresource()
	{
		let firstLayer = RGSubresourceRange(0, 1, 0, 1);
		let secondLayer = RGSubresourceRange(0, 1, 1, 1);
		let bothLayers = RGSubresourceRange(0, 1, 0, 2);

		Test.Assert(!firstLayer.Overlaps(secondLayer, 1, 4), "different cascades do not");
		Test.Assert(firstLayer.Overlaps(bothLayers, 1, 4));
		Test.Assert(bothLayers.Overlaps(secondLayer, 1, 4));
		Test.Assert(firstLayer.Overlaps(firstLayer, 1, 4));
	}

	/// An OPEN ENDED count resolves against the totals, so a range meaning everything really
	/// does overlap the last layer.
	[Test]
	public static void AnOpenEndedRangeResolvesAgainstTheTotals()
	{
		let everything = RGSubresourceRange.All;
		let lastLayer = RGSubresourceRange(0, 1, 3, 1);

		Test.Assert(everything.Overlaps(lastLayer, 1, 4));
		Test.Assert(lastLayer.Overlaps(everything, 1, 4));
		// With only one layer in the resource, the fourth is past the end and cannot overlap.
		Test.Assert(!everything.Overlaps(lastLayer, 1, 1));
	}

	[Test]
	public static void AnAccessAnswersForItsOwnType()
	{
		let read = RGResourceAccess(RGHandle(0, 0), .ReadTexture);
		let write = RGResourceAccess(RGHandle(0, 0), .WriteColorTarget);

		Test.Assert(read.IsRead && !read.IsWrite);
		Test.Assert(write.IsWrite && !write.IsRead);
		Test.Assert(write.ToResourceState() == .RenderTarget);
	}
}
