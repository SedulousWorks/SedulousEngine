using System;
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

/// The opaque entity a value carries, read back through the core's own members.
static class ScriptEntityTests
{
	[Test]
	public static void AnOpaqueEntityRoundTripsWithItsOwner()
	{
		let owner = scope String();
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

	[Test]
	public static void AnEntityIsExpectedInItsOwner()
	{
		let ctx = scope ScratchCallContext();
		let a = scope String();
		let b = scope String();
		var args = ScriptValue[2](.FromEntityRef(.(1, 1, a)), .FromEntityRef(.(2, 1, null)));
		var frame = ScriptCallFrame(ctx, args);
		Test.Assert(frame.ExpectEntityIn(0, a));
		Test.Assert(frame.ExpectEntityIn(0, null));
		Test.Assert(frame.ExpectEntityIn(1, b));
		Test.Assert(!frame.ExpectEntityIn(0, b) && frame.Failed);
	}
}
