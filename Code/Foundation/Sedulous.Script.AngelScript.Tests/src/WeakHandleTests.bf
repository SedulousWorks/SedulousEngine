using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.AngelScript.Tests;

/// A weakly held class in AngelScript: a counted handle that resolves on every use. It
/// answers while its object lives; once the object goes, IsValid is false and every other use
/// is the one gone-object error. `X::Of` narrows without ever failing, `==` compares handles,
/// a handle converts to its base's, and every handle a script kept gives its table back its
/// reference when the module goes.
static class WeakHandleTests
{
	private static void Dump(AngelScriptRuntime vm)
	{
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
	}

	[Test]
	public static void AWeakHandleAnswersUntilItsObjectGoesAndThenSaysSo()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		// Released last: every gadget in it, and the runtime holding boxes on it, go first.
		let table = new FakeWeakTable();
		defer table.ReleaseLastRef();
		let startReferences = table.RefCount;

		let vm = new AngelScriptRuntime();
		vm.Bind(s);
		let ok = vm.Compile("w", "w.as", """
			Gadget@ held;
			void take(Gadget@ g) { @held = g; }
			int64 charge() { return held.Charge; }
			void setCharge() { held.Charge = 9; }
			bool heldValid() { return held.IsValid; }
			bool wrong() { return Gizmo::Of(held) is null; }
			bool right(Gadget@ g) { Sprocket@ s = Sprocket::Of(g); return s !is null; }
			bool same(Gadget@ a, Gadget@ b) { return a == b; }
			int64 up(Sprocket@ s) { Gadget@ g = s; return g.Charge; }
			""");
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		let gadget = new Gadget(table);
		gadget.Charge = 5;
		let gadgetSlot = gadget.Slot;
		let sprocket = new Sprocket(table);
		sprocket.Charge = 7;
		defer delete sprocket;
		var gadgetArg = ScriptValue[1](.FromWeak(gadget));
		var sprocketArg = ScriptValue[1](.FromWeak(sprocket));
		var r = ScriptValue.Nil;

		// Handed in as an argument and kept: the one box the script holds is the table's one
		// reference more, the argument's own released with the call.
		Test.Assert(vm.Call("w", "void take(Gadget@)", gadgetArg, ref r), "take");
		Test.Assert(table.RefCount == startReferences + 1, scope $"{table.RefCount} references");
		Test.Assert(vm.Call("w", "int64 charge()", default, ref r) && (r.AsInt == 5), "the kept handle reads");
		Test.Assert(vm.Call("w", "bool heldValid()", default, ref r) && r.AsBool, "and is valid");
		Test.Assert(vm.Call("w", "void setCharge()", default, ref r) && (gadget.Charge == 9), "and writes");

		// Narrowing: to the wrong type null, to the right one the handle.
		Test.Assert(vm.Call("w", "bool wrong()", default, ref r) && r.AsBool, "a gadget is no gizmo");
		Test.Assert(vm.Call("w", "bool right(Gadget@)", sprocketArg, ref r) && r.AsBool, "a sprocket is one");
		Test.Assert(vm.Call("w", "bool right(Gadget@)", gadgetArg, ref r) && !r.AsBool, "a gadget is not");

		// `==` is the same handle, by identity: two boxes for one gadget compare equal.
		var twoGadgets = ScriptValue[2](.FromWeak(gadget), .FromWeak(gadget));
		Test.Assert(vm.Call("w", "bool same(Gadget@, Gadget@)", twoGadgets, ref r) && r.AsBool, "the same gadget");
		var mixed = ScriptValue[2](.FromWeak(gadget), .FromWeak(sprocket));
		Test.Assert(vm.Call("w", "bool same(Gadget@, Gadget@)", mixed, ref r) && !r.AsBool, "two gadgets");

		// A sprocket converts to its base's handle.
		Test.Assert(vm.Call("w", "int64 up(Sprocket@)", sprocketArg, ref r) && (r.AsInt == 7), "the base's handle reads");
		Dump(vm);
		Test.Assert(vm.Problems.IsEmpty, "nothing failed while it lived");

		// The gadget goes: IsValid answers, narrowing is null, every other use is the error.
		delete gadget;
		Test.Assert(vm.Call("w", "bool heldValid()", default, ref r) && !r.AsBool, "gone: not valid");
		Test.Assert(vm.Call("w", "bool wrong()", default, ref r) && r.AsBool, "gone: narrowed to null");
		Test.Assert(vm.Problems.IsEmpty, "and neither is an error");
		Test.Assert(!vm.Call("w", "int64 charge()", default, ref r), "gone: the read fails");
		Test.Assert(!vm.Problems.IsEmpty && vm.Problems.Back.Contains(ScriptErrors.ObjectGone), "saying the object is gone");
		ClearAndDeleteItems!(vm.Problems);
		Test.Assert(!vm.Call("w", "void setCharge()", default, ref r), "gone: the write fails");
		Test.Assert(!vm.Problems.IsEmpty && vm.Problems.Back.Contains(ScriptErrors.ObjectGone), "saying the same");
		ClearAndDeleteItems!(vm.Problems);

		// Its slot reused by another gadget: the old handle still does not answer.
		let reuser = new Gadget(table);
		defer delete reuser;
		Test.Assert(reuser.Slot == gadgetSlot, "the freed slot is reused");
		Test.Assert(vm.Call("w", "bool heldValid()", default, ref r) && !r.AsBool, "a reused slot does not answer");

		// The table closed: a live object's handle reads gone.
		Test.Assert(vm.Call("w", "void take(Gadget@)", sprocketArg, ref r));
		Test.Assert(vm.Call("w", "bool heldValid()", default, ref r) && r.AsBool, "the sprocket is there");
		table.Close();
		Test.Assert(vm.Call("w", "bool heldValid()", default, ref r) && !r.AsBool, "a closed table reads gone");
		Test.Assert(!vm.Call("w", "int64 charge()", default, ref r) && vm.Problems.Back.Contains(ScriptErrors.ObjectGone));
		ClearAndDeleteItems!(vm.Problems);

		// The module goes, and the handle it still held with it.
		Test.Assert(table.RefCount == startReferences + 1, scope $"{table.RefCount} references while held");
		vm.DiscardModule("w");
		Test.Assert(table.RefCount == startReferences, scope $"{table.RefCount} references after the module");
		delete vm;
	}
}
