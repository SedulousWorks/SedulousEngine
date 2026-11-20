using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Script;
using Sedulous.Script.Pipeline;

namespace Sedulous.Editor.Project;

// The files an outside code editor reads in a project's Code folder, so it completes and checks
// the scripts against the engine's API. Each language with declarations writes its file
// (AngelScript's as.predefined) from the API its checks use, so the file follows the engine and the
// plugins loaded. For VS Code, .vscode/extensions.json recommends each language's extension and
// .vscode/settings.json points them at the declarations.
//
// The declarations are generated, so they are written whenever they differ. A file a user may edit
// (the VS Code ones) is written when it is missing, and afterwards only while it is still what was
// last written: a ledger in the project's cache keeps the hash of each file written, and a file
// whose hash differs, or that was there before the ledger knew it, is the user's and is left.

/// One tooling file: its path under the Code folder (forward slashes), its text, and whether a user
/// may edit it (then it is not written over their edit).
class CodeToolingFile
{
	public String Path = new .() ~ delete _;
	public String Text = new .() ~ delete _;
	public bool UserMay;

	public this(StringView path, StringView text, bool userMay)
	{
		Path.Set(path);
		Text.Set(text);
		UserMay = userMay;
	}
}

static class CodeTooling
{
	/// Where Keep keeps what it wrote, in a project's cache folder.
	public const String LedgerFile = "code-tooling.txt";

	/// Whether `pathInCode`, a path under the Code folder with forward slashes ("as.predefined",
	/// ".vscode/settings.json"), is a file written here for an outside editor: a language's
	/// declarations or a VS Code file. It is not the project's code, whatever its extension.
	public static bool IsToolingFile(StringView pathInCode)
	{
		if ((pathInCode == ".vscode/extensions.json") || (pathInCode == ".vscode/settings.json"))
			return true;
		return ScriptLanguageCooks.IsDeclarationsFile(pathInCode);
	}

	/// The tooling files for the registered script languages, appended to `outFiles` (the
	/// caller's): each one's declarations, and with `vscode` the two VS Code files. A language
	/// without a cook or declarations adds none.
	public static void Files(bool vscode, List<CodeToolingFile> outFiles)
	{
		let extensions = scope List<String>();
		defer { ClearAndDeleteItems!(extensions); }
		// "key": value, one per entry.
		let settings = scope List<String>();
		defer { ClearAndDeleteItems!(settings); }
		let languages = scope List<String>();
		defer { ClearAndDeleteItems!(languages); }
		ScriptBackends.CollectLanguages(languages);
		for (let language in languages)
		{
			if (let cook = ScriptLanguageCooks.Find(language))
			{
				let fileName = scope String();
				let text = scope String();
				if (cook.Declarations(fileName, text) && !fileName.IsEmpty)
					outFiles.Add(new CodeToolingFile(fileName, text, false));
			}
			let tooling = ScriptBackends.EditorTooling(language);
			if (tooling == null)
				continue;
			if (!tooling.VscodeExtension.IsEmpty)
				extensions.Add(new String(tooling.VscodeExtension));
			for (let setting in tooling.VscodeSettings)
				settings.Add(new String()..AppendF("\"{}\": {}", setting.Key, setting.Json));
		}
		if (!vscode)
			return;
		let recommendations = AppendList(extensions, "[", "    ]", "        ", true, .. scope .());
		outFiles.Add(new CodeToolingFile(".vscode/extensions.json", scope String()..AppendF("{{\n    \"recommendations\": {}\n}}\n", recommendations), true));
		outFiles.Add(new CodeToolingFile(".vscode/settings.json", AppendList(settings, "{", "}\n", "    ", false, .. scope .()), true));
	}

	/// `items` as a JSON list or object body: each on its own line after `open`, indented, then
	/// `close`; `quoted` puts each in quotes.
	private static void AppendList(List<String> items, StringView open, StringView close, StringView indent, bool quoted, String outText)
	{
		outText.Append(open);
		for (int i < items.Count)
		{
			outText.Append((i == 0) ? "\n" : ",\n");
			outText.Append(indent);
			if (quoted)
				outText.Append('"');
			outText.Append(items[i]);
			if (quoted)
				outText.Append('"');
		}
		if (!items.IsEmpty)
			outText.Append('\n');
		outText.Append(close);
	}

	/// Writes `files` under `codeRoot` as the rules above say, keeping their hashes in the ledger at
	/// `ledgerPath`. Returns how many it wrote.
	public static int Keep(StringView codeRoot, StringView ledgerPath, Span<CodeToolingFile> files)
	{
		// The ledger: a line per file written, its hash, a space, its path.
		let ledger = scope List<(String Path, String Hash)>();
		defer { for (let entry in ledger) { delete entry.Path; delete entry.Hash; } }
		let ledgerText = scope String();
		if (System.IO.File.ReadAllText(ledgerPath, ledgerText, true) case .Ok)
		{
			for (let line in ledgerText.Split('\n'))
			{
				let space = line.IndexOf(' ');
				if (space > 0)
					ledger.Add((new String(line, space + 1), new String(line, 0, space)));
			}
		}

		int written = 0;
		bool changed = false;
		for (let file in files)
		{
			let onDisk = PathJoin(codeRoot, file.Path, .. scope .());
			let wanted = HashOf(file.Text, .. scope .());
			int known = -1;
			for (int i < ledger.Count)
			{
				if (ledger[i].Path == file.Path)
					known = i;
			}
			let there = scope String();
			if (System.IO.File.ReadAllText(onDisk, there, true) case .Ok)
			{
				let present = HashOf(there, .. scope .());
				if (present == wanted)
				{
					if (known < 0)
					{
						ledger.Add((new String(file.Path), new String(wanted))); // as it would have been written
						changed = true;
					}
					continue;
				}
				// The user's: edited since it was written, or there before the ledger knew it.
				if (file.UserMay && ((known < 0) || (ledger[known].Hash != present)))
					continue;
			}
			let parent = PathParent(onDisk, .. scope .());
			CreateDirectory(parent);
			if (System.IO.File.WriteAllText(onDisk, file.Text) case .Err)
			{
				GlobalLog(.Warning, "Project: {} could not be written", onDisk);
				continue;
			}
			written++;
			changed = true;
			if (known >= 0)
				ledger[known].Hash.Set(wanted);
			else
				ledger.Add((new String(file.Path), new String(wanted)));
		}
		if (changed)
		{
			let text = scope String();
			for (let entry in ledger)
				text.AppendF("{} {}\n", entry.Hash, entry.Path);
			CreateDirectory(PathParent(ledgerPath, .. scope .()));
			if (System.IO.File.WriteAllText(ledgerPath, text) case .Err)
				GlobalLog(.Warning, "Project: {} could not be written", ledgerPath);
		}
		return written;
	}

	private static void HashOf(StringView text, String outHex)
	{
		Sha256.Of(.((uint8*)text.Ptr, text.Length)).ToHex(outHex);
	}
}
