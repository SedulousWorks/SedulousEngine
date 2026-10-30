using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.AngelScript.Pipeline;
using Sedulous.Engine.Composition;

namespace Sedulous.Editor.Script.Tests;

/// The page's headless half: the runtime's problem lines split for the problems list, and the check
/// that compiles as the cook does, running nothing.
class ScriptSourceDocumentTests
{
	[Test]
	public static void CompileErrorsParseTheRuntimeShape()
	{
		let parsed = ScriptCompileError.Parse("cook (3, 5) : error : Expected ';'");
		defer delete parsed;
		// A space before the parenthesis is not the runtime shape: whole message.
		Test.Assert((parsed.Line == 0) && parsed.Module.IsEmpty);
		let runtime = ScriptCompileError.Parse("main.as(12,4): error: unexpected token");
		defer delete runtime;
		Test.Assert((runtime.Module == "main.as") && (runtime.Line == 12) && (runtime.Column == 4) && (runtime.Message == "error: unexpected token"));
		let bare = ScriptCompileError.Parse("no class in the source");
		defer delete bare;
		Test.Assert((bare.Line == 0) && (bare.Column == 0) && (bare.Message == "no class in the source"));
	}

	/// BORROWED by the cook registered with it, so it lives as long as the registration.
	private static ScriptSurface sCookSurface = null ~ delete _;

	/// The AngelScript cook registered once, over the engine surface (the script page's check
	/// compiles through it).
	public static void EnsureCook()
	{
		if (sCookSurface != null)
			return;
		sCookSurface = new ScriptSurface();
		EngineScriptSurface.Populate(sCookSurface);
		AngelScriptCook.Register(sCookSurface);
	}

	/// The page's check, a moment after each edit: it compiles, runs nothing, and an error
	/// keeps its column.
	[Test]
	public static void TheDocumentsCheckRunsNothingAndAnErrorKeepsItsColumn()
	{
		EnsureCook();
		let doc = scope ScriptSourceDocument();
		doc.Bind("", "mover.as", "angelscript");
		// A cook runs this initializer and faults; the check never runs it.
		doc.SetSource("""
			int Zero() { return 0; }
			int boom = 10 / Zero();
			class Mover
			{
				[4.5] float speed;
				Entity self;
			}
			""");
		Test.Assert(doc.Validate(), doc.Errors.IsEmpty ? "" : doc.Errors[0].Message);
		Test.Assert(doc.ClassName == "Mover");
		Test.Assert(doc.Errors.IsEmpty);

		doc.SetSource("class Mover\n{\n    void onStart() { int b = ; }\n}\n");
		Test.Assert(!doc.Validate());
		bool found = false;
		for (let e in doc.Errors)
			found |= (e.Line == 3) && (e.Column == 30) && e.Message.StartsWith("error");
		Test.Assert(found, "the error at its line and column");
	}
}
