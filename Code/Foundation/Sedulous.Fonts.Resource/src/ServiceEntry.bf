using System;
using Sedulous.Fonts;
using Sedulous.Image;

namespace Sedulous.Fonts.Resource;

/// One resolvable (family, size) in the service's table.
class ServiceEntry
{
	public String Family = new .() ~ delete _;
	public float PixelHeight;
	/// The wrapper handed to callers. Owned here, but see OwnsViews for what inside it is.
	public CachedFont Cached;
	/// Product owned, so never freed here.
	public ImageData Image;

	/// Whether this is a SYNTHESIZED entry, whose font and atlas are view wrappers this
	/// entry created and may free. A base entry's font and atlas belong to the product,
	/// and CachedFont's destructor would otherwise take the product's tables with it.
	public bool OwnsViews;
}
