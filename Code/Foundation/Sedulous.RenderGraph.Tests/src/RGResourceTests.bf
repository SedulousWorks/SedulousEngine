using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// The resource's own bookkeeping.
class RGResourceTests
{
	[Test]
	public static void TrackingStartsCleared()
	{
		let resource = scope RenderGraphResource("Test", .Texture, .Transient);

		Test.Assert(resource.RefCount == 0);
		Test.Assert(!resource.FirstWriter.IsValid);
		Test.Assert(!resource.LastReader.IsValid);
		Test.Assert((resource.FirstUsePass == -1) && (resource.LastUsePass == -1));
		Test.Assert(resource.Generation == 1, "a fresh resource starts at one");
	}

	[Test]
	public static void ResettingClearsWhatTheCompileWorkedOut()
	{
		let resource = scope RenderGraphResource("Test", .Texture, .Transient);
		resource.RefCount = 5;
		resource.FirstWriter = .(2);
		resource.LastReader = .(7);
		resource.FirstUsePass = 2;
		resource.LastUsePass = 7;

		resource.ResetTracking();

		Test.Assert(resource.RefCount == 0);
		Test.Assert(!resource.FirstWriter.IsValid);
		Test.Assert(resource.LastUsePass == -1);
	}

	/// The totals come from the DESCRIPTOR before anything is allocated, which is what a
	/// subresource range resolves against during compile.
	[Test]
	public static void TheTotalsComeFromTheDescriptor()
	{
		let resource = scope RenderGraphResource("Cascades", .Texture, .Transient);
		var desc = RGTextureDesc(TextureFormat.Depth32Float, 1024, 1024);
		desc.MipLevelCount = 3;
		desc.ArrayLayerCount = 4;
		resource.TextureDesc = desc;

		Test.Assert(resource.TotalMipLevels == 3);
		Test.Assert(resource.TotalArrayLayers == 4);
	}

	/// A buffer has neither, and says one rather than nothing, so a range still resolves.
	[Test]
	public static void ABufferHasOneOfEach()
	{
		let resource = scope RenderGraphResource("Counts", .Buffer, .Transient);
		Test.Assert(resource.TotalMipLevels == 1);
		Test.Assert(resource.TotalArrayLayers == 1);
	}

	/// Releasing does nothing for a resource the graph did not create: an imported or
	/// persistent one belongs to whoever made it.
	[Test]
	public static void ReleasingLeavesWhatTheGraphDoesNotOwn()
	{
		let imported = scope RenderGraphResource("Imported", .Texture, .Imported);
		// Nothing to assert but that it does not fault, which is the whole point: a null
		// device with a non transient lifetime must return before it touches either.
		imported.ReleaseTransient(null);

		let persistent = scope RenderGraphResource("Persistent", .Texture, .Persistent);
		persistent.ReleaseTransient(null);
	}
}
