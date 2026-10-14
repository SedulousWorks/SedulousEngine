using System;
using Sedulous.Engine.Scene;
using Sedulous.Engine.UI;
using Sedulous.Profiler;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.DefaultApp.Tests;

/// The application's profiler overlay: off until shown, then on the UI's overlay layer, the
/// profiler armed while it shows and its views reading the frames that end.
class ProfilerOverlayHostTests
{
	[Test]
	public static void OffUntilShownThenOnTheOverlayLayerArmedAndReading()
	{
		let context = scope Context();
		let scenes = context.AddSubsystem<SceneSubsystem>();
		let sceneManager = scope SceneManager();
		scenes.RegisterManager(sceneManager);
		let ui = scope UISubsystem(null);
		context.RegisterSubsystem<UISubsystem>(ui);
		context.Startup();
		defer context.Dispose();

		let profiler = scope Sedulous.Profiler.Profiler();
		let host = scope ProfilerOverlayHost(profiler);
		let before = ui.ScreenOverlayCount;
		Test.Assert(!host.Shown);
		Test.Assert(host.Overlay == null);
		Test.Assert(!profiler.Armed);

		host.Toggle(ui);
		Test.Assert(host.Shown);
		Test.Assert(host.Overlay != null);
		Test.Assert(ui.ScreenOverlayCount == before + 1);
		Test.Assert(!ui.OverlayLayerWantsInput, "the game under it keeps the pointer");
		Test.Assert(profiler.Armed);

		// A frame recorded while shown reaches its views at the next refresh.
		profiler.BeginFrame();
		Test.Assert(profiler.BeginScope("Update"));
		profiler.EndScope();
		profiler.EndFrame();
		host.Refresh();
		Test.Assert(host.Overlay.Scopes.Rows.Length == 1);
		Test.Assert(host.Overlay.Scopes.Rows[0].Name == "Update");

		host.Toggle(ui);
		Test.Assert(!host.Shown);
		Test.Assert(ui.ScreenOverlayCount == before);
		Test.Assert(!profiler.Armed);

		host.Show(ui); // shown again: the same overlay
		host.Show(ui); // once only
		Test.Assert(ui.ScreenOverlayCount == before + 1);
		host.Hide();
		Test.Assert(!profiler.Armed);
	}
}
