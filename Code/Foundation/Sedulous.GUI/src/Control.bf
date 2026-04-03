using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// The visual state of a control.
public enum ControlState
{
	/// Normal state.
	Normal,
	/// Mouse is hovering over the control.
	Hover,
	/// Control is being pressed.
	Pressed,
	/// Control is disabled.
	Disabled,
	/// Control has keyboard focus.
	Focused
}

/// Base class for interactive controls with theming and state management.
/// Controls can be focused, enabled/disabled, and have visual states.
public abstract class Control : UIElement
{
	// State
	private bool mIsEnabled = true;
	private bool mIsHovered = false;
	private bool mIsPressed = false;
	private ControlState mCurrentState = .Normal;

	// Theming - null means use theme, explicit value overrides theme
	private Color? mBackground;
	private Color? mForeground;
	private Color? mBorderColor;
	private float? mBorderThickness;
	private float mCornerRadius = -1; // -1 means "use control-specific default" (Button uses 4, others use 0)
	private Thickness? mControlPadding;

	// Image-based background - null means use theme or color fallback
	private ImageBrush? mBackgroundImage;

	// Focus visual - null means use theme
	private Color? mFocusBorderColor;
	private float? mFocusBorderThickness;

	// Tooltip text
	private String mTooltipText ~ delete _;

	// Context menu (owned by the control)
	private ContextMenu mContextMenu ~ delete _;
	private EventAccessor<delegate void(ContextMenuEventArgs)> mContextMenuOpening = new .() ~ delete _;

	/// Creates a Control with focus enabled by default.
	public this()
	{
		// Controls are focusable and tab-navigable by default
		IsFocusable = true;
		IsTabStop = true;
	}

	/// Whether this control is enabled.
	public bool IsEnabled
	{
		get => mIsEnabled;
		set
		{
			if (mIsEnabled != value)
			{
				mIsEnabled = value;
				UpdateControlState();
			}
		}
	}

	/// Whether this control is effectively enabled (considering parent chain).
	public bool IsEffectivelyEnabled
	{
		get
		{
			if (!mIsEnabled)
				return false;
			if (let parentControl = Parent as Control)
				return parentControl.IsEffectivelyEnabled;
			return true;
		}
	}


	/// Whether the mouse is hovering over this control.
	public bool IsHovered
	{
		get => mIsHovered;
		set
		{
			if (mIsHovered != value)
			{
				mIsHovered = value;
				UpdateControlState();
			}
		}
	}

	/// Whether this control is being pressed.
	public bool IsPressed
	{
		get => mIsPressed;
		set
		{
			if (mIsPressed != value)
			{
				mIsPressed = value;
				UpdateControlState();
			}
		}
	}

	/// The current visual state of the control.
	public ControlState CurrentState => mCurrentState;

	// === Theming Properties ===

	/// The control type name used for theme style lookup.
	/// Override in subclasses to use specific theme styles.
	protected virtual StringView ControlTypeName => "Control";

	/// Gets the theme style for this control type.
	protected ControlStyle GetThemeStyle()
	{
		if (Context?.Theme != null)
			return Context.Theme.GetControlStyle(ControlTypeName);
		return default;
	}

	/// Background color. Set to override theme.
	public Color Background
	{
		get => mBackground ?? GetThemeStyle().Background;
		set => mBackground = value;
	}

	/// Foreground (text) color. Set to override theme.
	public Color Foreground
	{
		get => mForeground ?? GetThemeStyle().Foreground;
		set => mForeground = value;
	}

	/// Border color. Set to override theme.
	public Color BorderColor
	{
		get => mBorderColor ?? GetThemeStyle().BorderColor;
		set => mBorderColor = value;
	}

	/// Border thickness. Set to override theme.
	public float BorderThickness
	{
		get => mBorderThickness ?? GetThemeStyle().BorderThickness;
		set
		{
			if (mBorderThickness != value)
			{
				mBorderThickness = value;
				InvalidateLayout();
			}
		}
	}

	/// Corner radius for rounded corners.
	public float CornerRadius
	{
		get => mCornerRadius;
		set => mCornerRadius = value;
	}

	/// Background image (nine-slice or stretched). Set to override theme.
	/// When set, replaces both color-based background and border rendering.
	public ImageBrush? BackgroundImage
	{
		get => mBackgroundImage;
		set => mBackgroundImage = value;
	}

	/// Padding (space inside the control). Set to override theme.
	/// Falls back to theme-defined padding for the control type.
	public new Thickness Padding
	{
		get => mControlPadding ?? GetThemeStyle().Padding;
		set
		{
			mControlPadding = value;
			base.Padding = value;
		}
	}

	/// Gets the effective padding, using theme default if not explicitly set.
	protected override Thickness GetEffectivePadding()
	{
		if (mControlPadding.HasValue)
			return mControlPadding.Value;

		return GetThemeStyle().Padding;
	}

	/// Focus indicator border color. Set to override theme.
	public Color FocusBorderColor
	{
		get => mFocusBorderColor ?? Context?.Theme?.FocusIndicatorColor ?? Color(100, 149, 237, 255);
		set => mFocusBorderColor = value;
	}

	/// Focus indicator border thickness. Set to override theme.
	public float FocusBorderThickness
	{
		get => mFocusBorderThickness ?? Context?.Theme?.FocusIndicatorThickness ?? 2;
		set => mFocusBorderThickness = value;
	}

	/// Tooltip text shown when hovering over this control.
	public StringView TooltipText
	{
		get => mTooltipText ?? "";
		set
		{
			if (mTooltipText == null)
				mTooltipText = new String(value);
			else
				mTooltipText.Set(value);
		}
	}

	/// The context menu shown on right-click.
	/// The control takes ownership and will delete the menu.
	public ContextMenu ContextMenu
	{
		get => mContextMenu;
		set
		{
			if (mContextMenu != null)
				delete mContextMenu;
			mContextMenu = value;
		}
	}

	/// Event fired before a context menu is shown. Set Cancel to true to prevent it.
	public EventAccessor<delegate void(ContextMenuEventArgs)> ContextMenuOpening => mContextMenuOpening;

	/// Updates the current control state based on flags.
	protected void UpdateControlState()
	{
		if (!IsEffectivelyEnabled)
			mCurrentState = .Disabled;
		else if (mIsPressed)
			mCurrentState = .Pressed;
		else if (IsFocused)
			mCurrentState = .Focused;
		else if (mIsHovered)
			mCurrentState = .Hover;
		else
			mCurrentState = .Normal;
	}

	/// Gets the background color for the current state.
	protected virtual Color GetStateBackground()
	{
		let baseColor = Background;
		switch (mCurrentState)
		{
		case .Disabled:
			return Palette.ComputeDisabled(baseColor);
		case .Pressed:
			return Palette.ComputePressed(baseColor);
		case .Hover:
			return Palette.ComputeHover(baseColor);
		case .Focused:
			// Focused state uses base color (focus is shown via border)
			return baseColor;
		default:
			return baseColor;
		}
	}

	/// Gets the foreground color for the current state.
	protected virtual Color GetStateForeground()
	{
		let baseColor = Foreground;
		switch (mCurrentState)
		{
		case .Disabled:
			return Palette.ComputeDisabled(baseColor);
		default:
			return baseColor;
		}
	}

	/// Gets the border color for the current state.
	protected virtual Color GetStateBorderColor()
	{
		if (IsFocused)
			return FocusBorderColor;
		let baseColor = BorderColor;
		switch (mCurrentState)
		{
		case .Disabled:
			return Palette.ComputeDisabled(baseColor);
		case .Hover:
			return Palette.ComputeHover(baseColor);
		default:
			return baseColor;
		}
	}

	/// Gets the border thickness for the current state.
	protected virtual float GetStateBorderThickness()
	{
		if (IsFocused)
			return FocusBorderThickness;
		return BorderThickness;
	}

	/// Gets the background image for the current state.
	/// Checks per-instance override first, then theme.
	/// Returns null if no image is configured.
	protected ImageBrush? GetStateBackgroundImage()
	{
		// Per-instance override with auto-tint modulation
		if (mBackgroundImage.HasValue && mBackgroundImage.Value.IsValid)
		{
			var img = mBackgroundImage.Value;
			img.Tint = ControlStyle.ModulateTint(img.Tint, mCurrentState);
			return img;
		}

		// Theme-based image
		return GetThemeStyle().GetBackgroundImage(mCurrentState);
	}

	/// Renders the control background and border.
	protected virtual void RenderBackground(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Try image-based background first
		let bgImage = GetStateBackgroundImage();
		if (bgImage.HasValue && bgImage.Value.IsValid)
		{
			ctx.DrawImageBrush(bgImage.Value, bounds);
			return; // Image replaces both color fill and border
		}

		// Color-based fallback
		let bgColor = GetStateBackground();
		let borderColor = GetStateBorderColor();
		let borderThickness = GetStateBorderThickness();

		// Draw background
		if (bgColor.A > 0)
		{
			if (mCornerRadius > 0)
				ctx.FillRoundedRect(bounds, mCornerRadius, bgColor);
			else
				ctx.FillRect(bounds, bgColor);
		}

		// Draw border
		if (borderThickness > 0 && borderColor.A > 0)
		{
			if (mCornerRadius > 0)
			{
				// For rounded borders, we'd need a stroke rounded rect
				// For now, just draw a regular rect outline
				ctx.DrawRect(bounds, borderColor, borderThickness);
			}
			else
			{
				ctx.DrawRect(bounds, borderColor, borderThickness);
			}
		}
	}

	/// Default render implementation draws background/border.
	protected override void RenderOverride(DrawContext ctx)
	{
		RenderBackground(ctx);
	}

	// === Input Handling ===

	protected override void OnMouseEnter(MouseEventArgs e)
	{
		IsHovered = true;
		base.OnMouseEnter(e);
	}

	protected override void OnMouseLeave(MouseEventArgs e)
	{
		IsHovered = false;
		IsPressed = false;
		base.OnMouseLeave(e);
	}

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		if (e.Button == .Left && IsEffectivelyEnabled)
		{
			IsPressed = true;
			// Request focus when clicked
			if (IsFocusable)
				Context?.FocusManager?.SetFocus(this);
		}
		else if (e.Button == .Right && IsEffectivelyEnabled && Context != null)
		{
			// Find context menu - check this control and ancestors
			ContextMenu menu = mContextMenu;
			UIElement menuOwner = this;

			if (menu == null)
			{
				// Search up parent chain for a context menu
				var parent = Parent;
				while (parent != null && menu == null)
				{
					if (let parentControl = parent as Control)
					{
						if (parentControl.ContextMenu != null)
						{
							menu = parentControl.ContextMenu;
							menuOwner = parentControl;
							break;
						}
					}
					parent = parent.Parent;
				}
			}

			if (menu != null)
			{
				// Fire ContextMenuOpening event to allow cancellation
				let args = scope ContextMenuEventArgs();
				args.Menu = menu;
				args.Owner = menuOwner as Control;
				args.Cancel = false;
				mContextMenuOpening.[Friend]Invoke(args);

				if (!args.Cancel)
				{
					// Attach context menu to context if needed
					if (menu.Context == null)
						menu.OnAttachedToContext(Context);
					// Show context menu on right-click
					menu.Show(menuOwner, .(e.ScreenX, e.ScreenY));
				}
				e.Handled = true;
			}
		}
		base.OnMouseDown(e);
	}

	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		if (e.Button == .Left)
		{
			IsPressed = false;
		}
		base.OnMouseUp(e);
	}

	protected override void OnGotFocus(FocusEventArgs e)
	{
		UpdateControlState();
		base.OnGotFocus(e);
	}

	protected override void OnLostFocus(FocusEventArgs e)
	{
		UpdateControlState();
		base.OnLostFocus(e);
	}
}
