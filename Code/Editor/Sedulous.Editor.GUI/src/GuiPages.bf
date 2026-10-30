using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.GUI;

/// What the GUI asset page shares with a test: the markup a sheet first previews over, the name its
/// problems go under, and the cook's diagnostics as the page's problems.
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

	/// How the problems list names the preview markup's problems (a sheet's page).
	public const String cPreviewMarkupName = "preview markup";

	/// The cook's diagnostics as the page's problems, `file` the code they are in (empty: the page's
	/// own), appended; the caller deletes them. `found` stays the caller's.
	public static void AddProblems(List<GuiDiagnostic> found, StringView file, List<CodeProblem> outProblems)
	{
		for (let d in found)
		{
			// The cook names lines: the whole of each is marked.
			outProblems.Add(new CodeProblem((d.Level == .Error) ? CodeSeverity.Error : .Warning, d.Message, file, (d.Line > 0) ? d.Line - 1 : 0, 0, false));
		}
	}
}
