namespace Sedulous.UI;

/// How a Dialog was closed.
enum DialogResult
{
	/// Closed without a decision, and what a dialog holds until one is made. A button given
	/// this result is CALLER MANAGED: it does not close the dialog by itself.
	None,
	OK,
	Cancel
}
