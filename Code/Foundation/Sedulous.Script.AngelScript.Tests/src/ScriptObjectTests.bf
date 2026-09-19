using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.AngelScript.Tests;

/// The object contract a behaviour host needs: instantiate a script class, read and write
/// its properties, dispatch its handlers by name, and run its coroutines.
static class ScriptObjectTests
{
	private const String cMover = """
		class Mover
		{
			float speed = 2;
			int lives = 3;
			bool armed = true;
			string label = "m";
			Vec2 offset = Vec2(1, 2);
			Entity self;
			Thing@ buddy;
			int updates = 0;
			float elapsed = 0;
			int hits = 0;
			string lastMessage;

			void onStart() { updates = 100; }
			void onUpdate(float dt) { updates++; elapsed += dt; }
			void onHit(int damage) { hits += damage; }
			void onHit(const string &in who) { lastMessage = who; }
			float Speed() { return speed; }
		}
		class Plain {}
		""";

	private static AngelScriptRuntime Bound()
	{
		let s = new ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		vm.Bind(s);
		// The surface is the runtime's to keep for the test's life.
		sSurfaces.Add(s);
		return vm;
	}
	private static System.Collections.List<ScriptSurface> sSurfaces = new .() ~ DeleteContainerAndItems!(_);

	private static void Dump(ScriptRuntime vm)
	{
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
	}

	[Test]
	public static void AnInstanceHasItsPropertiesAndHandlers()
	{
		let vm = Bound();
		defer delete vm;
		Test.Assert(vm.Compile("b", "Mover.as", cMover), "compiled");
		Dump(vm);

		let mover = vm.Instantiate("b", "Mover");
		Test.Assert(mover != null, "instantiated");
		Test.Assert(mover.ClassName == "Mover");
		Test.Assert(vm.Instantiate("b", "Nope") == null);
		Test.Assert(vm.Problems.Back.Contains("Nope"));

		// Defaults, read back in the frame's kinds.
		var v = ScriptValue.Nil;
		Test.Assert(vm.GetProperty(mover, "speed", ref v) && (v.Kind == .Float) && (v.AsFloat == 2));
		Test.Assert(vm.GetProperty(mover, "lives", ref v) && (v.Kind == .Int) && (v.AsInt == 3));
		Test.Assert(vm.GetProperty(mover, "armed", ref v) && v.AsBool);
		Test.Assert(vm.GetProperty(mover, "label", ref v) && (v.AsString == "m"));
		Test.Assert(vm.GetProperty(mover, "offset", ref v) && (v.Kind == .Struct) && ((*(Vec2*)v.AsStruct).Y == 2), "a struct by pointer into the object");
		Test.Assert(vm.GetProperty(mover, "buddy", ref v) && v.IsNil, "a null handle is nil");
		Test.Assert(!vm.GetProperty(mover, "nope", ref v));

		// Writes, typed: a number into a float, an int into an int, not a string into a float.
		Test.Assert(vm.SetProperty(mover, "speed", .FromInt(5)));
		Test.Assert(vm.GetProperty(mover, "speed", ref v) && (v.AsFloat == 5));
		Test.Assert(!vm.SetProperty(mover, "speed", .FromString("x")));
		Test.Assert(vm.SetProperty(mover, "label", .FromString("changed")));
		Test.Assert(vm.GetProperty(mover, "label", ref v) && (v.AsString == "changed"));
		var moved = Vec2(7, 8);
		Test.Assert(vm.SetProperty(mover, "offset", .FromStruct(&moved, typeof(Vec2))));
		Test.Assert(vm.GetProperty(mover, "offset", ref v) && ((*(Vec2*)v.AsStruct).X == 7));
		let scene = scope Scene();
		let e = scene.CreateEntity("e");
		Test.Assert(vm.SetProperty(mover, "self", .FromEntity(e, scene)));
		Test.Assert(vm.GetProperty(mover, "self", ref v) && (v.AsEntity == e) && (v.AsEntityScene === scene), "an entity keeps its scene");
		let thing = scope Thing();
		Test.Assert(vm.SetProperty(mover, "buddy", .FromObject(thing)));
		Test.Assert(vm.GetProperty(mover, "buddy", ref v) && (v.AsObject === thing));

		// Handlers, by presence and arity.
		Test.Assert(vm.HasMethod(mover, "onStart", 0) && vm.HasMethod(mover, "onUpdate", 1));
		Test.Assert(!vm.HasMethod(mover, "onUpdate", 0) && !vm.HasMethod(mover, "onDestroy", 0));

		var r = ScriptValue.Nil;
		Test.Assert(vm.Invoke(mover, "onStart", default, ref r));
		var dt = ScriptValue[1](.FromFloat(0.5));
		Test.Assert(vm.Invoke(mover, "onUpdate", dt, ref r));
		Test.Assert(vm.Invoke(mover, "onUpdate", dt, ref r));
		Test.Assert(vm.GetProperty(mover, "updates", ref v) && (v.AsInt == 102));
		Test.Assert(vm.GetProperty(mover, "elapsed", ref v) && (v.AsFloat == 1));
		Test.Assert(vm.Invoke(mover, "Speed", default, ref r) && (r.AsFloat == 5));

		// An overloaded handler picks by the payload's kind.
		var damage = ScriptValue[1](.FromInt(4));
		Test.Assert(vm.Invoke(mover, "onHit", damage, ref r));
		var who = ScriptValue[1](.FromString("bob"));
		Test.Assert(vm.Invoke(mover, "onHit", who, ref r));
		Test.Assert(vm.GetProperty(mover, "hits", ref v) && (v.AsInt == 4));
		Test.Assert(vm.GetProperty(mover, "lastMessage", ref v) && (v.AsString == "bob"));
		var wrong = ScriptValue[1](.FromBool(true));
		Test.Assert(!vm.Invoke(mover, "onHit", wrong, ref r));
		Test.Assert(vm.Problems.Back.Contains("onHit"));

		vm.Release(mover);
		let plain = vm.Instantiate("b", "Plain");
		Test.Assert((plain != null) && !vm.HasMethod(plain, "onStart", 0));
		// Left to the runtime to release.
	}

	[Test]
	public static void CoroutinesWaitAndResumeOnTheHostsClock()
	{
		let vm = Bound();
		defer delete vm;
		Test.Assert(vm.Compile("c", "c.as", """
			class Blinker
			{
				int steps = 0;
				bool done = false;
				void onStart() { startCoroutine(ScriptCoroutine(this.run)); }
				void run()
				{
					steps = 1;
					wait(1.0);
					steps = 2;
					wait(0.5);
					steps = 3;
					done = true;
				}
			}
			int freeSteps = 0;
			void freeRunner() { freeSteps = 1; wait(2.0); freeSteps = 2; }
			void startFree() { startCoroutine(freeRunner); }
			void badWait() { wait(1.0); }
			"""), "compiled");
		Dump(vm);

		let blinker = vm.Instantiate("c", "Blinker");
		var r = ScriptValue.Nil;
		var v = ScriptValue.Nil;
		Test.Assert(vm.Invoke(blinker, "onStart", default, ref r));
		Dump(vm);
		Test.Assert(vm.CoroutineCount == 1);
		Test.Assert(vm.GetProperty(blinker, "steps", ref v) && (v.AsInt == 1), "ran to the first wait at once");

		vm.AdvanceCoroutines(0.5);
		Test.Assert(vm.GetProperty(blinker, "steps", ref v) && (v.AsInt == 1), "not due yet");
		vm.AdvanceCoroutines(0.5);
		Test.Assert(vm.GetProperty(blinker, "steps", ref v) && (v.AsInt == 2), "resumed when due");
		vm.AdvanceCoroutines(0.6);
		Test.Assert(vm.GetProperty(blinker, "steps", ref v) && (v.AsInt == 3));
		Test.Assert(vm.GetProperty(blinker, "done", ref v) && v.AsBool);
		Test.Assert(vm.CoroutineCount == 0, "finished and dropped");

		// A free function coroutine, cancelled by nobody, ends on its own.
		Test.Assert(vm.Call("c", "void startFree()", default, ref r));
		Test.Assert(vm.CoroutineCount == 1);
		vm.AdvanceCoroutines(3);
		Test.Assert(vm.CoroutineCount == 0);

		// Releasing the owner cancels what it started.
		Test.Assert(vm.Invoke(blinker, "onStart", default, ref r));
		Test.Assert(vm.CoroutineCount == 1);
		vm.Release(blinker);
		Test.Assert(vm.CoroutineCount == 0, "cancelled with its owner");

		// wait() outside a coroutine is a fault, reported.
		Test.Assert(!vm.Call("c", "void badWait()", default, ref r));
		Test.Assert(vm.Problems.Back.Contains("coroutine"));
	}
}
