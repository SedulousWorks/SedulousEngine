namespace Sedulous.GUI;

/// Base layout parameters attached to a child view by its parent container.
/// Each layout container subclasses this with container-specific fields
/// (e.g. FlexLayout.LayoutParams adds Grow, Shrink, AlignSelf).
public class LayoutParams
{
	public SizeSpec Width = .Wrap;
	public SizeSpec Height = .Wrap;
	public Thickness Margin;
}
