using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript.Tests.Values;

namespace Sedulous.Script.AngelScript.Tests;

/// A struct-valued field is written where it lives: whole, field by field, a struct inside
/// it, and from another owner's; a local taken from it is a copy; a read-only one is never
/// written.
static class StructFieldTests
{
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1e-4;

	[Test]
	public static void AStructFieldIsWrittenWholeOrFieldByFieldAndACopyOutOfItStaysApart()
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
				h.Spare.Size = 9;       // a field of it
				B = h.Spare.Size;
				Room saved = h.Spare;   // a copy, not a view
				h.Spare.Size = 1;
				C = saved.Size;
				g.Spare.Size = 6;
				h.Spare = g.Spare;      // one owner's from another's
				g.Spare.Size = 2;       // h keeps its own
				h.Spare.Entry.Width = 3; // a field of a struct inside it
				h.Shown.Size = 5;       // read only: lands in a copy
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
		Test.Assert(Near(h.Spare.Entry.Width, 3), "the nested field, in place");
		Test.Assert(Near(g.Spare.Entry.Width, 0));
		Test.Assert(Near(h.Shown.Size, 0), "the read-only field untouched");
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
