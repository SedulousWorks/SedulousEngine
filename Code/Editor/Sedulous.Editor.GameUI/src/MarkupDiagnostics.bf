using System;
using System.Collections;
using Sedulous.Xml;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.GameUI;

/// The XML well-formedness probe an editor shows in its margin: one error diagnostic on
/// the failing line, or none.
static class MarkupDiagnostics
{
	/// Fills `outDiagnostics` (the caller owns the entries); true when the markup parses.
	public static bool Probe(StringView markup, List<CodeDiagnostic> outDiagnostics)
	{
		let probe = scope XmlDocument();
		let result = probe.Parse(markup);
		if (!result.IsError)
			return true;
		outDiagnostics.Add(new CodeDiagnostic(true, probe.ErrorLine - 1, result.Describe)); // 1-based to buffer lines
		return false;
	}

	/// Probes and puts the result in the editor's margin.
	public static bool Apply(StringView markup, CodeEditView editor)
	{
		let diagnostics = new List<CodeDiagnostic>();
		let ok = Probe(markup, diagnostics);
		editor.Document.SetDiagnostics(diagnostics);
		editor.Invalidate();
		return ok;
	}
}
