using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// The SHARED, bake ready chrome glyphs behind the built in themes.
///
/// The crisp icons used to be editor only by WIRING rather than by design: the editor baked
/// its own icons into a pixel snapped atlas while the themes' own glyphs stayed live vector
/// renders, so the same close button was crisp in one place and soft in another.
///
/// A theme takes glyphs through Acquire. When a host has INITIALIZED the set, every theme
/// shares ONE drawable per glyph and the host bakes them; until the bake lands they draw as
/// live vectors, so the order of initialising and baking does not matter. A headless or test
/// context never initialises the set, and Acquire then hands out fresh unbaked drawables,
/// which is exactly the behaviour from before any of this existed.
class ThemeIconSet
{
	/// Bump when ThemeIcon gains a glyph: Initialize materialises ALL of them, so a stale
	/// count would silently leave the new one unbaked.
	public const int cGlyphCount = 10;

	private class TintedGlyph
	{
		public ThemeIcon Icon;
		public Color Tint;
		/// OWNED.
		public BakedSVGDrawable Drawable ~ _?.ReleaseRef();
	}

	private BakedSVGDrawable[cGlyphCount] mGlyphs = .();
	private List<TintedGlyph> mTinted = new .() ~ DeleteContainerAndItems!(_);
	private bool mInitialized = false;

	/// Process wide, and torn down explicitly by the host. The glyphs live for the process by
	/// design, as the global logger and job system do.
	private static ThemeIconSet sInstance = new .() ~ delete _;

	public static ThemeIconSet Get() => sInstance;

	public ~this()
	{
		ReleaseGlyphs();
	}

	private void ReleaseGlyphs()
	{
		for (int i < cGlyphCount)
		{
			if (mGlyphs[i] != null)
			{
				mGlyphs[i].ReleaseRef();
				mGlyphs[i] = null;
			}
		}
	}

	/// Materialises the shared glyphs. Idempotent, and called BEFORE apps build their themes
	/// so that every theme references the shared instances rather than its own copies.
	public void Initialize()
	{
		if (mInitialized)
			return;

		for (int i < cGlyphCount)
			mGlyphs[i] = BakedSVGDrawable.FromString(((ThemeIcon)i).Svg);

		mInitialized = true;
	}

	/// Drops the shared references. A sheet holding its own reference keeps its instance
	/// alive.
	///
	/// Baked variants must be cleared FIRST when the atlas owner is going away, since a
	/// variant borrows that atlas.
	public void Shutdown()
	{
		ReleaseGlyphs();
		ClearAndDeleteItems!(mTinted);
		mInitialized = false;
	}

	public bool IsInitialized => mInitialized;

	/// The shared glyph when the set is live, otherwise a fresh unbaked one. The caller OWNS
	/// a reference either way.
	public static Drawable Acquire(ThemeIcon icon)
	{
		let set = Get();
		if (set.mInitialized)
		{
			let shared = set.mGlyphs[(int)icon];
			if (shared != null)
			{
				shared.AddRef();
				return shared;
			}
		}
		return SVGDrawable.FromString(icon.Svg);
	}

	/// The TINTED shared variant, which the light and textured themes ask for.
	///
	/// One shared instance per glyph and tint, of which a theme uses a handful, materialised
	/// on first acquire so it joins the bake pass. The caller OWNS a reference.
	public static Drawable Acquire(ThemeIcon icon, Color tint)
	{
		let set = Get();
		if (set.mInitialized)
		{
			for (let entry in set.mTinted)
			{
				if ((entry.Icon == icon) && (entry.Tint == tint))
				{
					entry.Drawable.AddRef();
					return entry.Drawable;
				}
			}

			let made = BakedSVGDrawable.FromString(icon.Svg);
			if (made != null)
			{
				made.TintColor = tint;

				let entry = new TintedGlyph();
				entry.Icon = icon;
				entry.Tint = tint;
				entry.Drawable = made;
				set.mTinted.Add(entry);

				made.AddRef();
				return made;
			}
		}
		return SVGDrawable.FromString(icon.Svg, tint);
	}

	/// Every live glyph, base and tinted, for the host's bake pass. BORROWED.
	public void CollectBakeable(List<BakedSVGDrawable> outGlyphs)
	{
		for (int i < cGlyphCount)
		{
			if (mGlyphs[i] != null)
				outGlyphs.Add(mGlyphs[i]);
		}
		for (let entry in mTinted)
		{
			if (entry.Drawable != null)
				outGlyphs.Add(entry.Drawable);
		}
	}

	/// Detaches the baked variants, which BORROW the baker's atlas.
	///
	/// Call before the atlas owner dies, or before re-baking at a new scale. The glyphs fall
	/// back to live vector rendering in the meantime.
	public void ClearBakedVariants()
	{
		for (int i < cGlyphCount)
		{
			if (mGlyphs[i] != null)
				mGlyphs[i].ClearBakedVariants();
		}
		for (let entry in mTinted)
		{
			if (entry.Drawable != null)
				entry.Drawable.ClearBakedVariants();
		}
	}
}
