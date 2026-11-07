using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// A game's Engine part registering two behaviours, as a game's Load does.
class BehaviourProbePart : PluginPart
{
	public override StringView PluginId => "behaviour_probe";
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context)
	{
		let engine = context.Find<EnginePluginServices>();
		GameplayServices.AddBehaviour<Walker>(engine);
		GameplayServices.AddBehaviour<Runner>(engine);
	}
}

/// AddBehaviour contributes the behaviour's manager to every scene, and the BehaviourSystem
/// once, before the first manager; the plugin's unload takes them back out, the system last.
///
/// The contribution list is process wide, so each test clears the keys it uses first.
class GameplayServicesTests
{
	private static uint64 SystemKey => GameplayServices.SystemTypeOf<BehaviourSystem>();
	private static uint64 WalkerKey => GameplayServices.SystemTypeOf<BehaviourManager<Walker>>();
	private static uint64 RunnerKey => GameplayServices.SystemTypeOf<BehaviourManager<Runner>>();

	private static void ClearContributions()
	{
		let registry = SceneModuleContributions.Global;
		registry.Remove(RunnerKey);
		registry.Remove(WalkerKey);
		registry.Remove(SystemKey);
	}

	/// Two registrations insert three contributions, the system first and once, and none
	/// without the engine's service.
	[Test]
	public static void TheSystemIsContributedOnceBeforeTheFirstManager()
	{
		ClearContributions();
		let registry = SceneModuleContributions.Global;

		GameplayServices.AddBehaviour<Walker>(null);
		Test.Assert(!registry.Contains(SystemKey) && !registry.Contains(WalkerKey), "no service, nothing added");

		let recorded = scope List<uint64>();
		delegate void(uint64) observer = scope [&] (systemType) => { recorded.Add(systemType); };
		registry.SetRegistrationObserver(observer);
		let engine = scope EnginePluginServices();
		GameplayServices.AddBehaviour<Walker>(engine);
		GameplayServices.AddBehaviour<Runner>(engine);
		GameplayServices.AddBehaviour<Runner>(engine);
		registry.SetRegistrationObserver(null);

		Test.Assert(recorded.Count == 3, "the system once, and each manager once");
		Test.Assert(recorded[0] == SystemKey);
		Test.Assert(recorded[1] == WalkerKey);
		Test.Assert(recorded[2] == RunnerKey);

		// A scene made now has the system with both managers on it.
		let scene = scope Scene("services");
		registry.InstallAll(scene);
		let system = scene.GetSystem<BehaviourSystem>();
		Test.Assert(system != null);
		Test.Assert(scene.HasSystem<BehaviourManager<Walker>>() && scene.HasSystem<BehaviourManager<Runner>>());
		Test.Assert(system.ManagerCount == 2);
		Test.Assert(system.UpdateCount == 2);

		ClearContributions();
	}

	/// Through a plugin host: the part's Load adds them, a scene made while it is loaded has
	/// them and runs them, and the unload takes every one of them out.
	[Test]
	public static void APluginsBehavioursArriveAndLeaveWithIt()
	{
		ClearContributions();
		let manifest = scope PluginManifest();
		manifest.Id.Set("behaviour_probe");
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		let xml = manifest.Write(.. scope .());
		let probe = scope BehaviourProbePart();

		let subsystems = scope SubsystemManager();
		let engine = scope EnginePluginServices();
		{
			let host = scope PluginHost(subsystems, .Player, "0.1.0");
			Test.Assert(engine.Attach(host));
			PluginPart[1] parts = .(probe);
			Test.Assert(host.AddLinked(xml, parts) case .Ok);
			let report = scope PluginLoadReport();
			host.Load(scope StringView[]("behaviour_probe"), report);
			Test.Assert(report.Loaded.Count == 1);

			let registry = SceneModuleContributions.Global;
			Test.Assert(registry.Contains(SystemKey));
			Test.Assert(registry.Contains(WalkerKey));
			Test.Assert(registry.Contains(RunnerKey));

			LifecycleLog.Text.Clear();
			{
				let scene = scope Scene("probe");
				registry.InstallAll(scene);
				scene.GetSystem<BehaviourManager<Runner>>().Add(scene.CreateEntity("e"));
				scene.Update(1.0f / 60.0f);
			}
			Test.Assert(LifecycleLog.Text == "R:e.Enable R:e.Start R:e.Update ", LifecycleLog.Text);

			host.Unload();
			Test.Assert(!registry.Contains(RunnerKey));
			Test.Assert(!registry.Contains(WalkerKey));
			Test.Assert(!registry.Contains(SystemKey), "the system goes with the last of them");
		}
	}
}
