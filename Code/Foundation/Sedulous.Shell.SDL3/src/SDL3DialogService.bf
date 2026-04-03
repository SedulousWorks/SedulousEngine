namespace Sedulous.Shell.SDL3;

using System;
using System.Collections;
using SDL3;
using Sedulous.Shell;

/// SDL3 implementation of the dialog service.
class SDL3DialogService : IDialogService
{
	private SDL3WindowManager mWindowManager;

	public this(SDL3WindowManager windowManager)
	{
		mWindowManager = windowManager;
	}

	public void ShowFolderDialog(DialogResultCallback callback, StringView defaultPath = default, IWindow window = null)
	{
		let ctx = new CallbackContext(callback);

		char8* defaultPathPtr = null;
		if (!defaultPath.IsEmpty)
		{
			ctx.DefaultPath = new String(defaultPath);
			defaultPathPtr = ctx.DefaultPath.CStr();
		}

		SDL_Window* sdlWindow = GetSDLWindow(window);
		SDL_ShowOpenFolderDialog(=> OnDialogResult, Internal.UnsafeCastToPtr(ctx), sdlWindow, defaultPathPtr, false);
	}

	public void ShowOpenFileDialog(DialogResultCallback callback, Span<StringView> filters = default, StringView defaultPath = default, bool allowMultiple = false, IWindow window = null)
	{
		let ctx = new CallbackContext(callback);

		char8* defaultPathPtr = null;
		if (!defaultPath.IsEmpty)
		{
			ctx.DefaultPath = new String(defaultPath);
			defaultPathPtr = ctx.DefaultPath.CStr();
		}

		SDL_DialogFileFilter* filterPtr = null;
		int32 filterCount = 0;

		if (filters.Length > 0)
		{
			ctx.Filters = new SDL_DialogFileFilter[filters.Length];
			ctx.FilterStrings = new List<String>();

			for (int i = 0; i < filters.Length; i++)
			{
				// Parse "Name|pattern" format
				let filter = filters[i];
				let pipeIdx = filter.IndexOf('|');

				String name = new .();
				String pattern = new .();

				if (pipeIdx >= 0)
				{
					name.Set(filter.Substring(0, pipeIdx));
					pattern.Set(filter.Substring(pipeIdx + 1));
				}
				else
				{
					name.Set(filter);
					pattern.Set("*");
				}

				ctx.FilterStrings.Add(name);
				ctx.FilterStrings.Add(pattern);

				ctx.Filters[i].name = name.CStr();
				ctx.Filters[i].pattern = pattern.CStr();
			}

			filterPtr = &ctx.Filters[0];
			filterCount = (int32)filters.Length;
		}

		SDL_Window* sdlWindow = GetSDLWindow(window);
		SDL_ShowOpenFileDialog(=> OnDialogResult, Internal.UnsafeCastToPtr(ctx), sdlWindow, filterPtr, filterCount, defaultPathPtr, allowMultiple);
	}

	public void ShowSaveFileDialog(DialogResultCallback callback, Span<StringView> filters = default, StringView defaultPath = default, IWindow window = null)
	{
		let ctx = new CallbackContext(callback);

		char8* defaultPathPtr = null;
		if (!defaultPath.IsEmpty)
		{
			ctx.DefaultPath = new String(defaultPath);
			defaultPathPtr = ctx.DefaultPath.CStr();
		}

		SDL_DialogFileFilter* filterPtr = null;
		int32 filterCount = 0;

		if (filters.Length > 0)
		{
			ctx.Filters = new SDL_DialogFileFilter[filters.Length];
			ctx.FilterStrings = new List<String>();

			for (int i = 0; i < filters.Length; i++)
			{
				let filter = filters[i];
				let pipeIdx = filter.IndexOf('|');

				String name = new .();
				String pattern = new .();

				if (pipeIdx >= 0)
				{
					name.Set(filter.Substring(0, pipeIdx));
					pattern.Set(filter.Substring(pipeIdx + 1));
				}
				else
				{
					name.Set(filter);
					pattern.Set("*");
				}

				ctx.FilterStrings.Add(name);
				ctx.FilterStrings.Add(pattern);

				ctx.Filters[i].name = name.CStr();
				ctx.Filters[i].pattern = pattern.CStr();
			}

			filterPtr = &ctx.Filters[0];
			filterCount = (int32)filters.Length;
		}

		SDL_Window* sdlWindow = GetSDLWindow(window);
		SDL_ShowSaveFileDialog(=> OnDialogResult, Internal.UnsafeCastToPtr(ctx), sdlWindow, filterPtr, filterCount, defaultPathPtr);
	}

	private SDL_Window* GetSDLWindow(IWindow window)
	{
		if (window == null)
			return null;

		if (let sdl3Window = window as SDL3Window)
			return sdl3Window.Handle;

		return null;
	}

	private static void OnDialogResult(void* userdata, char8** filelist, int32 filter)
	{
		let ctx = (CallbackContext)Internal.UnsafeCastToObject(userdata);
		defer delete ctx;

		if (filelist == null || *filelist == null)
		{
			// Cancelled or error
			ctx.Callback(Span<StringView>());
			return;
		}

		// Count paths
		int count = 0;
		while (filelist[count] != null)
			count++;

		if (count == 0)
		{
			ctx.Callback(Span<StringView>());
			return;
		}

		// Build StringView array
		StringView[] paths = scope StringView[count];
		for (int i = 0; i < count; i++)
			paths[i] = StringView(filelist[i]);

		ctx.Callback(Span<StringView>(paths));
	}

	/// Context for async callback.
	class CallbackContext
	{
		public DialogResultCallback Callback ~ delete _;
		public String DefaultPath ~ delete _;
		public SDL_DialogFileFilter[] Filters ~ delete _;
		public List<String> FilterStrings ~ DeleteContainerAndItems!(_);

		public this(DialogResultCallback callback)
		{
			Callback = callback;
		}
	}
}
