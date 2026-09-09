namespace Sedulous.UI;

/// Whether a view takes part in its container's flow.
enum Position
{
	/// Laid out by the container, under whatever rules that container has.
	Static,
	/// Taken OUT of the flow and placed against the container's content box from the
	/// Left, Top, Right and Bottom insets, as CSS absolute positioning does.
	Absolute
}
