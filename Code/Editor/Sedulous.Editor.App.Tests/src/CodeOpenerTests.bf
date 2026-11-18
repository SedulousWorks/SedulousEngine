using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Settings;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;
using internal Sedulous.Content;

namespace Sedulous.Editor.App.Tests;

/// Where code opens, over a scratch project with one script asset in Code/: the built-in page at
/// the line by default; an outside editor's command with the location put in when the preference
/// names one; the built-in page, with a warning, when that command does not start; the Code folder
/// in the folder command or the file manager; Open in Built-in Editor whatever the preference; and
/// a file in the Code folder that is no asset as plain text.
static class CodeOpenerTests
{
	/// A code page that records where it was asked to show.
	private class LinePage : EditorPage, ICodePage
	{
		public uint32 Line = 0;
		public uint32 Column = 0;
		public override StringView Title => "Player";
		public override Result<void, ErrorCode> Save() => .Ok;

		public void ShowLine(uint32 line, uint32 column)
		{
			Line = line;
			Column = column;
		}
	}

	private class Bed
	{
		public const String cDir = "scratch_code_opener_project";
		public EditorContext Context = new .() ~ delete _;
		public Settings User = new .() ~ delete _;
		public EditorProject Project = null;
		public EditorCodeOpener Opener = null;
		/// Borrowed from the project's database.
		public Instance Script = null;
		public LinePage Page = new .() ~ delete _;
		/// Borrowed from the project's database.
		public List<Instance> Opened = new .() ~ delete _;
		/// Each start: the program, then its arguments.
		public List<List<String>> Launched = new .() ~ { for (let call in _) DeleteContainerAndItems!(call); delete _; };
		public bool LaunchStarts = true;
		/// How many times the Code folder was asked to be ready for an outside editor.
		public int BeforeLaunches = 0;
		public List<String> ShownFolders = new .() ~ DeleteContainerAndItems!(_);
		public List<String> Warnings = new .() ~ DeleteContainerAndItems!(_);

		public this()
		{
			RemoveDirectoryRecursive(cDir);
			Test.Assert(EditorProject.Create(cDir, "Opener") case .Ok);
			Project = EditorProject.Open(cDir);
			Test.Assert(Project != null);
			Script = Project.SourceDb.RootGroup.CreateInstance("Player", "OpenerAsset");
			Test.Assert(Script != null);
			Script.SetSourceName("Code/Scripts/Player.cs");
			Context.SetProject(Project);
			Context.UserEditorSettings = User;
			Context.OnNotice = new (kind, message) =>
				{
					if (kind == .Warning)
						Warnings.Add(new String(message));
				};
			let services = new EditorCodeOpenerServices();
			services.Context = Context;
			services.OpenPage = new (instance) =>
				{
					Opened.Add(instance);
					return Page;
				};
			services.Launch = new (program, arguments) =>
				{
					let call = new List<String>();
					call.Add(new String(program));
					for (let argument in arguments)
						call.Add(new String(argument));
					Launched.Add(call);
					return LaunchStarts;
				};
			services.ShowFolder = new (folder) => { ShownFolders.Add(new String(folder)); };
			services.BeforeLaunch = new () => { BeforeLaunches++; };
			Opener = new EditorCodeOpener(services);
		}

		public ~this()
		{
			delete Opener;
			Context.UserEditorSettings = null;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(cDir);
		}

		public void ScriptFile(String outPath) => Project.SourceFile("Code/Scripts/Player.cs", outPath);
		public void CodeRoot(String outPath) => Project.CodeRoot(outPath);

		public void Prefer(StringView editorId, StringView fileCommand = default, StringView folderCommand = default)
		{
			let code = User.Section<EditorCodeEditorSettings>();
			code.Editor.Set(editorId);
			code.FileCommand.Set(fileCommand);
			code.FolderCommand.Set(folderCommand);
		}
	}

	[Test]
	public static void WithNoPreferenceAFileOpensItsAssetsPageAtTheLine()
	{
		let bed = scope Bed();
		Test.Assert(bed.Opener.Open(bed.ScriptFile(.. scope .()), 12, 4));
		Test.Assert(bed.Opened.Count == 1);
		Test.Assert(bed.Opened[0] == bed.Script);
		Test.Assert(bed.Page.Line == 12);
		Test.Assert(bed.Page.Column == 4);
		Test.Assert(bed.Launched.IsEmpty);

		// A file no asset names opens nothing, and says so.
		Test.Assert(!bed.Opener.Open(PathJoin(bed.CodeRoot(.. scope .()), "Holdout.csproj", .. scope .()), 0, 0));
		Test.Assert(bed.Warnings.Count == 1);
	}

	[Test]
	public static void VSCodeGetsTheFolderAndTheFileAtItsLineACodeAssetOpensThereToo()
	{
		let bed = scope Bed();
		bed.Prefer("vscode");
		let file = bed.ScriptFile(.. scope .());
		Test.Assert(bed.Opener.Open(file, 7, 0));
		Test.Assert(bed.Launched.Count == 1);
		let call = bed.Launched[0];
		Test.Assert(call.Count == 4);
		Test.Assert(call[0] == "code");
		Test.Assert(call[1] == bed.CodeRoot(.. scope .()));
		Test.Assert(call[2] == "--goto");
		Test.Assert(call[3] == scope $"{file}:7:1");
		Test.Assert(bed.Opened.IsEmpty);
		Test.Assert(bed.BeforeLaunches == 1, "the Code folder made ready before the editor starts");

		Test.Assert(bed.Opener.OpenAsset(bed.Script));
		Test.Assert(bed.Launched.Count == 2);
		Test.Assert(bed.Opened.IsEmpty);

		// Open in Built-in Editor takes the page whatever is preferred.
		Test.Assert(bed.Opener.OpenAsset(bed.Script, true));
		Test.Assert(bed.Launched.Count == 2);
		Test.Assert(bed.Opened.Count == 1);
		Test.Assert(bed.BeforeLaunches == 2, "none for the built-in editor");
	}

	[Test]
	public static void ACommandThatDoesNotStartOpensThePageInsteadWithAWarning()
	{
		let bed = scope Bed();
		bed.Prefer("command", "\"my editor\" {file} -l {line}");
		bed.LaunchStarts = false;
		Test.Assert(bed.Opener.Open(bed.ScriptFile(.. scope .()), 3, 0));
		Test.Assert(bed.Launched.Count == 1);
		Test.Assert(bed.Launched[0][0] == "my editor");
		Test.Assert(bed.Launched[0][3] == "3");
		Test.Assert(bed.Opened.Count == 1);
		Test.Assert(bed.Warnings.Count == 1);
		Test.Assert(bed.Warnings[0].StartsWith("my editor"));
	}

	[Test]
	public static void TheCodeFolderOpensInTheFolderCommandElseTheFileManager()
	{
		let bed = scope Bed();
		let codeRoot = bed.CodeRoot(.. scope .());
		Test.Assert(bed.Opener.Open(default, 0, 0));
		Test.Assert(bed.ShownFolders.Count == 1);
		Test.Assert(bed.ShownFolders[0] == codeRoot);

		bed.Prefer("vscode");
		Test.Assert(bed.Opener.Open(default, 0, 0));
		Test.Assert(bed.Launched.Count == 1);
		Test.Assert(bed.Launched[0].Count == 2);
		Test.Assert(bed.Launched[0][1] == codeRoot);
		Test.Assert(bed.ShownFolders.Count == 1);

		// A command with no folder command shows the folder in the file manager.
		bed.Prefer("command", "ed {file}");
		Test.Assert(bed.Opener.Open(default, 0, 0));
		Test.Assert(bed.Launched.Count == 1);
		Test.Assert(bed.ShownFolders.Count == 2);
	}

	[Test]
	public static void AFileInTheCodeFolderThatIsNoAssetOpensAsPlainText()
	{
		let bed = scope Bed();
		let files = scope List<String>();
		defer { ClearAndDeleteItems!(files); }
		// The bed's opener again, now with a text page to open.
		let services = new EditorCodeOpenerServices();
		services.Context = bed.Context;
		services.OpenPage = new (instance) => bed.Page;
		services.OpenFile = new [=files, =bed] (file) =>
			{
				files.Add(new String(file));
				return bed.Page;
			};
		let opener = scope EditorCodeOpener(services);

		let codeRoot = bed.CodeRoot(.. scope .());
		let project = PathJoin(codeRoot, "Opener.csproj", .. scope .());
		Test.Assert(System.IO.Directory.CreateDirectory(codeRoot) case .Ok);
		Test.Assert(System.IO.File.WriteAllText(project, "<Project/>") case .Ok);
		Test.Assert(opener.Open(project, 2, 0));
		Test.Assert(files.Count == 1);
		Test.Assert(files[0] == project);
		Test.Assert(bed.Page.Line == 2);

		// A file outside the Code folder, or one not there, is not opened.
		let outside = PathJoin(bed.Project.SourcesRoot(.. scope .()), "notes.txt", .. scope .());
		Test.Assert(System.IO.File.WriteAllText(outside, "x") case .Ok);
		Test.Assert(!opener.Open(outside, 0, 0));
		Test.Assert(!opener.Open(PathJoin(codeRoot, "gone.luaurc", .. scope .()), 0, 0));
		Test.Assert(files.Count == 1);
	}
}
