using System;
using System.Interop;

namespace zlib_Beef;

/*
 * zlib - deflate and inflate.
 *
 * Source: https://github.com/madler/zlib (release v1.3.2, https://zlib.net)
 * License: zlib (see zlib/LICENSE).
 *
 * Built with Z_PREFIX, so every symbol is z_-prefixed: a library loaded beside the engine that
 * carries a zlib of its own cannot be confused with this one. zlib's stream is bound as it is,
 * since its layout is zlib's ABI and no configuration changes it; uLong is C's unsigned long,
 * 64 bits on Linux64 and 32 on Windows and wasm, hence c_ulong. The surface grows with what the
 * engine needs.
 */

/// zlib's z_stream.
[CRepr]
struct ZStream
{
	public uint8* NextIn;
	public c_uint AvailIn;
	public c_ulong TotalIn;

	public uint8* NextOut;
	public c_uint AvailOut;
	public c_ulong TotalOut;

	/// The last error's message, null when none.
	public char8* Msg;
	public void* State;

	/// Null for zlib's own malloc and free.
	public void* ZAlloc;
	public void* ZFree;
	public void* Opaque;

	public c_int DataType;
	public c_ulong Adler;
	public c_ulong Reserved;
}

static
{
	public const String ZLIB_VERSION = "1.3.2";

	public const c_int Z_NO_FLUSH = 0;
	public const c_int Z_FINISH = 4;

	public const c_int Z_OK = 0;
	public const c_int Z_STREAM_END = 1;
	public const c_int Z_NEED_DICT = 2;
	public const c_int Z_STREAM_ERROR = -2;
	public const c_int Z_DATA_ERROR = -3;
	public const c_int Z_MEM_ERROR = -4;
	public const c_int Z_BUF_ERROR = -5;

	/// The largest window: 32 KB. Negated for inflateInit2, raw deflate (no zlib header).
	public const c_int MAX_WBITS = 15;

	/// The library's version, "1.3.2". Static storage.
	[CLink] public static extern char8* z_zlibVersion();

	/// inflateInit2's function: inflateInit2 is a macro over it, passing the version and the
	/// stream's size, which z_inflateInit2 below does.
	[CLink] public static extern c_int z_inflateInit2_(ZStream* strm, c_int windowBits, char8* version, c_int streamSize);
	[CLink] public static extern c_int z_inflate(ZStream* strm, c_int flush);
	[CLink] public static extern c_int z_inflateEnd(ZStream* strm);

	/// The CRC-32 of `len` bytes, continuing from `crc` (0 to start).
	[CLink] public static extern c_ulong z_crc32(c_ulong crc, uint8* buf, c_uint len);

	/// zlib.h's inflateInit2 macro.
	public static c_int z_inflateInit2(ZStream* strm, c_int windowBits) =>
		z_inflateInit2_(strm, windowBits, "1.3.2", (c_int)sizeof(ZStream)); // ZLIB_VERSION
}
