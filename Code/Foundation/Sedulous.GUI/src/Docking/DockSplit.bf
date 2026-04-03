using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A node in the dock layout that splits space between two children.
/// Children can be either DockTabGroup or DockSplit (for nested splits).
public class DockSplit : Control
{
	private Orientation mOrientation = .Horizontal;
	private float mSplitRatio = 0.5f;
	private float mMinFirstSize = 100;
	private float mMinSecondSize = 100;
	private Control mFirst;   // DockTabGroup or DockSplit
	private Control mSecond;  // DockTabGroup or DockSplit
	private Splitter mSplitter ~ delete _;
	private delegate void(Splitter, float) mSplitterMovedHandler ~ delete _;

	// Parent reference
	public DockManager Manager;
	public DockSplit ParentSplit;

	/// Creates a new DockSplit.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;

		mSplitter = new Splitter(GetSplitterOrientation());
		mSplitter.Thickness = 4;
		mSplitterMovedHandler = new => OnSplitterMoved;
		mSplitter.SplitterMoved.Subscribe(mSplitterMovedHandler);
	}

	/// Destructor - clean up children and unsubscribe from events.
	public ~this()
	{
		// Unsubscribe from splitter events (don't delete delegate, field destructor will do it)
		if (mSplitter != null && mSplitterMovedHandler != null)
			mSplitter.SplitterMoved.Unsubscribe(mSplitterMovedHandler, false);

		// Delete children
		if (mFirst != null)
			delete mFirst;
		if (mSecond != null)
			delete mSecond;
	}

	/// Creates a new DockSplit with orientation.
	public this(Orientation orientation) : this()
	{
		Orientation = orientation;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "DockSplit";

	/// The split orientation.
	/// Horizontal: first on left, second on right.
	/// Vertical: first on top, second on bottom.
	public Orientation Orientation
	{
		get => mOrientation;
		set
		{
			if (mOrientation != value)
			{
				mOrientation = value;
				mSplitter.Orientation = GetSplitterOrientation();
				InvalidateLayout();
			}
		}
	}

	/// The split ratio (0.0 to 1.0). 0.5 = equal split.
	public float SplitRatio
	{
		get => mSplitRatio;
		set
		{
			let clamped = Math.Clamp(value, 0.0f, 1.0f);
			if (mSplitRatio != clamped)
			{
				mSplitRatio = clamped;
				InvalidateLayout();
			}
		}
	}

	/// The first child (left or top).
	public Control First
	{
		get => mFirst;
		set => SetChild(ref mFirst, value);
	}

	/// The second child (right or bottom).
	public Control Second
	{
		get => mSecond;
		set => SetChild(ref mSecond, value);
	}

	/// Minimum size of the first section.
	public float MinFirstSize
	{
		get => mMinFirstSize;
		set => mMinFirstSize = Math.Max(50, value);
	}

	/// Minimum size of the second section.
	public float MinSecondSize
	{
		get => mMinSecondSize;
		set => mMinSecondSize = Math.Max(50, value);
	}

	/// The internal Splitter control.
	public Splitter Splitter => mSplitter;

	// === Child Management ===

	private void SetChild(ref Control field, Control value)
	{
		if (field == value)
			return;

		// Detach old child
		if (field != null)
		{
			if (Context != null)
				field.OnDetachedFromContext();
			ClearChildParent(field);
		}

		field = value;

		// Attach new child
		if (field != null)
		{
			SetChildParent(field);
			if (Context != null)
				field.OnAttachedToContext(Context);
		}

		InvalidateLayout();
	}

	private void SetChildParent(Control child)
	{
		if (child == null)
			return;
		child.SetParent(this);
		if (let tabGroup = child as DockTabGroup)
			tabGroup.Manager = Manager;
		else if (let split = child as DockSplit)
		{
			split.Manager = Manager;
			split.ParentSplit = this;
		}
	}

	private void ClearChildParent(Control child)
	{
		if (child == null)
			return;
		child.SetParent(null);
		if (let tabGroup = child as DockTabGroup)
			tabGroup.Manager = null;
		else if (let split = child as DockSplit)
		{
			split.Manager = null;
			split.ParentSplit = null;
		}
	}

	/// Maps split orientation to splitter orientation.
	private Orientation GetSplitterOrientation()
	{
		return mOrientation == .Horizontal ? .Vertical : .Horizontal;
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mSplitter.OnAttachedToContext(context);
		if (mFirst != null)
		{
			// Restore parent reference (may have been cleared during tree restructuring)
			SetChildParent(mFirst);
			mFirst.OnAttachedToContext(context);
		}
		if (mSecond != null)
		{
			SetChildParent(mSecond);
			mSecond.OnAttachedToContext(context);
		}
	}

	public override void OnDetachedFromContext()
	{
		if (mFirst != null)
			mFirst.OnDetachedFromContext();
		if (mSecond != null)
			mSecond.OnDetachedFromContext();
		mSplitter.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float firstWidth = 0, firstHeight = 0;
		float secondWidth = 0, secondHeight = 0;
		let splitterSize = mSplitter.Thickness;

		mSplitter.Measure(constraints);

		if (mFirst != null && mFirst.Visibility != .Collapsed)
		{
			mFirst.Measure(constraints);
			let size = mFirst.DesiredSize;
			firstWidth = size.Width;
			firstHeight = size.Height;
		}

		if (mSecond != null && mSecond.Visibility != .Collapsed)
		{
			mSecond.Measure(constraints);
			let size = mSecond.DesiredSize;
			secondWidth = size.Width;
			secondHeight = size.Height;
		}

		if (mOrientation == .Horizontal)
		{
			return .(
				firstWidth + splitterSize + secondWidth,
				Math.Max(firstHeight, secondHeight)
			);
		}
		else
		{
			return .(
				Math.Max(firstWidth, secondWidth),
				firstHeight + splitterSize + secondHeight
			);
		}
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		let splitterSize = mSplitter.Thickness;
		float availableSize = mOrientation == .Horizontal ?
			contentBounds.Width - splitterSize :
			contentBounds.Height - splitterSize;

		// Clamp ratio to respect minimum sizes
		float minRatio = mMinFirstSize / Math.Max(1, availableSize);
		float maxRatio = 1.0f - (mMinSecondSize / Math.Max(1, availableSize));
		float clampedRatio = Math.Clamp(mSplitRatio, minRatio, maxRatio);

		float firstSize = availableSize * clampedRatio;
		float secondSize = availableSize - firstSize;

		// Arrange first child
		if (mFirst != null && mFirst.Visibility != .Collapsed)
		{
			RectangleF firstRect;
			if (mOrientation == .Horizontal)
				firstRect = .(contentBounds.X, contentBounds.Y, firstSize, contentBounds.Height);
			else
				firstRect = .(contentBounds.X, contentBounds.Y, contentBounds.Width, firstSize);
			mFirst.Arrange(firstRect);
		}

		// Arrange splitter
		RectangleF splitterRect;
		if (mOrientation == .Horizontal)
		{
			splitterRect = .(
				contentBounds.X + firstSize,
				contentBounds.Y,
				splitterSize,
				contentBounds.Height
			);
		}
		else
		{
			splitterRect = .(
				contentBounds.X,
				contentBounds.Y + firstSize,
				contentBounds.Width,
				splitterSize
			);
		}
		mSplitter.Arrange(splitterRect);

		// Arrange second child
		if (mSecond != null && mSecond.Visibility != .Collapsed)
		{
			RectangleF secondRect;
			if (mOrientation == .Horizontal)
			{
				secondRect = .(
					contentBounds.X + firstSize + splitterSize,
					contentBounds.Y,
					secondSize,
					contentBounds.Height
				);
			}
			else
			{
				secondRect = .(
					contentBounds.X,
					contentBounds.Y + firstSize + splitterSize,
					contentBounds.Width,
					secondSize
				);
			}
			mSecond.Arrange(secondRect);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		// Render children
		if (mFirst != null && mFirst.Visibility != .Collapsed)
			mFirst.Render(ctx);

		if (mSecond != null && mSecond.Visibility != .Collapsed)
			mSecond.Render(ctx);

		// Render splitter
		mSplitter.Render(ctx);
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Check splitter first
		let splitterHit = mSplitter.HitTest(point);
		if (splitterHit != null)
			return splitterHit;

		// Check children
		if (mFirst != null)
		{
			let hit = mFirst.HitTest(point);
			if (hit != null)
				return hit;
		}

		if (mSecond != null)
		{
			let hit = mSecond.HitTest(point);
			if (hit != null)
				return hit;
		}

		return this;
	}

	// === Child Detachment ===

	/// Override to support polymorphic child detachment.
	/// Called by MutationQueue when deleting a child element.
	public override UIElement TryDetachChild(UIElement child)
	{
		if (child == mFirst)
		{
			let result = mFirst;
			mFirst = null;
			if (result != null)
			{
				ClearChildParent(result);
				if (Context != null)
					result.OnDetachedFromContext();
			}
			return result;
		}
		if (child == mSecond)
		{
			let result = mSecond;
			mSecond = null;
			if (result != null)
			{
				ClearChildParent(result);
				if (Context != null)
					result.OnDetachedFromContext();
			}
			return result;
		}
		return null;
	}

	// === Visual Children ===

	public override int VisualChildCount
	{
		get
		{
			int count = 1;  // Splitter
			if (mFirst != null) count++;
			if (mSecond != null) count++;
			return count;
		}
	}

	public override UIElement GetVisualChild(int index)
	{
		int i = 0;
		if (mFirst != null)
		{
			if (i == index) return mFirst;
			i++;
		}
		if (mSecond != null)
		{
			if (i == index) return mSecond;
			i++;
		}
		if (i == index) return mSplitter;
		return null;
	}

	// === Splitter Handler ===

	private void OnSplitterMoved(Splitter splitter, float delta)
	{
		let splitterSize = mSplitter.Thickness;
		float availableSize = mOrientation == .Horizontal ?
			ContentBounds.Width - splitterSize :
			ContentBounds.Height - splitterSize;

		if (availableSize <= 0)
			return;

		float ratioChange = delta / availableSize;
		float newRatio = mSplitRatio + ratioChange;

		float minRatio = mMinFirstSize / Math.Max(1, availableSize);
		float maxRatio = 1.0f - (mMinSecondSize / Math.Max(1, availableSize));
		SplitRatio = Math.Clamp(newRatio, minRatio, maxRatio);
	}
}
