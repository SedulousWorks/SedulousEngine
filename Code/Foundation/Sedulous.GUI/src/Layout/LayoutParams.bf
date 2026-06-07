namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;

/// Base layout parameters for a view within a container.
/// Container-specific subclasses add layout-specific fields
/// (e.g., FlexLayout.LayoutParams adds Grow/Shrink).
public class LayoutParams
{
	/// Desired width. Default: Wrap (fit to content).
	public SizeSpec Width = .Wrap;

	/// Desired height. Default: Wrap (fit to content).
	public SizeSpec Height = .Wrap;

	/// Margin around this view (space between this view and siblings/parent).
	public Thickness Margin;
}
