using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The problems list: errors first in their places' order, the count said, a row chosen going to its
/// problem, and a code editor's diagnostics as its problems.
class ProblemsListTests
{
	[Test]
	public static void ErrorsFirstInTheirPlacesOrderTheCountSaidARowChosenGoesToItsProblem()
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		let host = new Panel();
		root.AddChild(host);
		defer host.ReleaseRef();
		let problems = scope ProblemsList(host);
		Test.Assert(problems.Summary(.. scope .()) == "No problems");

		CodeProblem[4] found = .(
			scope .(.Warning, "unused variable", "", 2, 4),
			scope .(.Error, "no such type", "", 9, 0),
			scope .(.Error, "in the include", "Shaders/Common.hlsli", 0, 0),
			scope .(.Error, "missing ;", "", 3, 7));
		problems.Show(found);
		Test.Assert(problems.Summary(.. scope .()) == "3 errors, 1 warning");
		let shown = problems.Problems;
		Test.Assert(shown.Length == 4);
		Test.Assert(shown[0].Message == "missing ;", "its own code's errors by line");
		Test.Assert(shown[1].Message == "no such type");
		Test.Assert(shown[2].Message == "in the include", "then an include's");
		Test.Assert(shown[3].Severity == .Warning);
		Test.Assert(ProblemsList.PlaceOf(shown[0], .. scope .()) == "4:8");
		Test.Assert(ProblemsList.PlaceOf(shown[2], .. scope .()) == "Common.hlsli 1:1");
		let lineOnly = scope CodeProblem(shown[0].Severity, shown[0].Message, shown[0].File, shown[0].Line, shown[0].Column, false); // the check named the line alone
		Test.Assert(ProblemsList.PlaceOf(lineOnly, .. scope .()) == "4");

		let chosen = scope String();
		problems.SetOnChoose(new [=chosen] (p) => { chosen.Set(p.Message); });
		problems.Choose(.(1, 0, -1));
		Test.Assert(chosen == "no such type");
		problems.Choose(.(9, 0, -1)); // no such row: nothing
		Test.Assert(chosen == "no such type");

		// A code editor's diagnostics are its own code's problems.
		let d = scope CodeDiagnostic();
		d.Range.Start = .(5, 2);
		d.Severity = .Warning;
		d.Message.Set("shadowed");
		CodeDiagnostic[1] diagnostics = .(d);
		let fromEditor = scope List<CodeProblem>();
		defer { ClearAndDeleteItems!(fromEditor); }
		CodeProblem.Of(diagnostics, fromEditor);
		Test.Assert(fromEditor.Count == 1);
		Test.Assert(fromEditor[0].Line == 5);
		Test.Assert(fromEditor[0].File.IsEmpty);
		Test.Assert(fromEditor[0].AtColumn);

		// A problem at its line alone stays so in the list.
		CodeProblem[1] lineOnlyFound = .(lineOnly);
		problems.Show(lineOnlyFound);
		Test.Assert(!problems.Problems[0].AtColumn);
	}
}
