using System;

namespace Sedulous.Http.Client;

#if BF_PLATFORM_WASM
/// The slice of emscripten/fetch.h the browser client needs.
///
/// Declared here rather than vendored, as Net.WebSocket declares its slice of websocket.h: every
/// signature is taken from the emsdk's own fetch.h, and the structs must match it FIELD FOR FIELD,
/// because the browser reads and writes them.
///
/// Anything linking this needs `-sFETCH=1` on the emcc command line: the API lives in a JS library,
/// and it belongs to whoever links the executable.
static class EmscriptenFetch
{
	public const uint32 LoadToMemory = 1;

	public typealias Callback = function void(Fetch* fetch);

	[CRepr]
	public struct Attributes
	{
		public char8[32] RequestMethod;
		public void* UserData;
		public Callback OnSuccess;
		public Callback OnError;
		public Callback OnProgress;
		public Callback OnReadyStateChange;
		public uint32 Attributes;
		public uint32 TimeoutMSecs;
		public bool WithCredentials;
		public char8* DestinationPath;
		public char8* UserName;
		public char8* Password;
		public char8** RequestHeaders;
		public char8* OverriddenMimeType;
		public char8* RequestData;
		public uint RequestDataSize;
	}

	[CRepr]
	public struct Fetch
	{
		public uint32 Id;
		public void* UserData;
		public char8* Url;
		public char8* Data;
		public uint64 NumBytes;
		public uint64 DataOffset;
		public uint64 TotalBytes;
		public uint16 ReadyState;
		public uint16 Status;
		public char8[64] StatusText;
		public Attributes Attributes;
		public char8* ResponseUrl;
	}

	[CLink, CallingConvention(.Cdecl)]
	public static extern void emscripten_fetch_attr_init(Attributes* attributes);
	[CLink, CallingConvention(.Cdecl)]
	public static extern Fetch* emscripten_fetch(Attributes* attributes, char8* url);
	[CLink, CallingConvention(.Cdecl)]
	public static extern int32 emscripten_fetch_close(Fetch* fetch);
	[CLink, CallingConvention(.Cdecl)]
	public static extern uint emscripten_fetch_get_response_headers_length(Fetch* fetch);
	[CLink, CallingConvention(.Cdecl)]
	public static extern uint emscripten_fetch_get_response_headers(Fetch* fetch, char8* dst, uint dstSizeBytes);
	[CLink, CallingConvention(.Cdecl)]
	public static extern char8** emscripten_fetch_unpack_response_headers(char8* headersString);
	[CLink, CallingConvention(.Cdecl)]
	public static extern void emscripten_fetch_free_unpacked_response_headers(char8** unpackedHeaders);
}
#endif
