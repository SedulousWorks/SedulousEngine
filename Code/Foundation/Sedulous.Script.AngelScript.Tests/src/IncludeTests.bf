using System;
using System.Collections;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.AngelScript.Tests;

/// A source compiles with the files it includes, each a section named by its path: a class
/// compiled from source failed on its #include line, since nothing preprocessed it.
static class IncludeTests
{
	private const String cPlayer = "#include \"Lib/Math.as\"\nint f() { return twice(2); }\n";

	[Test]
	public static void ASourceCompilesWithTheFilesItIncludes()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		ClearAndDeleteItems!(vm.Problems);

		ScriptSection[2] sections = .(.("Scripts/Player.as", cPlayer), .("Scripts/Lib/Math.as", "int twice(int x) { return x * 2; }\n"));
		Test.Assert(vm.CompileModule("m", sections), vm.Problems.IsEmpty ? "" : vm.Problems[0]);
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("m", "int f()", default, ref r) && (r.AsInt == 4));

		// An error in an included file names that file.
		ScriptSection[2] broken = .(.("Scripts/Player.as", cPlayer), .("Scripts/Lib/Math.as", "int twice(int x) { return x * ; }\n"));
		Test.Assert(!vm.CompileModule("b", broken));
		bool named = false;
		for (let p in vm.Problems)
			named |= p.StartsWith("Scripts/Lib/Math.as(1,");
		Test.Assert(named, vm.Problems.IsEmpty ? "" : vm.Problems[0]);
		ClearAndDeleteItems!(vm.Problems);

		// The including source keeps its lines: the error is on its line 2, where it was written.
		ScriptSection[1] includes = .(.("Scripts/Lib/Math.as", "int twice(int x) { return x * 2; }\n"));
		Test.Assert(vm.Check("Scripts/Player.as", cPlayer, includes), vm.Problems.IsEmpty ? "" : vm.Problems[0]);
		Test.Assert(!vm.Check("Scripts/Player.as", "#include \"Lib/Math.as\"\nint f() { return nope(2); }\n", includes));
		bool atLine = false;
		for (let p in vm.Problems)
			atLine |= p.StartsWith("Scripts/Player.as(2,");
		Test.Assert(atLine, vm.Problems.IsEmpty ? "" : vm.Problems[0]);
		ClearAndDeleteItems!(vm.Problems);
	}

	[Test]
	public static void IncludeLinesAreBlankedAndListed()
	{
		let blanked = AngelScriptRuntime.BlankIncludes("  #include \"a.as\"\r\nint x;\n#include \"b/c.as\"", .. scope .());
		Test.Assert(blanked == "                 \r\nint x;\n                 ", scope $"[{blanked}]");
		let paths = scope List<String>();
		defer { ClearAndDeleteItems!(paths); }
		AngelScriptRuntime.IncludesOf("  #include \"a.as\"\r\nint x;\n#include \"b/c.as\"", paths);
		Test.Assert((paths.Count == 2) && (paths[0] == "a.as") && (paths[1] == "b/c.as"));
	}
}
