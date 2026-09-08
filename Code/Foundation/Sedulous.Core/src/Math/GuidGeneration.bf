using System;

namespace System;

/// Generating a Guid from a CALLER OWNED random source.
///
/// Beef's Guid.Create draws on system entropy, which is right for an id nobody needs to
/// reproduce and wrong for one that does: a scene owns its generator so a run that starts
/// from the same seed produces the same ids, which is what makes a generated world
/// reproducible and a test repeatable.
extension Guid
{
	/// An RFC 4122 version 4 Guid drawn from `rng`.
	public static Guid Generate(ref Sedulous.Core.Random rng)
	{
		var high = rng.NextU64();
		var low = rng.NextU64();

		// Version 4 and the RFC 4122 variant, 10xx.
		high = (high & 0xFFFFFFFFFFFF0FFFUL) | 0x0000000000004000UL;
		low = (low & 0x3FFFFFFFFFFFFFFFUL) | 0x8000000000000000UL;

		return .((uint32)(high >> 32), (uint16)(high >> 16), (uint16)high,
			(uint8)(low >> 56), (uint8)(low >> 48), (uint8)(low >> 40), (uint8)(low >> 32),
			(uint8)(low >> 24), (uint8)(low >> 16), (uint8)(low >> 8), (uint8)low);
	}
}
