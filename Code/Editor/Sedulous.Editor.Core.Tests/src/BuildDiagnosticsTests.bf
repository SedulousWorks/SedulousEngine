using System;
using System.Collections;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// BeefBuild's output read into diagnostics: real output of a failing build (a game's two files
/// and the engine's warnings), and the forms it did not show.
class BuildDiagnosticsTests
{
	/// What BeefBuild printed building a game with three errors in one file and one in another,
	/// over an engine with three duplicate-declaration warnings: its progress bar, excerpts and
	/// notes as they were.
	private const String cFailedBuild = Compiler.ReadText("src/Fixtures/beefbuild-errors.txt");

	/// The fixture reads as the compiler counted it: four errors and six warnings, each with its
	/// place, the progress bar off the front of the first, and the build failing as a whole.
	[Test]
	public static void AFailedBuildReadsAsTheCompilerCountedIt()
	{
		let diagnostics = scope BuildDiagnostics();
		diagnostics.Parse(cFailedBuild);
		Test.Assert(diagnostics.ErrorCount == 4, scope String()..AppendF("{} errors", diagnostics.ErrorCount));
		Test.Assert(diagnostics.WarningCount == 6, scope String()..AppendF("{} warnings", diagnostics.WarningCount));
		Test.Assert((diagnostics.SummaryErrors == 4) && (diagnostics.SummaryWarnings == 6), "the summary line read");
		Test.Assert(diagnostics.CompileFailed, "Compile failed read");

		let first = diagnostics.Items[0];
		Test.Assert(first.Severity == .Error);
		Test.Assert(first.Message == "Expression expected", first.Message);
		Test.Assert(first.File.EndsWith("/Code/Game/src/Other.bf") && first.File.StartsWith("/"), first.File);
		Test.Assert((first.Line == 7) && (first.Column == 17), scope String()..AppendF("{}:{}", first.Line, first.Column));
		Test.Assert(first.Code.IsEmpty);
		Test.Assert(first.Notes.IsEmpty);
		Test.Assert(first.Excerpt == "  undefinedCall(\n                ^", first.Excerpt);
		Test.Assert(first.Describe(.. scope .()) == scope $"{first.File}:7:17: Expression expected");

		let last = diagnostics.Items[diagnostics.Items.Count - 1];
		Test.Assert((last.Severity == .Error) && (last.Message == "Method 'undefinedCall' does not exist") && (last.Line == 7) && (last.Column == 3), last.Message);
	}

	/// A warning's number is its code, and a duplicate declaration's note carries the earlier
	/// place, with its own excerpt, apart from the warning's.
	[Test]
	public static void AWarningCarriesItsCodeAndItsNote()
	{
		let diagnostics = scope BuildDiagnostics();
		diagnostics.Parse(cFailedBuild);
		BuildDiagnostic unused = null;
		BuildDiagnostic duplicate = null;
		for (let item in diagnostics.Items)
		{
			if ((unused == null) && (item.Code == "BF0168"))
				unused = item;
			if ((duplicate == null) && (item.Code == "BF4200"))
				duplicate = item;
		}
		Test.Assert(unused != null, "a BF0168");
		Test.Assert((unused.Severity == .Warning) && (unused.Message == "The variable 'unused' is assigned but its value is never used"), unused.Message);
		Test.Assert(unused.Notes.IsEmpty);

		Test.Assert(duplicate != null, "a BF4200");
		Test.Assert(duplicate.Message == "A variable named 'a' has already been declared in this scope", duplicate.Message);
		Test.Assert(duplicate.File.EndsWith("Sedulous.Core/src/Math/Gradient.bf") && (duplicate.Line == 82) && (duplicate.Column == 62), duplicate.File);
		Test.Assert(duplicate.Notes.Count == 1, scope String()..AppendF("{} notes", duplicate.Notes.Count));
		let note = duplicate.Notes[0];
		Test.Assert(note.Message == "Previous declaration", note.Message);
		Test.Assert((note.Line == 60) && (note.Column == 62), scope String()..AppendF("{}:{}", note.Line, note.Column));
		Test.Assert(note.File == duplicate.File, note.File);
		Test.Assert(note.Excerpt.StartsWith("   if (GradientBracket(colors") && note.Excerpt.EndsWith("^"), note.Excerpt);
		Test.Assert(duplicate.Excerpt.StartsWith("  if (GradientBracket(alphas"), duplicate.Excerpt);
	}

	/// A message ending in a full stop says "Line" for "at line"; an error with no place has
	/// none; a source line at the left margin is still the excerpt; and a linker's errors are
	/// errors with no place, the whole line their message.
	[Test]
	public static void TheOtherFormsRead()
	{
		let diagnostics = scope BuildDiagnostics();
		diagnostics.Parse("""
			ERROR: Unable to load project 'Missing' specified in workspace
			WARNING: Obsolete. Line 3:1 in /game/src/Old.bf
			class Old
			ld.lld: error: undefined symbol: Game_Start
			/usr/bin/ld: Game.o: in function `main': undefined reference to `Game_Start'
			collect2: error: ld returned 1 exit status
			Errors: 1. Warnings: 1.
			""");
		Test.Assert(diagnostics.Items.Count == 5, scope String()..AppendF("{} items", diagnostics.Items.Count));
		let unloaded = diagnostics.Items[0];
		Test.Assert((unloaded.Severity == .Error) && !unloaded.HasPlace && (unloaded.Message == "Unable to load project 'Missing' specified in workspace"), unloaded.Message);
		Test.Assert(unloaded.Describe(.. scope .()) == unloaded.Message);
		let old = diagnostics.Items[1];
		Test.Assert((old.Severity == .Warning) && (old.Message == "Obsolete.") && (old.File == "/game/src/Old.bf") && (old.Line == 3) && (old.Column == 1), old.Message);
		Test.Assert(old.Excerpt == "class Old", old.Excerpt);
		Test.Assert((diagnostics.Items[2].Message == "ld.lld: error: undefined symbol: Game_Start") && !diagnostics.Items[2].HasPlace, diagnostics.Items[2].Message);
		Test.Assert(diagnostics.Items[3].Message.Contains("undefined reference to `Game_Start'"), diagnostics.Items[3].Message);
		Test.Assert((diagnostics.Items[4].Severity == .Error) && diagnostics.Items[4].Message.StartsWith("collect2: error:"), diagnostics.Items[4].Message);
		Test.Assert(!diagnostics.CompileFailed);
	}

	/// The same diagnostic printed twice (BeefBuild run once per config reports the engine's
	/// warnings each time) is kept once.
	[Test]
	public static void ADiagnosticRepeatedIsKeptOnce()
	{
		let diagnostics = scope BuildDiagnostics();
		let warning = "WARNING(2): BF0168: The variable 'x' is assigned but its value is never used at line 8:7 in /game/src/Program.bf\n  let x = 1;\n      ^\n";
		diagnostics.Parse(scope $"{warning}Compiling\n{warning}");
		Test.Assert(diagnostics.Items.Count == 1, scope String()..AppendF("{} items", diagnostics.Items.Count));
		Test.Assert(diagnostics.Items[0].Excerpt == "  let x = 1;\n      ^", diagnostics.Items[0].Excerpt);
	}

	/// The progress bar comes off the front of a line, and nothing else does.
	[Test]
	public static void TheProgressBarComesOff()
	{
		Test.Assert(BuildDiagnostics.StripProgress("[    ]\b\b\b\b\b\b**ERROR: x") == "ERROR: x");
		Test.Assert(BuildDiagnostics.StripProgress("*****") == "");
		Test.Assert(BuildDiagnostics.StripProgress("[Workspace]") == "[Workspace]");
		Test.Assert(BuildDiagnostics.StripProgress("  a * b") == "  a * b");
	}
}
