using System;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Pipeline.Cook;

/// Folding a recipe's parts into one number.
static class RecipeHash
{
	/// An ORDERED fold: every field is tagged, so two of them swapping places, or one moving
	/// by an offset, cannot cancel out. A commutative sum over the same parts would call two
	/// different recipes equal and never re-cook the second one.
	public static uint64 Fold(uint64 seed, uint64 tag, uint64 value)
	{
		var h = seed;
		var t = tag;
		var v = value;
		h = HashBytes(&t, sizeof(uint64), h);
		h = HashBytes(&v, sizeof(uint64), h);
		return h;
	}

	/// Every byte of a stream, in sixty four kilobyte bites.
	public static uint64 HashStream(IStream stream)
	{
		let chunk = scope uint8[64 * 1024]*;
		var h = HashBytes(null, 0);
		while (true)
		{
			let read = stream.Read(.(chunk, 64 * 1024));
			if (read <= 0)
				break;
			h = HashBytes(chunk, read, h);
		}
		return h;
	}
}
