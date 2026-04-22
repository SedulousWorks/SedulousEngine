using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A clickable button control that can execute commands or raise click events.
public class Button : ContentControl
{
	private GUICommand mCommand;
	private Object mCommandParameter;
	private bool mIsDefault;
	private bool mIsCancel;
	private EventAccessor<delegate void(Button)> mClick = new .() ~ delete _;

	/// Event raised when the button is clicked.
	public EventAccessor<delegate void(Button)> Click => mClick;

	/// Creates a new Button.
	public this()
	{
		// Buttons are focusable and respond to keyboard
		IsFocusable = true;
		IsTabStop = true;
		Cursor = .Pointer;
	}

	/// Creates a new Button with text content.
	public this(StringView text) : this()
	{
		let textBlock = new TextBlock(text);
		textBlock.TextAlignment = .Center;
		Content = textBlock;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Button";

	/// The command to execute when clicked.
	public GUICommand Command
	{
		get => mCommand;
		set
		{
			if (mCommand != value)
			{
				// Unsubscribe from old command
				if (mCommand != null)
					mCommand.CanExecuteChanged.Unsubscribe(scope => OnCanExecuteChanged);

				mCommand = value;

				// Subscribe to new command
				if (mCommand != null)
					mCommand.CanExecuteChanged.Subscribe(new => OnCanExecuteChanged);

				UpdateIsEnabled();
			}
		}
	}

	/// Parameter passed to the command when executed.
	public Object CommandParameter
	{
		get => mCommandParameter;
		set => mCommandParameter = value;
	}

	/// Whether this is the default button (activated by Enter key).
	public bool IsDefault
	{
		get => mIsDefault;
		set => mIsDefault = value;
	}

	/// Whether this is the cancel button (activated by Escape key).
	public bool IsCancel
	{
		get => mIsCancel;
		set => mIsCancel = value;
	}

	/// Called when the command's CanExecute state may have changed.
	private void OnCanExecuteChanged()
	{
		UpdateIsEnabled();
	}

	/// Updates IsEnabled based on command's CanExecute.
	private void UpdateIsEnabled()
	{
		if (mCommand != null)
			IsEnabled = mCommand.CanExecute(mCommandParameter);
	}

	/// Handles mouse button press.
	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && IsEnabled)
		{
			IsPressed = true;
			e.Handled = true;

			// Capture mouse to track release
			Context?.FocusManager?.SetCapture(this);
		}
	}

	/// Handles mouse button release.
	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		// Capture IsPressed before base class clears it
		let wasPressed = IsPressed;

		base.OnMouseUp(e);

		if (e.Button == .Left && wasPressed)
		{
			e.Handled = true;

			// Release capture
			Context?.FocusManager?.ReleaseCapture();

			// Only click if mouse is still over the button
			if (IsHovered && IsEnabled)
			{
				OnClick();
			}
		}
	}

	/// Handles mouse leaving the control.
	protected override void OnMouseLeave(MouseEventArgs e)
	{
		base.OnMouseLeave(e);
		// Visual update handled by IsHovered change
	}

	/// Handles key press.
	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (!IsEnabled)
			return;

		// Space or Enter activates the button
		if (e.Key == .Space || e.Key == .Return)
		{
			IsPressed = true;
			e.Handled = true;
		}
	}

	/// Handles key release.
	protected override void OnKeyUp(KeyEventArgs e)
	{
		base.OnKeyUp(e);

		if (!IsEnabled)
			return;

		// Space or Enter activates the button
		if ((e.Key == .Space || e.Key == .Return) && IsPressed)
		{
			IsPressed = false;
			OnClick();
			e.Handled = true;
		}
	}

	/// Called when the button is clicked.
	protected virtual void OnClick()
	{
		// Execute command if bound
		if (mCommand != null && mCommand.CanExecute(mCommandParameter))
			mCommand.Execute(mCommandParameter);

		// Raise click event
		RaiseClick();
	}

	/// Raises the Click event. Can be called by subclasses that override OnClick.
	protected void RaiseClick()
	{
		mClick.[Friend]Invoke(this);
	}

	/// Measures the button content with minimum size for visual appearance.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		var size = base.MeasureOverride(constraints);

		// Ensure minimum size for clickable area
		let style = GetThemeStyle();
		let minSize = style.BorderThickness * 2 + 16; // Minimum clickable size

		size.Width = Math.Max(size.Width, minSize);
		size.Height = Math.Max(size.Height, minSize / 2);

		return size;
	}

	/// Renders the button with background, border, content, and focus indicator.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;
		let defaultRadius = Context?.Theme?.DefaultCornerRadius ?? 4;
		let cornerRadius = CornerRadius >= 0 ? CornerRadius : defaultRadius; // Default rounded corners for buttons (use negative to get default)

		// Try image-based background first
		let bgImage = GetStateBackgroundImage();
		if (bgImage.HasValue && bgImage.Value.IsValid)
		{
			ctx.DrawImageBrush(bgImage.Value, bounds);
		}
		else
		{
			// Color-based fallback
			let style = GetThemeStyle();
			let bgColor = GetStateBackground();
			let borderColor = GetStateBorderColor();

			// Draw background
			if (bgColor.A > 0)
			{
				ctx.FillRoundedRect(bounds, cornerRadius, bgColor);
			}

			// Draw border
			if (style.BorderThickness > 0 && borderColor.A > 0)
			{
				ctx.DrawBorderRoundedRect(bounds, cornerRadius, borderColor, style.BorderThickness);
			}
		}

		// Draw content
		Content?.Render(ctx);

		// Draw focus indicator
		if (IsFocused)
		{
			let focusColor = FocusBorderColor;
			let focusThickness = FocusBorderThickness;
			let focusBounds = RectangleF(
				bounds.X - focusThickness,
				bounds.Y - focusThickness,
				bounds.Width + focusThickness * 2,
				bounds.Height + focusThickness * 2
			);
			ctx.DrawRoundedRect(focusBounds, cornerRadius + focusThickness, focusColor, focusThickness);
		}
	}

	/// Gets the border color for the current state.
	protected override Color GetStateBorderColor()
	{
		let baseColor = BorderColor;
		switch (CurrentState)
		{
		case .Disabled:
			return Palette.ComputeDisabled(baseColor);
		case .Pressed:
			return Palette.ComputePressed(baseColor);
		case .Hover:
			return Palette.ComputeHover(baseColor);
		default:
			return baseColor;
		}
	}
}
