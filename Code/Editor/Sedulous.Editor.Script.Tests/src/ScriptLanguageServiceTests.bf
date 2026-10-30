using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Engine.Composition;
using Sedulous.GUI;

namespace Sedulous.Editor.Script.Tests;

/// The script page's completion and hover over the SHARED ScriptApiSurface (built once through a
/// throwaway runtime bound against the engine surface): the bound types at the top level, a type's
/// statics after `Type.`, a variable's type's own members after `name.`, nothing after a name it
/// cannot place; hover saying what a type is, or a paused run's value.
class ScriptLanguageServiceTests
{
	private static bool Contains(List<CodeCompletionItem> items, StringView label)
	{
		for (let item in items)
		{
			if (item.Label == label)
				return true;
		}
		return false;
	}

	/// What the service offers at the end of `text` (one line), into `outItems` (cleared first).
	private static void CompleteAtEnd(ScriptLanguageService service, StringView text, List<CodeCompletionItem> outItems)
	{
		ClearAndDeleteItems!(outItems);
		let doc = scope CodeDocument();
		doc.SetText(text);
		uint32 start = (uint32)text.Length;
		while ((start > 0) && (((text[start - 1] >= 'a') && (text[start - 1] <= 'z')) || ((text[start - 1] >= 'A') && (text[start - 1] <= 'Z'))))
			--start;
		var request = CodeCompletionRequest();
		request.At = .(0, (uint32)text.Length);
		request.WordStart = .(0, start);
		service.Complete(doc, request, outItems);
	}

	[Test]
	public static void TheBoundApisCompletionAndHoverThroughAngelScript()
	{
		AngelScriptBackend.Register();
		let scriptSurface = scope ScriptSurface();
		EngineScriptSurface.Populate(scriptSurface);
		let surface = scope ScriptApiSurface();
		surface.SetLanguage("angelscript");
		surface.SetSurface(scriptSurface);
		let service = scope ScriptLanguageService(surface, null);
		let items = scope List<CodeCompletionItem>();
		defer { ClearAndDeleteItems!(items); }

		// Top level: the bound type names (the reflected Core math surface is always bound).
		CompleteAtEnd(service, "Flo", items);
		Test.Assert(Contains(items, "Float3"));
		// After the type's name, its statics (Sedulous binds Dot as a global, as Core spells it: the
		// statics here are the constants).
		CompleteAtEnd(service, "Float3.", items);
		Test.Assert(Contains(items, "Zero"));
		Test.Assert(!Contains(items, "X"));
		Test.Assert(!Contains(items, "Float3"));
		CompleteAtEnd(service, "Float3::", items);
		Test.Assert(Contains(items, "Zero"));
		// After a variable's name, the value's own members, of the type it is declared with (read from
		// the text).
		CompleteAtEnd(service, "Float3 where; where.", items);
		Test.Assert(Contains(items, "X"));
		Test.Assert(!Contains(items, "Zero"));
		// A name it cannot place: nothing.
		CompleteAtEnd(service, "nonsense.", items);
		Test.Assert(items.IsEmpty);

		// Hover: what a type is; while paused, what a name holds.
		let doc = scope CodeDocument();
		doc.SetText("Float3");
		let said = scope String();
		Test.Assert(service.Hover(doc, .(0, 2), said));
		Test.Assert(said.StartsWith("type Float3"));
		service.SetValueProbe(new (name, outText) =>
			{
				if (name == "Float3")
					outText.Append("(1, 2, 3)");
			});
		said.Clear();
		Test.Assert(service.Hover(doc, .(0, 2), said));
		Test.Assert(said == "(1, 2, 3)");

		// An unknown language: nothing bound.
		let unknown = scope ScriptApiSurface();
		unknown.SetLanguage("cobol");
		unknown.SetSurface(scriptSurface);
		let none = scope ScriptLanguageService(unknown, null);
		CompleteAtEnd(none, "Flo", items);
		Test.Assert(!Contains(items, "Float3"));
	}
}
