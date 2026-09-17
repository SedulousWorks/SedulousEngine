using System;

namespace Sedulous.Net.WebSocket;

#if BF_PLATFORM_WASM
/// The slice of emscripten/websocket.h the browser client socket needs.
///
/// Declared here rather than vendored, the same way Shell.Web declares its slice of html5.h:
/// it is six entry points and four event structs, against a header that only exists when the
/// target is wasm. Every signature is taken from the emsdk's own websocket.h and the structs
/// must match it FIELD FOR FIELD, because the browser writes into them.
///
/// Anything linking this needs `-lwebsocket.js` on the emcc command line. The API lives in a
/// JS library rather than in libc, so without it the wasm link fails on every entry point
/// below, and it cannot be declared from here: it belongs to whoever links the executable.
static class EmscriptenWebSocket
{
	/// The thread a callback is delivered on. The header's plain
	/// emscripten_websocket_set_on*_callback macros pass this one, which means the thread that
	/// registered it; for a build without pthreads that is the only thread there is.
	public const int CallingThread = 0x2;

	[CRepr]
	public struct OpenEvent
	{
		public int32 Socket;
	}

	[CRepr]
	public struct MessageEvent
	{
		public int32 Socket;
		public uint8* Data;
		public uint32 NumBytes;
		public bool IsText;
	}

	[CRepr]
	public struct ErrorEvent
	{
		public int32 Socket;
	}

	[CRepr]
	public struct CloseEvent
	{
		public int32 Socket;
		public bool WasClean;
		public uint16 Code;
		public char8[512] Reason;
	}

	[CRepr]
	public struct CreateAttributes
	{
		public char8* Url;
		public char8* Protocols;
		/// True puts the socket on the main browser thread, which is where our frame loop
		/// runs, so the callbacks land somewhere that can see the queues they write.
		public bool CreateOnMainThread;
	}

	public typealias OpenCallback = function bool(int32 eventType, OpenEvent* event, void* userData);
	public typealias MessageCallback = function bool(int32 eventType, MessageEvent* event, void* userData);
	public typealias ErrorCallback = function bool(int32 eventType, ErrorEvent* event, void* userData);
	public typealias CloseCallback = function bool(int32 eventType, CloseEvent* event, void* userData);

	[CLink, CallingConvention(.Cdecl)]
	public static extern bool emscripten_websocket_is_supported();

	[CLink, CallingConvention(.Cdecl)]
	public static extern int32 emscripten_websocket_new(CreateAttributes* attributes);

	[CLink, CallingConvention(.Cdecl)]
	public static extern int32 emscripten_websocket_set_onopen_callback_on_thread(int32 socket,
		void* userData, OpenCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern int32 emscripten_websocket_set_onmessage_callback_on_thread(int32 socket,
		void* userData, MessageCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern int32 emscripten_websocket_set_onerror_callback_on_thread(int32 socket,
		void* userData, ErrorCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern int32 emscripten_websocket_set_onclose_callback_on_thread(int32 socket,
		void* userData, CloseCallback callback, int targetThread);

	[CLink, CallingConvention(.Cdecl)]
	public static extern int32 emscripten_websocket_send_binary(int32 socket, void* data,
		uint32 length);

	[CLink, CallingConvention(.Cdecl)]
	public static extern int32 emscripten_websocket_close(int32 socket, uint16 code,
		char8* reason);

	[CLink, CallingConvention(.Cdecl)]
	public static extern int32 emscripten_websocket_delete(int32 socket);
}
#endif
