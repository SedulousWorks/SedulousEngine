namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

/// A flow-layout grid view for the asset browser tile/grid mode.
/// Fixed-size cells arranged in rows, wrapping on container width.
/// Virtualized — only creates/binds views for the visible range.
///
/// Uses the same IListAdapter as ListView for data binding.
/// Each cell is a single view created by the adapter.
class GridContentView : ViewGroup, IListAdapterObserver
{
	private IListAdapter mAdapter;
	public SelectionModel Selection = new .() ~ delete _;

	/// Cell dimensions (width x height including padding).
	public float CellWidth = 80;
	public float CellHeight = 96;

	/// Spacing between cells.
	public float SpacingX = 4;
	public float SpacingY = 4;

	/// Padding inside the grid area.
	public Thickness GridPadding = .(8, 8, 8, 8);

	/// Fired when an item is clicked. Args: (position, clickCount, localX, localY).
	public Event<delegate void(int32, int32, float, float)> OnItemClicked ~ _.Dispose();

	/// Fired when an item is right-clicked. Args: (position, localX, localY).
	public Event<delegate void(int32, float, float)> OnItemRightClicked ~ _.Dispose();

	/// Fired when an item is double-clicked. Args: (position).
	public Event<delegate void(int32)> OnItemDoubleClicked ~ _.Dispose();

	/// Fired when the background (empty space) is right-clicked. Args: (localX, localY).
	public Event<delegate void(float, float)> OnBackgroundRightClicked ~ _.Dispose();

	private ViewRecycler mRecycler = new .() ~ delete _;
	private float mScrollY;
	private MomentumHelper mMomentum = .();

	// Active views keyed by adapter position.
	private Dictionary<int32, View> mActiveViews = new .() ~ {
		for (let kv in _) delete kv.value;
		delete _;
	};

	// Layout metrics (recomputed on layout)
	private int32 mColumnsPerRow;
	private float mTotalContentHeight;

	// Scrollbar
	private ScrollBar mScrollBar ~ delete _;
	private bool mScrollBarVisible;

	// Click tracking
	private int32 mPressedItem = -1;
	private int32 mLastClickedItem = -1;
	private float mLastClickTime;

	public this()
	{
		ClipsContent = true;
		IsFocusable = true;

		mScrollBar = new ScrollBar();
		mScrollBar.Orientation = .Vertical;
		mScrollBar.Parent = this;
		mScrollBar.OnValueChanged = new (val) => { mScrollY = val; InvalidateLayout(); };
	}

	public IListAdapter Adapter
	{
		get => mAdapter;
		set
		{
			if (mAdapter != null)
				mAdapter.SetObserver(null);
			mAdapter = value;
			if (mAdapter != null)
				mAdapter.SetObserver(this);
			RecycleAllActive();
			InvalidateLayout();
		}
	}

	public float MaxScrollY
	{
		get
		{
			let viewportH = Height - GridPadding.Top - GridPadding.Bottom;
			return Math.Max(0, mTotalContentHeight - viewportH);
		}
	}

	public void ScrollBy(float dy)
	{
		mScrollY = Math.Clamp(mScrollY + dy, 0, MaxScrollY);
		InvalidateLayout();
	}

	public void ScrollToPosition(int32 position)
	{
		if (mColumnsPerRow <= 0) return;
		let row = position / mColumnsPerRow;
		let targetY = row * (CellHeight + SpacingY);
		mScrollY = Math.Clamp(targetY, 0, MaxScrollY);
		InvalidateLayout();
	}

	// === IListAdapterObserver ===

	public void OnDataSetChanged()
	{
		RecycleAllActive();
		InvalidateLayout();
	}

	public void OnItemRangeChanged(int32 start, int32 count)
	{
		// Rebind active views in changed range
		if (mAdapter == null) return;
		for (int32 pos = start; pos < start + count; pos++)
		{
			if (mActiveViews.TryGetValue(pos, let view))
				mAdapter.BindView(view, pos);
		}
	}

	// === Visual children (active views + scrollbar) ===

	public override int VisualChildCount => mActiveViews.Count + 1;

	public override View GetVisualChild(int index)
	{
		if (index < mActiveViews.Count)
		{
			int i = 0;
			for (let kv in mActiveViews)
			{
				if (i == index) return kv.value;
				i++;
			}
		}
		if (index == mActiveViews.Count)
			return mScrollBar;
		return null;
	}

	// === Layout ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		MeasuredSize = .(wSpec.Resolve(200), hSpec.Resolve(200));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		if (mAdapter == null) return;

		let viewportW = (right - left) - GridPadding.Left - GridPadding.Right - (mScrollBarVisible ? mScrollBar.BarThickness : 0);
		let viewportH = (bottom - top) - GridPadding.Top - GridPadding.Bottom;

		// Compute columns per row
		mColumnsPerRow = Math.Max(1, (int32)((viewportW + SpacingX) / (CellWidth + SpacingX)));

		// Compute total rows and content height
		let itemCount = mAdapter.ItemCount;
		let totalRows = (itemCount + mColumnsPerRow - 1) / mColumnsPerRow;
		mTotalContentHeight = totalRows * (CellHeight + SpacingY) - (totalRows > 0 ? SpacingY : 0);

		// No items — nothing to lay out
		if (itemCount == 0)
		{
			mScrollBarVisible = false;
			mScrollBar.Visibility = .Gone;
			return;
		}

		// Update scrollbar
		mScrollBarVisible = MaxScrollY > 0;
		mScrollBar.Visibility = mScrollBarVisible ? .Visible : .Gone;

		// Clamp scroll
		mScrollY = Math.Clamp(mScrollY, 0, MaxScrollY);

		// Compute visible row range
		let firstVisRow = (int32)(mScrollY / (CellHeight + SpacingY));
		let lastVisRow = (int32)((mScrollY + viewportH) / (CellHeight + SpacingY));

		let firstVisItem = firstVisRow * mColumnsPerRow;
		let lastVisItem = Math.Min((lastVisRow + 1) * mColumnsPerRow - 1, itemCount - 1);

		// Recycle out-of-range views
		let toRemove = scope List<int32>();
		for (let kv in mActiveViews)
		{
			if (kv.key < firstVisItem || kv.key > lastVisItem)
				toRemove.Add(kv.key);
		}
		for (let pos in toRemove)
		{
			let view = mActiveViews[pos];
			let viewType = (mAdapter != null) ? mAdapter.GetItemViewType(pos) : 0;
			if (view.Context != null)
				ViewGroup.DetachSubtree(view);
			view.Parent = null;
			mActiveViews.Remove(pos);
			mRecycler.Recycle(view, viewType);
		}

		// Create/bind views for visible items
		for (int32 pos = firstVisItem; pos <= lastVisItem; pos++)
		{
			if (!mActiveViews.ContainsKey(pos))
			{
				let view = mRecycler.GetOrCreate(mAdapter, pos);
				view.Parent = this;
				if (Context != null)
					ViewGroup.AttachSubtree(view, Context);
				mActiveViews[pos] = view;
			}
			else
			{
				mAdapter.BindView(mActiveViews[pos], pos);
			}

			// Position the cell
			let row = pos / mColumnsPerRow;
			let col = pos % mColumnsPerRow;
			let cellX = GridPadding.Left + col * (CellWidth + SpacingX);
			let cellY = GridPadding.Top + row * (CellHeight + SpacingY) - mScrollY;

			mActiveViews[pos].Measure(.Exactly(CellWidth), .Exactly(CellHeight));
			mActiveViews[pos].Layout(cellX, cellY, CellWidth, CellHeight);
		}

		// Layout scrollbar
		if (mScrollBarVisible)
		{
			mScrollBar.Value = mScrollY;
			mScrollBar.MaxValue = MaxScrollY;
			mScrollBar.ViewportSize = viewportH;
			let sbW = mScrollBar.BarThickness;
			mScrollBar.Measure(.Exactly(sbW), .Exactly(bottom - top));
			mScrollBar.Layout(right - left - sbW, 0, sbW, bottom - top);
		}

		// Selection highlight rendering handled in OnDraw
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (mAdapter == null) return;

		let itemIndex = GetItemAtPosition(e.X, e.Y);

		if (e.Button == .Right)
		{
			if (itemIndex >= 0 && itemIndex < mAdapter.ItemCount)
			{
				if (!Selection.IsSelected(itemIndex))
					Selection.Select(itemIndex);
				OnItemRightClicked(itemIndex, e.X, e.Y);
				e.Handled = true;
			}
			else
			{
				OnBackgroundRightClicked(e.X, e.Y);
				e.Handled = true;
			}
			return;
		}

		if (e.Button == .Left)
		{
			if (itemIndex >= 0 && itemIndex < mAdapter.ItemCount)
			{
				if (e.Modifiers.HasFlag(.Ctrl))
					Selection.Toggle(itemIndex);
				else if (e.Modifiers.HasFlag(.Shift))
					Selection.SelectRange(Selection.FirstSelected, itemIndex);
				else
					Selection.Select(itemIndex);

				OnItemClicked(itemIndex, e.ClickCount, e.X, e.Y);

				// Double-click detection
				if (e.ClickCount >= 2)
					OnItemDoubleClicked(itemIndex);

				e.Handled = true;
			}
			else
			{
				// Click on empty space — clear selection
				Selection.ClearSelection();
				e.Handled = true;
			}
		}
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (MaxScrollY > 0)
		{
			ScrollBy(-e.DeltaY * CellHeight);
			mMomentum.VelocityY = -e.DeltaY * 200;
			e.Handled = true;
		}
	}

	/// Returns the adapter position of the item at the given local coordinates, or -1.
	public int32 GetItemAtPosition(float localX, float localY)
	{
		if (mColumnsPerRow <= 0 || mAdapter == null) return -1;

		let scrolledY = localY + mScrollY - GridPadding.Top;
		let adjustedX = localX - GridPadding.Left;

		if (adjustedX < 0 || scrolledY < 0) return -1;

		let col = (int32)(adjustedX / (CellWidth + SpacingX));
		let row = (int32)(scrolledY / (CellHeight + SpacingY));

		if (col >= mColumnsPerRow) return -1;

		// Check that click is within the cell bounds (not in spacing)
		let cellLocalX = adjustedX - col * (CellWidth + SpacingX);
		let cellLocalY = scrolledY - row * (CellHeight + SpacingY);
		if (cellLocalX > CellWidth || cellLocalY > CellHeight) return -1;

		let pos = row * mColumnsPerRow + col;
		if (pos >= mAdapter.ItemCount) return -1;

		return pos;
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		// Tick momentum
		let dt = 1.0f / 60.0f;
		let (_, dy) = mMomentum.Update(dt);
		if (dy != 0) ScrollBy(dy);

		// Draw selection highlights
		if (mAdapter != null && Selection.SelectedCount > 0)
		{
			let selColor = ctx.Theme?.GetColor("GridView.Selection", .(60, 120, 200, 80)) ?? .(60, 120, 200, 80);
			for (let pos in Selection.SelectedPositions)
			{
				if (mActiveViews.TryGetValue(pos, let view))
				{
					let bounds = RectangleF(view.Bounds.X, view.Bounds.Y, view.Bounds.Width, view.Bounds.Height);
					ctx.VG.FillRoundedRect(bounds, 4, selColor);
				}
			}
		}

		DrawChildren(ctx);
	}

	// === Internal ===

	private void RecycleAllActive()
	{
		for (let kv in mActiveViews)
		{
			let viewType = (mAdapter != null) ? mAdapter.GetItemViewType(kv.key) : 0;
			if (kv.value.Context != null)
				ViewGroup.DetachSubtree(kv.value);
			kv.value.Parent = null;
			mRecycler.Recycle(kv.value, viewType);
		}
		mActiveViews.Clear();
	}
}
