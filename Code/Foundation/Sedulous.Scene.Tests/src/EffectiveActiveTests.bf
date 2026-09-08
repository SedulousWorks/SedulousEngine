using System;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// The EFFECTIVE active state: an entity's own flag AND every ancestor's.
///
/// The bit is cached and resettled only at the choke points that can change it, creation,
/// SetActive and a reparent, so reading it is O(1) rather than a walk up the chain on
/// every gate. These tests are about that cache staying honest.
class EffectiveActiveTests
{
	/// Darkening the MIDDLE of a chain darks everything below it, and leaves every own
	/// flag below untouched, so turning it back on restores exactly what was on before.
	[Test]
	public static void AMidAncestorDarksTheWholeSubtree()
	{
		let scene = scope Scene("eff");
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		let c = scene.CreateEntity("c");
		let d = scene.CreateEntity("d");
		scene.SetParent(b, a);
		scene.SetParent(c, b);
		scene.SetParent(d, c);

		Test.Assert(scene.IsEffectivelyActive(a));
		Test.Assert(scene.IsEffectivelyActive(d));

		scene.SetActive(b, false);
		Test.Assert(scene.IsEffectivelyActive(a), "above the toggle is unaffected");
		Test.Assert(!scene.IsEffectivelyActive(b));
		Test.Assert(!scene.IsEffectivelyActive(c));
		Test.Assert(!scene.IsEffectivelyActive(d));

		// The own flags below are NOT written, which is what makes the restore exact.
		Test.Assert(scene.IsActive(c));
		Test.Assert(scene.IsActive(d));

		scene.SetActive(b, true);
		Test.Assert(scene.IsEffectivelyActive(c));
		Test.Assert(scene.IsEffectivelyActive(d));
	}

	/// The restore is exact in BOTH directions: a child that was off before the parent
	/// went off is still off after the parent comes back.
	[Test]
	public static void AChildsOwnFlagSurvivesAParentToggle()
	{
		let scene = scope Scene("eff2");
		let parent = scene.CreateEntity("p");
		let onChild = scene.CreateEntity("on");
		let offChild = scene.CreateEntity("off");
		scene.SetParent(onChild, parent);
		scene.SetParent(offChild, parent);
		scene.SetActive(offChild, false);

		scene.SetActive(parent, false);
		Test.Assert(!scene.IsEffectivelyActive(onChild));
		Test.Assert(!scene.IsEffectivelyActive(offChild));

		scene.SetActive(parent, true);
		Test.Assert(scene.IsEffectivelyActive(onChild), "was on, so back on");
		Test.Assert(!scene.IsEffectivelyActive(offChild), "its own flag is still off");
		Test.Assert(!scene.IsActive(offChild));
	}

	/// A REPARENT changes the ancestor chain without touching a flag, so the cache has to
	/// resettle from the move alone.
	[Test]
	public static void ReparentingIntoAndOutOfADarkSubtreeResettles()
	{
		let scene = scope Scene("eff3");
		let darkHost = scene.CreateEntity("host");
		let mover = scene.CreateEntity("mover");
		let moverChild = scene.CreateEntity("mc");
		scene.SetParent(moverChild, mover);
		scene.SetActive(darkHost, false);

		scene.SetParent(mover, darkHost);
		Test.Assert(!scene.IsEffectivelyActive(mover));
		Test.Assert(!scene.IsEffectivelyActive(moverChild), "the whole subtree came with it");
		Test.Assert(scene.IsActive(mover), "the move did not write its own flag");

		scene.SetParent(mover, EntityHandle.Invalid);
		Test.Assert(scene.IsEffectivelyActive(mover));
		Test.Assert(scene.IsEffectivelyActive(moverChild));
	}

	/// MoveBefore can change the parent as well as the position, so it resettles too. This
	/// is the case a splice that only reordered would miss.
	[Test]
	public static void MoveBeforeAcrossParentsResettlesTheSubtree()
	{
		let scene = scope Scene("eff4");
		let activeParent = scene.CreateEntity("ap");
		let inactiveParent = scene.CreateEntity("ip");
		let anchor = scene.CreateEntity("anchor");
		let mover = scene.CreateEntity("mover");
		scene.SetParent(anchor, inactiveParent);
		scene.SetParent(mover, activeParent);
		scene.SetActive(inactiveParent, false);

		scene.MoveBefore(mover, anchor);
		Test.Assert(scene.GetParent(mover) == inactiveParent);
		Test.Assert(!scene.IsEffectivelyActive(mover));
	}

	[Test]
	public static void ACreatedRootIsActiveAndADeadHandleIsNot()
	{
		let scene = scope Scene("eff5");
		let entity = scene.CreateEntity("e");
		Test.Assert(scene.IsEffectivelyActive(entity), "created as an active root");
		Test.Assert(!scene.IsEffectivelyActive(EntityHandle.Invalid));

		scene.DestroyEntity(entity);
		Test.Assert(!scene.IsEffectivelyActive(entity));
	}
}
