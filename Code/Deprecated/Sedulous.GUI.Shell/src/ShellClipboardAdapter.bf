namespace Sedulous.LegacyGUI.Shell;

using System;

/// Adapter that bridges Sedulous.Shell.IClipboard to Sedulous.LegacyGUI.IClipboard.
public class ShellClipboardAdapter : Sedulous.LegacyGUI.IClipboard
{
	private Sedulous.Shell.IClipboard mShellClipboard;

	public this(Sedulous.Shell.IClipboard shellClipboard)
	{
		mShellClipboard = shellClipboard;
	}

	public ~this()
	{
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
