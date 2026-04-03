using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A top-level menu bar item (File, Edit, View, etc.).
/// Contains a dropdown menu that opens when clicked.
public class MenuBarItem : Control, IPopupOwner
{
	/// Fallback ratio for estimating character width when no font metrics available.
	private const float FallbackCharWidthRatio = 0.6f;

	private String mText ~ delete _;
	private String mDisplayText ~ delete _;  // Text without '&' marker
	private TextBlock mTextBlock ~ delete _;
	private ContextMenu mDropdownMenu ~ delete _;
	private char32 mAcceleratorKey = '\0';
	private int mAcceleratorIndex = -1;  // Index in display text to underline
	private bool mIsSelected = false;
	private bool mIsDropdownOpen = false;
	private Menu mParentMenu;
	private ImageBrush? mHighlightImage;

	/// Creates a new MenuBarItem.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;
		Padding = .(8, 4, 8, 4);  // Default padding for menu items

		mTextBlock = new TextBlock();
		mDropdownMenu = new ContextMenu();
	}

	/// Creates a new MenuBarItem with text.
	/// Use '&' before a character to mark it as the accelerator key (e.g., "&File").
	public this(StringView text) : this()
	{
		Text = text;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "MenuBarItem";

	/// The menu bar item text.
	/// Use '&' before a character to mark it as the accelerator key.
	public StringView Text
	{
		get => mText ?? "";
		set
		{
			if (mText == null)
				mText = new String();
			mText.Set(value);
			ParseAcceleratorKey();
			mTextBlock.Text = mDisplayText ?? "";
			InvalidateLayout();
		}
	}

	/// The accelerator key for this menu item (auto-detected from '&' in text).
	public char32 AcceleratorKey => mAcceleratorKey;

	/// Whether the item is currently selected (highlighted).
	public bool IsSelected => mIsSelected;

	/// Whether this item's dropdown is currently open.
	public bool IsDropdownOpen => mIsDropdownOpen;

	/// The dropdown menu for this item.
	public ContextMenu DropdownMenu => mDropdownMenu;

	/// The parent Menu container.
	public Menu ParentMenu
	{
		get => mParentMenu;
		set => mParentMenu = value;
	}

	/// Image for the hover/active background.
	public ImageBrush? HighlightImage
	{
		get => mHighlightImage;
		set => mHighlightImage = value;
	}

	/// Adds a menu item to the dropdown.
	public MenuItem AddDropdownItem(StringView text)
	{
		return mDropdownMenu.AddItem(text);
	}

	/// Adds a separator to the dropdown.
	public void AddDropdownSeparator()
	{
		mDropdownMenu.AddSeparator();
	}

	/// Clears all items from the dropdown.
	public void ClearDropdownItems()
	{
		mDropdownMenu.ClearItems();
	}

	/// Sets the selected (highlighted) state.
	internal void SetSelected(bool selected)
	{
		if (mIsSelected != selected)
		{
			mIsSelected = selected;
		}
	}

	/// Opens the dropdown menu.
	internal void OpenDropdown()
	{
		if (mIsDropdownOpen || mDropdownMenu.ItemCount == 0)
			return;

		mIsDropdownOpen = true;

		// Position dropdown below this item
		let bounds = ArrangedBounds;
		mDropdownMenu.OnAttachedToContext(Context);

		mDropdownMenu.Show(this, .(bounds.X, bounds.Bottom));
	}

	/// Called when the dropdown is closed externally.
	public void OnPopupClosed(UIElement popup)
	{
		if (popup == mDropdownMenu)
		{
			mIsDropdownOpen = false;
			mParentMenu?.[Friend]OnDropdownClosed(this);
		}
	}

	/// Closes the dropdown menu.
	internal void CloseDropdown()
	{
		if (!mIsDropdownOpen)
			return;

		mDropdownMenu.Hide();
		mIsDropdownOpen = false;
	}

	/// Parses the text to extract the accelerator key.
	private void ParseAcceleratorKey()
	{
		mAcceleratorKey = '\0';
		mAcceleratorIndex = -1;

		if (mText == null || mText.IsEmpty)
		{
			if (mDisplayText != null)
				mDisplayText.Clear();
			return;
		}

		if (mDisplayText == null)
			mDisplayText = new String();
		mDisplayText.Clear();

		int displayIndex = 0;
		for (int i = 0; i < mText.Length; i++)
		{
			let c = mText[i];
			if (c == '&' && i + 1 < mText.Length)
			{
				let nextChar = mText[i + 1];
				if (nextChar == '&')
				{
					// Escaped '&&' becomes single '&'
					mDisplayText.Append('&');
					displayIndex++;
					i++;  // Skip next '&'
				}
				else
				{
					// This is the accelerator key
					mAcceleratorKey = nextChar.ToUpper;
					mAcceleratorIndex = displayIndex;
					// Don't add '&' to display text, continue normally
				}
			}
			else
			{
				mDisplayText.Append(c);
				displayIndex++;
			}
		}
	}

	// Input handling

	protected override void OnMouseEnter(MouseEventArgs e)
	{
		base.OnMouseEnter(e);

		// If another menu is open, switch to this one on hover
		if (mParentMenu != null && mParentMenu.[Friend]mOpenDropdown != null)
		{
			mParentMenu.[Friend]OpenDropdown(this);
		}
	}

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left)
		{
			if (mIsDropdownOpen)
				mParentMenu?.[Friend]CloseDropdown();
			else
				mParentMenu?.[Friend]OpenDropdown(this);
			e.Handled = true;
		}
	}

	// Layout

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		mTextBlock.Measure(constraints);
		let textSize = mTextBlock.DesiredSize;
		return .(textSize.Width + Padding.Left + Padding.Right,
				 textSize.Height + Padding.Top + Padding.Bottom);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		let textBounds = RectangleF(
			contentBounds.X + Padding.Left,
			contentBounds.Y + Padding.Top,
			contentBounds.Width - Padding.Left - Padding.Right,
			contentBounds.Height - Padding.Top - Padding.Bottom
		);
		mTextBlock.Arrange(textBounds);
	}

	// Rendering

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Get theme colors
		let palette = Context?.Theme?.Palette ?? Palette();
		let surfaceColor = palette.Surface.A > 0 ? palette.Surface : Color(45, 45, 45, 255);
		let accentColor = palette.Accent.A > 0 ? palette.Accent : Color(60, 120, 200, 255);
		let textColor = palette.Text.A > 0 ? palette.Text : Color(255, 255, 255, 255);

		// Background on hover or when dropdown open
		if (mIsSelected || IsHovered || mIsDropdownOpen)
		{
			if (mHighlightImage.HasValue && mHighlightImage.Value.IsValid)
			{
				ctx.DrawImageBrush(mHighlightImage.Value, bounds);
			}
			else
			{
				let highlightColor = mIsDropdownOpen ? accentColor : Palette.ComputeHover(surfaceColor);
				ctx.FillRect(bounds, highlightColor);
			}
		}

		// Text color - use bright text when highlighted
		let currentTextColor = (mIsSelected || IsHovered || mIsDropdownOpen) ? textColor : Foreground;
		mTextBlock.Foreground = currentTextColor;
		mTextBlock.Render(ctx);

		// Draw accelerator underline when Alt mode is active
		if (mParentMenu != null && mParentMenu.[Friend]mIsAltModeActive && mAcceleratorIndex >= 0)
		{
			RenderAcceleratorUnderline(ctx, currentTextColor);
		}
	}

	private void RenderAcceleratorUnderline(DrawContext ctx, Color textColor)
	{
		// Get the position of the accelerator character and draw underline
		let textBounds = mTextBlock.ArrangedBounds;
		let fontSize = mTextBlock.FontSize;

		// Try to use actual font measurement for accurate positioning
		float underlineX, underlineWidth;
		let fontService = mTextBlock.[Friend]GetFontService();
		let cachedFont = fontService != null ? mTextBlock.[Friend]GetCachedFont() : null;

		if (cachedFont?.Font != null && mDisplayText != null && mAcceleratorIndex < mDisplayText.Length)
		{
			// Measure text up to accelerator position for accurate X
			let prefix = scope String();
			prefix.Append(mDisplayText, 0, mAcceleratorIndex);
			underlineX = textBounds.X + cachedFont.Font.MeasureString(prefix);

			// Measure the accelerator character for width
			let accelChar = scope String();
			accelChar.Append(mDisplayText[mAcceleratorIndex]);
			underlineWidth = cachedFont.Font.MeasureString(accelChar);
		}
		else
		{
			// Fallback: approximate using character width estimate
			let charWidth = fontSize * FallbackCharWidthRatio;
			underlineX = textBounds.X + mAcceleratorIndex * charWidth;
			underlineWidth = charWidth;
		}

		let underlineY = textBounds.Y + fontSize;
		ctx.DrawLine(.(underlineX, underlineY), .(underlineX + underlineWidth, underlineY), textColor, 1);
	}

	// Hit testing - return self, not child TextBlock

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Return self to receive mouse events, not the TextBlock child
		return this;
	}

	// Visual children

	public override int VisualChildCount => 1;
	public override UIElement GetVisualChild(int index) => index == 0 ? mTextBlock : null;

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mTextBlock.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		mTextBlock.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}
}
