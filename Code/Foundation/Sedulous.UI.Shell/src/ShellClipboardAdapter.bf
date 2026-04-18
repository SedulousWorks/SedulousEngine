namespace Sedulous.UI.Shell;

using System;

/// Adapter that bridges Sedulous.Shell.IClipboard to Sedulous.UI.IClipboard.
public class ShellClipboardAdapter : Sedulous.UI.IClipboard
{
	private Sedulous.Shell.IClipboard mShellClipboard;

	public this(Sedulous.Shell.IClipboard shellClipboard)
	{
		mShellClipboard = shellClipboard;
	}

	public Result<void> GetText(String outText)
	{
		return mShellClipboard.GetText(outText);
	}

	public Result<void> SetText(StringView text)
	{
		return mShellClipboard.SetText(text);
	}

	public bool HasText => mShellClipboard.HasText;
}
