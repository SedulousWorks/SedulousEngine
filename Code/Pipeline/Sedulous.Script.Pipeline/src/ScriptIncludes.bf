using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Script.Resource;

namespace Sedulous.Script.Pipeline;

/// Reads the files a script includes, through whatever its caller reads the project's sources
/// with (the cook's mount, the editor's project folder). `path` is resolved (ScriptIncludes.Resolve).
interface IScriptIncludeReader
{
	bool Read(StringView path, String outText);
}

/// Included files read from a folder on disk: a project's sources root (the editor's check, an
/// agent's validation, an export's check), where the cook reads through its mount instead.
class FolderIncludeReader : IScriptIncludeReader
{
	private String mRoot = new .() ~ delete _;

	public this(StringView root)
	{
		mRoot.Set(root);
	}

	public bool Read(StringView path, String outText)
	{
		if (mRoot.IsEmpty)
			return false;
		let bytes = scope List<uint8>();
		if (ReadFile(PathJoin(mRoot, path, .. scope .()), bytes) case .Err)
			return false;
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
		return true;
	}
}

/// The one rule for a script's includes, from the cook to the run.
static class ScriptIncludes
{
	/// Where `#include "<include>"` points: relative to the folder of `from` (the including file,
	/// a path in the project's sources), with "." and ".." resolved and '/' between the parts.
	/// False for an absolute path, a drive or scheme, or one that would leave the sources.
	public static bool Resolve(StringView from, StringView include, String outPath)
	{
		if (include.IsEmpty || PathIsAbsolute(include) || include.Contains(':'))
			return false;
		let parent = PathParent(from, .. scope .());
		let parts = scope List<StringView>();
		if (!AppendParts(parent, parts) || !AppendParts(include, parts) || parts.IsEmpty)
			return false;
		outPath.Clear();
		for (let part in parts)
		{
			if (!outPath.IsEmpty)
				outPath.Append('/');
			outPath.Append(part);
		}
		return true;
	}

	/// Appends `path`'s parts, "." skipped and ".." taking one back; false past the root.
	private static bool AppendParts(StringView path, List<StringView> parts)
	{
		int start = 0;
		for (int i = 0; i <= path.Length; i++)
		{
			if ((i < path.Length) && (path[i] != '/') && (path[i] != '\\'))
				continue;
			let part = path.Substring(start, i - start);
			start = i + 1;
			if (part.IsEmpty || (part == "."))
				continue;
			if (part == "..")
			{
				if (parts.IsEmpty)
					return false;
				parts.PopBack();
				continue;
			}
			parts.Add(part);
		}
		return true;
	}

	/// Every file `source` (the file `sourceName`) includes, and every file those include, each
	/// once, in the order first named: resolved, read through `reader`, appended to `outIncludes`.
	/// False, the problem said, for a path that leaves the sources or a file that cannot be read
	/// (with no reader, none can).
	public static bool Gather(IScriptLanguageCook cook, StringView sourceName, StringView source, IScriptIncludeReader reader,
		List<ScriptIncludedSource> outIncludes, List<String> problems)
	{
		let pending = scope List<(String file, String text)>();
		defer { for (let p in pending) { delete p.file; delete p.text; } }
		pending.Add((new String(sourceName), new String(source)));
		for (int next = 0; next < pending.Count; next++)
		{
			let (file, text) = pending[next];
			let named = scope List<String>();
			defer { ClearAndDeleteItems!(named); }
			cook.ListIncludes(text, named);
			for (let include in named)
			{
				let resolved = scope String();
				if (!Resolve(file, include, resolved))
				{
					problems.Add(new $"{file}: #include \"{include}\" leaves the project's sources");
					return false;
				}
				bool known = (resolved == sourceName);
				for (let i in outIncludes)
					known |= (i.Path == resolved);
				if (known)
					continue;
				let read = scope String();
				if ((reader == null) || !reader.Read(resolved, read))
				{
					problems.Add(new $"{file}: #include \"{include}\": {resolved} could not be read");
					return false;
				}
				let included = new ScriptIncludedSource();
				included.Path.Set(resolved);
				included.Source.Set(read);
				outIncludes.Add(included);
				pending.Add((new String(resolved), new String(read)));
			}
		}
		return true;
	}
}
