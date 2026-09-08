using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// What an inspector asks to mark a field as overridden.
///
/// It asks the same question saving does, so what the inspector shows and what the file
/// records cannot disagree.
class PrefabOverrideQueryTests
{
	private static Guid PrefabId => .(0xABCD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	private static EntityHandle SpawnTurret(Scene scene, out HealthManager manager)
	{
		let template = scope Scene();
		let templateManager = template.AddSystem<HealthManager>();
		let root = template.CreateEntity("Turret");
		template.SetParent(template.CreateEntity("Barrel"), root);
		templateManager.Add(root).Value = 200.0f;

		let payload = scope MemoryStream();
		Test.Assert(PrefabCapture.Capture(template, root, payload, .Binary) case .Ok);
		payload.Seek(0, .Begin);

		manager = scene.AddSystem<HealthManager>();
		return PrefabSpawn.Spawn(scene, payload, PrefabId);
	}

	[Test]
	public static void AMemberIsFoundAndAPlainEntityIsNot()
	{
		let scene = scope Scene();
		let spawned = SpawnTurret(scene, var manager);
		let plain = scene.CreateEntity("Plain");

		Test.Assert(PrefabOverrides.FindMember(scene, scene.GetEntityId(spawned), var member));
		Test.Assert(member.State != null);
		Test.Assert(member.State.PrefabId == PrefabId);

		Test.Assert(PrefabOverrides.FindMember(scene, scene.GetEntityId(scene.GetFirstChild(spawned)),
			var child), "a non root member is a member too");
		Test.Assert(child.MemberIndex != member.MemberIndex);

		Test.Assert(!PrefabOverrides.FindMember(scene, scene.GetEntityId(plain), var none));
	}

	/// All three ways a component can differ read as an override. An inspector noticing
	/// only the first would show a field as clean after somebody deleted it.
	[Test]
	public static void EveryKindOfDifferenceReadsAsAnOverride()
	{
		let scene = scope Scene();
		let spawned = SpawnTurret(scene, var manager);
		let barrel = scene.GetFirstChild(spawned);

		Test.Assert(PrefabOverrides.FindMember(scene, scene.GetEntityId(spawned), var root));
		Test.Assert(PrefabOverrides.FindMember(scene, scene.GetEntityId(barrel), var member));

		// Untouched.
		Test.Assert(!PrefabOverrides.IsComponentOverridden(scene, root, manager));
		Test.Assert(!PrefabOverrides.IsTransformOverridden(scene, root));

		// Modified.
		manager.Get(spawned).Value = 1.0f;
		Test.Assert(PrefabOverrides.IsComponentOverridden(scene, root, manager));

		// Added, where the template gave none.
		Test.Assert(!PrefabOverrides.IsComponentOverridden(scene, member, manager));
		manager.Add(barrel);
		Test.Assert(PrefabOverrides.IsComponentOverridden(scene, member, manager));

		// Removed, where the template gave one.
		manager.RemoveComponent(spawned);
		Test.Assert(PrefabOverrides.IsComponentOverridden(scene, root, manager));

		// And a move.
		var moved = Transform();
		moved.Position = .(1, 2, 3);
		scene.SetLocalTransform(barrel, moved);
		Test.Assert(PrefabOverrides.IsTransformOverridden(scene, member));
	}

	/// The query and the save agree: what reads as overridden is what gets written.
	[Test]
	public static void TheQueryAgreesWithWhatIsSaved()
	{
		let scene = scope Scene();
		let spawned = SpawnTurret(scene, var manager);
		manager.Get(spawned).Value = 77.0f;

		Test.Assert(PrefabOverrides.FindMember(scene, scene.GetEntityId(spawned), var member));
		Test.Assert(PrefabOverrides.IsComponentOverridden(scene, member, manager));

		let delta = PrefabDeltas.Compute(scene, member.State);
		defer delete delta;
		Test.Assert(delta.ComponentOps.Count == 1, "the save writes exactly what the query reports");
		Test.Assert(delta.ComponentOps[0].Op == .Modify);
	}
}
