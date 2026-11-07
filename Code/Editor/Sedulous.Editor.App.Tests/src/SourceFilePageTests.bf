using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// A source file's page: a .bf of the project's own code read into the code editor, coloured as
/// Beef, its edits one history on the page's stack, saved back to the file, read again when written
/// outside while clean, and taken to a line; the editor opens it docked by its file, once whatever
/// the spelling, and only for a file under the project's Code/ or Plugins/.
class SourceFilePageTests
{
	public const String cGame = "// The game.\nnamespace Game;\n\nclass Spin\n{\n\tpublic float Speed = 1.5f;\n}\n";

	/// Writes `text` to `relative` under `dir`, its folders made.
	public static void Write(StringView dir, StringView relative, StringView text)
	{
		let path = PathJoin(dir, relative, .. scope .());
		MakeDirectories(PathParent(path, .. scope .()));
		Test.Assert(WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	private static void MakeDirectories(StringView dir)
	{
		if (dir.IsEmpty || DirectoryExists(dir))
			return;
		MakeDirectories(PathParent(dir, .. scope .()));
		CreateDirectory(dir);
	}

	private static void ReadBack(StringView path, String outText)
	{
		Test.Assert(System.IO.File.ReadAllText(path, outText, true) case .Ok);
	}

	/// The page's markup names the toolkit's bar and the code editor.
	public static void RegisterElements()
	{
		RegisterToolkitElements();
		RegisterCodeElements();
	}

	[Test]
	public static void APageReadsACodeFileColouredAsBeefAndSavesItBack()
	{
		RegisterElements();
		let bed = scope PagesBed("scratch_source_file_page");
		Write(bed.Dir, "Code/Game/src/Spin.bf", cGame);
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		let languages = scope CodeLanguages(new [=data] (path, outText) =>
			System.IO.File.ReadAllText(PathJoin(data, path, .. scope .()), outText) case .Ok);

		let full = scope String();
		let file = scope String();
		let error = scope String();
		Test.Assert(SourceFilePage.Resolve(bed.Project.Directory, "Code/Game/src/Spin.bf", full, file, error), error);
		Test.Assert(file == "Code/Game/src/Spin.bf", file);
		let page = new SourceFilePage(bed.Context, PagesBed.LoadMarkup(SourceFilePage.cMarkupPath), languages, full, file);
		defer delete page;
		Test.Assert(page.SourceRead);
		Test.Assert(page.Code != null);
		Test.Assert(!page.Code.IsReadOnly);
		Test.Assert(page.Title == "Spin.bf");
		Test.Assert(!page.InstanceId.IsSet, "it edits no asset");
		Test.Assert(page.Text(.. scope .()) == cGame);
		Test.Assert((page.Code.GetLanguage() != null) && (page.Code.GetLanguage().Id == "beef"));
		Test.Assert(!page.Code.TokensOf(1).IsEmpty);
		Test.Assert(page.Code.TokensOf(1)[0].Token == .Keyword, "namespace, coloured");
		Test.Assert(!page.IsDirty);

		// Typing: one step on the page's stack, which its undo and redo walk.
		page.Code.SetCaret(.(0, 0));
		page.Code.Type("// edited\n");
		Test.Assert(page.IsDirty);
		Test.Assert(page.Commands.CanUndo);
		page.Commands.Undo();
		Test.Assert(page.Text(.. scope .()) == cGame);
		page.Commands.Redo();
		Test.Assert(page.Text(.. scope .()).StartsWith("// edited\n"));

		// Saved: the file holds it.
		Test.Assert(page.Save() case .Ok);
		Test.Assert(!page.IsDirty);
		let onDisk = ReadBack(full, .. scope .());
		Test.Assert(onDisk == scope String()..AppendF("// edited\n{}", cGame), onDisk);

		// To a line and a column from 1, as a diagnostic names them; past the end, the last line.
		page.GoTo(7, 2);
		Test.Assert(page.Code.Primary.Head == CodePosition(6, 1));
		page.GoTo(100);
		Test.Assert(page.Code.Primary.Head.Line == page.Code.Document.LineCount - 1);

		// Written outside while clean: read again, its history let go.
		Write(bed.Dir, "Code/Game/src/Spin.bf", "class Spin {}\n");
		page.OnAssetExternallyModified();
		Test.Assert(page.Text(.. scope .()) == "class Spin {}\n");
		Test.Assert(!page.IsDirty);
		Test.Assert(!page.Commands.CanUndo);

		// Written outside with edits unsaved: they stay, and the user is told.
		page.Code.SetCaret(.(0, 0));
		page.Code.Type("// mine\n");
		Write(bed.Dir, "Code/Game/src/Spin.bf", "class Other {}\n");
		page.OnAssetExternallyModified();
		Test.Assert(page.IsDirty);
		Test.Assert(page.Text(.. scope .()).StartsWith("// mine\n"));
		Test.Assert(bed.LastSaid.Contains("unsaved edits"), scope String(bed.LastSaid));
	}

	[Test]
	public static void TheEditorOpensOnlyTheProjectsCodeEachFileOnce()
	{
		RegisterElements();
		let bed = scope PagesBed("scratch_source_file_pages");
		Write(bed.Dir, "Code/Game/src/Spin.bf", cGame);
		Write(bed.Dir, "Plugins/Lantern/Lantern.Engine/src/Lamp.bf", "class Lamp {}\n");
		Write(".", "scratch_source_file_outside.bf", "class Outside {}\n");
		defer DeleteFile("scratch_source_file_outside.bf");

		let error = scope String();
		let page = bed.Pages.OpenFile("Code/Game/src/Spin.bf", error);
		Test.Assert(page != null, error);
		Test.Assert(bed.Pages.Count == 1);
		Test.Assert(bed.Pages.PanelOf(page) == "file:Code/Game/src/Spin.bf");
		Test.Assert(bed.Context.ActivePage === page);
		Test.Assert(page.ProjectFile == "Code/Game/src/Spin.bf");

		// The same file by another spelling: the same page, brought forward.
		let absolute = SourceFilePage.Normalized(PathJoin(bed.Dir, "Code/./Game/../Game/src/Spin.bf", .. scope .()), .. scope .());
		Test.Assert(PathIsAbsolute(absolute));
		Test.Assert(bed.Pages.OpenFile(absolute, error) === page, error);
		Test.Assert(bed.Pages.Count == 1);

		// A Plugins/ package's file opens too.
		let lamp = bed.Pages.OpenFile("Plugins/Lantern/Lantern.Engine/src/Lamp.bf", error);
		Test.Assert(lamp != null, error);
		Test.Assert(bed.Pages.Count == 2);
		Test.Assert(bed.Context.ActivePage === lamp);

		// Outside the project, outside its code, or not there: refused, saying why.
		void Refused(StringView path, StringView why)
		{
			let refusal = scope String();
			Test.Assert(bed.Pages.OpenFile(path, refusal) == null, scope String(path));
			Test.Assert(refusal.Contains(why), refusal);
		}
		Refused("../scratch_source_file_outside.bf", "not in the project");
		Refused("Code/../../scratch_source_file_outside.bf", "not in the project");
		Refused(SourceFilePage.Normalized("scratch_source_file_outside.bf", .. scope .()), "not in the project");
		Refused("Project.xml", "not the project's code");
		Refused("Code/../Project.xml", "not the project's code");
		Refused("Code/Game/src/Missing.bf", "no file");
		Refused("", "no file named");
		Test.Assert(bed.Pages.Count == 2);

		bed.NoProject = true;
		Refused("Code/Game/src/Spin.bf", "no project");
	}

	/// Normalized takes `.` and `..` by name, against the current directory when relative.
	[Test]
	public static void APathIsNormalizedByName()
	{
		Test.Assert(SourceFilePage.Normalized("/a/./b/../c/", .. scope .()) == "/a/c");
		Test.Assert(SourceFilePage.Normalized("/../a", .. scope .()) == "/a", "a .. at the root stays there");
		Test.Assert(SourceFilePage.Normalized("/a\\b", .. scope .()) == "/a/b");
		let cwd = GetCurrentDirectory(.. scope .());
		let expected = SourceFilePage.Normalized(PathJoin(cwd, "x/y", .. scope .()), .. scope .());
		Test.Assert(SourceFilePage.Normalized("x/./z/../y", .. scope .()) == expected);
		Test.Assert(SourceFilePage.LanguageOf("Code/Game/src/Spin.bf") == "beef");
		Test.Assert(SourceFilePage.LanguageOf("Code/Plugin.xml") == "xml");
		Test.Assert(SourceFilePage.LanguageOf("Code/BeefProj.toml").IsEmpty);
	}
}
