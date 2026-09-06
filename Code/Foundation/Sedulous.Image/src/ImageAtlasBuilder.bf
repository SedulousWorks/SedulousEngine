using System;
using System.Collections;

namespace Sedulous.Image;

/// Packs several images into one atlas texture, by shelf packing.
///
/// Shelf packing rather than anything cleverer: entry counts here are small, the images
/// are sorted tallest first so the shelves stay tight, and the space wasted at the end of
/// a row costs far less than a better packer's complexity would.
///
/// The images being packed are NOT owned; the caller keeps them alive until Build.
class ImageAtlasBuilder
{
	private List<AtlasEntry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	private Dictionary<String, RectI> mRegions = new .() ~ delete _;
	private Image mAtlas ~ delete _;
	private uint32 mMinSize;
	private uint32 mMaxSize;
	private uint32 mPadding;
	private bool mBuilt;

	/// Sizes are rounded up to powers of two, since that is what a texture wants. Padding
	/// is the gap between packed images, which stops a sampler bleeding one into the next.
	public this(uint32 minSize = 256, uint32 maxSize = 4096, uint32 padding = 1)
	{
		mMinSize = NextPowerOfTwo(minSize);
		mMaxSize = NextPowerOfTwo(maxSize);
		mPadding = padding;
	}

	public ~this()
	{
		ClearRegions();
	}

	/// The built atlas, or null until Build has succeeded. THE BUILDER OWNS it.
	public Image Atlas => mBuilt ? mAtlas : null;

	public int EntryCount => mEntries.Count;

	/// Adds an image to pack under a name. The image is NOT owned.
	public void AddImage(StringView name, ImageData image)
	{
		if (image == null)
			return;

		let entry = new AtlasEntry();
		entry.Name.Set(name);
		entry.Image = image;
		mEntries.Add(entry);
	}

	/// The pixel space region of a packed image, or false when there is no such name.
	public bool GetRegion(StringView name, out RectI region)
	{
		let key = scope String(name);
		if (mRegions.TryGetValue(key, out region))
			return true;
		region = default;
		return false;
	}

	/// Packs everything added into one RGBA8 atlas, growing the atlas until it fits.
	public bool Build()
	{
		if (mEntries.IsEmpty)
		{
			// A one pixel transparent atlas rather than nothing, so a consumer that binds
			// the result unconditionally still has something valid to bind.
			DeleteAndNullify!(mAtlas);
			mAtlas = new Image(1, 1, .RGBA8);
			mBuilt = true;
			return true;
		}

		SortByHeightDescending();

		for (var size = mMinSize; size <= mMaxSize; size *= 2)
		{
			if (TryPack(size, size))
			{
				mBuilt = true;
				return true;
			}
		}

		// It does not fit even at the largest size allowed, which is a real answer: the
		// caller has to split the atlas or raise the limit.
		return false;
	}

	/// Tallest first, so each shelf holds images of a similar height and little is wasted
	/// above the short ones.
	private void SortByHeightDescending()
	{
		for (int i = 1; i < mEntries.Count; i++)
		{
			let key = mEntries[i];
			let keyHeight = key.Image.Height;
			var j = i;
			while ((j > 0) && (mEntries[j - 1].Image.Height < keyHeight))
			{
				mEntries[j] = mEntries[j - 1];
				j--;
			}
			mEntries[j] = key;
		}
	}

	private bool TryPack(uint32 atlasWidth, uint32 atlasHeight)
	{
		ClearRegions();

		var x = mPadding;
		var y = mPadding;
		uint32 rowHeight = 0;

		for (let entry in mEntries)
		{
			let width = entry.Image.Width;
			let height = entry.Image.Height;

			// Past the right edge, so start a new shelf.
			if (x + width + mPadding > atlasWidth)
			{
				x = mPadding;
				y += rowHeight + mPadding;
				rowHeight = 0;
			}

			if (y + height + mPadding > atlasHeight)
				return false;

			mRegions[new String(entry.Name)] = .((int32)x, (int32)y, (int32)width, (int32)height);

			x += width + mPadding;
			if (height > rowHeight)
				rowHeight = height;
		}

		DeleteAndNullify!(mAtlas);
		mAtlas = new Image(atlasWidth, atlasHeight, .RGBA8);

		for (let entry in mEntries)
		{
			if (!GetRegion(entry.Name, let region))
				continue;
			// Only RGBA8 sources are copied. Converting is not the packer's decision to
			// make, and copying another format's bytes raw would garble it.
			if (entry.Image.Format != .RGBA8)
				continue;

			let source = entry.Image.PixelData;
			let sourceStride = (int)entry.Image.Width * 4;
			let destinationStride = (int)atlasWidth * 4;
			let destination = mAtlas.PixelData;

			for (uint32 row < entry.Image.Height)
			{
				let sourceOffset = (int)row * sourceStride;
				let destinationOffset = ((int)region.Y + (int)row) * destinationStride + (int)region.X * 4;

				if ((sourceOffset + sourceStride <= source.Length)
					&& (destinationOffset + sourceStride <= destination.Length))
				{
					Internal.MemCpy(destination.Ptr + destinationOffset, source.Ptr + sourceOffset, sourceStride);
				}
			}
		}

		return true;
	}

	private void ClearRegions()
	{
		for (let key in mRegions.Keys)
			delete key;
		mRegions.Clear();
	}

	/// Wrapping arithmetic on purpose: a zero input decrements to all ones, the shifts
	/// fill it, and the increment wraps back to zero before the clamp lifts it to one.
	/// Plain arithmetic would trap at both ends.
	private static uint32 NextPowerOfTwo(uint32 value)
	{
		var n = value &- 1;
		n |= n >> 1;
		n |= n >> 2;
		n |= n >> 4;
		n |= n >> 8;
		n |= n >> 16;
		n = n &+ 1;
		return (n > 1) ? n : 1;
	}
}
