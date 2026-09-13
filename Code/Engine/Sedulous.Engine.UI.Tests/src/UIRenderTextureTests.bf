using System;
using Sedulous.Engine.Render;
using Sedulous.Engine.UI;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// Render texture canvases: an offscreen target of their own, out of both overlay tiers, and
/// bound onto whatever material component the same entity carries.
class UIRenderTextureTests
{
	[Test]
	public static void RenderTextureCanvasesOwnATargetAndStayOutOfTheTiers()
	{
		// Headless GPU: the null device gives the texture lifecycle without a real one.
		//
		// DECLARED FIRST so it is freed LAST: the fixture's teardown shuts the subsystem
		// down, which releases pipelines and textures THROUGH this device.
		let device = scope NullDevice();
		let encoder = scope NullCommandEncoder();
		let fixture = scope UITestFixture();
		fixture.UI.EnsureRenderReady(device, 2);

		let scene = fixture.Scenes.CreateScene("world");
		let canvases = scene.GetSystem<UICanvasComponentManager>();
		let e = scene.CreateEntity("screen");

		let document = UITestFixture.MakeDocument("<Label id=\"rt-label\" text=\"scoreboard\"/>");
		defer delete document;
		{
			let component = canvases.Add(e);
			component.Document.SetDirect(document);
			component.RenderMode = .RenderTexture;
			component.RenderTextureWidth = 256;
			component.RenderTextureHeight = 128;
		}

		let rootsBefore = fixture.UI.UiContext.RootViewCount; // the screen and scene roots
		fixture.Frame();
		var canvas = canvases.Get(e);
		Test.Assert(canvas != null);
		Test.Assert(canvas.Root != null);
		Test.Assert(canvas.RenderRoot != null);
		Test.Assert(fixture.UI.UiContext.RootViewCount == rootsBefore + 1, "the standalone root");

		// NOT in the overlay tiers: the scene root holds only its billboard layer and the
		// document is unreachable from it, since a render texture canvas never draws in the
		// overlay pass and never takes pointer input, the pump probing only tier roots.
		let sceneRoot = fixture.UI.SceneRoot(scene);
		Test.Assert(sceneRoot != null);
		Test.Assert(sceneRoot.ChildCount == 1);
		Test.Assert(sceneRoot.FindByName("rt-label") == null);
		Test.Assert(fixture.UI.ScreenRoot.FindByName("rt-label") == null);
		Test.Assert(canvas.RenderRoot.FindByName("rt-label") != null);

		// No texture until the host seam runs; then one at the authored size.
		Test.Assert(canvas.RenderTexture == null);
		fixture.UI.RenderCanvasTextures(encoder, 0);
		canvas = canvases.Get(e);
		Test.Assert(canvas.RenderTexture != null);
		Test.Assert(canvas.RenderTextureView != null);
		Test.Assert(canvas.RenderTexture.Desc.Width == 256);
		Test.Assert(canvas.RenderTexture.Desc.Height == 128);
		Test.Assert(fixture.UI.CanvasRenderTextureView(scene, e) == canvas.RenderTextureView);
		// And the root laid out at the texture's size.
		Test.Assert(canvas.RenderRoot.ViewportSize.X == 256.0f);
		Test.Assert(canvas.RenderRoot.ViewportSize.Y == 128.0f);

		// A resize recreates the target. A fresh UI frame comes first, the seam running at
		// most once per frame so co hosted editor pages share the one draw.
		canvas.RenderTextureWidth = 512;
		fixture.Frame();
		fixture.UI.RenderCanvasTextures(encoder, 1);
		canvas = canvases.Get(e);
		Test.Assert(canvas.RenderTexture != null);
		Test.Assert(canvas.RenderTexture.Desc.Width == 512);
		Test.Assert(canvas.RenderTexture.Desc.Height == 128);

		// Flipping the mode back to the screen overlay takes the standalone root away, re
		// parents the document into the scene root, and sweeps the GPU target.
		canvas.RenderMode = .ScreenOverlay;
		fixture.Frame();
		canvas = canvases.Get(e);
		Test.Assert(canvas.RenderRoot == null);
		Test.Assert(canvas.RenderTexture == null);
		Test.Assert(canvas.RenderTextureView == null);
		Test.Assert(fixture.UI.SceneRoot(scene).FindByName("rt-label") != null);
		fixture.UI.RenderCanvasTextures(encoder, 0);
		Test.Assert(fixture.UI.CanvasRenderTextureView(scene, e) == null);

		// Back to a render texture, then a DESPAWN: the sweep destroys the orphaned target
		// AND unregisters the standalone root from the context, which stores roots non
		// owning, so a stale registration would dangle.
		canvases.Get(e).RenderMode = .RenderTexture;
		fixture.Frame();
		fixture.UI.RenderCanvasTextures(encoder, 0);
		Test.Assert(canvases.Get(e).RenderTexture != null);
		Test.Assert(fixture.UI.UiContext.RootViewCount == rootsBefore + 1);

		scene.DestroyEntity(e);
		fixture.Frame();
		fixture.UI.RenderCanvasTextures(encoder, 0); // sweeps, and must neither crash nor leak
		Test.Assert(canvases.Get(e) == null);
		Test.Assert(fixture.UI.UiContext.RootViewCount == rootsBefore, "swept with the entity");
	}

	[Test]
	public static void RenderTextureCanvasesAutoBindTheEntitysSpriteAndDecalOverride()
	{
		// Freed last, the teardown releasing GPU objects through it.
		let device = scope NullDevice();
		let encoder = scope NullCommandEncoder();
		let fixture = scope UITestFixture();
		fixture.UI.EnsureRenderReady(device, 2);

		// The render managers normally come from the render subsystem; added by hand here.
		let scene = fixture.Scenes.CreateScene("world");
		scene.AddSystem<SpriteComponentManager>();
		scene.AddSystem<DecalComponentManager>();
		let canvases = scene.GetSystem<UICanvasComponentManager>();
		let sprites = scene.GetSystem<SpriteComponentManager>();
		let decals = scene.GetSystem<DecalComponentManager>();

		// One entity carries the render texture canvas AND the material components that
		// show it, which is the declarative contract: the same entity means auto bound,
		// with no scripting.
		let e = scene.CreateEntity("scoreboard");
		let document = UITestFixture.MakeDocument("<Label id=\"score\" text=\"0 : 0\"/>");
		defer delete document;
		{
			let component = canvases.Add(e);
			component.Document.SetDirect(document);
			component.RenderMode = .RenderTexture;
			component.RenderTextureWidth = 256;
			component.RenderTextureHeight = 128;
		}
		sprites.Add(e);
		decals.Add(e);

		fixture.Frame();
		fixture.UI.RenderCanvasTextures(encoder, 0);
		var canvas = canvases.Get(e);
		Test.Assert(canvas != null);
		Test.Assert(canvas.RenderTextureView != null);
		Test.Assert(sprites.Get(e).Texture == canvas.RenderTextureView);
		Test.Assert(decals.Get(e).Texture == canvas.RenderTextureView);

		// A resize recreates the target, so the view changes, which is exactly why manual
		// assignment breaks, and the binder refreshes the overrides in the same call. No
		// pointer inequality check: an allocator may legitimately hand the same address
		// back, and the CONTRACT is that the override IS the current view.
		canvas.RenderTextureWidth = 512;
		fixture.Frame();
		fixture.UI.RenderCanvasTextures(encoder, 1);
		canvas = canvases.Get(e);
		Test.Assert(canvas.RenderTextureView != null);
		Test.Assert(canvas.RenderTexture.Desc.Width == 512);
		Test.Assert(sprites.Get(e).Texture == canvas.RenderTextureView);
		Test.Assert(decals.Get(e).Texture == canvas.RenderTextureView);

		// Removing the CANVAS un binds, the target being destroyed and a stale override
		// therefore dangling. The sprite and decal components themselves survive.
		canvases.Remove(e);
		fixture.Frame();
		fixture.UI.RenderCanvasTextures(encoder, 0);
		Test.Assert(sprites.Get(e).Texture == null);
		Test.Assert(decals.Get(e).Texture == null);
	}
}
