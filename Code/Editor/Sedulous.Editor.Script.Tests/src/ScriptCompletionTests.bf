using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.AngelScript.Pipeline;
using Sedulous.Engine.Composition;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Script.Tests;

/// Bound API completion over the engine surface, through the AngelScript backend.
class ScriptCompletionTests
{
	private static bool Contains(List<CompletionCandidate> candidates, StringView label)
	{
		for (let c in candidates)
		{
			if (c.Label == label)
				return true;
		}
		return false;
	}

	[Test]
	public static void BoundApiCompletionThroughAngelScript()
	{
		AngelScriptBackend.Register();
		let scriptSurface = scope ScriptSurface();
		EngineScriptSurface.Populate(scriptSurface);
		let surface = scope ScriptApiSurface();
		surface.SetLanguage("angelscript");
		surface.SetSurface(scriptSurface);
		let provider = scope ScriptApiCompletionProvider();
		provider.SetSurface(surface);
		let doc = scope CodeDocument();
		let candidates = scope List<CompletionCandidate>();
		defer { ClearAndDeleteItems!(candidates); }

		// A bare prefix offers the types.
		doc.SetText("Flo");
		provider.Collect(doc, .(0, 3), "Flo", candidates);
		Test.Assert(Contains(candidates, "Float3"));

		// After "Type." the members. Dot is a global here, as Core spells it, so the
		// members are the fields and the constants.
		ClearAndDeleteItems!(candidates);
		doc.SetText("Float3.");
		provider.Collect(doc, .(0, 7), "", candidates);
		Test.Assert(candidates.Count > 0);
		Test.Assert(Contains(candidates, "Zero"));
		Test.Assert(!Contains(candidates, "Dot"));

		// An unknown receiver offers nothing.
		ClearAndDeleteItems!(candidates);
		doc.SetText("nonsense.");
		provider.Collect(doc, .(0, 9), "", candidates);
		Test.Assert(candidates.IsEmpty);

		// A language without a backend stays empty.
		let unknownSurface = scope ScriptApiSurface();
		unknownSurface.SetLanguage("cobol");
		unknownSurface.SetSurface(scriptSurface);
		let unknown = scope ScriptApiCompletionProvider();
		unknown.SetSurface(unknownSurface);
		doc.SetText("x");
		unknown.Collect(doc, .(0, 1), "x", candidates);
		Test.Assert(candidates.IsEmpty);
	}

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

	/// The page's check, a moment after each edit: it compiles, runs nothing, and an error
	/// keeps its column.
	[Test]
	public static void TheDocumentsCheckRunsNothingAndAnErrorKeepsItsColumn()
	{
		if (sCookSurface == null)
		{
			sCookSurface = new ScriptSurface();
			EngineScriptSurface.Populate(sCookSurface);
			AngelScriptCook.Register(sCookSurface);
		}
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
