using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI.Null;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// Per view gizmos stay in their own view, and a keyed view still draws its scene's list.
class DebugViewIsolationTests
{
	/// The camera preview contract: an editor viewport's grid and gizmos can never bleed into
	/// a second view of the same scene.
	[Test]
	public static void EachViewportKeyGetsItsOwnStableBuffer()
	{
		let device = scope NullDevice();
		let subsystem = scope RenderSubsystem(device, 2, null);

		// Two distinct keys, which is the main editor viewport and the camera preview inset.
		int32 mainKey = 0;
		int32 previewKey = 0;

		let main = subsystem.DebugView(&mainKey);
		let preview = subsystem.DebugView(&previewKey);
		Test.Assert(main !== preview);
		Test.Assert(subsystem.DebugView(&mainKey) === main);
		Test.Assert(subsystem.DebugView(&previewKey) === preview);

		// And a keyed buffer is distinct from the shared global one.
		Test.Assert(subsystem.DebugView(&mainKey) !== subsystem.DebugGlobal);

		// Draw into the MAIN view's buffer; the preview's stays empty.
		main.DrawLine(.(0, 0, 0), .(1, 0, 0), Color(1, 1, 1, 1));
		Test.Assert(main.HasAnyDraws);
		Test.Assert(!preview.HasAnyDraws);

		// The per scene list is a THIRD, independent buffer. A keyed view draws both its own
		// list and the scene's: the either/or this replaced made a keyed view, the edit
		// viewport, silently drop every scene level debug drawing, so physics and navigation
		// were invisible there while a play session showed them.
		let world = scope Scene("debug-scene");
		let sceneDebug = subsystem.DebugScene(world);
		Test.Assert(sceneDebug !== main);
		Test.Assert(sceneDebug !== preview);
		sceneDebug.DrawLine(.(0, 0, 0), .(0, 1, 0), Color(1, 1, 1, 1));
		Test.Assert(sceneDebug.HasAnyDraws);
		// A scene draw never mutates a view list.
		Test.Assert(!preview.HasAnyDraws);
	}

	/// The plumbing behind the fix: a view carries BOTH lists, and an unkeyed one carries no
	/// view list at all.
	[Test]
	public static void AViewCarriesTheSceneAndViewListsIndependently()
	{
		let view = scope RenderView();
		int32 sceneList = 0;
		int32 viewList = 0;

		view.SetDebugScene(&sceneList);
		view.SetDebugView(&viewList);
		Test.Assert(view.DebugScene == &sceneList);
		Test.Assert(view.DebugViewList == &viewList);

		view.SetDebugView(null);
		Test.Assert(view.DebugScene == &sceneList);
		Test.Assert(view.DebugViewList == null);
	}
}
