using System;
using System.Collections;

namespace Sedulous.Render;

/// Sorting a view's draw list by its keys.
static class DrawItemSorter
{
	/// A least significant digit radix sort, ascending, in eight passes of eight bits.
	///
	/// Linear and STABLE, which matters: two draws with equal keys keep the order extraction
	/// gave them, so a frame does not flicker between two orderings of the same scene. The
	/// scratch buffer is the caller's and is reused between frames rather than allocated per
	/// frame; what it holds afterwards is not defined.
	public static void RadixSortDrawItems(List<DrawItem> items, List<DrawItem> scratch)
	{
		let count = items.Count;
		if (count < 2)
			return;

		scratch.Resize(count);

		var source = items;
		var destination = scratch;

		for (uint32 shift = 0; shift < 64; shift += 8)
		{
			int[256] counts = default;
			for (int i < count)
				counts[(int)((source[i].Key >> shift) & 0xFF)]++;

			var total = 0;
			for (int bucket < 256)
			{
				let inBucket = counts[bucket];
				counts[bucket] = total;
				total += inBucket;
			}

			for (int i < count)
			{
				let bucket = (int)((source[i].Key >> shift) & 0xFF);
				destination[counts[bucket]++] = source[i];
			}

			Swap!(source, destination);
		}

		// Eight passes is an even number, so the result is back in the caller's list and
		// there is nothing to copy.
	}
}
