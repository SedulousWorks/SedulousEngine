using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The property grid: a source's properties as rows, a label beside an editor, on the core's item
// view, so only the rows in view exist and each kind of row has a pool (a category's header, a
// group's, one per editor). What the grid keeps is outside the rows (zed's way): the properties
// read once into a tree when the source says they changed, which paths are folded (categories
// start open, groups closed), the search, and one label split for every row, dragged at any row's
// boundary. A search keeps what matches by its shown name or its path, with what holds it, opened
// while it searches; the folding is left as it was. The wheel scrolls the grid and never changes a
// value (ezEngine's rule). An edit is the source's gesture; while it goes, its row is not rebound
// from the values it previews.

/// One row of a grid: a category's header, or a property (a group, or a value with its editor). A
/// class: it owns its path and its info; Set copies another into it.
class PropertyRow
{
	/// A category's: `#` and its name.
	public String Path = new .() ~ delete _;
	/// A category's: its name as Name.
	public PropertyInfo Info = new .() ~ delete _;
	public bool Category = false;
	public bool HasChildren = false;
	public bool Open = false;
	public int32 Depth = 0;
	/// Its pool: an editor's type, or a header's.
	public uint32 Type = 0;
	public ItemId Id = NoItem;
	/// An element of a list: its index, and what its list allows.
	public bool Element = false;
	public int Index = 0;
	public uint8 ListOps = 0;
	/// An element's: how many its list shows.
	public int Count = 0;
	/// The property it shows, in the grid's tree (-1: none).
	public int Node = -1;

	public void Set(PropertyRow other)
	{
		Path.Set(other.Path);
		Info.Set(other.Info);
		Category = other.Category;
		HasChildren = other.HasChildren;
		Open = other.Open;
		Depth = other.Depth;
		Type = other.Type;
		Id = other.Id;
		Element = other.Element;
		Index = other.Index;
		ListOps = other.ListOps;
		Count = other.Count;
		Node = other.Node;
	}
}

/// What PropertyGrid.bf keeps out of the public surface.
internal static class PropertyGridDetail
{
	// The grid's rows as the item view's flat model.
	public class PropertyRowModel : IModel
	{
		private List<PropertyRow> mRows = new .() ~ DeleteContainerAndItems!(_);
		private Dictionary<ItemId, int32> mRowOfId = new .() ~ delete _;

		/// OWNERSHIP of `rows` and what it holds transfers.
		public void SetRows(List<PropertyRow> rows)
		{
			DeleteContainerAndItems!(mRows);
			mRows = rows;
			mRowOfId.Clear();
			for (int i = 0; i < mRows.Count; ++i)
				mRowOfId[mRows[i].Id] = (int32)i;
			NotifyReset();
		}

		public List<PropertyRow> Rows => mRows;

		public void ValuesChanged()
		{
			if (mRows.Count != 0)
				NotifyRowsChanged(ModelIndex(), 0, (int32)mRows.Count);
		}

		public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mRows.Count;
		public override int ColumnCount() => 1;

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			return IsValidIndex(index) ? Sedulous.GUI.Variant(mRows[index.Row].Info.ShownName) : Sedulous.GUI.Variant();
		}

		public override ItemId IdOf(ModelIndex index) => IsValidIndex(index) ? mRows[index.Row].Id : NoItem;

		public override ModelIndex IndexOfId(ItemId id)
		{
			if (mRowOfId.TryGetValue(id, let row))
				return MakeModelIndex(row);
			return ModelIndex();
		}
	}

	/// The free ReadPropertyValue, reached where a member of that name hides it.
	public static PropertyValue ReadValue(IPropertySource source, StringView path, PropertyKind kind) => ReadPropertyValue(source, path, kind);
}

/// The thin strip at a row's label boundary: dragged, it moves every row's split.
[GuiReflect]
class PropertySplitHandle : UIWidget
{
	// The grid it belongs to, which outlives it.
	private PropertyGrid mGrid;
	private bool mDragging = false;

	public this(PropertyGrid grid)
	{
		mGrid = grid;
		Tag = "propertysplit";
		Cursor = .EwResize;
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		mDragging = true;
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (!mDragging)
			return;
		// The pointer's place across the grid's rows, from their inline start.
		let rows = mGrid.ContentBounds;
		let at = mGrid.ConvertToNodeSpace(e.Position); // events come in screen space
		var x = at.X - rows.X;
		if (mGrid.IsRightToLeft)
			x = rows.Width - x;
		if (rows.Width > 0.0f)
			mGrid.LabelRatio = x / rows.Width;
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		mDragging = false;
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		mDragging = false;
	}
}

/// A list element's grip: dragged, it moves the element to another place in its list.
[GuiReflect]
class PropertyGrip : UIWidget
{
	private PropertyGrid mGrid;
	private String mPath = new .() ~ delete _;
	private bool mDragging = false;

	public this(PropertyGrid grid)
	{
		mGrid = grid;
		Tag = "propertygrip";
		Cursor = .Grab;
	}

	public StringView Path
	{
		get => mPath;
		set => mPath.Set(value);
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		mDragging = true;
		Cursor = .Grabbing;
		mGrid.BeginReorder(mPath);
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (mDragging)
			mGrid.MoveReorder(e.Position);
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (!mDragging)
			return;
		mDragging = false;
		Cursor = .Grab;
		mGrid.EndReorder(true);
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		if (!mDragging)
			return;
		mDragging = false;
		Cursor = .Grab;
		mGrid.EndReorder(false);
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		// Two columns of three dots.
		let dots = GetPartStyle("dots");
		var color = dots.HasBackground ? dots.Box.BackgroundColor : Color(0.55f, 0.58f, 0.62f, 1.0f);
		color.A *= dots.Opacity;
		let cx = localBounds.X + localBounds.Width * 0.5f;
		let cy = localBounds.Y + localBounds.Height * 0.5f;
		for (int32 col = 0; col < 2; ++col)
		{
			for (int32 row = -1; row <= 1; ++row)
				ctx.VG.FillRect(.(cx - 3.0f + (float)col * 4.0f, cy - 1.0f + (float)row * 4.0f, 2.0f, 2.0f), color);
		}
	}

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("dots");
	}
}

/// A category's header: its chevron and its name across the row.
[GuiReflect]
class PropertyCategoryContent : UIWidget
{
	private PropertyGrid mGrid;
	private TreeArrow mArrow ~ _.ReleaseRef();
	private Sedulous.GUI.Label mLabel ~ _.ReleaseRef();
	private String mPath = new .() ~ delete _;

	public this(PropertyGrid grid)
	{
		mGrid = grid;
		Tag = "propertycategory";
		mArrow = new TreeArrow();
		mArrow.SetOnClicked(new () => { mGrid.ToggleOpen(mPath); });
		AddChild(mArrow);
		mLabel = new Sedulous.GUI.Label();
		mLabel.SetTextAlignment(.Start, .Middle);
		mLabel.HitTestVisible = false;
		AddChild(mLabel);
	}

	public void Show(PropertyRow row)
	{
		mPath.Set(row.Path);
		mArrow.Expanded = row.Open;
		mLabel.Text = row.Info.ShownName;
	}

	public StringView Path => mPath;
	public Sedulous.GUI.Label Label => mLabel;

	protected override void OnMouseClick(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		mGrid.ToggleOpen(mPath);
	}

	public override void OnLayout()
	{
		let @box = ContentBounds;
		let rtl = IsRightToLeft;
		let arrow = mGrid.ArrowSize;
		mArrow.Arrange(Rect.MirroredIn(.(@box.X, @box.Y, arrow, @box.Height), @box, rtl));
		mLabel.Arrange(Rect.MirroredIn(.(@box.X + arrow + 2.0f, @box.Y, Math.Max(0.0f, @box.Width - arrow - 2.0f), @box.Height), @box, rtl));
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mLabel);
	}
}

/// A property's row: indented by its depth, a group's chevron, its name (its description the
/// tooltip), the split, and its editor (none for a group).
[GuiReflect]
class PropertyRowContent : UIWidget
{
	private const float cGrip = 12.0f;
	private PropertyGrid mGrid;
	private TreeArrow mArrow ~ _.ReleaseRef();
	private Sedulous.GUI.Label mLabel ~ _.ReleaseRef();
	private PropertySplitHandle mSplit ~ _.ReleaseRef();
	private PropertyGrip mGrip ~ _.ReleaseRef();
	private PropertyEditor mEditor ~ _?.ReleaseRef();
	private String mPath = new .() ~ delete _;
	private String mDescription = new .() ~ delete _;
	private int32 mDepth = 0;
	// An element its list lets move: its grip shows.
	private bool mMovable = false;
	private bool mChanged = false;

	/// `editor` (null for a group's row): the row takes the reference it comes with.
	public this(PropertyGrid grid, PropertyEditor editor)
	{
		mGrid = grid;
		mEditor = editor;
		Tag = "propertyrowcontent";
		mArrow = new TreeArrow();
		mArrow.SetOnClicked(new () => { mGrid.ToggleOpen(mPath); });
		AddChild(mArrow);
		mLabel = new Sedulous.GUI.Label();
		mLabel.Tag = "propertyname";
		mLabel.SetTextAlignment(.Start, .Middle);
		mLabel.HitTestVisible = false;
		AddChild(mLabel);
		if (mEditor != null)
			AddChild(mEditor);
		mGrip = new PropertyGrip(grid);
		AddChild(mGrip);
		mSplit = new PropertySplitHandle(grid);
		AddChild(mSplit); // last: over the editor's edge
	}

	public void Show(PropertyRow row)
	{
		mPath.Set(row.Path);
		mDepth = row.Depth;
		mDescription.Set(row.Info.Description);
		mArrow.Visible = row.HasChildren;
		mArrow.Expanded = row.Open;
		mLabel.Text = row.Info.ShownName;
		mMovable = row.Element && ((row.ListOps & PropertyListMove) != 0) && (row.Count > 1);
		mGrip.Displayed = mMovable;
		mGrip.Path = row.Path;
		RequestLayout();
	}

	public StringView Path => mPath;
	public PropertyEditor Editor => mEditor;
	public Sedulous.GUI.Label Label => mLabel;
	public PropertySplitHandle SplitHandle => mSplit;
	public PropertyGrip Grip => mGrip;

	/// Marked: an object's value here, or under here, differs from its default.
	public bool IsChanged
	{
		get => mChanged;
		set
		{
			if (value == mChanged)
				return;
			mChanged = value;
			if (value)
				AddClass("changed");
			else
				RemoveClass("changed");
			Invalidate();
		}
	}

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("marker");
	}

	public override StringView TooltipText => mDescription;

	public override void OnLayout()
	{
		let @box = ContentBounds;
		let rtl = IsRightToLeft;
		let split = Math.Floor(@box.Width * mGrid.LabelRatio);
		let indent = (float)mDepth * mGrid.IndentWidth;
		let arrow = mGrid.ArrowSize;
		mArrow.Arrange(Rect.MirroredIn(.(@box.X + indent, @box.Y, arrow, @box.Height), @box, rtl));
		if (mMovable) // in the indent before the element
			mGrip.Arrange(Rect.MirroredIn(.(@box.X + Math.Max(0.0f, indent - cGrip), @box.Y, cGrip, @box.Height), @box, rtl));
		let textX = indent + arrow + 2.0f;
		mLabel.Arrange(Rect.MirroredIn(.(@box.X + textX, @box.Y, Math.Max(0.0f, split - textX - 4.0f), @box.Height), @box, rtl));
		if (mEditor != null)
			mEditor.Arrange(Rect.MirroredIn(.(@box.X + split + 2.0f, @box.Y + 1.0f, Math.Max(0.0f, @box.Width - split - 2.0f), Math.Max(0.0f, @box.Height - 2.0f)), @box, rtl));
		mSplit.Arrange(Rect.MirroredIn(.(@box.X + split - 3.0f, @box.Y, 6.0f, @box.Height), @box, rtl));
	}

	// The changed marker: a bar at the row's inline start, `::marker`'s colour.
	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		if (!mChanged)
			return;
		let marker = GetPartStyle("marker");
		var color = marker.HasBackground ? marker.Box.BackgroundColor : Color(0.31f, 0.61f, 1.0f, 1.0f);
		color.A *= marker.Opacity;
		let bar = Rect.MirroredIn(.(localBounds.X, localBounds.Y + 2.0f, 3.0f, Math.Max(0.0f, localBounds.Height - 4.0f)), localBounds, IsRightToLeft);
		ctx.VG.FillRect(bar.ToRectangle(), color);
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mLabel);
		if (mEditor != null)
			ShareTextStyle(mEditor);
	}
}

[GuiReflect(true)]
class PropertyGrid : ItemView, IPropertySourceClient, IPropertyEditHost
{
	public const uint32 cCategoryRow = 0x80000000;
	public const uint32 cGroupRow = 0x80000001;

	// The properties as read from the source: a tree, each node's children by index.
	private class PropertyNode
	{
		public String Path = new .() ~ delete _;
		public PropertyInfo Info ~ delete _;
		public List<int> Children = new .() ~ delete _;
	}

	// Not owned: it outlives the grid or is set to null first.
	private IPropertySource mSource = null;
	private PropertyGridDetail.PropertyRowModel mRows = new .() ~ delete _;
	private PropertyEditorRegistry mEditors = new .() ~ delete _;
	private uint32 mEditorGeneration = 0;
	private List<PropertyNode> mNodes = new .() ~ DeleteContainerAndItems!(_);
	private List<int> mTop = new .() ~ delete _;
	// Paths folded unlike their default.
	private List<String> mToggled = new .() ~ DeleteContainerAndItems!(_);
	private String mFilter = new .() ~ delete _;
	private String mEditPath = new .() ~ delete _;
	private Sedulous.GUI.Menu mMenu ~ _?.ReleaseRef();
	private delegate void(StringView message) mOnMessage ~ delete _;
	private delegate void(Sedulous.GUI.Menu menu, PropertyRow row) mOnRowMenu ~ delete _;
	// A grip's drag: the list, the element's index, where it would go, and the line's row.
	private String mReorderList = new .() ~ delete _;
	private int32 mReorderFrom = -1;
	private int32 mReorderTo = -1;
	private int32 mReorderLine = -1;
	private bool mReorderAfter = false;
	private float mLabelRatio = 0.4f;
	private float mIndentWidth = 12.0f;
	private float mArrowSize = 16.0f;

	public this()
	{
		Tag = "propertygrid";
		RowHeight = 24.0f;
		RegisterDefaultPropertyEditors(mEditors);
		mEditorGeneration = mEditors.Generation;
		SetRowFactory(MakeFactory());
		Model = mRows;
	}

	public ~this()
	{
		Model = null;
		if ((mSource != null) && (mSource.Client == this))
			mSource.Client = null;
	}

	/// The source it shows (not owned; it outlives the grid or is set to null first).
	public IPropertySource Source
	{
		get => mSource;
		set
		{
			if (mSource == value)
				return;
			if (mSource != null)
			{
				EndOpenEdit();
				if (mSource.Client == this)
					mSource.Client = null;
			}
			mSource = value;
			if (mSource != null)
				mSource.Client = this;
			ReadProperties();
		}
	}

	/// The editors it chooses from: an application registers its own here, then Refresh.
	public PropertyEditorRegistry Editors => mEditors;

	/// Reads the properties again (an editor registered, a source's change it did not say).
	public void Refresh()
	{
		if (mEditorGeneration != mEditors.Generation)
		{
			mEditorGeneration = mEditors.Generation;
			SetRowFactory(MakeFactory()); // the pools start again
		}
		ReadProperties();
	}

	// === Folding ===

	/// Whether `path` (a group's, or a category's `#Name`) is open: categories start open, groups
	/// closed.
	public bool IsOpen(StringView path)
	{
		let byDefault = (path.Length != 0) && (path[0] == '#');
		return byDefault != (ToggledAt(path) >= 0);
	}

	public void SetOpen(StringView path, bool open)
	{
		if (IsOpen(path) == open)
			return;
		let at = ToggledAt(path);
		if (at >= 0)
		{
			delete mToggled[at];
			mToggled.RemoveAt(at);
		}
		else
			mToggled.Add(new String(path));
		Fold();
	}

	public void ToggleOpen(StringView path) => SetOpen(path, !IsOpen(path));

	// === Search ===

	/// Shows only what matches `filter` by its shown name or its path (letters in either case
	/// alike), with what holds it; empty shows everything.
	public StringView Filter
	{
		get => mFilter;
		set
		{
			if (mFilter == value)
				return;
			mFilter.Set(value);
			Fold();
		}
	}

	// === The label split ===

	/// The labels' share of a row's width (`label-ratio`), kept between 0.1 and 0.9.
	[GuiProperty("label-ratio")]
	public float LabelRatio
	{
		get => mLabelRatio;
		set
		{
			let ratio = Math.Clamp(value, 0.1f, 0.9f);
			if (ratio == mLabelRatio)
				return;
			mLabelRatio = ratio;
			ForEachRow(scope (row) =>
				{
					if (let content = row.Content)
						content.RequestLayout();
				});
			Invalidate();
		}
	}

	/// A nested property's indent per level (`indent-width`).
	[GuiProperty("indent-width")]
	public float IndentWidth
	{
		get => mIndentWidth;
		set
		{
			mIndentWidth = Math.Max(0.0f, value);
			ItemsChanged();
		}
	}

	/// The column a row keeps for a group's arrow (`arrow-size`), the arrow drawn to fit it.
	[GuiProperty("arrow-size")]
	public float ArrowSize
	{
		get => mArrowSize;
		set
		{
			mArrowSize = Math.Max(0.0f, value);
			ItemsChanged();
		}
	}

	// === Lists ===

	/// Changes the list `path` through the source (an open edit ends first); an insert opens it.
	public bool EditPropertyList(StringView path, ListEdit edit)
	{
		if (mSource == null)
			return false;
		EndOpenEdit();
		let list = scope String(path);
		if (!mSource.EditList(list, edit))
			return false;
		if (edit.Kind == .Insert)
			SetOpen(list, true);
		return true;
	}

	/// The place the element would go now (its index after the move), or -1.
	public int32 ReorderTarget => mReorderTo;
	/// The row's menu, while it is open.
	public Sedulous.GUI.Menu RowMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;
	/// What the application adds to a row's menu, after the grid's own items: a header's menu is
	/// the application's alone (a component's verbs on its section), and shows only when it adds
	/// something. `row` is the row the menu is for (a header's path is `#` and its name), a copy
	/// alive for the call only. OWNERSHIP of `extend` transfers.
	public void SetOnRowMenu(delegate void(Sedulous.GUI.Menu menu, PropertyRow row) extend)
	{
		delete mOnRowMenu;
		mOnRowMenu = extend;
	}

	// === The rows ===

	public int RowCount => mRows.Rows.Count;

	public PropertyRow GetRow(int32 item) => ((item >= 0) && (item < mRows.Rows.Count)) ? mRows.Rows[item] : null;

	/// The row of `path` shown now, or -1.
	public int32 FindRow(StringView path)
	{
		for (int i = 0; i < mRows.Rows.Count; ++i)
		{
			if (mRows.Rows[i].Path == path)
				return (int32)i;
		}
		return -1;
	}

	/// The editor showing `path` now (its row realised), or null.
	public PropertyEditor FindEditor(StringView path)
	{
		let item = FindRow(path);
		let row = (item >= 0) ? RowForItem(item) : null;
		let content = (row != null) ? (row.Content as PropertyRowContent) : null;
		return (content != null) ? content.Editor : null;
	}

	// === Defaults ===

	/// Whether `path`'s row shows: an object differs from its default there, or under there.
	public bool IsRowChanged(StringView path)
	{
		let row = GetRow(FindRow(path));
		return (row != null) && (row.Node >= 0) && (row.Node < mNodes.Count) && IsChanged(row.Node);
	}

	/// Puts each object's default back at `path` and under it, through the source.
	public bool RevertProperty(StringView path)
	{
		if (mSource == null)
			return false;
		EndOpenEdit();
		let at = scope String(path);
		return mSource.Revert(at);
	}

	// === Copying ===

	/// Copies `path` (and what is under it) to the clipboard through the source; false when the
	/// source cannot.
	public bool CopyProperty(StringView path)
	{
		let dispatcher = EventDispatcher;
		let clipboard = (dispatcher != null) ? dispatcher.Clipboard : null;
		if ((mSource == null) || (clipboard == null))
			return false;
		let text = scope String();
		mSource.CopyValue(path, text);
		if (text.Length == 0)
			return false;
		clipboard.SetText(text);
		return true;
	}

	/// Pastes the clipboard's text into `path` through the source; refused, the reason goes to
	/// SetOnMessage's callback.
	public bool PasteProperty(StringView path)
	{
		let dispatcher = EventDispatcher;
		let clipboard = (dispatcher != null) ? dispatcher.Clipboard : null;
		if ((mSource == null) || (clipboard == null) || !clipboard.HasText)
			return false;
		EndOpenEdit();
		let at = scope String(path);
		let text = scope String();
		clipboard.GetText(text);
		let reason = scope String();
		if (mSource.PasteValue(at, text, reason))
			return true;
		if (mOnMessage != null)
			mOnMessage((reason.Length != 0) ? (StringView)reason : "Cannot paste that here");
		return false;
	}

	/// Told what the grid has to say: why a paste was refused (for a status bar). OWNERSHIP of
	/// `onMessage` transfers.
	public void SetOnMessage(delegate void(StringView message) onMessage)
	{
		delete mOnMessage;
		mOnMessage = onMessage;
	}

	/// The path an edit is open on (empty: none).
	public StringView EditPath => mEditPath;

	// === IPropertyEditHost's reads ===

	public void GetChildProperties(StringView path, List<PropertyInfo> outInfos)
	{
		if (mSource != null)
			mSource.GetProperties(path, outInfos);
	}

	public PropertyValue ReadPropertyValue(StringView path, PropertyKind kind)
	{
		return (mSource != null) ? PropertyGridDetail.ReadValue(mSource, path, kind) : PropertyValue();
	}

	// === IPropertySourceClient ===

	public void OnPropertiesChanged()
	{
		ReadProperties();
	}

	public void OnValuesChanged()
	{
		mRows.ValuesChanged();
	}

	// === IPropertyEditHost ===

	public void BeginPropertyEdit(StringView path)
	{
		if (mSource == null)
			return;
		if ((mEditPath.Length != 0) && (mEditPath != path))
			EndOpenEdit();
		if (mEditPath == path)
			return;
		mEditPath.Set(path);
		mSource.BeginEdit(path);
	}

	public void PreviewPropertyEdit(StringView path, PropertyWrite write)
	{
		if ((mSource != null) && (mEditPath == path))
			mSource.PreviewEdit(path, write);
	}

	public void CommitPropertyEdit(StringView path, PropertyWrite write)
	{
		if ((mSource == null) || (mEditPath != path))
			return;
		let at = scope String(path); // `path` may be a view of what is cleared
		mEditPath.Clear();
		mSource.CommitEdit(at, write);
		mRows.ValuesChanged(); // its own row too, now the gesture is over
	}

	public void CancelPropertyEdit(StringView path)
	{
		if ((mSource == null) || (mEditPath != path))
			return;
		let at = scope String(path);
		mEditPath.Clear();
		mSource.CancelEdit(at);
		mRows.ValuesChanged();
	}

	// === Lists ===

	/// A grip's drag: the element at `path` picked up, moved over the rows, let go (or given up).
	public void BeginReorder(StringView path)
	{
		let item = FindRow(path);
		let row = GetRow(item);
		if ((row == null) || !row.Element || ((row.ListOps & PropertyListMove) == 0))
			return;
		EndOpenEdit();
		mReorderList.Set(ParentPropertyPath(path));
		mReorderFrom = (int32)row.Index;
		mReorderTo = -1;
		mReorderLine = -1;
	}

	// Over an element of the same list: before it or after it, by its halves.
	public void MoveReorder(Float2 screen)
	{
		if (mReorderFrom < 0)
			return;
		mReorderTo = -1;
		mReorderLine = -1;
		let item = ItemAt(screen);
		let row = GetRow(item);
		if ((row != null) && row.Element && (ParentPropertyPath(row.Path) == mReorderList))
		{
			let bounds = ItemBounds(item);
			let y = ConvertToNodeSpace(screen).Y + ScrollOffset.Y;
			mReorderAfter = y > bounds.Y + bounds.Height * 0.5f;
			let slot = (int32)row.Index + (mReorderAfter ? 1 : 0); // a gap between elements
			mReorderTo = (slot > mReorderFrom) ? slot - 1 : slot;
			mReorderLine = item;
		}
		Invalidate();
	}

	public void EndReorder(bool drop)
	{
		let list = scope String(mReorderList);
		mReorderList.Clear();
		let from = mReorderFrom;
		let to = mReorderTo;
		mReorderFrom = mReorderTo = mReorderLine = -1;
		Invalidate();
		if (drop && (from >= 0) && (to >= 0) && (to != from))
		{
			let edit = scope ListEdit();
			edit.Kind = .Move;
			edit.Index = from;
			edit.To = to;
			EditPropertyList(list, edit);
		}
	}

	// A row's menu: an element's insert before it, remove it, move it up or down; any row's revert.
	/// Opens the menu of the row `item` at `position` (in the root's space); false when it has none.
	public bool OpenRowMenu(int32 item, Float2 position)
	{
		let found = GetRow(item);
		if ((found == null) || (found.Category && (mOnRowMenu == null)))
			return false;
		let row = scope PropertyRow(); // the rows change under the menu's actions
		row.Set(found);
		if (mMenu != null)
			mMenu.ReleaseRef();
		mMenu = new Sedulous.GUI.Menu();
		ShareTextStyle(mMenu, false);
		mMenu.SetAutoWidth(true);
		bool any = false;
		if (row.Category)
		{
			mOnRowMenu(mMenu, row);
			if (mMenu.ChildCount == 0)
				return false;
			mMenu.Open(this, position);
			return true;
		}
		if (row.Element)
		{
			let index = row.Index;
			let insert = mMenu.AddItem("Insert above", MakeListAction(row.Path, .Insert, index, 0));
			insert.Enabled = (row.ListOps & PropertyListAdd) != 0;
			let remove = mMenu.AddItem("Remove", MakeListAction(row.Path, .Remove, index, 0));
			remove.Enabled = (row.ListOps & PropertyListRemove) != 0;
			mMenu.AddSeparator();
			let up = mMenu.AddItem("Move up", MakeListAction(row.Path, .Move, index, index - 1));
			up.Enabled = ((row.ListOps & PropertyListMove) != 0) && (index > 0);
			let down = mMenu.AddItem("Move down", MakeListAction(row.Path, .Move, index, index + 1));
			down.Enabled = ((row.ListOps & PropertyListMove) != 0) && (index + 1 < row.Count);
			any = true;
		}
		if (mSource != null)
		{
			if (any)
				mMenu.AddSeparator();
			let dispatcher = EventDispatcher;
			let clipboard = (dispatcher != null) ? dispatcher.Clipboard : null;
			let copyPath = new String(row.Path);
			let copy = mMenu.AddItem("Copy", new [=this, =copyPath] () => { CopyProperty(copyPath); } ~ delete copyPath);
			let copied = scope String();
			mSource.CopyValue(row.Path, copied);
			copy.Enabled = (clipboard != null) && (copied.Length != 0);
			let pastePath = new String(row.Path);
			let paste = mMenu.AddItem("Paste", new [=this, =pastePath] () => { PasteProperty(pastePath); } ~ delete pastePath);
			paste.Enabled = (clipboard != null) && clipboard.HasText && !row.Info.ReadOnly;
			mMenu.AddSeparator();
			let revertText = scope String();
			mSource.GetRevertText(row.Path, revertText);
			let revertPath = new String(row.Path);
			let revert = mMenu.AddItem(revertText, new [=this, =revertPath] () => { RevertProperty(revertPath); } ~ delete revertPath);
			revert.Enabled = (row.Node >= 0) && (row.Node < mNodes.Count) && IsChanged(row.Node);
			any = true;
		}
		if (mOnRowMenu != null)
		{
			let before = mMenu.ChildCount;
			mOnRowMenu(mMenu, row);
			any = any || (mMenu.ChildCount != before);
		}
		if (!any)
			return false;
		mMenu.Open(this, position);
		return true;
	}

	/// The row whose editor took the focus is the current one, however it took it (a click, Tab,
	/// code): every editor alike, quietly marked, and where the arrow keys go on from.
	public override void OnDescendantFocused(Node focused)
	{
		base.OnDescendantFocused(focused);
		for (var node = focused; (node != null) && (node != this); node = node.Parent)
		{
			if (let row = node as ItemRow)
			{
				if ((row.ItemIndex >= 0) && !IsItemSelected(row.ItemIndex))
					SelectedItem = row.ItemIndex;
				return;
			}
		}
	}

	protected override Node CreateContent(uint32 type) => null;
	protected override void BindContent(Node content, int32 item, ModelIndex index) { }
	protected override StringView RowTag => "propertyrow";

	protected override void OnContextMenu(MouseEvent e)
	{
		base.OnContextMenu(e); // the row selected
		let item = ItemAt(e.Position);
		let top = RootNode;
		if ((item >= 0) && (top != null) && OpenRowMenu(item, top.ConvertToNodeSpace(e.Position)))
			e.Handled = true;
	}

	// The line where a dragged element would go.
	protected override void OnDrawAbove(DrawContext ctx)
	{
		base.OnDrawAbove(ctx);
		if ((mReorderLine < 0) || (mReorderTo < 0))
			return;
		let part = GetPartStyle("drop-indicator");
		let color = part.HasBackground ? part.Box.BackgroundColor : Color(0.31f, 0.61f, 1.0f, 1.0f);
		let @box = ContentBounds;
		var row = ItemBounds(mReorderLine);
		row.X -= ScrollOffset.X;
		row.Y -= ScrollOffset.Y;
		let y = mReorderAfter ? row.Y + row.Height - 1.0f : row.Y - 1.0f;
		ctx.PushClip(@box);
		ctx.VG.FillRect(.(row.X, y, row.Width, 2.0f), color);
		ctx.PopClip();
	}

	// Right opens a category or a group, Left closes it (mirrored right to left).
	protected override bool OnExtraKey(KeyCode key, uint32 modifiers)
	{
		if ((modifiers == KeyModCtrl) && ((key == .C) || (key == .V)))
		{
			let current = GetRow(CurrentItem);
			if ((current == null) || current.Category)
				return false;
			let path = scope String(current.Path);
			return (key == .C) ? CopyProperty(path) : PasteProperty(path);
		}
		if ((modifiers != 0) || ((key != .Left) && (key != .Right)))
			return false;
		let row = GetRow(CurrentItem);
		if ((row == null) || !(row.Category || row.HasChildren))
			return false;
		let open = (key == .Right) != IsRightToLeft;
		SetOpen(scope String(row.Path), open);
		return true;
	}

	private delegate void() MakeListAction(StringView path, ListEdit.Op op, int index, int to)
	{
		let list = new String(ParentPropertyPath(path));
		return new [=this, =list, =op, =index, =to] () =>
			{
				let change = scope ListEdit();
				change.Kind = op;
				change.Index = index;
				change.To = to;
				EditPropertyList(list, change);
			} ~ delete list;
	}

	private int ToggledAt(StringView path)
	{
		for (int i = 0; i < mToggled.Count; i++)
		{
			if (mToggled[i] == path)
				return i;
		}
		return -1;
	}

	private RowFactory MakeFactory()
	{
		let factory = new RowFactory();
		factory.TypeOf = new (index) =>
			{
				let row = GetRow(index.Row);
				return (row != null) ? row.Type : PropertyEditorRegistry.cNoEditor;
			};
		factory.Create = new (type) =>
			{
				if (type == cCategoryRow)
					return new PropertyCategoryContent(this);
				PropertyEditor editor = null;
				if (type != cGroupRow)
					editor = mEditors.Create(type);
				return new PropertyRowContent(this, editor);
			};
		factory.Bind = new (content, index) => { BindRow(content, index); };
		return factory;
	}

	private void BindRow(Node content, ModelIndex index)
	{
		let row = GetRow(index.Row);
		if (row == null)
			return;
		if (let category = content as PropertyCategoryContent)
		{
			category.Show(row);
			return;
		}
		let property = content as PropertyRowContent;
		if (property == null)
			return;
		// The row an edit is open on keeps what its editor shows: the source's values are its
		// previews, and the editor is mid-gesture. So does one being typed into: the text is the
		// edit's until it commits (the values refresh each frame; typed text went back at once).
		let same = property.Path == row.Path;
		let editing = same && (IsUnderEdit(row.Path) || ((property.Editor != null) && property.Editor.IsTyping));
		property.Show(row);
		property.IsChanged = (row.Node >= 0) && (row.Node < mNodes.Count) && IsChanged(row.Node);
		let editor = property.Editor;
		if ((editor != null) && !editing && (mSource != null))
		{
			var value = ReadPropertyValue(row.Path, row.Info.Kind);
			editor.Bind(this, row.Path, row.Info, value);
			value.Dispose();
		}
	}

	private void ReadProperties()
	{
		ClearAndDeleteItems!(mNodes);
		mTop.Clear();
		if (mSource != null)
			ReadChildren(default, mTop, 0);
		Fold();
	}

	private void ReadChildren(StringView parent, List<int> into, int depth)
	{
		let infos = scope List<PropertyInfo>();
		mSource.GetProperties(parent, infos);
		for (let info in infos)
		{
			let at = mNodes.Count;
			let node = new PropertyNode();
			JoinPropertyPath(parent, info.Name, node.Path);
			node.Info = info; // the node takes it
			mNodes.Add(node);
			into.Add(at);
			let kind = node.Info.Kind;
			if (((kind == .Group) || (kind == .List)) && (depth < 32)) // a cycle in a source stops here
			{
				let path = scope String(node.Path);
				ReadChildren(path, node.Children, depth + 1);
			}
		}
	}

	private bool Matches(PropertyNode node)
	{
		let filter = StringView(mFilter);
		bool Contains(StringView text)
		{
			for (int i = 0; i + filter.Length <= text.Length; ++i)
			{
				if ((i > 0) && (((uint8)text[i] & 0xC0) == 0x80))
					continue; // inside a character
				if (StartsWithIgnoringCase(text.Substring(i, text.Length - i), filter))
					return true;
			}
			return false;
		}
		return Contains(node.Info.ShownName) || Contains(node.Path);
	}

	// An object differs from its default here (a value, a list's count), or under here.
	private bool IsChanged(int node)
	{
		if (mSource == null)
			return false;
		let at = mNodes[node];
		if (at.Info.Kind != .Group)
		{
			for (int i = 0; i < mSource.ObjectCount; ++i)
			{
				var byDefault = mSource.GetDefault(at.Path, i);
				defer byDefault.Dispose();
				if (byDefault.IsEmpty)
					continue;
				var value = mSource.GetValue(at.Path, i);
				defer value.Dispose();
				if (value.Compare(byDefault) != 0) // an int and a float by value
					return true;
			}
		}
		for (let child in at.Children)
		{
			if (IsChanged(child))
				return true;
		}
		return false;
	}

	private bool SubtreeMatches(int node)
	{
		if (!mNodes[node].Info.Visible)
			return false;
		if (Matches(mNodes[node]))
			return true;
		for (let child in mNodes[node].Children)
		{
			if (SubtreeMatches(child))
				return true;
		}
		return false;
	}

	// `filtered`: only what matches, and what holds it, shows (an ancestor matched clears it).
	private void AddRows(List<PropertyRow> rows, int index, int32 depth, bool filtered, PropertyNode parent = null)
	{
		let node = mNodes[index];
		if (!node.Info.Visible)
			return;
		let matches = !filtered || Matches(node);
		if (!matches && !SubtreeMatches(index))
			return;
		let row = new PropertyRow();
		row.Path.Set(node.Path);
		row.Info.Set(node.Info);
		row.Depth = depth;
		// A group has no editor unless a hint asks for one (a Float3), which may be none; an editor
		// covering the children shows them on this row, so none go under it.
		row.Type = ((node.Info.Kind == .Group) && (node.Info.Hint.Length == 0)) ? cGroupRow : mEditors.Choose(node.Info);
		if ((row.Type == PropertyEditorRegistry.cNoEditor) && (node.Info.Kind == .Group) && !node.Children.IsEmpty)
			row.Type = cGroupRow; // a hint no editor takes: its own rows, if it has any
		let covered = mEditors.CoversChildren(row.Type);
		let holds = (node.Info.Kind == .Group) || (node.Info.Kind == .List);
		row.HasChildren = holds && !node.Children.IsEmpty && !covered;
		if ((parent != null) && (parent.Info.Kind == .List))
		{
			row.Element = true;
			row.ListOps = parent.Info.ReadOnly ? 0 : parent.Info.ListOps;
			row.Count = parent.Children.Count;
			for (int i = 0; i < parent.Children.Count; ++i)
			{
				if (parent.Children[i] == index)
					row.Index = i;
			}
		}
		row.Open = row.HasChildren && (IsOpen(node.Path) || !matches);
		row.Id = HashBytes(node.Path.Ptr, node.Path.Length);
		row.Node = index;
		rows.Add(row);
		if (row.Open)
		{
			for (let child in node.Children)
				AddRows(rows, child, depth + 1, !matches, node);
		}
	}

	private void Fold()
	{
		let rows = new List<PropertyRow>();
		let filtered = mFilter.Length != 0;
		// The categories in the order they first come; what has none comes first, without a header.
		let categories = scope List<StringView>();
		for (let top in mTop)
		{
			let category = mNodes[top].Info.Category;
			if (category.Length == 0)
				AddRows(rows, top, 0, filtered);
			else
			{
				bool seen = false;
				for (let known in categories)
					seen = seen || (known == category);
				if (!seen)
					categories.Add(category);
			}
		}
		for (let category in categories)
		{
			let header = new PropertyRow();
			header.Path.Set("#");
			header.Path.Append(category);
			header.Info.Name.Set(category);
			header.Category = true;
			header.Type = cCategoryRow;
			header.Id = HashBytes(header.Path.Ptr, header.Path.Length);
			// A header over nothing shown (each of its rows hidden, or none matching) is left out.
			bool any = false;
			for (let top in mTop)
			{
				if ((mNodes[top].Info.Category == category) && (filtered ? SubtreeMatches(top) : mNodes[top].Info.Visible))
					any = true;
			}
			if (!any)
			{
				delete header;
				continue;
			}
			header.Open = IsOpen(header.Path) || filtered;
			let open = header.Open;
			rows.Add(header);
			if (open)
			{
				for (let top in mTop)
				{
					if (mNodes[top].Info.Category == category)
						AddRows(rows, top, 0, filtered);
				}
			}
		}
		mRows.SetRows(rows);
	}

	// An edit is open on `path` or on a part of it (a Float3's field).
	private bool IsUnderEdit(StringView path)
	{
		let edit = StringView(mEditPath);
		if ((edit.Length == 0) || (edit.Length < path.Length) || (edit.Substring(0, path.Length) != path))
			return false;
		return (edit.Length == path.Length) || (edit[path.Length] == '.');
	}

	private void EndOpenEdit()
	{
		if ((mEditPath.Length == 0) || (mSource == null))
			return;
		let path = scope String(mEditPath);
		mEditPath.Clear();
		mSource.CancelEdit(path);
	}
}
