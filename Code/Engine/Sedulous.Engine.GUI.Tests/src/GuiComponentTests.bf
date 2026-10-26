using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.GUI;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.GUI.Tests;

/// The GUI's components through the scene format: what is authored comes back, under the keys
/// Raptor writes.
class GuiComponentTests
{
	/// `authored` written as a scene and read back into `loaded`, which has the same managers.
	private static void RoundTrip(Scene authored, Scene loaded)
	{
		let blob = scope MemoryStream();
		{
			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, authored);
			Test.Assert(writer.IsOk);
		}
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}
	}

	[Test]
	public static void ACanvasComponentRoundTripsThroughTheSceneFormat()
	{
		let document = Guid.Create();
		let sheet = Guid.Create();
		let authored = scope Scene();
		GuiScene.AddGuiSceneManagers(authored);
		let entity = authored.CreateEntity("hud");
		let a = authored.GetSystem<GuiCanvasComponentManager>().Add(entity);
		a.Document.SetId(document);
		a.Sheet.SetId(sheet);
		a.Order = 7;
		a.Visible = false;
		a.Interactive = false;
		a.ScalerMode = .ReferenceResolution;
		a.ReferenceResolution = .(1280.0f, 800.0f);
		a.RenderMode = .RenderTexture;
		a.RenderTextureWidth = 256;
		a.RenderTextureHeight = 128;
		let id = authored.GetEntityId(entity);

		let loaded = scope Scene();
		GuiScene.AddGuiSceneManagers(loaded);
		RoundTrip(authored, loaded);

		let found = loaded.FindEntity(id);
		Test.Assert(found.IsAssigned);
		let b = loaded.GetSystem<GuiCanvasComponentManager>().Get(found);
		Test.Assert(b != null);
		Test.Assert(b.Document.Id == document);
		Test.Assert(b.Sheet.Id == sheet);
		Test.Assert(b.Order == 7);
		Test.Assert(!b.Visible);
		Test.Assert(!b.Interactive);
		Test.Assert(b.ScalerMode == .ReferenceResolution);
		Test.Assert(b.ReferenceResolution.X == 1280.0f);
		Test.Assert(b.ReferenceResolution.Y == 800.0f);
		Test.Assert(b.RenderMode == .RenderTexture);
		Test.Assert(b.RenderTextureWidth == 256);
		Test.Assert(b.RenderTextureHeight == 128);
	}

	[Test]
	public static void ABillboardAndAWorldPanelRoundTripThroughTheSceneFormat()
	{
		let document = Guid.Create();
		let sheet = Guid.Create();
		let authored = scope Scene();
		GuiScene.AddGuiSceneManagers(authored);
		let entity = authored.CreateEntity("guard");
		let plate = authored.GetSystem<GuiBillboardComponentManager>().Add(entity);
		plate.Document.SetId(document);
		plate.Sheet.SetId(sheet);
		plate.Offset = .(0.0f, 2.0f, 0.5f);
		plate.Orientation = .Screen;
		plate.ScaleMode = .Distance;
		plate.ReferenceDistance = 6.0f;
		plate.MinScale = 0.5f;
		plate.MaxScale = 3.0f;
		plate.Visible = false;
		let panel = authored.GetSystem<GuiWorldPanelComponentManager>().Add(entity);
		panel.Document.SetId(document);
		panel.Sheet.SetId(sheet);
		panel.SizeMeters = .(2.0f, 1.0f);
		panel.PixelsPerMeter = 300.0f;
		panel.Interactive = false;
		panel.Visible = false;
		let id = authored.GetEntityId(entity);

		let loaded = scope Scene();
		GuiScene.AddGuiSceneManagers(loaded);
		RoundTrip(authored, loaded);

		let found = loaded.FindEntity(id);
		Test.Assert(found.IsAssigned);
		let b = loaded.GetSystem<GuiBillboardComponentManager>().Get(found);
		Test.Assert(b != null);
		Test.Assert((b.Document.Id == document) && (b.Sheet.Id == sheet));
		Test.Assert((b.Offset.Y == 2.0f) && (b.Offset.Z == 0.5f));
		Test.Assert(b.Orientation == .Screen);
		Test.Assert(b.ScaleMode == .Distance);
		Test.Assert(b.ReferenceDistance == 6.0f);
		Test.Assert((b.MinScale == 0.5f) && (b.MaxScale == 3.0f));
		Test.Assert(!b.Visible);
		let p = loaded.GetSystem<GuiWorldPanelComponentManager>().Get(found);
		Test.Assert(p != null);
		Test.Assert((p.Document.Id == document) && (p.Sheet.Id == sheet));
		Test.Assert((p.SizeMeters.X == 2.0f) && (p.SizeMeters.Y == 1.0f));
		Test.Assert(p.PixelsPerMeter == 300.0f);
		Test.Assert(!p.Interactive);
		Test.Assert(!p.Visible);
	}
}
