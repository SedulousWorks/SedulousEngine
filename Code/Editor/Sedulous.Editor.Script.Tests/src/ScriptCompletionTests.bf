using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Engine.ScriptSurface;
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
		Test.Assert((runtime.Module == "main.as") && (runtime.Line == 12) && (runtime.Message == "error: unexpected token"));
		let bare = ScriptCompileError.Parse("no class in the source");
		defer delete bare;
		Test.Assert((bare.Line == 0) && (bare.Message == "no class in the source"));
	}
}
