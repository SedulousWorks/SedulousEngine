using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Base class for all UI elements.
/// Provides layout properties, visibility, transforms, and input handling.
/// This class has NO children - use Container for multi-child elements.
public abstract class UIElement
{
	// Identity
	private UIElementId mId;
	private GUIContext mContext;
	private UIElement mParent;

	// Lifecycle
	private bool mIsPendingDeletion;

	// Layout properties
	private SizeDimension mWidth = .Auto;
	private SizeDimension mHeight = .Auto;
	private Thickness mMargin;
	private Thickness mPadding;
	private HorizontalAlignment mHorizontalAlignment = .Stretch;
	private VerticalAlignment mVerticalAlignment = .Stretch;
	private float mMinWidth;
	private float mMinHeight;
	private float mMaxWidth = SizeConstraints.Infinity;
	private float mMaxHeight = SizeConstraints.Infinity;

	// Layout state
	private DesiredSize mDesiredSize;
	private RectangleF mArrangedBounds;
	private bool mLayoutDirty = true;
	private bool mMeasureDirty = true;

	// Visual properties
	private Visibility mVisibility = .Visible;
	private float mOpacity = 1.0f;
	private bool mClipToBounds = false;
	private bool mIsHitTestVisible = true;
	private Matrix mRenderTransform = Matrix.Identity;
	private Vector2 mRenderTransformOrigin = .(0.5f, 0.5f);
	private CursorType mCursor = .Default;

	// Focus properties (on UIElement for consistent FocusManager API)
	private bool mIsFocusable = false;
	private bool mIsTabStop = false;
	private int mTabIndex = 0;
	private bool mIsFocused = false;

	/// Creates a new UI element and generates a unique ID.
	public this()
	{
		mId = UIElementId.Generate();
	}

	/// Destructor - ensures element is unregistered from context.
	public ~this()
	{
		// Unregister from context if still registered
		// This handles cases where children are deleted via parent's destructor
		mContext?.UnregisterElement(mId);
	}

	/// The unique identifier for this element.
	public UIElementId Id => mId;

	/// The context that owns this element, or null if not attached.
	public GUIContext Context => mContext;

	/// The parent element, or null if this is a root element.
	public UIElement Parent => mParent;

	/// Whether this element is marked for deletion.
	/// Elements marked for deletion should not be interacted with.
	public bool IsPendingDeletion => mIsPendingDeletion;

	// === Layout Properties ===

	/// The width of this element.
	public SizeDimension Width
	{
		get => mWidth;
		set
		{
			if (mWidth != value)
			{
				mWidth = value;
				InvalidateLayout();
			}
		}
	}

	/// The height of this element.
	public SizeDimension Height
	{
		get => mHeight;
		set
		{
			if (mHeight != value)
			{
				mHeight = value;
				InvalidateLayout();
			}
		}
	}

	/// The margin (space outside the element).
	public Thickness Margin
	{
		get => mMargin;
		set
		{
			if (mMargin != value)
			{
				mMargin = value;
				InvalidateLayout();
			}
		}
	}

	/// The padding (space inside the element).
	public Thickness Padding
	{
		get => mPadding;
		set
		{
			if (mPadding != value)
			{
				mPadding = value;
				InvalidateLayout();
			}
		}
	}

	/// Horizontal alignment within the parent.
	public HorizontalAlignment HorizontalAlignment
	{
		get => mHorizontalAlignment;
		set
		{
			if (mHorizontalAlignment != value)
			{
				mHorizontalAlignment = value;
				InvalidateLayout();
			}
		}
	}

	/// Vertical alignment within the parent.
	public VerticalAlignment VerticalAlignment
	{
		get => mVerticalAlignment;
		set
		{
			if (mVerticalAlignment != value)
			{
				mVerticalAlignment = value;
				InvalidateLayout();
			}
		}
	}

	/// Minimum width constraint.
	public float MinWidth
	{
		get => mMinWidth;
		set
		{
			if (mMinWidth != value)
			{
				mMinWidth = value;
				InvalidateLayout();
			}
		}
	}

	/// Minimum height constraint.
	public float MinHeight
	{
		get => mMinHeight;
		set
		{
			if (mMinHeight != value)
			{
				mMinHeight = value;
				InvalidateLayout();
			}
		}
	}

	/// Maximum width constraint.
	public float MaxWidth
	{
		get => mMaxWidth;
		set
		{
			if (mMaxWidth != value)
			{
				mMaxWidth = value;
				InvalidateLayout();
			}
		}
	}

	/// Maximum height constraint.
	public float MaxHeight
	{
		get => mMaxHeight;
		set
		{
			if (mMaxHeight != value)
			{
				mMaxHeight = value;
				InvalidateLayout();
			}
		}
	}

	/// The desired size calculated during Measure pass.
	public DesiredSize DesiredSize => mDesiredSize;

	/// The final bounds after Arrange pass.
	public RectangleF ArrangedBounds => mArrangedBounds;

	/// The content bounds (arranged bounds minus padding).
	public RectangleF ContentBounds
	{
		get
		{
			let effectivePadding = GetEffectivePadding();
			return RectangleF(
				mArrangedBounds.X + effectivePadding.Left,
				mArrangedBounds.Y + effectivePadding.Top,
				mArrangedBounds.Width - effectivePadding.TotalHorizontal,
				mArrangedBounds.Height - effectivePadding.TotalVertical
			);
		}
	}

	// === Visual Properties ===

	/// The visibility state of this element.
	public Visibility Visibility
	{
		get => mVisibility;
		set
		{
			if (mVisibility != value)
			{
				mVisibility = value;
				InvalidateLayout();
			}
		}
	}

	/// Whether this element is visible (Visibility == Visible).
	public bool IsVisible => mVisibility == .Visible;

	/// The opacity of this element (0.0 to 1.0).
	public float Opacity
	{
		get => mOpacity;
		set
		{
			mOpacity = Math.Clamp(value, 0.0f, 1.0f);
		}
	}

	/// Whether child content is clipped to this element's bounds.
	/// When true, any content that extends beyond this element's bounds
	/// will be clipped. Applies to containers (Panel, Border, etc.).
	public bool ClipToBounds
	{
		get => mClipToBounds;
		set => mClipToBounds = value;
	}

	/// Whether this element can be returned as a hit test result.
	/// When false, the element itself is skipped but its children are still tested.
	public bool IsHitTestVisible
	{
		get => mIsHitTestVisible;
		set => mIsHitTestVisible = value;
	}

	/// The render transform applied to this element.
	public Matrix RenderTransform
	{
		get => mRenderTransform;
		set => mRenderTransform = value;
	}

	/// The origin point for the render transform (0-1 in each dimension).
	public Vector2 RenderTransformOrigin
	{
		get => mRenderTransformOrigin;
		set => mRenderTransformOrigin = value;
	}

	/// The cursor to display when hovering this element.
	public CursorType Cursor
	{
		get => mCursor;
		set => mCursor = value;
	}

	/// The effective cursor (considering parent chain).
	public CursorType EffectiveCursor
	{
		get
		{
			if (mCursor != .Default)
				return mCursor;
			return mParent?.EffectiveCursor ?? .Default;
		}
	}

	// === Focus Properties ===

	/// Whether this element can receive keyboard focus.
	/// Default is false for UIElement; Control overrides to true.
	public bool IsFocusable
	{
		get => mIsFocusable;
		set => mIsFocusable = value;
	}

	/// Whether this element participates in tab navigation.
	/// Default is false for UIElement; Control overrides to true.
	public bool IsTabStop
	{
		get => mIsTabStop;
		set => mIsTabStop = value;
	}

	/// Tab order for keyboard navigation. Lower values come first.
	public int TabIndex
	{
		get => mTabIndex;
		set => mTabIndex = value;
	}

	/// Whether this element has keyboard focus.
	public bool IsFocused
	{
		get => mIsFocused;
		set
		{
			if (mIsFocused != value)
			{
				mIsFocused = value;
				if (value)
					OnGotFocus(scope FocusEventArgs());
				else
					OnLostFocus(scope FocusEventArgs());
			}
		}
	}

	/// Whether focus is within this element or any descendant.
	/// Override in container classes to check children.
	public virtual bool IsFocusWithin
	{
		get => mIsFocused;
	}

	// === Layout Methods ===

	/// Invalidates the layout of this element, triggering a re-measure and re-arrange.
	public void InvalidateLayout()
	{
		mLayoutDirty = true;
		mMeasureDirty = true;
		mContext?.InvalidateLayout();
	}

	/// Gets the effective padding for layout calculations.
	/// Override in subclasses to provide padding from themes or other sources.
	protected virtual Thickness GetEffectivePadding()
	{
		return mPadding;
	}

	/// Measures the element given the available constraints.
	/// Returns the desired size.
	public DesiredSize Measure(SizeConstraints constraints)
	{
		if (mVisibility == .Collapsed)
		{
			mDesiredSize = .Zero;
			return mDesiredSize;
		}

		// Apply margin to constraints
		let marginConstraints = constraints.Deflate(mMargin);

		// Calculate size based on Width/Height properties
		float width = mWidth.IsFixed ? mWidth.Value : marginConstraints.MaxWidth;
		float height = mHeight.IsFixed ? mHeight.Value : marginConstraints.MaxHeight;

		// Apply min/max constraints
		width = Math.Clamp(width, Math.Max(mMinWidth, marginConstraints.MinWidth),
			Math.Min(mMaxWidth, marginConstraints.MaxWidth));
		height = Math.Clamp(height, Math.Max(mMinHeight, marginConstraints.MinHeight),
			Math.Min(mMaxHeight, marginConstraints.MaxHeight));

		// Get effective padding (may come from theme in Control subclasses)
		let effectivePadding = GetEffectivePadding();

		// Create content constraints
		let contentConstraints = SizeConstraints.FromMaximum(
			width - effectivePadding.TotalHorizontal,
			height - effectivePadding.TotalVertical
		);

		// Let subclass measure its content
		var contentSize = MeasureOverride(contentConstraints);

		// Add padding back
		if (mWidth.IsAuto)
			width = contentSize.Width + effectivePadding.TotalHorizontal;
		if (mHeight.IsAuto)
			height = contentSize.Height + effectivePadding.TotalVertical;

		// Apply min/max again
		width = Math.Clamp(width, mMinWidth, mMaxWidth);
		height = Math.Clamp(height, mMinHeight, mMaxHeight);

		// Add margin to get total desired size
		mDesiredSize = .(width + mMargin.TotalHorizontal, height + mMargin.TotalVertical);
		mMeasureDirty = false;

		return mDesiredSize;
	}

	/// Override this to measure content. Default returns zero size.
	protected virtual DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		return .Zero;
	}

	/// Arranges the element within the given bounds.
	public void Arrange(RectangleF finalRect)
	{
		if (mVisibility == .Collapsed)
		{
			mArrangedBounds = .Empty;
			return;
		}

		// Apply margin
		let marginRect = RectangleF(
			finalRect.X + mMargin.Left,
			finalRect.Y + mMargin.Top,
			Math.Max(0, finalRect.Width - mMargin.TotalHorizontal),
			Math.Max(0, finalRect.Height - mMargin.TotalVertical)
		);

		// Calculate actual size based on alignment
		float actualWidth = mDesiredSize.Width - mMargin.TotalHorizontal;
		float actualHeight = mDesiredSize.Height - mMargin.TotalVertical;

		// Only stretch if the dimension is not explicitly fixed
		if (mHorizontalAlignment == .Stretch && !mWidth.IsFixed)
			actualWidth = marginRect.Width;
		if (mVerticalAlignment == .Stretch && !mHeight.IsFixed)
			actualHeight = marginRect.Height;

		// Apply min/max
		actualWidth = Math.Clamp(actualWidth, mMinWidth, Math.Min(mMaxWidth, marginRect.Width));
		actualHeight = Math.Clamp(actualHeight, mMinHeight, Math.Min(mMaxHeight, marginRect.Height));

		// Calculate position based on alignment
		float x = marginRect.X;
		float y = marginRect.Y;

		switch (mHorizontalAlignment)
		{
		case .Center:
			x = marginRect.X + (marginRect.Width - actualWidth) / 2;
		case .Right:
			x = marginRect.Right - actualWidth;
		default:
			break;
		}

		switch (mVerticalAlignment)
		{
		case .Center:
			y = marginRect.Y + (marginRect.Height - actualHeight) / 2;
		case .Bottom:
			y = marginRect.Bottom - actualHeight;
		default:
			break;
		}

		mArrangedBounds = .(x, y, actualWidth, actualHeight);

		// Let subclass arrange its content
		ArrangeOverride(ContentBounds);

		mLayoutDirty = false;
	}

	/// Override this to arrange content. Default does nothing.
	protected virtual void ArrangeOverride(RectangleF contentBounds)
	{
	}

	// === Rendering ===

	/// Renders this element using the provided draw context.
	public void Render(DrawContext ctx)
	{
		if (mVisibility != .Visible)
			return;

		// Apply opacity if not fully opaque
		bool hasOpacity = mOpacity < 1.0f;
		if (hasOpacity)
			ctx.PushOpacity(mOpacity);

		// Apply render transform if not identity
		bool hasTransform = mRenderTransform != Matrix.Identity;
		if (hasTransform)
		{
			ctx.PushState();

			// Calculate transform origin in world space
			let originX = mArrangedBounds.X + mArrangedBounds.Width * mRenderTransformOrigin.X;
			let originY = mArrangedBounds.Y + mArrangedBounds.Height * mRenderTransformOrigin.Y;

			// Apply: translate to origin, apply transform, translate back
			let currentTransform = ctx.GetTransform();
			let originTransform = Matrix.CreateTranslation(-originX, -originY, 0);
			let originTransformInv = Matrix.CreateTranslation(originX, originY, 0);
			let finalTransform = originTransform * mRenderTransform * originTransformInv * currentTransform;
			ctx.SetTransform(finalTransform);
		}

		// Render this element
		RenderOverride(ctx);

		// Restore transform state
		if (hasTransform)
			ctx.PopState();

		// Restore opacity
		if (hasOpacity)
			ctx.PopOpacity();
	}

	/// Override this to render the element. Default does nothing.
	protected virtual void RenderOverride(DrawContext ctx)
	{
	}

	// === Hit Testing ===

	/// Tests if the given point (in parent coordinates) hits this element.
	/// Returns this element if hit, or null if not.
	public virtual UIElement HitTest(Vector2 point)
	{
		if (mVisibility != .Visible)
			return null;

		// Transform hit point if this element has a render transform
		var hitX = point.X;
		var hitY = point.Y;

		if (mRenderTransform != Matrix.Identity)
		{
			// Calculate the inverse transform to map screen point to local space
			let originX = mArrangedBounds.X + mArrangedBounds.Width * mRenderTransformOrigin.X;
			let originY = mArrangedBounds.Y + mArrangedBounds.Height * mRenderTransformOrigin.Y;

			let toOrigin = Matrix.CreateTranslation(-originX, -originY, 0);
			let fromOrigin = Matrix.CreateTranslation(originX, originY, 0);
			let fullTransform = toOrigin * mRenderTransform * fromOrigin;

			// Try to invert the transform
			Matrix inverseTransform;
			if (Matrix.TryInvert(fullTransform, out inverseTransform))
			{
				let transformed = Vector2.Transform(.(point.X, point.Y), inverseTransform);
				hitX = transformed.X;
				hitY = transformed.Y;
			}
		}

		// Check if point is within bounds
		if (!mArrangedBounds.Contains(hitX, hitY))
			return null;

		return mIsHitTestVisible ? this : null;
	}

	// === Context Management ===

	/// Called when this element is attached to a context.
	/// (Public for access from GUIContext; not intended for external use)
	public virtual void OnAttachedToContext(GUIContext context)
	{
		mContext = context;
		context.RegisterElement(this);
	}

	/// Called when this element is detached from a context.
	/// (Public for access from GUIContext; not intended for external use)
	public virtual void OnDetachedFromContext()
	{
		mContext?.UnregisterElement(this.Id);
		mContext = null;
	}

	/// Sets the parent of this element.
	/// (Public for access from Container; not intended for external use)
	public void SetParent(UIElement parent)
	{
		mParent = parent;
	}

	/// Attempts to detach the specified child from this element.
	/// Returns the detached child if successful, null if the child wasn't found.
	/// Override in Container, ContentControl, Decorator to implement actual detachment.
	/// The caller takes ownership of the returned element.
	public virtual UIElement TryDetachChild(UIElement child)
	{
		// Base UIElement has no children
		return null;
	}

	/// Attempts to add a child to this element.
	/// Returns true if successful, false if this element doesn't support children.
	/// Override in Container to implement actual child addition.
	/// Ownership of the child is transferred to this element on success.
	public virtual bool TryAddChild(UIElement child)
	{
		// Base UIElement has no children
		return false;
	}

	/// Detaches this element from its parent.
	/// Returns true if detachment was successful.
	/// The caller takes ownership of this element after detachment.
	public bool DetachFromParent()
	{
		if (mParent == null)
			return false;

		return mParent.TryDetachChild(this) != null;
	}

	/// Gets the number of visual children.
	/// Override in Container, ContentControl, Decorator.
	public virtual int VisualChildCount => 0;

	/// Gets a visual child by index.
	/// Override in Container, ContentControl, Decorator.
	public virtual UIElement GetVisualChild(int index) => null;

	/// Iterates over all visual children, invoking the delegate for each.
	public void ForEachVisualChild(delegate void(UIElement child) action)
	{
		let count = VisualChildCount;
		for (int i = 0; i < count; i++)
		{
			let child = GetVisualChild(i);
			if (child != null)
				action(child);
		}
	}

	// === Input Handlers ===
	// These are virtual methods that can be overridden by subclasses.
	// Called by the input manager when events are routed to this element.

	protected virtual void OnMouseEnter(MouseEventArgs e) { }
	protected virtual void OnMouseLeave(MouseEventArgs e) { }
	protected virtual void OnMouseMove(MouseEventArgs e) { }
	protected virtual void OnMouseDown(MouseButtonEventArgs e) { }
	protected virtual void OnMouseUp(MouseButtonEventArgs e) { }
	protected virtual void OnMouseWheel(MouseWheelEventArgs e) { }
	protected virtual void OnKeyDown(KeyEventArgs e) { }
	protected virtual void OnKeyUp(KeyEventArgs e) { }
	protected virtual void OnTextInput(TextInputEventArgs e) { }
	protected virtual void OnGotFocus(FocusEventArgs e) { }
	protected virtual void OnLostFocus(FocusEventArgs e) { }
}
