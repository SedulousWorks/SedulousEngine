using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// The subresource state tracker: the uniform fast path, divergence, and the collapse back.
class RGStateTrackerTests
{
	[Test]
	public static void ItStartsUniform()
	{
		let tracker = scope SubresourceStateTracker(4, 2, .Undefined);

		Test.Assert(tracker.IsUniform);
		Test.Assert(tracker.UniformState == .Undefined);
		Test.Assert(tracker.GetState(3, 1) == .Undefined);
		Test.Assert((tracker.MipCount == 4) && (tracker.LayerCount == 2));
	}

	/// A geometry of nothing is clamped to one, so every index still answers.
	[Test]
	public static void AZeroGeometryIsClampedToOne()
	{
		let tracker = scope SubresourceStateTracker(0, 0, .ShaderRead);
		Test.Assert((tracker.MipCount == 1) && (tracker.LayerCount == 1));
		Test.Assert(tracker.GetState(0, 0) == .ShaderRead);
	}

	/// Writing the WHOLE resource stays uniform, whatever it was before.
	[Test]
	public static void AWholeResourceWriteStaysUniform()
	{
		let tracker = scope SubresourceStateTracker(4, 2, .Undefined);

		tracker.SetState(.All, .RenderTarget);
		Test.Assert(tracker.IsUniform);
		Test.Assert(tracker.UniformState == .RenderTarget);
	}

	/// Writing PART of it materialises the per subresource storage.
	[Test]
	public static void APartialWriteDiverges()
	{
		let tracker = scope SubresourceStateTracker(1, 4, .Undefined);

		tracker.SetState(.(0, 1, 1, 1), .DepthStencilWrite);
		Test.Assert(!tracker.IsUniform);
		Test.Assert(tracker.GetState(0, 1) == .DepthStencilWrite);
		Test.Assert(tracker.GetState(0, 0) == .Undefined, "the others are where they were");
		Test.Assert(tracker.GetState(0, 3) == .Undefined);
	}

	/// A partial write of the state everything ALREADY HAS diverges nothing: there would be
	/// nothing to remember.
	[Test]
	public static void APartialWriteOfTheSameStateStaysUniform()
	{
		let tracker = scope SubresourceStateTracker(1, 4, .ShaderRead);

		tracker.SetState(.(0, 1, 1, 1), .ShaderRead);
		Test.Assert(tracker.IsUniform);
	}

	/// Once every subresource agrees again it COLLAPSES back, so the divergence costs only as
	/// long as it lasts.
	[Test]
	public static void ItCollapsesWhenTheyAgreeAgain()
	{
		let tracker = scope SubresourceStateTracker(1, 2, .Undefined);

		tracker.SetState(.(0, 1, 0, 1), .RenderTarget);
		Test.Assert(!tracker.IsUniform);

		tracker.SetState(.(0, 1, 1, 1), .RenderTarget);
		Test.Assert(tracker.IsUniform, "both layers agree now");
		Test.Assert(tracker.UniformState == .RenderTarget);
	}

	[Test]
	public static void SettingEverythingCollapsesImmediately()
	{
		let tracker = scope SubresourceStateTracker(2, 2, .Undefined);
		tracker.SetState(.(0, 1, 0, 1), .RenderTarget);

		tracker.SetAll(.Present);
		Test.Assert(tracker.IsUniform);
		Test.Assert(tracker.GetState(1, 1) == .Present);
	}

	/// A count of zero means the REST from the base, which is what a default range relies on.
	[Test]
	public static void AZeroCountMeansTheRest()
	{
		let tracker = scope SubresourceStateTracker(4, 1, .Undefined);

		tracker.SetState(2, 0, 0, 0, .ShaderRead);
		Test.Assert(tracker.GetState(2, 0) == .ShaderRead);
		Test.Assert(tracker.GetState(3, 0) == .ShaderRead, "and everything after it");
		Test.Assert(tracker.GetState(1, 0) == .Undefined);
	}

	/// The states copy out and back, which is how a persistent resource carries a divergence
	/// across a frame.
	[Test]
	public static void TheStatesRoundTrip()
	{
		let tracker = scope SubresourceStateTracker(1, 2, .Undefined);
		tracker.SetState(.(0, 1, 0, 1), .RenderTarget);

		let copied = scope List<ResourceState>();
		tracker.CopyStates(copied);
		Test.Assert(copied.Count == 2);

		let restored = scope SubresourceStateTracker(1, 2, .Undefined);
		restored.InitFromStates(copied, .Undefined);
		Test.Assert(!restored.IsUniform);
		Test.Assert(restored.GetState(0, 0) == .RenderTarget);
		Test.Assert(restored.GetState(0, 1) == .Undefined);
	}

	/// A uniform tracker copies out NOTHING, which is what says it is uniform.
	[Test]
	public static void AUniformTrackerCopiesNothing()
	{
		let tracker = scope SubresourceStateTracker(2, 2, .ShaderRead);

		let copied = scope List<ResourceState>();
		tracker.CopyStates(copied);
		Test.Assert(copied.IsEmpty);
	}

	/// A snapshot that does not MATCH this geometry falls back to the uniform state: the
	/// resource was reallocated at a different size, and the old states describe something
	/// that no longer exists.
	[Test]
	public static void AMismatchedSnapshotFallsBack()
	{
		let tracker = scope SubresourceStateTracker(1, 4, .Undefined);

		let wrongSize = scope List<ResourceState>();
		wrongSize.Add(.RenderTarget);
		wrongSize.Add(.RenderTarget);

		tracker.InitFromStates(wrongSize, .ShaderRead);
		Test.Assert(tracker.IsUniform);
		Test.Assert(tracker.UniformState == .ShaderRead);
	}

	/// A snapshot where everything agrees collapses on the way in.
	[Test]
	public static void AUniformSnapshotCollapsesOnRestore()
	{
		let tracker = scope SubresourceStateTracker(1, 2, .Undefined);

		let states = scope List<ResourceState>();
		states.Add(.RenderTarget);
		states.Add(.RenderTarget);

		tracker.InitFromStates(states, .Undefined);
		Test.Assert(tracker.IsUniform);
		Test.Assert(tracker.UniformState == .RenderTarget);
	}
}
