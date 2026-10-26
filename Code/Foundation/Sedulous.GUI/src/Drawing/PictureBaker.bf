using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG.SVG;

namespace Sedulous.GUI;

// IPictureBaker: the seam through which the GUI asks for a vector picture drawn once, at the size
// it shows in device pixels, and kept as a texture, so that what would tessellate its paths every
// frame (an SVG skin's nine pieces, each the whole document clipped to its place) draws textured
// quads instead. The host's renderer bakes (a GPU texture, never read back): the GUI only asks.
// A picture asked for and not yet baked comes back null and is queued; the GUI draws it as paths
// meanwhile, and redraws when the baker's generation moves (a bake landed).

/// Where an atlas keeps a picture: the page the renderer samples (premultiplied colour, as a
/// bake's texture) and the picture's rectangle on it, in the page's pixels.
struct PictureRegion
{
	/// The largest side a picture keeps in an atlas: larger ones are baked alone
	/// (IPictureBaker.Baked).
	public const uint32 cLargestAtlasPicture = 128;

	/// Borrowed: the baker keeps it.
	public ImageData Page = null;
	public Rectangle Source = .();

	public this() {}

	public this(ImageData page, Rectangle source)
	{
		Page = page;
		Source = source;
	}
}

interface IPictureBaker
{
	/// `document` at `width` by `height` device pixels in an atlas shared by many pictures (an
	/// icon), so pictures drawn one after another are one draw: its page and rectangle, or null
	/// while it is not baked yet (asking queues it) or it is larger than an atlas keeps
	/// (PictureRegion.cLargestAtlasPicture). A `mask` picture is baked white where it covers, to
	/// take a tint when it is drawn (VGContext.DrawImagePremultiplied with the tint); otherwise as
	/// authored. The document must outlive the bake, as for Baked.
	PictureRegion? AtlasRegion(SVGDocument document, uint32 width, uint32 height, bool mask);

	/// `document` drawn at `width` by `height` device pixels: the image the renderer samples its
	/// texture by (premultiplied colour: VGContext.DrawImagePremultiplied), or null while it is
	/// not baked yet, which asking queues. The document must outlive the bake (a resource
	/// provider's does). Borrowed: the baker keeps it.
	ImageData Baked(SVGDocument document, uint32 width, uint32 height);
	/// Counts the bakes that have landed: a GUI that drew a picture as paths while it waited
	/// redraws when this moves.
	uint64 Generation { get; }
}
