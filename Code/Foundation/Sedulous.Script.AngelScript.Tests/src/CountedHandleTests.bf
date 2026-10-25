using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.AngelScript.Tests;

/// A counted class in AngelScript: the handle is the object, and each handle a script keeps
/// is one reference on it. A kept handle outlives the native holder, the module's going gives
/// its references back, a script-made object is freed by its last handle rather than by the
/// runtime, a handle converts to its base's, and a counted argument reaches a script callback
/// counted too.
static class CountedHandleTests
{
	private static void Dump(AngelScriptRuntime vm)
	{
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
	}

	private const String cSource = """
		Spool@ held;
		Spool@ made;
		Spool@ heard;
		void take(Spool@ s) { @held = s; }
		int64 heldTurns() { return held.Turns; }
		void make() { @made = Spool(); made.Turns = 2; }
		int64 madeTurns() { return made.Turns; }
		void drop() { @made = null; }
		void makeAndForget() { Spool@ s = Spool(); s.Turns = 5; }
		void keepMade() { @made = Spool::Make(); }
		bool lent() { Spool@ s = Spool(); return s.Itself() is s; }
		int64 up(Bobbin@ b) { Spool@ s = b; return s.Turns; }
		int64 bobbin() { Bobbin@ b = Bobbin(); b.Turns = 1; Spool@ s = b; return b.Wraps + s.Turns; }
		void onSpool(Spool@ s) { @heard = s; }
		void listen(Gadget@ g) { g.OnSpool(onSpool); }
		int64 heardTurns() { return heard.Turns; }
		""";

	[Test]
	public static void AScriptsHandleKeepsItsSpoolAndTheModuleGivesItBack()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let live = Spool.Live;

		let vm = new AngelScriptRuntime();
		vm.Bind(s);
		let ok = vm.Compile("c", "c.as", cSource);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");
		var r = ScriptValue.Nil;

		// Handed in and kept: the script's handle is one reference more, and outlives the
		// native one.
		let spool = new Spool();
		spool.Turns = 4;
		var spoolArg = ScriptValue[1](.FromCounted(spool));
		Test.Assert(vm.Call("c", "void take(Spool@)", spoolArg, ref r), "take");
		Test.Assert(spool.RefCount == 2, scope $"{spool.RefCount} references");
		spool.ReleaseRef();
		Test.Assert(Spool.Live == live + 1, "the script's handle keeps it");
		Test.Assert(vm.Call("c", "int64 heldTurns()", default, ref r) && (r.AsInt == 4), "and it reads");

		// Made by the script: no runtime keeps it, so its last handle frees it.
		Test.Assert(vm.Call("c", "void make()", default, ref r));
		Test.Assert(Spool.Live == live + 2, "made");
		Test.Assert(vm.Call("c", "int64 madeTurns()", default, ref r) && (r.AsInt == 2));
		Test.Assert(vm.Call("c", "void drop()", default, ref r));
		Test.Assert(Spool.Live == live + 1, "freed by its last handle, the runtime holding none");
		Test.Assert(vm.Call("c", "void makeAndForget()", default, ref r));
		Test.Assert(Spool.Live == live + 1, "a local's handle frees it on the way out");

		// A handed reference becomes the script's one; a lent result is the same object.
		Test.Assert(vm.Call("c", "void keepMade()", default, ref r));
		Test.Assert(Spool.Live == live + 2, "the handed spool, kept");
		Test.Assert(vm.Call("c", "int64 madeTurns()", default, ref r) && (r.AsInt == 1));
		Test.Assert(vm.Call("c", "bool lent()", default, ref r) && r.AsBool, "lent, the same handle");
		Test.Assert(Spool.Live == live + 2, "and nothing lent leaked");

		// A bobbin converts to its base's handle, the same object.
		let bobbin = new Bobbin();
		bobbin.Turns = 7;
		var bobbinArg = ScriptValue[1](.FromCounted(bobbin));
		Test.Assert(vm.Call("c", "int64 up(Bobbin@)", bobbinArg, ref r) && (r.AsInt == 7), "the base's handle reads");
		Test.Assert(bobbin.RefCount == 1, scope $"{bobbin.RefCount} references after the up-cast");
		bobbin.ReleaseRef();
		Test.Assert(vm.Call("c", "int64 bobbin()", default, ref r) && (r.AsInt == 4), "a script-made bobbin, and its base's handle");
		Test.Assert(Spool.Live == live + 2);
		Dump(vm);
		Test.Assert(vm.Problems.IsEmpty, "nothing failed");

		// The module goes, and the references it held with it.
		vm.DiscardModule("c");
		Test.Assert(Spool.Live == live, scope $"{Spool.Live - live} spools left after the module");
		delete vm;
		Test.Assert(Spool.Live == live);
	}

	/// A spool reaches a script callback counted, and a call that fails before its callee
	/// runs drops the callback it was handed rather than leaking it.
	[Test]
	public static void ACallbackTakesACountedArgumentAndAFailedCallDropsItsCallback()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let live = Spool.Live;
		// Released last: the gadget in it, and the runtime holding boxes on it, go first.
		let table = new FakeWeakTable();
		defer table.ReleaseLastRef();

		let vm = new AngelScriptRuntime();
		vm.Bind(s);
		let ok = vm.Compile("c", "c.as", cSource);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled");
		var r = ScriptValue.Nil;
		let delegates = vm.[Friend]mDelegates;
		let before = delegates.Count;

		// The gadget takes the callback, and calls it with a spool the script keeps.
		let gadget = new Gadget(table);
		var gadgetArg = ScriptValue[1](.FromWeak(gadget));
		Test.Assert(vm.Call("c", "void listen(Gadget@)", gadgetArg, ref r), "listen");
		Test.Assert((gadget.SpoolHandler != null) && (delegates.Count == before + 1), "the gadget holds the callback");
		let spool = new Spool();
		spool.Turns = 8;
		var spoolArg = ScriptValue[1](.FromCounted(spool));
		var result = ScriptValue.Nil;
		Test.Assert(gadget.SpoolHandler.Invoke(spoolArg, ref result), "invoked");
		Test.Assert(spool.RefCount == 2, scope $"{spool.RefCount} references: the script kept one");
		spool.ReleaseRef();
		Test.Assert(vm.Call("c", "int64 heardTurns()", default, ref r) && (r.AsInt == 8), "the kept spool reads");

		// The gadget goes, its callback with it; a call through its gone handle fails before
		// the callee, and the callback made for it goes too.
		delete gadget;
		Test.Assert(delegates.Count == before, "the gadget's callback went with it");
		Test.Assert(!vm.Call("c", "void listen(Gadget@)", gadgetArg, ref r), "a gone gadget fails");
		Test.Assert(!vm.Problems.IsEmpty && vm.Problems.Back.Contains(ScriptErrors.ObjectGone));
		ClearAndDeleteItems!(vm.Problems);
		Test.Assert(delegates.Count == before, scope $"{delegates.Count - before} callbacks leaked by the failed call");

		vm.DiscardModule("c");
		Test.Assert(Spool.Live == live, scope $"{Spool.Live - live} spools left after the module");
		delete vm;
	}
}
