using System;
namespace Sedulous.GUI;

/// Interface for clipboard operations.
/// This interface is defined in the GUI layer to avoid Shell dependencies.
/// Applications should implement an adapter that bridges their platform's clipboard.
public interface IClipboard
{
	/// Gets text from the clipboard.
	/// @param outText String to receive the clipboard text.
	/// @return Ok on success, Err if clipboard is empty or unavailable.
	Result<void> GetText(String outText);

	/// Sets text to the clipboard.
	/// @param text The text to copy to the clipboard.
	/// @return Ok on success, Err if clipboard is unavailable.
	Result<void> SetText(StringView text);

	/// Returns whether the clipboard contains text.
	bool HasText { get; }
}
