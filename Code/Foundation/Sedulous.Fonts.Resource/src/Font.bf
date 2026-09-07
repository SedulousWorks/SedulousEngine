using System;
using System.Collections;

namespace Sedulous.Fonts.Resource;

/// The runtime product: one family, and every size it was baked at.
///
/// A packaged game loads THIS and never links a rasterizer. Nothing here can produce a
/// glyph that was not baked, which is the point: the tables came off disk.
class Font
{
	private String mFamily = new .() ~ delete _;
	private List<FontEntry> mEntries = new .() ~ DeleteContainerAndItems!(_);

	public void SetFamily(StringView family) => mFamily.Set(family);
	public void GetFamily(String outFamily) => outFamily.Append(mFamily);
	public StringView Family => mFamily;

	/// Takes ownership of the entry.
	public void AddEntry(FontEntry entry) => mEntries.Add(entry);

	public int EntryCount => mEntries.Count;
	public FontEntry EntryAt(int index) => mEntries[index];
	public List<FontEntry> Entries => mEntries;

	/// The entry baked NEAREST to `pixelHeight`, or null when there are none.
	///
	/// Nearest rather than exact because a font is baked at a handful of sizes and asked
	/// for at any: the service maps a request through this and then, for a distance field,
	/// scales the result the rest of the way.
	public FontEntry ClosestEntry(float pixelHeight)
	{
		FontEntry best = null;
		float bestDistance = 0;
		for (let entry in mEntries)
		{
			let distance = Math.Abs(entry.PixelHeight - pixelHeight);
			if ((best == null) || (distance < bestDistance))
			{
				best = entry;
				bestDistance = distance;
			}
		}
		return best;
	}
}
