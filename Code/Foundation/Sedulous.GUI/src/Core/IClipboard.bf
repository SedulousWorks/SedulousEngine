namespace Sedulous.GUI;

using System;

/// Clipboard adapter interface. Implemented by the shell layer
/// (e.g. ShellClipboardAdapter) to bridge platform clipboard.
public interface IClipboard
{
	/// Reads current clipboard text into outText.
	Result<void> GetText(String outText);

	/// Sets the clipboard text.
	Result<void> SetText(StringView text);

	/// Returns true if the clipboard contains text.
	bool HasText { get; }
}
