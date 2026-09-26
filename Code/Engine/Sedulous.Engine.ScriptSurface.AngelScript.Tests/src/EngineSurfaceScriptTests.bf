using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
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

		// Every member the surface binds, the language binds: the lists cross as arrays.
		Test.Assert(vm.Problems.Count == 0, scope $"{vm.Problems.Count} members the language refused; see the report");

		// And what it bound, as a script spells it, beside the listing: the API a browser
		// or a completion shows.
		let api = scope List<ScriptApiType>();
		defer { ClearAndDeleteItems(api); }
		vm.DescribeBoundApi(api);
		let text = scope String();
		text.AppendF("angelscript bound api: {} types\n\n", api.Count);
		for (let t in api)
		{
			text.AppendF("{}{}{}\n", t.IsNamespace ? "namespace " : "", t.ScriptName.IsEmpty ? "<global>" : t.ScriptName, t.TypeFullName.IsEmpty ? "" : scope:: $" [{t.TypeFullName}]");
			for (let m in t.Members)
				text.AppendF("    {}\n", m.Signature);
			text.Append("\n");
		}
		let apiPath = scope String();
		Path.GetAbsolutePath("../../build/engine-script-api-angelscript.txt", Directory.GetCurrentDirectory(.. scope .()), apiPath);
		File.WriteAllText(apiPath, text).IgnoreError();
		// One bound type per surface type: the facades, the values they pass, the globals.
		Test.Assert(api.Count == 45, scope $"{api.Count} bound types");
		// Spot checks of the spelling at the engine's scale.
		var scene = (ScriptApiType)null;
		for (let t in api)
			if (t.ScriptName == "Scene")
				scene = t;
		Test.Assert(scene != null);
		bool physics = false;
		for (let m in scene.Members)
			if (m.Signature == "PhysicsFacade@ Scene.Physics")
				physics = true;
		Test.Assert(physics, "the scene's system property");
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
				// A list parameter is the script's own array, filled by the callee: no
				// bodies yet, so it stays empty, and the call itself is what is proven.
				array<Entity> hits;
				a.Physics.OverlapSphere(Float3(0, 0, 0), 5.0f, hits);
				return int(a.GetWorldPosition(ea).Y) * 10 + int(b.GetWorldPosition(eb).Y) + a.Physics.BodyCount + b.Physics.BodyCount + int(hits.length());
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

	/// A character controller is reached through scene.Physics, never a component handle:
	/// the verbs write the intent the physics step consumes, and an entity with no character
	/// is a no-op rather than a fault.
	[Test]
	public static void AScriptSteersACharacterThroughThePhysicsFacade()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		let ok = vm.Compile("game", "game.as", """
			bool drive(Scene@ scene, const Entity &in rider, const Entity &in bystander)
			{
				scene.Physics.MoveCharacter(rider, 3.0f, -4.0f);
				scene.Physics.JumpCharacter(rider, 5.5f);
				scene.Physics.SetCharacterPosition(rider, Float3(1, 2, 3));
				// No character on the bystander: every verb quietly does nothing.
				scene.Physics.MoveCharacter(bystander, 9.0f, 9.0f);
				return scene.Physics.IsCharacterGrounded(rider) || scene.Physics.IsCharacterGrounded(bystander);
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		let scene = scope Scene("chars");
		defer Sedulous.Script.SceneFacades.Release(scene);
		scene.AddSystem<Sedulous.Engine.Physics.PhysicsSceneSystem>();
		let characters = scene.AddSystem<Sedulous.Engine.Physics.CharacterComponentManager>();
		let rider = scene.CreateEntity("rider");
		let bystander = scene.CreateEntity("bystander");
		characters.Add(rider);

		var args = ScriptValue[3](.FromObject(scene), .FromEntity(rider, scene), .FromEntity(bystander, scene));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("game", "bool drive(Scene@, const Entity &in, const Entity &in)", args, ref r), "ran");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(!r.AsBool, "never stepped, so nothing is grounded");

		let character = characters.Get(rider);
		Test.Assert((character.MoveVelocity.X == 3.0f) && (character.MoveVelocity.Y == 0.0f) && (character.MoveVelocity.Z == -4.0f));
		Test.Assert(character.JumpSpeed == 5.5f);
		Test.Assert(character.TeleportPending && (character.TeleportTo.X == 1.0f) && (character.TeleportTo.Z == 3.0f));
		Test.Assert(!characters.Has(bystander), "a verb never adds a character");
	}
}
