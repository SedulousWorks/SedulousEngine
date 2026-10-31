namespace Sedulous.UI;

/// Which style properties INHERIT.
static class InheritableStyle
{
	/// The text properties take the parent's COMPUTED value when nothing sets them on the view
	/// itself, which is what lets a font size on a panel reach every label inside it.
	public static bool IsInheritable(StyleProperty property)
	{
		switch (property)
		{
		case .TextColor, .TextDimColor, .FontSize, .FontFamily, .WordWrap:
			return true;
		default:
			return false;
		}
	}
}
