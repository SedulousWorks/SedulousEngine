using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// The web shell's window IS an HTML canvas.
///
/// Its size comes from the live element rather than from anything this holds, because CSS can
/// resize a canvas at any moment with no event to listen for, so QuerySize re-polls it every
/// frame and the manager turns a change into a Resized event.
///
/// Native hands back the canvas CSS SELECTOR, which is what the WebGPU backend turns into a
/// surface through WGPUEmscriptenSurfaceSourceCanvasHTMLSelector. That is why the selector is
/// stored rather than borrowed: the pointer has to outlive the call.
class WebWindow : IWindow
{
	private uint32 mId;
	private String mSelector = new .() ~ delete _;
	private uint32 mWidth;
	private uint32 mHeight;
	private bool mOpen = true;
	private bool mTextInput;

	public this(uint32 id, StringView selector, WindowSettings settings)
	{
		mId = id;
		mSelector.Set(selector);
		mWidth = settings.Width;
		mHeight = settings.Height;
		QuerySize(); // seed from the live canvas where it is already sized
	}

	public uint32 Id => mId;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;

	/// A canvas has no screen position: it sits where the page puts it.
	public int32 X => 0;
	public int32 Y => 0;
	public void SetPosition(int32 x, int32 y) {}

	public void SetSize(uint32 width, uint32 height)
	{
		mWidth = width;
		mHeight = height;
#if BF_PLATFORM_WASM
		EmscriptenHtml5.emscripten_set_canvas_element_size(mSelector, (int32)width, (int32)height);
#endif
	}

	/// The browser's device pixel ratio, which is what a canvas has instead of a monitor scale.
	public float ContentScale
	{
		get
		{
#if BF_PLATFORM_WASM
			let ratio = EmscriptenHtml5.emscripten_get_device_pixel_ratio();
			return (ratio > 0.0) ? (float)ratio : 1.0f;
#else
			return 1.0f;
#endif
		}
	}

	/// The RHI reads Window as the canvas CSS selector. See NativeWindow, which documents Web
	/// as exactly that.
	public NativeWindow Native
	{
		get
		{
			NativeWindow native = .();
			native.System = .Web;
			native.Display = null;
			native.Window = (void*)mSelector.CStr();
			return native;
		}
	}

	public bool IsOpen => mOpen;
	/// A canvas is never minimised; a hidden page stops painting instead, which the frame
	/// callback sees as simply not being called.
	public bool IsMinimized => false;
	public void Close() => mOpen = false;

	public void StartTextInput() => mTextInput = true;
	public void StopTextInput() => mTextInput = false;
	public bool IsTextInputActive => mTextInput;

	public StringView Selector => mSelector;

	/// Re-polls the live canvas. True when the size MOVED, which is what makes the manager
	/// emit a Resized event; the browser has no resize queue to drain.
	public bool QuerySize()
	{
#if BF_PLATFORM_WASM
		int32 width = 0;
		int32 height = 0;
		if (EmscriptenHtml5.emscripten_get_canvas_element_size(mSelector, &width, &height)
			!= .Success)
			return false;

		if ((width <= 0) || (height <= 0))
			return false;

		let newWidth = (uint32)width;
		let newHeight = (uint32)height;
		if ((newWidth == mWidth) && (newHeight == mHeight))
			return false;

		mWidth = newWidth;
		mHeight = newHeight;
		return true;
#else
		return false;
#endif
	}
}
