using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

// What can be done to the project's assets and groups:
// rename, duplicate, a move into another group, delete, a new group, the export flag, cook. One
// place for each, so the assets browser's menus, keys and drops and an agent's delete over MCP do
// the same thing: an asset's pages close before it goes, the default scene is let go when it does,
// the cooked mirror follows a rename and a move, and nothing changes the databases while a cook
// reads them (it waits for the cook, saying so). A name is checked by AssetNames, Create Asset's
// and Save As's rule.

/// What an AssetOperations works over.
class AssetOperationsServices
{
	/// The project, and where what happened is said. Borrowed.
	public EditorContext Context = null;
	/// The cook an operation waits for and a duplicate asks of; null: nothing waits (a test).
	/// Borrowed.
	public EditorCookService Cook = null;
	/// Closes every page editing an asset, now (EditorPages.CloseAssetNow). Owned.
	public delegate void(Guid id) ClosePages ~ delete _;
	/// Runs work after the event that asked for it (a confirmation's answer); unset: at once.
	/// It TAKES OWNERSHIP of the work. Owned.
	public delegate void(delegate void() work) Later ~ delete _;
}

class AssetOperations
{
	/// A group's delete waiting to run: the group by its path (found again when it runs, so a
	/// group gone meanwhile is never reached), and who hears where to go first.
	private class GroupDelete
	{
		public String Path = new .() ~ delete _;
		public delegate void(Group next) WhereNext ~ delete _;
	}

	private AssetOperationsServices mServices ~ delete _;

	/// TAKES OWNERSHIP of the services.
	public this(AssetOperationsServices services)
	{
		mServices = services;
	}

	// === Renaming ===

	/// Renames an asset: true when it was (or will be, after a cook), else false with why not
	/// appended to `outWhy`. Its cooked product's name follows, and the default scene's path.
	public bool Rename(Guid id, StringView name, String outWhy)
	{
		let instance = Find(id);
		if (instance == null)
		{
			outWhy.Append("That asset is gone.");
			return false;
		}
		if (instance.Name == name)
			return true;
		AssetNames.Refusal(instance.OwningGroup, name, outWhy);
		if (!outWhy.IsEmpty)
			return false;
		if (Locked)
		{
			let renamed = new String(name);
			Wait(new [=this, =id, =renamed] () => { Rename(id, renamed, scope .()); } ~ delete renamed, "Rename");
			return true;
		}
		let project = CurrentProject;
		let oldPath = instance.GetPath(.. scope .());
		if (project.SourceDb.RenameInstance(id, name) case .Err(let error))
		{
			GlobalLog(.Warning, "Assets: rename FAILED for '{}' ({})", oldPath, error);
			outWhy.Append("The rename failed (see the Console).");
			return false;
		}
		// Its product's name in step: everything binds by guid, but a stale name in Cooked confuses.
		project.CookedDb.RenameInstance(id, name).IgnoreError();
		// The manifest's default scene is the guid; its path the readable mirror. The path's
		// compare covers a manifest with no guid, which then takes it.
		if ((project.Settings.DefaultSceneId == id) || (project.Settings.DefaultScene == oldPath))
		{
			project.Settings.DefaultSceneId = id;
			instance.GetPath(project.Settings.DefaultScene..Clear());
			project.SaveSettings().IgnoreError();
		}
		GlobalLog(.Information, "Assets: renamed '{}' -> '{}'", oldPath, instance.GetPath(.. scope .()));
		return true;
	}

	/// Renames a group (not the top one): true when it was (or will be, after a cook), else false
	/// with why not appended to `outWhy`. The cooked group of its path follows, and the default
	/// scene's path where the scene was in it.
	public bool RenameGroup(Group group, StringView name, String outWhy)
	{
		if (group.Parent == null)
		{
			outWhy.Append("Content cannot be renamed.");
			return false;
		}
		if (group.Name == name)
			return true;
		GroupNameRefusal(group.Parent, name, outWhy);
		if (!outWhy.IsEmpty)
			return false;
		let oldPath = group.GetPath(.. scope .());
		if (Locked)
		{
			let path = new String(oldPath);
			let renamed = new String(name);
			Wait(new [=this, =path, =renamed] () =>
				{
					let sources = (CurrentProject != null) ? CurrentProject.SourceDb : null;
					if (let found = (sources != null) ? GroupAt(sources, path) : null)
						RenameGroup(found, renamed, scope .());
				} ~ { delete path; delete renamed; }, "Rename");
			return true;
		}
		let project = CurrentProject;
		if (project.SourceDb.RenameGroup(group, name) case .Err(let error))
		{
			GlobalLog(.Warning, "Assets: rename FAILED for group '{}' ({})", oldPath, error);
			outWhy.Append("The rename failed (see the Console).");
			return false;
		}
		if (let cooked = GroupAt(project.CookedDb, oldPath))
			project.CookedDb.RenameGroup(cooked, name).IgnoreError();
		RefreshDefaultScenePath(project);
		MoveDefaultScenePathUnder(project, oldPath, group);
		GlobalLog(.Information, "Assets: renamed group '{}' -> '{}'", oldPath, group.GetPath(.. scope .()));
		return true;
	}

	// === Making ===

	/// A copy of an asset beside it ("Crate.2"), cooked so a builder's copy is pickable at once;
	/// null when it could not be made (said) or waits for a cook.
	public Instance Duplicate(Guid id)
	{
		let source = Find(id);
		if (source == null)
			return null;
		if (Locked)
		{
			Wait(new [=this, =id] () => { Duplicate(id); }, "Duplicate");
			return null;
		}
		let name = source.OwningGroup.UniqueInstanceName(source.Name, .. scope .());
		let copy = CurrentProject.SourceDb.CloneInstance(id, name);
		if (copy == null)
		{
			GlobalLog(.Warning, "Assets: duplicate FAILED for '{}'", source.GetPath(.. scope .()));
			Notify(.Error, "The duplicate failed (see the Console).");
			return null;
		}
		GlobalLog(.Information, "Assets: duplicated '{}' -> '{}'", source.GetPath(.. scope .()), copy.GetPath(.. scope .()));
		Context.SetStatus(scope $"Duplicated as {copy.Name}.");
		if (mServices.Cook != null)
			mServices.Cook.RequestCook(false);
		return copy;
	}

	/// A new group in `parent` named `wanted` ("Group", "Group.2" when taken), a folder on disk at
	/// once so it stays while empty; null when it could not be made or waits for a cook (and is made
	/// after it).
	public Group CreateGroup(Group parent, StringView wanted = "Group")
	{
		let project = CurrentProject;
		if ((project == null) || (parent == null))
			return null;
		if (Locked)
		{
			let parentPath = parent.GetPath(.. new .());
			let wantedName = new String(wanted);
			Wait(new [=this, =parentPath, =wantedName] () =>
				{
					let sources = (CurrentProject != null) ? CurrentProject.SourceDb : null;
					if (let found = (sources != null) ? GroupAt(sources, parentPath) : null)
						CreateGroup(found, wantedName);
				} ~ { delete parentPath; delete wantedName; }, "New group");
			return null;
		}
		let name = parent.UniqueGroupName(wanted.IsEmpty ? "Group" : wanted, .. scope .());
		let created = parent.CreateGroup(name);
		if (created == null)
			return null;
		// The database is scanned from its folders: an empty group with no folder would vanish.
		let folder = created.GetPath(.. scope .());
		if (let writable = project.SourceDb.Mount as IWritableFileSystem)
			writable.CreateDirectory(folder).IgnoreError();
		GlobalLog(.Information, "Assets: created group '{}'", folder);
		return created;
	}

	// === Moving ===

	/// Whether the assets `ids` can move into `to`; when not, why appended to `outWhy`: they are
	/// all there already, or one's name is taken there. One not in the project is passed by.
	/// Borrows `ids`.
	public bool CanMove(Span<Guid> ids, Group to, String outWhy)
	{
		int moving = 0;
		for (let id in ids)
		{
			let instance = Find(id);
			if ((instance == null) || (instance.OwningGroup === to))
				continue;
			if (to.GetInstance(instance.Name) != null)
			{
				outWhy.AppendF("{} is already in {}", instance.Name, GroupPicker.ShownName(to, .. scope .()));
				return false;
			}
			moving++;
		}
		if (moving == 0)
			outWhy.AppendF("Already in {}", GroupPicker.ShownName(to, .. scope .()));
		return moving > 0;
	}

	/// Moves the assets `ids` into `to`: their files with them (ContentDatabase.MoveInstance), each
	/// cooked product's place in the cooked mirror following, the default scene's path kept true.
	/// One whose name is taken there stays, said; how many moved is said. Waiting for a cook, `to`
	/// is found again by its path when it runs (gone by then: nothing). Borrows `ids`.
	public void MoveTo(Span<Guid> ids, Group to)
	{
		let project = CurrentProject;
		if ((project == null) || (to == null))
			return;
		if (Locked)
		{
			let path = to.GetPath(.. new .());
			let waiting = new List<Guid>();
			waiting.AddRange(ids);
			Wait(new [=this, =path, =waiting] () =>
				{
					let sources = (CurrentProject != null) ? CurrentProject.SourceDb : null;
					if (let found = (sources != null) ? GroupAt(sources, path) : null)
						MoveTo(waiting, found);
				} ~ { delete path; delete waiting; }, "Move");
			return;
		}
		let shown = GroupPicker.ShownName(to, .. scope .());
		let toPath = to.GetPath(.. scope .());
		let settings = project.Settings;
		int moved = 0;
		for (let id in ids)
		{
			let instance = Find(id);
			if ((instance == null) || (instance.OwningGroup === to))
				continue;
			if (to.GetInstance(instance.Name) != null)
			{
				Notify(.Warning, scope $"{instance.Name} stays: {shown} has one of that name.");
				continue;
			}
			let from = instance.GetPath(.. scope .());
			if (project.SourceDb.MoveInstance(id, to) case .Err(let error))
			{
				GlobalLog(.Warning, "Assets: move FAILED for '{}' ({})", from, error);
				Notify(.Error, scope $"{instance.Name} could not be moved (see the Console).");
				continue;
			}
			moved++;
			GlobalLog(.Information, "Assets: moved '{}' -> '{}'", from, instance.GetPath(.. scope .()));
			// Its product's place in step: everything binds by guid, but the mirror only reads true.
			if (project.CookedDb.GetInstance(id) != null)
			{
				if (let cooked = MakeGroupAt(project.CookedDb, toPath))
					project.CookedDb.MoveInstance(id, cooked).IgnoreError();
			}
			// A manifest with no guid names the default scene by its path: the one moving from
			// it gives the manifest its guid, so the refresh below finds where it went.
			if (!settings.DefaultSceneId.IsSet && (settings.DefaultScene == from))
				settings.DefaultSceneId = id;
		}
		RefreshDefaultScenePath(project);
		if (moved > 0)
			Context.SetStatus((moved == 1) ? scope:: $"Moved 1 asset to {shown}." : scope:: $"Moved {moved} assets to {shown}.");
	}

	// === Deleting ===

	/// What a confirmation names for `ids`, appended: "Crate", "Crate and Barrel", "Crate, Barrel
	/// and Bell", "Crate, Barrel and 3 more"; nothing when none is there.
	public void Names(Span<Guid> ids, String outNames)
	{
		let names = scope List<StringView>();
		for (let id in ids)
		{
			if (let instance = Find(id))
				names.Add(instance.Name);
		}
		if (names.IsEmpty)
			return;
		switch (names.Count)
		{
		case 1: outNames.Append(names[0]);
		case 2: outNames.AppendF("{} and {}", names[0], names[1]);
		case 3: outNames.AppendF("{}, {} and {}", names[0], names[1], names[2]);
		default: outNames.AppendF("{}, {} and {} more", names[0], names[1], names.Count - 2);
		}
	}

	/// Deletes assets after the event that asked (their pages closed first), waiting for a cook;
	/// how many went is said. Borrows `ids`.
	public void Delete(Span<Guid> ids)
	{
		let targets = new List<Guid>();
		targets.AddRange(ids);
		Later(new [=this, =targets] () => { DeleteNow(targets); } ~ delete targets);
	}

	/// One asset, now (an agent's delete, which has waited out any cook itself): its page closed,
	/// the default scene let go with it. False when it is not there or did not go.
	public bool DeleteOne(Guid id)
	{
		if ((CurrentProject == null) || !Remove(id))
			return false;
		ClearDefaultSceneIfGone();
		return true;
	}

	/// Deletes a group and all it holds after the event that asked, its assets' pages closed
	/// first, waiting for a cook; `whereNext` hears the group's parent before it goes, so what
	/// showed it moves away first. Nothing for the top group. TAKES OWNERSHIP of `whereNext`.
	public void DeleteGroup(Group group, delegate void(Group next) whereNext = null)
	{
		if (group.Parent == null)
		{
			delete whereNext;
			return;
		}
		let job = new GroupDelete();
		group.GetPath(job.Path);
		job.WhereNext = whereNext;
		Later(new [=this, =job] () => { DeleteGroupNow(job); } ~ delete job);
	}

	/// The assets a group holds, all the way down.
	public static int CountAssets(Group group)
	{
		var count = group.Instances.Count;
		for (let child in group.Groups)
			count += CountAssets(child);
		return count;
	}

	/// The assets a group holds, all the way down, added to `outIds`.
	public static void CollectAssets(Group group, List<Guid> outIds)
	{
		for (let instance in group.Instances)
			outIds.Add(instance.Id);
		for (let child in group.Groups)
			CollectAssets(child, outIds);
	}

	// === Exporting and cooking ===

	/// Whether an export takes the asset whatever reaches it ("Always Export").
	public bool IsAlwaysExported(Guid id) => (CurrentProject != null) && CurrentProject.ExportRoots.HasInstance(id);
	/// Whether an export takes everything in the group whatever reaches it.
	public bool IsAlwaysExported(Group group) => (CurrentProject != null) && CurrentProject.ExportRoots.HasGroup(group.GetPath(.. scope .()));

	/// Flags the asset as always exported, or not; kept with the project at once.
	public void ToggleAlwaysExport(Guid id)
	{
		let instance = Find(id);
		if (instance == null)
			return;
		let now = CurrentProject.ExportRoots.ToggleInstance(id);
		SaveExportRoots(now ? scope:: $"{instance.Name} is always exported." : scope:: $"{instance.Name} is exported when reached.");
	}

	/// Flags everything in the group as always exported, or not; kept with the project at once.
	public void ToggleAlwaysExport(Group group)
	{
		if (CurrentProject == null)
			return;
		let now = CurrentProject.ExportRoots.ToggleGroup(group.GetPath(.. scope .()));
		SaveExportRoots(now ? scope:: $"Everything in {group.Name} is always exported." : scope:: $"{group.Name} is exported when reached.");
	}

	/// Cooks the assets and what they need; `force` rebuilds them.
	public void Cook(Span<Guid> ids, bool force)
	{
		if ((mServices.Cook != null) && !ids.IsEmpty)
			mServices.Cook.RequestCookFor(ids, force);
	}

	public void CookGroup(Group group, bool force)
	{
		let ids = scope List<Guid>();
		CollectAssets(group, ids);
		Cook(ids, force);
	}

	public void CookAll(bool force)
	{
		if (mServices.Cook != null)
			mServices.Cook.RequestCook(force);
	}

	// === Underneath ===

	private EditorContext Context => mServices.Context;
	private EditorProject CurrentProject => (mServices.Context != null) ? mServices.Context.Project : null;

	private Instance Find(Guid id)
	{
		let project = CurrentProject;
		return (project != null) ? project.SourceDb.GetInstance(id) : null;
	}

	private void Notify(NoticeKind kind, StringView text)
	{
		Context.Notify(kind, text);
	}

	/// TAKES OWNERSHIP of `work`.
	private void Later(delegate void() work)
	{
		if (mServices.Later != null)
		{
			mServices.Later(work);
			return;
		}
		defer delete work;
		work();
	}

	/// A cook reads the databases now: what changes them waits.
	private bool Locked => (mServices.Cook != null) && mServices.Cook.MutationLocked;

	/// `work` again once the cook is idle, said. TAKES OWNERSHIP of `work`.
	private void Wait(delegate void() work, StringView what)
	{
		mServices.Cook.RunWhenIdle(work);
		Notify(.Info, scope $"{what} waits for the cook to finish.");
	}

	/// Why `name` cannot name a group in `parent` (empty, a character a folder cannot hold, taken
	/// there), appended; nothing when it can.
	private static void GroupNameRefusal(Group parent, StringView name, String outWhy)
	{
		if (name.IsEmpty)
		{
			outWhy.Append("Enter a name.");
			return;
		}
		for (let c in name)
		{
			if (AssetNames.cRefused.Contains(c))
			{
				outWhy.AppendF("A name cannot hold {}.", c);
				return;
			}
		}
		if (parent.GetGroup(name) != null)
			outWhy.AppendF("{} is already there.", name);
	}

	/// The group at `path` in `db` (empty: the top); null when there is none.
	private static Group GroupAt(ContentDatabase db, StringView path)
	{
		var group = db.RootGroup;
		for (let segment in path.Split('/'))
		{
			if (group == null)
				break;
			if (!segment.IsEmpty)
				group = group.GetGroup(segment);
		}
		return group;
	}

	/// The group at `path` in `db`, each group on the way made where it is not there yet (empty: the
	/// top): where the cooked mirror files a product that moved.
	private static Group MakeGroupAt(ContentDatabase db, StringView path)
	{
		var group = db.RootGroup;
		for (let segment in path.Split('/'))
		{
			if (!segment.IsEmpty)
				group = group.CreateGroup(segment);
		}
		return group;
	}

	/// Borrows `ids`; waiting, a copy waits.
	private void DeleteNow(List<Guid> ids)
	{
		if (CurrentProject == null)
			return;
		if (Locked)
		{
			let waiting = new List<Guid>(ids.GetEnumerator());
			Wait(new [=this, =waiting] () => { DeleteNow(waiting); } ~ delete waiting, "Delete");
			return;
		}
		int gone = 0;
		for (let id in ids)
		{
			if (Remove(id))
				gone++;
		}
		ClearDefaultSceneIfGone();
		Context.SetStatus((gone == 1) ? "Deleted 1 asset." : scope:: $"Deleted {gone} assets."); // the next cook sweeps their products
	}

	/// Borrows `job`; waiting, what it holds moves to one that waits.
	private void DeleteGroupNow(GroupDelete job)
	{
		let project = CurrentProject;
		if (project == null)
			return;
		if (Locked)
		{
			let waiting = new GroupDelete();
			waiting.Path.Set(job.Path);
			waiting.WhereNext = job.WhereNext;
			job.WhereNext = null;
			Wait(new [=this, =waiting] () => { DeleteGroupNow(waiting); } ~ delete waiting, "Delete");
			return;
		}
		let group = GroupAt(project.SourceDb, job.Path);
		if ((group == null) || (group.Parent == null))
			return;
		let ids = scope List<Guid>();
		CollectAssets(group, ids);
		if (mServices.ClosePages != null)
		{
			for (let id in ids)
				mServices.ClosePages(id);
		}
		if (job.WhereNext != null)
			job.WhereNext(group.Parent); // away before the group's pointers go
		// DeleteGroup frees the group and all it holds: nothing of it is reached after.
		if (project.SourceDb.DeleteGroup(group) case .Ok)
		{
			GlobalLog(.Information, "Assets: deleted group '{}' ({} asset(s))", job.Path, ids.Count);
			Context.SetStatus(scope $"Deleted {job.Path}.");
		}
		else
		{
			GlobalLog(.Warning, "Assets: delete FAILED for group '{}'", job.Path);
			Notify(.Error, "The group's delete failed (see the Console).");
		}
		ClearDefaultSceneIfGone();
	}

	/// One asset: its pages closed first, then the instance deleted (freed) and logged.
	private bool Remove(Guid id)
	{
		let instance = Find(id);
		if (instance == null)
			return false;
		let path = instance.GetPath(.. scope .());
		if (mServices.ClosePages != null)
			mServices.ClosePages(id);
		if (CurrentProject.SourceDb.DeleteInstance(id) case .Err)
		{
			GlobalLog(.Warning, "Assets: delete FAILED for '{}'", path);
			return false;
		}
		GlobalLog(.Information, "Assets: deleted '{}'", path); // the next cook sweeps its product
		return true;
	}

	/// A delete may have taken the default scene with it: the manifest lets it go rather than
	/// keep a guid the player would fail on.
	private void ClearDefaultSceneIfGone()
	{
		let project = CurrentProject;
		if ((project == null) || (!project.Settings.DefaultSceneId.IsSet && project.Settings.DefaultScene.IsEmpty))
			return;
		let there = project.Settings.DefaultSceneId.IsSet
			? (project.SourceDb.GetInstance(project.Settings.DefaultSceneId) != null)
			: (project.SourceDb.GetInstanceByPath(project.Settings.DefaultScene) != null);
		if (there)
			return;
		project.Settings.DefaultSceneId = .Empty;
		project.Settings.DefaultScene.Clear();
		project.SaveSettings().IgnoreError();
		GlobalLog(.Information, "Assets: the default scene was deleted: cleared in the manifest");
	}

	/// The default scene's path mirror, from its guid, after the scene may have moved (a group's
	/// rename, a move), saved when it changed; nothing for a manifest with no guid.
	private static void RefreshDefaultScenePath(EditorProject project)
	{
		let settings = project.Settings;
		if (!settings.DefaultSceneId.IsSet)
			return;
		if (let scene = project.SourceDb.GetInstance(settings.DefaultSceneId))
		{
			let path = scene.GetPath(.. scope .());
			if (settings.DefaultScene != path)
			{
				settings.DefaultScene.Set(path);
				project.SaveSettings().IgnoreError();
			}
		}
	}

	/// After a group's rename from `oldPath`, in a manifest with no guid: the default scene's path
	/// moved with the group when it was under it.
	private static void MoveDefaultScenePathUnder(EditorProject project, StringView oldPath, Group renamed)
	{
		let settings = project.Settings;
		if (settings.DefaultSceneId.IsSet)
			return;
		let scene = StringView(settings.DefaultScene);
		if ((scene.Length > oldPath.Length) && scene.StartsWith(oldPath) && (scene[oldPath.Length] == '/'))
		{
			let moved = renamed.GetPath(.. scope .());
			moved.Append(scene.Substring(oldPath.Length));
			settings.DefaultScene.Set(moved);
			project.SaveSettings().IgnoreError();
		}
	}

	private void SaveExportRoots(StringView said)
	{
		if (CurrentProject.SaveExportRoots() case .Err)
		{
			Notify(.Error, "The export roots could not be saved (export_roots.xml).");
			return;
		}
		Notify(.Info, said);
	}
}
