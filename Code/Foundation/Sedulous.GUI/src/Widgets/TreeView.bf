using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// TreeView: a virtualised tree over a model (eepp's UITreeView in role). It flattens the open
// nodes into the items ItemView realises, so a huge tree costs only the rows in view. A row shows
// its indent, a disclosure chevron (the expander's) that opens and closes it, its icon where the
// model gives one (ModelRole.Icon, with ModelRole.IconClass a class on it, as a type's category
// tints it), and its text; ModelRole.RowClass gives the row classes of its own (a state).
// Expansion is a set of node ids, as the selection is, so both survive the flattening; closing a
// node that holds the selection selects the node. Right opens a node (or goes to its first
// child), Left closes it (or goes to its parent). In markup its children are nested
// `<TreeItem text="..." expanded="true" icon="..." icon-class="...">`s, which become a model of
// its own.

// A node's chevron: right when closed, down when open; a click opens or closes the node.
class TreeArrow : UIWidget
{
	private bool mExpanded = false;
	private Color mColor = .(0.80f, 0.84f, 0.90f, 1.0f);
	private delegate void() mOnClicked ~ delete _;

	public this()
	{
		Tag = "treearrow";
	}

	public bool Expanded
	{
		get => mExpanded;
		set
		{
			if (mExpanded != value)
			{
				mExpanded = value;
				Invalidate();
			}
		}
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnClicked(delegate void() callback)
	{
		delete mOnClicked;
		mOnClicked = callback;
	}

	// On the press (as a row selects on it), and taken: the row under it does not select.
	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		if (mOnClicked != null)
			mOnClicked();
	}

	// The click after the press is the chevron's too: a row that folds on a click of its own (a
	// property grid's header) would fold back what the press folded.
	protected override void OnMouseClick(MouseEvent e)
	{
		if (e.Button == .Left)
			e.Handled = true;
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		DrawDisclosure(ctx, LocalBounds, mExpanded, mColor, IsRightToLeft);
	}
}

// A tree row's content: its indent, its chevron, its icon (`treeicon`, when it has one) and its
// text (`treecell`).
class TreeRowContent : UIWidget
{
	private const float cIconGap = 4.0f;

	private TreeArrow mArrow ~ _.ReleaseRef();
	private Sedulous.GUI.Image mIcon = null ~ _?.ReleaseRef();
	private Sedulous.GUI.Label mLabel ~ _.ReleaseRef();
	private String mIconClass = new .() ~ delete _;
	private String mRowClasses = new .() ~ delete _; // the model's (RowClass)
	private float mIndent = 0.0f;
	private float mArrowSize = 16.0f;
	private float mIconSize = 0.0f; // none shown

	public this()
	{
		Tag = "treerowcontent";
		mArrow = new TreeArrow();
		AddChild(mArrow);
		mLabel = new Sedulous.GUI.Label();
		mLabel.Tag = "treecell";
		using (StyleWriteScope(mLabel)) // its own values, which a sheet returns to
		{
			mLabel.SetTextAlignment(.Start, .Middle);
			mLabel.HitTestVisible = false;
		}
		AddChild(mLabel);
	}

	public Sedulous.GUI.Label Label => mLabel;
	public TreeArrow Arrow => mArrow;
	/// Its icon, made when it first has one (none: null).
	public Sedulous.GUI.Image Icon => mIcon;

	public void Configure(float indent, float arrowSize, bool hasChildren, bool expanded)
	{
		mIndent = indent;
		mArrowSize = arrowSize;
		mArrow.Visible = hasChildren;
		mArrow.Expanded = expanded;
		RequestLayout();
	}

	/// Its icon: `source` an image's (empty: none), `iconClass` a class on it, `size` its square.
	public void SetIcon(StringView source, StringView iconClass, float size)
	{
		mIconSize = source.IsEmpty ? 0.0f : size;
		if (source.IsEmpty)
		{
			if (mIcon != null)
				mIcon.Displayed = false;
			RequestLayout();
			return;
		}
		if (mIcon == null)
		{
			mIcon = new Sedulous.GUI.Image();
			mIcon.Tag = "treeicon";
			mIcon.HitTestVisible = false;
			AddChildAt(mIcon, 1); // after the arrow, before the text
		}
		mIcon.Displayed = true;
		mIcon.Source = source; // the same source is not loaded again
		if (mIconClass != iconClass)
		{
			if (!mIconClass.IsEmpty)
				mIcon.RemoveClass(mIconClass);
			mIconClass.Set(iconClass);
			if (!mIconClass.IsEmpty)
				mIcon.AddClass(mIconClass);
		}
		RequestLayout();
	}

	/// Classes the model gives the row (space separated; empty: none), in place of those it gave
	/// before: a state a sheet styles (dimmed, a member of something).
	public void SetRowClasses(StringView classes)
	{
		if (mRowClasses == classes)
			return;
		RemoveClasses(mRowClasses);
		mRowClasses.Set(classes);
		AddClasses(mRowClasses);
	}

	public override Float2 MeasureContent(Float2 available)
	{
		let textX = TextStart;
		let text = mLabel.Measure(LayoutConstraints(.(0.0f, 0.0f), .(Math.Max(0.0f, available.X - textX), cUnbounded), .(-1.0f, -1.0f), false, false));
		return .(textX + text.X, Math.Max(Math.Max(text.Y, mArrowSize), mIconSize));
	}

	public override void OnLayout()
	{
		// Indented from the inline start, the arrow before the text.
		let @box = ContentBounds;
		let rtl = IsRightToLeft;
		mArrow.Arrange(Rect.MirroredIn(.(@box.X + mIndent, @box.Y, mArrowSize, @box.Height), @box, rtl));
		if ((mIcon != null) && (mIconSize > 0.0f))
		{
			let top = @box.Y + (@box.Height - mIconSize) * 0.5f;
			mIcon.Arrange(Rect.MirroredIn(.(@box.X + mIndent + mArrowSize + 2.0f, top, mIconSize, mIconSize), @box, rtl));
		}
		let textX = TextStart;
		mLabel.Arrange(Rect.MirroredIn(.(@box.X + textX, @box.Y, Math.Max(0.0f, @box.Width - textX - 2.0f), @box.Height), @box, rtl));
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mLabel);
	}

	// Where its text starts: after the indent, the arrow's column and its icon with a gap.
	private float TextStart => mIndent + mArrowSize + 2.0f + ((mIconSize > 0.0f) ? mIconSize + cIconGap : 0.0f);
}

/// A node of a tree written in markup: its text, whether it starts open, and its children.
[GuiReflect(true)]
class TreeItem : UIWidget
{
	private String mText = new .() ~ delete _;
	private String mIcon = new .() ~ delete _;
	private String mIconClass = new .() ~ delete _;
	private bool mExpanded = false;

	public this()
	{
		Tag = "treeitem";
		Displayed = false; // data, not drawn
	}

	public override bool SetMarkupAttribute(StringView name, StringView value)
	{
		if (name != "text")
			return base.SetMarkupAttribute(name, value);
		mText.Set(value);
		return true;
	}

	[GuiProperty]
	public StringView Text
	{
		get => mText;
		set => mText.Set(value);
	}

	/// Its icon: an image's source, and a class on it a sheet styles.
	[GuiProperty("icon")]
	public StringView Icon
	{
		get => mIcon;
		set => mIcon.Set(value);
	}

	[GuiProperty("icon-class")]
	public StringView IconClass
	{
		get => mIconClass;
		set => mIconClass.Set(value);
	}

	[GuiProperty("expanded")]
	public bool Expanded
	{
		get => mExpanded;
		set => mExpanded = value;
	}
}

[GuiReflect(true), Scriptable]
class TreeView : ItemView
{
	private struct FlatEntry
	{
		public ModelIndex Index;
		public Sedulous.GUI.ItemId Id;
		public int32 Depth;
		public bool HasChildren;

		public this(ModelIndex index, Sedulous.GUI.ItemId id, int32 depth, bool hasChildren)
		{
			Index = index;
			Id = id;
			Depth = depth;
			HasChildren = hasChildren;
		}
	}

	private List<FlatEntry> mFlat = new .() ~ delete _; // the open nodes, in display order
	private HashSet<Sedulous.GUI.ItemId> mExpanded = new .() ~ delete _; // the open nodes' ids
	private Dictionary<Sedulous.GUI.ItemId, int32> mItemOfId = new .() ~ delete _; // an id's flat item
	private float mIndentWidth = 16.0f;
	private float mWidest = 0.0f; // the widest row bound (NoteRowWidth)
	private IModel mWidestOf = null; // the model it was measured over: compared, never read through
	private float mArrowSize = 16.0f;
	private float mIconSize = 16.0f; // a row's icon's square
	private TreeModel mOwnTree = null; // markup's items; let go in the destructor
	private Node mMarkupHost = null ~ _?.ReleaseRef(); // where markup's items land, then taken in
	private bool mAdopting = false;

	public this()
	{
		Tag = "treeview";
		AccessRoleName = "tree"; // what a screen reader takes it for
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			TextColor = .(0.88f, 0.90f, 0.94f, 1.0f);
			// Sideways too, as a table across its columns: its rows are as wide as its widest
			// (RowWidth), and without it a row wider than the view was only cut at its edge.
			EditLayoutStyle(scope (s) => { s.OverflowX = .Auto; });
		}
	}

	// Its own model goes before the view's base would let go of it: let go first.
	public ~this()
	{
		Model = null;
		delete mOwnTree;
	}

	/// A level's indent (`indent-width`) and the column a row keeps for its arrow (`arrow-size`),
	/// the arrow drawn to fit it: a sheet sets them (an editor's density).
	[GuiProperty("indent-width"), Scriptable]
	public float IndentWidth
	{
		get => mIndentWidth;
		set
		{
			mIndentWidth = Math.Max(0.0f, value);
			ItemsChanged();
		}
	}

	[GuiProperty("arrow-size"), Scriptable]
	public float ArrowSize
	{
		get => mArrowSize;
		set
		{
			mArrowSize = Math.Max(0.0f, value);
			ItemsChanged();
		}
	}

	/// A row's icon's square (`icon-size`), where the model gives one.
	[GuiProperty("icon-size"), Scriptable]
	public float IconSize
	{
		get => mIconSize;
		set
		{
			mIconSize = Math.Max(0.0f, value);
			ItemsChanged();
		}
	}

	// Expansion by item (a visible row).
	[Scriptable]
	public void ExpandItem(int32 item)
	{
		SetExpanded(item, true);
	}

	[Scriptable]
	public void CollapseItem(int32 item)
	{
		SetExpanded(item, false);
	}

	public void ToggleItem(int32 item)
	{
		SetExpanded(item, !IsItemExpanded(item));
	}

	public bool IsItemExpanded(int32 item) => (item >= 0) && (item < (int32)mFlat.Count) && mExpanded.Contains(mFlat[item].Id);
	public int32 ItemDepth(int32 item) => ((item >= 0) && (item < (int32)mFlat.Count)) ? mFlat[item].Depth : 0;

	/// Expansion by node id (open or not, shown or not).
	public bool IsIdExpanded(Sedulous.GUI.ItemId id) => mExpanded.Contains(id);

	public void SetIdExpanded(Sedulous.GUI.ItemId id, bool expanded)
	{
		if (expanded)
			mExpanded.Add(id);
		else
			mExpanded.Remove(id);
		Reflatten();
		ItemsChanged();
	}

	/// Markup's children are its items (nested TreeItems), made into a model of its own.
	public override Node ChildHost
	{
		get
		{
			if (mMarkupHost == null)
				mMarkupHost = new MarkupChildHost(new (host) => { AdoptItems(host); });
			return mMarkupHost;
		}
	}

	protected override int ItemCount() => mFlat.Count;
	protected override ModelIndex ItemToModelIndex(int32 item) => ((item >= 0) && (item < (int32)mFlat.Count)) ? mFlat[item].Index : ModelIndex();
	protected override Sedulous.GUI.ItemId ItemIdAt(int32 item) => ((item >= 0) && (item < (int32)mFlat.Count)) ? mFlat[item].Id : NoItem;
	protected override int32 ItemOfId(Sedulous.GUI.ItemId id) => mItemOfId.TryGetValue(id, let item) ? item : -1;
	protected override bool IsFlat => false;

	// A drag resting on a closed node opens it.
	protected override bool OnDragHoverOpen(Float2 local)
	{
		let item = ItemAt(ConvertToWorldSpace(local));
		if ((item < 0) || !mFlat[item].HasChildren || IsItemExpanded(item))
			return false;
		ExpandItem(item);
		return true;
	}

	protected override void OnModelChanged()
	{
		Reflatten();
	}

	protected override StringView RowTag => "treerow";

	protected override Node CreateContent(uint32 type)
	{
		let content = new TreeRowContent();
		content.Arrow.SetOnClicked(new () =>
			{
				if (let row = content.Parent as ItemRow)
					ToggleItem(row.ItemIndex);
			});
		return content;
	}

	protected override void BindContent(Node content, int32 item, ModelIndex index)
	{
		let entry = mFlat[item];
		let row = (TreeRowContent)content;
		let text = scope String();
		Model.Data(index).ToString(text);
		row.Label.Text = text;
		let icon = scope String();
		Model.Data(index, .Icon).ToString(icon);
		let iconClass = scope String();
		Model.Data(index, .IconClass).ToString(iconClass);
		row.SetIcon(icon, iconClass, mIconSize);
		let rowClasses = scope String();
		Model.Data(index, .RowClass).ToString(rowClasses);
		row.SetRowClasses(rowClasses);
		row.Configure((float)entry.Depth * mIndentWidth, mArrowSize, entry.HasChildren, mExpanded.Contains(entry.Id));
		NoteRowWidth(content);
	}

	// Rows as wide as the widest one bound, or the view when it is wider: a deep level or a long
	// name scrolls sideways, where it had been cut at the view's edge.
	protected override float RowWidth(float width) => Math.Max(width, mWidest);

	// The rows in view measured again once placed: one bound before the sheet reached it (a row
	// just made has no font yet, its name no width) is measured as it is drawn.
	protected override void OnLayoutDecorations()
	{
		for (let row in LiveRows)
			NoteRowWidth(row);
	}

	// The arrow toward the inline end (Right, Left in right to left) opens a node, or on an open
	// one goes to its first child; toward the start closes an open one, or goes to its parent.
	protected override bool OnExtraKey(KeyCode key, uint32 modifiers)
	{
		let item = CurrentItem;
		if ((modifiers != 0) || (item < 0) || (item >= (int32)mFlat.Count))
			return false;
		let entry = mFlat[item];
		let along = InlineStep(key);
		if ((along > 0) && entry.HasChildren)
		{
			if (!IsItemExpanded(item))
				ExpandItem(item);
			else
			{
				SelectByUser(item + 1, 0);
				ScrollToItem(item + 1);
			}
			return true;
		}
		if (along < 0)
		{
			if (entry.HasChildren && IsItemExpanded(item))
			{
				CollapseItem(item);
				return true;
			}
			let parent = ParentItem(item);
			if (parent >= 0)
			{
				SelectByUser(parent, 0);
				ScrollToItem(parent);
				return true;
			}
		}
		return false;
	}

	private void AdoptItems(Node host)
	{
		if (mAdopting)
			return;
		mAdopting = true;
		if (mOwnTree == null)
			mOwnTree = new TreeModel();
		while (host.ChildCount != 0)
		{
			let child = host.GetChildAt(0);
			child.AddRef(); // held across its move
			host.RemoveChild(child);
			if (let item = child as TreeItem)
				AddItem(item, TreeModel.Root);
			child.ReleaseRef();
		}
		mAdopting = false;
		if (Model != mOwnTree)
			Model = mOwnTree;
		Reflatten();
		ItemsChanged();
	}

	private void AddItem(TreeItem item, int32 parent)
	{
		let id = mOwnTree.AddNode(parent, item.Text);
		if (!item.Icon.IsEmpty)
			mOwnTree.SetIcon(id, item.Icon, item.IconClass);
		if (item.Expanded)
			mExpanded.Add((Sedulous.GUI.ItemId)id);
		for (int i = 0; i < item.ChildCount; ++i)
		{
			if (let child = item.GetChildAt(i) as TreeItem)
				AddItem(child, id);
		}
	}

	private void SetExpanded(int32 item, bool expanded)
	{
		if ((item < 0) || (item >= (int32)mFlat.Count))
			return;
		let id = mFlat[item].Id;
		if (expanded == mExpanded.Contains(id))
			return;
		if (expanded)
			mExpanded.Add(id);
		else
		{
			// Closing a node that holds the keyboard's row moves it, selected, to the node.
			let current = CurrentItem;
			let holdsCurrent = (current > item) && IsUnder(current, item);
			mExpanded.Remove(id);
			if (holdsCurrent)
				SelectedItem = item;
		}
		Reflatten();
		ItemsChanged();
	}

	// Whether flat item `item` lies under flat item `ancestor`.
	private bool IsUnder(int32 item, int32 ancestor)
	{
		let depth = mFlat[ancestor].Depth;
		for (int32 i = ancestor + 1; i < (int32)mFlat.Count; ++i)
		{
			if (mFlat[i].Depth <= depth)
				return false;
			if (i == item)
				return true;
		}
		return false;
	}

	private int32 ParentItem(int32 item)
	{
		let depth = mFlat[item].Depth;
		for (int32 i = item - 1; i >= 0; --i)
		{
			if (mFlat[i].Depth < depth)
				return i;
		}
		return -1;
	}

	// The widest row bound so far, kept while the model is the same one (a model built again on
	// each change, the hierarchy's, would else snap the sideways scroll back as rows rebind).
	private void NoteRowWidth(Node content)
	{
		if (Model !== mWidestOf)
		{
			mWidestOf = Model;
			mWidest = 0.0f;
		}
		let row = (content is ItemRow) ? content : ((content.Parent != null) ? content.Parent : content); // the row's own padding too
		let width = row.Measure(LayoutConstraints()).X;
		if (width > mWidest + 0.5f)
		{
			mWidest = width;
			RequestLayout();
		}
	}

	private void Reflatten()
	{
		mFlat.Clear();
		mItemOfId.Clear();
		if (Model != null)
			FlattenLevel(ModelIndex(), 0);
	}

	private void FlattenLevel(ModelIndex parent, int32 depth)
	{
		let model = Model;
		let rows = model.RowCount(parent);
		for (int r = 0; r < rows; ++r)
		{
			let index = model.Index((int32)r, 0, parent);
			let id = model.IdOf(index);
			let hasChildren = model.HasChildren(index);
			mItemOfId[id] = (int32)mFlat.Count;
			mFlat.Add(FlatEntry(index, id, depth, hasChildren));
			if (hasChildren && mExpanded.Contains(id))
				FlattenLevel(index, depth + 1);
		}
	}
}
