namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Tree view using FlattenedTreeAdapter for virtualization.
/// Internally uses a ListView with the flattened adapter.
/// Draws indent + expand/collapse arrows. Single-click on arrow toggles expansion.
public class TreeView : ViewGroup
{
	public ITreeAdapter TreeAdapter;
	public SelectionModel Selection => mListView.Selection;
	public float ItemHeight { get => mListView.ItemHeight.Value; set => mListView.ItemHeight.Value = value; }

	public struct ItemClickInfo
	{
		public int32 NodeId;
		public int32 ClickCount;
	}

	/// Fired when an item is clicked. Parameters: ItemClickInfo.
	public Event<delegate void(ItemClickInfo)> OnItemClick ~ _.Dispose();

	/// Fired when an item is right-clicked. Parameters: (nodeId, localX, localY).
	public Event<delegate void(int32, float, float)> OnItemRightClick ~ _.Dispose();

	/// Fired when a key is pressed with an item selected. Parameters: (nodeId, KeyEventArgs).
	public Event<delegate void(int32, KeyEventArgs)> OnItemKeyDown ~ _.Dispose();

	/// Fired when a node is expanded or collapsed. Parameter: nodeId.
	public Event<delegate void(int32)> OnItemToggled ~ _.Dispose();

	private FlattenedTreeAdapter mFlatAdapter ~ delete _;
	private ListView mListView ~ delete _;
	public Property<float> IndentWidth = new .(20) ~ delete _;
	public Property<float> ArrowSize = new .(8) ~ delete _;
	public FlattenedTreeAdapter FlatAdapter => mFlatAdapter;
	public ListView InternalListView => mListView;

	public this()
	{
		ClipsContent = true;
		WantsArrowKeys = true;
		IndentWidth.SetOwner(this);
		ArrowSize.SetOwner(this);
		mListView = new ListView();
		mListView.Parent = this;

		mListView.OnItemClicked.Add(new (position, clickCount, localX, localY) =>
		{
			if (IsArrowHit(position, localX))
			{
				ToggleExpand(position);
				return;
			}

			let nodeId = (mFlatAdapter != null) ? mFlatAdapter.GetNodeId(position) : position;
			OnItemClick(.() { NodeId = nodeId, ClickCount = clickCount });
		});

		mListView.OnItemRightClicked.Add(new (position, localX, localY) =>
		{
			let nodeId = (mFlatAdapter != null) ? mFlatAdapter.GetNodeId(position) : position;
			OnItemRightClick(nodeId, localX, localY);
		});
	}

	/// Set the tree adapter and build the flat list.
	public void SetAdapter(ITreeAdapter adapter)
	{
		TreeAdapter = adapter;
		delete mFlatAdapter;
		mFlatAdapter = new FlattenedTreeAdapter(adapter);
		mListView.Adapter = mFlatAdapter;
	}

	/// Toggle expansion of the node at the given flat position.
	public void ToggleExpand(int32 flatPosition)
	{
		if (mFlatAdapter == null) return;
		let nodeId = mFlatAdapter.GetNodeId(flatPosition);
		if (nodeId >= 0)
		{
			mFlatAdapter.ToggleExpand(nodeId);
			mListView.NotifyDataChanged();
			OnItemToggled(nodeId);
		}
	}

	/// Checks if a click at localX is in the arrow zone for the given flat position.
	private bool IsArrowHit(int32 position, float localX)
	{
		if (mFlatAdapter == null || TreeAdapter == null) return false;

		let nodeId = mFlatAdapter.GetNodeId(position);
		if (nodeId < 0 || !TreeAdapter.HasChildren(nodeId)) return false;

		let depth = mFlatAdapter.GetDepth(position);
		let arrowLeft = depth * IndentWidth.Value;
		let arrowRight = arrowLeft + IndentWidth.Value;

		return localX >= arrowLeft && localX < arrowRight;
	}

	// === Keyboard: Left/Right expand/collapse ===

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (mFlatAdapter == null) return;
		let sel = mListView.Selection.FirstSelected;
		if (sel < 0) return;

		let nodeId = mFlatAdapter.GetNodeId(sel);
		if (nodeId < 0) return;

		OnItemKeyDown(nodeId, e);
		if (e.Handled) return;

		switch (e.Key)
		{
		case .Right:
			if (TreeAdapter.HasChildren(nodeId) && !mFlatAdapter.IsExpanded(nodeId))
			{
				mFlatAdapter.ToggleExpand(nodeId);
				mListView.NotifyDataChanged();
				OnItemToggled(nodeId);
				e.Handled = true;
			}
		case .Left:
			if (TreeAdapter.HasChildren(nodeId) && mFlatAdapter.IsExpanded(nodeId))
			{
				mFlatAdapter.ToggleExpand(nodeId);
				mListView.NotifyDataChanged();
				OnItemToggled(nodeId);
				e.Handled = true;
			}
		default:
		}
	}

	// === Visual children: the internal ListView ===

	public override int VisualChildCount => 1;
	public override View GetVisualChild(int index) => (index == 0) ? mListView : null;

	// === Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		mListView.Measure(constraints);
		MeasuredSize = mListView.MeasuredSize;
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		mListView.Layout(0, 0, width, height);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);
		DrawTreeOverlay(ctx);
	}

	/// Draws expand/collapse arrows for visible items.
	private void DrawTreeOverlay(UIDrawContext ctx)
	{
		if (mFlatAdapter == null || TreeAdapter == null) return;

		let scrollY = mListView.ScrollY;
		let itemH = mListView.ItemHeight.Value;
		let viewportH = Height;

		let firstVisible = (int32)(scrollY / itemH);
		let lastVisible = Math.Min(firstVisible + (int32)(viewportH / itemH) + 1, mFlatAdapter.ItemCount - 1);

		for (int32 i = firstVisible; i <= lastVisible; i++)
		{
			let nodeId = mFlatAdapter.GetNodeId(i);
			if (nodeId < 0) continue;
			if (!TreeAdapter.HasChildren(nodeId)) continue;

			let depth = mFlatAdapter.GetDepth(i);
			let itemY = i * itemH - scrollY;
			let arrowX = depth * IndentWidth.Value + (IndentWidth.Value - ArrowSize.Value) * 0.5f;
			let arrowCY = itemY + itemH * 0.5f;
			let halfSize = ArrowSize.Value * 0.5f;

			// Try themed chevron icons first.
			let isExpanded = mFlatAdapter.IsExpanded(nodeId);
			var chevronState = GetControlState();
			if (isExpanded) chevronState |= .Checked;
			let chevron = ResolvePartDrawable("chevron", .Background, chevronState);

			if (chevron != null)
			{
				let iconRect = RectangleF(arrowX, arrowCY - halfSize, ArrowSize.Value, ArrowSize.Value);
				chevron.Draw(ctx, iconRect);
			}
			else
			{
				// VG fallback.
				let arrowColor = ResolveStyleColor(.TextDimColor, .(160, 165, 180, 255));
				ctx.VG.BeginPath();
				if (isExpanded)
				{
					ctx.VG.MoveTo(arrowX, arrowCY - halfSize * 0.6f);
					ctx.VG.LineTo(arrowX + ArrowSize.Value, arrowCY - halfSize * 0.6f);
					ctx.VG.LineTo(arrowX + halfSize, arrowCY + halfSize * 0.6f);
				}
				else
				{
					ctx.VG.MoveTo(arrowX, arrowCY - halfSize * 0.8f);
					ctx.VG.LineTo(arrowX + ArrowSize.Value * 0.6f, arrowCY);
					ctx.VG.LineTo(arrowX, arrowCY + halfSize * 0.8f);
				}
				ctx.VG.ClosePath();
				ctx.VG.Fill(arrowColor);
			}
		}
	}
}
