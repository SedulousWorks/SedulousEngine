namespace Sedulous.UI;

/// Layout-specific metadata stored on the child. Each ViewGroup subclass
/// can define its own LayoutParams subclass with additional fields
/// (e.g., LinearLayout.LayoutParams adds Weight and Gravity).
public class LayoutParams
{
	/// Sentinel: child should fill the parent along this axis.
	public const float MatchParent = -1;
	/// Sentinel: child should be just big enough for its content.
	public const float WrapContent = -2;

	public float Width = WrapContent;
	public float Height = WrapContent;
	public Thickness Margin;
}
