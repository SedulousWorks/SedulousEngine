using System;
using Sedulous.Engine.Scene;
using Sedulous.Engine.GUI;
using Sedulous.Profiler;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.DefaultApp.Tests;

/// The application's profiler overlay (on the GUI, Raptor's engine-ui-removal spec, layer 1): off
/// until shown, then on the GUI's overlay layer taking no pointer (so the layer stays passive), the
/// profiler armed while it shows and its views reading the frames that end; hidden, it leaves the
/// layer and lets the profiler go.
class ProfilerOverlayHostTests
{
	[Test]
	public static void OffUntilShownThenOnTheOverlayLayerArmedAndReading()
	{
		let context = scope Context();
		let scenes = context.AddSubsystem<SceneSubsystem>();
		let sceneManager = scope SceneManager();
		scenes.RegisterManager(sceneManager);
		let gui = scope GuiSubsystem(null);
		context.RegisterSubsystem<GuiSubsystem>(gui);
		context.Startup();
		defer context.Dispose();

		let profiler = scope Sedulous.Profiler.Profiler();
		let host = scope ProfilerOverlayHost(profiler);
		let before = gui.OverlayCount;
		Test.Assert(!host.Shown);
		Test.Assert(host.Overlay == null);
		Test.Assert(!profiler.Armed);

		host.Toggle(gui);
		Test.Assert(host.Shown);
		Test.Assert(host.Overlay != null);
		Test.Assert(gui.OverlayCount == before + 1);
		Test.Assert(host.Overlay.Parent === gui.OverlayLayer);
		Test.Assert(!host.Overlay.HitTestVisible, "the layer stays passive: the game keeps the pointer");
		Test.Assert(profiler.Armed);

		// A frame recorded while shown reaches its views at the next refresh.
		profiler.BeginFrame();
		Test.Assert(profiler.BeginScope("Update"));
		profiler.EndScope();
		profiler.EndFrame();
		host.Refresh();
		Test.Assert(host.Overlay.Scopes.Length == 1);
		Test.Assert(host.Overlay.Scopes[0].Name == "Update");

		host.Toggle(gui);
		Test.Assert(!host.Shown);
		Test.Assert(gui.OverlayCount == before);
		Test.Assert(!profiler.Armed);

		host.Show(gui); // shown again: the same overlay
		host.Show(gui); // once only
		Test.Assert(gui.OverlayCount == before + 1);
		host.Hide();
		Test.Assert(!profiler.Armed);
	}
}
