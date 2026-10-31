namespace Sedulous.UI.Toolkit;

/// What an edit WAS, which is what decides whether it merges with the one before it.
///
/// Only typing, backspace and delete coalesce, and only when they are contiguous and close
/// together in time. A newline or a paste is a landmark a user expects to undo back to.
enum CodeEditKind : uint8
{
	None,
	Typing,
	Backspace,
	Delete,
	Newline,
	Paste,
	Other
}
