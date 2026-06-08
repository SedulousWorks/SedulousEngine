namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Virtualized flowing grid with fixed cell size. Items flow left-to-right,
/// wrapping to new rows. Only creates/binds views for visible rows.
public class GridView : ViewGroup, IListAdapterObserver
{
	private IListAdapter mAdapter;
	public SelectionModel Selection = new .() ~ delete _;

	/// Fixed cell dimensions.
	public Property<float> CellWidth = new .(60) ~ delete _;
	public Property<float> CellHeight = new .(60) ~ delete _;
	public Property<float> CellSpacing = new .(4) ~ delete _;

	/// Fired when an item is clicked. Args: (position, clickCount, localX, localY).
	public Event<delegate void(int32, int32, float, float)> OnItemClicked ~ _.Dispose();

	/// Fired when an item is right-clicked. Args: (position, localX, localY).
	public Event<delegate void(int32, float, float)> OnItemRightClicked ~ _.Dispose();

	private ViewRecycler mRecycler = new .() ~ delete _;
	private float mScrollY;
	private MomentumHelper mMomentum = .();

	private Dictionary<int32, View> mActiveViews = new .() ~ {
		for (let kv in _) delete kv.value;
		delete _;
	};

	private ScrollBar mScrollBar ~ delete _;
	private bool mScrollBarVisible;

	private int32 mColumnsCount = 1;
	private int32 mRowCount;
	private float mTotalContentHeight;

	public float ScrollY => mScrollY;

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
			Invalidate();
		}
	}

	public float MaxScrollY => Math.Max(0, mTotalContentHeight - (Height - Padding.TotalVertical));

	public this()
	{
		ClipsContent = true;
		IsFocusable = true;
		IsTabStop = true;
		WantsArrowKeys = true;
		CellWidth.SetOwner(this);
		CellHeight.SetOwner(this);
		CellSpacing.SetOwner(this);
		mScrollBar = new ScrollBar();
		mScrollBar.Parent = this;
		mScrollBar.OnValueChanged.Add(new (bar, val) => { mScrollY = val; Invalidate(); });
	}

	public void ScrollBy(float dy)
	{
		mScrollY = Math.Clamp(mScrollY + dy, 0, MaxScrollY);
		Invalidate();
	}

	// === IListAdapterObserver ===

	public void OnDataSetChanged()
	{
		RecycleAllActive();
		Invalidate();
	}

	public void OnItemRangeChanged(int32 start, int32 count)
	{
		if (mAdapter == null) return;
		for (int32 pos = start; pos < start + count; pos++)
		{
			if (mActiveViews.TryGetValue(pos, let view))
				mAdapter.BindView(view, pos);
		}
	}

	// === Visual children ===

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

	// === Input ===

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (MaxScrollY > 0)
		{
			ScrollBy(-e.DeltaY * (CellHeight.Value + CellSpacing.Value) * 2);
			mMomentum.VelocityY = -e.DeltaY * 200;
			e.Handled = true;
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (mAdapter == null) return;

		let pos = GetItemAtPoint(e.X, e.Y);

		if (e.Button == .Right)
		{
			if (pos >= 0 && pos < mAdapter.ItemCount)
			{
				if (!Selection.IsSelected(pos))
					Selection.Select(pos);
				OnItemRightClicked(pos, e.X, e.Y);
			}
			e.Handled = true;
		}
		else if (e.Button == .Left)
		{
			if (pos >= 0 && pos < mAdapter.ItemCount)
			{
				if (e.Modifiers.HasFlag(.Ctrl))
					Selection.Toggle(pos);
				else if (e.Modifiers.HasFlag(.Shift))
					Selection.SelectRange(Selection.FirstSelected, pos);
				else
					Selection.Select(pos);

				OnItemClicked(pos, e.ClickCount, e.X, e.Y);
			}
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (mAdapter == null || mColumnsCount <= 0) return;
		let sel = Selection.FirstSelected;
		let count = mAdapter.ItemCount;

		switch (e.Key)
		{
		case .Right:
			if (sel < count - 1) Selection.Select(sel + 1);
			ScrollToPosition(Selection.FirstSelected);
			e.Handled = true;
		case .Left:
			if (sel > 0) Selection.Select(sel - 1);
			ScrollToPosition(Selection.FirstSelected);
			e.Handled = true;
		case .Down:
			let next = Math.Min(sel + mColumnsCount, count - 1);
			Selection.Select(next);
			ScrollToPosition(next);
			e.Handled = true;
		case .Up:
			let prev = Math.Max(sel - mColumnsCount, 0);
			Selection.Select(prev);
			ScrollToPosition(prev);
			e.Handled = true;
		case .Home:
			Selection.Select(0);
			ScrollToPosition(0);
			e.Handled = true;
		case .End:
			Selection.Select(count - 1);
			ScrollToPosition(count - 1);
			e.Handled = true;
		case .PageDown:
			let visibleRows = (int32)(Height / (CellHeight.Value + CellSpacing.Value));
			let pageNext = Math.Min(sel + visibleRows * mColumnsCount, count - 1);
			Selection.Select(pageNext);
			ScrollToPosition(pageNext);
			e.Handled = true;
		case .PageUp:
			let visibleRowsUp = (int32)(Height / (CellHeight.Value + CellSpacing.Value));
			let pagePrev = Math.Max(sel - visibleRowsUp * mColumnsCount, 0);
			Selection.Select(pagePrev);
			ScrollToPosition(pagePrev);
			e.Handled = true;
		default:
		}
	}

	/// Get the adapter position at a point, or -1.
	public int32 GetItemAtPoint(float localX, float localY)
	{
		if (mColumnsCount <= 0) return -1;
		let scrolledY = localY + mScrollY - Padding.Top;
		let x = localX - Padding.Left;

		let col = (int32)(x / (CellWidth.Value + CellSpacing.Value));
		let row = (int32)(scrolledY / (CellHeight.Value + CellSpacing.Value));

		if (col < 0 || col >= mColumnsCount) return -1;
		let pos = row * mColumnsCount + col;
		if (mAdapter != null && pos >= mAdapter.ItemCount) return -1;
		return pos;
	}

	/// Scroll so that the item at position is visible.
	public void ScrollToPosition(int32 position)
	{
		if (mAdapter == null || mColumnsCount <= 0 || position < 0) return;

		let row = position / mColumnsCount;
		let rowY = row * (CellHeight.Value + CellSpacing.Value);
		let viewportH = Height - Padding.TotalVertical;

		if (rowY < mScrollY)
			mScrollY = rowY;
		else if (rowY + CellHeight.Value > mScrollY + viewportH)
			mScrollY = rowY + CellHeight.Value - viewportH;

		mScrollY = Math.Clamp(mScrollY, 0, MaxScrollY);
		Invalidate();
	}

	// === Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(constraints.MaxHeight));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let viewportW = width - Padding.TotalHorizontal;
		let viewportH = height - Padding.TotalVertical;

		// Compute grid layout.
		mColumnsCount = Math.Max(1, (int32)((viewportW + CellSpacing.Value) / (CellWidth.Value + CellSpacing.Value)));
		let itemCount = (mAdapter != null) ? mAdapter.ItemCount : 0;
		mRowCount = (itemCount > 0) ? (itemCount + mColumnsCount - 1) / mColumnsCount : 0;
		mTotalContentHeight = (mRowCount > 0) ? mRowCount * (CellHeight.Value + CellSpacing.Value) - CellSpacing.Value : 0;

		mScrollBarVisible = MaxScrollY > 0;
		mScrollBar.Visibility = mScrollBarVisible ? .Visible : .Gone;
		mScrollY = Math.Clamp(mScrollY, 0, MaxScrollY);

		if (mAdapter == null || itemCount == 0) return;

		// Ensure scrollbar is attached.
		if (Context != null && mScrollBar.Context == null)
			Context.AttachView(mScrollBar);

		// Compute visible row range.
		let firstRow = (int32)(mScrollY / (CellHeight.Value + CellSpacing.Value));
		let lastRow = Math.Min(firstRow + (int32)(viewportH / (CellHeight.Value + CellSpacing.Value)) + 1, mRowCount - 1);
		let firstPos = firstRow * mColumnsCount;
		let lastPos = Math.Min((lastRow + 1) * mColumnsCount - 1, itemCount - 1);

		// Recycle out-of-range views.
		RecycleOutOfRange(firstPos, lastPos);

		// Create/bind visible cells.
		for (int32 pos = firstPos; pos <= lastPos; pos++)
		{
			if (!mActiveViews.ContainsKey(pos))
			{
				let view = mRecycler.GetOrCreate(mAdapter, pos);
				view.Parent = this;
				if (Context != null)
					Context.AttachView(view);
				mActiveViews[pos] = view;
			}
			else
			{
				mAdapter.BindView(mActiveViews[pos], pos);
			}

			let row = pos / mColumnsCount;
			let col = pos % mColumnsCount;
			let cellX = Padding.Left + col * (CellWidth.Value + CellSpacing.Value);
			let cellY = Padding.Top + row * (CellHeight.Value + CellSpacing.Value) - mScrollY;

			mActiveViews[pos].Measure(BoxConstraints.Tight(CellWidth.Value, CellHeight.Value));
			mActiveViews[pos].Layout(cellX, cellY, CellWidth.Value, CellHeight.Value);
		}

		// Layout scrollbar.
		if (mScrollBarVisible)
		{
			mScrollBar.Value = mScrollY;
			mScrollBar.MaxValue = MaxScrollY;
			mScrollBar.ViewportSize = viewportH;
			mScrollBar.Measure(BoxConstraints.Tight(mScrollBar.BarThickness, viewportH));
			mScrollBar.Layout(width - mScrollBar.BarThickness, Padding.Top, mScrollBar.BarThickness, viewportH);
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		// Tick momentum.
		let dt = Context?.DeltaTime ?? 0.016f;
		let (_, dy) = mMomentum.Update(dt);
		if (dy != 0) ScrollBy(dy);

		// Draw selection highlights.
		if (mAdapter != null)
		{
			let selColor = ResolveStyleColor(.SelectionColor, .(60, 120, 200, 80));
			for (let kv in mActiveViews)
			{
				if (Selection.IsSelected(kv.key))
				{
					let view = kv.value;
					ctx.VG.FillRect(.(view.Bounds.X, view.Bounds.Y, view.Width, view.Height), selColor);
				}
			}
		}

		DrawChildren(ctx);
	}

	// === Internal ===

	private void RecycleOutOfRange(int32 first, int32 last)
	{
		let toRemove = scope List<int32>();
		for (let kv in mActiveViews)
		{
			if (kv.key < first || kv.key > last)
				toRemove.Add(kv.key);
		}
		for (let pos in toRemove)
		{
			let view = mActiveViews[pos];
			let viewType = (mAdapter != null) ? mAdapter.GetItemViewType(pos) : 0;
			if (view.Context != null)
				view.Context.DetachView(view);
			view.Parent = null;
			mActiveViews.Remove(pos);
			mRecycler.Recycle(view, viewType);
		}
	}

	private void RecycleAllActive()
	{
		for (let kv in mActiveViews)
		{
			let viewType = (mAdapter != null) ? mAdapter.GetItemViewType(kv.key) : 0;
			if (kv.value.Context != null)
				kv.value.Context.DetachView(kv.value);
			kv.value.Parent = null;
			mRecycler.Recycle(kv.value, viewType);
		}
		mActiveViews.Clear();
	}
}
