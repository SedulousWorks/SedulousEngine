using System;

namespace Sedulous.Core;

/// Bulk memory comparison, through the C library.
///
/// Beef's Internal.MemCmp is a BYTE AT A TIME loop. That is fine for a Guid or a vertex,
/// and ruinous for anything large: measured at 0.55 GB/s against libc memcmp's SIMD path,
/// it cost the WebGPU backend around a hundred milliseconds a frame comparing its buffer
/// shadows, which is what the C++ this was ported from does with std::memcmp for free.
///
/// Use this wherever the length is not obviously small. Internal.MemCpy is already a real
/// memcpy, so only the comparison needs the detour.
static class RawMemory
{
	[CLink, CallingConvention(.Cdecl)]
	private static extern int32 memcmp(void* left, void* right, uint length);

	/// Whether two blocks hold identical bytes. A zero length is equal, and a null with a
	/// zero length is legal here even though memcmp itself would not promise it.
	public static bool Equal(void* left, void* right, int length)
	{
		if (length <= 0)
			return true;

		return memcmp(left, right, (uint)length) == 0;
	}

	/// The sign of the first differing byte, as memcmp reports it.
	public static int32 Compare(void* left, void* right, int length)
	{
		if (length <= 0)
			return 0;

		return memcmp(left, right, (uint)length);
	}
}
