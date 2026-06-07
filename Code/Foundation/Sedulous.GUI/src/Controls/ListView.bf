namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Virtualized list view. Only creates/binds views for the visible range.
/// Uses IListAdapter for data + view creation and ViewRecycler for pooling.
/// Supports fixed item height (O(1)) and variable height (binary search).
public class ListView : ViewGroup, IListAdapterObserver
{
	private IListAdapter mAdapter;
	public SelectionModel Selection = new .() ~ delete _;
	public float ItemHeight = 30;

	/// Fired when an item is clicked. Args: (position, clickCount, localX, localY).
	public Event<delegate void(int32, int32, float, float)> OnItemClicked ~ _.Dispose();

	/// Fired when an item is right-clicked. Args: (position, localX, localY).
	public Event<delegate void(int32, float, float)> OnItemRightClicked ~ _.Dispose();

	/// Fired when an item is long-pressed. Args: (position).
	public Event<delegate void(int32)> OnItemLongPress ~ _.Dispose();

	/// Fired when the background (empty space) is right-clicked. Args: (localX, localY).
	public Event<delegate void(float, float)> OnBackgroundRightClicked ~ _.Dispose();

	/// Fired when a key is pressed with an item selected. Args: (position, KeyEventArgs).
	/// Set e.Handled = true to prevent default ListView key handling.
	public Event<delegate void(int32, KeyEventArgs)> OnItemKeyDown ~ _.Dispose();

	/// Long press threshold in seconds.
	public float LongPressTime = 0.5f;

	private ViewRecycler mRecycler = new .() ~ delete _;
	private float mScrollY;
	private MomentumHelper mMomentum = .();

	// Currently visible item views, keyed by adapter position.
	private Dictionary<int32, View> mActiveViews = new .() ~ {
		for (let kv in _) delete kv.value;
		delete _;
	};
	private int32 mFirstVisible = -1;
	private int32 mLastVisible = -1;

	// Variable-height support: cached cumulative offsets.
	private List<float> mItemOffsets = new .() ~ delete _;
	private bool mVariableHeight;
	private float mTotalContentHeight;

	// Scrollbar (visual child).
	private ScrollBar mScrollBar ~ delete _;
	private bool mScrollBarVisible;

	// Drag state.
	private bool mDragging;
	private float mDragLastY;

	// Long press state.
	private int32 mPressedItem = -1;
	private float mPressTime;
	private bool mLongPressFired;

	public float ScrollY => mScrollY;
	public ViewRecycler Recycler => mRecycler;

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
			RebuildOffsets();
			RecycleAllActive();
			Invalidate();
		}
	}

	public float MaxScrollY
	{
		get
		{
			let contentH = mVariableHeight ? mTotalContentHeight : ((mAdapter != null) ? mAdapter.ItemCount * ItemHeight : 0);
			let viewportH = Height - Padding.TotalVertical;
			return Math.Max(0, contentH - viewportH);
		}
	}

	public this()
	{
		ClipsContent = true;
		IsFocusable = true;
		IsTabStop = true;
		mScrollBar = new ScrollBar();
		mScrollBar.Parent = this;
		mScrollBar.OnValueChanged.Add(new (bar, val) => { mScrollY = val; Invalidate(); });
	}

	/// Scroll by delta, clamping to valid range.
	public void ScrollBy(float dy)
	{
		mScrollY = Math.Clamp(mScrollY + dy, 0, MaxScrollY);
		Invalidate();
	}

	/// Notify that the adapter data has changed - rebuild visible items.
	public void NotifyDataChanged()
	{
		RebuildOffsets();
		RecycleAllActive();
		Invalidate();
	}

	// === IListAdapterObserver ===

	public void OnDataSetChanged()
	{
		NotifyDataChanged();
	}

	public void OnItemRangeChanged(int32 start, int32 count)
	{
		if (mAdapter == null) return;
		for (int32 pos = start; pos < start + count; pos++)
		{
			if (mActiveViews.TryGetValue(pos, let view))
				mAdapter.BindView(view, pos);
		}
		if (mVariableHeight)
		{
			RebuildOffsets();
			Invalidate();
		}
	}

	// === Variable-height offset cache ===

	private void RebuildOffsets()
	{
		mItemOffsets.Clear();
		mVariableHeight = false;
		mTotalContentHeight = 0;

		if (mAdapter == null) return;

		let count = mAdapter.ItemCount;
		mItemOffsets.Reserve(count + 1);

		float offset = 0;
		for (int32 i = 0; i < count; i++)
		{
			mItemOffsets.Add(offset);
			let h = mAdapter.GetItemHeight(i);
			if (h > 0)
			{
				mVariableHeight = true;
				offset += h;
			}
			else
			{
				offset += ItemHeight;
			}
		}
		mItemOffsets.Add(offset);
		mTotalContentHeight = offset;
	}

	private float GetItemOffset(int32 position)
	{
		if (mVariableHeight && position < mItemOffsets.Count)
			return mItemOffsets[position];
		return position * ItemHeight;
	}

	private float GetItemHeightAt(int32 position)
	{
		if (mVariableHeight && mAdapter != null)
		{
			let h = mAdapter.GetItemHeight(position);
			if (h > 0) return h;
		}
		return ItemHeight;
	}

	private int32 FindFirstVisible(float scrollY)
	{
		if (!mVariableHeight || mItemOffsets.Count <= 1)
			return (int32)(scrollY / ItemHeight);

		int32 lo = 0, hi = (int32)(mItemOffsets.Count - 2);
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

	// === Visual children: active item views + scrollbar ===

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

	// === Mouse input ===

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (MaxScrollY > 0)
		{
			ScrollBy(-e.DeltaY * ItemHeight * 2);
			mMomentum.VelocityY = -e.DeltaY * 200;
			e.Handled = true;
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		// Convert to our local coordinates (event coords may be in a child's space).
		let screenX = Context?.InputManager?.MouseX ?? 0;
		let screenY = Context?.InputManager?.MouseY ?? 0;
		let local = ScreenToLocal(.(screenX, screenY));

		if (e.Button == .Left && MaxScrollY > 0)
		{
			mDragging = true;
			mDragLastY = local.Y;
			Context?.FocusManager.SetCapture(this);
		}

		// Right-click item notification.
		if (mAdapter != null && e.Button == .Right)
		{
			let itemIndex = GetItemAtY(local.Y);
			if (itemIndex >= 0 && itemIndex < mAdapter.ItemCount)
			{
				if (!Selection.IsSelected(itemIndex))
					Selection.Select(itemIndex);
				OnItemRightClicked(itemIndex, local.X, local.Y);
				e.Handled = true;
			}
			else
			{
				OnBackgroundRightClicked(local.X, local.Y);
				e.Handled = true;
			}
		}

		// Selection + item click notification.
		if (mAdapter != null && e.Button == .Left)
		{
			let itemIndex = GetItemAtY(local.Y);
			if (itemIndex >= 0 && itemIndex < mAdapter.ItemCount)
			{
				if (e.Modifiers.HasFlag(.Ctrl))
					Selection.Toggle(itemIndex);
				else if (e.Modifiers.HasFlag(.Shift))
					Selection.SelectRange(Selection.FirstSelected, itemIndex);
				else
					Selection.Select(itemIndex);

				OnItemClicked(itemIndex, e.ClickCount, local.X, local.Y);

				mPressedItem = itemIndex;
				mPressTime = 0;
				mLongPressFired = false;
			}
			e.Handled = true;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDragging)
		{
			let screenY = Context?.InputManager?.MouseY ?? 0;
			let local = ScreenToLocal(.(0, screenY));
			let dy = mDragLastY - local.Y;
			if (Math.Abs(dy) > 1)
			{
				ScrollBy(dy);
				mMomentum.VelocityY = dy * 60;
				mDragLastY = local.Y;
			}
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDragging)
		{
			mDragging = false;
			Context?.FocusManager.ReleaseCapture();
		}
		mPressedItem = -1;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (mAdapter == null) return;
		let sel = Selection.FirstSelected;
		let count = mAdapter.ItemCount;

		if (sel >= 0)
		{
			OnItemKeyDown(sel, e);
			if (e.Handled) return;
		}

		let shift = e.Modifiers.HasFlag(.Shift);

		switch (e.Key)
		{
		case .Down:
			let next = Math.Min(sel + 1, count - 1);
			if (shift) Selection.SelectRange(sel, next);
			else Selection.Select(next);
			ScrollToPosition(next);
			e.Handled = true;
		case .Up:
			let prev = Math.Max(sel - 1, 0);
			if (shift) Selection.SelectRange(sel, prev);
			else Selection.Select(prev);
			ScrollToPosition(prev);
			e.Handled = true;
		case .Home:
			if (shift) Selection.SelectRange(sel, 0);
			else Selection.Select(0);
			ScrollToPosition(0);
			e.Handled = true;
		case .End:
			if (shift) Selection.SelectRange(sel, count - 1);
			else Selection.Select(count - 1);
			ScrollToPosition(count - 1);
			e.Handled = true;
		case .PageDown:
			let pageSize = (int32)(Height / ItemHeight);
			let pageNext = Math.Min(sel + pageSize, count - 1);
			if (shift) Selection.SelectRange(sel, pageNext);
			else Selection.Select(pageNext);
			ScrollToPosition(pageNext);
			e.Handled = true;
		case .PageUp:
			let pageSizeUp = (int32)(Height / ItemHeight);
			let pagePrev = Math.Max(sel - pageSizeUp, 0);
			if (shift) Selection.SelectRange(sel, pagePrev);
			else Selection.Select(pagePrev);
			ScrollToPosition(pagePrev);
			e.Handled = true;
		default:
		}
	}

	/// Get the currently visible view for a specific adapter position.
	public View GetActiveView(int32 position)
	{
		if (mActiveViews.TryGetValue(position, let view))
			return view;
		return null;
	}

	/// Scroll so that the item at the given position is visible.
	public void ScrollToPosition(int32 position)
	{
		if (mAdapter == null || position < 0 || position >= mAdapter.ItemCount) return;

		let itemTop = GetItemOffset(position);
		let itemBottom = itemTop + GetItemHeightAt(position);
		let viewportH = Height - Padding.TotalVertical;

		if (itemTop < mScrollY)
			mScrollY = itemTop;
		else if (itemBottom > mScrollY + viewportH)
			mScrollY = itemBottom - viewportH;

		mScrollY = Math.Clamp(mScrollY, 0, MaxScrollY);
		Invalidate();
	}

	/// Get the adapter position of the item at local Y coordinate.
	public int32 GetItemAtY(float localY)
	{
		let scrolledY = localY + mScrollY - Padding.Top;
		if (mVariableHeight)
			return FindFirstVisible(scrolledY);
		return (int32)(scrolledY / ItemHeight);
	}

	// === Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let contentH = mVariableHeight ? mTotalContentHeight : ((mAdapter != null) ? mAdapter.ItemCount * ItemHeight : 0);
		float desiredH = contentH + Padding.TotalVertical;
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth), constraints.ConstrainHeight(desiredH));

		mScrollBarVisible = MaxScrollY > 0;
		mScrollBar.Visibility = mScrollBarVisible ? .Visible : .Gone;
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mAdapter == null) return;

		let viewportH = height - Padding.TotalVertical;
		let viewportW = width - Padding.TotalHorizontal - (mScrollBarVisible ? mScrollBar.BarThickness : 0);

		// Clamp scroll.
		mScrollY = Math.Clamp(mScrollY, 0, MaxScrollY);

		if (mAdapter.ItemCount == 0)
		{
			mScrollBarVisible = false;
			mScrollBar.Visibility = .Gone;
			return;
		}

		// Ensure scrollbar is attached to context.
		if (Context != null && mScrollBar.Context == null)
			Context.AttachView(mScrollBar);

		// Compute visible range.
		let firstVis = FindFirstVisible(mScrollY);
		int32 lastVis = firstVis;

		float y = GetItemOffset(firstVis) - mScrollY;
		for (int32 pos = firstVis; pos < mAdapter.ItemCount; pos++)
		{
			if (y > viewportH) break;
			lastVis = pos;
			y += GetItemHeightAt(pos);
		}

		// Recycle views that scrolled out.
		RecycleOutOfRange(firstVis, lastVis);

		// Create/bind views for newly visible items.
		for (int32 pos = firstVis; pos <= lastVis; pos++)
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

			let itemY = Padding.Top + GetItemOffset(pos) - mScrollY;
			let itemH = GetItemHeightAt(pos);
			mActiveViews[pos].Measure(BoxConstraints.Tight(viewportW, itemH));
			mActiveViews[pos].Layout(Padding.Left, itemY, viewportW, itemH);
		}

		mFirstVisible = firstVis;
		mLastVisible = lastVis;

		// Layout scrollbar.
		if (mScrollBarVisible)
		{
			mScrollBar.Value = mScrollY;
			mScrollBar.MaxValue = MaxScrollY;
			mScrollBar.ViewportSize = viewportH;
			mScrollBar.Measure(BoxConstraints.Tight(mScrollBar.BarThickness, viewportH));
			mScrollBar.Layout(
				width - mScrollBar.BarThickness,
				Padding.Top,
				mScrollBar.BarThickness,
				viewportH);
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		// Tick momentum.
		let dt = Context?.DeltaTime ?? 0.016f;
		let (_, dy) = mMomentum.Update(dt);
		if (dy != 0) ScrollBy(dy);

		// Tick long press.
		if (mPressedItem >= 0 && !mLongPressFired && !mDragging)
		{
			mPressTime += dt;
			if (mPressTime >= LongPressTime)
			{
				mLongPressFired = true;
				OnItemLongPress(mPressedItem);
			}
		}

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

		// Draw visible item views + scrollbar via visual children.
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
