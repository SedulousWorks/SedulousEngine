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
/// The edit context is borrowed; the page owns it. The context menus are the scene editor's
/// actions (create, duplicate, delete, the prefab flows, the clipboard) over the page this
/// hierarchy belongs to, around the view's own rename and copy id items.
class SceneHierarchyView : ViewGroup
{
	private SceneEditContext mEdit;
	/// BORROWED, nullable: the toasts.
	private EditorContext mEditor = null;
	/// BORROWED: the context owns the registry, the page owns this view. Null without actions
	/// (a bare view in a test): the menus then carry only the view's own items.
	private EditorActionRegistry mActions = null;
	private EditorPage mSubject = null;
	private DraggableTreeView mTree;
	private EditText mFilterEdit;
	private EntityTreeSnapshot mSnapshot = new .() ~ delete _;
	private HierarchyAdapter mAdapter ~ delete _;
	/// The entities the user collapsed; survives rebuilds.
	private HashSet<Guid> mCollapsed = new .() ~ delete _;
	private uint64 mRevision = uint64.MaxValue;
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

		mAdapter = new HierarchyAdapter(this, mSnapshot);
		mTree = new DraggableTreeView();
		mTree.ItemHeight = 22.0f;
		mAdapter.SetTree(mTree.InternalTreeView);
		mTree.SetAdapter(mAdapter);
		// A dragged row names its entity, so an inspector's entity slot can take it.
		mTree.OnDecorateDragData = new [=this](data) => { DecorateDrag(data); };
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

	/// The scene editor's actions over `subject`, the page this hierarchy belongs to.
	public void SetActions(EditorActionRegistry actions, EditorPage subject)
	{
		mActions = actions;
		mSubject = subject;
	}

	/// Puts an entity's PERSISTENT id on the OS text clipboard: the id the scene file, the
	/// prefab deltas and a script all name it by. False with a bare view, which has no UI
	/// context to reach a clipboard through, or a nil entity.
	public bool CopyEntityId(Guid id)
	{
		let clipboard = (Context != null) ? Context.Clipboard : null;
		if ((clipboard == null) || id.IsNil)
			return false;
		if (mEditor != null)
			return mEditor.CopyText(clipboard, scope $"{id}", "entity ID"); // with its toast
		return clipboard.SetText(scope $"{id}") case .Ok;
	}

	/// The editor whose toasts say what was copied. BORROWED; null for a bare view.
	public void SetEditor(EditorContext editor) => mEditor = editor;

	public SceneEditContext Edit => mEdit;
	public DraggableTreeView Tree => mTree;
	public int NodeCount => mSnapshot.Count;

	/// Rebuilds the snapshot when the scene changed since the last look.
	public void Refresh()
	{
		if (mEdit.Scene.Revision != mRevision)
		{
			mRevision = mEdit.Scene.Revision;
			RebuildSnapshot();
		}
	}

	/// Names the entity a drag of flat row `data.SourcePosition` carries.
	public void DecorateDrag(TreeDragData data)
	{
		let flat = mTree.InternalTreeView.FlatAdapter;
		if ((flat == null) || (data.SourcePosition < 0) || (data.SourcePosition >= flat.ItemCount))
			return;
		let id = GuidOfNode(flat.GetNodeId(data.SourcePosition));
		if (id.IsNil)
			return;
		data.ItemKind.Set("entity");
		data.ItemId = id;
		let h = mEdit.Scene.FindEntity(id);
		if (h.IsAssigned)
			data.ItemName.Set(mEdit.Scene.GetEntityName(h));
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
			if (mActions != null)
				mActions.AppendActionItems(menu, mSubject, SceneActionIds.EntityCreate, SceneActionIds.EntitySpawnPrefab, SceneActionIds.EntityPaste);
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
		=> EntityTreeSnapshot.MatchesFilter(name, filter);

	private void CaptureCollapseState()
	{
		let flat = mTree.InternalTreeView.FlatAdapter;
		if (flat == null)
			return;
		let nodes = mSnapshot.Nodes;
		for (int32 i < (int32)nodes.Count)
		{
			if (nodes[i].Children.IsEmpty)
				continue;
			if (flat.IsExpanded(i))
				mCollapsed.Remove(nodes[i].Id);
			else
				mCollapsed.Add(nodes[i].Id);
		}
	}

	private void RebuildSnapshot()
	{
		CaptureCollapseState();
		mSnapshot.Rebuild(mEdit.Scene, "(unnamed)");

		// SetAdapter rebuilds the flat view; everything not collapsed by the user is expanded.
		mTree.SetAdapter(mAdapter);
		let flat = mTree.InternalTreeView.FlatAdapter;
		let nodes = mSnapshot.Nodes;
		for (int32 i < (int32)nodes.Count)
		{
			if (nodes[i].Children.IsEmpty)
				continue;
			if (!mCollapsed.Contains(nodes[i].Id))
				flat.Expand(i);
		}
		mTree.InternalTreeView.InternalListView.NotifyDataChanged();
		SyncSelectionToTree();
	}

	public Guid GuidOfNode(int32 nodeId) => mSnapshot.GuidOfNode(nodeId);

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
