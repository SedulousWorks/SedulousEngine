using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.Editor.Scene;

/// The tree half: the snapshot rebuilt from the effect, selection by ref, and the row
/// context menu that adds, moves and deletes systems and modules.
extension ParticleEffectEditorPage
{
	/// The node table from the effect, every node expanded.
	private void RebuildTree()
	{
		mSnapshot.Rebuild((mAsset != null) ? mAsset.Effect : null);
		mTree.SetAdapter(mAdapter);
		if (let flat = mTree.InternalTreeView.FlatAdapter)
		{
			for (int32 i < (int32)mSnapshot.Nodes.Count)
			{
				if (!mSnapshot.Nodes[i].Children.IsEmpty)
					flat.Expand(i);
			}
		}
		mTree.InternalTreeView.InternalListView.NotifyDataChanged();
	}

	/// Selects `target` in the tree and inspects it.
	private void SelectNode(ParticleNodeRef target)
	{
		mSelected = target;
		let nodeId = mSnapshot.NodeIdForRef(target);
		if (nodeId >= 0)
		{
			if (let flat = mTree.InternalTreeView.FlatAdapter)
			{
				for (int32 p < flat.ItemCount)
				{
					if (flat.GetNodeId(p) == nodeId)
					{
						mTree.Selection.ClearSelection();
						mTree.Selection.Select(p);
						break;
					}
				}
			}
		}
		RebuildInspector();
	}

	private void ShowNodeContextMenu(int32 nodeId, float screenX, float screenY)
	{
		if (!mSnapshot.InRange(nodeId) || (mAsset == null))
			return;
		let node = mSnapshot.Nodes[nodeId];
		let ctx = Ctx;
		if (ctx == null)
			return;
		let menu = new ContextMenu();
		defer menu.ReleaseRef();

		switch (node.Kind)
		{
		case .Effect:
			menu.AddItem("Add System", new [=this]() => { AddSystem(); });
		case .System:
			let sysIndex = node.SystemIndex;
			AddInitializerMenu(menu, sysIndex);
			AddBehaviorMenu(menu, sysIndex);
			menu.AddSeparator();
			if (mAsset.Effect.SystemCount > 1)
			{
				menu.AddItem("Delete System", new [=this, =sysIndex]() =>
					{
						QueueStructural("del-system", new [=this, =sysIndex]() => { mAsset.Effect.RemoveSystem(sysIndex); }, .Root);
					});
			}
		case .InitializersFolder:
			AddInitializerMenu(menu, node.SystemIndex);
		case .BehaviorsFolder:
			AddBehaviorMenu(menu, node.SystemIndex);
		case .Initializer, .Behavior:
			let kind = node.Kind;
			let sysIndex = node.SystemIndex;
			let mod = node.ModuleIndex;
			let folder = (kind == .Initializer) ? ParticleNodeKind.InitializersFolder : ParticleNodeKind.BehaviorsFolder;
			menu.AddItem("Move Up", new [=this, =kind, =sysIndex, =mod]() => { MoveModule(kind, sysIndex, mod, mod - 1); }, mod > 0);
			menu.AddItem("Move Down", new [=this, =kind, =sysIndex, =mod]() => { MoveModule(kind, sysIndex, mod, mod + 1); });
			menu.AddSeparator();
			menu.AddItem("Delete", new [=this, =kind, =sysIndex, =mod, =folder]() =>
				{
					QueueStructural((kind == .Initializer) ? "del-init" : "del-beh", new [=this, =kind, =sysIndex, =mod]() =>
						{
							if (let s = mAsset.Effect.GetSystem(sysIndex))
							{
								if (kind == .Initializer)
									s.RemoveInitializer(mod);
								else
									s.RemoveBehavior(mod);
							}
						}, .(folder, sysIndex, -1));
				});
		default:
		}
		menu.Show(ctx, screenX, screenY);
	}

	private void AddSystem()
	{
		let next = mAsset.Effect.SystemCount;
		QueueStructural("add-system", new [=this]() => { mAsset.Effect.AddSystem(2000); }, .(.System, next, -1));
	}

	private void AddInitializerMenu(ContextMenu menu, int32 sysIndex)
	{
		let sub = menu.AddSubmenu("Add Initializer").Submenu;
		if (sub == null)
			return;
		for (int k < ParticleEffectEdit.InitializerNames.Count)
		{
			let kind = k;
			sub.AddItem(ParticleEffectEdit.InitializerNames[k], new [=this, =sysIndex, =kind]() =>
				{
					QueueStructural("add-init", new [=this, =sysIndex, =kind]() =>
						{
							if (let s = mAsset.Effect.GetSystem(sysIndex))
								ParticleEffectEdit.AddInitializer(s, kind);
						}, .(.InitializersFolder, sysIndex, -1));
				});
		}
	}

	private void AddBehaviorMenu(ContextMenu menu, int32 sysIndex)
	{
		let sub = menu.AddSubmenu("Add Behavior").Submenu;
		if (sub == null)
			return;
		for (int k < ParticleEffectEdit.BehaviorNames.Count)
		{
			let kind = k;
			sub.AddItem(ParticleEffectEdit.BehaviorNames[k], new [=this, =sysIndex, =kind]() =>
				{
					QueueStructural("add-beh", new [=this, =sysIndex, =kind]() =>
						{
							if (let s = mAsset.Effect.GetSystem(sysIndex))
								ParticleEffectEdit.AddBehavior(s, kind);
						}, .(.BehaviorsFolder, sysIndex, -1));
				});
		}
	}
}
