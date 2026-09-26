using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene.Resource;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The hierarchy's event wiring: selection both ways, the row and background menus, the
/// keyboard verbs, and the filter.
extension SceneHierarchyView
{
	private void WireEvents()
	{
		let tree = mTree.InternalTreeView;

		tree.OnItemClick.Add(new [=this](info) =>
		{
			if (mSyncing)
				return;
			let id = GuidOfNode(info.NodeId);
			if (id != Guid())
			{
				mSyncing = true;
				mEdit.EntitySelection.Set(id);
				mSyncing = false;
			}
		});

		// Arrow key navigation moves the selection model without a click.
		mTree.Selection.OnSelectionChanged.Add(new [=this]() =>
		{
			if (mSyncing)
				return;
			let pos = mTree.Selection.FirstSelected();
			let id = (pos >= 0) ? GuidAtFlat(pos) : Guid();
			if (id != Guid())
			{
				mSyncing = true;
				mEdit.EntitySelection.Set(id);
				mSyncing = false;
			}
		});

		tree.OnItemRightClick.Add(new [=this](nodeId, x, y) => { ShowRowMenu(nodeId, x, y); });
		tree.InternalListView.OnBackgroundRightClicked.Add(new [=this](x, y) => { ShowBackgroundMenu(x, y); });

		tree.OnItemKeyDown.Add(new [=this](nodeId, e) =>
		{
			let id = GuidOfNode(nodeId);
			if (id == Guid())
				return;
			if (e.Key == .F2)
			{
				BeginRename(id);
				e.Handled = true;
			}
			else if (e.Key == .Delete)
			{
				mEdit.DestroyEntity(id);
				e.Handled = true;
			}
		});

		mFilterEdit.OnTextChanged.Add(new [=this](edit) =>
		{
			mSnapshot.Filter.Set(edit.Text);
			RebuildSnapshot(); // a filter change rebuilds regardless of the revision
		});

		delete mEdit.EntitySelection.OnChanged;
		mEdit.EntitySelection.OnChanged = new [=this]() =>
		{
			if (mSyncing)
				return;
			SyncSelectionToTree();
		};
	}

	private void ShowRowMenu(int32 nodeId, float x, float y)
	{
		let id = GuidOfNode(nodeId);
		if ((id == Guid()) || (Context == null))
			return;
		mEdit.EntitySelection.Set(id);

		// The scene editor's actions over the page (the right-click selected this entity, so
		// they act on it), with the view's own items between.
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		if (mActions != null)
			mActions.AppendActionItems(menu, mSubject, SceneActionIds.EntityCreateChild);
		menu.AddItem("Rename", new [=this, =id]() => { BeginRename(id); });
		menu.AddItem("Copy ID", new [=this, =id]() => { CopyEntityId(id); });
		if (mActions != null)
		{
			menu.AddSeparator();
			mActions.AppendActionItems(menu, mSubject, SceneActionIds.EntityDuplicate, SceneActionIds.EntityCreatePrefab,
				SceneActionIds.EntitySpawnPrefabAsChild, SceneActionIds.EntitySpawnPrefab);
			if (mActions.IsEnabled(SceneActionIds.PrefabApply, mSubject))
			{
				menu.AddSeparator();
				mActions.AppendActionItems(menu, mSubject, SceneActionIds.PrefabApply, SceneActionIds.PrefabRevert);
			}
			menu.AddSeparator();
			mActions.AppendActionItems(menu, mSubject, SceneActionIds.EntityCopy, SceneActionIds.EntityPasteAsChild);
			menu.AddSeparator();
			mActions.AppendActionItems(menu, mSubject, SceneActionIds.EntityDelete);
		}
		let screenPos = mTree.InternalTreeView.LocalToScreen(.(x, y));
		menu.Show(Context, screenPos.X, screenPos.Y);
	}

	private void ShowBackgroundMenu(float x, float y)
	{
		if (Context == null)
			return;
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		if (mActions != null)
			mActions.AppendActionItems(menu, mSubject, SceneActionIds.EntityCreate, SceneActionIds.EntitySpawnPrefab, SceneActionIds.EntityPaste);
		let screenPos = mTree.InternalTreeView.InternalListView.LocalToScreen(.(x, y));
		menu.Show(Context, screenPos.X, screenPos.Y);
	}
}
