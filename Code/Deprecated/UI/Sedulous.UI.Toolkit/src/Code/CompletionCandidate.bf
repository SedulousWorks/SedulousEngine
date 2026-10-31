using System;

namespace Sedulous.UI.Toolkit;

/// One entry in the completion popup.
///
/// A class rather than a value, because it OWNS two strings and the merged list is moved
/// between the providers, the model and the popup.
class CompletionCandidate
{
	/// Shown in the popup, and what the typed prefix is matched against.
	public String Label = new .() ~ delete _;
	/// Replaces the prefix on accept. Usually the same as the label.
	public String InsertText = new .() ~ delete _;
	/// Sort tier: lower ranks first. Context providers use zero, harvested words a hundred,
	/// so a member suggestion is never buried under the buffer's vocabulary.
	public uint8 Priority = 0;

	public this() {}

	public this(StringView label, StringView insertText, uint8 priority = 0)
	{
		Label.Set(label);
		InsertText.Set(insertText);
		Priority = priority;
	}
}
