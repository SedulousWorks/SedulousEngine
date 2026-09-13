using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.UI;
using Sedulous.UI.Resource;

namespace Sedulous.Engine.UI.Tests;

/// The canvases, headless: instantiated from a document, rebuilt on a reload, kept in step
/// with the component each frame, and round tripped through the wire.
class UICanvasTests
{
	private const String cPauseMarkup = """
		<FlexLayout><Label id="title" text="Paused" /><Button id="resume-btn" text="Resume" /></FlexLayout>
		""";

	[Test]
	public static void CanvasesInstantiateReloadAndSyncVisibility()
	{
		let fixture = scope UITestFixture();
		let scene = fixture.Scenes.CreateScene("menu");
		let canvases = scene.GetSystem<UICanvasComponentManager>();
		// Installed by the scene composition rather than by hand.
		Test.Assert(canvases != null);

		let entity = scene.CreateEntity("pause");
		let canvas = canvases.Add(entity);

		let document = UITestFixture.MakeDocument(cPauseMarkup);
		defer delete document;
		canvas.Document.SetDirect(document);

		// The subsystem builds the tree.
		fixture.Frame();

		Test.Assert(canvas.Root != null, "the tree was instantiated");
		let group = canvas.Root as ViewGroup;
		Test.Assert(group != null);
		Test.Assert(group.FindByName("resume-btn") != null);

		// The tier split: a canvas parents into ITS SCENE's root, above that scene's
		// billboard layer, and the screen root holds only the global overlay layer.
		let sceneRoot = fixture.UI.SceneRoot(scene);
		Test.Assert(sceneRoot != null);
		Test.Assert(sceneRoot.ChildCount == 2, "the billboard layer and the canvas");
		Test.Assert(fixture.UI.ScreenRoot.ChildCount == 1, "the overlay layer alone");
		Test.Assert(sceneRoot.FindByName("resume-btn") != null);

		// A hot reload: a NEW document rebuilds the tree. The STRUCTURE is what proves it,
		// since comparing addresses can read as unchanged when an allocator hands the same
		// one back.
		let replacement = UITestFixture.MakeDocument(
			"""
			<FlexLayout><Label id="only" text="v2" /></FlexLayout>
			""");
		defer delete replacement;
		canvas.Document.SetDirect(replacement);

		fixture.Frame();
		Test.Assert(canvas.Root != null);
		Test.Assert((canvas.Root as ViewGroup).FindByName("only") != null, "the new tree");
		Test.Assert((canvas.Root as ViewGroup).FindByName("resume-btn") == null, "and not the old");

		// The flags flow into the live tree every frame.
		canvas.Visible = false;
		canvas.Interactive = false;
		fixture.Frame();
		Test.Assert(canvas.Root.Visibility == .Gone);
		Test.Assert(!canvas.Root.IsHitTestVisible);

		// And tearing the scene down detaches cleanly.
		fixture.Scenes.DestroyScene(scene);
		fixture.Frame();
	}

	[Test]
	public static void AnInactiveEntitysCanvasGoesAwayAndComesBack()
	{
		let fixture = scope UITestFixture();

		let scene = fixture.Scenes.CreateScene("menu");
		let canvases = scene.GetSystem<UICanvasComponentManager>();
		Test.Assert(canvases != null);

		// The canvas rides a CHILD of the entity being toggled, which is the path that
		// actually matters: activity is inherited.
		let parent = scene.CreateEntity("holder");
		let entity = scene.CreateEntity("hud");
		scene.SetParent(entity, parent);

		let canvas = canvases.Add(entity);
		let document = UITestFixture.MakeDocument(
			"""
			<FlexLayout><Label id="hp" text="100" /></FlexLayout>
			""");
		defer delete document;
		canvas.Document.SetDirect(document);

		fixture.Frame();
		Test.Assert(canvas.Root != null);
		Test.Assert(canvas.Root.Visibility == .Visible);

		// An inactive entity does not show its interface.
		scene.SetActive(parent, false);
		fixture.Frame();
		Test.Assert(canvas.Root.Visibility == .Gone);

		scene.SetActive(parent, true);
		fixture.Frame();
		Test.Assert(canvas.Root.Visibility == .Visible);

		fixture.Scenes.DestroyScene(scene);
		fixture.Frame();
	}

	[Test]
	public static void ACanvasComponentRoundTrips()
	{
		let blob = scope MemoryStream();
		Guid id = default;

		let authored = scope Scene();
		{
			let canvases = authored.AddSystem<UICanvasComponentManager>();
			let entity = authored.CreateEntity("hud");
			let canvas = canvases.Add(entity);

			canvas.Order = 7;
			canvas.Visible = false;
			canvas.Interactive = false;
			canvas.ScalerMode = .ReferenceResolution;
			canvas.ReferenceResolution = .(1280.0f, 720.0f);
			canvas.RenderMode = .RenderTexture;
			canvas.RenderTextureWidth = 256;
			canvas.RenderTextureHeight = 128;
			id = authored.GetEntityId(entity);

			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, authored);
			Test.Assert(writer.IsOk);
		}

		let loaded = scope Scene();
		let canvases = loaded.AddSystem<UICanvasComponentManager>();
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		let entity = loaded.FindEntity(id);
		Test.Assert(entity.IsAssigned);

		let canvas = canvases.Get(entity);
		Test.Assert(canvas != null);
		Test.Assert(canvas.Order == 7);
		Test.Assert(!canvas.Visible);
		Test.Assert(!canvas.Interactive);
		Test.Assert(canvas.ScalerMode == .ReferenceResolution);
		Test.Assert(canvas.ReferenceResolution.X == 1280.0f);
		Test.Assert(canvas.ReferenceResolution.Y == 720.0f);
		Test.Assert(canvas.RenderMode == .RenderTexture);
		Test.Assert(canvas.RenderTextureWidth == 256);
		Test.Assert(canvas.RenderTextureHeight == 128);
	}
}
