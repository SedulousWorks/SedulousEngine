using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Editor.Camera;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// A scene page's overlays drawn into a debug list of the test's own.
class SceneOverlaysTests
{
	[Test]
	public static void TheEntityTheAnimationPanelPosesIsMarkedASphereAndPreviewOverIt()
	{
		let scene = scope Sedulous.Scene.Scene("overlays");
		let e = scene.CreateEntity("Door");
		scene.SetLocalPosition(e, .(2.0f, 1.0f, 0.0f));
		scene.UpdateTransforms();
		let camera = scope EditorCamera();
		let overlays = scope SceneOverlays();
		overlays.Settings.ShowGrid = false;
		var frame = SceneOverlayFrame();
		frame.Scene = scene;
		frame.Camera = camera;
		let plain = scope DebugDraw();
		overlays.Draw(plain, frame);
		Test.Assert(plain.TextCommands3D.IsEmpty);

		frame.Previewed = scene.GetEntityId(e);
		let marked = scope DebugDraw();
		overlays.Draw(marked, frame);
		Test.Assert(marked.TextCommands3D.Length == 1);
		let text = marked.TextCommands3D[0];
		Test.Assert(Math.Abs(text.WorldPosition.X - 2.0f) < 0.001f);
		Test.Assert(Math.Abs(text.WorldPosition.Y - 1.0f) < 0.001f);
		Test.Assert(StringView((char8*)marked.TextChars.Ptr + text.TextStart, text.TextLength) == "preview");
		Test.Assert(marked.OverlayLineVertices.Length > plain.OverlayLineVertices.Length);
	}
}
