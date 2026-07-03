namespace Sedulous.UI.Platform;

using System;

/// Adapter that bridges Sedulous.Platform.IClipboard to Sedulous.UI.IClipboard.
public class PlatformClipboardAdapter : Sedulous.UI.IClipboard
{
	private Sedulous.Platform.IClipboard mPlatformClipboard;

	public this(Sedulous.Platform.IClipboard platformClipboard)
	{
		mPlatformClipboard = platformClipboard;
	}

	public Result<void> GetText(String outText)
	{
		return mPlatformClipboard.GetText(outText);
	}

	public Result<void> SetText(StringView text)
	{
		return mPlatformClipboard.SetText(text);
	}

	public bool HasText => mPlatformClipboard.HasText;
}
