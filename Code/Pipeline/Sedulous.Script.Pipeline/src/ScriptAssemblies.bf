using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Pipeline.Importer;
using Sedulous.VFS;

namespace Sedulous.Script.Pipeline;

/// Finding a project assembly and what it builds from: the project that holds a source file, and
/// the sources under a project's folder.
static class ScriptAssemblies
{
	/// The stored type name of a project's asset.
	public const String cAssetType = "Sedulous.Script.Pipeline.ScriptAssemblyAsset";

	/// The project assembly a `language` source file at `file` (a path in the sources) builds
	/// into: the ScriptAssemblyAsset of that language whose project file's folder holds `file`, the
	/// nearest when projects nest. Null when no project holds it.
	public static Instance FindFor(IContentDatabase sourceDb, StringView language, StringView file)
	{
		if ((sourceDb == null) || (sourceDb.RootGroup == null))
			return null;
		Instance best = null;
		int bestDepth = 0;
		FindIn(sourceDb.RootGroup, language, file, ref best, ref bestDepth);
		return best;
	}

	private static void FindIn(Group group, StringView language, StringView file, ref Instance best, ref int bestDepth)
	{
		for (let instance in group.Instances)
		{
			if (instance.TypeName != cAssetType)
				continue;
			let object = instance.ReadObject();
			defer { if (object != null) delete object; }
			let project = object as ScriptAssemblyAsset;
			if ((project == null) || (project.Language != language))
				continue;
			let folder = PathParent(project.FileName.Value, .. scope .());
			if (!folder.IsEmpty && !PathIsInside(file, folder))
				continue;
			// The nearest project: the deepest folder holding the file.
			if ((best == null) || (folder.Length + 1 > bestDepth))
			{
				best = instance;
				bestDepth = folder.Length + 1;
			}
		}
		for (let child in group.Groups)
			FindIn(child, language, file, ref best, ref bestDepth);
	}

	/// Every file under `folder` (a path in the sources; empty for the root) whose extension is
	/// `suffix` (lowercase, no dot), through `sources`, into `outPaths`, sorted so a build reads
	/// its sources in one order on every machine. Build output folders (bin, obj) are passed over.
	public static void ListSourcesUnder(IFileSystem sources, StringView folder, StringView suffix, List<String> outPaths)
	{
		let enumerable = sources as IEnumerableFileSystem;
		if (enumerable == null)
			return;
		let start = outPaths.Count;
		ListIn(enumerable, folder, suffix, outPaths);
		outPaths.Sort(scope (a, b) => CompareOrdinal(a, b), start, outPaths.Count - start);
	}

	private static void ListIn(IEnumerableFileSystem files, StringView folder, StringView suffix, List<String> outPaths)
	{
		let entries = scope List<DirEntry>();
		defer
		{
			for (var entry in ref entries)
				entry.Dispose();
		}
		if (files.Enumerate(folder, entries) case .Err)
			return;
		for (let entry in entries)
		{
			let path = scope String();
			if (folder.IsEmpty)
				path.Set(entry.Name);
			else
				PathJoin(folder, entry.Name, path);
			if (entry.IsDirectory)
			{
				// An IDE's build of the project writes into these; they are not sources.
				if ((entry.Name != "bin") && (entry.Name != "obj"))
					ListIn(files, path, suffix, outPaths);
				continue;
			}
			if (ImportPaths.ExtensionLower(entry.Name, .. scope .()) == suffix)
				outPaths.Add(new String(path));
		}
	}

	/// Byte by byte, so the order is the same whatever the host's culture.
	private static int CompareOrdinal(StringView a, StringView b)
	{
		let count = Math.Min(a.Length, b.Length);
		for (int i < count)
		{
			if (a[i] != b[i])
				return (uint8)a[i] <=> (uint8)b[i];
		}
		return a.Length <=> b.Length;
	}
}
