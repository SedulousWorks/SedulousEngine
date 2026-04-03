using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A modal dialog with title bar, content area, and button row.
public class Dialog : Control
{
	// Title
	private String mTitle ~ delete _;
	private TextBlock mTitleBlock ~ delete _;

	// Content
	private UIElement mContent ~ delete _;

	// Button row (buttons are owned by mButtonRow, not this list)
	private StackPanel mButtonRow ~ delete _;
	private List<Button> mButtons ~ delete _;

	// Result
	private DialogResult mResult = .None;

	// Events
	private EventAccessor<delegate void(Dialog, DialogResult)> mClosed = new .() ~ delete _;

	// Appearance
	private float mTitleBarHeight = 36;
	private float mButtonRowHeight = 40;
	private float mMinWidth = 300;
	private float mMinHeight = 120;
	private float mCornerRadius = 6;
	private Color mTitleBackground;
	private Color mTitleForeground;
	private Color mBorderColor;

	/// Creates a new Dialog.
	public this()
	{
		IsFocusable = true;
		IsTabStop = false;

		// Set default colors (will be updated by ApplyThemeDefaults)
		Background = Color(50, 50, 50, 255);
		Foreground = Color(220, 220, 220, 255);
		mTitleBackground = Color(35, 35, 35, 255);
		mTitleForeground = Color(220, 220, 220, 255);
		mBorderColor = Color(80, 80, 80, 255);

		// Create title block
		mTitleBlock = new TextBlock("");
		mTitleBlock.Foreground = mTitleForeground;
		mTitleBlock.VerticalAlignment = .Center;

		// Create button row
		mButtonRow = new StackPanel();
		mButtonRow.Orientation = .Horizontal;
		mButtonRow.Spacing = 8;
		mButtonRow.HorizontalAlignment = .Right;
		mButtonRow.VerticalAlignment = .Center;

		mButtons = new .();
	}

	/// Creates a new Dialog with title.
	public this(StringView title) : this()
	{
		Title = title;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Dialog";

	/// The dialog title.
	public StringView Title
	{
		get => mTitle ?? "";
		set
		{
			if (mTitle == null)
				mTitle = new String(value);
			else
				mTitle.Set(value);
			mTitleBlock.Text = value;
		}
	}

	/// The dialog content.
	public UIElement Content
	{
		get => mContent;
		set
		{
			if (mContent != null)
				delete mContent;
			mContent = value;
		}
	}

	/// The dialog result.
	public DialogResult Result => mResult;

	/// Event fired when the dialog is closed.
	public EventAccessor<delegate void(Dialog, DialogResult)> Closed => mClosed;

	/// Minimum width of the dialog.
	public float DialogMinWidth
	{
		get => mMinWidth;
		set => mMinWidth = value;
	}

	/// Minimum height of the dialog.
	public float DialogMinHeight
	{
		get => mMinHeight;
		set => mMinHeight = value;
	}

	/// Adds a button with the specified text and result.
	public Button AddButton(StringView text, DialogResult result)
	{
		let button = new Button(text);
		button.Width = .Fixed(80);
		button.Height = .Fixed(28);

		// Capture result for lambda
		let capturedResult = result;
		button.Click.Subscribe(new (b) => {
			Close(capturedResult);
		});

		mButtons.Add(button);
		mButtonRow.AddChild(button);

		return button;
	}

	/// Shows the dialog as modal.
	public void Show()
	{
		if (Context == null)
			return;

		mResult = .None;

		// Get modal manager from context
		if (let modalManager = Context.GetService<ModalManager>())
		{
			modalManager.PushModal(this, true);
		}
		else
		{
			// Fallback: just show as popup
			let viewportCenter = Vector2(Context.ViewportWidth / 2, Context.ViewportHeight / 2);
			let anchorRect = RectangleF(viewportCenter.X, viewportCenter.Y, 1, 1);
			Context.PopupLayer.ShowPopup(this, null, anchorRect, false);
		}
	}

	/// Closes the dialog with the specified result.
	public void Close(DialogResult result)
	{
		mResult = result;

		if (Context != null)
		{
			if (let modalManager = Context.GetService<ModalManager>())
			{
				modalManager.PopModal(this);
			}
			else
			{
				Context.PopupLayer.ClosePopup(this);
			}
		}

		mClosed.[Friend]Invoke(this, result);
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Title bar
		mTitleBlock.Measure(SizeConstraints.Unconstrained);

		// Content
		float contentWidth = 0;
		float contentHeight = 0;
		if (mContent != null && mContent.Visibility != .Collapsed)
		{
			let contentConstraints = SizeConstraints.FromMaximum(
				constraints.MaxWidth - Padding.TotalHorizontal,
				constraints.MaxHeight - mTitleBarHeight - mButtonRowHeight - Padding.TotalVertical
			);
			mContent.Measure(contentConstraints);
			contentWidth = mContent.DesiredSize.Width;
			contentHeight = mContent.DesiredSize.Height;
		}

		// Button row
		mButtonRow.Measure(SizeConstraints.Unconstrained);

		// Calculate total size
		float width = Math.Max(mMinWidth, Math.Max(contentWidth, mButtonRow.DesiredSize.Width) + Padding.TotalHorizontal);
		float height = Math.Max(mMinHeight, mTitleBarHeight + contentHeight + mButtonRowHeight + Padding.TotalVertical);

		return .(width, height);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		// Title bar
		let titleBounds = RectangleF(
			contentBounds.X + 12,
			contentBounds.Y,
			contentBounds.Width - 24,
			mTitleBarHeight
		);
		mTitleBlock.Arrange(titleBounds);

		// Content area
		if (mContent != null && mContent.Visibility != .Collapsed)
		{
			let contentAreaBounds = RectangleF(
				contentBounds.X + Padding.Left,
				contentBounds.Y + mTitleBarHeight + Padding.Top,
				contentBounds.Width - Padding.TotalHorizontal,
				contentBounds.Height - mTitleBarHeight - mButtonRowHeight - Padding.TotalVertical
			);
			mContent.Arrange(contentAreaBounds);
		}

		// Button row
		let buttonRowBounds = RectangleF(
			contentBounds.X + Padding.Left,
			contentBounds.Bottom - mButtonRowHeight,
			contentBounds.Width - Padding.TotalHorizontal,
			mButtonRowHeight
		);
		mButtonRow.Arrange(buttonRowBounds);
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Try image-based background first (replaces entire frame)
		let bgImage = GetStateBackgroundImage();
		if (bgImage.HasValue && bgImage.Value.IsValid)
		{
			ctx.DrawImageBrush(bgImage.Value, bounds);
		}
		else
		{
			// Draw dialog background with rounded corners
			if (Background.A > 0)
			{
				ctx.FillRoundedRect(bounds, mCornerRadius, Background);
			}

			// Draw title bar background
			let titleBounds = RectangleF(bounds.X, bounds.Y, bounds.Width, mTitleBarHeight);
			ctx.FillRoundedRect(
				RectangleF(titleBounds.X, titleBounds.Y, titleBounds.Width, titleBounds.Height + mCornerRadius),
				mCornerRadius,
				mTitleBackground
			);
			// Cover the bottom corners of the title bar
			ctx.FillRect(
				RectangleF(titleBounds.X, titleBounds.Bottom - mCornerRadius, titleBounds.Width, mCornerRadius),
				mTitleBackground
			);

			// Draw border
			ctx.DrawRoundedRect(bounds, mCornerRadius, mBorderColor, 1);
		}

		// Render title
		mTitleBlock.Render(ctx);

		// Render content
		mContent?.Render(ctx);

		// Render button row
		mButtonRow.Render(ctx);
	}

	// === Input ===

	protected override void OnKeyDown(KeyEventArgs e)
	{
		if (e.Key == .Escape)
		{
			// Close with Cancel result
			Close(.Cancel);
			e.Handled = true;
		}
		else if (e.Key == .Return)
		{
			// Find and activate focused button by simulating click
			for (let button in mButtons)
			{
				if (button.IsFocused)
				{
					// Simulate button activation through its OnMouseUp handler
					let bounds = button.ArrangedBounds;
					let fakeArgs = scope MouseButtonEventArgs(bounds.X + 1, bounds.Y + 1, .Left, .None);
					button.[Friend]OnMouseUp(fakeArgs);
					e.Handled = true;
					break;
				}
			}
		}

		if (!e.Handled)
			base.OnKeyDown(e);
	}

	// === Visual child management ===

	public override int VisualChildCount
	{
		get
		{
			int count = 2;  // mTitleBlock and mButtonRow
			if (mContent != null)
				count++;
			return count;
		}
	}

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0)
			return mTitleBlock;
		if (index == 1)
			return mButtonRow;
		if (index == 2 && mContent != null)
			return mContent;
		return null;
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Test button row first (most likely click target)
		let buttonHit = mButtonRow.HitTest(point);
		if (buttonHit != null)
			return buttonHit;

		// Test content
		if (mContent != null)
		{
			let contentHit = mContent.HitTest(point);
			if (contentHit != null)
				return contentHit;
		}

		// Test title
		let titleHit = mTitleBlock.HitTest(point);
		if (titleHit != null)
			return titleHit;

		return this;
	}

	// === Lifecycle ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
		mTitleBlock.OnAttachedToContext(context);
		mButtonRow.OnAttachedToContext(context);
		mContent?.OnAttachedToContext(context);
	}

	/// Applies theme defaults for dialog styling.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		let palette = theme?.Palette ?? Palette();

		// Apply surface/background colors from theme
		if (palette.Surface.A > 0)
			Background = palette.Surface;
		if (palette.Text.A > 0)
			Foreground = palette.Text;

		// Title bar uses darker background
		mTitleBackground = palette.Background.A > 0
			? palette.Background
			: Sedulous.GUI.Palette.Darken(Background, 0.2f);
		mTitleForeground = Foreground;
		mBorderColor = palette.Border.A > 0 ? palette.Border : Color(80, 80, 80, 255);

		// Corner radius from theme
		mCornerRadius = theme?.DefaultCornerRadius ?? 6;

		// Update title block colors
		mTitleBlock.Foreground = mTitleForeground;
	}

	public override void OnDetachedFromContext()
	{
		mTitleBlock.OnDetachedFromContext();
		mButtonRow.OnDetachedFromContext();
		mContent?.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}
}
