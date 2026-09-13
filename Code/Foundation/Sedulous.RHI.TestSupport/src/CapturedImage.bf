using System;
using System.Collections;

namespace Sedulous.RHI.TestSupport;

/// An RGBA8 image read back off a render target.
///
/// TIGHTLY PACKED, width times height times four, so the backend's 256 byte row alignment
/// never leaks into a probe's arithmetic.
class CapturedImage
{
	public bool Valid = false;
	public uint32 Width = 0;
	public uint32 Height = 0;
	public List<uint8> Rgba = new .() ~ delete _;

	/// The four bytes at a pixel.
	public uint8* At(uint32 x, uint32 y) =>
		&Rgba[((int)y * (int)Width + (int)x) * 4];

	/// A cheap brightness proxy, nought to 765: the three channels added up.
	///
	/// Enough to tell dark from mid from bright, which is all a structural probe asks. It is
	/// NOT a perceptual measure and is not meant to be.
	public uint32 Luma(uint32 x, uint32 y)
	{
		let p = At(x, y);
		return (uint32)p[0] + p[1] + p[2];
	}

	/// How many pixels satisfy `predicate`, which is handed the four bytes of each.
	public uint32 CountWhere(delegate bool(uint8* rgba) predicate)
	{
		var count = 0;
		for (uint32 y = 0; y < Height; y++)
		{
			for (uint32 x = 0; x < Width; x++)
			{
				if (predicate(At(x, y)))
					count++;
			}
		}
		return (uint32)count;
	}
}
