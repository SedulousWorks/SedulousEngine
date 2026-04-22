using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A draggable splitter/resize handle for resizing adjacent elements.
/// Can be used standalone or within container layouts like SplitPanel.
public class Splitter : Control
{
	// Orientation
	private Orientation mOrientation = .Vertical; // Vertical = resizes horizontally (left/right)

	// Appearance
	private float mThickness = 6;
	private Color? mGripColor;
	private bool mShowGrip = true;
	private int mGripLines = 3;
	private ImageBrush? mGripImage;

	// Interaction state
	private bool mIsDragging = false;
	private float mGrabOffset; // Distance from mouse to splitter center when drag started

	// Constraints
	private float mMinOffset = 0;
	private float mMaxOffset = float.MaxValue;

	// Events
	private EventAccessor<delegate void(Splitter, float)> mSplitterMoved = new .() ~ delete _;
	private EventAccessor<delegate void(Splitter)> mDragStarted = new .() ~ delete _;
	private EventAccessor<delegate void(Splitter)> mDragCompleted = new .() ~ delete _;

	/// Creates a new Splitter.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;
	}

	/// Creates a new Splitter with specified orientation.
	public this(Orientation orientation) : this()
	{
		mOrientation = orientation;
		UpdateCursor();
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Splitter";

	/// The orientation of the splitter.
	/// Vertical = draggable left/right, Horizontal = draggable up/down.
	public Orientation Orientation
	{
		get => mOrientation;
		set
		{
			if (mOrientation != value)
			{
				mOrientation = value;
				UpdateCursor();
				InvalidateLayout();
			}
		}
	}

	/// The thickness of the splitter (in the drag direction).
	public float Thickness
	{
		get => mThickness;
		set
		{
			if (mThickness != value)
			{
				mThickness = Math.Max(2, value);
				InvalidateLayout();
			}
		}
	}

	/// The grip color (dots/lines visual).
	public Color GripColor
	{
		get
		{
			if (mGripColor.HasValue)
				return mGripColor.Value;
			let palette = Context?.Theme?.Palette ?? Palette();
			return palette.Border.A > 0 ? palette.Border : Color(100, 100, 100, 255);
		}
		set => mGripColor = value;
	}

	/// Whether to show the grip visual.
	public bool ShowGrip
	{
		get => mShowGrip;
		set => mShowGrip = value;
	}

	/// Number of grip lines/dots.
	public int GripLines
	{
		get => mGripLines;
		set => mGripLines = Math.Max(0, value);
	}

	/// Image for the splitter grip (replaces background + grip dots).
	public ImageBrush? GripImage
	{
		get => mGripImage;
		set => mGripImage = value;
	}

	/// Minimum offset constraint for dragging.
	public float MinOffset
	{
		get => mMinOffset;
		set => mMinOffset = value;
	}

	/// Maximum offset constraint for dragging.
	public float MaxOffset
	{
		get => mMaxOffset;
		set => mMaxOffset = value;
	}

	/// Whether the splitter is currently being dragged.
	public bool IsDragging => mIsDragging;

	/// Event fired when the splitter is moved. Delta is the change in position.
	public EventAccessor<delegate void(Splitter, float)> SplitterMoved => mSplitterMoved;

	/// Event fired when drag starts.
	public EventAccessor<delegate void(Splitter)> DragStarted => mDragStarted;

	/// Event fired when drag completes.
	public EventAccessor<delegate void(Splitter)> DragCompleted => mDragCompleted;

	private void UpdateCursor()
	{
		switch (mOrientation)
		{
		case .Vertical:
			Cursor = .ResizeEW;
		case .Horizontal:
			Cursor = .ResizeNS;
		}
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		switch (mOrientation)
		{
		case .Vertical:
			// Vertical splitter: fixed width, takes available height
			let height = constraints.MaxHeight != SizeConstraints.Infinity
				? constraints.MaxHeight
				: 100;
			return .(mThickness, height);

		case .Horizontal:
			// Horizontal splitter: fixed height, takes available width
			let width = constraints.MaxWidth != SizeConstraints.Infinity
				? constraints.MaxWidth
				: 100;
			return .(width, mThickness);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Try image-based grip first
		if (mGripImage.HasValue && mGripImage.Value.IsValid)
		{
			var img = mGripImage.Value;
			if (mIsDragging)
				img.Tint = Palette.Lighten(img.Tint, 0.15f);
			else if (IsHovered)
				img.Tint = Palette.Lighten(img.Tint, 0.08f);
			ctx.DrawImageBrush(img, bounds);
		}
		else
		{
			// Draw background
			var bgColor = GetStateBackground();
			if (bgColor.A == 0)
			{
				let palette = Context?.Theme?.Palette ?? Palette();
				bgColor = palette.Surface.A > 0 ? palette.Surface : Color(50, 50, 50, 255);
			}

			if (mIsDragging)
				bgColor = bgColor.Interpolate(Color.White, 0.15f);
			else if (IsHovered)
				bgColor = bgColor.Interpolate(Color.White, 0.08f);

			ctx.FillRect(bounds, bgColor);

			// Draw grip
			if (mShowGrip && mGripLines > 0)
			{
				RenderGrip(ctx, bounds);
			}
		}
	}

	private void RenderGrip(DrawContext ctx, RectangleF bounds)
	{
		let gripColor = GripColor;
		let dotSize = 2.0f;
		let spacing = 4.0f;

		switch (mOrientation)
		{
		case .Vertical:
			// Draw vertical dots in center
			let totalHeight = mGripLines * dotSize + (mGripLines - 1) * spacing;
			let startY = bounds.Y + (bounds.Height - totalHeight) / 2;
			let centerX = bounds.X + bounds.Width / 2 - dotSize / 2;

			for (int i = 0; i < mGripLines; i++)
			{
				let y = startY + i * (dotSize + spacing);
				ctx.FillRect(.(centerX, y, dotSize, dotSize), gripColor);
			}

		case .Horizontal:
			// Draw horizontal dots in center
			let totalWidth = mGripLines * dotSize + (mGripLines - 1) * spacing;
			let startX = bounds.X + (bounds.Width - totalWidth) / 2;
			let centerY = bounds.Y + bounds.Height / 2 - dotSize / 2;

			for (int i = 0; i < mGripLines; i++)
			{
				let x = startX + i * (dotSize + spacing);
				ctx.FillRect(.(x, centerY, dotSize, dotSize), gripColor);
			}
		}
	}

	// === Input ===

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && IsEffectivelyEnabled)
		{
			mIsDragging = true;

			// Calculate grab offset: distance from mouse to splitter center
			let globalMousePos = Context?.InputManager?.LastMousePosition ?? .Zero;
			switch (mOrientation)
			{
			case .Vertical:
				let splitterCenter = ArrangedBounds.X + mThickness / 2;
				mGrabOffset = globalMousePos.X - splitterCenter;
			case .Horizontal:
				let splitterCenter = ArrangedBounds.Y + mThickness / 2;
				mGrabOffset = globalMousePos.Y - splitterCenter;
			}

			Context?.FocusManager?.SetCapture(this);
			mDragStarted.[Friend]Invoke(this);
			e.Handled = true;
		}
	}

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		if (mIsDragging)
		{
			// Get the global mouse position from InputManager
			let globalMousePos = Context?.InputManager?.LastMousePosition ?? .Zero;

			float currentMousePos;
			float currentSplitterCenter;
			switch (mOrientation)
			{
			case .Vertical:
				currentMousePos = globalMousePos.X;
				currentSplitterCenter = ArrangedBounds.X + mThickness / 2;
			case .Horizontal:
				currentMousePos = globalMousePos.Y;
				currentSplitterCenter = ArrangedBounds.Y + mThickness / 2;
			}

			// Calculate where the splitter center should be based on mouse and grab offset
			let targetCenter = currentMousePos - mGrabOffset;
			let delta = targetCenter - currentSplitterCenter;

			// Only move if mouse is on the appropriate side of the splitter:
			// - To move right/down (delta > 0): mouse must be right/below splitter center
			// - To move left/up (delta < 0): mouse must be left/above splitter center
			// This prevents "rubber banding" when the splitter is at a limit
			if (delta > 0 && currentMousePos > currentSplitterCenter)
			{
				mSplitterMoved.[Friend]Invoke(this, delta);
			}
			else if (delta < 0 && currentMousePos < currentSplitterCenter)
			{
				mSplitterMoved.[Friend]Invoke(this, delta);
			}
		}
	}

	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		base.OnMouseUp(e);

		if (e.Button == .Left && mIsDragging)
		{
			mIsDragging = false;
			Context?.FocusManager?.ReleaseCapture();
			mDragCompleted.[Friend]Invoke(this);
			e.Handled = true;
		}
	}

	protected override void OnMouseLeave(MouseEventArgs e)
	{
		base.OnMouseLeave(e);
		// Don't stop dragging on mouse leave - that's handled by capture
	}

	protected override void OnLostFocus(FocusEventArgs e)
	{
		base.OnLostFocus(e);

		if (mIsDragging)
		{
			mIsDragging = false;
			if (Context?.FocusManager?.CapturedElement == this)
				Context?.FocusManager?.ReleaseCapture();
			mDragCompleted.[Friend]Invoke(this);
		}
	}
}
