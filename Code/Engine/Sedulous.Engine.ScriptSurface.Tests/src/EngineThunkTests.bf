using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Scripting;
using Sedulous.Engine.ScriptSurface;

namespace Sedulous.Engine.ScriptSurface.Tests;

/// The emitted thunks against the real engine types: a scene driven entirely through the
/// surface, the way a script would.
static class EngineThunkTests
{
	private static ScriptMethodInfo Method(ScriptSurface s, StringView type, StringView name, int arity = -1)
	{
		let t = s.Find(type);
		for (let m in t.Methods)
		{
			if ((m.ScriptName == name) && ((arity < 0) || (m.Params.Count == arity)))
				return m;
		}
		return null;
	}

	[Test]
	public static void ASceneIsDrivenThroughTheSurface()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let ctx = scope ScratchCallContext();
		let scene = scope Scene();
		const String cScene = "Sedulous.Scene.Scene";

		// Scene is a plain class: Self is the object.
		var name = ScriptValue[1](.FromString("player"));
		var frame = ScriptCallFrame(ctx, name);
		frame.Self = .FromObject(scene);
		Method(s, cScene, "CreateEntity").Invoke(ref frame);
		Test.Assert(!frame.Failed, scope String(frame.Error));
		Test.Assert(frame.Result.Kind == .Entity);
		Test.Assert(frame.Result.AsEntityScene === scene, "the entity a scene answers names that scene");
		let entity = frame.Result.AsEntity;
		Test.Assert(scene.IsValid(entity) && (scene.GetEntityName(entity) == "player"));

		var move = ScriptValue[2](.FromEntity(entity), .FromFloat3(.(1, 2, 3)));
		frame.Args = move;
		Method(s, cScene, "SetLocalPosition").Invoke(ref frame);
		Test.Assert(!frame.Failed);
		scene.UpdateTransforms();

		var one = ScriptValue[1](.FromEntity(entity));
		frame.Args = one;
		Method(s, cScene, "GetWorldPosition").Invoke(ref frame);
		Test.Assert((frame.Result.Kind == .Float3) && (frame.Result.AsFloat3.Y == 2));

		// A struct result lands in context storage: the local transform.
		Method(s, cScene, "GetLocalTransform").Invoke(ref frame);
		Test.Assert(frame.Result.Kind == .Struct);
		Test.Assert(frame.Result.StructType == typeof(Transform));
		Test.Assert((*(Transform*)frame.Result.AsStruct).Position.Z == 3);

		// The handle is opaque: no writable Index.
		let handle = s.Find("Sedulous.Scene.EntityHandle");
		Test.Assert(!handle.AllPublic);
		for (let f in handle.Fields)
			Test.Assert((f.Name != "Index") && (f.Name != "Generation"));

		// Everything bound, except what the frame cannot carry; those say why.
		for (let t in s.Types)
		{
			for (let m in t.Methods)
				Test.Assert(m.IsCallable || !m.Unsupported.IsEmpty);
			for (let f in t.Fields)
				Test.Assert((f.Get != null) || !f.Unsupported.IsEmpty);
		}
	}
}
