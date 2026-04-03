using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A panel that splits its area into two resizable sections with a draggable splitter.
/// Uses the Splitter control internally for consistent drag behavior.
public class SplitPanel : Panel
{
	private Orientation mOrientation = .Horizontal;
	private float mSplitRatio = 0.5f;  // 0.0 to 1.0
	private float mMinFirstSize = 50;
	private float mMinSecondSize = 50;
	// IMPORTANT: mSplitterMovedHandler must be declared before mSplitter so that
	// mSplitter is destroyed first (reverse declaration order). The EventAccessor
	// in Splitter will call Dispose() which deletes subscribed delegates.
	private delegate void(Splitter, float) mSplitterMovedHandler;
	private Splitter mSplitter ~ delete _;

	/// Creates a new SplitPanel.
	public this()
	{
		mSplitter = new Splitter(GetSplitterOrientation());
		mSplitterMovedHandler = new => OnSplitterMoved;
		mSplitter.SplitterMoved.Subscribe(mSplitterMovedHandler);
	}

	/// The orientation of the split.
	/// Horizontal: first child on left, second on right.
	/// Vertical: first child on top, second on bottom.
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

	/// Maps SplitPanel orientation to Splitter orientation.
	/// SplitPanel.Horizontal (left/right) uses Splitter.Vertical (drags left/right).
	/// SplitPanel.Vertical (top/bottom) uses Splitter.Horizontal (drags up/down).
	private Orientation GetSplitterOrientation()
	{
		return mOrientation == .Horizontal ? .Vertical : .Horizontal;
	}

	/// The split ratio (0.0 to 1.0). 0.5 means equal split.
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

	/// The size of the splitter bar in pixels.
	public float SplitterSize
	{
		get => mSplitter.Thickness;
		set => mSplitter.Thickness = value;
	}

	/// Minimum size of the first section.
	public float MinFirstSize
	{
		get => mMinFirstSize;
		set => mMinFirstSize = Math.Max(0, value);
	}

	/// Minimum size of the second section.
	public float MinSecondSize
	{
		get => mMinSecondSize;
		set => mMinSecondSize = Math.Max(0, value);
	}

	/// Whether to show the grip visual on the splitter.
	public bool ShowGrip
	{
		get => mSplitter.ShowGrip;
		set => mSplitter.ShowGrip = value;
	}

	/// Color of the splitter bar.
	/// Hover and drag colors are calculated automatically by lightening this color.
	public Color SplitterColor
	{
		get => mSplitter.Background;
		set => mSplitter.Background = value;
	}

	/// The internal Splitter control (for advanced customization).
	public Splitter Splitter => mSplitter;

	/// Gets the first child (left/top section).
	public UIElement FirstChild => ChildCount > 0 ? GetChild(0) : null;

	/// Gets the second child (right/bottom section).
	public UIElement SecondChild => ChildCount > 1 ? GetChild(1) : null;

	/// Whether the splitter is currently being dragged.
	public bool IsDragging => mSplitter.IsDragging;

	// === Context Management ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mSplitter.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		mSplitter.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Visual Children ===

	/// Returns the number of visual children (content children + splitter).
	public override int VisualChildCount => base.VisualChildCount + 1;

	/// Gets a visual child by index (content children first, then splitter).
	public override UIElement GetVisualChild(int index)
	{
		if (index < base.VisualChildCount)
			return base.GetVisualChild(index);
		if (index == base.VisualChildCount)
			return mSplitter;
		return null;
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float firstWidth = 0, firstHeight = 0;
		float secondWidth = 0, secondHeight = 0;
		let splitterSize = mSplitter.Thickness;

		// Measure splitter
		mSplitter.Measure(constraints);

		// Measure first child
		if (FirstChild != null && FirstChild.Visibility != .Collapsed)
		{
			let size = FirstChild.Measure(constraints);
			firstWidth = size.Width;
			firstHeight = size.Height;
		}

		// Measure second child
		if (SecondChild != null && SecondChild.Visibility != .Collapsed)
		{
			let size = SecondChild.Measure(constraints);
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
		if (FirstChild != null && FirstChild.Visibility != .Collapsed)
		{
			RectangleF firstRect;
			if (mOrientation == .Horizontal)
			{
				firstRect = .(contentBounds.X, contentBounds.Y, firstSize, contentBounds.Height);
			}
			else
			{
				firstRect = .(contentBounds.X, contentBounds.Y, contentBounds.Width, firstSize);
			}
			FirstChild.Arrange(firstRect);
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
		if (SecondChild != null && SecondChild.Visibility != .Collapsed)
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
			SecondChild.Arrange(secondRect);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		if (ClipToBounds)
			ctx.PushClipRect(ArrangedBounds);

		// Render children
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChild(i);
			child?.Render(ctx);
		}

		// Render splitter
		mSplitter.Render(ctx);

		if (ClipToBounds)
			ctx.PopClip();
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		// Transform hit point if this element has a render transform
		var hitPoint = point;

		if (RenderTransform != Matrix.Identity)
		{
			let originX = ArrangedBounds.X + ArrangedBounds.Width * RenderTransformOrigin.X;
			let originY = ArrangedBounds.Y + ArrangedBounds.Height * RenderTransformOrigin.Y;

			let toOrigin = Matrix.CreateTranslation(-originX, -originY, 0);
			let fromOrigin = Matrix.CreateTranslation(originX, originY, 0);
			let fullTransform = toOrigin * RenderTransform * fromOrigin;

			Matrix inverseTransform;
			if (Matrix.TryInvert(fullTransform, out inverseTransform))
			{
				let transformed = Vector2.Transform(point, inverseTransform);
				hitPoint = transformed;
			}
		}

		if (!ArrangedBounds.Contains(hitPoint.X, hitPoint.Y))
			return null;

		// Check splitter first
		let splitterHit = mSplitter.HitTest(hitPoint);
		if (splitterHit != null)
			return splitterHit;

		// Check children in reverse order
		for (int i = ChildCount - 1; i >= 0; i--)
		{
			let child = GetChild(i);
			if (child == null)
				continue;
			let hit = child.HitTest(hitPoint);
			if (hit != null)
				return hit;
		}

		return this;
	}

	// === Splitter Event Handler ===

	private void OnSplitterMoved(Splitter splitter, float delta)
	{
		let splitterSize = mSplitter.Thickness;
		float availableSize = mOrientation == .Horizontal ?
			ContentBounds.Width - splitterSize :
			ContentBounds.Height - splitterSize;

		if (availableSize <= 0)
			return;

		// Convert delta to ratio change
		float ratioChange = delta / availableSize;
		float newRatio = mSplitRatio + ratioChange;

		// Clamp to respect minimum sizes
		float minRatio = mMinFirstSize / Math.Max(1, availableSize);
		float maxRatio = 1.0f - (mMinSecondSize / Math.Max(1, availableSize));
		SplitRatio = Math.Clamp(newRatio, minRatio, maxRatio);
	}
}
