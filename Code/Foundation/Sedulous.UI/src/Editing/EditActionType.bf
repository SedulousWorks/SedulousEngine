namespace Sedulous.UI;

/// What kind of edit just happened, so that consecutive ones of the same kind can be
/// coalesced into a single undo entry.
enum EditActionType
{
	None,
	CharInsert,
	Delete,
	Paste,
	Cut
}
