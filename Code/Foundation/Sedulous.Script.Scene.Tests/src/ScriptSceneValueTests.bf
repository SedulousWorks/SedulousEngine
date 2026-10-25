using System;
using System.Collections;
using Sedulous.Scene;
using Sedulous.Script;

// Not Sedulous.Script.Scene.Tests: a namespace named Scene under Sedulous.Script would take
// the bare name `Scene` from the type in the code a surface root emits.
namespace Sedulous.ScriptScene.Tests;

/// The opaque entity is laid out as the scene's handle, then the owner: a component handle
/// reads its entity first, and an unassigned entity reads the same through both.
static
{
	private static void Assert_ScriptEntityMatchesEntityHandle()
	{
		Compiler.Assert(offsetof(ScriptEntity, Index) == offsetof(EntityHandle, Index));
		Compiler.Assert(offsetof(ScriptEntity, Generation) == offsetof(EntityHandle, Generation));
		Compiler.Assert(offsetof(ScriptEntity, Owner) == sizeof(EntityHandle));
		Compiler.Assert(ScriptEntity.cInvalidIndex == EntityHandle.cInvalidIndex);
	}
}

/// A context with nothing but scratch: the scene members read only its ambient owner.
class SceneTestCallContext : ScriptCallContext
{
	private List<void*> mAllocs = new .() ~ delete _;

	public ~this()
	{
		for (let p in mAllocs)
			Internal.Free(p);
	}

	public override Object FindService(Type type) => null;

	public override void SetService(Type type, Object service) {}

	public override void* AllocScratch(int size, int align)
	{
		let p = Internal.Malloc(size);
		mAllocs.Add(p);
		return p;
	}
}

/// The scene typed members over the core's opaque entity, and the names the core matches
/// scene types by.
static class ScriptSceneValueTests
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
	public static void AnEntityRoundTripsWithItsScene()
	{
		let scene = scope Sedulous.Scene.Scene();
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

		let made = ScriptEntity(handle, scene);
		Test.Assert((made.Index == 3) && (made.Generation == 7) && (made.Owner === scene));

		var set = ScriptEntity.Invalid;
		set.Handle = handle;
		set.Scene = scene;
		Test.Assert((set.Index == 3) && (set.Generation == 7) && (set.Owner === scene));

		// No scene named: the entity resolves in the context's.
		let bare = ScriptValue.FromEntity(handle);
		Test.Assert((bare.AsEntity == handle) && (bare.AsEntityOwner == null) && (bare.AsEntityScene == null));

		// An owner that is no scene is carried, and reads as no scene.
		let other = scope String();
		let opaque = ScriptValue.FromEntityRef(.(3, 7, other));
		Test.Assert((opaque.AsEntityOwner === other) && (opaque.AsEntityScene == null));
	}

	[Test]
	public static void NilAndAnotherKindReadNoScene()
	{
		Test.Assert(ScriptValue.Nil.AsEntityScene == null);
		Test.Assert(ScriptValue.FromFloat4(.(1.0f, 2.0f, 3.0f, 4.0f)).AsEntityScene == null);
	}

	[Test]
	public static void TheContextSceneIsItsAmbientOwner()
	{
		let ctx = scope SceneTestCallContext();
		Test.Assert((ctx.Scene == null) && (ctx.AmbientOwner == null));
		let scene = scope Sedulous.Scene.Scene();
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
	public static void AnEntityResolvesInItsSceneElseTheContexts()
	{
		let ctx = scope SceneTestCallContext();
		let a = scope Sedulous.Scene.Scene();
		let b = scope Sedulous.Scene.Scene();
		ctx.Scene = b;
		var args = ScriptValue[2](.FromEntity(.(1, 1), a), .FromEntity(.(2, 1)));
		var frame = ScriptCallFrame(ctx, args);
		Test.Assert(frame.SceneOf(args[0]) === a);
		Test.Assert(frame.SceneOf(args[1]) === b);
		Test.Assert(frame.ExpectEntityIn(0, a));
		Test.Assert(!frame.ExpectEntityIn(0, b) && frame.Failed);
	}

	[Test]
	public static void TheSceneNamesNameTheSceneTypes()
	{
		Test.Assert(typeof(EntityHandle).GetFullName(.. scope .()) == ScriptSceneNames.cEntityHandle);
		Test.Assert(typeof(Sedulous.Scene.Scene).GetFullName(.. scope .()) == ScriptSceneNames.cScene);
		Test.Assert(typeof(SceneSystem).GetFullName(.. scope .()) == ScriptSceneNames.cSceneSystem);
		Test.Assert(typeof(IScriptEntityScene).GetFullName(.. scope .()) == ScriptSceneNames.cEntitySceneInterface);
	}
}
