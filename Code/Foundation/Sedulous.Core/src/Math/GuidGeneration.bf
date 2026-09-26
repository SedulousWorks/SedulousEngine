using System;

namespace System;

/// Generating a Guid from a CALLER OWNED random source, or from the OS.
///
/// A scene owns its generator so a run that starts from the same seed produces the same ids,
/// which is what makes a generated world reproducible and a test repeatable. A secret (a
/// token) is the opposite case: nobody may predict or replay it, so it comes from the OS.
extension Guid
{
	/// An RFC 4122 version 4 Guid drawn from `rng`.
	public static Guid Generate(ref Sedulous.Core.Random rng)
	{
		return Tagged(rng.NextU64(), rng.NextU64());
	}

	/// An RFC 4122 version 4 Guid from OS entropy: one nobody can predict or replay (a
	/// secret, a token), never for an id that must reproduce from a seed. False when the OS
	/// refused entropy; `outGuid` is untouched then.
	public static bool TryGenerateFromSystemEntropy(out Guid outGuid)
	{
		outGuid = default;
		uint64[2] words = default;
		if (!Sedulous.Core.SystemEntropy.Fill(.((uint8*)&words, sizeof(uint64[2]))))
			return false;
		outGuid = Tagged(words[0], words[1]);
		return true;
	}

	/// The version (4) and variant (RFC 4122, 10xx) bits over 128 random bits.
	private static Guid Tagged(uint64 highBits, uint64 lowBits)
	{
		let high = (highBits & 0xFFFFFFFFFFFF0FFFUL) | 0x0000000000004000UL;
		let low = (lowBits & 0x3FFFFFFFFFFFFFFFUL) | 0x8000000000000000UL;

		return .((uint32)(high >> 32), (uint16)(high >> 16), (uint16)high,
			(uint8)(low >> 56), (uint8)(low >> 48), (uint8)(low >> 40), (uint8)(low >> 32),
			(uint8)(low >> 24), (uint8)(low >> 16), (uint8)(low >> 8), (uint8)low);
	}
}
