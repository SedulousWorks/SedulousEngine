using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// Reverting an instance, and carrying a template edit out to every instance of it.
///
/// The bargain a prefab makes: change the template and every instance follows, EXCEPT
/// where somebody deliberately changed an instance. These are the tests that the exception
/// holds, because a rebuild that quietly discarded a user's work would make the feature
/// unusable.
class PrefabRebuildTests
{
	private static Guid PrefabId => .(0xABCD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	/// The template: a turret with a barrel and health on the root. `health` sets what the
	/// template says, so a test can capture a SECOND, edited version of it.
	private static void CapturePayload(MemoryStream payload, float health = 200.0f,
		StringView rootName = "Turret")
	{
		let template = scope Scene();
		let manager = template.AddSystem<HealthManager>();
		let root = template.CreateEntity(rootName);
		let barrel = template.CreateEntity("Barrel");
		template.SetParent(barrel, root);
		manager.Add(root).Value = health;

		Test.Assert(PrefabCapture.Capture(template, root, payload, .Binary) case .Ok);
		payload.Seek(0, .Begin);
	}

	private static void CopyBytes(MemoryStream payload, List<uint8> outBytes)
	{
		outBytes.Clear();
		outBytes.AddRange(payload.Bytes);
	}

	/// Reverting drops what was changed and keeps where it was PUT: an instance's placement
	/// and its position among its siblings are properties of the placing, not of the edit.
	[Test]
	public static void RevertingDropsOverridesAndKeepsThePlacement()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);
		let bytes = scope List<uint8>();
		CopyBytes(payload, bytes);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let host = scene.CreateEntity("Host");
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId, host);
		let rootId = scene.GetEntityId(spawned);

		var placed = Transform();
		placed.Position = .(3, 4, 5);
		scene.SetLocalTransform(spawned, placed);
		manager.Get(spawned).Value = 1.0f;

		Test.Assert(PrefabRebuild.Revert(scene, rootId, bytes));

		let reverted = scene.FindEntity(rootId);
		Test.Assert(reverted.IsAssigned, "it kept its id");
		Test.Assert(manager.Get(reverted).Value == 200.0f, "the override is gone");
		Test.Assert(scene.GetLocalTransform(reverted).Position.X == 3.0f, "the placement stayed");
		Test.Assert(scene.GetParent(reverted) == host, "and so did its parent");
	}

	/// A template edit reaches an instance that was never customised.
	[Test]
	public static void ATemplateEditReachesAnUntouchedInstance()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		Test.Assert(manager.Get(spawned).Value == 200.0f);

		// The template changes.
		let edited = scope MemoryStream();
		CapturePayload(edited, 500.0f);
		let editedBytes = scope List<uint8>();
		CopyBytes(edited, editedBytes);

		Test.Assert(PrefabRebuild.Rebuild(scene, PrefabId, editedBytes) == 1);

		let root = scene.FindEntityByName("Turret");
		Test.Assert(root.IsAssigned);
		Test.Assert(manager.Get(root).Value == 500.0f, "the instance followed the template");
	}

	/// And it does NOT reach what somebody deliberately changed. This is the whole bargain.
	[Test]
	public static void ATemplateEditDoesNotOverwriteAnOverride()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let first = PrefabSpawn.Spawn(scene, payload, PrefabId);
		payload.Seek(0, .Begin);
		let second = PrefabSpawn.Spawn(scene, payload, PrefabId);

		// One of them is customised.
		manager.Get(first).Value = 42.0f;
		let firstId = scene.GetEntityId(first);
		let secondId = scene.GetEntityId(second);

		let edited = scope MemoryStream();
		CapturePayload(edited, 500.0f);
		let editedBytes = scope List<uint8>();
		CopyBytes(edited, editedBytes);

		Test.Assert(PrefabRebuild.Rebuild(scene, PrefabId, editedBytes) == 2);

		Test.Assert(manager.Get(scene.FindEntity(firstId)).Value == 42.0f,
			"the customised instance kept what somebody chose");
		Test.Assert(manager.Get(scene.FindEntity(secondId)).Value == 500.0f,
			"the untouched one followed the template");
	}

	/// A rebuild keeps every instance's identity, so the rest of the scene does not have to
	/// be told that anything happened.
	[Test]
	public static void ARebuildKeepsTheInstancesIdentity()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let rootId = scene.GetEntityId(spawned);
		let barrelId = scene.GetEntityId(scene.GetFirstChild(spawned));

		let edited = scope MemoryStream();
		CapturePayload(edited, 500.0f);
		let editedBytes = scope List<uint8>();
		CopyBytes(edited, editedBytes);

		PrefabRebuild.Rebuild(scene, PrefabId, editedBytes);

		Test.Assert(scene.FindEntity(rootId).IsAssigned, "the root kept its id");
		Test.Assert(scene.FindEntity(barrelId).IsAssigned, "and so did the member");
	}

	/// A plain entity somebody parented under an instance SURVIVES a rebuild.
	///
	/// It is not part of the template, and destroying a member destroys its whole subtree,
	/// so without rescuing it a template edit would silently eat the user's own content.
	[Test]
	public static void AUserEntityUnderAnInstanceSurvivesARebuild()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let barrel = scene.GetFirstChild(spawned);

		// The user hangs something of their own off a member.
		let attachment = scene.CreateEntity("Scope");
		scene.SetParent(attachment, barrel);
		let attachmentId = scene.GetEntityId(attachment);

		let edited = scope MemoryStream();
		CapturePayload(edited, 500.0f);
		let editedBytes = scope List<uint8>();
		CopyBytes(edited, editedBytes);

		PrefabRebuild.Rebuild(scene, PrefabId, editedBytes);

		let survivor = scene.FindEntity(attachmentId);
		Test.Assert(survivor.IsAssigned, "the user's entity was not eaten by the rebuild");
		Test.Assert(scene.GetEntityName(survivor) == "Scope");
		// And it went back where it was, under the member rather than at the scene root.
		let parent = scene.GetParent(survivor);
		Test.Assert(parent.IsAssigned);
		Test.Assert(scene.GetEntityName(parent) == "Barrel");
	}

	/// Rebuilding a prefab nothing instances is a no op rather than a walk over the scene.
	[Test]
	public static void RebuildingAnUninstancedPrefabChangesNothing()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		PrefabSpawn.Spawn(scene, payload, PrefabId);

		let other = Guid(0x1234, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
		let edited = scope MemoryStream();
		CapturePayload(edited, 500.0f);
		let editedBytes = scope List<uint8>();
		CopyBytes(edited, editedBytes);

		Test.Assert(PrefabRebuild.Rebuild(scene, other, editedBytes) == 0);
		Test.Assert(scene.FindEntityByName("Turret").IsAssigned, "the scene is untouched");
	}

	/// Reverting something that is not an instance says so rather than doing damage.
	[Test]
	public static void RevertingSomethingThatIsNotAnInstanceIsRefused()
	{
		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let plain = scene.CreateEntity("Plain");

		let bytes = scope List<uint8>();
		Test.Assert(!PrefabRebuild.Revert(scene, scene.GetEntityId(plain), bytes));
		Test.Assert(!PrefabRebuild.Revert(scene, Guid(), bytes));
		Test.Assert(scene.FindEntityByName("Plain").IsAssigned);
	}
}
