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
			mFilter.Set(edit.Text);
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

		let edit = mEdit;
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		menu.AddItem("Create Child", new [=edit, =id]() => { edit.CreateEntity("Entity", id); });
		menu.AddItem("Rename", new [=this, =id]() => { BeginRename(id); });
		menu.AddSeparator();
		menu.AddItem("Duplicate", new [=edit, =id]() => { edit.DuplicateEntity(id); });
		menu.AddItem("Create Prefab from Selection", new [=this, =id]() => { if (OnCreatePrefab != null) OnCreatePrefab(id); });
		menu.AddItem("Spawn Prefab as Child", new [=this, =id]() => { if (OnSpawnPrefab != null) OnSpawnPrefab(id); });
		menu.AddItem("Spawn Prefab at Root", new [=this]() => { if (OnSpawnPrefab != null) OnSpawnPrefab(.()); });
		PrefabMemberInfo member = ?;
		if (PrefabOverrides.FindMember(edit.Scene, id, out member))
		{
			let rootId = member.State.RootEntityId;
			menu.AddSeparator();
			menu.AddItem("Apply to Prefab", new [=this, =rootId]() => { if (OnApplyPrefab != null) OnApplyPrefab(rootId); });
			menu.AddItem("Revert Instance", new [=this, =rootId]() => { if (OnRevertPrefab != null) OnRevertPrefab(rootId); });
		}
		if (let editor = mEditor)
		{
			menu.AddItem("Copy", new [=edit, =editor, =id]() =>
			{
				let blob = scope List<uint8>();
				edit.CopyEntity(id, blob);
				if (!blob.IsEmpty)
					editor.SetClipboard("entities", blob);
			});
			let clip = editor.ClipboardData("entities");
			menu.AddItem("Paste as Child", new [=edit, =editor, =id]() =>
			{
				edit.PasteEntities(editor.ClipboardData("entities"), id);
			}, !clip.IsEmpty);
		}
		menu.AddSeparator();
		menu.AddItem("Delete", new [=edit, =id]() => { edit.DestroyEntity(id); });
		let screenPos = mTree.InternalTreeView.LocalToScreen(.(x, y));
		menu.Show(Context, screenPos.X, screenPos.Y);
	}

	private void ShowBackgroundMenu(float x, float y)
	{
		if (Context == null)
			return;
		let edit = mEdit;
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		menu.AddItem("Create Entity", new [=edit]() => { edit.CreateEntity("Entity"); });
		menu.AddItem("Spawn Prefab...", new [=this]() => { if (OnSpawnPrefab != null) OnSpawnPrefab(.()); });
		if (let editor = mEditor)
		{
			let clip = editor.ClipboardData("entities");
			menu.AddItem("Paste", new [=edit, =editor]() =>
			{
				edit.PasteEntities(editor.ClipboardData("entities"));
			}, !clip.IsEmpty);
		}
		let screenPos = mTree.InternalTreeView.InternalListView.LocalToScreen(.(x, y));
		menu.Show(Context, screenPos.X, screenPos.Y);
	}
}
