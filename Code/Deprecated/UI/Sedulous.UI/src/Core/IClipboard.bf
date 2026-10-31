using System;

namespace Sedulous.UI;

/// Clipboard access.
///
/// Declared HERE rather than taken from the shell, so the UI core stays platform agnostic.
/// The application, or the Sedulous.UI.Shell bridge, supplies the adapter.
interface IClipboard
{
	Result<void> GetText(String outText);
	Result<void> SetText(StringView text);
	bool HasText { get; }
}
