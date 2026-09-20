using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.GameUI.Tests;

/// The game UI editor's registration and the markup probe its editors show.
class GameUIEditorTests
{
	[Test]
	public static void RegisteringRoutesBothAssetsToTheirPages()
	{
		let context = scope EditorContext();
		GameUIEditor.Register(context, null, null);
		let document = context.Pages.FindFactory(typeof(UIDocumentAsset));
		Test.Assert((document != null) && (document.PrimaryType == typeof(UIDocumentAsset)));
		let theme = context.Pages.FindFactory(typeof(UIThemeAsset));
		Test.Assert((theme != null) && (theme.PrimaryType == typeof(UIThemeAsset)));
	}

	[Test]
	public static void TheProbeReportsOneErrorOnTheFailingLine()
	{
		let diagnostics = scope List<CodeDiagnostic>();
		defer { ClearAndDeleteItems!(diagnostics); }
		Test.Assert(MarkupDiagnostics.Probe("<Panel>\n  <Label text=\"a\"/>\n</Panel>", diagnostics));
		Test.Assert(diagnostics.IsEmpty);
		Test.Assert(!MarkupDiagnostics.Probe("<Panel>\n  <Label text=\"a\">\n</Panel>", diagnostics));
		Test.Assert(diagnostics.Count == 1);
		Test.Assert(diagnostics[0].IsError && (diagnostics[0].Line >= 1) && !diagnostics[0].Message.IsEmpty);

		// Through an editor, the margin takes it.
		let editor = new CodeEditView();
		defer editor.ReleaseRef();
		editor.SetText("<a><b></a>");
		Test.Assert(!MarkupDiagnostics.Apply("<a><b></a>", editor));
		Test.Assert(editor.Document.DiagnosticCount == 1);
		Test.Assert(MarkupDiagnostics.Apply("<a/>", editor));
		Test.Assert(editor.Document.DiagnosticCount == 0);
		Test.Assert(UIThemeEditorPage.cStockPreviewMarkup.StartsWith("<Panel"));
	}

	[Test]
	public static void LinkedSourceReadsEmptyWithoutAProject()
	{
		let context = scope EditorContext();
		let text = scope String("stale");
		LinkedSource.Read(context, "UI/missing.sml", text);
		Test.Assert(text.IsEmpty);
	}
}
