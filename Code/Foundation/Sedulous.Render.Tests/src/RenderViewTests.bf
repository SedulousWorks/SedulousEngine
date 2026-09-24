using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// A view over a snapshot: what it draws, in what order, and what it culls.
class RenderViewTests
{
	private static Float4x4 Projection() => Float4x4.PerspectiveFovRH(1.0f, 1.0f, 0.1f, 100.0f);

	/// Looking down negative Z from the origin, which is where a right handed camera looks.
	private static ViewCamera LookingForward()
	{
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0));
		camera.Projection = Projection();
		camera.FarZ = 100.0f;
		return camera;
	}

	/// A mesh at a distance ahead of the camera.
	private static MeshRenderData AddMeshAt(ExtractedScene scene, float distance, uint16 category)
	{
		let mesh = scene.Add<MeshRenderData>();
		mesh.Category = category;
		mesh.WorldCenter = .(0, 0, -distance);
		mesh.WorldRadius = 1.0f;
		return mesh;
	}

	/// Opaque work sorts FRONT TO BACK, so the nearest draws first and rejects what is behind
	/// it.
	[Test]
	public static void OpaqueDrawsSortNearestFirst()
	{
		let scene = scope ExtractedScene();
		let near = AddMeshAt(scene, 5.0f, RenderCategories.Opaque);
		let far = AddMeshAt(scene, 50.0f, RenderCategories.Opaque);

		let view = scope RenderView();
		view.Bind(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);

		let scratch = scope List<DrawItem>();
		view.BuildDrawList(scratch);

		Test.Assert(view.DrawList.Length == 2);
		Test.Assert(view.DrawList[0].Data == near);
		Test.Assert(view.DrawList[1].Data == far);
	}

	/// Blended work sorts BACK TO FRONT, because the order is the result.
	[Test]
	public static void BlendedDrawsSortFurthestFirst()
	{
		let scene = scope ExtractedScene();
		let near = AddMeshAt(scene, 5.0f, RenderCategories.Transparent);
		let far = AddMeshAt(scene, 50.0f, RenderCategories.Transparent);

		let view = scope RenderView();
		view.Bind(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);

		let scratch = scope List<DrawItem>();
		view.BuildDrawList(scratch);

		Test.Assert(view.DrawList[0].Data == far);
		Test.Assert(view.DrawList[1].Data == near);
	}

	/// The CATEGORY outranks depth, so every opaque draw precedes every blended one whatever
	/// their distances.
	[Test]
	public static void EveryOpaqueDrawPrecedesTheBlendedOnes()
	{
		let scene = scope ExtractedScene();
		let blendedNear = AddMeshAt(scene, 1.0f, RenderCategories.Transparent);
		let opaqueFar = AddMeshAt(scene, 90.0f, RenderCategories.Opaque);

		let view = scope RenderView();
		view.Bind(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);

		let scratch = scope List<DrawItem>();
		view.BuildDrawList(scratch);

		Test.Assert(view.DrawList[0].Data == opaqueFar);
		Test.Assert(view.DrawList[1].Data == blendedNear);
	}

	/// Culling rejects what the frustum misses, and counts what it looked at.
	[Test]
	public static void CullingRejectsWhatIsOutsideTheFrustum()
	{
		let scene = scope ExtractedScene();
		AddMeshAt(scene, 10.0f, RenderCategories.Opaque);

		let behind = scene.Add<MeshRenderData>();
		behind.WorldCenter = .(0, 0, 500);
		behind.WorldRadius = 1.0f;

		let view = scope RenderView();
		view.Bind(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);

		let scratch = scope List<DrawItem>();
		view.BuildDrawList(scratch, true);

		Test.Assert(view.SceneItemCount == 2);
		Test.Assert(view.CulledCount == 1);
		Test.Assert(view.DrawList.Length == 1);
	}

	/// With culling OFF nothing is tested, and the counts say so.
	[Test]
	public static void WithoutCullingNothingIsTested()
	{
		let scene = scope ExtractedScene();
		AddMeshAt(scene, 10.0f, RenderCategories.Opaque);

		let behind = scene.Add<MeshRenderData>();
		behind.WorldCenter = .(0, 0, 500);

		let view = scope RenderView();
		view.Bind(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);

		let scratch = scope List<DrawItem>();
		view.BuildDrawList(scratch, false);

		Test.Assert(view.CulledCount == 0);
		Test.Assert(view.DrawList.Length == 2);
	}

	/// A view with no snapshot draws nothing rather than faulting.
	[Test]
	public static void AnUnboundViewDrawsNothing()
	{
		let view = scope RenderView();
		let scratch = scope List<DrawItem>();

		view.BuildDrawList(scratch);
		Test.Assert(view.DrawList.IsEmpty);
		Test.Assert(view.SceneItemCount == 0);
	}

	/// A stated viewport is a SUB RECTANGLE of the target; without one the view covers all of
	/// it.
	[Test]
	public static void TheViewportDefaultsToTheWholeTarget()
	{
		let scene = scope ExtractedScene();
		let view = scope RenderView();

		view.Bind(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);
		Test.Assert((view.ViewportX == 0) && (view.ViewportY == 0));
		Test.Assert((view.ViewportWidth == 800) && (view.ViewportHeight == 600));

		var settings = ViewSettings();
		settings.ViewportX = 400;
		settings.ViewportWidth = 400;
		settings.ViewportHeight = 300;
		view.Bind(scene, LookingForward(), settings, null, .BGRA8Unorm, 800, 600);

		Test.Assert(view.ViewportX == 400);
		Test.Assert((view.ViewportWidth == 400) && (view.ViewportHeight == 300));
		Test.Assert((view.Width == 800) && (view.Height == 600), "the target is still the target");
	}

	/// The jitter shifts clip space by a constant number of pixels, which is what temporal
	/// antialiasing samples between.
	[Test]
	public static void TheProjectionJitterShiftsClipSpace()
	{
		let scene = scope ExtractedScene();
		let view = scope RenderView();
		view.Bind(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);

		let before = view.Camera.Projection;
		view.ApplyProjectionJitter(0.01f, -0.02f);
		let after = view.Camera.Projection;

		Test.Assert(after[2, 0] == before[2, 0] + 0.01f);
		Test.Assert(after[2, 1] == before[2, 1] - 0.02f);
		Test.Assert(after[0, 0] == before[0, 0], "and nothing else moved");
	}

	/// Binding a view again CLEARS its draw list, so a pooled view does not draw the last
	/// frame's scene.
	[Test]
	public static void BindingAgainClearsTheDrawList()
	{
		let scene = scope ExtractedScene();
		AddMeshAt(scene, 10.0f, RenderCategories.Opaque);

		let view = scope RenderView();
		view.Bind(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);

		let scratch = scope List<DrawItem>();
		view.BuildDrawList(scratch);
		Test.Assert(view.DrawList.Length == 1);

		view.Bind(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);
		Test.Assert(view.DrawList.IsEmpty);
	}

	/// The pool hands out views whose addresses are STABLE, so growing it never moves one
	/// somebody already acquired.
	[Test]
	public static void ThePoolHandsOutStableViews()
	{
		let pool = scope RenderViewPool();
		pool.Begin();

		let first = pool.Acquire();
		let second = pool.Acquire();

		Test.Assert(first != second);
		Test.Assert(pool.ActiveCount == 2);
		Test.Assert(pool.At(0) == first);

		// Growing the pool past its capacity leaves the earlier views where they were.
		for (int i < 16)
			pool.Acquire();
		Test.Assert(pool.At(0) == first);
		Test.Assert(pool.At(1) == second);
	}

	/// Beginning REWINDS the pool, keeping the views and their draw list storage.
	[Test]
	public static void BeginningRewindsThePool()
	{
		let pool = scope RenderViewPool();

		pool.Begin();
		let first = pool.Acquire();
		pool.Acquire();
		Test.Assert(pool.ActiveCount == 2);

		pool.Begin();
		Test.Assert(pool.ActiveCount == 0);
		Test.Assert(pool.Acquire() == first, "the same storage comes back");
	}

	/// The opaque debug and identity slots are carried per view, which is what lets an editor
	/// viewport draw a grid that appears only in it.
	[Test]
	public static void TheOpaqueSlotsAreCarriedPerView()
	{
		let view = scope RenderView();
		var sceneDebug = 1;
		var viewDebug = 2;
		var key = 3;

		view.SetDebugScene(&sceneDebug);
		view.SetDebugView(&viewDebug);
		view.SetSceneKey(&key);

		Test.Assert(view.DebugScene == &sceneDebug);
		Test.Assert(view.DebugViewList == &viewDebug);
		Test.Assert(view.SceneKey == &key);
	}

	/// The frame gates the cull by BOTH its own switch, on by default, and the view's
	/// setting, which a "draw everything" override clears for an A/B.
	[Test]
	public static void TheFrameGatesCullingByItsSwitchAndTheViewsSetting()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;

		let scene = scope ExtractedScene();
		AddMeshAt(scene, 10.0f, RenderCategories.Opaque);
		let behind = scene.Add<MeshRenderData>();
		behind.WorldCenter = .(0, 0, 500);
		behind.WorldRadius = 1.0f;

		let registry = scope RendererRegistry(); // AddView only builds the draw list
		let frame = scope RenderFrame(device, registry, 2);
		Test.Assert(frame.ViewCulling); // on by default, for every host

		let culled = frame.AddView(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);
		Test.Assert(culled.DrawList.Length == 1);
		Test.Assert(culled.CulledCount == 1);

		// The view opting out draws everything even with the frame's switch on.
		var optOut = ViewSettings();
		optOut.FrustumCull = false;
		let all = frame.AddView(scene, LookingForward(), optOut, null, .BGRA8Unorm, 800, 600);
		Test.Assert(all.DrawList.Length == 2);
		Test.Assert(all.CulledCount == 0);

		// And the frame's switch off overrides a view that would have culled.
		frame.SetViewCulling(false);
		let none = frame.AddView(scene, LookingForward(), .(), null, .BGRA8Unorm, 800, 600);
		Test.Assert(none.DrawList.Length == 2);
		Test.Assert(none.CulledCount == 0);
	}
}
