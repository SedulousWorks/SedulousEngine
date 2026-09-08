using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// Modules a plugin contributes at RUNTIME.
///
/// The contribution list is process wide, so each test clears its own key first: sharing
/// state between tests is exactly the failure these would otherwise cause each other.
class SceneContributionTests
{
	private static uint64 ContributedSystemType
	{
		get
		{
			let name = scope String();
			typeof(ContributedSystem).GetFullName(name);
			return TypeIdOf(name);
		}
	}

	private static SceneModuleContribution MakeContribution()
	{
		var contribution = SceneModuleContribution();
		contribution.Id = "contrib";
		contribution.Install = => CompositionProbes.InstallContribution;
		contribution.SystemType = ContributedSystemType;
		return contribution;
	}

	/// A scene composed AFTER a contribution gets its system through the tail of every
	/// instantiation, and one composed after it is withdrawn does not.
	[Test]
	public static void InstantiateAppendsContributedSystemsAndRemoveWithdrawsThem()
	{
		let registry = SceneModuleContributions.Global;
		registry.Remove(ContributedSystemType);

		let recorded = scope List<uint64>();
		delegate void(uint64) observer = scope [&](systemType) => { recorded.Add(systemType); };
		registry.SetRegistrationObserver(observer);

		registry.Add(MakeContribution());
		// Idempotent by system type: no second insert, and so no second record.
		registry.Add(MakeContribution());
		registry.SetRegistrationObserver(null);

		Test.Assert(recorded.Count == 1);
		Test.Assert(recorded[0] == ContributedSystemType);
		Test.Assert(registry.Contains(ContributedSystemType));

		var moduleA = SceneModule("a", => CompositionProbes.InstallA, => CompositionProbes.ReflectA);
		var modules = SceneModule*[1](&moduleA);
		let composition = SceneComposition.Build(modules);
		defer delete composition;

		let scene = scope Scene("contrib-new");
		composition.Instantiate(scene);
		Test.Assert(scene.HasSystem<ContributedSystem>());
		Test.Assert(scene.GetSystem<ContributedSystem>().Settings.Value == 7);

		registry.Remove(ContributedSystemType);
		Test.Assert(!registry.Contains(ContributedSystemType));

		let later = scope Scene("contrib-after-remove");
		composition.Instantiate(later);
		Test.Assert(!later.HasSystem<ContributedSystem>());
	}

	/// A scene ALREADY ALIVE gains the system when the contribution arrives and loses it
	/// when the contribution goes.
	///
	/// The removal order is what matters: the system dies while the code that built it is
	/// still mapped, which is the whole reason the withdrawal happens before the plugin's
	/// registrations reverse.
	[Test]
	public static void ALiveSceneGainsTheSystemOnAddAndLosesItOnRemove()
	{
		let registry = SceneModuleContributions.Global;
		registry.Remove(ContributedSystemType);

		let live = scope Scene("contrib-live");
		let liveScenes = scope List<Scene>();
		liveScenes.Add(live);

		delegate void(delegate void(Scene)) sink = scope [&](visit) =>
		{
			for (let scene in liveScenes)
				visit(scene);
		};
		registry.SetLiveSceneSink(sink);

		registry.Add(MakeContribution());
		Test.Assert(live.HasSystem<ContributedSystem>(), "applied to the already alive scene");

		registry.Remove(ContributedSystemType);
		Test.Assert(!live.HasSystem<ContributedSystem>(), "and withdrawn from it");

		registry.SetLiveSceneSink(null);
	}

	/// Removing a system DESTROYS it, and every lookup forgets it. A manager's pool dies
	/// with it, which is what makes unloading the code behind it safe.
	[Test]
	public static void RemoveSystemDestroysItAndEveryLookupForgetsIt()
	{
		let scene = scope Scene("remove-system");
		let system = scene.AddSystem<ContributedSystem>();
		Test.Assert(system != null);
		Test.Assert(scene.Systems.Length == 1);

		Test.Assert(scene.RemoveSystem<ContributedSystem>());
		Test.Assert(!scene.HasSystem<ContributedSystem>());
		Test.Assert(scene.GetSystem<ContributedSystem>() == null);
		Test.Assert(scene.Systems.Length == 0);

		Test.Assert(!scene.RemoveSystem<ContributedSystem>(), "removing again says so rather than faulting");
	}
}
