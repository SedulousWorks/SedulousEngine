using System;
using Sedulous.Core;
using Sedulous.Shell;
using Sedulous.UI;

namespace Sedulous.UI.Shell;

/// The platform clipboard, behind the UI's own IClipboard seam.
///
/// The UI declares the seam rather than taking the shell's, so the core stays platform
/// agnostic; this is the adapter an application plugs in to make a text field's cut, copy and
/// paste work.
///
/// The shell is BORROWED.
class ShellClipboard : IClipboard
{
	private IShell mShell;

	public this(IShell shell)
	{
		mShell = shell;
	}

	public Result<void> GetText(String outText)
	{
		if (mShell == null)
			return .Err;

		mShell.GetClipboardText(outText);
		return .Ok;
	}

	public Result<void> SetText(StringView text)
	{
		if (mShell == null)
			return .Err;

		mShell.SetClipboardText(text);
		return .Ok;
	}

	public bool HasText => (mShell != null) && mShell.HasClipboardText;
}
