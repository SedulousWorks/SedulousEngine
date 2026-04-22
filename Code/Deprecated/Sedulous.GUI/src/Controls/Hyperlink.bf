using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A clickable hyperlink text control.
public class Hyperlink : Button
{
	private String mNavigateUri ~ delete _;
	private EventAccessor<delegate void(Hyperlink, StringView)> mRequestNavigate = new .() ~ delete _;

	/// Event raised when the hyperlink is clicked with a URI.
	public EventAccessor<delegate void(Hyperlink, StringView)> RequestNavigate => mRequestNavigate;

	/// Creates a new Hyperlink.
	public this() : base()
	{
		// Hyperlinks show a hand cursor
		Cursor = .Pointer;
	}

	/// Creates a new Hyperlink with text content.
	public this(StringView text) : base(text)
	{
		Cursor = .Pointer;
	}

	/// Creates a new Hyperlink with text and URI.
	public this(StringView text, StringView uri) : base(text)
	{
		Cursor = .Pointer;
		NavigateUri = uri;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Hyperlink";

	/// The URI to navigate to when clicked.
	public StringView NavigateUri
	{
		get => mNavigateUri ?? "";
		set
		{
			if (mNavigateUri == null)
				mNavigateUri = new String(value);
			else
				mNavigateUri.Set(value);
		}
	}

	/// Called when the hyperlink is clicked.
	protected override void OnClick()
	{
		// Raise navigation event with URI
		if (mNavigateUri != null && !mNavigateUri.IsEmpty)
			mRequestNavigate.[Friend]Invoke(this, mNavigateUri);

		// Call base for command and click event
		base.OnClick();
	}

	/// Gets the foreground color for hyperlink states.
	protected override Color GetStateForeground()
	{
		let baseColor = GetHyperlinkColor();
		switch (CurrentState)
		{
		case .Disabled:
			return Palette.ComputeDisabled(baseColor);
		case .Pressed:
			return GetVisitedColor();
		case .Hover:
			return baseColor.Interpolate(Color.White, 0.2f);
		default:
			return baseColor;
		}
	}

	/// Gets the hyperlink color (blue by default).
	protected Color GetHyperlinkColor()
	{
		let palette = Context?.Theme?.Palette ?? Palette();
		// Prefer Link color if set, otherwise Accent, otherwise fallback
		return palette.Link.A > 0 ? palette.Link :
			(palette.Accent.A > 0 ? palette.Accent : Color(0, 102, 204, 255));
	}

	/// Gets the visited color (purple by default).
	protected Color GetVisitedColor()
	{
		let palette = Context?.Theme?.Palette ?? Palette();
		return palette.LinkVisited.A > 0 ? palette.LinkVisited : Color(128, 0, 128, 255);
	}

	/// Renders the hyperlink.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Hyperlinks typically have transparent background
		// Just render the content with underline

		// Draw content (text)
		Content?.Render(ctx);

		// Draw underline on hover
		if (IsHovered || IsFocused)
		{
			let underlineColor = GetStateForeground();
			let underlineY = bounds.Bottom - 2;
			ctx.DrawLine(
				.(bounds.X, underlineY),
				.(bounds.Right, underlineY),
				underlineColor,
				1
			);
		}

		// Draw focus indicator
		if (IsFocused)
		{
			let focusColor = FocusBorderColor;
			let focusThickness = FocusBorderThickness;
			let focusBounds = RectangleF(
				bounds.X - focusThickness - 2,
				bounds.Y - focusThickness,
				bounds.Width + (focusThickness + 2) * 2,
				bounds.Height + focusThickness * 2
			);
			ctx.DrawRect(focusBounds, focusColor, focusThickness);
		}
	}

	/// Gets the background color - transparent for hyperlinks.
	protected override Color GetStateBackground()
	{
		return Color.Transparent;
	}
}
