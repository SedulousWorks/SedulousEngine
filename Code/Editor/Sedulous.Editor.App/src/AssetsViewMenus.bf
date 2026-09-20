using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The row and background context menus, the "Always Export" roots, new groups and
/// duplicates.
extension AssetsView
{
	/// The selected instance ids in the active view; group rows never join the selection set
	/// for destructive actions, and the clicked row is always included.
	private void SelectedInstanceIds(SelectionModel selection, int32 clicked, List<Guid> outIds)
	{
		mixin Push(int32 position)
		{
			let row = RowAt(position);
			if ((row.Group == null) && row.Id.IsSet && !outIds.Contains(row.Id))
				outIds.Add(row.Id);
		}
		if ((selection != null) && selection.IsSelected(clicked))
		{
			for (let position in selection.SelectedPositions)
				Push!(position);
		}
		else
		{
			Push!(clicked);
		}
	}

	private void ShowRowMenu(View anchor, SelectionModel selection, int32 position, float x, float y)
	{
		if (Context == null)
			return;
		let row = RowAt(position);
		if ((row.Group == null) && !row.Id.IsSet)
			return;

		// Group rows: navigate, rename in place, delete recursively after confirming.
		if (row.Group != null)
		{
			let group = row.Group;
			let menu = new ContextMenu();
			defer menu.ReleaseRef();
			menu.AddItem("Open", new [=group, =this]() => { SelectGroup(group); });
			menu.AddSeparator();
			menu.AddItem("Rename", new [=position, =this]() => { StartRenameDeferred(position); });
			menu.AddItem(IsGroupExportRoot(group) ? "Don't always export contents" : "Always export contents",
				new [=group, =this]() => { ToggleGroupExportRoot(group); });
			menu.AddSeparator();
			menu.AddItem("Cook Group", new [=group, =this]() => { CookGroup(group, false); });
			menu.AddItem("Rebuild Group", new [=group, =this]() => { CookGroup(group, true); });
			menu.AddSeparator();
			menu.AddItem("Delete Group", new [=group, =this]() => { ConfirmDeleteGroup(group); });
			let screenPos = anchor.LocalToScreen(.(x, y));
			menu.Show(Context, screenPos.X, screenPos.Y);
			return;
		}

		let instance = Resolve(row.Id);
		if (instance == null)
			return;
		let id = row.Id;
		let targets = new List<Guid>();
		SelectedInstanceIds(selection, position, targets);

		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		menu.AddItem("Open", new [=id, =this]() =>
			{
				if (let inst = Resolve(id))
				{
					if (OnOpenInstance != null)
						OnOpenInstance(inst);
				}
			});
		menu.AddSeparator();
		menu.AddItem("Rename", new [=position, =this]() => { StartRenameDeferred(position); });
		menu.AddItem("Duplicate", new [=id, =this]() => { DuplicateInstance(id); });
		menu.AddSeparator();
		// The OS clipboard, not the editor's typed one: the canonical UUID string and the
		// mount-relative content path, for pasting into scripts and docs.
		menu.AddItem("Copy GUID", new [=id, =this]() =>
			{
				if (let clipboard = (Context != null) ? Context.Clipboard : null)
					clipboard.SetText(id.ToString(.. scope .(), 'D')).IgnoreError();
			});
		menu.AddItem("Copy Path", new [=id, =this]() =>
			{
				let clipboard = (Context != null) ? Context.Clipboard : null;
				let inst = Resolve(id);
				if ((clipboard != null) && (inst != null))
					clipboard.SetText(inst.GetPath(.. scope .())).IgnoreError();
			});
		menu.AddItem(mContext.IsFavorite(id) ? "Unpin favorite" : "Pin favorite", new [=id, =this]() =>
			{
				mContext.ToggleFavorite(id);
				RebuildList();
			});
		menu.AddItem(IsInstanceExportRoot(id) ? "Remove from Always Export" : "Always Export",
			new [=id, =this]() => { ToggleInstanceExportRoot(id); });
		menu.AddSeparator();
		// Scoped: the selected assets and their dependency closure; Build > Cook All stays
		// the whole-project path, so huge scenes cook one asset or group at a time.
		let cookTargets = new List<Guid>(targets.GetEnumerator());
		menu.AddItem("Cook", new [=cookTargets, =this]() => { mCook.RequestCookFor(cookTargets, false); } ~ delete cookTargets);
		let rebuildTargets = new List<Guid>(targets.GetEnumerator());
		menu.AddItem("Rebuild", new [=rebuildTargets, =this]() => { mCook.RequestCookFor(rebuildTargets, true); } ~ delete rebuildTargets);
		menu.AddSeparator();
		let deleteLabel = scope String("Delete");
		if (targets.Count > 1)
			deleteLabel.AppendF(" {} assets", targets.Count);
		menu.AddItem(deleteLabel, new [=targets, =this]() => { ConfirmDelete(targets); } ~ delete targets);
		let screenPos = anchor.LocalToScreen(.(x, y));
		menu.Show(Context, screenPos.X, screenPos.Y);
	}

	private void ShowBackgroundMenu(View anchor, float x, float y)
	{
		if (Context == null)
			return;
		let target = mSelectedGroup; // creations land in the group we are in
		let menu = new ContextMenu();
		defer menu.ReleaseRef();

		// One Create submenu holds every asset creator: uncategorised items flat, then one
		// nested submenu per category, since a flat list of every creator outgrew the screen.
		{
			let create = menu.AddSubmenu("Create").Submenu;
			if (create != null)
			{
				let categories = scope List<StringView>();
				for (let creator in mContext.Creators)
				{
					if (creator.Category.IsEmpty)
					{
						AddCreatorItem(create, creator, target);
						continue;
					}
					if (!categories.Contains(creator.Category))
						categories.Add(creator.Category);
				}
				if (!categories.IsEmpty)
					create.AddSeparator();
				categories.Sort(scope (a, b) => a <=> b);
				for (let category in categories)
				{
					let categoryMenu = create.AddSubmenu(category).Submenu;
					if (categoryMenu == null)
						continue;
					for (let creator in mContext.Creators)
					{
						if (creator.Category == category)
							AddCreatorItem(categoryMenu, creator, target);
					}
				}
			}
		}
		menu.AddItem("New Group", new [=target, =this]() => { CreateGroupIn(target); });
		// Browse for a file to import: the app opens the native file dialog and routes it to
		// ImportFile.
		menu.AddItem("Import...", new () => { if (OnBrowseImport != null) OnBrowseImport(); });
		if (target != null)
		{
			menu.AddSeparator();
			if (target.Parent != null)
			{
				menu.AddItem("Rename Group", new [=target, =this]() => { StartRenameGroupInTreeDeferred(target); });
				menu.AddItem(IsGroupExportRoot(target) ? "Don't always export contents" : "Always export contents",
					new [=target, =this]() => { ToggleGroupExportRoot(target); });
			}
			menu.AddItem("Cook Group", new [=target, =this]() => { CookGroup(target, false); });
			menu.AddItem("Rebuild Group", new [=target, =this]() => { CookGroup(target, true); });
			if (target.Parent != null)
				menu.AddItem("Delete Group", new [=target, =this]() => { ConfirmDeleteGroup(target); });
		}
		menu.AddSeparator();
		menu.AddItem("Cook All", new () => { mCook.RequestCook(false); });
		menu.AddItem("Rebuild All", new () => { mCook.RequestCook(true); });
		let screenPos = anchor.LocalToScreen(.(x, y));
		menu.Show(Context, screenPos.X, screenPos.Y);
	}

	private void AddCreatorItem(ContextMenu into, AssetCreator creator, Group target)
	{
		into.AddItem(creator.Label, new [=creator, =target, =this]() =>
			{
				if (OnCreate != null)
					OnCreate(creator, target);
				Rebuild();
			});
	}

	private void CookGroup(Group group, bool force)
	{
		let ids = scope List<Guid>();
		CollectInstanceIds(group, ids);
		mCook.RequestCookFor(ids, force);
	}

	// ---- "Always Export" roots -------------------------------------------------------------
	// A user flags an asset, or a whole group subtree, as an export root; its dependency
	// closure then ships even with reachability pruning on. Stored centrally on the project
	// (export_roots.xml) and saved immediately on toggle: deliberate, rare, auditable.

	private bool IsInstanceExportRoot(Guid id)
	{
		let project = mContext.Project;
		return (project != null) && project.ExportRoots.HasInstance(id);
	}

	/// A directly flagged instance or a flagged group row, the corner-dot badge.
	private bool IsRowExportRoot(int32 position)
	{
		let row = RowAt(position);
		if (row.Group != null)
			return IsGroupExportRoot(row.Group);
		return row.Id.IsSet && IsInstanceExportRoot(row.Id);
	}

	/// Instances only, groups are never favourites: the gold corner dot.
	private bool IsRowFavorite(int32 position)
	{
		let row = RowAt(position);
		return (row.Group == null) && row.Id.IsSet && mContext.IsFavorite(row.Id);
	}

	private bool IsGroupExportRoot(Group group)
	{
		let project = mContext.Project;
		return (project != null) && (group != null) && project.ExportRoots.HasGroup(group.GetPath(.. scope .()));
	}

	private void ToggleInstanceExportRoot(Guid id)
	{
		let project = mContext.Project;
		if (project == null)
			return;
		let nowRoot = project.ExportRoots.ToggleInstance(id);
		let inst = Resolve(id);
		AfterExportRootChange(nowRoot, (inst != null) ? inst.Name : "asset", false);
	}

	private void ToggleGroupExportRoot(Group group)
	{
		let project = mContext.Project;
		if ((project == null) || (group == null))
			return;
		let nowRoot = project.ExportRoots.ToggleGroup(group.GetPath(.. scope .()));
		AfterExportRootChange(nowRoot, group.Name, true);
	}

	/// Persists, surfaces and refreshes after a flag toggle.
	private void AfterExportRootChange(bool nowRoot, StringView name, bool isGroup)
	{
		let project = mContext.Project;
		if (project == null)
			return;
		if (project.SaveExportRoots() case .Err)
		{
			mContext.Notify(.Error, "Failed to save export roots (export_roots.xml)");
			return;
		}
		let message = scope String(nowRoot ? "Always Export: " : "Removed from Always Export: ");
		message.Append(name);
		if (isGroup && nowRoot)
			message.Append(" (contents)");
		mContext.Notify(.Info, message);
		RebuildList();
	}

	private void CreateGroupIn(Group parent)
	{
		// The cook gate: a structural database mutation while the plan worker reads.
		if (mCook.MutationLocked)
		{
			mCook.RunWhenIdle(new [=parent, =this]() => { CreateGroupIn(parent); });
			mContext.Notify(.Info, "New group queued until the current cook finishes.");
			return;
		}
		if ((parent == null) || (mContext.Project == null))
			return;
		let name = parent.UniqueGroupName("Group", .. scope .());
		let created = parent.CreateGroup(name);
		if (created != null)
		{
			// CreateGroup is in-memory only, no disk write until an instance is committed, and
			// the database is rebuilt by scanning folders on reopen, so an empty group would
			// vanish. Materialised as a real directory now, so it persists while still empty.
			let groupPath = created.GetPath(.. scope .());
			if (let writable = mContext.Project.SourceDb.Mount as IWritableFileSystem)
				writable.CreateDirectory(groupPath).IgnoreError();
			GlobalLog(.Information, "Assets: created group '{}'", groupPath);
			mSelectedGroup = created;
			Rebuild();
		}
	}

	private void DuplicateInstance(Guid id)
	{
		let src = Resolve(id);
		if ((src == null) || (mContext.Project == null))
			return;
		let db = mContext.Project.SourceDb;

		// "name.2", "name.3", ... in the source's own group; the source holds the base.
		let name = src.OwningGroup.UniqueInstanceName(src.Name, .. scope .());
		let copy = db.CloneInstance(id, name);
		if (copy == null)
		{
			mContext.Notify(.Error, "Duplicate FAILED (see console).");
			return;
		}
		GlobalLog(.Information, "Assets: duplicated '{}' -> '{}'", src.GetPath(.. scope .()), copy.GetPath(.. scope .()));
		mContext.SetStatus(scope $"Duplicated as '{copy.Name}'.");
		Rebuild();
		mCook.RequestCook(false); // builder-backed clones become pickable right away
	}
}
