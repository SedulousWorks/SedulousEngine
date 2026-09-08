using System;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// The post load pass reaching a component's resource references.
///
/// Loading leaves a reference unbound on purpose: binding needs a manager over the
/// database the scene came from, and the loader has no business knowing about one. This is
/// the pass that closes that, and it has to reach COMPONENTS, not only the systems'
/// settings blocks.
class ComponentResourceTests
{
	[Test]
	public static void TheResolvePassReachesEveryComponentThatHoldsReferences()
	{
		let scene = scope Scene();
		let manager = scene.AddSystem<AmmoManager>();

		let first = scene.CreateEntity("First");
		let second = scene.CreateEntity("Second");
		manager.Add(first).Rounds = 30;
		manager.Add(second).Rounds = 12;

		Test.Assert(manager.Get(first).Binds == 0, "loading leaves them unbound");

		// The pass only hands the manager through, so a database is not needed to see it arrive.
		let resources = scope ResourceManager(null);
		SceneResolve.ResolveSceneResources(scene, resources);

		Test.Assert(manager.Get(first).Binds == 1, "the pass reached the component");
		Test.Assert(manager.Get(second).Binds == 1, "and every one of them");

		// Idempotent: running it again is a re bind, not a fault.
		SceneResolve.ResolveSceneResources(scene, resources);
		Test.Assert(manager.Get(first).Binds == 2);
	}

	/// A component with NO references costs nothing: its manager does not implement the
	/// bind, so the pass walks past it.
	[Test]
	public static void AComponentWithoutReferencesIsUntouched()
	{
		let scene = scope Scene();
		let health = scene.AddSystem<HealthManager>();
		let entity = scene.CreateEntity("Plain");
		health.Add(entity).Value = 5.0f;

		// The pass only hands the manager through, so a database is not needed to see it arrive.
		let resources = scope ResourceManager(null);
		SceneResolve.ResolveSceneResources(scene, resources);

		Test.Assert(health.Get(entity).Value == 5.0f);
	}
}
