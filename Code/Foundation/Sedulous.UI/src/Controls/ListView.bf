using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// A virtualised list: only the rows that can be seen exist as views.
///
/// Rows scrolling out are recycled into a pool and come back bound to new positions, so a list
/// of ten thousand costs a screenful of views rather than ten thousand. Fixed row heights are
/// O(1) to index; variable ones are found by binary search over a cumulative offset table.
///
/// The adapter is BORROWED: the caller owns it and outlives the list.
class ListView : ViewGroup, IListAdapterObserver
{
	/// A wheel notch moves this many rows.
	private const float WheelRows = 2.0f;
	private const float WheelMomentum = 200.0f;
	private const float DragMomentum = 60.0f;

	public SelectionModel Selection = new .() ~ delete _;
	public Property<float> ItemHeight = new .(30.0f) ~ delete _;

	/// (position, clickCount, localX, localY)
	public Event<delegate void(int32, int32, float, float)> OnItemClicked ~ _.Dispose();
	/// (position, localX, localY)
	public Event<delegate void(int32, float, float)> OnItemRightClicked ~ _.Dispose();
	public Event<delegate void(int32)> OnItemLongPress ~ _.Dispose();
	/// (localX, localY)
	public Event<delegate void(float, float)> OnBackgroundRightClicked ~ _.Dispose();
	/// (position, args). Marking the args handled suppresses the list's own key handling.
	public Event<delegate void(int32, KeyEventArgs)> OnItemKeyDown ~ _.Dispose();

	public float LongPressTime = 0.5f;

	/// BORROWED.
	private IListAdapter mAdapter = null;
	private ViewRecycler mRecycler = new .() ~ delete _;
	private float mScrollY = 0.0f;
	private MomentumHelper mMomentum = .();

	/// OWNED: a row's reference lives here between being taken from the pool and going back.
	private Dictionary<int32, View> mActiveViews = new .() ~ delete _;
	private int32 mFirstVisible = -1;
	private int32 mLastVisible = -1;

	/// Cumulative row tops, one per row plus a final total. Only built when the rows differ.
	private List<float> mItemOffsets = new .() ~ delete _;
	private bool mVariableHeight = false;
	private float mTotalContentHeight = 0.0f;

	/// OWNED, and a VISUAL child rather than a logical one.
	private ScrollBar mScrollBar;
	private bool mScrollBarVisible = false;

	private bool mDragging = false;
	private float mDragLastY = 0.0f;

	private int32 mPressedItem = -1;
	private float mPressTime = 0.0f;
	private bool mLongPressFired = false;

	public this()
	{
		ClipsContent = true;
		IsFocusable = true;
		IsTabStop = true;
		// The arrows move the selection, so focus must not spend them on moving away.
		WantsArrowKeys = true;
		ItemHeight.SetOwner(this);

		mScrollBar = new ScrollBar(false);
		mScrollBar.Parent = this;
		mScrollBar.OnValueChanged.Add(new (bar, val) =>
			{
				mScrollY = val;
				Invalidate();
			});
	}

	public ~this()
	{
		// The pool and the active rows both hold references, and both have to go before the
		// recycler's own storage does.
		RecycleAllActive();
		mRecycler.Clear();

		if (mScrollBar.Context != null)
			mScrollBar.Context.DetachView(mScrollBar);
		mScrollBar.Parent = null;
		mScrollBar.ReleaseRef();
	}

	// ---- Adapter ----------------------------------------------------------------------------

	/// Borrowed; may be null.
	public IListAdapter Adapter => mAdapter;

	/// BORROWS the adapter. The caller owns it and must outlive the list.
	public void SetAdapter(IListAdapter adapter)
	{
		if (mAdapter != null)
			mAdapter.SetObserver(null);

		mAdapter = adapter;

		if (mAdapter != null)
			mAdapter.SetObserver(this);

		RebuildOffsets();
		RecycleAllActive();
		Invalidate();
	}

	public float ScrollY => mScrollY;
	public ViewRecycler Recycler => mRecycler;

	/// The rows that currently exist, by position. Borrowed.
	public View GetActiveView(int32 position)
	{
		if (mActiveViews.TryGetValue(position, let view))
			return view;

		return null;
	}

	public int32 FirstVisible => mFirstVisible;
	public int32 LastVisible => mLastVisible;

	// ---- Scrolling --------------------------------------------------------------------------

	public float MaxScrollY
	{
		get
		{
			let contentHeight = ContentHeight;
			let viewportHeight = Height - Padding.TotalVertical;
			return Max(0.0f, contentHeight - viewportHeight);
		}
	}

	private float ContentHeight
	{
		get
		{
			if (mVariableHeight)
				return mTotalContentHeight;

			return (mAdapter != null) ? mAdapter.ItemCount * ItemHeight.Value : 0.0f;
		}
	}

	public void ScrollBy(float dy)
	{
		mScrollY = Clamp(mScrollY + dy, 0.0f, MaxScrollY);
		Invalidate();
	}

	/// Scrolls the least that brings a row fully into view.
	public void ScrollToPosition(int32 position)
	{
		if ((mAdapter == null) || (position < 0) || (position >= mAdapter.ItemCount))
			return;

		let itemTop = GetItemOffset(position);
		let itemBottom = itemTop + GetItemHeightAt(position);
		let viewportHeight = Height - Padding.TotalVertical;

		if (itemTop < mScrollY)
			mScrollY = itemTop;
		else if (itemBottom > mScrollY + viewportHeight)
			mScrollY = itemBottom - viewportHeight;

		mScrollY = Clamp(mScrollY, 0.0f, MaxScrollY);
		Invalidate();
	}

	/// The adapter position at a local Y, which may be past the end.
	public int32 GetItemAtY(float localY)
	{
		let scrolledY = localY + mScrollY - Padding.Top;
		if (mVariableHeight)
			return FindFirstVisible(scrolledY);

		return (int32)(scrolledY / ItemHeight.Value);
	}

	// ---- Data changes -----------------------------------------------------------------------

	/// Rebuilds everything after the data changed underneath.
	public void NotifyDataChanged()
	{
		RebuildOffsets();
		RecycleAllActive();

		// The selection is POSITIONAL, so indices past the new count are dropped: a shrunken
		// list would otherwise leave a stale index quietly highlighting whichever row
		// inherited it.
		Selection.PruneFrom((mAdapter != null) ? mAdapter.ItemCount : 0);
		Invalidate();
	}

	public void OnDataSetChanged() => NotifyDataChanged();

	/// A range changed in place, so the rows showing it are rebound where they exist. Cheaper
	/// than a full rebuild, which is the whole point of the narrower notification.
	public void OnItemRangeChanged(int32 start, int32 count)
	{
		if (mAdapter == null)
			return;

		for (int32 position = start; position < start + count; position++)
		{
			if (mActiveViews.TryGetValue(position, let view))
				mAdapter.BindView(view, position);
		}

		// A variable height row may have changed height, which moves everything after it.
		if (mVariableHeight)
		{
			RebuildOffsets();
			Invalidate();
		}
	}

	// ---- Visual children --------------------------------------------------------------------

	public override int VisualChildCount => mActiveViews.Count + 1;

	public override View GetVisualChild(int index)
	{
		if (index == mActiveViews.Count)
			return mScrollBar;

		if ((index < 0) || (index > mActiveViews.Count))
			return null;

		var i = 0;
		for (let pair in mActiveViews)
		{
			if (i == index)
				return pair.value;
			i++;
		}

		return null;
	}

	// ---- Input ------------------------------------------------------------------------------

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (MaxScrollY <= 0)
			return;

		ScrollBy(-e.DeltaY * ItemHeight.Value * WheelRows);
		mMomentum.VelocityY = -e.DeltaY * WheelMomentum;
		e.Handled = true;
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		let local = ScreenToLocal(MouseScreenPos());

		// A click into the list takes focus, so the arrows and the item keys follow it. A row
		// that keeps focus itself, an editing label being the case, marks its own press
		// handled and never reaches here.
		if (Context != null)
			Context.GetFocusManager().SetFocus(this);

		if ((e.Button == .Left) && (MaxScrollY > 0))
		{
			mDragging = true;
			mDragLastY = local.Y;
			if (Context != null)
				Context.GetFocusManager().SetCapture(this);
		}

		if (mAdapter == null)
			return;

		if (e.Button == .Right)
		{
			HandleRightClick(local);
			e.Handled = true;
			return;
		}

		if (e.Button == .Left)
		{
			HandleLeftClick(local, e);
			e.Handled = true;
		}
	}

	private void HandleRightClick(Float2 local)
	{
		let position = GetItemAtY(local.Y);
		if ((position < 0) || (position >= mAdapter.ItemCount))
		{
			OnBackgroundRightClicked(local.X, local.Y);
			return;
		}

		// A right click on an UNSELECTED row selects it first, so the menu that follows acts on
		// what was clicked rather than on whatever happened to be selected.
		if (!Selection.IsSelected(position))
			Selection.Select(position);

		OnItemRightClicked(position, local.X, local.Y);
	}

	private void HandleLeftClick(Float2 local, MouseEventArgs e)
	{
		let position = GetItemAtY(local.Y);
		if ((position < 0) || (position >= mAdapter.ItemCount))
			return;

		if (e.Modifiers.HasFlag(.Ctrl))
			Selection.Toggle(position);
		else if (e.Modifiers.HasFlag(.Shift))
			Selection.SelectRange(Selection.FirstSelected(), position);
		else
			Selection.Select(position);

		OnItemClicked(position, e.ClickCount, local.X, local.Y);

		mPressedItem = position;
		mPressTime = 0;
		mLongPressFired = false;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (!mDragging)
			return;

		// A drag and drop taking over the same gesture WINS: otherwise the list scrolls under
		// the drag and the drop lands on the wrong row.
		if ((Context != null) && Context.DragDrop.IsDragging)
		{
			mDragging = false;
			mMomentum.VelocityY = 0;
			Context.GetFocusManager().ReleaseCapture();
			return;
		}

		let local = ScreenToLocal(MouseScreenPos());
		let dy = mDragLastY - local.Y;

		// A dead zone of a pixel, so a click that trembles does not scroll.
		if (Abs(dy) > 1)
		{
			ScrollBy(dy);
			mMomentum.VelocityY = dy * DragMomentum;
			mDragLastY = local.Y;
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDragging)
		{
			mDragging = false;
			if (Context != null)
				Context.GetFocusManager().ReleaseCapture();
		}

		mPressedItem = -1;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (mAdapter == null)
			return;

		let selected = Selection.FirstSelected();
		let count = mAdapter.ItemCount;

		// The row gets FIRST refusal, so a consumer can bind F2 or Delete without the list
		// having to know about them.
		if (selected >= 0)
		{
			OnItemKeyDown(selected, e);
			if (e.Handled)
				return;
		}

		let page = (int32)(Height / ItemHeight.Value);

		switch (e.Key)
		{
		case .Down:
			MoveSelection(selected, Min(selected + 1, count - 1), e);
		case .Up:
			MoveSelection(selected, Max(selected - 1, 0), e);
		case .Home:
			MoveSelection(selected, 0, e);
		case .End:
			MoveSelection(selected, count - 1, e);
		case .PageDown:
			MoveSelection(selected, Min(selected + page, count - 1), e);
		case .PageUp:
			MoveSelection(selected, Max(selected - page, 0), e);
		default:
		}
	}

	/// Shift EXTENDS from where the selection was; without it the selection moves outright.
	private void MoveSelection(int32 from, int32 to, KeyEventArgs e)
	{
		if (e.Modifiers.HasFlag(.Shift))
			Selection.SelectRange(from, to);
		else
			Selection.Select(to);

		ScrollToPosition(to);
		e.Handled = true;
	}

	// ---- Layout -----------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let desiredHeight = ContentHeight + Padding.TotalVertical;

		// A list scrolls its own content, so it never needs an unbounded width: under an
		// unbounded parent it takes a default rather than FloatMax.
		MeasuredSize = .(constraints.ConstrainWidth(constraints.BoundedMaxWidth(300.0f)),
			constraints.ConstrainHeight(desiredHeight));

		mScrollBarVisible = MaxScrollY > 0;
		mScrollBar.Visibility = mScrollBarVisible ? .Visible : .Gone;
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mAdapter == null)
			return;

		let viewportHeight = height - Padding.TotalVertical;
		let viewportWidth = width - Padding.TotalHorizontal -
			(mScrollBarVisible ? mScrollBar.BarThickness : 0.0f);

		mScrollY = Clamp(mScrollY, 0.0f, MaxScrollY);

		if (mAdapter.ItemCount == 0)
		{
			mScrollBarVisible = false;
			mScrollBar.Visibility = .Gone;
			RecycleOutOfRange(0, -1);
			return;
		}

		if ((Context != null) && (mScrollBar.Context == null))
			Context.AttachView(mScrollBar);

		let firstVisible = FindFirstVisible(mScrollY);
		let lastVisible = FindLastVisible(firstVisible, viewportHeight);

		// Recycled BEFORE the new rows are taken, so the pool has them to hand out.
		RecycleOutOfRange(firstVisible, lastVisible);

		for (int32 position = firstVisible; position <= lastVisible; position++)
			LayoutRow(position, viewportWidth);

		mFirstVisible = firstVisible;
		mLastVisible = lastVisible;

		if (mScrollBarVisible)
			LayoutScrollBar(width, viewportHeight);
	}

	private int32 FindLastVisible(int32 firstVisible, float viewportHeight)
	{
		var last = firstVisible;
		var y = GetItemOffset(firstVisible) - mScrollY;

		for (int32 position = firstVisible; position < mAdapter.ItemCount; position++)
		{
			if (y > viewportHeight)
				break;

			last = position;
			y += GetItemHeightAt(position);
		}

		return last;
	}

	private void LayoutRow(int32 position, float viewportWidth)
	{
		if (!mActiveViews.ContainsKey(position))
		{
			let view = mRecycler.GetOrCreate(mAdapter, position);
			view.Parent = this;
			if (Context != null)
				Context.AttachView(view);

			mActiveViews[position] = view;
		}

		// Rows already active are NOT rebound here. GetOrCreate binds on acquire, and every
		// data change path rebinds already: in place for a range, by recycling everything for
		// a whole reset. Rebinding per layout meant every visible row rebound every frame.
		let view = mActiveViews[position];
		let itemY = Padding.Top + GetItemOffset(position) - mScrollY;
		let itemHeight = GetItemHeightAt(position);

		view.Measure(BoxConstraints.Tight(viewportWidth, itemHeight));
		view.Layout(Padding.Left, itemY, viewportWidth, itemHeight);
	}

	private void LayoutScrollBar(float width, float viewportHeight)
	{
		mScrollBar.Value = mScrollY;
		mScrollBar.MaxValue = MaxScrollY;
		mScrollBar.ViewportSize = viewportHeight;
		mScrollBar.Measure(BoxConstraints.Tight(mScrollBar.BarThickness, viewportHeight));
		mScrollBar.Layout(width - mScrollBar.BarThickness, Padding.Top, mScrollBar.BarThickness,
			viewportHeight);
	}

	// ---- Draw -------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		let deltaTime = (Context != null) ? Context.DeltaTime : 0.016f;

		let drift = mMomentum.Update(deltaTime);
		if (drift.Y != 0)
			ScrollBy(drift.Y);

		UpdateLongPress(deltaTime);
		DrawSelection(ctx);
		DrawChildren(ctx);
	}

	/// A press held still for long enough is a long press. Driven from the draw, which keeps
	/// asking for frames while the timer is arming so it can actually reach the threshold.
	private void UpdateLongPress(float deltaTime)
	{
		if ((mPressedItem < 0) || mLongPressFired || mDragging)
			return;

		mPressTime += deltaTime;
		if (mPressTime >= LongPressTime)
		{
			mLongPressFired = true;
			OnItemLongPress(mPressedItem);
		}

		Invalidate();
	}

	/// Selection is painted by the LIST, under the rows, so an adapter's views need know
	/// nothing about being selected.
	private void DrawSelection(UIDrawContext ctx)
	{
		if (mAdapter == null)
			return;

		let color = ResolveStyleColor(.SelectionColor,
			Color(60 / 255.0f, 120 / 255.0f, 200 / 255.0f, 80 / 255.0f));
		let radius = ResolveStyleFloat(.CornerRadius, 0.0f);

		for (let pair in mActiveViews)
		{
			if (!Selection.IsSelected(pair.key))
				continue;

			let view = pair.value;
			let rect = Rectangle(view.Bounds.X, view.Bounds.Y, view.Width, view.Height);
			if (radius > 0)
				ctx.VG.FillRoundedRect(rect, radius, color);
			else
				ctx.VG.FillRect(rect, color);
		}
	}

	// ---- Offsets ----------------------------------------------------------------------------

	/// Builds the cumulative offset table, and notices whether any row asked for its own height.
	private void RebuildOffsets()
	{
		mItemOffsets.Clear();
		mVariableHeight = false;
		mTotalContentHeight = 0;

		if (mAdapter == null)
			return;

		let count = mAdapter.ItemCount;
		mItemOffsets.Reserve(count + 1);

		var offset = 0.0f;
		for (int32 i = 0; i < count; i++)
		{
			mItemOffsets.Add(offset);

			// A height of nought means "use the list's", so a mostly uniform list with one odd
			// row still gets the table.
			let height = mAdapter.GetItemHeight(i);
			if (height > 0)
			{
				mVariableHeight = true;
				offset += height;
			}
			else
			{
				offset += ItemHeight.Value;
			}
		}

		// The final entry is the total, which is what makes the table one longer than the list.
		mItemOffsets.Add(offset);
		mTotalContentHeight = offset;
	}

	private float GetItemOffset(int32 position)
	{
		if (mVariableHeight && (position < mItemOffsets.Count))
			return mItemOffsets[position];

		return position * ItemHeight.Value;
	}

	private float GetItemHeightAt(int32 position)
	{
		if (mVariableHeight && (mAdapter != null))
		{
			let height = mAdapter.GetItemHeight(position);
			if (height > 0)
				return height;
		}

		return ItemHeight.Value;
	}

	/// Uniform rows divide; varied ones binary search the offset table.
	private int32 FindFirstVisible(float scrollY)
	{
		if (!mVariableHeight || (mItemOffsets.Count <= 1))
			return (int32)(scrollY / ItemHeight.Value);

		int32 lo = 0;
		int32 hi = (int32)mItemOffsets.Count - 2;
		while (lo < hi)
		{
			let mid = (lo + hi + 1) / 2;
			if (mItemOffsets[mid] <= scrollY)
				lo = mid;
			else
				hi = mid - 1;
		}

		return lo;
	}

	// ---- Recycling --------------------------------------------------------------------------

	private void RecycleOutOfRange(int32 first, int32 last)
	{
		// Collected first: the map cannot be written while it is being walked.
		let toRemove = scope List<int32>();
		for (let pair in mActiveViews)
		{
			if ((pair.key < first) || (pair.key > last))
				toRemove.Add(pair.key);
		}

		for (let position in toRemove)
		{
			let view = mActiveViews[position];
			mActiveViews.Remove(position);
			RecycleRow(view, position);
		}
	}

	private void RecycleAllActive()
	{
		for (let pair in mActiveViews)
			RecycleRow(pair.value, pair.key);

		mActiveViews.Clear();
	}

	/// CONSUMES the row's reference, handing it to the pool.
	private void RecycleRow(View view, int32 position)
	{
		let viewType = (mAdapter != null) ? mAdapter.GetItemViewType(position) : 0;

		// Detached by hand, because a row is a visual child that was attached by hand: a view
		// released while still registered leaves the context holding a dangling pointer.
		if (view.Context != null)
			view.Context.DetachView(view);

		view.Parent = null;
		mRecycler.Recycle(view, viewType);
	}

	private Float2 MouseScreenPos()
	{
		if ((Context == null) || (Context.GetInputManager() == null))
			return .Zero;

		let input = Context.GetInputManager();
		return .(input.MouseX, input.MouseY);
	}
}
