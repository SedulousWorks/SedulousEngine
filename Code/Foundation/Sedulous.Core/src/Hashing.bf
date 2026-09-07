using System;

namespace Sedulous.Core;

/// The engine's hashes.
///
/// Beef's own GetHashCode is fine for a dictionary within one run, but these are for
/// values that OUTLIVE a run: a type id in a saved file, a string identity compared across
/// a network. They are fixed algorithms with fixed constants, and changing either is a
/// format change.
static
{
	public const uint64 FnvOffsetBasis = 1469598103934665603UL;
	public const uint64 FnvPrime = 1099511628211UL;

	/// FNV-1a over raw bytes.
	///
	/// The seed is exposed so a caller can chain: hashing part two with part one's result
	/// gives the same answer as hashing the whole.
	public static uint64 HashBytes(void* data, int size, uint64 seed = FnvOffsetBasis)
	{
		let bytes = (uint8*)data;
		var hash = seed;
		for (int i < size)
		{
			hash ^= (uint64)bytes[i];
			// &* because FNV RELIES on the multiply wrapping. Plain arithmetic traps on
			// overflow wherever those checks are on, which would take every hash in the
			// process down through a build configuration rather than a code change.
			hash = hash &* FnvPrime;
		}
		return hash;
	}

	/// FNV-1a over a view's UTF-8 bytes. The same function as HashBytes over the same
	/// bytes, so a text hash and a byte hash of the same content agree.
	public static uint64 HashText(StringView text)
	{
		var hash = FnvOffsetBasis;
		for (int i < text.Length)
		{
			hash ^= (uint64)(uint8)text[i];
			hash = hash &* FnvPrime;
		}
		return hash;
	}

	/// The splitmix64 finaliser.
	///
	/// For keys that are already integers. Sequential ids hash to sequential buckets
	/// without it, which turns a hash table into a linked list exactly when it is fullest.
	public static uint64 HashInteger(uint64 value)
	{
		var x = value;
		x ^= x >> 33;
		x = x &* 0xff51afd7ed558ccdUL;
		x ^= x >> 33;
		x = x &* 0xc4ceb9fe1a85ec53UL;
		x ^= x >> 33;
		return x;
	}
}
