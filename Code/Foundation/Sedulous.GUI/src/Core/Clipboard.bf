using System;

namespace Sedulous.GUI;

/// The GUI core's abstract system clipboard. Text widgets cut, copy and paste through it, so the
/// core stays platform agnostic, like the platform text input (IME) seam. The concrete one lives
/// in the GUI.Shell bridge (ShellClipboard, over the shell's clipboard); tests supply a trivial
/// in-memory one. The dispatcher holds a non-owning reference a widget reaches through
/// EventDispatcher.Clipboard, which may be null (then cut, copy and paste do nothing).
interface IClipboard
{
	/// True if the clipboard holds text.
	bool HasText { get; }
	/// Appends the clipboard's text (nothing if none).
	void GetText(String outText);
	/// Replaces the clipboard's text.
	void SetText(StringView text);
}
