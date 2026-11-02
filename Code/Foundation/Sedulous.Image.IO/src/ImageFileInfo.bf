using System;

namespace Sedulous.Image.IO;

/// What an image file holds, read from its header without decoding it (ImageIO.ReadImageFileInfo):
/// its size, its channels as stored (1 grey, 2 grey and alpha, 3 RGB, 4 RGBA), and whether each is
/// 16-bit or floating point (HDR). The loads widen every file to RGBA, so this is how to say what
/// the file itself is.
struct ImageFileInfo
{
	public uint32 Width = 0;
	public uint32 Height = 0;
	public uint32 Channels = 0;
	public bool SixteenBit = false;
	public bool Hdr = false;

	public this() {}
}
