using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// The process's weak table: what a script's handle to a scene, and an entity's owner, resolve
/// through. A handle taken before its object went answers null, whatever holds the slot since.
class ScriptWeakTableTests
{
	/// An object in the table, as a scene is.
	private class Held : IScriptWeaklyHeld
	{
		private ScriptWeakSlot mSlot;

		public ~this()
		{
			mSlot.Free();
		}

		public ScriptWeakRef TakeScriptWeak() => mSlot.Take(this);
	}

	[Test]
	public static void AHandleResolvesWhileItsObjectLivesAndNullAfter()
	{
		let table = ScriptWeakTable.Shared;
		let before = table.LiveCount;
		let held = new Held();
		Test.Assert(table.LiveCount == before, "no slot until a script names it");
		let handle = held.TakeScriptWeak();
		Test.Assert((handle.Generation != 0) && table.Holds(handle));
		Test.Assert(handle.Resolve() === held);
		Test.Assert(held.TakeScriptWeak().SameAs(handle), "one slot, however often it is named");
		Test.Assert(table.LiveCount == before + 1);

		delete held;
		Test.Assert(handle.Resolve() == null, "gone with its object");
		Test.Assert(table.LiveCount == before);

		// The slot taken again by another: the old handle does not reach it.
		let next = scope Held();
		let reused = next.TakeScriptWeak();
		Test.Assert(reused.Slot == handle.Slot, "the slot is reused");
		Test.Assert(reused.Generation != handle.Generation);
		Test.Assert(handle.Resolve() == null);
		Test.Assert(reused.Resolve() === next);
	}

	[Test]
	public static void GenerationZeroNamesNothing()
	{
		let table = ScriptWeakTable.Shared;
		let held = scope Held();
		let handle = held.TakeScriptWeak();
		Test.Assert(table.ResolveWeak(handle.Slot, 0) == null);
		// Freeing generation 0 frees nothing.
		table.Free(handle.Slot, 0);
		Test.Assert(handle.Resolve() === held);
		Test.Assert(!table.Holds(default), "an empty handle is no one's");
	}
}
