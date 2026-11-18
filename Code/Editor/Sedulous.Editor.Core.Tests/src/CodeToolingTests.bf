using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// The tooling files an outside code editor reads in the Code folder: a generated file is written
/// when it differs; a file a user may edit is written when missing and again only while it is what
/// was last written, never over an edit or a file that was there first.
static class CodeToolingTests
{
	private static void ReadText(StringView path, String outText)
	{
		System.IO.File.ReadAllText(path, outText, true).IgnoreError();
	}

	private static void WriteText(StringView path, StringView text)
	{
		Test.Assert(System.IO.File.WriteAllText(path, text) case .Ok);
	}

	[Test]
	public static void GeneratedFilesFollowAUsersEditIsKeptAFileThereFirstIsTheUsers()
	{
		let root = "scratch_code_tooling";
		RemoveDirectoryRecursive(root);
		defer RemoveDirectoryRecursive(root);
		let code = PathJoin(root, "Code", .. scope .());
		let ledger = PathJoin(root, ".cache/code-tooling.txt", .. scope .());
		let declarations = PathJoin(code, "as.predefined", .. scope .());
		let settingsPath = PathJoin(code, ".vscode/settings.json", .. scope .());
		let extensionsPath = PathJoin(code, ".vscode/extensions.json", .. scope .());

		let files = scope List<CodeToolingFile>();
		defer { ClearAndDeleteItems!(files); }
		files.Add(new .("as.predefined", "class A {}\n", false));
		files.Add(new .(".vscode/settings.json", "{ \"a\": 1 }\n", true));
		files.Add(new .(".vscode/extensions.json", "{ }\n", true));
		// A user's extensions.json, there before anything was written.
		Test.Assert(CreateDirectory(PathJoin(code, ".vscode", .. scope .())));
		WriteText(extensionsPath, "{ \"mine\": true }\n");

		Test.Assert(CodeTooling.Keep(code, ledger, files) == 2);
		Test.Assert(ReadText(declarations, .. scope .()) == "class A {}\n");
		Test.Assert(ReadText(settingsPath, .. scope .()) == "{ \"a\": 1 }\n");
		Test.Assert(ReadText(extensionsPath, .. scope .()) == "{ \"mine\": true }\n");
		Test.Assert(CodeTooling.Keep(code, ledger, files) == 0, "nothing changed");

		// The API changed: the declarations and the settings nobody edited are written again.
		files[0].Text.Set("class A {}\nclass B {}\n");
		files[1].Text.Set("{ \"a\": 2 }\n");
		Test.Assert(CodeTooling.Keep(code, ledger, files) == 2);
		Test.Assert(ReadText(settingsPath, .. scope .()) == "{ \"a\": 2 }\n");

		// The user edits both; the declarations are generated and written again, the settings kept.
		WriteText(declarations, "// edited\n");
		WriteText(settingsPath, "{ \"a\": 2, \"mine\": 3 }\n");
		files[1].Text.Set("{ \"a\": 3 }\n");
		Test.Assert(CodeTooling.Keep(code, ledger, files) == 1);
		Test.Assert(ReadText(declarations, .. scope .()) == files[0].Text);
		Test.Assert(ReadText(settingsPath, .. scope .()) == "{ \"a\": 2, \"mine\": 3 }\n");

		// A file the user removed is written again.
		Test.Assert(System.IO.File.Delete(settingsPath) case .Ok);
		Test.Assert(CodeTooling.Keep(code, ledger, files) == 1);
		Test.Assert(ReadText(settingsPath, .. scope .()) == "{ \"a\": 3 }\n");
	}
}
