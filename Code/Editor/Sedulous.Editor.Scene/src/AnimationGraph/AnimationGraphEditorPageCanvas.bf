using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Scene;

/// The canvas half: the selected layer's states as nodes and transitions as edges, the
/// canvas gestures mapped onto the model, and the canvas, node and edge menus.
extension AnimationGraphEditorPage
{
	private const int32 cAnyStateNode = 0;
	private static int32 StateToNode(int32 state) => state + 1;
	private static int32 NodeToState(int32 node) => node - 1;

	private static Color HeaderPlain => .(0.27f, 0.40f, 0.60f, 1.0f);
	private static Color HeaderDefault => .(0.80f, 0.52f, 0.18f, 1.0f);
	private static Color HeaderAny => .(0.30f, 0.55f, 0.50f, 1.0f);

	private void WireCanvas()
	{
		mCanvas.OnNodeMoved.Add(new [=this](node) =>
			{
				if (mSyncingCanvas || (mAsset == null))
					return;
				let n = mCanvas.GetNode(node);
				if (n == null)
					return;
				AnimationGraphEdit.SyncLayouts(mAsset, mDoc);
				if (!mDoc.HasLayer(mSelectedLayer))
					return;
				let layout = mAsset.LayerLayouts[mSelectedLayer];
				if (node == cAnyStateNode)
					layout.AnyStatePosition = n.Position;
				else
				{
					let state = NodeToState(node);
					if ((state >= 0) && (state < layout.StatePositions.Count))
						layout.StatePositions[state] = n.Position;
				}
				CommitEdit("move-node");
			});
		mCanvas.OnCanvasContextMenu.Add(new [=this](x, y) => { ShowCanvasMenu(x, y); });
		mCanvas.OnNodeContextMenu.Add(new [=this](node) => { ShowNodeMenu(node); });
		mCanvas.OnConnectionContextMenu.Add(new [=this](conn) => { ShowConnectionMenu(conn); });
		mCanvas.OnNodeDoubleClicked.Add(new [=this](node) =>
			{
				if (node != cAnyStateNode)
					Select(.(.State, mSelectedLayer, NodeToState(node)));
			});
		mCanvas.OnNodeLinkRequested.Add(new [=this](sourceNode, targetNode) =>
			{
				if ((targetNode == cAnyStateNode) || (mAsset == null))
					return;
				let layerIndex = mSelectedLayer;
				let src = (sourceNode == cAnyStateNode) ? (int32)-1 : NodeToState(sourceNode);
				let dst = NodeToState(targetNode);
				QueueStructural("add-transition", new [=this, =layerIndex, =src, =dst]() =>
					{
						if (let layer = mDoc.Layer(layerIndex))
							layer.AddTransition(src, dst);
					}, .(.Transition, layerIndex, GraphSel.Last));
			});
		mCanvas.OnConnectionDeleting.Add(new [=this](connectionIndex) =>
			{
				if (mSyncingCanvas)
					return;
				let layerIndex = mSelectedLayer;
				QueueStructural("del-transition", new [=this, =layerIndex, =connectionIndex]() =>
					{
						if (let layer = mDoc.Layer(layerIndex))
							layer.RemoveTransition(connectionIndex);
					}, .None);
			});
		mCanvas.OnSelectionChanged.Add(new [=this]() =>
			{
				if (mSyncingCanvas)
					return;
				let nodes = scope List<int32>();
				mCanvas.GetSelectedNodes(nodes);
				var derived = GraphSel.None; // an empty space click, or a cleared box select
				if (!nodes.IsEmpty)
				{
					if (nodes[0] != cAnyStateNode)
						derived = .(.State, mSelectedLayer, NodeToState(nodes[0]));
				}
				else
				{
					for (int32 i < mCanvas.ConnectionCount)
					{
						if (mCanvas.GetConnection(i).IsSelected)
						{
							derived = .(.Transition, mSelectedLayer, i);
							break;
						}
					}
				}
				if (derived != mSelected)
					Select(derived);
			});
	}

	/// Nodes and connections for the selected layer; Any State is node zero, a state its
	/// index plus one.
	private void RebuildCanvas()
	{
		mSyncingCanvas = true;
		mCanvas.Clear();
		let layer = CurrentLayer;
		if ((layer != null) && (mAsset != null))
		{
			AnimationGraphEdit.SyncLayouts(mAsset, mDoc);
			let layout = mAsset.LayerLayouts[mSelectedLayer];

			let any = new NodeGraphNode();
			any.Title.Set("Any State");
			any.Position = layout.AnyStatePosition;
			any.Size = .(140.0f, 44.0f);
			any.HeaderColor = HeaderAny;
			any.IsDeletable = false;
			mCanvas.AddNode(any);

			for (int i < layer.States.Count)
			{
				let s = layer.States[i];
				let node = new NodeGraphNode();
				node.Title.Set(s.Name);
				node.Subtitle.Set(AnimationGraphEdit.NodeKindLabel(s.NodeKind));
				node.Position = layout.StatePositions[i];
				node.Size = .(150.0f, 46.0f);
				node.HeaderColor = ((int32)i == layer.DefaultState) ? HeaderDefault : HeaderPlain;
				node.IsDeletable = false; // deletion goes through the menu, model first
				mCanvas.AddNode(node);
			}
			for (let tr in layer.Transitions)
			{
				var conn = NodeGraphConnection();
				conn.SourceNodeIndex = (tr.Src < 0) ? cAnyStateNode : StateToNode(tr.Src);
				conn.DestNodeIndex = StateToNode(tr.Dst);
				mCanvas.AddConnection(conn);
			}
		}
		mLastHighlightedNode = -1;
		mSyncingCanvas = false;
	}

	private void ShowCanvasMenu(float canvasX, float canvasY)
	{
		let ctx = Ctx;
		if ((ctx == null) || (mAsset == null))
			return;
		let layerIndex = mSelectedLayer;
		let at = Float2(canvasX, canvasY);
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		AddStateItem(menu, "Add Clip State", 0, layerIndex, at);
		AddStateItem(menu, "Add Blend Tree 1D", 1, layerIndex, at);
		AddStateItem(menu, "Add Blend Tree 2D", 2, layerIndex, at);
		let screen = mCanvas.LocalToScreen(mCanvas.CanvasToScreen(at));
		menu.Show(ctx, screen.X, screen.Y);
	}

	private void AddStateItem(ContextMenu menu, StringView label, uint8 kind, int32 layerIndex, Float2 at)
	{
		menu.AddItem(label, new [=this, =layerIndex, =at, =kind]() =>
			{
				QueueStructural("add-state", new [=this, =layerIndex, =at, =kind]() =>
					{
						let layer = mDoc.Layer(layerIndex);
						if (layer == null)
							return;
						layer.AddState(scope $"State {layer.States.Count}", kind);
						AnimationGraphEdit.SyncLayouts(mAsset, mDoc);
						let positions = mAsset.LayerLayouts[layerIndex].StatePositions;
						positions[positions.Count - 1] = at;
					}, .(.State, layerIndex, GraphSel.Last));
			});
	}

	private void ShowNodeMenu(int32 nodeIndex)
	{
		let ctx = Ctx;
		let layer = CurrentLayer;
		if ((ctx == null) || (layer == null))
			return;
		let layerIndex = mSelectedLayer;
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		menu.AddItem("Make Transition", new [=this, =nodeIndex]() => { mCanvas.StartLinkFrom(nodeIndex); });
		if (nodeIndex != cAnyStateNode)
		{
			let stateIndex = NodeToState(nodeIndex);
			menu.AddItem("Set as Default State", new [=this, =layerIndex, =stateIndex]() =>
				{
					QueueStructural("set-default", new [=this, =layerIndex, =stateIndex]() =>
						{
							if (let l = mDoc.Layer(layerIndex))
								l.DefaultState = stateIndex;
						}, .(.State, layerIndex, stateIndex));
				});
			menu.AddSeparator();
			menu.AddItem("Delete State", new [=this, =layerIndex, =stateIndex]() =>
				{
					QueueStructural("del-state", new [=this, =layerIndex, =stateIndex]() => { DeleteState(layerIndex, stateIndex); }, .(.Layer, layerIndex, layerIndex));
				});
		}
		var at = mCanvas.LocalToScreen(.(0.0f, 0.0f));
		if (let node = mCanvas.GetNode(nodeIndex))
			at = mCanvas.LocalToScreen(mCanvas.CanvasToScreen(node.Position));
		menu.Show(ctx, at.X + 16.0f, at.Y + 16.0f);
	}

	private void ShowConnectionMenu(int32 connectionIndex)
	{
		let ctx = Ctx;
		if (ctx == null)
			return;
		let layerIndex = mSelectedLayer;
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		menu.AddItem("Edit Transition", new [=this, =layerIndex, =connectionIndex]() => { Select(.(.Transition, layerIndex, connectionIndex)); });
		menu.AddSeparator();
		menu.AddItem("Delete Transition", new [=this, =layerIndex, =connectionIndex]() =>
			{
				QueueStructural("del-transition", new [=this, =layerIndex, =connectionIndex]() =>
					{
						if (let layer = mDoc.Layer(layerIndex))
							layer.RemoveTransition(connectionIndex);
					}, .None);
			});
		let screen = mCanvas.LocalToScreen(.(20.0f, 20.0f));
		menu.Show(ctx, screen.X, screen.Y);
	}

	/// Removes a state from the model and its canvas position together.
	private void DeleteState(int32 layerIndex, int32 stateIndex)
	{
		let layer = mDoc.Layer(layerIndex);
		if ((layer == null) || !layer.DeleteState(stateIndex))
			return;
		if (layerIndex < mAsset.LayerLayouts.Count)
		{
			let positions = mAsset.LayerLayouts[layerIndex].StatePositions;
			if (stateIndex < positions.Count)
				positions.RemoveAt(stateIndex);
		}
	}

	/// Puts the active state ring on the node the player is in.
	private void HighlightNode(int32 highlightNode)
	{
		if (highlightNode == mLastHighlightedNode)
			return;
		for (int32 n < mCanvas.NodeCount)
		{
			if (let node = mCanvas.GetNode(n))
				node.IsHighlighted = n == highlightNode;
		}
		mLastHighlightedNode = highlightNode;
		mCanvas.Invalidate();
	}
}
