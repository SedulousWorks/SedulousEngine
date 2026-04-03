using System;
using SDL3;

namespace Sedulous.Shell.SDL3;

/// SDL3 implementation of clipboard operations.
internal class SDL3Clipboard : IClipboard
{
	public bool HasText => SDL_HasClipboardText();

	public Result<void> GetText(String outText)
	{
		let text = SDL_GetClipboardText();
		if (text == null)
			return .Err;

		outText.Append(StringView(text));
		SDL_free(text);
		return .Ok;
	}

	public Result<void> SetText(StringView text)
	{
		// Need null-terminated string for SDL
		let cstr = text.ToScopeCStr!();
		if (SDL_SetClipboardText(cstr))
			return .Ok;
		return .Err;
	}
}
