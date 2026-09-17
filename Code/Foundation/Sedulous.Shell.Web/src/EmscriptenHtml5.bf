using System;

namespace Sedulous.Shell.Web;

/// The slice of emscripten/html5.h and emscripten.h this shell needs.
///
/// Declared here rather than vendored as a binding project: it is a dozen entry points and
/// five event structs, against a header that only exists when the target is wasm. Every
/// signature is taken from the emsdk's own html5.h, and the structs must match it FIELD FOR
/// FIELD, since the browser writes into them.
///
/// The `target` of every registration is a CSS selector for the element the listener goes on,
/// which is the canvas for pointer and touch and the window for keys.
static class EmscriptenHtml5
{
	/// What a registration takes as its target when the listener belongs on the page rather
	/// than on one element.
	///
	/// These are MAGIC POINTER VALUES, not strings: html5.h spells them `((const char*)1)` and
	/// up, and the JS side compares the pointer before it ever tries to read a selector out of
	/// it. Passing "#window" instead registers against a target that does not resolve, and
	/// emscripten reports "the target element for event handler registration does not exist"
	/// with an undefined target, so the keyboard silently never arrives.
	public static char8* TargetDocument => (char8*)(void*)1;
	public static char8* TargetWindow => (char8*)(void*)2;
	public static char8* TargetScreen => (char8*)(void*)3;

	/// Passed as the thread to run the callback on. Zero is "the calling thread", which for a
	/// non pthreads build is the only one there is.
	public const int PthreadMain = 0;

	public typealias KeyCallback = function bool(int32 eventType, EmscriptenKeyboardEvent* event,
		void* userData);
	public typealias MouseCallback = function bool(int32 eventType, EmscriptenMouseEvent* event,
		void* userData);
	public typealias WheelCallback = function bool(int32 eventType, EmscriptenWheelEvent* event,
		void* userData);
	public typealias TouchCallback = function bool(int32 eventType, EmscriptenTouchEvent* event,
		void* userData);
	public typealias FocusCallback = function bool(int32 eventType, EmscriptenFocusEvent* event,
		void* userData);
	public typealias MainLoopCallback = function void(void* userData);

	// ---- the canvas ----

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_get_canvas_element_size(char8* target,
		int32* width, int32* height);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_canvas_element_size(char8* target,
		int32 width, int32 height);

	[CLink, CallingConvention(.Cdecl)]
	public static extern double emscripten_get_device_pixel_ratio();

	/// The element's CSS size in pixels, which is what a pointer event's coordinates are in.
	/// The BACKING size, what the canvas renders at, is the one above, and the two differ by
	/// the device pixel ratio.
	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_get_element_css_size(char8* target,
		double* width, double* height);

	// ---- the frame loop ----

	[CLink, CallingConvention(.Cdecl)]
	public static extern void emscripten_set_main_loop_arg(MainLoopCallback callback, void* arg,
		int32 fps, int32 simulateInfiniteLoop);

	[CLink, CallingConvention(.Cdecl)]
	public static extern void emscripten_cancel_main_loop();

	// ---- the listeners ----
	//
	// useCapture false throughout: the engine listens in the bubble phase, so a page that wants
	// to handle something before the canvas still can.

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_keydown_callback_on_thread(char8* target,
		void* userData, bool useCapture, KeyCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_keyup_callback_on_thread(char8* target,
		void* userData, bool useCapture, KeyCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_mousedown_callback_on_thread(char8* target,
		void* userData, bool useCapture, MouseCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_mouseup_callback_on_thread(char8* target,
		void* userData, bool useCapture, MouseCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_mousemove_callback_on_thread(char8* target,
		void* userData, bool useCapture, MouseCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_wheel_callback_on_thread(char8* target,
		void* userData, bool useCapture, WheelCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_touchstart_callback_on_thread(char8* target,
		void* userData, bool useCapture, TouchCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_touchend_callback_on_thread(char8* target,
		void* userData, bool useCapture, TouchCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_touchmove_callback_on_thread(char8* target,
		void* userData, bool useCapture, TouchCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_touchcancel_callback_on_thread(char8* target,
		void* userData, bool useCapture, TouchCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_blur_callback_on_thread(char8* target,
		void* userData, bool useCapture, FocusCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_set_focus_callback_on_thread(char8* target,
		void* userData, bool useCapture, FocusCallback callback, int targetThread);

	// ---- gamepads ----
	//
	// POLLED, not listened to, unlike everything above. A browser reveals a pad only after the
	// user presses something on it, so a pad connected at load appears mid run.

	/// Latches this frame's pad state. Nothing below reads anything new until it is called.
	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_sample_gamepad_data();

	/// NEGATIVE when the browser has no Gamepad API at all, which is not the same as zero pads.
	[CLink, CallingConvention(.Cdecl)]
	public static extern int32 emscripten_get_num_gamepads();

	[CLink, CallingConvention(.Cdecl)]
	public static extern EmscriptenResult emscripten_get_gamepad_status(int32 index,
		EmscriptenGamepadEvent* state);
}
