using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Scripting;
using Sedulous.Scripting.AngelScript;
using Sedulous.Engine.ScriptSurface;

namespace Sedulous.Engine.ScriptSurface.AngelScript.Tests;

/// The whole runtime surface in AngelScript: it binds, and a script drives a real scene.
static class EngineSurfaceScriptTests
{
	[Test]
	public static void TheRuntimeSurfaceBinds()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		// Whatever the language refused is written beside the listing, for reading.
		let report = scope String();
		for (let p in vm.Problems)
			report.AppendF("{}\n", p);
		let path = scope String();
		Path.GetAbsolutePath("../../build/engine-script-surface-angelscript.txt", Directory.GetCurrentDirectory(.. scope .()), path);
		File.WriteAllText(path, report).IgnoreError();
		Console.WriteLine("angelscript binding report: {} ({} problems)", path, vm.Problems.Count);

		// The lists: five members whose List<T> has no AngelScript type yet. Everything else binds.
		for (let p in vm.Problems)
			Test.Assert(p.Contains("System.Collections.List<"), p);
		Test.Assert(vm.Problems.Count == 5, scope $"{vm.Problems.Count} members the language refused; see the report");
	}

	[Test]
	public static void AScriptDrivesAScene()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		let ok = vm.Compile("game", "game.as", """
			float run(Scene@ scene)
			{
				Entity e = scene.CreateEntity("player");
				scene.SetLocalPosition(e, Float3(1, 2, 3));
				scene.SetLocalScale(e, Float3(2, 2, 2));
				scene.UpdateTransforms();
				Float3 p = scene.GetWorldPosition(e);
				Transform t = scene.GetLocalTransform(e);
				return p.Y + t.Scale.X + Length(Float3(3, 4, 0)) + float(scene.IsValid(e) ? 100 : 0);
			}
			// Two scenes: each entity resolves in its own, whatever the other is doing.
			int bodies(Scene@ a, Scene@ b)
			{
				Entity ea = a.CreateEntity("a");
				Entity eb = b.CreateEntity("b");
				b.SetLocalPosition(eb, Float3(0, 5, 0));
				b.UpdateTransforms();
				a.UpdateTransforms();
				return int(a.GetWorldPosition(ea).Y) * 10 + int(b.GetWorldPosition(eb).Y) + a.Physics.BodyCount + b.Physics.BodyCount;
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		let scene = scope Scene();
		var arg = ScriptValue[1](.FromObject(scene));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("game", "float run(Scene@)", arg, ref r), "ran");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(Math.Abs(r.AsFloat - (2 + 2 + 5 + 100)) < 1e-4, scope $"got {r.AsFloat}");
		Test.Assert(scene.EntityCount == 1);

		let a = scope Scene("a");
		let b = scope Scene("b");
		a.AddSystem<Sedulous.Engine.Physics.PhysicsSceneSystem>();
		b.AddSystem<Sedulous.Engine.Physics.PhysicsSceneSystem>();
		var two = ScriptValue[2](.FromObject(a), .FromObject(b));
		Test.Assert(vm.Call("game", "int bodies(Scene@, Scene@)", two, ref r), "two scenes at once");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(r.AsInt == 5, scope $"got {r.AsInt}");
		Test.Assert((a.EntityCount == 1) && (b.EntityCount == 1));
	}
}
