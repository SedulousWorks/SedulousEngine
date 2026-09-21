using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.DefaultApp.Integration.Tests;

/// The client side net spawn resolver, against a REAL content database.
///
/// This is the body a replicated spawn runs: a prefab guid arrives over the wire, and the
/// resolver has to turn it into a live entity in the scene the endpoint replicates. The
/// WIRING (that the factory reaches each endpoint and survives a reconnect) and the
/// handler CONTRACT (with a stand in lambda) are covered elsewhere; this is the body
/// itself, which was once a stub answering no entity, so a replicated spawn was silently
/// inert.
///
/// Every failure path matters as much as the success one, because each answers the same
/// unassigned handle and none of them logs: a spawn that quietly produces nothing is the
/// exact symptom this suite exists to attribute.
static class SpawnResolverTests
{
	/// Builds a two entity prefab and stores it, answering its guid.
	private static Guid StoreTurretPrefab(SpawnContentFixture fixture)
	{
		let template = scope Scene("turret");
		let root = template.CreateEntity("Turret");
		let barrel = template.CreateEntity("Barrel");
		template.SetParent(barrel, root);

		let instance = fixture.Database.RootGroup.CreateInstance("turret",
			SpawnContentFixture.PrefabTypeName);
		Test.Assert(SceneStorage.SavePrefab(template, instance) case .Ok, "the prefab stored");
		return instance.Id;
	}

	[Test]
	public static void AStoredPrefabResolvesIntoALiveEntity()
	{
		let fixture = scope SpawnContentFixture("scratch_spawn_resolver");
		let prefabId = StoreTurretPrefab(fixture);

		let level = scope Scene("level");
		let root = DefaultApplication.ResolveNetworkPrefab(fixture.Database, null, level,
			prefabId);

		Test.Assert(root.IsAssigned, "the resolver produced an entity");
		Test.Assert(level.IsValid(root), "and it is alive in the scene it was asked for");

		// The whole subtree, not just the root: a prefab that spawns its root and drops its
		// children would pass an IsAssigned check and be wrong on screen.
		Test.Assert(level.GetChildCount(root) == 1,
			scope $"the child came with it, got {level.GetChildCount(root)}");
	}

	[Test]
	public static void ResolvingTwiceProducesTwoIndependentEntities()
	{
		// A replicated spawn arrives once per networked instance, so the second must not
		// alias the first: the ids are freshly assigned per spawn, which is what lets
		// replication address them separately.
		let fixture = scope SpawnContentFixture("scratch_spawn_resolver_twice");
		let prefabId = StoreTurretPrefab(fixture);

		let level = scope Scene("level");
		let first = DefaultApplication.ResolveNetworkPrefab(fixture.Database, null, level,
			prefabId);
		let second = DefaultApplication.ResolveNetworkPrefab(fixture.Database, null, level,
			prefabId);

		Test.Assert(first.IsAssigned && second.IsAssigned, "both spawned");
		Test.Assert(first != second, "and they are distinct entities, not one aliased twice");
		Test.Assert(level.IsValid(first) && level.IsValid(second), "both are alive");
	}

	[Test]
	public static void WithoutAContentDatabaseNothingSpawns()
	{
		// The app may never have been handed one. No entity, rather than half of one.
		let level = scope Scene("level");
		let root = DefaultApplication.ResolveNetworkPrefab(null, null, level, Guid());

		Test.Assert(!root.IsAssigned, "a null database resolved to nothing");
		Test.Assert(level.EntityCount == 0, "and left the scene untouched");
	}

	[Test]
	public static void AnUnknownPrefabIdSpawnsNothing()
	{
		// The wire named something this client's content does not carry, which is a version
		// skew between peers rather than a fault here.
		let fixture = scope SpawnContentFixture("scratch_spawn_resolver_unknown");
		let level = scope Scene("level");

		let root = DefaultApplication.ResolveNetworkPrefab(fixture.Database, null, level,
			Guid());

		Test.Assert(!root.IsAssigned, "an unknown id resolved to nothing");
		Test.Assert(level.EntityCount == 0, "and left the scene untouched");
	}

	[Test]
	public static void AnInstanceWithNoSceneStreamSpawnsNothing()
	{
		// The instance EXISTS but carries no "scene" payload, which is what a half written
		// or wrong typed asset looks like. Distinct from the unknown id case: this one gets
		// past the database lookup and fails at the stream.
		let fixture = scope SpawnContentFixture("scratch_spawn_resolver_nostream");
		let instance = fixture.Database.RootGroup.CreateInstance("empty",
			SpawnContentFixture.PrefabTypeName);

		let level = scope Scene("level");
		let root = DefaultApplication.ResolveNetworkPrefab(fixture.Database, null, level,
			instance.Id);

		Test.Assert(!root.IsAssigned, "an instance with no scene stream resolved to nothing");
		Test.Assert(level.EntityCount == 0, "and left the scene untouched");
	}
}
