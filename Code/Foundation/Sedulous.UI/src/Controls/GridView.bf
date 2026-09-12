using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// A virtualised grid of fixed cells: items flow left to right and wrap, and only the rows that
/// can be seen exist as views.
///
/// The same machinery as ListView, laid out in two dimensions. The column count follows the
/// width, so the grid reflows rather than scrolling sideways.
///
/// The adapter is BORROWED: the caller owns it and outlives the grid.
class GridView : ViewGroup, IListAdapterObserver
{
	/// A wheel notch moves this many rows.
	private const float WheelRows = 2.0f;
	private const float WheelMomentum = 200.0f;

	public SelectionModel Selection = new .() ~ delete _;
	public Property<float> CellWidth = new .(60.0f) ~ delete _;
	public Property<float> CellHeight = new .(60.0f) ~ delete _;
	public Property<float> CellSpacing = new .(4.0f) ~ delete _;

	/// (position, clickCount, localX, localY)
	public Event<delegate void(int32, int32, float, float)> OnItemClicked ~ _.Dispose();
	/// (position, localX, localY)
	public Event<delegate void(int32, float, float)> OnItemRightClicked ~ _.Dispose();
	/// A right click on empty space, for a menu on the container itself.
	public Event<delegate void(float, float)> OnBackgroundRightClicked ~ _.Dispose();
	/// (position, args). Offered before the grid's own navigation, as ListView does.
	public Event<delegate void(int32, KeyEventArgs)> OnItemKeyDown ~ _.Dispose();

	/// BORROWED.
	private IListAdapter mAdapter = null;
	private ViewRecycler mRecycler = new .() ~ delete _;
	private float mScrollY = 0.0f;
	private MomentumHelper mMomentum = .();

	/// OWNED.
	private Dictionary<int32, View> mActiveViews = new .() ~ delete _;
	/// OWNED, and a VISUAL child rather than a logical one.
	private ScrollBar mScrollBar;
	private bool mScrollBarVisible = false;

	private int32 mColumnsCount = 1;
	private int32 mRowCount = 0;
	private float mTotalContentHeight = 0.0f;

	public this()
	{
		ClipsContent = true;
		IsFocusable = true;
		IsTabStop = true;
		// The arrows move the selection, so focus must not spend them on moving away.
		WantsArrowKeys = true;

		CellWidth.SetOwner(this);
		CellHeight.SetOwner(this);
		CellSpacing.SetOwner(this);

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

	/// BORROWS the adapter. The caller owns it and must outlive the grid.
	public void SetAdapter(IListAdapter adapter)
	{
		if (mAdapter != null)
			mAdapter.SetObserver(null);

		mAdapter = adapter;

		if (mAdapter != null)
			mAdapter.SetObserver(this);

		// The selection is positional, so a smaller adapter has to drop the indices past its
		// end here for the same reason a shrunken data set does.
		Selection.PruneFrom((mAdapter != null) ? mAdapter.ItemCount : 0);
		RecycleAllActive();
		Invalidate();
	}

	public float ScrollY => mScrollY;
	public ViewRecycler Recycler => mRecycler;
	public int32 ColumnsCount => mColumnsCount;
	public int32 RowCount => mRowCount;

	/// The cell that currently exists for a position, or null.
	public View GetActiveView(int32 position)
	{
		if (mActiveViews.TryGetValue(position, let view))
			return view;

		return null;
	}

	// ---- Scrolling --------------------------------------------------------------------------

	public float MaxScrollY => Max(0.0f, mTotalContentHeight - (Height - Padding.TotalVertical));

	public void ScrollBy(float dy)
	{
		mScrollY = Clamp(mScrollY + dy, 0.0f, MaxScrollY);
		Invalidate();
	}

	/// Scrolls the least that brings a cell's ROW fully into view.
	public void ScrollToPosition(int32 position)
	{
		if ((mAdapter == null) || (mColumnsCount <= 0) || (position < 0))
			return;

		let rowY = (position / mColumnsCount) * RowStride;
		let viewportHeight = Height - Padding.TotalVertical;

		if (rowY < mScrollY)
			mScrollY = rowY;
		else if (rowY + CellHeight.Value > mScrollY + viewportHeight)
			mScrollY = rowY + CellHeight.Value - viewportHeight;

		mScrollY = Clamp(mScrollY, 0.0f, MaxScrollY);
		Invalidate();
	}

	/// The adapter position at a local point, or -1 for none.
	public int32 GetItemAtPoint(float localX, float localY)
	{
		if (mColumnsCount <= 0)
			return -1;

		let column = (int32)((localX - Padding.Left) / (CellWidth.Value + CellSpacing.Value));
		let row = (int32)((localY + mScrollY - Padding.Top) / RowStride);

		// A point past the last COLUMN is not the first cell of the next row.
		if ((column < 0) || (column >= mColumnsCount))
			return -1;

		let position = row * mColumnsCount + column;
		if ((mAdapter != null) && (position >= mAdapter.ItemCount))
			return -1;

		return position;
	}

	// ---- Data changes -----------------------------------------------------------------------

	public void OnDataSetChanged()
	{
		RecycleAllActive();

		// DIVERGES from Raptor, which recycles and stops. The selection is positional, and a
		// shrunken data set otherwise leaves a stale index quietly highlighting whichever cell
		// inherits it. Raptor's ListView prunes here for exactly that reason; its GridView was
		// not given the same treatment.
		Selection.PruneFrom((mAdapter != null) ? mAdapter.ItemCount : 0);
		Invalidate();
	}

	/// A range changed in place, so the cells showing it are rebound where they exist.
	public void OnItemRangeChanged(int32 start, int32 count)
	{
		if (mAdapter == null)
			return;

		for (int32 position = start; position < start + count; position++)
		{
			if (mActiveViews.TryGetValue(position, let view))
				mAdapter.BindView(view, position);
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

		ScrollBy(-e.DeltaY * RowStride * WheelRows);
		mMomentum.VelocityY = -e.DeltaY * WheelMomentum;
		e.Handled = true;
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (mAdapter == null)
			return;

		let position = GetItemAtPoint(e.X, e.Y);

		if (e.Button == .Right)
		{
			HandleRightClick(position, e);
			e.Handled = true;
			return;
		}

		if (e.Button == .Left)
		{
			HandleLeftClick(position, e);
			e.Handled = true;
		}
	}

	private void HandleRightClick(int32 position, MouseEventArgs e)
	{
		if ((position < 0) || (position >= mAdapter.ItemCount))
		{
			OnBackgroundRightClicked(e.X, e.Y);
			return;
		}

		// A right click on an UNSELECTED cell selects it first, so the menu that follows acts
		// on what was clicked.
		if (!Selection.IsSelected(position))
			Selection.Select(position);

		OnItemRightClicked(position, e.X, e.Y);
	}

	private void HandleLeftClick(int32 position, MouseEventArgs e)
	{
		if ((position < 0) || (position >= mAdapter.ItemCount))
			return;

		if (e.Modifiers.HasFlag(.Ctrl))
			Selection.Toggle(position);
		else if (e.Modifiers.HasFlag(.Shift))
			Selection.SelectRange(Selection.FirstSelected(), position);
		else
			Selection.Select(position);

		OnItemClicked(position, e.ClickCount, e.X, e.Y);
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if ((mAdapter == null) || (mColumnsCount <= 0))
			return;

		let selected = Selection.FirstSelected();
		let count = mAdapter.ItemCount;

		// The cell gets FIRST refusal, so a consumer can bind F2 or Delete without the grid
		// having to know about them.
		if (selected >= 0)
		{
			OnItemKeyDown(selected, e);
			if (e.Handled)
				return;
		}

		// A page is however many whole rows fit.
		let rowsPerPage = (int32)(Height / RowStride);

		switch (e.Key)
		{
		case .Right:
			// Left and Right walk the SEQUENCE, so they wrap between rows rather than
			// stopping at the edge of one.
			if (selected < count - 1)
				MoveSelection(selected + 1);
			e.Handled = true;
		case .Left:
			if (selected > 0)
				MoveSelection(selected - 1);
			e.Handled = true;
		case .Down:
			MoveSelection(Min(selected + mColumnsCount, count - 1));
			e.Handled = true;
		case .Up:
			MoveSelection(Max(selected - mColumnsCount, 0));
			e.Handled = true;
		case .Home:
			MoveSelection(0);
			e.Handled = true;
		case .End:
			MoveSelection(count - 1);
			e.Handled = true;
		case .PageDown:
			MoveSelection(Min(selected + rowsPerPage * mColumnsCount, count - 1));
			e.Handled = true;
		case .PageUp:
			MoveSelection(Max(selected - rowsPerPage * mColumnsCount, 0));
			e.Handled = true;
		default:
		}
	}

	private void MoveSelection(int32 to)
	{
		Selection.Select(to);
		ScrollToPosition(to);
	}

	// ---- Layout -----------------------------------------------------------------------------

	/// One row's worth of vertical advance: the cell plus the gap after it.
	private float RowStride => CellHeight.Value + CellSpacing.Value;

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// A grid scrolls its own content, so it never needs unbounded room: under an unbounded
		// parent it takes defaults rather than FloatMax.
		MeasuredSize = .(constraints.ConstrainWidth(constraints.BoundedMaxWidth(300.0f)),
			constraints.ConstrainHeight(constraints.BoundedMaxHeight(300.0f)));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let viewportWidth = width - Padding.TotalHorizontal;
		let viewportHeight = height - Padding.TotalVertical;

		// The spacing between cells is one fewer than the cells, so it is added back before
		// dividing: three 60s with 4 between them fit in 188, not 192.
		mColumnsCount = Max(1, (int32)((viewportWidth + CellSpacing.Value) /
			(CellWidth.Value + CellSpacing.Value)));

		let itemCount = (mAdapter != null) ? mAdapter.ItemCount : 0;
		mRowCount = (itemCount > 0) ? (itemCount + mColumnsCount - 1) / mColumnsCount : 0;
		// The trailing gap after the last row is not content.
		mTotalContentHeight = (mRowCount > 0) ? mRowCount * RowStride - CellSpacing.Value : 0.0f;

		mScrollBarVisible = MaxScrollY > 0;
		mScrollBar.Visibility = mScrollBarVisible ? .Visible : .Gone;
		mScrollY = Clamp(mScrollY, 0.0f, MaxScrollY);

		if ((mAdapter == null) || (itemCount == 0))
		{
			RecycleOutOfRange(0, -1);
			return;
		}

		if ((Context != null) && (mScrollBar.Context == null))
			Context.AttachView(mScrollBar);

		let firstRow = (int32)(mScrollY / RowStride);
		let lastRow = Min(firstRow + (int32)(viewportHeight / RowStride) + 1, mRowCount - 1);
		let firstPosition = firstRow * mColumnsCount;
		let lastPosition = Min((lastRow + 1) * mColumnsCount - 1, itemCount - 1);

		// Recycled BEFORE the new cells are taken, so the pool has them to hand out.
		RecycleOutOfRange(firstPosition, lastPosition);

		for (int32 position = firstPosition; position <= lastPosition; position++)
			LayoutCell(position);

		if (mScrollBarVisible)
			LayoutScrollBar(width, viewportHeight);
	}

	private void LayoutCell(int32 position)
	{
		if (!mActiveViews.ContainsKey(position))
		{
			let view = mRecycler.GetOrCreate(mAdapter, position);
			view.Parent = this;
			if (Context != null)
				Context.AttachView(view);

			mActiveViews[position] = view;
		}

		// DIVERGES from Raptor, which rebinds an already-active cell here on every layout
		// pass. GetOrCreate binds on acquire and every data change path rebinds, so the
		// per-pass rebind is pure cost, and it clobbers any state a bound cell is holding.
		// Raptor's ListView carries a comment about having fixed exactly this; its GridView
		// still has the unfixed version.
		let view = mActiveViews[position];
		let row = position / mColumnsCount;
		let column = position % mColumnsCount;
		let cellX = Padding.Left + column * (CellWidth.Value + CellSpacing.Value);
		let cellY = Padding.Top + row * RowStride - mScrollY;

		view.Measure(BoxConstraints.Tight(CellWidth.Value, CellHeight.Value));
		view.Layout(cellX, cellY, CellWidth.Value, CellHeight.Value);
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

		DrawSelection(ctx);
		DrawChildren(ctx);
	}

	/// Selection is painted by the GRID, under the cells, so an adapter's views need know
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
			RecycleCell(view, position);
		}
	}

	private void RecycleAllActive()
	{
		for (let pair in mActiveViews)
			RecycleCell(pair.value, pair.key);

		mActiveViews.Clear();
	}

	/// CONSUMES the cell's reference, handing it to the pool.
	private void RecycleCell(View view, int32 position)
	{
		let viewType = (mAdapter != null) ? mAdapter.GetItemViewType(position) : 0;

		// Detached by hand, because a cell is a visual child that was attached by hand.
		if (view.Context != null)
			view.Context.DetachView(view);

		view.Parent = null;
		mRecycler.Recycle(view, viewType);
	}
}
