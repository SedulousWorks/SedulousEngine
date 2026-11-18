using System;
using System.Collections;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Script.Tests;

/// With AngelScript registered: its declarations always, and VS Code's extension and settings only
/// when asked for.
class CodeToolingFilesTests
{
	private static CodeToolingFile Named(List<CodeToolingFile> files, StringView path)
	{
		for (let file in files)
		{
			if (file.Path == path)
				return file;
		}
		return null;
	}

	[Test]
	public static void AngelScriptsDeclarationsAndVSCodesFilesOnlyWhenAskedFor()
	{
		ScriptSourceDocumentTests.EnsureCook();
		AngelScriptBackend.Register();
		let plain = scope List<CodeToolingFile>();
		defer { ClearAndDeleteItems!(plain); }
		CodeTooling.Files(false, plain);
		for (let file in plain)
			Test.Assert(!file.Path.StartsWith(".vscode/"), file.Path);
		let declarations = Named(plain, "as.predefined");
		Test.Assert(declarations != null);
		Test.Assert(!declarations.UserMay);
		Test.Assert(!declarations.Text.IsEmpty);

		let vscode = scope List<CodeToolingFile>();
		defer { ClearAndDeleteItems!(vscode); }
		CodeTooling.Files(true, vscode);
		let extensions = Named(vscode, ".vscode/extensions.json");
		let settings = Named(vscode, ".vscode/settings.json");
		Test.Assert((extensions != null) && (settings != null));
		Test.Assert(extensions.UserMay && settings.UserMay);
		Test.Assert(extensions.Text.Contains("\"recommendations\": [\n        \"sashi0034.angel-lsp\"\n    ]"), extensions.Text);
		// angel-lsp needs no settings: an empty object.
		Test.Assert(settings.Text == "{}\n", settings.Text);
	}
}
