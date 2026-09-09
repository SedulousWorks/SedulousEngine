using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The overlay registry, and the two views handed to overlay sources.
class OverlayRegistryTests
{
	/// A scene overlay that records nothing and answers a stated order.
	private class TestOverlay : ISceneOverlay
	{
		private int32 mOrder;

		public this(int32 order)
		{
			mOrder = order;
		}

		public int32 OverlayOrder => mOrder;
		public void Render(IRenderPassEncoder encoder, SceneOverlayView view) {}
	}

	[Test]
	public static void OverlaysAreKeptInOrder()
	{
		let registry = scope OverlayRegistry<ISceneOverlay>();
		let last = scope TestOverlay(10);
		let first = scope TestOverlay(-5);
		let middle = scope TestOverlay(0);

		registry.Add(last);
		registry.Add(first);
		registry.Add(middle);

		Test.Assert(registry.Count == 3);
		Test.Assert(registry.Items[0] == first);
		Test.Assert(registry.Items[1] == middle);
		Test.Assert(registry.Items[2] == last);
	}

	/// A TIE keeps the order they registered in, so two overlays at the same order do not
	/// shuffle between frames.
	[Test]
	public static void TiesKeepTheirRegistrationOrder()
	{
		let registry = scope OverlayRegistry<ISceneOverlay>();
		let first = scope TestOverlay(0);
		let second = scope TestOverlay(0);
		let third = scope TestOverlay(0);

		registry.Add(first);
		registry.Add(second);
		registry.Add(third);

		Test.Assert(registry.Items[0] == first);
		Test.Assert(registry.Items[1] == second);
		Test.Assert(registry.Items[2] == third);
	}

	/// Registering is IDEMPOTENT, so a source that registers twice does not draw twice.
	[Test]
	public static void RegisteringTwiceRegistersOnce()
	{
		let registry = scope OverlayRegistry<ISceneOverlay>();
		let overlay = scope TestOverlay(0);

		registry.Add(overlay);
		registry.Add(overlay);

		Test.Assert(registry.Count == 1);
		Test.Assert(registry.Contains(overlay));
	}

	[Test]
	public static void RemovingTakesItOut()
	{
		let registry = scope OverlayRegistry<ISceneOverlay>();
		let overlay = scope TestOverlay(0);
		let other = scope TestOverlay(1);

		registry.Add(overlay);
		registry.Add(other);
		registry.Remove(overlay);

		Test.Assert(!registry.Contains(overlay));
		Test.Assert(registry.Contains(other));
		Test.Assert(registry.Count == 1);

		// Removing something that is not there changes nothing.
		registry.Remove(overlay);
		Test.Assert(registry.Count == 1);
	}

	[Test]
	public static void NothingIsNotAnOverlay()
	{
		let registry = scope OverlayRegistry<ISceneOverlay>();

		registry.Add(null);
		Test.Assert(registry.IsEmpty);
	}

	/// Both overlay views are COLOUR ONLY by default: a source may record stencil work only
	/// when the pass carries a depth stencil attachment AND its format matches what the
	/// source's own pipelines were built against.
	[Test]
	public static void TheOverlayViewsAreColourOnlyByDefault()
	{
		let sceneView = SceneOverlayView();
		Test.Assert(sceneView.DepthStencilFormat == .Undefined);
		Test.Assert(sceneView.TargetFormat == .BGRA8Unorm);
		Test.Assert(sceneView.ViewProjection == Sedulous.Core.Float4x4.Identity());

		let screenView = ScreenOverlayView();
		Test.Assert(screenView.DepthStencilFormat == .Undefined);
		Test.Assert(screenView.TargetFormat == .BGRA8Unorm);
	}

	/// A debug view is OFF until something names a resource or a semantic mode.
	[Test]
	public static void ADebugViewIsOffUntilItNamesSomething()
	{
		let debug = scope ViewDebugView();
		Test.Assert(debug.IsOff);

		debug.Semantic = .Albedo;
		Test.Assert(!debug.IsOff);

		debug.Semantic = .Off;
		debug.Resource.Set("ao.ao");
		Test.Assert(!debug.IsOff);
	}

	/// A multisampled debug source is listed but NOT blittable: its resolved twin is the one
	/// to pick.
	[Test]
	public static void AMultisampledSourceIsNotBlittable()
	{
		let single = scope DebugResourceInfo("scene.color", 1920, 1080, 1, false);
		Test.Assert(single.IsBlittable);

		let multisampled = scope DebugResourceInfo("scene.colorMS", 1920, 1080, 4, false);
		Test.Assert(!multisampled.IsBlittable);
	}

	/// The camera's view projection composes in ROW VECTOR order: the view applies first.
	[Test]
	public static void TheCameraComposesViewThenProjection()
	{
		var camera = ViewCamera();
		camera.View = Sedulous.Core.Float4x4.Translation(.(1, 2, 3));
		camera.Projection = Sedulous.Core.Float4x4.Scale(.(2, 2, 2));

		Test.Assert(camera.ViewProjection == camera.View * camera.Projection);
	}

	/// A viewport of no width means the WHOLE target rather than nothing.
	[Test]
	public static void AZeroWidthViewportMeansTheWholeTarget()
	{
		Test.Assert(ViewportRect().IsFullTarget);
		Test.Assert(!ViewportRect(0, 0, 320, 240).IsFullTarget);
	}
}
