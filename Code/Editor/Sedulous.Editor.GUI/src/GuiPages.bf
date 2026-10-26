using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.GUI;

/// What the GUI asset page shares with a test: the markup a sheet first previews over, and the
/// cook's diagnostics put in an editor's margin.
static class GuiPages
{
	/// What a sheet is previewed over with nothing chosen yet: a little of everything a sheet
	/// styles.
	public const String cStockPreviewMarkup =
		"""
		<Panel class="page" flex-direction="column" gap="8" padding="16">
		    <Label class="title" text="Title"/>
		    <Label text="Body text."/>
		    <Button text="Button"/>
		    <CheckBox text="Check box"/>
		    <Slider/>
		</Panel>

		""";

	/// The cook's diagnostics on `editor`'s lines, as its margin marks them (from 0; a diagnostic
	/// with no line on the first). `found` stays the caller's.
	public static void MarkLines(CodeEditView editor, List<GuiDiagnostic> found)
	{
		let marks = new List<Sedulous.UI.Toolkit.CodeDiagnostic>(); // consumed by the document
		for (let diagnostic in found)
		{
			let line = (diagnostic.Line > 0) ? (int32)diagnostic.Line - 1 : 0;
			marks.Add(new Sedulous.UI.Toolkit.CodeDiagnostic(diagnostic.Level == .Error, line, diagnostic.Message));
		}
		editor.Document.SetDiagnostics(marks);
		editor.Invalidate();
	}
}
