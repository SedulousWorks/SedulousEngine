using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.Project;

/// One file-backed asset as EditorProject.PlaceInGroupFolders reads it: the file it names, the
/// folder its group asks for, and the files that move with it (a .gltf's sidecars).
class PlacedFile
{
	public Instance Instance;
	public String File = new .() ~ delete _;
	public String Folder = new .() ~ delete _;
	public List<String> Companions = new .() ~ DeleteContainerAndItems!(_);
}

/// A project's files follow its asset groups: each asset's file sits in its group's folder,
/// Sources/<group>/, or Code/<group>/ for code (Asset.IsCode).
extension EditorProject
{
	/// Puts the files of `assets` in their groups' folders (Sources/<group>/, Code/<group>/ for
	/// code): each file not there moves, with its companions (a .gltf's sidecars), and every
	/// asset naming it or a companion follows (ids kept, the import ledger's origins carried). A
	/// file assets in different groups share stays where it is, and so does another asset's
	/// companion, which moves only with that asset's file; a name taken in the folder takes the
	/// next free one ("a.2.png"). Folders a move leaves empty go. Run for the assets a move or a
	/// group rename touched, and for all of an older project's at open. Answers how many files
	/// moved.
	public int PlaceInGroupFolders(Span<Instance> assets)
	{
		let ledger = ImportPaths.ImportLedgerPath(CacheRoot(.. scope .()), .. scope .());
		// Every asset's file and the folder its group asks for, across the whole project: a file
		// moves only when every asset naming it asks for the same folder.
		let placed = scope List<PlacedFile>();
		defer { ClearAndDeleteItems!(placed); }
		let all = scope List<Instance>();
		ExportStaging.CollectAllInstances(SourceDb.RootGroup, all);
		for (let instance in all)
		{
			if (instance.SourceName.IsEmpty)
				continue; // names no file: nothing to place, and no read
			let object = instance.ReadObject();
			if (object == null)
				continue;
			defer delete object;
			let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Asset;
			if ((asset == null) || asset.FileName.IsEmpty)
				continue;
			let entry = new PlacedFile();
			entry.Instance = instance;
			entry.File.Set(asset.FileName.Value);
			ImportPaths.GroupFolder(instance.OwningGroup, asset.IsCode ? StringView(SourcePath.CodeFolder) : StringView(), entry.Folder);
			asset.CompanionFiles(SourceFile(entry.File, .. scope .()), entry.Companions);
			placed.Add(entry);
		}

		// Another file's companions, beside it: they keep their places relative to it, so they
		// move with it and never on their own (a model's texture in its tex/ folder).
		// Each companion once per file it belongs to, however many assets name that file.
		let pinned = scope List<String>();
		defer { ClearAndDeleteItems!(pinned); }
		let pinnedBy = scope List<String>(); // the file each pinned companion belongs to
		defer { ClearAndDeleteItems!(pinnedBy); }
		for (let entry in placed)
		{
			let folder = PathParent(entry.File, .. scope .());
			for (let companion in entry.Companions)
			{
				let path = InFolder(folder, companion, .. scope .());
				var known = false;
				for (int i < pinned.Count)
				{
					if ((pinned[i] == path) && (pinnedBy[i] == entry.File))
						known = true;
				}
				if (known)
					continue;
				pinned.Add(new String(path));
				pinnedBy.Add(new String(entry.File));
			}
		}

		let moved = scope List<String>(); // files already placed (or left) by this call
		defer { ClearAndDeleteItems!(moved); }
		int count = 0;
		for (let instance in assets)
		{
			PlacedFile entry = null;
			for (let candidate in placed)
			{
				if (candidate.Instance === instance)
				{
					entry = candidate;
					break;
				}
			}
			if (entry == null)
				continue;
			let file = scope String(entry.File);
			if (Holds(moved, file))
				continue;
			moved.Add(new String(file));
			if (Holds(pinned, file))
				continue;
			let folder = scope String(entry.Folder);
			var agreed = true;
			for (let other in placed)
			{
				if ((other.File == file) && (other.Folder != folder))
					agreed = false;
			}
			let oldFolder = PathParent(file, .. scope .());
			if (!agreed || (oldFolder == folder))
				continue; // shared across groups, or in its folder already

			let fromDisk = SourceFile(file, .. scope .());
			if (!FileExists(fromDisk))
				continue; // a missing file: its asset says so, nothing to move
			// Its name in the folder, the next free one when another file has it.
			let name = ImportPaths.FileNameOf(file);
			let stem = ImportPaths.StemOf(name);
			let @extension = name.Substring(stem.Length); // with its dot
			let target = InFolder(folder, name, .. scope .());
			let probe = SourceFile(target, .. scope .());
			for (int n = 2; FileExists(probe); n++)
			{
				InFolder(folder, scope String()..AppendF("{}.{}{}", stem, n, @extension), target);
				SourceFile(target, probe);
			}

			// Its companions, which keep their places relative to it; none may land on a file, and
			// none may be another file's too (two models sharing a texture), which would leave
			// that file without it.
			var clear = true;
			var sharedCompanion = false;
			for (let companion in entry.Companions)
			{
				let landing = InFolder(folder, companion, .. scope .());
				if (FileExists(SourceFile(landing, .. scope .())))
					clear = false;
				if (Count(pinned, InFolder(oldFolder, companion, .. scope .())) > 1)
					sharedCompanion = true;
			}
			if (!clear)
			{
				GlobalLog(.Warning, "Project: {} stays: a file beside it would land on another in {}", file, folder);
				continue;
			}
			if (sharedCompanion)
			{
				GlobalLog(.Warning, "Project: {} stays: a file beside it belongs to another file too", file);
				continue;
			}
			let toDisk = SourceFile(target, .. scope .());
			CreateDirectory(PathParent(toDisk, .. scope .()));
			if (!MoveFile(fromDisk, toDisk))
			{
				GlobalLog(.Error, "Project: {} could not be moved to {}", file, target);
				continue;
			}
			Repoint(placed, ledger, file, target);
			moved.Add(new String(target));
			for (let companion in entry.Companions)
			{
				let from = InFolder(oldFolder, companion, .. scope .());
				let to = InFolder(folder, companion, .. scope .());
				let companionDisk = SourceFile(from, .. scope .());
				if (!FileExists(companionDisk))
					continue;
				let companionTo = SourceFile(to, .. scope .());
				CreateDirectory(PathParent(companionTo, .. scope .()));
				if (MoveFile(companionDisk, companionTo))
				{
					Repoint(placed, ledger, from, to);
					moved.Add(new String(from));
					moved.Add(new String(to));
					RemoveEmptyFolders(PathParent(from, .. scope .()));
				}
			}
			RemoveEmptyFolders(oldFolder);
			count++;
		}
		return count;
	}

	/// A project made before its files followed their groups kept them flat in Sources/, its code
	/// among them. Puts every asset's file in its group's folder (PlaceInGroupFolders: code under
	/// Code/); a folder already at Sources/Code, which Code/ would hide, is renamed first and the
	/// assets naming files in it follow. Nothing to do once every file is in place.
	private static void PlaceFilesAtOpen(EditorProject project)
	{
		let code = SourcePath.CodeFolder;
		let sourcesRoot = project.SourcesRoot(.. scope .());
		let instances = scope List<Instance>();
		ExportStaging.CollectAllInstances(project.SourceDb.RootGroup, instances);

		// A folder Sources/Code from before would be hidden by Code/: renamed first, and the
		// assets naming files in it follow it.
		let hidden = PathJoin(sourcesRoot, code, .. scope .());
		if (DirectoryExists(hidden))
		{
			let renamed = scope $"{code}.moved";
			for (int n = 2; DirectoryExists(PathJoin(sourcesRoot, renamed, .. scope .())); n++)
			{
				renamed.Clear();
				renamed.AppendF("{}.moved{}", code, n);
			}
			if (System.IO.Directory.Move(hidden, PathJoin(sourcesRoot, renamed, .. scope .())) case .Err)
			{
				GlobalLog(.Error, "Project: Sources/{} could not be renamed, so the project's files stay where they are for now", code);
				return;
			}
			GlobalLog(.Warning, "Project: Sources/{} is now Sources/{}: Code/ is the project's code folder", code, renamed);
			for (let instance in instances)
			{
				if (instance.SourceName.IsEmpty)
					continue;
				let object = instance.ReadObject();
				if (object == null)
					continue;
				defer delete object;
				let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Asset;
				if (asset == null)
					continue;
				StringView rest;
				if (!SourcePath.AfterFolder(asset.FileName.Value, code, out rest))
					continue;
				asset.FileName.Set(PathJoin(renamed, rest, .. scope .()));
				instance.WriteObject(object).IgnoreError();
			}
		}

		let moved = project.PlaceInGroupFolders((Span<Instance>)instances);
		if (moved > 0)
			GlobalLog(.Information, "Project: moved {} file(s) into their groups' folders", moved);
	}

	/// Points every asset naming `from` at `to` (its record and the placement's view of it), and
	/// carries the ledger's origin.
	private static void Repoint(List<PlacedFile> placed, StringView ledger, StringView from, StringView to)
	{
		for (let entry in placed)
		{
			if (entry.File != from)
				continue;
			let object = entry.Instance.ReadObject();
			if (object == null)
				continue;
			defer delete object;
			if (let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Asset)
			{
				asset.FileName.Set(to);
				if (entry.Instance.WriteObject(object) case .Err)
					GlobalLog(.Error, "Project: {} could not be pointed at {}", entry.Instance.Name, to);
			}
			entry.File.Set(to);
		}
		let origin = ImportPaths.ImportOriginOf(ledger, from, .. scope .());
		if (!origin.IsEmpty)
			ImportPaths.RecordImportOrigin(ledger, to, origin);
	}

	/// Removes `folder` (a file's old folder, as a source path) and its parents while they are
	/// empty, never the sources' root or Code/ itself.
	private void RemoveEmptyFolders(StringView folder)
	{
		let at = scope String(folder);
		while (!at.IsEmpty && (at != SourcePath.CodeFolder))
		{
			let full = SourceFile(at, .. scope .());
			var empty = true;
			if (!DirectoryExists(full))
				return;
			ListDirectory(full, scope [&empty] (name, isDirectory) => { empty = false; });
			if (!empty || !RemoveDirectory(full))
				return;
			let parent = PathParent(at, .. scope .());
			at.Set(parent);
		}
	}

	/// `file` in `folder` ("" is the root), into `outPath`.
	private static void InFolder(StringView folder, StringView file, String outPath)
	{
		if (folder.IsEmpty)
			outPath.Set(file);
		else
			PathJoin(folder, file, outPath);
	}

	private static int Count(List<String> list, StringView path)
	{
		int count = 0;
		for (let item in list)
		{
			if (item == path)
				count++;
		}
		return count;
	}

	private static bool Holds(List<String> list, StringView path)
	{
		for (let item in list)
		{
			if (item == path)
				return true;
		}
		return false;
	}

	/// Imports where it lies each file among `changed` (source paths a watch reported) that is new
	/// code under Code/: one no asset names yet, whose importer imports code (ImportsCode). It joins
	/// the group its folder names, made if missing (Code/Enemies/Boss.as: Enemies), so a script
	/// made in an outside editor becomes an asset by itself. A name its group already holds is left
	/// for the user, and reported. Returns how many it imported.
	public int AdoptNewCode(Span<String> changed, ImporterRegistry importers)
	{
		int adopted = 0;
		HashSet<String> named = null; // every asset's file, read once when a candidate needs it
		defer { if (named != null) DeleteContainerAndItems!(named); }
		for (let path in changed)
		{
			if (!SourcePath.AfterFolder(path, SourcePath.CodeFolder, let rest) || rest.IsEmpty)
				continue;
			let onDisk = SourceFile(path, .. scope .());
			if (!FileExists(onDisk))
				continue; // removed: its asset, if any, finds its file missing
			let importer = importers.FindFor(ImportPaths.ExtensionLower(path, .. scope .()));
			if ((importer == null) || !importer.ImportsCode)
				continue;
			// One an asset names already is not new (its edit is a cook's business).
			if (named == null)
			{
				named = new .();
				let pending = scope List<Group>();
				pending.Add(SourceDb.RootGroup);
				while (!pending.IsEmpty)
				{
					let group = pending.PopBack();
					for (let instance in group.Instances)
					{
						if (!instance.SourceName.IsEmpty)
							named.Add(new String(instance.SourceName));
					}
					pending.AddRange(group.Groups);
				}
			}
			if (named.ContainsAlt(path))
				continue;
			// Its group: the folders between Code/ and the file, made where missing.
			var group = SourceDb.RootGroup;
			let folders = PathParent(rest, .. scope .());
			for (let part in folders.Split('/'))
			{
				if (!part.IsEmpty)
					group = group.CreateGroup(part);
			}
			let context = scope ImportContext(SourcesRoot(.. scope .()));
			CodeRoot(context.CodeRoot);
			ImportPaths.ImportLedgerPath(CacheRoot(.. scope .()), context.LedgerPath);
			// Its copy is itself (the import's target in its group's folder is where it lies), so
			// nothing is written but its asset.
			if (importer.Import(onDisk, context, group, null, null, null) case .Err)
			{
				GlobalLog(.Warning, "Project: {} is not imported: '{}' has an asset of its name already", path, group.GetPath(.. scope .()));
				continue;
			}
			GlobalLog(.Information, "Project: imported new code {} into '{}'", path, group.GetPath(.. scope .()));
			named.Add(new String(path));
			adopted++;
		}
		return adopted;
	}
}
