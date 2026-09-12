using System;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Engine.Scene;

namespace Sedulous.Engine.Scene.Tests;

/// The Context level scene driver: an owner registers its OWN manager, the subsystem
/// assembles every scene from the composition, fans the observer stages, and ticks each
/// manager on the Context lane.
class SceneSubsystemTests
{
	/// The module every case composes from, pointing at the shared install.
	private static SceneModule RenderModule() =>
		SceneModule("render", => CompositionProbes.InstallRenderManagers, null);

	[Test]
	public static void TheCompositionAssemblesASceneAndReadyObserversThenWire()
	{
		let context = scope Context();
		let scenes = context.AddSubsystem<SceneSubsystem>();
		let render = context.AddSubsystem<FakeRenderSubsystem>();
		context.Startup(); // OnReady is where the observer registers

		var module = RenderModule();
		var modules = SceneModule*[1](&module);
		scenes.SetComposition(SceneComposition.Build(modules));

		// The OWNER creates the manager: there is no shared default.
		let manager = scope SceneManager();
		scenes.RegisterManager(manager);

		let level = manager.CreateScene("level");
		Test.Assert(level != null);
		Test.Assert(level.GetSystem<RenderSceneSystem>() != null, "the composition installed it");
		Test.Assert(render.Ready == 1, "SystemsReady fired after assembly");
		Test.Assert(render.Destroyed == 0);
		Test.Assert(manager.ActiveScenes.Length == 1);

		scenes.UnregisterManager(manager);
		context.Shutdown();
	}

	[Test]
	public static void TheSubsystemTicksItsScenesEachContextUpdate()
	{
		let context = scope Context();
		let scenes = context.AddSubsystem<SceneSubsystem>();
		context.Startup();

		var module = RenderModule();
		var modules = SceneModule*[1](&module);
		scenes.SetComposition(SceneComposition.Build(modules));

		let manager = scope SceneManager();
		scenes.RegisterManager(manager);

		let level = manager.CreateScene();
		let system = level.GetSystem<RenderSceneSystem>();
		Test.Assert(system != null);

		context.Update(0.016f);
		context.Update(0.016f);
		Test.Assert(system.Ticks == 2);

		scenes.UnregisterManager(manager);
		context.Shutdown();
	}

	[Test]
	public static void DestroyingASceneFiresDestroyingAndDropsItFromTheActiveList()
	{
		let context = scope Context();
		let scenes = context.AddSubsystem<SceneSubsystem>();
		let render = context.AddSubsystem<FakeRenderSubsystem>();
		context.Startup();

		var module = RenderModule();
		var modules = SceneModule*[1](&module);
		scenes.SetComposition(SceneComposition.Build(modules));

		let manager = scope SceneManager();
		scenes.RegisterManager(manager);

		let a = manager.CreateScene("a");
		let b = manager.CreateScene("b");
		Test.Assert(manager.ActiveScenes.Length == 2);
		Test.Assert(render.Ready == 2);

		manager.DestroyScene(a);
		Test.Assert(render.Destroyed == 1);
		Test.Assert(manager.ActiveScenes.Length == 1);
		Test.Assert(manager.GetScene("a") == null);
		Test.Assert(manager.GetScene("b") == b);

		scenes.UnregisterManager(manager);
		context.Shutdown();
	}

	/// Per scene time: a scale isolates one scene, and a pause stops it without the other.
	[Test]
	public static void SceneScalesIsolateAndAPauseStopsOnlyItsOwnScene()
	{
		let context = scope Context();
		let scenes = context.AddSubsystem<SceneSubsystem>();
		context.Startup();

		let manager = scope SceneManager();
		scenes.RegisterManager(manager);

		let normal = manager.CreateScene("normal");
		let slow = manager.CreateScene("slow");
		let normalProbe = normal.AddSystem<TimeProbeSystem>();
		let slowProbe = slow.AddSystem<TimeProbeSystem>();
		slow.TimeScale = 0.5f;

		// Driven through the REAL lanes: BeginFrame steps, Update ticks.
		for (int i < 60)
		{
			context.BeginFrame(1.0f / 60.0f);
			context.Update(1.0f / 60.0f);
		}
		Test.Assert(normalProbe.FixedSteps == 60);
		Test.Assert(slowProbe.FixedSteps == 30, "half speed");
		Test.Assert(Math.Abs(normalProbe.AccumulatedUpdate - 1.0f) < 0.001f);
		Test.Assert(Math.Abs(slowProbe.AccumulatedUpdate - 0.5f) < 0.001f);

		// Paused through its own scale: the other keeps stepping.
		slow.TimeScale = 0.0f;
		let slowBefore = slowProbe.FixedSteps;
		for (int i < 30)
		{
			context.BeginFrame(1.0f / 60.0f);
			context.Update(1.0f / 60.0f);
		}
		Test.Assert(slowProbe.FixedSteps == slowBefore, "frozen");
		Test.Assert(normalProbe.FixedSteps == 90, "unaffected");
		Test.Assert(Math.Abs(slowProbe.LastUpdateDelta) < 0.001f);

		// The Context scale still multiplies on top of the scene scales.
		slow.TimeScale = 1.0f;
		context.TimeScale = 2.0f;
		for (int i < 30)
		{
			context.BeginFrame(1.0f / 60.0f);
			context.Update((1.0f / 60.0f) * context.TimeScale); // the host pre scales Update
		}
		Test.Assert(normalProbe.FixedSteps == 150, "thirty frames of two steps");
		Test.Assert(slowProbe.FixedSteps == slowBefore + 60);

		scenes.UnregisterManager(manager);
		context.Shutdown();
	}

	/// The fixed alpha is the scene's OWN leftover fraction, not the context's.
	[Test]
	public static void TheFixedAlphaIsTheScenesOwnLeftover()
	{
		let context = scope Context();
		let scenes = context.AddSubsystem<SceneSubsystem>();
		context.Startup();

		let manager = scope SceneManager();
		scenes.RegisterManager(manager);

		let scene = manager.CreateScene("alpha");
		scene.SetFixedTiming(1.0f / 60.0f, 4);

		// A step and a half: one fires, half remains.
		context.BeginFrame(1.5f / 60.0f);
		Test.Assert(Math.Abs(scene.FixedAlpha - 0.5f) < 0.01f);

		// Three quarters more: the second fires, a quarter remains.
		context.BeginFrame(0.75f / 60.0f);
		Test.Assert(Math.Abs(scene.FixedAlpha - 0.25f) < 0.05f);

		scenes.UnregisterManager(manager);
		context.Shutdown();
	}
}
