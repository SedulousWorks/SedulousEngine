namespace Sedulous.UI;

/// The ONE resolved chrome of a view.
///
/// Padding is the component wise MAX of three channels: the container's own Padding field,
/// the styled padding, and the background drawable's own padding. Taking the largest means a
/// padding declared through ANY of them takes effect, rather than one silently winning.
///
/// Border participates in layout, as in the CSS border box: the measured size is content plus
/// padding plus border. Margin stays the PARENT's business, since it is space between
/// siblings rather than inside this view.
struct BoxMetrics
{
	public Thickness Margin = .();
	public Thickness Padding = .();
	public Thickness Border = .();

	public this() {}

	/// Padding plus border: what deflates the content constraints.
	public Thickness Chrome => .(Padding.Left + Border.Left, Padding.Top + Border.Top,
		Padding.Right + Border.Right, Padding.Bottom + Border.Bottom);
}
