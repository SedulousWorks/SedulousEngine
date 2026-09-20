using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// Inline rename, confirmed deletes, and the keyboard shortcuts on rows.
extension AssetsView
{
	// ---- inline rename ---------------------------------------------------------------------

	/// The name label's commit handler: routes to the instance or the group apply.
	public void ApplyRename(AssetNameLabel label, StringView newName)
	{
		if (label.TargetGroup != null)
			ApplyRenameGroup(label.TargetGroup, newName);
		else
			ApplyRenameInstance(label.TargetId, newName);
	}

	private void ApplyRenameInstance(Guid id, StringView name)
	{
		// The cook gate: renames move files and rewrite both databases' entries.
		if (mCook.MutationLocked)
		{
			let renamed = new String(name);
			mCook.RunWhenIdle(new [=id, =renamed, =this]() => { ApplyRenameInstance(id, renamed); } ~ delete renamed);
			mContext.Notify(.Info, "Rename queued until the current cook finishes.");
			return;
		}
		if (mContext.Project == null)
			return;
		let inst = Resolve(id);
		if (inst == null)
			return;
		let oldPath = inst.GetPath(.. scope .());
		if (mContext.Project.SourceDb.RenameInstance(id, name) case .Err(let error))
		{
			mContext.Notify(.Error, (error == .AlreadyExists) ? "NOT renamed: name already taken." : "Rename FAILED (see console).");
			Rebuild(); // the label snaps back to the real name
			return;
		}
		// The cooked product's name keeps in step: the same guid, purely cosmetic since
		// everything binds by guid, but stale names in Cooked confuse.
		mContext.Project.CookedDb.RenameInstance(id, name).IgnoreError();
		// The manifest's default scene is guid-authoritative; the human-readable path mirror
		// refreshes. The path compare covers guid-less manifests, and adopts the guid.
		let project = mContext.Project;
		if ((project.Settings.DefaultSceneId == id) || (project.Settings.DefaultScene == oldPath))
		{
			project.Settings.DefaultSceneId = id;
			inst.GetPath(project.Settings.DefaultScene..Clear());
			project.SaveSettings().IgnoreError();
		}
		GlobalLog(.Information, "Assets: renamed '{}' -> '{}'", oldPath, inst.GetPath(.. scope .()));
		Rebuild();
	}

	private void ApplyRenameGroup(Group group, StringView name)
	{
		if (mCook.MutationLocked)
		{
			let renamed = new String(name);
			mCook.RunWhenIdle(new [=group, =renamed, =this]() => { ApplyRenameGroup(group, renamed); } ~ delete renamed);
			mContext.Notify(.Info, "Rename queued until the current cook finishes.");
			return;
		}
		if (mContext.Project == null)
			return;
		let oldPath = group.GetPath(.. scope .());
		if (mContext.Project.SourceDb.RenameGroup(group, name) case .Err(let error))
		{
			mContext.Notify(.Error, (error == .AlreadyExists) ? "NOT renamed: name already taken." : "Rename FAILED (see console).");
			Rebuild();
			return;
		}
		// Mirrored in the cooked database when a same-path group exists there.
		var cooked = mContext.Project.CookedDb.RootGroup;
		for (let segment in oldPath.Split('/'))
		{
			if (cooked == null)
				break;
			if (!segment.IsEmpty)
				cooked = cooked.GetGroup(segment);
		}
		if (cooked != null)
			mContext.Project.CookedDb.RenameGroup(cooked, name).IgnoreError();
		// The default scene's path mirror refreshes if it lived under the renamed group; the
		// guid still resolves, the mirror is cosmetic but should not lie.
		let project = mContext.Project;
		if (project.Settings.DefaultSceneId.IsSet)
		{
			if (let ds = project.SourceDb.GetInstance(project.Settings.DefaultSceneId))
			{
				let path = ds.GetPath(.. scope .());
				if (project.Settings.DefaultScene != path)
				{
					project.Settings.DefaultScene.Set(path);
					project.SaveSettings().IgnoreError();
				}
			}
		}
		else
		{
			let ds = StringView(project.Settings.DefaultScene);
			if ((ds.Length > oldPath.Length) && ds.StartsWith(oldPath) && (ds[oldPath.Length] == '/'))
			{
				let updated = group.GetPath(.. scope .());
				updated.Append(ds.Substring(oldPath.Length));
				project.Settings.DefaultScene.Set(updated);
				project.SaveSettings().IgnoreError();
			}
		}
		GlobalLog(.Information, "Assets: renamed group '{}' -> '{}'", oldPath, group.GetPath(.. scope .()));
		Rebuild();
	}

	/// Begins the in-place edit of a content-area row.
	private void StartRename(int32 position)
	{
		AssetNameLabel label = null;
		if (mGridMode)
		{
			mGrid.ScrollToPosition(position);
			if (let tile = mGrid.GetActiveView(position) as FlexLayout)
			{
				if (tile.ChildCount >= 2)
					label = tile.GetChildAt(1) as AssetNameLabel;
			}
		}
		else
		{
			mList.ScrollToPosition(position);
			if (let row = mList.GetActiveView(position) as FlexLayout)
			{
				if (row.ChildCount >= 2)
					label = row.GetChildAt(1) as AssetNameLabel;
			}
		}
		if (label != null)
			label.BeginEdit();
	}

	/// The menu Rename path is double-deferred through the mutation queue: BeginEdit's
	/// SetFocus must land after the menu's close restored focus, and one drain is not enough.
	private void StartRenameDeferred(int32 position)
	{
		let ctx = Context;
		if (ctx == null)
			return;
		ctx.MutationQueue.QueueAction(new [=ctx, =position, =this]() =>
			{
				ctx.MutationQueue.QueueAction(new [=position, =this]() => { StartRename(position); });
			});
	}

	/// The in-place edit of a group's tree row, the background and tree menu path.
	private void StartRenameGroupInTree(Group group)
	{
		let flat = mTree.FlatAdapter;
		if (flat == null)
			return;
		for (int32 pos = 0; pos < flat.ItemCount; pos++)
		{
			if (mTreeAdapter.GroupAt(flat.GetNodeId(pos)) === group)
			{
				mTree.InternalListView.ScrollToPosition(pos);
				if (let row = mTree.InternalListView.GetActiveView(pos) as AssetNameLabel)
					row.BeginEdit();
				return;
			}
		}
	}

	private void StartRenameGroupInTreeDeferred(Group group)
	{
		let ctx = Context;
		if (ctx == null)
			return;
		ctx.MutationQueue.QueueAction(new [=ctx, =group, =this]() =>
			{
				ctx.MutationQueue.QueueAction(new [=group, =this]() => { StartRenameGroupInTree(group); });
			});
	}

	// ---- delete ----------------------------------------------------------------------------

	/// Borrows the ids for the duration of the call.
	private void ConfirmDelete(List<Guid> ids)
	{
		if (ids.IsEmpty || (Context == null))
			return;
		let message = scope String();
		if (ids.Count == 1)
		{
			let instance = Resolve(ids[0]);
			if (instance == null)
				return;
			message.AppendF("Delete '{}'? Its source file and cooked product go away; open pages close.", instance.Name);
		}
		else
		{
			message.AppendF("Delete {} assets? Their source files and cooked products go away; open pages close.", ids.Count);
		}

		let targets = new List<Guid>(ids.GetEnumerator());
		let dialog = Dialog.Confirm("Delete assets", message);
		dialog.OnClosed.Add(new [=targets, =this](d, result) =>
			{
				if (result != .OK)
					return;
				// Deferred: page teardown and database mutation never run mid dispatch.
				let ctx = Context;
				if (ctx == null)
					return;
				let queued = new List<Guid>(targets.GetEnumerator());
				ctx.MutationQueue.QueueAction(new [=queued, =this]() => { DeleteInstances(queued); } ~ delete queued);
			} ~ delete targets);
		dialog.Show(Context);
	}

	/// From the mutation queue: closes pages, deletes, logs, refreshes. Borrows the ids.
	private void DeleteInstances(List<Guid> ids)
	{
		if (mCook.MutationLocked)
		{
			let copy = new List<Guid>(ids.GetEnumerator());
			mCook.RunWhenIdle(new [=copy, =this]() => { DeleteInstances(copy); } ~ delete copy);
			mContext.Notify(.Info, "Delete queued until the current cook finishes.");
			return;
		}
		if (mContext.Project == null)
			return;
		let db = mContext.Project.SourceDb;
		int deleted = 0;
		for (let id in ids)
		{
			let instance = db.GetInstance(id);
			if (instance == null)
				continue;
			let path = instance.GetPath(.. scope .());
			if (OnCloseInstancePage != null)
				OnCloseInstancePage(id);
			if (db.DeleteInstance(id) case .Ok)
			{
				deleted++;
				GlobalLog(.Information, "Assets: deleted '{}'", path);
			}
			else
			{
				GlobalLog(.Warning, "Assets: delete FAILED for '{}'", path);
			}
		}
		mContext.SetStatus(scope $"Deleted {deleted} asset(s).");
		ClearDefaultSceneIfGone();
		Rebuild(); // the next cook's plan sweeps the orphaned products
	}

	/// F2 is inline rename, Delete a confirmed delete; dispatched by the list and grid
	/// before their own navigation keys.
	private void OnRowKeyDown(SelectionModel selection, int32 position, KeyEventArgs e)
	{
		let row = RowAt(position);
		if ((row.Group == null) && !row.Id.IsSet)
			return;
		if (e.Key == .F2)
		{
			StartRename(position);
			e.Handled = true;
		}
		else if (e.Key == .Delete)
		{
			if (row.Group != null)
			{
				ConfirmDeleteGroup(row.Group);
			}
			else
			{
				let ids = scope List<Guid>();
				SelectedInstanceIds(selection, position, ids);
				ConfirmDelete(ids);
			}
			e.Handled = true;
		}
	}

	private void ConfirmDeleteGroup(Group group)
	{
		if ((group == null) || (group.Parent == null) || (Context == null))
			return;
		int assetCount = 0;
		CountInstances(group, ref assetCount);
		let message = scope $"Delete group '{group.Name}' and ALL its contents ({assetCount} asset(s))? Source files and cooked products go away; open pages close.";
		let dialog = Dialog.Confirm("Delete group", message);
		dialog.OnClosed.Add(new [=group, =this](d, result) =>
			{
				if (result != .OK)
					return;
				let ctx = Context;
				if (ctx == null)
					return;
				// Deferred: page teardown and database mutation never run mid dispatch.
				ctx.MutationQueue.QueueAction(new [=group, =this]() => { DeleteGroupNow(group); });
			});
		dialog.Show(Context);
	}

	/// From the mutation queue: closes every page under the group, deletes the whole subtree,
	/// navigates the selection out of the dead branch.
	private void DeleteGroupNow(Group group)
	{
		if (mContext.Project == null)
			return;
		// The same cook gate as the import: deleting instances mid cook dangles the worker's
		// snapshotted pointers.
		if (mCook.MutationLocked)
		{
			mCook.RunWhenIdle(new [=group, =this]() => { DeleteGroupNow(group); });
			mContext.Notify(.Info, "Delete queued until the current cook finishes.");
			return;
		}
		let ids = scope List<Guid>();
		CollectInstanceIds(group, ids);
		if (OnCloseInstancePage != null)
		{
			for (let id in ids)
				OnCloseInstancePage(id);
		}
		// Navigated away before the pointers die.
		for (var g = mSelectedGroup; g != null; g = g.Parent)
		{
			if (g === group)
			{
				mSelectedGroup = group.Parent;
				break;
			}
		}
		let path = group.GetPath(.. scope .());
		if (mContext.Project.SourceDb.DeleteGroup(group) case .Ok)
		{
			GlobalLog(.Information, "Assets: deleted group '{}' ({} asset(s))", path, ids.Count);
			mContext.SetStatus(scope $"Deleted group '{path}'.");
		}
		else
		{
			GlobalLog(.Warning, "Assets: delete FAILED for group '{}'", path);
			mContext.Notify(.Error, "Delete group FAILED (see console).");
		}
		ClearDefaultSceneIfGone();
		Rebuild(); // the next cook's plan sweeps the orphaned products
	}

	private static void CountInstances(Group group, ref int count)
	{
		count += group.Instances.Count;
		for (let child in group.Groups)
			CountInstances(child, ref count);
	}

	private static void CollectInstanceIds(Group group, List<Guid> outIds)
	{
		for (let instance in group.Instances)
			outIds.Add(instance.Id);
		for (let child in group.Groups)
			CollectInstanceIds(child, outIds);
	}

	/// A delete may have taken the default scene with it: the manifest reference clears
	/// instead of leaving a dangling guid the player would fail on.
	private void ClearDefaultSceneIfGone()
	{
		let project = mContext.Project;
		if (project == null)
			return;
		if (!project.Settings.DefaultSceneId.IsSet && project.Settings.DefaultScene.IsEmpty)
			return;
		let resolves = project.Settings.DefaultSceneId.IsSet
			? project.SourceDb.GetInstance(project.Settings.DefaultSceneId) != null
			: project.SourceDb.GetInstanceByPath(project.Settings.DefaultScene) != null;
		if (resolves)
			return;
		project.Settings.DefaultSceneId = .Empty;
		project.Settings.DefaultScene.Clear();
		project.SaveSettings().IgnoreError();
		GlobalLog(.Information, "Assets: default scene was deleted, cleared it in the manifest");
	}
}
