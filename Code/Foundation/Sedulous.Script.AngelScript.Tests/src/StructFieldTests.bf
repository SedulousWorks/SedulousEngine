using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript.Tests.Values;

namespace Sedulous.Script.AngelScript.Tests;

/// A struct-valued field reads as a copy, as a C# struct does: it is written whole, from a
/// value or another owner's; a field written through a read of it is refused, since it would
/// change the copy; a local taken from it stays apart; a read-only one is never written.
static class StructFieldTests
{
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1e-4;

	[Test]
	public static void AStructFieldIsWrittenWholeAndACopyOutOfItStaysApart()
	{
		let s = scope ScriptSurface();
		ValuesSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(vm.Problems.IsEmpty, "every member registered");

		let ok = vm.Compile("t", "t.as", """
			float A; float B; float C;
			void main(House@ h, House@ g)
			{
				Room fresh;
				fresh.Size = 4;
				h.Spare = fresh;        // whole
				A = h.Spare.Size;
				Room changed = h.Spare; // copy, change, write back
				changed.Size = 9;
				h.Spare = changed;
				B = h.Spare.Size;
				Room saved = h.Spare;   // a copy, not a view
				changed.Size = 1;
				h.Spare = changed;
				C = saved.Size;
				Room other = g.Spare;
				other.Size = 6;
				g.Spare = other;
				h.Spare = g.Spare;      // one owner's from another's
				other.Size = 2;
				g.Spare = other;        // h keeps its own
				Room nested = h.Spare;  // a struct inside it, the same way
				nested.Entry.Width = 3;
				h.Spare = nested;
			}
			float a() { return A; }
			float b() { return B; }
			float c() { return C; }
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled");

		let h = scope House();
		let g = scope House();
		var args = ScriptValue[2](.FromObject(h), .FromObject(g));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("t", "void main(House@, House@)", args, ref r), "ran");
		Test.Assert(vm.Call("t", "float a()", default, ref r) && Near(r.AsFloat, 4), "the whole value");
		Test.Assert(vm.Call("t", "float b()", default, ref r) && Near(r.AsFloat, 9), "a field of it");
		Test.Assert(vm.Call("t", "float c()", default, ref r) && Near(r.AsFloat, 9), "the copy kept its value");
		Test.Assert(Near(h.Spare.Size, 6), scope $"from the other owner's: {h.Spare.Size}");
		Test.Assert(Near(g.Spare.Size, 2), "the other kept its own");
		Test.Assert(Near(h.Spare.Entry.Width, 3), "the nested field, written back");
		Test.Assert(Near(g.Spare.Entry.Width, 0));
		Test.Assert(Near(h.Shown.Size, 0), "the read-only field untouched");
	}

	/// A field written through a read of a struct-valued member would change the copy, so the
	/// compiler refuses it: copy, change, write back. It compiled and wrote the owner.
	[Test]
	public static void AFieldWrittenThroughAStructReadIsRefused()
	{
		let s = scope ScriptSurface();
		ValuesSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		ClearAndDeleteItems!(vm.Problems);
		Test.Assert(!vm.Compile("t", "t.as", "void main(House@ h) { h.Spare.Size = 9; }\n"), "a field of the copy");
		ClearAndDeleteItems!(vm.Problems);
		Test.Assert(!vm.Compile("n", "n.as", "void main(House@ h) { h.Spare.Entry.Width = 3; }\n"), "a field of a struct inside it");
		ClearAndDeleteItems!(vm.Problems);
	}

	/// A value's own fields are members: written in place on a local, compound assignments
	/// included, a struct inside it too. Through accessors they were refused (`+=`) or landed in
	/// a temporary (a nested field).
	[Test]
	public static void AValuesOwnFieldsAreMembersWrittenInPlace()
	{
		let s = scope ScriptSurface();
		ValuesSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		ClearAndDeleteItems!(vm.Problems);
		let ok = vm.Compile("v", "v.as", "float f() { Room r; r.Size = 0; r.Size += 2; r.Entry.Width = 3; r.Entry.Width += 1; return r.Size + r.Entry.Width; }\n");
		Test.Assert(ok, vm.Problems.IsEmpty ? "" : vm.Problems[0]);
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("v", "float f()", default, ref r) && Near(r.AsFloat, 6));
	}

	/// A read-only struct field still refuses a whole assignment at compile time.
	[Test]
	public static void AReadOnlyStructFieldIsNotAssigned()
	{
		let s = scope ScriptSurface();
		ValuesSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		let ok = vm.Compile("t", "t.as", """
			void main(House@ h) { Room fresh; h.Shown = fresh; }
			""");
		Test.Assert(!ok, "no setter, so no assignment");
	}
}
