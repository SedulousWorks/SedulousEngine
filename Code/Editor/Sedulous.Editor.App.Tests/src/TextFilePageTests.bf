using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// A file that is no asset as plain text: it shows what the file holds; an edit marks the page
/// unsaved and Save writes it; Discard Changes reads it again; a line shown moves the cursor there;
/// a file that does not read is read-only and never written.
static class TextFilePageTests
{
	private static void ReadText(StringView path, String outText)
	{
		System.IO.File.ReadAllText(path, outText, true).IgnoreError();
	}

	[Test]
	public static void ShowsTheFileSavesAnEditReadsItAgainShowsALine()
	{
		let file = "scratch_text_file_page.csproj";
		Test.Assert(System.IO.File.WriteAllText(file, "<Project>\n  <PropertyGroup/>\n</Project>\n") case .Ok);
		{
			let page = scope TextFilePage(file);
			Test.Assert(page.Title == file);
			ICodePage shown = page; // it publishes the line service
			Test.Assert(shown != null);
			Test.Assert(page.Code != null);
			Test.Assert(page.Code.GetText(.. scope .()) == "<Project>\n  <PropertyGroup/>\n</Project>\n");
			Test.Assert(!page.Code.IsReadOnly);
			Test.Assert(!page.IsDirty);

			page.ShowLine(2, 3);
			Test.Assert(page.Code.Selections.Length == 1);
			Test.Assert(page.Code.Selections[0].Head.Line == 1);
			Test.Assert(page.Code.Selections[0].Head.Column == 2);

			page.Code.Type("x");
			Test.Assert(page.IsDirty);
			Test.Assert(page.Save() case .Ok);
			Test.Assert(!page.IsDirty);
			Test.Assert(ReadText(file, .. scope .()) == page.Code.GetText(.. scope .()));
			Test.Assert(ReadText(file, .. scope .()).Contains("  x<PropertyGroup/>"));

			page.Code.Type("y");
			Test.Assert(page.DiscardChanges());
			Test.Assert(!page.IsDirty);
			Test.Assert(page.Code.GetText(.. scope .()) == ReadText(file, .. scope .()));

			// Reading the file again is no edit.
			Test.Assert(page.ReloadFromSource());
			Test.Assert(!page.IsDirty);
		}
		System.IO.File.Delete(file).IgnoreError();
	}

	[Test]
	public static void AFileThatDoesNotReadIsReadOnlyAndNotWritten()
	{
		let file = "scratch_text_file_page_missing.luaurc";
		System.IO.File.Delete(file).IgnoreError();
		let page = scope TextFilePage(file);
		Test.Assert(page.Code.IsReadOnly);
		Test.Assert(page.Code.GetText(.. scope .()).IsEmpty);
		Test.Assert(page.Save() case .Err);
		Test.Assert(!FileExists(file));
	}
}
