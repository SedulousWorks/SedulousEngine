using System;

namespace Sedulous.Resource;

/// A product a rebuild replaced, waiting out the frames that may still reference it.
struct Grave
{
	public Object Product;
	/// Counted down once a frame; released at zero.
	public uint32 FramesLeft;

	public this() { Product = null; FramesLeft = 0; }
}
