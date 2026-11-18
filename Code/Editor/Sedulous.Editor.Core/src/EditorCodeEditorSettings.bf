using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// Where the editor opens code (Preferences > Code): its own page, or an outside editor started
/// with a command. Editor is "builtin", "vscode" or "command". A command is a program and its
/// arguments, split at spaces outside double quotes, with {file}, {line}, {column} and {folder}
/// (the project's Code/ folder) put in each argument after the split, so a path with spaces stays
/// one argument. FileCommand opens a file at a line; FolderCommand opens the folder (empty: the
/// system's file manager shows it). VS Code is a preset of the two.
[Serializable(1)]
class EditorCodeEditorSettings
{
	public const String BuiltIn = "builtin";
	public const String Command = "command";

	public String Editor = new .(BuiltIn) ~ delete _;
	public String FileCommand = new .() ~ delete _;
	public String FolderCommand = new .() ~ delete _;
}

/// A preset of the command preference: an outside editor the Code tab offers by name.
struct CodeEditorPreset
{
	/// The stored Editor value.
	public String Id;
	/// What the Code tab shows.
	public String Label;
	public String FileCommand;
	public String FolderCommand;

	public this(String id, String label, String fileCommand, String folderCommand)
	{
		Id = id;
		Label = label;
		FileCommand = fileCommand;
		FolderCommand = folderCommand;
	}
}

/// Where a code editor opens: a file on disk at a 1-based line and column (0: the start), and the
/// project's Code/ folder.
struct CodeLocation
{
	public StringView File;
	public uint32 Line;
	public uint32 Column;
	public StringView Folder;

	public this(StringView file, uint32 line, uint32 column, StringView folder)
	{
		File = file;
		Line = line;
		Column = column;
		Folder = folder;
	}
}

/// The commands the preference names and how one is filled in.
static class CodeEditorCommands
{
	/// The folder first, so a file opens in the window that has its project.
	public static readonly CodeEditorPreset[1] Presets = .(
		.("vscode", "VS Code", "code {folder} --goto {file}:{line}:{column}", "code {folder}"));

	/// The commands `settings` names, into the two: a preset's, the user's (trimmed) for "command",
	/// and none (both left empty) for the built-in page or an id this build does not know. True
	/// when code opens outside (a file command is set).
	public static bool Of(EditorCodeEditorSettings settings, String outFileCommand, String outFolderCommand)
	{
		outFileCommand.Clear();
		outFolderCommand.Clear();
		if (settings == null)
			return false;
		if (settings.Editor == EditorCodeEditorSettings.Command)
		{
			outFileCommand.Append(settings.FileCommand);
			outFileCommand.Trim();
			outFolderCommand.Append(settings.FolderCommand);
			outFolderCommand.Trim();
		}
		else
		{
			for (let preset in Presets)
			{
				if (settings.Editor == preset.Id)
				{
					outFileCommand.Append(preset.FileCommand);
					outFolderCommand.Append(preset.FolderCommand);
					break;
				}
			}
		}
		return !outFileCommand.IsEmpty;
	}

	/// Splits a command into its program and arguments, appended to `outParts` (new strings, the
	/// caller's): at spaces and tabs outside double quotes, the quotes removed. An empty command
	/// gives none.
	public static void Split(StringView command, List<String> outParts)
	{
		String part = null;
		bool quoted = false;
		for (let c in command)
		{
			if (c == '"')
			{
				quoted = !quoted;
				if (part == null)
					part = new .();
			}
			else if (!quoted && ((c == ' ') || (c == '\t')))
			{
				if (part != null)
					outParts.Add(part);
				part = null;
			}
			else
			{
				if (part == null)
					part = new .();
				part.Append(c);
			}
		}
		if (part != null)
			outParts.Add(part);
	}

	/// The command split (Split), the location put in each part's placeholders: the program first,
	/// then its arguments, appended to `outParts` (the caller's). A line or column of 0 is written 1.
	public static void Expand(StringView command, CodeLocation at, List<String> outParts)
	{
		let line = scope String()..AppendF("{}", Math.Max(at.Line, 1));
		let column = scope String()..AppendF("{}", Math.Max(at.Column, 1));
		StringView[4] names = .("{file}", "{line}", "{column}", "{folder}");
		StringView[4] values = .(at.File, line, column, at.Folder);
		let first = outParts.Count;
		Split(command, outParts);
		let expanded = scope String();
		for (int p = first; p < outParts.Count; p++)
		{
			let text = outParts[p];
			expanded.Clear();
			int i = 0;
			while (i < text.Length)
			{
				let rest = StringView(text, i);
				int which = 0;
				while ((which < 4) && !rest.StartsWith(names[which]))
					which++;
				if (which < 4)
				{
					expanded.Append(values[which]);
					i += names[which].Length;
				}
				else
				{
					expanded.Append(text[i]);
					i++;
				}
			}
			text.Set(expanded);
		}
	}
}
