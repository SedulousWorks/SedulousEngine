using System;
using System.Collections;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// The declarative assembly layer: the time chain, the topological build, the observers,
/// the manager registry and the runtime contributions.
class SceneCompositionTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	/// One FrameTime carries the whole chain, which is what stops the terms being hand
	/// multiplied in several places and drifting apart.
	[Test]
	public static void FrameTimeFoldsTheWholeChain()
	{
		let identity = FrameTime(0.016f);
		Test.Assert(Near(identity.RawDelta, 0.016f));
		Test.Assert(Near(identity.ContextScale, 1.0f));
		Test.Assert(Near(identity.GroupScale, 1.0f));
		Test.Assert(Near(identity.SceneDelta, 0.016f), "identity terms change nothing");

		let scaled = FrameTime(0.016f, 2.0f, 0.5f, 0.25f);
		Test.Assert(Near(scaled.ContextDelta, 0.032f), "host by context");
		Test.Assert(Near(scaled.SceneDelta, 0.004f), "and then group and scene");
	}

	[Test]
	public static void BuildSortsModulesByTheirDependencies()
	{
		CompositionProbes.Reset();

		var moduleA = SceneModule("a", => CompositionProbes.InstallA, => CompositionProbes.ReflectA);
		var dependencies = SceneModule*[1](&moduleA);
		var moduleB = SceneModule("b", => CompositionProbes.InstallB, => CompositionProbes.ReflectB,
			dependencies);

		// Deliberately handed in REVERSED, so a build that merely preserved input order
		// would fail this.
		var modules = SceneModule*[2](&moduleB, &moduleA);
		let composition = SceneComposition.Build(modules);
		defer delete composition;
		Test.Assert(composition.ModuleCount == 2);

		let scene = scope Scene("probe");
		composition.Instantiate(scene);
		Test.Assert(CompositionProbes.InstallOrder == "ab");

		composition.RegisterReflection();
		Test.Assert(CompositionProbes.Reflections == 2);
	}

	/// A dependency that is not in the set is OUT OF SCOPE for this composition, not
	/// missing from it, so it is treated as satisfied rather than blocking the build.
	[Test]
	public static void ADependencyOutsideTheSetIsTreatedAsSatisfied()
	{
		CompositionProbes.Reset();

		var moduleA = SceneModule("a", => CompositionProbes.InstallA, => CompositionProbes.ReflectA);
		var dependencies = SceneModule*[1](&moduleA);
		var moduleB = SceneModule("b", => CompositionProbes.InstallB, => CompositionProbes.ReflectB,
			dependencies);

		var modules = SceneModule*[1](&moduleB);
		let composition = SceneComposition.Build(modules);
		defer delete composition;
		Test.Assert(composition.ModuleCount == 1);

		let scene = scope Scene("probe");
		composition.Instantiate(scene);
		Test.Assert(CompositionProbes.InstallOrder == "b");
	}

	/// A CYCLE must not hang the build. It is broken loudly instead: every module is still
	/// emitted exactly once, one of them out of order, and the log says which.
	[Test]
	public static void ADependencyCycleDoesNotHangTheBuild()
	{
		CompositionProbes.Reset();

		// Built through indirection, because at x's construction y does not exist yet.
		var xDependencies = SceneModule*[1](null);
		var yDependencies = SceneModule*[1](null);
		var x = SceneModule("x", => CompositionProbes.InstallA, null, xDependencies);
		var y = SceneModule("y", => CompositionProbes.InstallB, null, yDependencies);
		xDependencies[0] = &y;
		yDependencies[0] = &x;

		var modules = SceneModule*[2](&x, &y);
		let composition = SceneComposition.Build(modules);
		defer delete composition;
		Test.Assert(composition.ModuleCount == 2);

		let scene = scope Scene("probe");
		composition.Instantiate(scene);
		Test.Assert(CompositionProbes.InstallOrder.Length == 2, "every module, exactly once");
	}

	/// A module with no install is a reflection only module, which is legal: it declares
	/// types without adding a system.
	[Test]
	public static void AModuleWithNoInstallIsSkippedSafely()
	{
		var moduleNoInstall = SceneModule("meta", null, => CompositionProbes.ReflectA);
		var modules = SceneModule*[1](&moduleNoInstall);
		let composition = SceneComposition.Build(modules);
		defer delete composition;

		let scene = scope Scene("probe");
		composition.Instantiate(scene);

		CompositionProbes.Reset();
		composition.RegisterReflection();
		Test.Assert(CompositionProbes.Reflections == 1);
	}

	/// The composition OWNS its module copies, so a caller may build one from modules that
	/// live on the stack and then go away.
	///
	/// The regression this pins: the first version stored the caller's pointers and
	/// dereferenced a dead stack module at instantiation. One compiler caught it and the
	/// other passed on stack layout luck, which is the worst way to find out.
	[Test]
	public static void ACompositionOwnsItsModuleCopies()
	{
		CompositionProbes.Reset();

		SceneComposition composition;
		{
			var localA = SceneModule("a", => CompositionProbes.InstallA, => CompositionProbes.ReflectA);
			var dependencies = SceneModule*[1](&localA);
			var localB = SceneModule("b", => CompositionProbes.InstallB, => CompositionProbes.ReflectB,
				dependencies);
			var modules = SceneModule*[2](&localB, &localA);
			composition = SceneComposition.Build(modules);
		}
		// Both modules and the dependency array are gone by here.
		defer delete composition;

		Test.Assert(composition.ModuleCount == 2);

		let scene = scope Scene("lifetime");
		composition.Instantiate(scene);
		Test.Assert(CompositionProbes.InstallOrder == "ab", "the sorted order survived the copy");

		composition.RegisterReflection();
		Test.Assert(CompositionProbes.Reflections == 2);
	}

	[Test]
	public static void ObserversFireAtTheirStageLowestOrderFirst()
	{
		let registry = scope SceneRegistry();
		let a = scope RecordingObserver('a', 10);
		let b = scope RecordingObserver('b', -10);

		registry.AddObserver(a, .Destroying);
		registry.AddObserver(b, .Destroying);
		// Registering the same pair again must not deliver twice.
		registry.AddObserver(a, .Destroying);

		let scene = scope Scene("s");
		CompositionProbes.Reset();
		registry.Notify(.Destroying, scene);

		Test.Assert(a.Destroying == 1);
		Test.Assert(b.Destroying == 1);
		Test.Assert(CompositionProbes.ObserverOrder == "ba", "lower Order ran first");

		// A different stage does not reach observers registered for this one.
		registry.Notify(.SystemsReady, scene);
		Test.Assert(a.Ready == 0);
		Test.Assert(b.Ready == 0);

		registry.RemoveObserver(a);
		CompositionProbes.ObserverOrder.Clear();
		registry.Notify(.Destroying, scene);
		Test.Assert(a.Destroying == 1, "unregistered");
		Test.Assert(b.Destroying == 2);
		Test.Assert(CompositionProbes.ObserverOrder == "b");
	}

	[Test]
	public static void TheManagerRegistryDedupsAndSweepsEveryScene()
	{
		let registry = scope SceneRegistry();
		let first = scope SceneManager();
		let second = scope SceneManager();

		registry.RegisterManager(first);
		registry.RegisterManager(first);
		registry.RegisterManager(second);
		Test.Assert(registry.ManagerCount == 2, "registering twice adds once");

		first.CreateScene("A");
		first.CreateScene("B");
		second.CreateScene("C");

		int sweeps = 0;
		registry.ForEachScene(scope [&](scene) => { sweeps++; });
		Test.Assert(sweeps == 3);

		registry.UnregisterManager(first);
		Test.Assert(registry.ManagerCount == 1);

		sweeps = 0;
		registry.ForEachScene(scope [&](scene) => { sweeps++; });
		Test.Assert(sweeps == 1);
	}

	[Test]
	public static void TheLaneFanOutTicksEveryRegisteredManagersScenes()
	{
		let registry = scope SceneRegistry();
		let first = scope SceneManager();
		let second = scope SceneManager();
		registry.RegisterManager(first);
		registry.RegisterManager(second);

		let a = first.CreateScene("A");
		let b = second.CreateScene("B");
		a.SetFixedTiming(1.0f / 60.0f, 4);
		b.SetFixedTiming(1.0f / 60.0f, 4);
		let probeA = a.AddSystem<DeltaProbeSystem>();
		let probeB = b.AddSystem<DeltaProbeSystem>();

		registry.BeginFrame(FrameTime(1.0f / 60.0f, 1.0f, 1.0f, 1.0f, 1.0f / 60.0f));
		registry.Update(FrameTime(1.0f / 60.0f));

		Test.Assert(probeA.FixedSteps == 1);
		Test.Assert(probeB.FixedSteps == 1);
		Test.Assert(Near(probeA.LastUpdate, 1.0f / 60.0f));
		Test.Assert(Near(probeB.LastUpdate, 1.0f / 60.0f));
	}

	/// The full chain, checked where it lands: the bridge builds ONE FrameTime carrying
	/// host and context, the manager folds in the group term and the scene its own.
	[Test]
	public static void TheManagerLanesFoldTheFullChainFromOneFrameTime()
	{
		let manager = scope SceneManager();
		manager.TimeScale = 0.5f;

		let scene = manager.CreateScene("chain");
		scene.Start();
		scene.SetSimulationEnabled(true);
		scene.TimeScale = 0.5f;
		let probe = scene.AddSystem<DeltaProbeSystem>();

		let time = FrameTime(0.032f, 0.5f, 1.0f, 1.0f, 1.0f / 250.0f);
		manager.BeginFrame(time);
		manager.Update(time);

		// 0.032 by 0.5 context by 0.5 group by 0.5 scene.
		Test.Assert(Near(probe.LastUpdate, 0.004f));
		// Four milliseconds of scene time at a four millisecond step is exactly one.
		Test.Assert(probe.FixedSteps == 1);
		Test.Assert(Near(scene.FixedTimeStep, 1.0f / 250.0f), "seeded from the lane's configuration");
	}
}
