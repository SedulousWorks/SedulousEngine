using System;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.Tests;

/// The layout is the contract: AngelScript registers Entity at this size and alignment, and a
/// component handle reads its entity first, as the scene's handle then the owner.
static
{
	private static void Assert_ScriptEntityLayout()
	{
		Compiler.Assert(sizeof(ScriptEntity) == 16);
		Compiler.Assert(alignof(ScriptEntity) == 8);
		Compiler.Assert(offsetof(ScriptEntity, Index) == offsetof(EntityHandle, Index));
		Compiler.Assert(offsetof(ScriptEntity, Generation) == offsetof(EntityHandle, Generation));
		Compiler.Assert(offsetof(ScriptEntity, Owner) == sizeof(EntityHandle));
		Compiler.Assert(ScriptEntity.cInvalidIndex == EntityHandle.cInvalidIndex);
	}
}

/// The opaque entity a value carries, read back through the scene typed members and the
/// core's own, and the names the core matches scene types by.
static class ScriptEntityTests
{
	[Test]
	public static void TheInvalidEntityIsTheInvalidHandle()
	{
		let invalid = ScriptEntity.Invalid;
		Test.Assert(invalid.Index == EntityHandle.Invalid.Index);
		Test.Assert(invalid.Generation == EntityHandle.Invalid.Generation);
		Test.Assert(invalid.Owner == null);
		Test.Assert(invalid.Handle == EntityHandle.Invalid);
	}

	[Test]
	public static void AnEntityRoundTripsWithItsOwner()
	{
		let scene = scope Scene();
		let handle = EntityHandle(3, 7);
		let value = ScriptValue.FromEntity(handle, scene);
		Test.Assert(value.Kind == .Entity);
		Test.Assert(value.AsEntity == handle);
		Test.Assert(value.AsEntityScene === scene);
		Test.Assert(value.AsEntityOwner === scene);
		let e = value.AsEntityRef;
		Test.Assert((e.Index == 3) && (e.Generation == 7) && (e.Owner === scene));
		Test.Assert((e.Handle == handle) && (e.Scene === scene));

		let again = ScriptValue.FromEntityRef(e);
		Test.Assert((again.AsEntity == handle) && (again.AsEntityScene === scene));

		// No owner named: the entity resolves in the context's.
		let bare = ScriptValue.FromEntity(handle);
		Test.Assert((bare.AsEntity == handle) && (bare.AsEntityOwner == null) && (bare.AsEntityScene == null));

		// An owner that is no scene is carried, and reads as no scene.
		let other = scope String();
		let opaque = ScriptValue.FromEntityRef(.(3, 7, other));
		Test.Assert((opaque.AsEntityOwner === other) && (opaque.AsEntityScene == null));
	}

	[Test]
	public static void NilReadsAsAZeroEntityWithNoOwner()
	{
		let none = ScriptValue.Nil;
		let e = none.AsEntityRef;
		Test.Assert((e.Index == 0) && (e.Generation == 0) && (e.Owner == null));
		Test.Assert(none.AsEntityOwner == null);
		Test.Assert(none.AsEntityScene == null);
	}

	/// A value of another kind reads no owner, though its bytes overlap where an entity's owner is.
	[Test]
	public static void AnotherKindReadsNoOwner()
	{
		let notEntity = ScriptValue.FromFloat4(.(1.0f, 2.0f, 3.0f, 4.0f));
		Test.Assert(notEntity.AsEntityOwner == null);
		Test.Assert(notEntity.AsEntityScene == null);
	}

	[Test]
	public static void TheContextSceneIsItsAmbientOwner()
	{
		let ctx = scope ScratchCallContext();
		Test.Assert((ctx.Scene == null) && (ctx.AmbientOwner == null));
		let scene = scope Scene();
		ctx.Scene = scene;
		Test.Assert((ctx.AmbientOwner === scene) && (ctx.Scene === scene));
		// An owner that is no scene reads as no scene.
		let other = scope String();
		ctx.AmbientOwner = other;
		Test.Assert(ctx.Scene == null);
		ctx.Scene = null;
		Test.Assert(ctx.AmbientOwner == null);
	}

	[Test]
	public static void AnEntityIsExpectedInItsOwner()
	{
		let ctx = scope ScratchCallContext();
		let a = scope Scene();
		let b = scope Scene();
		var args = ScriptValue[2](.FromEntity(.(1, 1), a), .FromEntity(.(2, 1)));
		var frame = ScriptCallFrame(ctx, args);
		Test.Assert(frame.ExpectEntityIn(0, a));
		Test.Assert(frame.ExpectEntityIn(0, null));
		Test.Assert(frame.ExpectEntityIn(1, b));
		Test.Assert(!frame.ExpectEntityIn(0, b) && frame.Failed);
	}

	[Test]
	public static void TheSceneNamesNameTheSceneTypes()
	{
		Test.Assert(typeof(EntityHandle).GetFullName(.. scope .()) == ScriptSceneNames.cEntityHandle);
		Test.Assert(typeof(Scene).GetFullName(.. scope .()) == ScriptSceneNames.cScene);
		Test.Assert(typeof(SceneSystem).GetFullName(.. scope .()) == ScriptSceneNames.cSceneSystem);
		Test.Assert(typeof(IScriptEntityScene).GetFullName(.. scope .()) == ScriptSceneNames.cEntitySceneInterface);
	}
}
