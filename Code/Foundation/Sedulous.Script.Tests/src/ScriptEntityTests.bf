using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.Tests;

/// The layout is the contract: AngelScript registers Entity at this size and alignment. The
/// pins against the scene's handle are in Sedulous.Script.Scene.Tests.
static
{
	private static void Assert_ScriptEntityLayout()
	{
		Compiler.Assert(sizeof(ScriptEntity) == 16);
		Compiler.Assert(alignof(ScriptEntity) == 8);
	}
}

/// An owner in the process's weak table that is no scene, as a scene is one.
class TableOwner : IScriptWeaklyHeld
{
	private ScriptWeakSlot mSlot;

	public ~this()
	{
		mSlot.Free();
	}

	public ScriptWeakRef TakeScriptWeak() => mSlot.Take(this);
}

/// The opaque entity a value carries, read back through the core's own members.
static class ScriptEntityTests
{
	[Test]
	public static void AnOpaqueEntityRoundTripsWithItsOwner()
	{
		let owner = scope TableOwner();
		let value = ScriptValue.FromEntityRef(.(3, 7, owner));
		Test.Assert(value.Kind == .Entity);
		Test.Assert(value.AsEntityOwner === owner);
		let e = value.AsEntityRef;
		Test.Assert((e.Index == 3) && (e.Generation == 7) && (e.Owner === owner));

		let again = ScriptValue.FromEntityRef(e);
		Test.Assert(again.AsEntityRef.Index == 3);
		Test.Assert(again.AsEntityRef.Generation == 7);
		Test.Assert(again.AsEntityOwner === owner);

		// No owner named: the entity resolves in the context's.
		let bare = ScriptValue.FromEntityRef(.(3, 7, null));
		Test.Assert(bare.AsEntityOwner == null);
	}

	[Test]
	public static void NilReadsAsAZeroEntityWithNoOwner()
	{
		let none = ScriptValue.Nil;
		let e = none.AsEntityRef;
		Test.Assert((e.Index == 0) && (e.Generation == 0) && (e.Owner == null));
		Test.Assert(none.AsEntityOwner == null);
	}

	/// A value of another kind reads no owner, though its bytes overlap where an entity's owner is.
	[Test]
	public static void AnotherKindReadsNoOwner()
	{
		let notEntity = ScriptValue.FromFloat4(.(1.0f, 2.0f, 3.0f, 4.0f));
		Test.Assert(notEntity.AsEntityOwner == null);
	}

	/// An owner outside the table cannot be named: the entity names none.
	[Test]
	public static void AnOwnerOutsideTheTableIsNone()
	{
		let other = scope String();
		let value = ScriptValue.FromEntityRef(.(3, 7, other));
		Test.Assert(value.AsEntityOwner == null);
		Test.Assert(!value.NamesEntityOwner && !value.EntityOwnerGone);
	}

	/// An entity kept past its owner reads the owner as gone, by its place, never by what now
	/// holds the slot: a call checking it does nothing and reports no failure.
	[Test]
	public static void AnEntityKeptPastItsOwnerReadsItGone()
	{
		let ctx = scope ScratchCallContext();
		let owner = new TableOwner();
		var args = ScriptValue[1](.FromEntityRef(.(1, 1, owner)));
		let kept = args[0].AsEntityRef;
		Test.Assert(args[0].NamesEntityOwner && !args[0].EntityOwnerGone);
		delete owner;

		// A new owner takes the freed slot: the kept entity is not in it.
		let next = scope TableOwner();
		let taken = ScriptValue.FromEntityRef(.(1, 1, next)).AsEntityRef;
		Test.Assert(taken.OwnerSlot == kept.OwnerSlot, "the slot is reused");
		Test.Assert(args[0].AsEntityOwner == null, "the kept entity's owner is gone");
		Test.Assert(args[0].NamesEntityOwner && args[0].EntityOwnerGone);
		Test.Assert(!kept.SameOwner(taken));
		Test.Assert(args[0].AsEntityRef.SameOwner(kept), "written back, it stays gone");

		var frame = ScriptCallFrame(ctx, args);
		Test.Assert(!frame.ExpectEntityIn(0, next) && !frame.Failed, "a gone entity makes the call do nothing");
		Test.Assert(!frame.ExpectEntityIn(0, null) && !frame.Failed, "in no owner too");
	}

	[Test]
	public static void AnEntityIsExpectedInItsOwner()
	{
		let ctx = scope ScratchCallContext();
		let a = scope TableOwner();
		let b = scope TableOwner();
		var args = ScriptValue[2](.FromEntityRef(.(1, 1, a)), .FromEntityRef(.(2, 1, null)));
		var frame = ScriptCallFrame(ctx, args);
		Test.Assert(frame.ExpectEntityIn(0, a));
		Test.Assert(frame.ExpectEntityIn(0, null));
		Test.Assert(frame.ExpectEntityIn(1, b));
		Test.Assert(!frame.ExpectEntityIn(0, b) && frame.Failed);
	}
}
