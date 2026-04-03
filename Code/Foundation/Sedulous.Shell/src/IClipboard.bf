using System;

namespace Sedulous.Shell;

/// Interface for clipboard operations.
public interface IClipboard
{
	/// Gets text from the clipboard.
	/// Returns .Ok if text was retrieved, .Err otherwise.
	Result<void> GetText(String outText);

	/// Sets text to the clipboard.
	/// Returns .Ok if text was set, .Err otherwise.
	Result<void> SetText(StringView text);

	/// Returns whether the clipboard contains text.
	bool HasText { get; }
}
