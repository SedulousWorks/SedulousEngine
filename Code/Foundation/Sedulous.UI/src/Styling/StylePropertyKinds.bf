namespace Sedulous.UI;

/// What a style property's KIND implies for transitions.
static class StylePropertyKinds
{
	/// Whether a change to this property can never move geometry.
	///
	/// A transition on one of these marks REDRAW damage each frame; everything else marks
	/// LAYOUT damage. The decision belongs to the PROPERTY, never to the rule that set it:
	/// deciding per rule is how a theme ends up relaying out every frame.
	public static bool IsVisualOnly(StyleProperty property)
	{
		switch (property)
		{
		case .Background, .CheckedBackground, .MenuItemHoverDrawable,
			 .TextColor, .TextDimColor, .PlaceholderColor, .BorderColor, .CursorColor,
			 .SelectionColor, .AccentColor, .SuccessColor, .WarningColor, .ErrorColor,
			 .CornerRadius, .Opacity, .BoxShadow, .ZIndex, .Overflow, .Transition,
			 .TextOverflow:
			return true;
		default:
			return false;
		}
	}

	/// Whether a `transition` can animate this property: colours, floats, thicknesses,
	/// lengths, the box shadow, and Background, whose drawables cross fade rather than
	/// interpolate.
	public static bool IsAnimatable(StyleProperty property)
	{
		switch (property)
		{
		case .Background,
			 .TextColor, .TextDimColor, .PlaceholderColor, .BorderColor, .CursorColor,
			 .SelectionColor, .AccentColor, .SuccessColor, .WarningColor, .ErrorColor,
			 .FontSize, .CornerRadius, .BorderWidth, .Spacing, .Opacity, .Width, .Height,
			 .Padding, .Margin, .BoxShadow,
			 .MinWidth, .MinHeight, .MaxWidth, .MaxHeight,
			 .Top, .Right, .Bottom, .Left,
			 .FlexGrow, .FlexShrink, .FlexBasis:
			return true;
		default:
			return false;
		}
	}
}
