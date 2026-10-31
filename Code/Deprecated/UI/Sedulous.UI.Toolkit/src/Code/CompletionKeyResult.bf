namespace Sedulous.UI.Toolkit;

/// What the completion popup did with a key.
enum CompletionKeyResult
{
	/// Not a popup key. The editor handles it normally.
	Ignored,
	/// Popup navigation took it.
	Consumed,
	/// Commit the selected candidate.
	Accepted,
	/// The popup closed, and the editor should NOT go on to process the key.
	Dismissed
}
