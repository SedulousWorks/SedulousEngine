namespace Sedulous.Images;

using System;
using System.Collections;

/// General-purpose image atlas packer. Combines multiple RGBA8 images
/// into a single atlas texture using shelf packing. Usable by UI themes,
/// sprite sheets, texture packers, etc.
public class ImageAtlasBuilder
{
	private struct Entry
	{
		public String Name;
		public IImageData Image;
	}

	private List<Entry> mEntries = new .() ~ {
		for (var e in _) delete e.Name;
		delete _;
	};

	private OwnedImageData mAtlas ~ delete _;
	private Dictionary<String, RectangleI> mRegions = new .() ~ {
		for (let kv in _) delete kv.key;
		delete _;
	};

	private uint32 mMinSize;
	private uint32 mMaxSize;
	private uint32 mPadding;

	/// The built atlas image. Null until Build() is called.
	public IImageData Atlas => mAtlas;

	/// Number of entries added.
	public int EntryCount => mEntries.Count;

	/// Create an atlas builder.
	/// minSize: minimum atlas dimension (default 256).
	/// maxSize: maximum atlas dimension (default 4096).
	/// padding: pixels between packed images (default 1).
	public this(uint32 minSize = 256, uint32 maxSize = 4096, uint32 padding = 1)
	{
		mMinSize = NextPowerOf2(minSize);
		mMaxSize = NextPowerOf2(maxSize);
		mPadding = padding;
	}

	/// Add an image to be packed. Name must be unique.
	public void AddImage(StringView name, IImageData image)
	{
		if (image == null) return;

		Entry entry;
		entry.Name = new String(name);
		entry.Image = image;
		mEntries.Add(entry);
	}

	/// Pack all added images into a single RGBA8 atlas. Returns true on success.
	public bool Build()
	{
		if (mEntries.Count == 0)
		{
			let emptyPixel = new uint8[4];
			mAtlas = new OwnedImageData(1, 1, .RGBA8, emptyPixel);
			return true;
		}

		// Sort by height descending for better shelf packing.
		mEntries.Sort(scope (a, b) => (int)b.Image.Height - (int)a.Image.Height);

		// Try increasing atlas sizes until everything fits.
		for (uint32 size = mMinSize; size <= mMaxSize; size *= 2)
		{
			if (TryPack(size, size))
				return true;
		}

		return false; // Couldn't fit in max size.
	}

	/// Get the pixel-space region of a packed image by name.
	/// Returns null if not found or not yet built.
	public RectangleI? GetRegion(StringView name)
	{
		for (let kv in mRegions)
		{
			if (StringView(kv.key) == name)
				return kv.value;
		}
		return null;
	}

	private bool TryPack(uint32 atlasW, uint32 atlasH)
	{
		// Clear previous regions.
		for (let kv in mRegions) delete kv.key;
		mRegions.Clear();

		// Shelf packing: place images left-to-right, start new row when full.
		uint32 curX = mPadding;
		uint32 curY = mPadding;
		uint32 rowHeight = 0;

		for (let entry in mEntries)
		{
			let imgW = entry.Image.Width;
			let imgH = entry.Image.Height;

			// Check if image fits in current row.
			if (curX + imgW + mPadding > atlasW)
			{
				// Start new row.
				curX = mPadding;
				curY += rowHeight + mPadding;
				rowHeight = 0;
			}

			// Check if image fits vertically.
			if (curY + imgH + mPadding > atlasH)
				return false;

			// Place image.
			mRegions[new String(entry.Name)] = .((int32)curX, (int32)curY, (int32)imgW, (int32)imgH);

			curX += imgW + mPadding;
			rowHeight = Math.Max(rowHeight, imgH);
		}

		// Build the atlas pixel data.
		let pixelData = new uint8[atlasW * atlasH * 4];
		Internal.MemSet(pixelData.Ptr, 0, pixelData.Count);

		for (let entry in mEntries)
		{
			let region = GetRegion(entry.Name);
			if (!region.HasValue) continue;

			let r = region.Value;
			let src = entry.Image;

			// Copy pixels row by row.
			if (src.Format == .RGBA8)
			{
				let srcData = src.PixelData;
				let srcStride = src.Width * 4;
				let dstStride = atlasW * 4;

				for (uint32 y = 0; y < src.Height; y++)
				{
					let srcOffset = y * srcStride;
					let dstOffset = ((uint32)r.Y + y) * dstStride + (uint32)r.X * 4;

					if (srcOffset + srcStride <= (uint32)srcData.Length &&
						dstOffset + srcStride <= (uint32)pixelData.Count)
					{
						Internal.MemCpy(
							&pixelData[(int)dstOffset],
							&srcData[(int)srcOffset],
							(int)srcStride);
					}
				}
			}
		}

		delete mAtlas;
		// OwnedImageData takes ownership of pixelData - don't delete it.
		mAtlas = new OwnedImageData(atlasW, atlasH, .RGBA8, pixelData);

		return true;
	}

	private static uint32 NextPowerOf2(uint32 v)
	{
		var n = v;
		n--;
		n |= n >> 1;
		n |= n >> 2;
		n |= n >> 4;
		n |= n >> 8;
		n |= n >> 16;
		n++;
		return Math.Max(n, 1);
	}
}

/// Integer rectangle for atlas regions.
public struct RectangleI
{
	public int32 X, Y, Width, Height;

	public this(int32 x, int32 y, int32 w, int32 h)
	{
		X = x; Y = y; Width = w; Height = h;
	}
}
