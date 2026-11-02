using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// ItemView: the engine behind ListView, TreeView and TableView. It is a scroll container like any
// other node (its wheel, bars, touch, fling, smooth scrolling, right stick and `::scrollbar` parts
// are Node's), which realises only the rows in view:
//
//   - Rows come from a factory (a native one, or the view's own default): each row type has a
//     pool of rows, and a row scrolled out of view goes back to its pool for the next one.
//     A row is an ItemRow holding the factory's content; it shows `:selected`.
//   - Heights are fixed (`row-height`) or measured: a measured row's height is estimated until it
//     is first realised, then measured, and kept in a sum tree (RowHeights), so finding the row at
//     an offset or the offset of a row is a logarithmic walk (GPUI's list in role).
//   - Scrolling is anchored to an item and an offset into it: a row above measuring taller, or
//     rows inserted above, leave what is in view where it is.
//   - The model reports row ranges; the view follows inserts, removals, moves and changes of a
//     flat model and resets for the rest. Selection is a set of row ids, so it survives inserts,
//     moves and sorting.
//   - A grid is a layout mode of the same view: cells of a size, as many across as fit (stretched
//     to fill the row), lines of them down; the arrows move across and down.
//   - Rows from markup: a `<template>` child is made into each row, its `{{item}}`,
//     `{{item.Column}}` and `{{index}}` attributes filled for the item it shows; templates of a
//     `type` are picked by the text in the view's `row-type-column`. `items="a|b|c"` gives a
//     markup list a model of its own.
//   - Drag and drop: with a `drag-type`, rows drag the selection (their ids, the view a weak
//     reference in the payload's value); as a target the view finds where a drop lands in a row
//     (before, on or after it, by quarter bands, by halves when the model takes nothing onto a
//     row), asks its model (ModelDrop: CanDrop, Drop), and draws an insertion line or an outline
//     (`::drop-indicator`); a row moved to another model is removed from this one.
//   - A double-click, Return or the pad's South reports `activate`; typing letters and digits
//     jumps to the next row that starts with them (read from the keys, not text input, which the
//     shell turns on for fields alone); F2 (or BeginEdit) edits a row in place, a hook able to
//     refuse the edit or the value.
//
// A subclass says what an item is (ItemCount, ItemToModelIndex: a tree flattens its open nodes),
// makes its default rows (CreateContent, BindContent), and adds decorations (a table's header).

enum SelectionMode
{
	Single,
	Multi
}

/// How an item view lays its items out: rows down (List), or cells across then down (Grid).
enum ItemLayout : uint8
{
	List,
	Grid,
}

/// Row heights in a sum tree (a Fenwick tree): the offset of a row and the row at an offset
/// in O(log n), a height changed in O(log n); inserts and removals rebuild it, O(n).
class RowHeights
{
	private List<float> mHeights = new .() ~ delete _;
	private List<uint8> mMeasured = new .() ~ delete _;
	private List<float> mTree = new .() ~ delete _; // 1-based
	private int mHighBit = 1;

	public void Reset(int count, float estimate)
	{
		mHeights.Clear();
		mMeasured.Clear();
		for (int i = 0; i < count; ++i)
		{
			mHeights.Add(estimate);
			mMeasured.Add(0);
		}
		Rebuild();
	}

	public void Insert(int at, int count, float estimate)
	{
		var at;
		at = Math.Min(at, mHeights.Count);
		for (int i = 0; i < count; ++i)
		{
			mHeights.Insert(at, estimate);
			mMeasured.Insert(at, (uint8)0);
		}
		Rebuild();
	}

	public void Remove(int at, int count)
	{
		for (int i = 0; (i < count) && (at < mHeights.Count); ++i)
		{
			mHeights.RemoveAt(at);
			mMeasured.RemoveAt(at);
		}
		Rebuild();
	}

	/// `count` rows from `first` now start at `to` (in the order after the move).
	public void Move(int first, int count, int to)
	{
		var to;
		let heights = scope List<float>();
		let measured = scope List<uint8>();
		for (int i = 0; (i < count) && (first < mHeights.Count); ++i)
		{
			heights.Add(mHeights[first]);
			measured.Add(mMeasured[first]);
			mHeights.RemoveAt(first);
			mMeasured.RemoveAt(first);
		}
		to = Math.Min(to, mHeights.Count);
		for (int i = 0; i < heights.Count; ++i)
		{
			mHeights.Insert(to + i, heights[i]);
			mMeasured.Insert(to + i, measured[i]);
		}
		Rebuild();
	}

	public int Count => mHeights.Count;
	public float At(int i) => ((i >= 0) && (i < mHeights.Count)) ? mHeights[i] : 0.0f;
	public bool IsMeasured(int i) => (i >= 0) && (i < mMeasured.Count) && (mMeasured[i] != 0);

	/// Sets a row's height (measured: it stays until Unmeasure); true when it changed.
	public bool Set(int i, float height, bool measured = true)
	{
		if ((i < 0) || (i >= mHeights.Count))
			return false;
		mMeasured[i] = measured ? 1 : 0;
		let delta = height - mHeights[i];
		if (delta == 0.0f)
			return false;
		mHeights[i] = height;
		for (int k = i + 1; k <= mHeights.Count; k += k & (~k + 1))
			mTree[k] += delta;
		return true;
	}

	public void Unmeasure(int i)
	{
		if ((i >= 0) && (i < mMeasured.Count))
			mMeasured[i] = 0;
	}

	/// Where row `i` starts: the sum of the heights before it.
	public float Top(int i)
	{
		float sum = 0.0f;
		for (int k = Math.Min(Math.Max(i, 0), mHeights.Count); k > 0; k -= k & (~k + 1))
			sum += mTree[k];
		return sum;
	}

	public float Total => Top(mHeights.Count);

	/// The row at offset `y` (the last row past the end; 0 when there are none).
	public int Find(float y)
	{
		var y;
		let n = mHeights.Count;
		if (n == 0)
			return 0;
		int pos = 0;
		for (int step = mHighBit; step > 0; step >>= 1)
		{
			if ((pos + step <= n) && (mTree[pos + step] <= y))
			{
				pos += step;
				y -= mTree[pos];
			}
		}
		return Math.Min(pos, n - 1);
	}

	private void Rebuild()
	{
		let n = mHeights.Count;
		mTree.Clear();
		for (int i = 0; i <= n; ++i)
			mTree.Add(0.0f);
		for (int i = 1; i <= n; ++i)
		{
			mTree[i] += mHeights[i - 1];
			let parent = i + (i & (~i + 1));
			if (parent <= n)
				mTree[parent] += mTree[i];
		}
		mHighBit = 1;
		while (mHighBit * 2 <= n)
			mHighBit *= 2;
	}
}

/// A native row factory: a row's content made once per pooled row of a type, and filled for
/// each item it shows. A class: it owns its callbacks.
class RowFactory
{
	/// The row type an item takes (null: one type); each type has its own pool.
	public delegate uint32(ModelIndex index) TypeOf ~ delete _;
	/// A row's content of a type; the row takes the reference it comes with.
	public delegate Node(uint32 type) Create ~ delete _;
	public delegate void(Node content, ModelIndex index) Bind ~ delete _;
}

/// One realised row: the view's container round a factory's content. It shows `:selected`
/// and draws the view's ::selection part under its content while selected.
class ItemRow : UIWidget
{
	internal ItemView mView; // its parent, which owns it
	internal Node mContent = null ~ _?.ReleaseRef();
	internal int32 mItem = -1;
	internal Sedulous.GUI.ItemId mItemId = NoItem;
	internal uint32 mType = 0;
	internal bool mSelected = false;
	internal bool mDirty = true; // its content shows stale data
	internal bool mTaken = false; // claimed in this realisation

	public this(ItemView view)
	{
		mView = view;
		Tag = view.[Friend]RowTag;
	}

	public int32 ItemIndex => mItem;
	public Sedulous.GUI.ItemId ItemId => mItemId;
	public uint32 RowType => mType;
	public Node Content => mContent;
	public bool IsSelected => mSelected;
	public override uint32 WidgetStates => mSelected ? WidgetStateSelected : WidgetStateNone;

	protected override void OnMouseDown(MouseEvent e)
	{
		mView.[Friend]RowPressed(this, e);
	}

	protected override void OnMouseClick(MouseEvent e)
	{
		mView.[Friend]RowClicked(this, e);
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		if (mSelected)
			mView.GetPartStyle("selection").Draw(ctx, LocalBounds, FilledBox(Color(0.18f, 0.37f, 0.62f, 1.0f), scope NodeBox()));
	}

	// Its content fills it; an editor lies over it where the view says.
	public override void OnLayout()
	{
		let @box = ContentBounds;
		if (mContent != null)
			mContent.Arrange(@box);
		let editor = mView.[Friend]mEditor;
		if ((editor != null) && (editor.Parent == this) && editor.Displayed)
			editor.Arrange(mView.[Friend]EditRect(this, mView.[Friend]mEditColumn));
	}

	protected override void OnTextStyleChange()
	{
		if (let content = mContent as UINode)
			ShareTextStyle(content);
	}

	internal void SetSelectedState(bool selected)
	{
		if (selected == mSelected)
			return;
		mSelected = selected;
		MarkStyleStateDirty(StateSelected);
		Invalidate();
	}
}

// A row made from a markup template: the template's tree, and the attributes it fills from
// the item it shows.
class TemplateRowContent : UIWidget
{
	private List<ItemBinding> mItemBindings = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		Tag = "templaterow";
	}

	public List<ItemBinding> Bindings => mItemBindings;

	// The template's root fills the row (or a grid's cell), inside its margin.
	public override void OnLayout()
	{
		let @box = ContentBounds;
		for (int i = 0; i < ChildCount; ++i)
		{
			let child = GetChildAt(i);
			let m = child.Margin;
			child.Arrange(.(@box.X + m.Left, @box.Y + m.Top, Math.Max(0.0f, @box.Width - m.TotalHorizontal),
				Math.Max(0.0f, @box.Height - m.TotalVertical)));
		}
	}
}

[GuiReflect, Scriptable]
abstract class ItemView : UIWidget, IModelClient
{
	private class Pool
	{
		public uint32 Type = 0;
		public List<ItemRow> Rows = new .() ~ { for (let row in _) row.ReleaseRef(); delete _; };
	}

	private class RowTemplate
	{
		public String Type = new .() ~ delete _;
		public String Markup = new .() ~ delete _;
	}

	// A selection of thousands: its first fifty have accessibility nodes.
	private const int cAccessSelectedCap = 50;

	private IModel mModel = null; // not owned (unless it is mOwnModel, or mListModel's)
	private ListModel mListModel = null ~ _?.ReleaseRef(); // a script's model it shows
	private StringListModel mOwnModel = null ~ delete _; // markup's `items`
	private RowFactory mFactory = new .() ~ delete _;
	private List<RowTemplate> mTemplates = new .() ~ DeleteContainerAndItems!(_);
	private String mRowTypeColumn = new .() ~ delete _;
	private Observable mSelectionChanged = new .() ~ delete _; // what bindings reading the selection follow
	private List<Sedulous.GUI.ItemId> mDragIds = new .() ~ delete _; // the rows of the drag going from here
	private int32 mDeferredItem = -1; // a pressed row of a multi-selection, selected alone on click
	private bool mDropOver = false; // a drop would land here now
	private int32 mDropItem = -1;
	private Sedulous.GUI.DropPlace mDropPlace = .After;
	private ModelDrop mLastDrop = .(); // the drop the last query found
	private RowHeights mHeights = new .() ~ delete _;
	private List<ItemRow> mLive = new .() ~ { for (let row in _) row.ReleaseRef(); delete _; }; // realised, in item order
	// Accessibility: each item's key, and back; this view's key; what each node said.
	private Dictionary<Sedulous.GUI.ItemId, uint32> mAccessKeys = new .() ~ delete _;
	private Dictionary<uint32, Sedulous.GUI.ItemId> mAccessItems = new .() ~ delete _;
	private uint32 mNextAccessKey = 1;
	private uint32 mAccessViewKey = 0;
	private Dictionary<uint64, uint64> mAccessItemsSent = new .() ~ delete _;
	private List<Pool> mPools = new .() ~ DeleteContainerAndItems!(_); // released rows, by type
	private HashSet<Sedulous.GUI.ItemId> mSelected = new .() ~ delete _;
	private Sedulous.GUI.ItemId mCurrent = NoItem; // where the keyboard is
	private Sedulous.GUI.ItemId mAnchorSelection = NoItem; // where a Shift range starts
	private Sedulous.GUI.SelectionMode mSelectionMode = .Single;
	private delegate void(ModelIndex index) mOnSelection ~ delete _;
	private delegate void(ModelIndex index) mOnActivated ~ delete _;
	private delegate void(DragPayload payload, Span<Sedulous.GUI.ItemId> ids) mOnDragPayload ~ delete _; // the owner's payload
	private float mRowHeight = 24.0f;
	private float mEstimate = 24.0f;
	/// FitsRows.
	private bool mFitsRows = false;
	private ItemLayout mLayout = .List;
	private Float2 mCellSize = .(96.0f, 96.0f);
	private int32 mScrollAnchor = 0;
	private float mScrollAnchorDelta = 0.0f;
	private bool mRealizing = false;
	// Type-ahead.
	private TypeAheadSearch mTypeAhead = new .() ~ delete _;
	// Editing.
	private TextField mEditor = null ~ _?.ReleaseRef();
	private bool mEditing = false;
	private Sedulous.GUI.ItemId mEditId = NoItem;
	private int32 mEditColumn = 0;
	private delegate bool(ModelIndex index) mOnEditBegin ~ delete _;
	private delegate bool(ModelIndex index, StringView text) mOnEditCommit ~ delete _;
	private delegate void(ModelIndex index) mOnEditCancel ~ delete _;
	// What ItemsText last wrote.
	private String mItemsText = new .() ~ delete _;

	public this()
	{
		TabFocusable = true;
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) => { s.OverflowY = .Auto; });
		}
		ScrollStep = mRowHeight;
	}

	public ~this()
	{
		if (mModel != null)
			mModel.RemoveClient(this);
	}

	// === Model ===

	/// The model it shows (borrowed: it outlives the view, or is replaced first).
	public IModel Model
	{
		get => mModel;
		set
		{
			if (mModel != null)
				mModel.RemoveClient(this);
			mModel = value;
			if (mModel != null)
				mModel.AddClient(this);
			mSelected.Clear();
			mCurrent = NoItem;
			mAnchorSelection = NoItem;
			ResetScrollAnchor();
			OnModelReset(); // its items from the new model first: the scroll's realising binds them
			ScrollOffset = .(0.0f, 0.0f);
		}
	}

	// === Rows ===

	/// Rows from a native factory instead of the view's own (the pools start again). OWNERSHIP of
	/// `factory` transfers; null: the view's own rows.
	public void SetRowFactory(RowFactory factory)
	{
		delete mFactory;
		mFactory = (factory != null) ? factory : new RowFactory();
		DropRows();
		RequestLayout();
	}

	/// A markup template for rows (`type` names one of several, picked by the
	/// row-type-column's text; empty: the default).
	public override bool SetMarkupTemplate(StringView type, StringView markup)
	{
		let entry = new RowTemplate();
		entry.Type.Set(type);
		entry.Markup.Set(markup);
		mTemplates.Add(entry);
		UseTemplates();
		return true;
	}

	/// The column whose text picks a row's template (by its `type`).
	[GuiProperty("row-type-column"), Scriptable]
	public StringView RowTypeColumn
	{
		get => mRowTypeColumn;
		set
		{
			mRowTypeColumn.Set(value);
			if (!mTemplates.IsEmpty)
				UseTemplates();
		}
	}

	/// Shows a script's list model, keeping it alive while it does (a reference held). `SetModel`
	/// to a script.
	[Scriptable, ScriptName("SetModel")]
	public void SetListModel(ListModel model)
	{
		let was = mListModel;
		if (model != null)
			model.AddRef();
		mListModel = model;
		Model = (mListModel != null) ? mListModel.Model : null;
		if (was != null)
			was.ReleaseRef(); // let go once the view no longer shows its model
	}

	/// A model of its own from text, '|' between the items (markup's `items`).
	[GuiProperty("items"), Scriptable]
	public StringView ItemsText
	{
		get
		{
			mItemsText.Clear();
			if (mOwnModel != null)
			{
				for (int i = 0; i < mOwnModel.RowCount(); ++i)
				{
					if (i > 0)
						mItemsText.Append('|');
					mItemsText.Append(mOwnModel.ItemAt(i));
				}
			}
			return mItemsText;
		}
		set
		{
			if (mOwnModel == null)
				mOwnModel = new StringListModel();
			let text = scope String(value); // the items are views into it
			let items = scope List<StringView>();
			SplitItems(text, items);
			mOwnModel.SetItems(items);
			if (mModel != mOwnModel)
				Model = mOwnModel;
		}
	}

	/// "single" or "multi" (markup's `selection-mode`).
	[GuiProperty("selection-mode"), Scriptable]
	public StringView SelectionModeName
	{
		get => (mSelectionMode == .Multi) ? "multi" : "single";
		set => mSelectionMode = (ParseUtil.Trim(value) == "multi") ? Sedulous.GUI.SelectionMode.Multi : Sedulous.GUI.SelectionMode.Single;
	}

	/// Every row this tall (0: each measured, estimated until it is).
	[GuiProperty("row-height"), Scriptable]
	public float RowHeight
	{
		get => mRowHeight;
		set
		{
			mRowHeight = Math.Max(0.0f, value);
			ScrollStep = (mRowHeight > 0.0f) ? mRowHeight : mEstimate;
			mHeights.Reset(ItemCount(), RowEstimate);
			RequestLayout();
		}
	}

	/// Whether its natural height is its rows' (a short list among other content, as an import's
	/// settings above what the file makes). Off, as by default, it measures as a box of its pooled
	/// rows does and takes the height its layout gives it, which a long list wants.
	public bool FitsRows
	{
		get => mFitsRows;
		set
		{
			if (value == mFitsRows)
				return;
			mFitsRows = value;
			RequestLayout();
		}
	}

	/// What an unmeasured row is taken to be until it is realised.
	[GuiProperty("estimated-row-height"), Scriptable]
	public float EstimatedRowHeight
	{
		get => mEstimate;
		set
		{
			mEstimate = Math.Max(1.0f, value);
			if (mRowHeight <= 0.0f)
				mHeights.Reset(ItemCount(), mEstimate);
			RequestLayout();
		}
	}

	/// The rows realised now (in view, and one past each edge).
	public int VisibleRowCount => mLive.Count;

	/// The realised row showing `item` (null when it is not in view).
	public ItemRow RowForItem(int32 item)
	{
		for (let row in mLive)
		{
			if (row.mItem == item)
				return row;
		}
		return null;
	}

	/// The item under a point in world space (-1: none).
	public int32 ItemAt(Float2 world)
	{
		for (let row in mLive)
		{
			if (row.ScreenBounds.Contains(world))
				return row.mItem;
		}
		return -1;
	}

	/// Where an item starts in the content and how tall it is (estimated until measured).
	public Rect ItemBounds(int32 item)
	{
		let @box = ContentBounds;
		let i = Math.Max(0, item);
		if (mLayout == .Grid)
		{
			let across = GridColumns(@box.Width);
			let w = @box.Width / (float)across;
			return CellBounds(@box, i, across, w, @box.Y + ContentTopInset + ItemTop(i), ItemHeight(i));
		}
		let width = RowWidth(@box.Width);
		return .(RowLeft(@box, width), @box.Y + ContentTopInset + ItemTop(i), width, ItemHeight(i));
	}

	/// Where a row `width` wide starts: at the box's left, or, scrolling from the right (right to
	/// left, a table wider than its view), at its right less the width, overflowing leftward.
	public float RowLeft(Rect @box, float width) => ScrollsFromRight ? @box.Right - width : @box.X;

	/// A grid's cell: across its line from the inline start.
	public Rect CellBounds(Rect @box, int32 item, int32 across, float width, float y, float height)
	{
		return Rect.MirroredIn(.(@box.X + (float)(item % across) * width, y, width, height), @box, IsRightToLeft);
	}

	// === Grid ===

	/// Lists rows down, or lays cells out in a grid.
	public ItemLayout LayoutMode
	{
		get => mLayout;
		set
		{
			mLayout = value;
			ForEachRow(scope (row) => { row.mDirty = true; });
			RequestLayout();
		}
	}

	/// "list" or "grid" (markup's `layout`).
	[GuiProperty("layout"), Scriptable]
	public StringView LayoutModeName
	{
		get => (mLayout == .Grid) ? "grid" : "list";
		set => LayoutMode = (ParseUtil.Trim(value) == "grid") ? ItemLayout.Grid : ItemLayout.List;
	}

	/// A grid cell's least width (as many fit across as can, stretched to fill) and height.
	[GuiProperty("cell-width"), Scriptable]
	public float CellWidth
	{
		get => mCellSize.X;
		set
		{
			mCellSize.X = Math.Max(1.0f, value);
			RequestLayout();
		}
	}

	[GuiProperty("cell-height"), Scriptable]
	public float CellHeight
	{
		get => mCellSize.Y;
		set
		{
			mCellSize.Y = Math.Max(1.0f, value);
			RequestLayout();
		}
	}

	/// How many cells a grid lays across (1 for a list).
	public int32 ColumnsAcross => GridColumns(ContentBounds.Width);

	/// Scrolls so `item` shows (Nearest: the least move).
	public void ScrollToItem(int32 item, ScrollAlign align = .Nearest)
	{
		if ((item < 0) || (item >= (int32)ItemCount()))
			return;
		let @box = ContentBounds;
		let view = Math.Max(0.0f, @box.Height - ContentTopInset);
		let top = ItemTop(item);
		let bottom = top + ItemHeight(item);
		let now = ScrollTarget.Y;
		var to = now;
		switch (align)
		{
		case .Start: to = top;
		case .End: to = bottom - view;
		case .Center: to = (top + bottom - view) * 0.5f;
		case .Nearest:
			if (top < now)
				to = top;
			else if (bottom > now + view)
				to = Math.Min(top, bottom - view);
		}
		// Its offset is known now, so the extent is brought up to date first (the range).
		SetScrollExtent(.(ContentExtent.X, ContentTopInset + ContentHeight));
		ScrollTo(.(ScrollTarget.X, to));
		if (!mRealizing)
			Realize();
	}

	// === Drag and drop ===
	// (Rows drag the selection as the view's `drag-type`; empty, they do not drag.)

	/// The ids of the rows of the drag going from here (in their order).
	public List<Sedulous.GUI.ItemId> DraggedIds => mDragIds;
	/// Where a drop would land now (the item, -1 for the end; the place), while one is over it.
	public int32 DropItem => mDropOver ? mDropItem : -1;
	public Sedulous.GUI.DropPlace DropPlace => mDropPlace;
	public bool IsDropOver => mDropOver;

	// === Appearance ===

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("selection");
		outParts.Add("drop-indicator");
	}

	// Its rows draw the selection in ::selection's style.
	protected override void OnPartStyleChange(StringView part)
	{
		if (part == "selection")
			ForEachRow(scope (row) => { row.Invalidate(); });
	}

	// === Selection ===

	public Sedulous.GUI.SelectionMode SelectionMode
	{
		get => mSelectionMode;
		set => mSelectionMode = value;
	}

	/// The user changed the selection (code's changes report nothing); the index is the current
	/// item's. OWNERSHIP of `callback` transfers.
	public void SetOnSelectionChanged(delegate void(ModelIndex index) callback)
	{
		delete mOnSelection;
		mOnSelection = callback;
	}

	/// A row was activated: a double-click, Return or the pad's South. OWNERSHIP of `callback`
	/// transfers.
	public void SetOnActivated(delegate void(ModelIndex index) callback)
	{
		delete mOnActivated;
		mOnActivated = callback;
	}

	/// What a drag of its items carries, the owner's say: told the payload as the view filled it
	/// (its own type, the view and its ids, for a drop within it) and the dragged items' ids in
	/// item order, it may put what it carries instead (an asset browser's assets). OWNERSHIP of
	/// `callback` transfers.
	public void SetOnDragPayload(delegate void(DragPayload payload, Span<Sedulous.GUI.ItemId> ids) callback)
	{
		delete mOnDragPayload;
		mOnDragPayload = callback;
	}

	public int SelectionCount => mSelected.Count;
	public bool IsIdSelected(Sedulous.GUI.ItemId id) => mSelected.Contains(id);
	public bool IsItemSelected(int32 item) => (item >= 0) && IsIdSelected(ItemIdAt(item));

	/// The selected ids, added to `outIds`.
	public void GetSelectedIds(List<Sedulous.GUI.ItemId> outIds)
	{
		for (let id in mSelected)
			outIds.Add(id);
	}

	/// The current item (where the keyboard is) when it is selected, else -1; read, it is a read a
	/// binding records. Set from code it selects that item alone (scrolled into view; no events);
	/// -1 clears.
	[GuiProperty("selected", .TwoWay), Scriptable]
	public int32 SelectedItem
	{
		get
		{
			mSelectionChanged.Track();
			let item = ItemOfId(mCurrent);
			return ((item >= 0) && IsIdSelected(mCurrent)) ? item : -1;
		}
		set
		{
			if ((value < 0) || (value >= (int32)ItemCount()))
			{
				ClearSelection();
				return;
			}
			SelectOnly(value);
			ScrollToItem(value);
		}
	}

	/// The item the keyboard is on (-1: none).
	public int32 CurrentItem => ItemOfId(mCurrent);

	public ModelIndex SelectedIndex
	{
		get
		{
			let item = SelectedItem;
			return (item >= 0) ? ItemToModelIndex(item) : ModelIndex();
		}
	}

	// === Accessibility: its items as nodes of the accessibility tree, which the GUI builds
	// (Scene/AccessibilityImpl.bf). Not every item has one: the rows made and a page of items each
	// side, the current item and the selected ones (each node says its place among all), so a list
	// of a hundred thousand sends a few dozen. ===

	public int GetItemCount() => ItemCount();
	public void GetItemText(int32 item, String outText) => TypeAheadText(item, outText);
	public ModelIndex GetItemIndex(int32 item) => ItemToModelIndex(item);

	/// The items that have nodes, in item order, added to `outItems`.
	public void GetAccessItems(List<int32> outItems)
	{
		let count = (int32)ItemCount();
		if (count <= 0)
			return;
		int32 first = count;
		int32 last = -1;
		for (let row in mLive)
		{
			if (row.mItem >= 0)
			{
				first = Math.Min(first, row.mItem);
				last = Math.Max(last, row.mItem);
			}
		}
		if (last < 0)
		{
			first = Math.Max(0, CurrentItem);
			last = first;
		}
		let page = Math.Max(1, last - first + 1);
		let wanted = scope HashSet<int32>();
		for (int32 i = Math.Max(0, first - page); i <= Math.Min(count - 1, last + page); ++i)
			wanted.Add(i);
		let current = CurrentItem;
		if (current >= 0)
			wanted.Add(current);
		int selected = 0;
		for (let id in mSelected)
		{
			let item = ItemOfId(id);
			if ((item >= 0) && (selected++ < cAccessSelectedCap))
				wanted.Add(item);
		}
		for (let item in wanted)
			outItems.Add(item);
		outItems.Sort(scope (a, b) => a <=> b);
	}

	/// An item's key among this view's nodes: it follows the item as rows recycle, scroll and
	/// move, made the first time the item is asked for. The GUI joins it to the view's own.
	public uint32 GetAccessKeyOfItem(int32 item)
	{
		let id = ItemIdAt(item);
		if (mAccessKeys.TryGetValue(id, let found))
			return found;
		let key = mNextAccessKey++;
		mAccessKeys[id] = key;
		mAccessItems[key] = id;
		return key;
	}

	/// The item a key names now (-1: gone).
	public int32 GetItemOfAccessKey(uint32 key) => mAccessItems.TryGetValue(key, let id) ? ItemOfId(id) : -1;

	/// This view's key among the GUI's item views (0 until the GUI gives it one).
	public uint32 AccessViewKey
	{
		get => mAccessViewKey;
		set => mAccessViewKey = value;
	}

	/// What each item's node said last (by its id), so a node unchanged is not sent again.
	public Dictionary<uint64, uint64> AccessItemsSent => mAccessItemsSent;

	/// A screen reader moves to an item: as the keyboard would, selected and scrolled to.
	public void FocusItemFromAccess(int32 item)
	{
		RequestFocus();
		SelectByUser(item, 0);
		ScrollToItem(item);
	}

	public void ActivateItemFromAccess(int32 item)
	{
		ActivateItem(item);
	}

	/// Selects the items with `ids` from code (one alone without multi-selection), the first the
	/// current one and scrolled into view; no events. An id not shown now (under a closed node)
	/// stays selected for when it is. None clears.
	public void SetSelectedIds(Span<Sedulous.GUI.ItemId> ids)
	{
		mSelected.Clear();
		mAnchorSelection = NoItem;
		for (let id in ids)
		{
			if ((mSelectionMode != .Multi) && !mSelected.IsEmpty)
				break;
			mSelected.Add(id);
		}
		if (!ids.IsEmpty)
		{
			mCurrent = ids[0];
			mAnchorSelection = ids[0];
		}
		RefreshSelectionStates();
		let item = ids.IsEmpty ? (int32)-1 : (int32)ItemOfId(ids[0]);
		if (item >= 0)
			ScrollToItem(item);
	}

	[Scriptable]
	public void ClearSelection()
	{
		mSelected.Clear();
		mAnchorSelection = NoItem;
		RefreshSelectionStates();
	}

	/// Every item (multi-selection), as Ctrl+A does.
	[Scriptable]
	public void SelectAll()
	{
		if (mSelectionMode != .Multi)
			return;
		for (int32 i = 0; i < (int32)ItemCount(); ++i)
		{
			if (IsItemSelectable(i))
				mSelected.Add(ItemIdAt(i));
		}
		RefreshSelectionStates();
	}

	/// Whether a user may select the item (its model's say; a section header may not).
	public bool IsItemSelectable(int32 item) =>
		(item >= 0) && (item < (int32)ItemCount()) && ((mModel == null) || mModel.IsSelectable(ItemToModelIndex(item)));

	// === Editing ===

	/// Edits `item` in place (`column` for a table), if its model cell is editable and the begin
	/// hook allows; false otherwise.
	[Scriptable]
	public bool BeginEdit(int32 item, int32 column = 0)
	{
		if ((mModel == null) || (item < 0) || (item >= (int32)ItemCount()))
			return false;
		var index = ItemToModelIndex(item);
		index.Column = column;
		if (!mModel.IsEditable(index) || ((mOnEditBegin != null) && !mOnEditBegin(index)))
			return false;
		if (mEditing && !EndEdit(true))
			return false;
		ScrollToItem(item);
		Realize();
		let row = RowForItem(item);
		if (row == null)
			return false;
		if (mEditor == null)
		{
			mEditor = new TextField();
			mEditor.AddClass("editor");
			mEditor.SetOnSubmit(new (text) => { EndEdit(true); });
			mEditor.AddEventListener(.FocusLost, new (e) =>
				{
					// Focus went elsewhere: committed if it may be, else put back.
					if (mEditing && !EndEdit(true))
						EndEdit(false);
				});
		}
		mEditing = true;
		mEditId = ItemIdAt(item);
		mEditColumn = column;
		row.AddChild(mEditor);
		ShareTextStyle(mEditor);
		mEditor.RemoveClass("invalid");
		let text = scope String();
		mModel.Data(index).ToString(text);
		mEditor.Text = text;
		mEditor.Displayed = true;
		mEditor.Model.SelectAll();
		mEditor.Arrange(EditRect(row, column));
		mEditor.RequestFocus();
		return true;
	}

	/// Ends an edit: commits (if the commit hook and the model take it) or cancels. False when the
	/// value was refused and it is still editing.
	public bool EndEdit(bool commit)
	{
		if (!mEditing)
			return true;
		let item = ItemOfId(mEditId);
		var index = (item >= 0) ? ItemToModelIndex(item) : ModelIndex();
		index.Column = mEditColumn;
		if (commit && index.IsValid)
		{
			let text = scope String(mEditor.Text);
			let taken = ((mOnEditCommit == null) || mOnEditCommit(index, text)) && mModel.SetData(index, Sedulous.GUI.Variant(text));
			if (!taken)
			{
				mEditor.AddClass("invalid");
				return false;
			}
		}
		else if (!commit && (mOnEditCancel != null) && index.IsValid)
			mOnEditCancel(index);
		mEditing = false;
		mEditId = NoItem;
		let hadFocus = mEditor.IsFocused;
		mEditor.Displayed = false;
		if (hadFocus)
			RequestFocus(); // the view keeps the focus the editor had
		return true;
	}

	public bool IsEditing => mEditing;
	public TextField Editor => mEditor;

	/// May refuse to start an edit. OWNERSHIP of `hook` transfers.
	public void SetOnEditBegin(delegate bool(ModelIndex index) hook)
	{
		delete mOnEditBegin;
		mOnEditBegin = hook;
	}

	/// May refuse a value (false: it keeps editing, marked `.invalid`); otherwise the model's
	/// SetData decides. OWNERSHIP of `hook` transfers.
	public void SetOnEditCommit(delegate bool(ModelIndex index, StringView text) hook)
	{
		delete mOnEditCommit;
		mOnEditCommit = hook;
	}

	/// OWNERSHIP of `hook` transfers.
	public void SetOnEditCancel(delegate void(ModelIndex index) hook)
	{
		delete mOnEditCancel;
		mOnEditCancel = hook;
	}

	// === IModelClient ===

	public void OnModelReset()
	{
		OnModelChanged();
		if (mEditing && (ItemOfId(mEditId) < 0))
			EndEdit(false);
		mHeights.Reset(ItemCount(), RowEstimate);
		ForEachRow(scope (row) => { row.mDirty = true; });
		PruneSelection();
		ClampScrollAnchor();
		RequestLayout();
	}

	public void OnRowsInserted(ModelIndex parent, int32 first, int32 count)
	{
		if (parent.IsValid || !IsFlat)
		{
			OnModelReset();
			return;
		}
		mHeights.Insert(first, count, RowEstimate);
		if (first <= mScrollAnchor)
			mScrollAnchor += count; // what is in view stays in view
		RequestLayout();
	}

	public void OnRowsRemoved(ModelIndex parent, int32 first, int32 count)
	{
		if (parent.IsValid || !IsFlat)
		{
			OnModelReset();
			return;
		}
		mHeights.Remove(first, count);
		if (mEditing && (ItemOfId(mEditId) < 0))
			EndEdit(false);
		if (mScrollAnchor >= first + count)
			mScrollAnchor -= count;
		else if (mScrollAnchor >= first)
		{
			mScrollAnchor = first; // its row went: the one now in its place, from its top
			mScrollAnchorDelta = 0.0f;
		}
		PruneSelection();
		ClampScrollAnchor();
		RequestLayout();
	}

	public void OnRowsMoved(ModelIndex parent, int32 first, int32 count, int32 to)
	{
		if (parent.IsValid || !IsFlat)
		{
			OnModelReset();
			return;
		}
		mHeights.Move(first, count, to);
		RequestLayout();
	}

	public void OnRowsChanged(ModelIndex parent, int32 first, int32 count)
	{
		if (parent.IsValid || !IsFlat)
		{
			OnModelReset();
			return;
		}
		for (int32 i = first; i < first + count; ++i)
		{
			mHeights.Unmeasure(i);
			let row = RowForItem(i);
			if (row != null)
				row.mDirty = true;
		}
		RequestLayout();
	}

	// === What a subclass says ===

	protected virtual int ItemCount() => (mModel != null) ? mModel.RowCount() : 0;
	protected virtual ModelIndex ItemToModelIndex(int32 item) => (mModel != null) ? mModel.Index(item) : ModelIndex();
	protected virtual Sedulous.GUI.ItemId ItemIdAt(int32 item) => ((mModel != null) && (item >= 0)) ? mModel.IdOf(ItemToModelIndex(item)) : NoItem;

	protected virtual int32 ItemOfId(Sedulous.GUI.ItemId id)
	{
		if ((mModel == null) || (id == NoItem))
			return -1;
		let index = mModel.IndexOfId(id);
		return index.IsValid ? index.Row : -1;
	}

	/// Its items are the model's top-level rows (a tree's are not: it resets on every range).
	protected virtual bool IsFlat => true;
	/// A default row's content (when no factory is set); the row takes the reference it comes
	/// with.
	protected abstract Node CreateContent(uint32 type);
	/// Fills a default row's content for the item it shows.
	protected abstract void BindContent(Node content, int32 item, ModelIndex index);
	/// Room above the rows (a table's header).
	protected virtual float ContentTopInset => 0.0f;

	/// With FitsRows, as tall as its rows (and what is above them); otherwise as any box.
	public override Float2 MeasureContent(Float2 available)
	{
		let measured = base.MeasureContent(available);
		return mFitsRows ? Float2(measured.X, ContentTopInset + ContentHeight) : measured;
	}
	/// How wide a row is in a content box `width` wide (a table's columns may be wider).
	protected virtual float RowWidth(float width) => width;
	/// The model was set or reset (a tree flattens, a table rebuilds its header).
	protected virtual void OnModelChanged() { }
	/// After the rows are placed (a table places its header).
	protected virtual void OnLayoutDecorations() { }
	/// A key before the view's own (a tree's Left and Right); true when used.
	protected virtual bool OnExtraKey(KeyCode key, uint32 modifiers) => false;
	/// Where an editor goes over a row (in the row's space).
	protected virtual Rect EditRect(ItemRow row, int32 column) => row.ContentBounds;

	/// The text type-ahead matches (the display text of the item's first column), appended.
	protected virtual void TypeAheadText(int32 item, String outText)
	{
		if (mModel != null)
			mModel.Data(ItemToModelIndex(item)).ToString(outText);
	}

	/// Its rows' tag (`listviewrow`, `treerow`, ...).
	protected virtual StringView RowTag => "itemrow";

	// === Helpers for a subclass ===

	protected void ForEachRow(delegate void(ItemRow row) visit)
	{
		for (let row in mLive)
			visit(row);
		for (let pool in mPools)
		{
			for (let row in pool.Rows)
				visit(row);
		}
	}

	protected List<ItemRow> LiveRows => mLive;

	/// The items changed in a way only the subclass knows (a tree opened a node): heights start
	/// again, rows are refilled.
	protected void ItemsChanged()
	{
		mHeights.Reset(ItemCount(), RowEstimate);
		ForEachRow(scope (row) => { row.mDirty = true; });
		PruneSelection();
		ClampScrollAnchor();
		RequestLayout();
		if (!mRealizing && (Size.Y > 0.0f))
			Realize();
	}

	/// Selects as a click does, with its modifiers (a subclass's own rows call it).
	protected void SelectByUser(int32 item, uint32 modifiers)
	{
		if (!IsItemSelectable(item))
			return;
		let ctrl = (modifiers & KeyModCtrl) != 0;
		let shift = (modifiers & KeyModShift) != 0;
		if ((mSelectionMode == .Multi) && shift && (mAnchorSelection != NoItem))
			SelectRange(item);
		else if ((mSelectionMode == .Multi) && ctrl)
			ToggleSelected(item);
		else
			SelectOnly(item);
		NotifySelectionByUser();
	}

	public override void OnLayout()
	{
		Realize();
		OnLayoutDecorations();
	}

	public override void OnScrollChange()
	{
		if (mRealizing)
			return;
		UpdateScrollAnchor();
		if (Size.Y <= 0.0f)
			return;
		Realize(); // laid out: the rows now in view, at once (a press lands on them)
		OnLayoutDecorations();
	}

	protected override void OnTextStyleChange()
	{
		ForEachRow(scope (row) => { ShareTextStyle(row); });
		if (mRowHeight <= 0.0f)
			mHeights.Reset(ItemCount(), RowEstimate); // a new font measures anew
		RequestLayout();
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let key = (KeyCode)e.KeyCode;
		if (mEditing && (e.Target == mEditor))
		{
			if (key == .Escape)
			{
				EndEdit(false);
				e.Handled = true;
			}
			return;
		}
		if (e.Target != this)
			return;
		if (OnExtraKey(key, e.Modifiers))
		{
			e.Handled = true;
			return;
		}
		let items = (int32)ItemCount();
		if (items == 0)
			return;
		let shift = (e.Modifiers & KeyModShift) != 0;
		let ctrl = (e.Modifiers & KeyModCtrl) != 0;
		if ((key == .F2) && (e.Modifiers == 0))
		{
			if ((CurrentItem >= 0) && BeginEdit(CurrentItem))
				e.Handled = true;
			return;
		}
		if ((key == .A) && ctrl && (mSelectionMode == .Multi))
		{
			SelectAll();
			NotifySelectionByUser();
			e.Handled = true;
			return;
		}
		if ((key == .Space) && ctrl && (mSelectionMode == .Multi) && (CurrentItem >= 0))
		{
			ToggleSelected(CurrentItem);
			NotifySelectionByUser();
			e.Handled = true;
			return;
		}
		// A key that types is its type-ahead's: the text it types arrives next, through the
		// keyboard layout and an IME, and no binding of the bare key takes it.
		if (((e.Modifiers & ~KeyModShift) == 0) && KeyTypesText(key) && (ItemCount() > 0))
		{
			e.Handled = true;
			return;
		}
		let current = CurrentItem;
		// A grid's line is a step of `across` items; a page the lines (rows) that fit.
		let across = Across;
		let rowH = Math.Max(1.0f, ItemHeight(Math.Max(0, current)));
		let page = Math.Max(1, (int32)((ContentBounds.Height - ContentTopInset) / rowH) - 1) * across;
		let grid = mLayout == .Grid;
		var target = current;
		switch (key)
		{
		case .Up: target = (current < 0) ? 0 : ((current - across >= 0) ? current - across : current);
		case .Down: target = (current < 0) ? 0 : ((current + across < items) ? current + across : current);
		case .Left, .Right:
			// Along a grid's rows as they run: toward the inline end is the next item.
			if (!grid)
				return;
			target = (InlineStep(key) < 0) ? ((current <= 0) ? 0 : current - 1) : ((current < 0) ? 0 : Math.Min(items - 1, current + 1));
		case .Home: target = 0;
		case .End: target = items - 1;
		case .PageUp: target = Math.Max(0, Math.Max(0, current) - page);
		case .PageDown: target = Math.Min(items - 1, Math.Max(0, current) + page);
		default: return;
		}
		// Past what may not be selected (a section header), on in the key's direction; none there
		// keeps where it is.
		if (!IsItemSelectable(target))
		{
			let back = (key == .Up) || (key == .PageUp) || (key == .End) || (((key == .Left) || (key == .Right)) && (InlineStep(key) < 0));
			let step = ((key == .Up) || (key == .Down)) ? across : 1;
			var next = target;
			while ((next >= 0) && (next < items) && !IsItemSelectable(next))
				next += back ? -step : step;
			target = ((next >= 0) && (next < items)) ? next : current;
		}
		// An arrow at the view's edge is given back (focus moves on).
		let arrow = (key == .Up) || (key == .Down) || (key == .Left) || (key == .Right);
		if (arrow && (target == current) && IsItemSelected(current))
			return;
		e.Handled = true;
		let dispatcher = EventDispatcher;
		if ((dispatcher != null) && dispatcher.IsKeyboardDrag)
		{
			mCurrent = ItemIdAt(target); // dragging from the keys: the keyboard moves, the selection stays
			Invalidate();
		}
		else if (ctrl && (mSelectionMode == .Multi))
			mCurrent = ItemIdAt(target); // Ctrl moves the keyboard alone (Ctrl+Space picks)
		else if (shift && (mSelectionMode == .Multi))
		{
			SelectRange(target);
			NotifySelectionByUser();
		}
		else
		{
			SelectOnly(target);
			NotifySelectionByUser();
		}
		ScrollToItem(target);
	}

	// Typed text is its type-ahead: it asks for text input while it has items.
	public override bool WantsTextInput => IsTreeEnabled && (ItemCount() > 0);

	protected override void OnTextInput(TextInputEvent e)
	{
		if ((e.Target == this) && TypeAhead(e.Text))
			e.Handled = true;
	}

	protected override bool OnActivate()
	{
		let item = CurrentItem;
		if (item < 0)
			return false;
		ActivateItem(item);
		return true;
	}

	// A context menu asked for over a row selects it first (unless it is selected already), and
	// goes on (to whoever opens a menu: its own `context-menu`, or one above).
	protected override void OnContextMenu(MouseEvent e)
	{
		let item = ItemAt(e.Position);
		if ((item >= 0) && !IsItemSelected(item))
			SelectByUser(item, 0);
		base.OnContextMenu(e);
	}

	// --- Drag and drop ---

	protected override bool OnDragRequested(DragRequest request)
	{
		if (DragType.IsEmpty || (mModel == null))
			return false;
		let item = request.FromKeyboard ? CurrentItem : ItemAt(ConvertToWorldSpace(request.Press));
		if (item < 0)
			return false;
		mDeferredItem = -1;
		if (!IsItemSelected(item))
		{
			SelectOnly(item);
			NotifySelectionByUser();
		}
		// The selection in item order (one row: no scan).
		mDragIds.Clear();
		if (mSelected.Count == 1)
			mDragIds.Add(ItemIdAt(item));
		else
		{
			for (int32 i = 0; i < (int32)ItemCount(); ++i)
			{
				if (IsItemSelected(i))
					mDragIds.Add(ItemIdAt(i));
			}
		}
		request.Payload.Type.Set(DragType);
		request.Payload.Value.Dispose();
		request.Payload.Value = System.Variant.Create(TakeElementRef()); // the view, weakly: a target reads its ids
		request.Payload.Label.Clear();
		if (mDragIds.Count == 1)
			TypeAheadText(item, request.Payload.Label);
		else
			request.Payload.Label.AppendF("{} items", mDragIds.Count);
		request.Payload.Allowed = DropEffectsCopy | DropEffectsMove;
		if (mOnDragPayload != null)
			mOnDragPayload(request.Payload, (Span<Sedulous.GUI.ItemId>)mDragIds);
		return true;
	}

	protected override void OnDragQuery(DropQuery query)
	{
		if (mModel == null)
			return;
		let reason = scope String();
		let drop = DropAt(query, var effect, reason);
		if (effect == .None)
		{
			SetDropIndicator(false, -1, .After);
			if (!reason.IsEmpty)
				query.Refuse(reason);
			return;
		}
		query.Accept(effect);
		query.Effect = effect; // the model's (a list takes text as a copy)
		query.Reason.Set(reason);
		let item = drop.Index.IsValid ? ItemOfId(mModel.IdOf(drop.Index)) : -1;
		query.Place = (int32)drop.Place;
		SetDropIndicator(true, item, drop.Place);
		mLastDrop = drop; // what a drop now does (the release asks once more, here)
	}

	protected override void OnDragLeave(DragEvent e)
	{
		SetDropIndicator(false, -1, .After);
	}

	// The drop as the last query found it (the release asked again where it landed).
	protected override void OnDrop(DragEvent e)
	{
		if ((mModel == null) || !mDropOver)
			return;
		var drop = mLastDrop;
		drop.Effect = e.Effect;
		SetDropIndicator(false, -1, .After);
		mModel.Drop(drop);
	}

	protected override void OnDragEnd(DragResult result)
	{
		// Moved to another model: the rows leave this one (one moved within it moved already).
		if ((result.Effect == .Move) && (mModel != null) && !mDragIds.IsEmpty)
		{
			let target = result.Target as ItemView;
			if ((target == null) || (target.Model != mModel))
				mModel.RemoveIds((Span<Sedulous.GUI.ItemId>)mDragIds);
		}
		mDragIds.Clear();
	}

	// The insertion line before or after a row (across a grid's cell edge), or an outline round
	// the row a drop goes onto.
	protected override void OnDrawAbove(DrawContext ctx)
	{
		if (!mDropOver)
			return;
		let part = GetPartStyle("drop-indicator");
		let color = part.HasBackground ? part.Box.BackgroundColor : Color(0.31f, 0.61f, 1.0f, 1.0f);
		let @box = ContentBounds;
		Rect row;
		if (mDropItem < 0)
		{
			let count = ItemCount();
			row = (count > 0) ? ItemBounds((int32)count - 1) : Rect(@box.X, @box.Y + ContentTopInset, @box.Width, 0.0f);
		}
		else
			row = ItemBounds(mDropItem);
		row.X -= ScrollOffset.X;
		row.Y -= ScrollOffset.Y;
		ctx.PushClip(@box);
		let across = mLayout == .Grid;
		if ((mDropPlace == .On) && (mDropItem >= 0))
		{
			let pb = scope PathBuilder();
			pb.MoveTo(row.X + 1.0f, row.Y + 1.0f);
			pb.LineTo(row.X + row.Width - 1.0f, row.Y + 1.0f);
			pb.LineTo(row.X + row.Width - 1.0f, row.Y + row.Height - 1.0f);
			pb.LineTo(row.X + 1.0f, row.Y + row.Height - 1.0f);
			pb.Close();
			let path = pb.ToPath();
			ctx.VG.StrokePath(path, color, StrokeStyle(2.0f));
			delete path;
		}
		else
		{
			let before = (mDropPlace == .Before) && (mDropItem >= 0);
			let left = before != IsRightToLeft; // before is the inline start
			let line = across ? Rect(left ? row.X - 1.0f : row.X + row.Width - 1.0f, row.Y, 2.0f, row.Height)
				: Rect(row.X, (before ? row.Y : row.Y + row.Height) - 1.0f, row.Width, 2.0f);
			ctx.VG.FillRect(.(line.X, line.Y, line.Width, line.Height), color);
		}
		ctx.PopClip();
	}

	// The item view a payload's value names (a drag from one: its view, weakly), or null.
	private static ItemView SourceOf(DragPayload payload)
	{
		if (!payload.Value.HasValue || (payload.Value.VariantType != typeof(Node.ElementRef)))
			return null;
		let weak = payload.Value.Get<Node.ElementRef>();
		return (weak.Table != null) ? weak.Table.Resolve(weak.Slot, weak.Generation) as ItemView : null;
	}

	// Where a drop at the query's point lands, as the model hears it (its answer in
	// `effect`/`reason`).
	private ModelDrop DropAt(DropQuery query, out DropEffect effect, String reason)
	{
		effect = .None;
		var drop = ModelDrop();
		drop.Payload = query.Payload;
		drop.Effect = query.Preferred;
		// From an item view: its dragged rows and its model.
		let source = SourceOf(query.Payload);
		if (source != null)
		{
			drop.Ids = (Span<Sedulous.GUI.ItemId>)source.mDragIds;
			drop.Source = source.mModel;
		}
		// From the keys: the current row (onto it where the model takes that, else after it).
		if (query.FromKeyboard)
		{
			let current = CurrentItem;
			drop.Index = (current >= 0) ? ItemToModelIndex(current) : ModelIndex();
			drop.Place = (current >= 0) ? Sedulous.GUI.DropPlace.On : Sedulous.GUI.DropPlace.After;
			effect = mModel.CanDrop(drop, reason);
			if ((effect == .None) && reason.IsEmpty && (current >= 0))
			{
				drop.Place = .After;
				effect = mModel.CanDrop(drop, reason);
			}
			return drop;
		}
		let item = ItemAt(ConvertToWorldSpace(query.Local));
		if (item < 0)
		{
			drop.Index = ModelIndex(); // past the rows: the end
			drop.Place = .After;
			effect = mModel.CanDrop(drop, reason);
			return drop;
		}
		drop.Index = ItemToModelIndex(item);
		// Where in the row: quarters at the edges are before and after, the middle onto it (a grid
		// reads across); a place the model does not take falls back to the halves.
		let b = ItemBounds(item);
		let content = Float2(query.Local.X + ScrollOffset.X, query.Local.Y + ScrollOffset.Y);
		let across = mLayout == .Grid;
		var at = across ? (content.X - b.X) / Math.Max(1.0f, b.Width) : (content.Y - b.Y) / Math.Max(1.0f, b.Height);
		if (across && IsRightToLeft)
			at = 1.0f - at; // before is the inline start, the right
		drop.Place = (at < 0.25f) ? Sedulous.GUI.DropPlace.Before : ((at > 0.75f) ? Sedulous.GUI.DropPlace.After : Sedulous.GUI.DropPlace.On);
		effect = mModel.CanDrop(drop, reason);
		if ((effect == .None) && reason.IsEmpty)
		{
			drop.Place = (drop.Place == .On) ? ((at < 0.5f) ? Sedulous.GUI.DropPlace.Before : Sedulous.GUI.DropPlace.After) : Sedulous.GUI.DropPlace.On;
			effect = mModel.CanDrop(drop, reason);
		}
		return drop;
	}

	private void SetDropIndicator(bool over, int32 item, Sedulous.GUI.DropPlace place)
	{
		if ((over == mDropOver) && (item == mDropItem) && (place == mDropPlace))
			return;
		mDropOver = over;
		mDropItem = item;
		mDropPlace = place;
		Invalidate();
	}

	// A click on a row whose press left a multi-selection alone (to drag it): selected alone now.
	private void RowClicked(ItemRow row, MouseEvent e)
	{
		if ((mDeferredItem >= 0) && (mDeferredItem == row.mItem))
		{
			SelectOnly(mDeferredItem);
			NotifySelectionByUser();
		}
		mDeferredItem = -1;
	}

	// Rows from the markup templates: each type made by loading its markup with item bindings,
	// and filled by them.
	private void UseTemplates()
	{
		let factory = new RowFactory();
		factory.TypeOf = new (index) => TemplateFor(index);
		factory.Create = new (type) =>
			{
				let content = new TemplateRowContent();
				let elements = ElementSet;
				if ((elements == null) || (type >= (uint32)mTemplates.Count))
					return content;
				let loader = scope MarkupLoader(elements);
				loader.SetItemBindings(content.Bindings);
				let tree = loader.LoadFromString(mTemplates[(int)type].Markup);
				if (tree != null)
				{
					content.AddChild(tree);
					tree.ReleaseRef(); // the content holds it
				}
				return content;
			};
		factory.Bind = new (content, index) =>
			{
				let text = scope String();
				for (let binding in ((TemplateRowContent)content).Bindings)
				{
					text.Clear();
					for (let part in binding.Parts)
					{
						if (part.IsName)
							ItemField(index, part.Text, text);
						else
							text.Append(part.Text);
					}
					MarkupLoader.ApplyAttribute(binding.Target, binding.Attribute, text);
				}
			};
		delete mFactory;
		mFactory = factory;
		DropRows();
		RequestLayout();
	}

	// The template an item takes: the one whose type is its row-type-column's text, else the
	// default (the one with no type, else the first).
	private uint32 TemplateFor(ModelIndex index)
	{
		uint32 fallback = 0;
		for (int t = 0; t < mTemplates.Count; ++t)
		{
			if (mTemplates[t].Type.IsEmpty)
			{
				fallback = (uint32)t;
				break;
			}
		}
		if (mRowTypeColumn.IsEmpty)
			return fallback;
		let field = scope String()..AppendF("item.{}", mRowTypeColumn);
		let kind = scope String();
		ItemField(index, field, kind);
		for (int t = 0; t < mTemplates.Count; ++t)
		{
			if (!mTemplates[t].Type.IsEmpty && (mTemplates[t].Type == kind))
				return (uint32)t;
		}
		return fallback;
	}

	// A template name's text for an item, appended: `item` (its first column), `item.Column` (a
	// column by name), `index` (its row).
	private void ItemField(ModelIndex index, StringView name, String outText)
	{
		if (mModel == null)
			return;
		if (name == "index")
		{
			index.Row.ToString(outText);
			return;
		}
		if (name == "item")
		{
			mModel.Data(index).ToString(outText);
			return;
		}
		StringView prefix = "item.";
		if ((name.Length <= prefix.Length) || (name.Substring(0, prefix.Length) != prefix))
			return;
		let column = name.Substring(prefix.Length, name.Length - prefix.Length);
		let columnName = scope String();
		for (int c = 0; c < mModel.ColumnCount(); ++c)
		{
			columnName.Clear();
			mModel.ColumnName(c, columnName);
			if (columnName == column)
			{
				mModel.Data(mModel.Index(index.Row, (int32)c, mModel.ParentIndex(index))).ToString(outText);
				return;
			}
		}
	}

	// --- Geometry: a list's rows by the heights, a grid's lines by the cell height ---

	private int32 GridColumns(float width) => (mLayout == .Grid) ? Math.Max(1, (int32)(width / mCellSize.X)) : 1;
	private int32 Across => GridColumns(ContentBounds.Width);

	private float ItemTop(int32 item)
	{
		if (mLayout == .Grid)
			return (float)(item / Across) * mCellSize.Y;
		return mHeights.Top(item);
	}

	private float ItemHeight(int32 item) => (mLayout == .Grid) ? mCellSize.Y : mHeights.At(item);

	private float ContentHeight
	{
		get
		{
			if (mLayout == .Grid)
			{
				let across = Across;
				return (float)(((int32)ItemCount() + across - 1) / across) * mCellSize.Y;
			}
			return mHeights.Total;
		}
	}

	private static bool StylePending(Node node)
	{
		if (node.IsStyleDirty)
			return true;
		for (int i = 0; i < node.ChildCount; ++i)
		{
			if (StylePending(node.GetChildAt(i)))
				return true;
		}
		return false;
	}

	private float RowEstimate => (mRowHeight > 0.0f) ? mRowHeight : mEstimate;

	private uint32 RowTypeOf(int32 item) => (mFactory.TypeOf != null) ? mFactory.TypeOf(ItemToModelIndex(item)) : 0;

	// A list holds a reference to each row in it.
	private static void Hold(List<ItemRow> list, ItemRow row)
	{
		row.AddRef();
		list.Add(row);
	}

	private static void LetGo(List<ItemRow> list)
	{
		for (let row in list)
			row.ReleaseRef();
		list.Clear();
	}

	// `next`'s rows become the live ones (their references with them).
	private void TakeLive(List<ItemRow> next)
	{
		LetGo(mLive);
		mLive.AddRange(next);
		next.Clear();
	}

	// The rows in view (and one past each edge) realised, measured and placed; the scroll anchor
	// kept where it was when rows above it measured differently from their estimate.
	private void Realize()
	{
		if (mRealizing)
			return;
		if (mLayout == .Grid)
		{
			RealizeGrid();
			return;
		}
		mRealizing = true;
		let @box = ContentBounds;
		let inset = ContentTopInset;
		let width = RowWidth(@box.Width);
		let count = ItemCount();
		if (mHeights.Count != count)
			mHeights.Reset(count, RowEstimate);
		let measured = mRowHeight <= 0.0f;
		let across = LayoutConstraints(.(width, 0.0f), .(width, cUnbounded), .(width, -1.0f), false, false);

		// Realise from the anchor; a row above it measuring differently moves the anchor's
		// offset, which is put back, and the rows are taken again (a few passes settle it).
		for (int pass = 0; pass < 3; ++pass)
		{
			let top = ScrollOffset.Y;
			let bottom = top + Math.Max(0.0f, @box.Height - inset);
			let next = scope List<ItemRow>();
			int first = (count > 0) ? mHeights.Find(top) : 0;
			if (first > 0)
				--first; // one above the view
			// The rows leaving the view go back to their pools first, so those coming in take
			// them rather than new ones (judged by the heights as they stand).
			{
				int last = first;
				while ((last < count) && (mHeights.Top(last) < bottom))
					++last;
				// (By the ids in range, not each row's lookup: an id's row is a search in a list.)
				let inRange = scope List<Sedulous.GUI.ItemId>();
				for (int i = first; (count > 0) && (i <= Math.Min(last, count - 1)); ++i)
					inRange.Add(ItemIdAt((int32)i));
				let kept = scope List<ItemRow>();
				for (let row in mLive)
				{
					bool stays = false;
					for (let id in inRange)
						stays = stays || (id == row.mItemId);
					if (stays)
						Hold(kept, row);
					else
						ReleaseRow(row);
				}
				TakeLive(kept);
			}
			for (let row in mLive)
				row.mTaken = false;
			if (count > 0)
			{
				bool pastEnd = false;
				for (int i = first; (i < count) && !pastEnd; ++i)
				{
					pastEnd = mHeights.Top(i) >= bottom; // one below the view
					let row = TakeRow((int32)i, next);
					// A row not yet styled (just made, or its template's attributes just
					// written) is measured again once it is. Unstyled it often measures nothing
					// (no font yet); then it keeps its estimate, since rows of no height all start
					// at the top and the view would start at the last of them.
					if (measured && !mHeights.IsMeasured(i))
					{
						let pending = StylePending(row);
						let height = row.Measure(across).Y;
						if (!pending || (height > 0.0f))
							mHeights.Set(i, height, !pending);
					}
				}
			}
			for (let row in mLive)
			{
				if (!row.mTaken)
					ReleaseRow(row);
			}
			TakeLive(next);
			for (let row in mLive)
				row.mTaken = false;

			SetScrollExtent(.(width, inset + mHeights.Total));
			// The new range moved the offset (a scroll aimed before a layout, clamped now): the
			// rows are taken again where it is, since the scroll it reports is not heard here.
			if (Math.Abs(ScrollOffset.Y - top) >= 0.5f)
			{
				UpdateScrollAnchor();
				continue;
			}
			if (IsFlinging || IsSmoothScrolling || (mScrollAnchor >= (int32)count))
				break;
			let want = mHeights.Top(mScrollAnchor) + mScrollAnchorDelta;
			if ((Math.Abs(want - ScrollOffset.Y) < 0.5f) || (ScrollRange.Y < want - 0.5f))
				break;
			ApplyScrollOffset(.(ScrollOffset.X, want));
		}

		for (let row in mLive)
		{
			let i = row.mItem;
			row.Arrange(.(RowLeft(@box, width), @box.Y + inset + mHeights.Top(i), width, mHeights.At(i)));
		}
		mRealizing = false;
	}

	// A grid's cells in view (and a line past each edge), at the cell size, stretched across.
	private void RealizeGrid()
	{
		mRealizing = true;
		let @box = ContentBounds;
		let inset = ContentTopInset;
		let count = (int32)ItemCount();
		let across = GridColumns(@box.Width);
		let cellW = @box.Width / (float)across;
		let top = ScrollOffset.Y;
		let bottom = top + Math.Max(0.0f, @box.Height - inset);
		let firstLine = Math.Max(0, (int32)(top / mCellSize.Y) - 1);
		let lastLine = (int32)(bottom / mCellSize.Y) + 1;
		let first = Math.Min(count, firstLine * across);
		let last = Math.Min(count, (lastLine + 1) * across);

		let inRange = scope List<Sedulous.GUI.ItemId>();
		for (int32 i = first; i < last; ++i)
			inRange.Add(ItemIdAt(i));
		let kept = scope List<ItemRow>();
		for (let row in mLive)
		{
			bool stays = false;
			for (let id in inRange)
				stays = stays || (id == row.mItemId);
			if (stays)
				Hold(kept, row);
			else
				ReleaseRow(row);
		}
		TakeLive(kept);
		for (let row in mLive)
			row.mTaken = false;
		let next = scope List<ItemRow>();
		for (int32 i = first; i < last; ++i)
			TakeRow(i, next);
		// A row kept for its item but not taken (the item's row type changed) goes back too.
		for (let row in mLive)
		{
			if (!row.mTaken)
				ReleaseRow(row);
		}
		TakeLive(next);
		for (let row in mLive)
		{
			row.mTaken = false;
			let i = row.mItem;
			row.Arrange(CellBounds(@box, i, across, cellW, @box.Y + inset + (float)(i / across) * mCellSize.Y, mCellSize.Y));
		}
		SetScrollExtent(.(@box.Width, inset + ContentHeight));
		mRealizing = false;
	}

	// Typing jumps to the next item whose text starts with what was typed (within a second of
	// the last text; one character again cycles through the items starting with it). The text is
	// typed text: it follows the keyboard layout and an IME. False for no text or no items.
	private bool TypeAhead(StringView typed)
	{
		if ((typed.Length == 0) || (ItemCount() == 0))
			return false;
		let d = EventDispatcher;
		// (An item a user may not select matches nothing.)
		let item = mTypeAhead.Find(typed, (d != null) ? d.Time : 0.0f, (int32)ItemCount(), CurrentItem, scope (i, outText) =>
			{
				if (IsItemSelectable(i))
					TypeAheadText(i, outText);
			});
		if (item >= 0)
		{
			SelectOnly(item);
			NotifySelectionByUser();
			ScrollToItem(item);
		}
		return true;
	}

	// A row for `item`: the live one showing its id, else one from its type's pool, else new.
	// `next` takes a reference to it.
	private ItemRow TakeRow(int32 item, List<ItemRow> next)
	{
		let id = ItemIdAt(item);
		let type = RowTypeOf(item);
		ItemRow row = null;
		for (let live in mLive)
		{
			if (!live.mTaken && (live.mItemId == id) && (live.mType == type))
			{
				row = live;
				break;
			}
		}
		if (row == null)
		{
			let pool = PoolOf(type);
			if (pool.Rows.Count != 0)
			{
				row = pool.Rows.PopBack();
				next.Add(row); // the pool's reference, handed on
			}
			else
			{
				let made = new ItemRow(this);
				made.mType = type;
				made.mContent = (mFactory.Create != null) ? mFactory.Create(type) : CreateContent(type);
				if (made.mContent != null)
					made.AddChild(made.mContent);
				ShareTextStyle(made);
				AddChild(made);
				row = made;
				next.Add(made); // the reference it was made with
			}
			row.mDirty = true;
			row.mItemId = id;
		}
		else
			Hold(next, row);
		row.mTaken = true;
		row.mItem = item;
		if (row.mDirty)
		{
			let index = ItemToModelIndex(item);
			if (row.mContent != null)
			{
				if (mFactory.Bind != null)
					mFactory.Bind(row.mContent, index);
				else
					BindContent(row.mContent, item, index);
			}
			row.mDirty = false;
		}
		row.Displayed = true;
		row.SetSelectedState(IsIdSelected(id));
		return row;
	}

	private void ReleaseRow(ItemRow row)
	{
		if (mEditing && (row.mItemId == mEditId))
			EndEdit(true); // scrolled away: what was typed is kept
		row.Displayed = false;
		row.mItemId = NoItem;
		row.mItem = -1;
		Hold(PoolOf(row.mType).Rows, row);
	}

	private Pool PoolOf(uint32 type)
	{
		for (let pool in mPools)
		{
			if (pool.Type == type)
				return pool;
		}
		let pool = new Pool();
		pool.Type = type;
		mPools.Add(pool);
		return pool;
	}

	private void DropRows()
	{
		ForEachRow(scope (row) => { row.RemoveFromParent(); });
		LetGo(mLive);
		ClearAndDeleteItems!(mPools);
	}

	// --- The scroll anchor: an item and how far into it the top of the view is ---

	private void ResetScrollAnchor()
	{
		mScrollAnchor = 0;
		mScrollAnchorDelta = 0.0f;
	}

	private void UpdateScrollAnchor()
	{
		if (mLayout == .Grid)
			return; // a grid's cells do not change height
		let y = ScrollOffset.Y;
		mScrollAnchor = (int32)mHeights.Find(y);
		mScrollAnchorDelta = y - mHeights.Top(mScrollAnchor);
	}

	private void ClampScrollAnchor()
	{
		let count = (int32)ItemCount();
		if (mScrollAnchor >= count)
			ResetScrollAnchor();
	}

	// --- Selection ---

	private void SelectOnly(int32 item)
	{
		let id = ItemIdAt(item);
		mSelected.Clear();
		mSelected.Add(id);
		mCurrent = id;
		mAnchorSelection = id;
		RefreshSelectionStates();
	}

	private void SelectRange(int32 item)
	{
		let anchor = ItemOfId(mAnchorSelection);
		let from = (anchor >= 0) ? anchor : item;
		mSelected.Clear();
		for (int32 i = Math.Min(from, item); i <= Math.Max(from, item); ++i)
		{
			if (IsItemSelectable(i))
				mSelected.Add(ItemIdAt(i));
		}
		mCurrent = ItemIdAt(item);
		RefreshSelectionStates();
	}

	private void ToggleSelected(int32 item)
	{
		let id = ItemIdAt(item);
		if (!mSelected.Remove(id))
			mSelected.Add(id);
		mCurrent = id;
		mAnchorSelection = id;
		RefreshSelectionStates();
	}

	private void PruneSelection()
	{
		let gone = scope List<Sedulous.GUI.ItemId>();
		for (let id in mSelected)
		{
			if (ItemOfId(id) < 0)
				gone.Add(id);
		}
		for (let id in gone)
			mSelected.Remove(id);
		if (ItemOfId(mCurrent) < 0)
			mCurrent = NoItem;
		if (ItemOfId(mAnchorSelection) < 0)
			mAnchorSelection = NoItem;
	}

	private void RefreshSelectionStates()
	{
		mSelectionChanged.Notify();
		for (let row in mLive)
			row.SetSelectedState(IsIdSelected(row.mItemId));
	}

	private void NotifySelectionByUser()
	{
		if (mOnSelection != null)
			mOnSelection(SelectedIndex);
		SendEvent(scope Event(.Changed, this));
	}

	private void ActivateItem(int32 item)
	{
		if (!IsItemSelectable(item))
			return;
		let index = ItemToModelIndex(item);
		if (mOnActivated != null)
			mOnActivated(index);
		SendEvent(scope ItemEvent(.ItemActivate, this, item, index));
	}

	// A press on a row: the left button selects (a second press activates), the right one
	// selects for its context menu.
	private void RowPressed(ItemRow row, MouseEvent e)
	{
		if (row.mItem < 0)
			return;
		if (e.Button == .Left)
		{
			e.Handled = true;
			RequestFocus();
			if (e.ClickCount == 2)
			{
				ActivateItem(row.mItem);
				return;
			}
			// A plain press on a row of a multi-selection leaves it (a drag takes it all); the
			// click, if no drag starts, selects the row alone.
			if ((mSelectionMode == .Multi) && (e.Modifiers == 0) && (mSelected.Count > 1) && IsItemSelected(row.mItem))
			{
				mDeferredItem = row.mItem;
				mCurrent = ItemIdAt(row.mItem);
				return;
			}
			SelectByUser(row.mItem, e.Modifiers);
		}
	}
}
