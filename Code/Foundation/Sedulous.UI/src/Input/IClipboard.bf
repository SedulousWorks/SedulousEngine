namespace Sedulous.UI;

using System;

/// Interface for clipboard operations.
/// Defined in the UI layer to avoid Shell dependencies.
/// Applications provide an adapter that bridges their platform's clipboard.
public interface IClipboard
{
	/// Gets text from the clipboard.
	Result<void> GetText(String outText);

	/// Sets text to the clipboard.
	Result<void> SetText(StringView text);

	/// Returns whether the clipboard contains text.
	bool HasText { get; }
}
