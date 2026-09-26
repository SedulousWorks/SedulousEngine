using System;

namespace Sedulous.Core;

/// The OS entropy source: what a secret or an id nobody may predict is drawn from. A seeded
/// Random is for reproducible generation, never for this.
///
/// Not Beef's Guid.Create: on Linux it seeds a Mersenne Twister from ONE 32 bit random_device
/// draw, so it can only ever produce 2^32 distinct values, which a neighbour can enumerate.
static class SystemEntropy
{
	/// Fills `out` from the OS (getentropy on Linux and Emscripten, BCryptGenRandom on
	/// Windows). False when the OS refused; the buffer is unspecified then.
	public static bool Fill(Span<uint8> outBytes)
	{
#if BF_PLATFORM_WINDOWS
		const uint32 cUseSystemPreferredRng = 0x00000002;
		return BCryptGenRandom(null, outBytes.Ptr, (uint32)outBytes.Length, cUseSystemPreferredRng) >= 0;
#else
		// getentropy caps one call at 256 bytes; fill in chunks.
		var cursor = outBytes.Ptr;
		var remaining = outBytes.Length;
		while (remaining > 0)
		{
			let chunk = Math.Min(remaining, 256);
			if (getentropy(cursor, (uint)chunk) != 0)
				return false;
			cursor += chunk;
			remaining -= chunk;
		}
		return true;
#endif
	}

#if BF_PLATFORM_WINDOWS
	/// An NTSTATUS; a negative value is a failure.
	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern int32 BCryptGenRandom(void* algorithm, uint8* buffer, uint32 count, uint32 flags);
#else
	[CLink]
	private static extern int32 getentropy(void* buffer, uint length);
#endif
}
