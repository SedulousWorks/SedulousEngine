using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The scene's entity tree: a filter box, an add button, and a draggable tree over a
/// pre-order SNAPSHOT of the scene, rebuilt when the scene's revision moves. Collapse
/// state and the selection survive a rebuild. Selection flows both ways: a click or a
/// keyboard move sets the scene selection, and a scene selection change selects the row.
///
/// The edit context is borrowed; the page owns it. The prefab verbs are delegated out
/// through the four callbacks, which the view owns.
class SceneHierarchyView : ViewGroup
{
	public delegate void(Guid) OnCreatePrefab ~ delete _;
	public delegate void(Guid) OnSpawnPrefab ~ delete _;
	/// An instance root: write the instance back to its asset.
	public delegate void(Guid) OnApplyPrefab ~ delete _;
	/// An instance root: discard its deltas.
	public delegate void(Guid) OnRevertPrefab ~ delete _;

	private SceneEditContext mEdit;
	/// Borrowed; the clipboard's home. Optional.
	private EditorContext mEditor = null;
	private DraggableTreeView mTree;
	private EditText mFilterEdit;
	private HierarchyAdapter mAdapter ~ delete _;
	private List<HierarchyNode> mNodes = new .() ~ DeleteContainerAndItems!(_);
	private List<int32> mRoots = new .() ~ delete _;
	/// The entities the user collapsed; survives rebuilds.
	private HashSet<Guid> mCollapsed = new .() ~ delete _;
	private uint64 mRevision = uint64.MaxValue;
	private String mFilter = new .() ~ delete _;
	private bool mSyncing = false;

	public this(SceneEditContext edit)
	{
		mEdit = edit;

		let column = new FlexLayout();
		column.Direction = .Vertical;

		let header = new FlexLayout();
		header.Direction = .Horizontal;
		header.Spacing = 4.0f;
		header.Padding = .(4, 3);
		let addButton = new Button("+");
		addButton.OnClick.Add(new [=edit](b) => { edit.CreateEntity("Entity"); });
		header.AddView(addButton);
		mFilterEdit = new EditText();
		mFilterEdit.SetPlaceholder("Filter...");
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		header.AddView(mFilterEdit, grow);
		column.AddView(header);

		mAdapter = new HierarchyAdapter(this);
		mTree = new DraggableTreeView();
		mTree.ItemHeight = 22.0f;
		mTree.SetAdapter(mAdapter);
		column.AddView(mTree, grow);

		AddView(column);

		WireEvents();
	}

	public ~this()
	{
		// The selection's callback captures this view.
		delete mEdit.EntitySelection.OnChanged;
		mEdit.EntitySelection.OnChanged = null;
		mTree.SetAdapter(null);
	}

	public void SetEditorContext(EditorContext context) => mEditor = context;

	public DraggableTreeView Tree => mTree;
	public int NodeCount => mNodes.Count;

	/// Rebuilds the snapshot when the scene changed since the last look.
	public void Refresh()
	{
		if (mEdit.Scene.Revision != mRevision)
		{
			mRevision = mEdit.Scene.Revision;
			RebuildSnapshot();
		}
	}

	/// Scrolls to an entity's row and opens its name for editing.
	public void BeginRename(Guid entity)
	{
		let flat = mTree.InternalTreeView.FlatAdapter;
		if (flat == null)
			return;
		for (int32 pos < flat.ItemCount)
		{
			if (GuidOfNode(flat.GetNodeId(pos)) == entity)
			{
				let list = mTree.InternalTreeView.InternalListView;
				list.ScrollToPosition(pos);
				if (let row = list.GetActiveView(pos) as HierarchyRow)
					row.BeginEdit();
				return;
			}
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if ((e.Button == .Right) && (Context != null))
		{
			let menu = new ContextMenu();
			defer menu.ReleaseRef();
			let edit = mEdit;
			menu.AddItem("Create Entity", new [=edit]() => { edit.CreateEntity("Entity"); });
			menu.AddItem("Spawn Prefab...", new [=this]() => { if (OnSpawnPrefab != null) OnSpawnPrefab(.()); });
			let screenPos = LocalToScreen(.(e.X, e.Y));
			menu.Show(Context, screenPos.X, screenPos.Y);
			e.Handled = true;
		}
	}

	/// Fills the available space: the default ViewGroup measure wraps to children, which
	/// would collapse the virtualised tree.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		for (int i < ChildCount)
			GetChildAt(i).Measure(constraints);
		MeasuredSize = .(constraints.MaxWidth, constraints.MaxHeight);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i < ChildCount)
			GetChildAt(i).Layout(0, 0, width, height);
	}

	// ---- snapshot ----

	/// A case insensitive substring match; an empty filter matches everything.
	public static bool MatchesFilter(StringView name, StringView filter)
	{
		if (filter.IsEmpty)
			return true;
		if (name.Length < filter.Length)
			return false;
		for (int i = 0; i + filter.Length <= name.Length; i++)
		{
			var match = true;
			for (int j < filter.Length)
			{
				if (name[i + j].ToLower != filter[j].ToLower)
				{
					match = false;
					break;
				}
			}
			if (match)
				return true;
		}
		return false;
	}

	/// An entity shows when it or anything beneath it matches, so a match keeps its path.
	private bool SubtreeMatches(Sedulous.Scene.Scene scene, EntityHandle e)
	{
		if (MatchesFilter(scene.GetEntityName(e), mFilter))
			return true;
		for (var c = scene.GetFirstChild(e); c.IsAssigned; c = scene.GetNextSibling(c))
		{
			if (SubtreeMatches(scene, c))
				return true;
		}
		return false;
	}

	private void CaptureCollapseState()
	{
		let flat = mTree.InternalTreeView.FlatAdapter;
		if (flat == null)
			return;
		for (int32 i < (int32)mNodes.Count)
		{
			if (mNodes[i].Children.IsEmpty)
				continue;
			if (flat.IsExpanded(i))
				mCollapsed.Remove(mNodes[i].Id);
			else
				mCollapsed.Add(mNodes[i].Id);
		}
	}

	private void RebuildSnapshot()
	{
		CaptureCollapseState();
		ClearAndDeleteItems(mNodes);
		mRoots.Clear();
		let scene = mEdit.Scene;

		for (var r = scene.FirstRoot; r.IsAssigned; r = scene.GetNextSibling(r))
		{
			if (SubtreeMatches(scene, r))
				mRoots.Add(AddNode(scene, r, 0));
		}

		// SetAdapter rebuilds the flat view; everything not collapsed by the user is expanded.
		mTree.SetAdapter(mAdapter);
		let flat = mTree.InternalTreeView.FlatAdapter;
		for (int32 i < (int32)mNodes.Count)
		{
			if (mNodes[i].Children.IsEmpty)
				continue;
			if (!mCollapsed.Contains(mNodes[i].Id))
				flat.Expand(i);
		}
		mTree.InternalTreeView.InternalListView.NotifyDataChanged();
		SyncSelectionToTree();
	}

	private int32 AddNode(Sedulous.Scene.Scene scene, EntityHandle e, int32 depth)
	{
		let nodeId = (int32)mNodes.Count;
		let node = new HierarchyNode();
		node.Id = scene.GetEntityId(e);
		node.Name.Set(scene.GetEntityName(e));
		if (node.Name.IsEmpty)
			node.Name.Set("(unnamed)");
		node.Depth = depth;
		mNodes.Add(node);

		for (var c = scene.GetFirstChild(e); c.IsAssigned; c = scene.GetNextSibling(c))
		{
			if (!SubtreeMatches(scene, c))
				continue;
			let child = AddNode(scene, c, depth + 1);
			mNodes[nodeId].Children.Add(child);
		}
		return nodeId;
	}

	public Guid GuidOfNode(int32 nodeId)
		=> ((nodeId >= 0) && (nodeId < mNodes.Count)) ? mNodes[nodeId].Id : Guid();

	public Guid GuidAtFlat(int32 flatPosition)
	{
		let flat = mTree.InternalTreeView.FlatAdapter;
		return (flat != null) ? GuidOfNode(flat.GetNodeId(flatPosition)) : Guid();
	}

	public int32 FlatCount
	{
		get
		{
			let flat = mTree.InternalTreeView.FlatAdapter;
			return (flat != null) ? flat.ItemCount : 0;
		}
	}

	private void SyncSelectionToTree()
	{
		let selection = mEdit.EntitySelection;
		let sel = mTree.Selection;
		mSyncing = true;
		if (selection.IsEmpty)
		{
			sel.ClearSelection();
		}
		else if (let flat = mTree.InternalTreeView.FlatAdapter)
		{
			let primary = selection.Primary;
			for (int32 pos < flat.ItemCount)
			{
				if (GuidOfNode(flat.GetNodeId(pos)) == primary)
				{
					sel.Select(pos);
					break;
				}
			}
		}
		mSyncing = false;
	}
}
