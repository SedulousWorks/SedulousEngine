namespace Sedulous.GUI;

/// The result of a dialog operation.
public enum DialogResult
{
	/// No result (dialog still open or cancelled without choice).
	None,
	/// User clicked OK/Accept.
	OK,
	/// User clicked Cancel or closed the dialog.
	Cancel,
	/// User clicked Yes.
	Yes,
	/// User clicked No.
	No,
	/// User clicked Retry.
	Retry,
	/// User clicked Abort.
	Abort,
	/// User clicked Ignore.
	Ignore
}
