using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.Image;

namespace Sedulous.Fonts.Resource;

/// Resolves (family, size) over bound Font PRODUCTS.
///
/// The host binds fonts through the resource manager and registers the products here; the
/// UI then asks for a family and a size and never learns where either came from.
///
/// OWNERSHIP is the awkward part. A CachedFont deletes its font, atlas and shaper, but for
/// a registered product the font and atlas belong to the PRODUCT, and only the shaper is
/// ours. So a base entry has those two nulled before its CachedFont is deleted, and a
/// synthesized entry, whose font and atlas really are wrappers this service made, does not.
class ResourceFontService : IFontService
{
	private List<ServiceEntry> mEntries = new .() ~ delete _;
	private String mDefaultFamily = new .() ~ delete _;

	public ~this()
	{
		Clear();
	}

	public void Clear()
	{
		for (let entry in mEntries)
		{
			if (entry.Cached != null)
			{
				if (!entry.OwnsViews)
				{
					// Product owned: let go before the CachedFont's destructor runs.
					entry.Cached.Font = null;
					entry.Cached.Atlas = null;
				}
				delete entry.Cached;
			}
			delete entry;
		}
		mEntries.Clear();
		mDefaultFamily.Clear();
	}

	/// Registers a bound product, one service entry per baked size.
	///
	/// The product is NOT owned here: the resource manager keeps it alive, and it has to
	/// outlive this service's entries because they point into its tables.
	public void AddFont(Font font)
	{
		if (font == null)
			return;

		for (int i < font.EntryCount)
		{
			let productEntry = font.EntryAt(i);

			let entry = new ServiceEntry();
			entry.Family.Set(font.Family);
			entry.PixelHeight = productEntry.PixelHeight;
			// The shaper is ours to make and ours to free. It reads only metrics and glyph
			// info, so the TrueType one serves a baked font perfectly well.
			entry.Cached = new CachedFont(productEntry.Font, productEntry.Atlas,
				new TrueTypeTextShaper());
			entry.Image = productEntry.AtlasImage;
			mEntries.Add(entry);
		}

		if (mDefaultFamily.IsEmpty && (font.EntryCount > 0))
			mDefaultFamily.Set(font.Family);
	}

	public void SetDefaultFamily(StringView family) => mDefaultFamily.Set(family);

	public override CachedFont GetFont(float pixelHeight) => GetFont(mDefaultFamily, pixelHeight);

	public override CachedFont GetFont(StringView familyName, float pixelHeight)
	{
		if (let exact = FindExact(familyName, pixelHeight))
			return exact.Cached;

		var entry = FindClosest(familyName, pixelHeight);
		if (entry == null)
			entry = FindClosest(mDefaultFamily, pixelHeight);
		if (entry == null)
			return null;

		// A distance field serves every size from ONE bake, so rather than hand back the
		// bake-size tables, synthesize a scaled view for the size actually asked for. A
		// coverage atlas cannot do this: it is sharp only near the size it was baked at.
		if ((entry.Cached != null) && (entry.Cached.Atlas != null)
			&& (entry.Cached.Atlas.Mode == .DistanceField)
			&& (entry.PixelHeight != pixelHeight))
			return SynthesizeScaled(entry, pixelHeight);

		return entry.Cached;
	}

	public override ImageData GetAtlasTexture(CachedFont font)
	{
		for (let entry in mEntries)
		{
			if (entry.Cached === font)
				return entry.Image;
		}
		return null;
	}

	public override ImageData GetAtlasTexture(StringView familyName, float pixelHeight)
	{
		var entry = FindClosest(familyName, pixelHeight);
		if (entry == null)
			entry = FindClosest(mDefaultFamily, pixelHeight);
		return (entry != null) ? entry.Image : null;
	}

	/// Nothing to do: the products own the payloads, and the service owns the wrappers for
	/// as long as it lives.
	public override void ReleaseFont(CachedFont font) {}

	public override void GetDefaultFontFamily(String outFamily) => outFamily.Append(mDefaultFamily);

	public int EntryCount => mEntries.Count;

	private ServiceEntry FindExact(StringView family, float pixelHeight)
	{
		for (let entry in mEntries)
		{
			if ((entry.Family == family) && (Math.Abs(entry.PixelHeight - pixelHeight) < 0.001f))
				return entry;
		}
		return null;
	}

	/// The nearest BASE entry. Synthesized ones are skipped: they are results of an earlier
	/// request, and letting one be the base for the next would scale a scaled view.
	///
	/// The numbers would survive that, since scaling composes and a view of a view lands on
	/// the same advance. What it would build is a CHAIN: every new size wrapping whichever
	/// happened to be nearest, each holding the last. The skip keeps every view one hop from
	/// a real bake, so no test can see the difference and the structure stays flat.
	private ServiceEntry FindClosest(StringView family, float pixelHeight)
	{
		ServiceEntry best = null;
		float bestDistance = 0;
		for (let entry in mEntries)
		{
			if (entry.OwnsViews || (entry.Family != family))
				continue;
			let distance = Math.Abs(entry.PixelHeight - pixelHeight);
			if ((best == null) || (distance < bestDistance))
			{
				best = entry;
				bestDistance = distance;
			}
		}
		return best;
	}

	/// A per-size view over a distance field base, CACHED so the next request for this size
	/// finds it exactly rather than building another.
	///
	/// The views borrow the base's product-owned font and atlas; the CachedFont owns the two
	/// wrappers and the shaper, which is what OwnsViews records.
	private CachedFont SynthesizeScaled(ServiceEntry baseEntry, float pixelHeight)
	{
		let fontView = new ScaledFontView(baseEntry.Cached.Font, pixelHeight);
		let atlasView = new ScaledFontAtlasView(baseEntry.Cached.Atlas, fontView.Scale);

		let entry = new ServiceEntry();
		entry.Family.Set(baseEntry.Family);
		entry.PixelHeight = pixelHeight;
		entry.Image = baseEntry.Image; // the same atlas texture, at a different scale
		entry.OwnsViews = true;
		entry.Cached = new CachedFont(fontView, atlasView, new TrueTypeTextShaper());

		mEntries.Add(entry);
		return entry.Cached;
	}
}
