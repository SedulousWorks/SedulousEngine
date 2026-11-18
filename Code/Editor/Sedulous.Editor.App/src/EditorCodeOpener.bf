using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

// EditorCodeOpener: where the editor opens code, by the user's Code Editor preference
// (EditorCodeEditorSettings). An outside editor gets its command with the file, line, column and
// the project's Code/ folder put in; the built-in editor opens the asset's page at the line, and a
// file in the Code folder that is no asset (a .csproj) as plain text. A command that does not start
// falls back to the built-in editor, saying so. The Code folder opens in the outside editor's
// folder command, or the system's file manager. Every way the user opens code
// comes here (the Assets browser, a log line, the menu); an agent's page_open keeps its page.

/// What an EditorCodeOpener works over. The context is borrowed; the delegates are its own.
class EditorCodeOpenerServices
{
	/// The project, the user's store, notices.
	public EditorContext Context = null;
	/// Opens (or brings forward) the page for an asset; null when it has none. Owned.
	public delegate EditorPage(Instance instance) OpenPage ~ delete _;
	/// Opens a page showing a file that is no asset as plain text; null when it cannot. Owned.
	public delegate EditorPage(StringView file) OpenFile ~ delete _;
	/// Starts a program and leaves it running; Process.LaunchDetached unless a test records it.
	/// Owned.
	public delegate bool(StringView program, Span<StringView> arguments) Launch ~ delete _;
	/// Shows a folder in the system's file manager. Owned.
	public delegate void(StringView folder) ShowFolder ~ delete _;
	/// Called before an outside editor starts, so the Code folder holds what it reads. Owned.
	public delegate void() BeforeLaunch ~ delete _;
}

class EditorCodeOpener
{
	private EditorCodeOpenerServices mServices ~ delete _;

	/// TAKES OWNERSHIP of `services`.
	public this(EditorCodeOpenerServices services)
	{
		mServices = services;
		if (mServices.Launch == null)
			mServices.Launch = new (program, arguments) => Sedulous.Core.Process.LaunchDetached(program, arguments);
	}

	/// Opens `file` (a path on disk) at `line` and `column` (1-based; 0 is the start) where the
	/// preference says, or in the built-in editor when `builtIn`. An empty `file` opens the
	/// project's Code/ folder. False when nothing opened.
	public bool Open(StringView file, uint32 line, uint32 column, bool builtIn = false)
	{
		let project = (mServices.Context != null) ? mServices.Context.Project : null;
		if (project == null)
			return false;
		let folder = project.CodeRoot(.. scope .());
		let fileCommand = scope String();
		let folderCommand = scope String();
		let outside = CodeEditorCommands.Of(Preference(), fileCommand, folderCommand);
		if (file.IsEmpty)
		{
			if (!builtIn && !folderCommand.IsEmpty && Launch(folderCommand, .(default, 0, 0, folder)))
				return true;
			if (mServices.ShowFolder == null)
				return false;
			mServices.ShowFolder(folder);
			return true;
		}
		if (!builtIn && outside)
		{
			if (Launch(fileCommand, .(file, line, column, folder)))
				return true;
			Notify(.Warning, scope $"{ProgramOf(fileCommand, .. scope .())} did not start; the file opens here instead.");
		}
		return OpenBuiltIn(project, file, line, column);
	}

	/// Opens a code asset where the preference says (the Assets browser's Open), or in the built-in
	/// editor when `builtIn`. False when it is not code, or nothing opened.
	public bool OpenAsset(Instance instance, bool builtIn = false)
	{
		let project = (mServices.Context != null) ? mServices.Context.Project : null;
		if ((project == null) || !IsCode(instance))
			return false;
		return Open(project.SourceFile(instance.SourceName, .. scope .()), 0, 0, builtIn);
	}

	/// Whether the asset's file is code (it lives in the project's Code/ folder).
	public static bool IsCode(Instance instance)
	{
		return SourcePath.AfterFolder(instance.SourceName, SourcePath.CodeFolder, let rest) && !rest.IsEmpty;
	}

	private EditorCodeEditorSettings Preference()
	{
		let user = mServices.Context.UserEditorSettings;
		return (user != null) ? user.Find<EditorCodeEditorSettings>() : null;
	}

	private bool Launch(StringView command, CodeLocation at)
	{
		let parts = scope List<String>();
		defer { ClearAndDeleteItems!(parts); }
		CodeEditorCommands.Expand(command, at, parts);
		if (parts.IsEmpty)
			return false;
		if (mServices.BeforeLaunch != null)
			mServices.BeforeLaunch();
		let arguments = scope List<StringView>();
		for (int i = 1; i < parts.Count; i++)
			arguments.Add(parts[i]);
		if (mServices.Launch(parts[0], arguments))
			return true;
		GlobalLog(.Warning, "Editor: the code editor command did not start: {}", command);
		return false;
	}

	/// The program a command starts (its first part), into `outProgram`.
	private static void ProgramOf(StringView command, String outProgram)
	{
		let parts = scope List<String>();
		defer { ClearAndDeleteItems!(parts); }
		CodeEditorCommands.Split(command, parts);
		outProgram.Append(parts.IsEmpty ? command : parts[0]);
	}

	// The asset whose file `file` is opens its page at the line; another file in the Code folder
	// opens as plain text.
	private bool OpenBuiltIn(EditorProject project, StringView file, uint32 line, uint32 column)
	{
		let name = SourceNameOf(project, file, .. scope .());
		let instance = name.IsEmpty ? null : FindBySource(project.SourceDb.RootGroup, name);
		EditorPage page = null;
		if ((instance != null) && (mServices.OpenPage != null))
			page = mServices.OpenPage(instance);
		else if ((instance == null) && (mServices.OpenFile != null) &&
			SourcePath.AfterFolder(name, SourcePath.CodeFolder, let inCode) && !inCode.IsEmpty && FileExists(file))
			page = mServices.OpenFile(file);
		if (page == null)
		{
			Notify(.Warning, scope $"No page here opens {PathFilename(file, .. scope .())}.");
			return false;
		}
		if ((line > 0) && (let code = page as ICodePage))
			code.ShowLine(line, column);
		return true;
	}

	// The source path a file on disk has: Code/ and its place under the code folder, or its place
	// under Sources/. Empty when it is under neither.
	private static void SourceNameOf(EditorProject project, StringView file, String outName)
	{
		let path = scope String(file);
		path.Replace('\\', '/');
		let code = project.CodeRoot(.. scope .());
		code.Replace('\\', '/');
		if (SourcePath.AfterFolder(path, code, let codeRest) && !codeRest.IsEmpty)
		{
			PathJoin(SourcePath.CodeFolder, codeRest, outName);
			return;
		}
		let sources = project.SourcesRoot(.. scope .());
		sources.Replace('\\', '/');
		if (SourcePath.AfterFolder(path, sources, let sourcesRest) && !sourcesRest.IsEmpty)
			outName.Append(sourcesRest);
	}

	private static Instance FindBySource(Group group, StringView name)
	{
		if (group == null)
			return null;
		for (let instance in group.Instances)
		{
			if (instance.SourceName == name)
				return instance;
		}
		for (let child in group.Groups)
		{
			if (let found = FindBySource(child, name))
				return found;
		}
		return null;
	}

	private void Notify(NoticeKind kind, StringView message)
	{
		if (mServices.Context != null)
			mServices.Context.Notify(kind, message);
	}
}
