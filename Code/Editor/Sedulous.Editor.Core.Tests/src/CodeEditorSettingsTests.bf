using System;
using System.Collections;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// The code editor preference: which commands it names, how a command splits into a program and
/// its arguments, and how a location fills its placeholders.
static class CodeEditorSettingsTests
{
	[Test]
	public static void ACommandSplitsAtSpacesOutsideDoubleQuotes()
	{
		let parts = scope List<String>();
		defer { ClearAndDeleteItems!(parts); }
		CodeEditorCommands.Split("  \"C:/Program Files/Ed/ed.exe\"  -g \"{file}\":{line}\t{folder} ", parts);
		Test.Assert(parts.Count == 4);
		Test.Assert(parts[0] == "C:/Program Files/Ed/ed.exe");
		Test.Assert(parts[1] == "-g");
		Test.Assert(parts[2] == "{file}:{line}");
		Test.Assert(parts[3] == "{folder}");

		let blank = scope List<String>();
		CodeEditorCommands.Split("   ", blank);
		Test.Assert(blank.IsEmpty);

		// An empty quoted argument is still an argument.
		let empty = scope List<String>();
		defer { ClearAndDeleteItems!(empty); }
		CodeEditorCommands.Split("ed \"\"", empty);
		Test.Assert(empty.Count == 2);
		Test.Assert(empty[1].IsEmpty);
	}

	[Test]
	public static void PlaceholdersFillEachArgumentAPathWithSpacesStayingOne()
	{
		let parts = scope List<String>();
		defer { ClearAndDeleteItems!(parts); }
		CodeEditorCommands.Expand("code {folder} --goto {file}:{line}:{column}",
			.("/home/me/My Game/Code/Scripts/Player.cs", 12, 5, "/home/me/My Game/Code"), parts);
		Test.Assert(parts.Count == 4);
		Test.Assert(parts[0] == "code");
		Test.Assert(parts[1] == "/home/me/My Game/Code");
		Test.Assert(parts[2] == "--goto");
		Test.Assert(parts[3] == "/home/me/My Game/Code/Scripts/Player.cs:12:5");

		// No line or column opens at the start; an unknown brace is left as written.
		let plain = scope List<String>();
		defer { ClearAndDeleteItems!(plain); }
		CodeEditorCommands.Expand("ed +{line}:{column} {file} {other}", .("a.luau", 0, 0, default), plain);
		Test.Assert(plain.Count == 4);
		Test.Assert(plain[1] == "+1:1");
		Test.Assert(plain[2] == "a.luau");
		Test.Assert(plain[3] == "{other}");
	}

	[Test]
	public static void ThePreferenceNamesAPresetsCommandsTheUsersOrNone()
	{
		let file = scope String();
		let folder = scope String();
		Test.Assert(!CodeEditorCommands.Of(null, file, folder));
		let settings = scope EditorCodeEditorSettings();
		Test.Assert(!CodeEditorCommands.Of(settings, file, folder)); // built-in by default

		settings.Editor.Set("vscode");
		Test.Assert(CodeEditorCommands.Of(settings, file, folder));
		Test.Assert(file.StartsWith("code "));
		Test.Assert(folder == "code {folder}");

		settings.Editor.Set("command");
		settings.FileCommand.Set("  zed {file}:{line}  ");
		Test.Assert(CodeEditorCommands.Of(settings, file, folder));
		Test.Assert(file == "zed {file}:{line}");
		Test.Assert(folder.IsEmpty);

		// A command with nothing in it is the built-in page, as is an editor this build does not know.
		settings.FileCommand.Set("   ");
		Test.Assert(!CodeEditorCommands.Of(settings, file, folder));
		settings.Editor.Set("someday");
		Test.Assert(!CodeEditorCommands.Of(settings, file, folder));
	}
}
