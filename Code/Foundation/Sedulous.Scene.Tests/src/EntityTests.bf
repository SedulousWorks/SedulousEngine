using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// The entity table: handles, generations, the persistent id map, names, the active flags
/// and the revision counter.
class EntityTests
{
	[Test]
	public static void CreatingEntitiesGivesUniqueValidHandles()
	{
		let scene = scope Scene("world");
		Test.Assert(scene.Name == "world");
		Test.Assert(scene.EntityCount == 0);

		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");

		Test.Assert(scene.IsValid(a));
		Test.Assert(scene.IsValid(b));
		Test.Assert(a != b);
		Test.Assert(scene.EntityCount == 2);
		Test.Assert(scene.GetEntityName(a) == "a");
		Test.Assert(scene.GetEntityName(b) == "b");
		Test.Assert(scene.IsActive(a), "entities start active");
	}

	[Test]
	public static void DestroyingAnEntityInvalidatesItsHandle()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();
		Test.Assert(scene.IsValid(entity));

		scene.DestroyEntity(entity);
		Test.Assert(!scene.IsValid(entity));
		Test.Assert(scene.EntityCount == 0);

		// A second destroy names something that is already gone, which is a no op rather
		// than a fault: a caller cannot always know.
		scene.DestroyEntity(entity);
		Test.Assert(scene.EntityCount == 0);
	}

	/// Reusing a slot BUMPS its generation, which is the whole reason the generation
	/// exists: the old handle must read as dead rather than as the new occupant.
	[Test]
	public static void ReusingASlotBumpsTheGenerationSoAStaleHandleIsCaught()
	{
		let scene = scope Scene();
		let first = scene.CreateEntity();
		let reusedIndex = first.Index;
		scene.DestroyEntity(first);

		let second = scene.CreateEntity();
		Test.Assert(second.Index == reusedIndex, "the freed slot came back");
		Test.Assert(second.Generation != first.Generation);
		Test.Assert(scene.IsValid(second));
		Test.Assert(!scene.IsValid(first), "the old handle stays dead");
	}

	[Test]
	public static void AnUnassignedOrOutOfRangeHandleNeverValidates()
	{
		let scene = scope Scene();
		Test.Assert(!scene.IsValid(EntityHandle.Invalid));
		Test.Assert(!scene.IsValid(EntityHandle(999, 1)));
		Test.Assert(scene.GetEntityName(EntityHandle.Invalid).IsEmpty);

		// Every mutator tolerates one, so a caller holding a handle it has not checked
		// cannot bring the scene down.
		scene.SetActive(EntityHandle.Invalid, false);
		scene.SetEntityName(EntityHandle.Invalid, "x");
	}

	/// The persistent id is what SURVIVES a save: a handle is an index into this run, and
	/// an id is the same entity in the next one.
	[Test]
	public static void ThePersistentIdResolvesBackToItsHandle()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity("named");

		let id = scene.GetEntityId(entity);
		Test.Assert(id != Guid());
		Test.Assert(scene.FindEntity(id) == entity);

		// A stated id, as a loaded scene supplies, round trips the same way.
		let fixedId = Guid(0x01234567, 0x89ab, 0xcdef, 0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10);
		let loaded = scene.CreateEntity(fixedId, "loaded");
		Test.Assert(scene.GetEntityId(loaded) == fixedId);
		Test.Assert(scene.FindEntity(fixedId) == loaded);

		// After a destroy the map entry is PRUNED rather than answered with.
		scene.DestroyEntity(loaded);
		Test.Assert(scene.FindEntity(fixedId) == EntityHandle.Invalid);
	}

	[Test]
	public static void NameAndActiveAreMutableOnALiveEntity()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity("orig");

		scene.SetActive(entity, false);
		Test.Assert(!scene.IsActive(entity));

		scene.SetEntityName(entity, "renamed");
		Test.Assert(scene.GetEntityName(entity) == "renamed");
	}

	[Test]
	public static void ForEachEntityVisitsExactlyTheLiveOnes()
	{
		let scene = scope Scene();
		let a = scene.CreateEntity();
		let b = scene.CreateEntity();
		let c = scene.CreateEntity();
		scene.DestroyEntity(b);

		int visited = 0;
		bool sawA = false;
		bool sawB = false;
		bool sawC = false;
		scene.ForEachEntity(scope [&](handle) =>
		{
			visited++;
			if (handle == a) sawA = true;
			if (handle == b) sawB = true;
			if (handle == c) sawC = true;
		});

		Test.Assert(visited == 2);
		Test.Assert(sawA && sawC);
		Test.Assert(!sawB, "the destroyed slot is not visited");
	}

	[Test]
	public static void TheRevisionAdvancesOnAStructuralChange()
	{
		let scene = scope Scene();
		let before = scene.Revision;
		let entity = scene.CreateEntity();
		Test.Assert(scene.Revision > before);

		let afterCreate = scene.Revision;
		scene.DestroyEntity(entity);
		Test.Assert(scene.Revision > afterCreate);
	}

	/// An observer, such as an editor's hierarchy, rebuilds off the revision, so every
	/// mutation that changes what it DISPLAYS has to advance it.
	///
	/// A local transform deliberately does NOT: it would churn a rebuild on every frame of
	/// a gizmo drag, and moving something changes nothing about the tree's shape.
	[Test]
	public static void TheRevisionAdvancesOnRenameReparentAndActiveButNotOnAMove()
	{
		let scene = scope Scene();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");

		var revision = scene.Revision;
		scene.SetEntityName(a, "renamed");
		Test.Assert(scene.Revision > revision);

		revision = scene.Revision;
		scene.SetParent(b, a);
		Test.Assert(scene.Revision > revision);

		revision = scene.Revision;
		scene.SetActive(a, false);
		Test.Assert(scene.Revision > revision);

		// Setting the state it already has changes nothing, so nothing is announced.
		revision = scene.Revision;
		scene.SetActive(a, false);
		Test.Assert(scene.Revision == revision);

		revision = scene.Revision;
		var transform = Transform();
		transform.Position = .(1, 2, 3);
		scene.SetLocalTransform(a, transform);
		Test.Assert(scene.Revision == revision, "a move is not a structural change");
	}

	[Test]
	public static void MoveBeforeReordersSiblingsAndRoots()
	{
		let scene = scope Scene();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		let c = scene.CreateEntity("c");

		// The root list starts in creation order.
		Test.Assert(scene.FirstRoot == a);
		Test.Assert(scene.GetNextSibling(a) == b);
		Test.Assert(scene.GetNextSibling(b) == c);

		// Before the head, which is the path that has to update the head pointer.
		var revision = scene.Revision;
		scene.MoveBefore(c, a);
		Test.Assert(scene.Revision > revision);
		Test.Assert(scene.FirstRoot == c);
		Test.Assert(scene.GetNextSibling(c) == a);
		Test.Assert(scene.GetNextSibling(a) == b);

		// Into the middle.
		scene.MoveBefore(c, b);
		Test.Assert(scene.FirstRoot == a);
		Test.Assert(scene.GetNextSibling(a) == c);
		Test.Assert(scene.GetNextSibling(c) == b);

		// Already there: no churn, so an observer is not woken for nothing.
		revision = scene.Revision;
		scene.MoveBefore(c, b);
		Test.Assert(scene.Revision == revision);

		// SetParent to invalid appends at the END of the root list, so it doubles as move
		// to end.
		scene.SetParent(a, EntityHandle.Invalid);
		Test.Assert(scene.FirstRoot == c);
		Test.Assert(scene.GetNextSibling(b) == a);

		// The same ordering works INSIDE a child list.
		let parent = scene.CreateEntity("p");
		scene.SetParent(b, parent);
		scene.MoveBefore(a, b);
		Test.Assert(scene.GetParent(a) == parent);
		Test.Assert(scene.GetFirstChild(parent) == a);
		Test.Assert(scene.GetNextSibling(a) == b);

		// The cycle guard holds for a move as well as a reparent: putting the parent into
		// its own grandchild's list is refused, not half applied.
		scene.SetParent(c, b);
		revision = scene.Revision;
		scene.MoveBefore(parent, c);
		Test.Assert(scene.Revision == revision);
		Test.Assert(scene.GetParent(parent) == EntityHandle.Invalid);
	}

	[Test]
	public static void EntitiesAreFoundByNameAndByPath()
	{
		let scene = scope Scene("world");
		let player = scene.CreateEntity("Player");
		let weapon = scene.CreateEntity("Weapon");
		let muzzle = scene.CreateEntity("Muzzle");
		let enemy = scene.CreateEntity("Enemy");
		scene.SetParent(weapon, player);
		scene.SetParent(muzzle, weapon);

		Test.Assert(scene.FindEntityByName("Player") == player);
		Test.Assert(scene.FindEntityByName("Muzzle") == muzzle);
		Test.Assert(!scene.FindEntityByName("Missing").IsAssigned);

		// Names are NOT unique, so the FIRST in slot order wins and the second is simply
		// unreachable this way. Identity is what the id is for.
		let firstDuplicate = scene.CreateEntity("Dup");
		scene.CreateEntity("Dup");
		Test.Assert(scene.FindEntityByName("Dup") == firstDuplicate);

		Test.Assert(scene.FindEntityByPath("Player") == player);
		Test.Assert(scene.FindEntityByPath("Player/Weapon") == weapon);
		Test.Assert(scene.FindEntityByPath("Player/Weapon/Muzzle") == muzzle);

		// Leading, trailing and doubled separators are tolerated: a path built by
		// concatenation grows them, and refusing would be pedantry.
		Test.Assert(scene.FindEntityByPath("/Player//Weapon/") == weapon);

		// A miss at ANY depth is a miss. Enemy is a root, not under Player.
		Test.Assert(!scene.FindEntityByPath("Player/Muzzle").IsAssigned);
		Test.Assert(!scene.FindEntityByPath("Player/Weapon/Enemy").IsAssigned);
		Test.Assert(!scene.FindEntityByPath("").IsAssigned);
		Test.Assert(scene.FindEntityByPath("Enemy") == enemy);

		// An invalid parent means the roots.
		Test.Assert(scene.FindChildByName(EntityHandle.Invalid, "Player") == player);
		Test.Assert(scene.FindChildByName(player, "Weapon") == weapon);
		Test.Assert(!scene.FindChildByName(player, "Muzzle").IsAssigned, "a grandchild is not a child");
	}
}
