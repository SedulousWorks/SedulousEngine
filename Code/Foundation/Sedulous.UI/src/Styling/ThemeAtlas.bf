using System;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.UI;

/// Packs theme images into one atlas and builds atlas backed drawables from its regions.
///
/// One atlas texture means NO texture switches while drawing the interface, which is the
/// whole point: a themed window is otherwise a long run of one-quad draws each with its own
/// binding.
///
/// Ref counted so a sheet can hold it alongside the drawables that reference it: an atlas
/// backed drawable borrows this atlas, so the atlas has to outlive them.
class ThemeAtlas : RefCounted
{
	private ImageAtlasBuilder mBuilder ~ delete _;
	private bool mBuilt = false;

	public this(uint32 minSize = 256, uint32 maxSize = 4096, uint32 padding = 1)
	{
		mBuilder = new .(minSize, maxSize, padding);
	}

	/// Null until Build has succeeded.
	public ImageData Atlas => mBuilder.Atlas;

	public void AddImage(StringView name, ImageData image) => mBuilder.AddImage(name, image);

	/// Packs everything added so far. Must succeed before any drawable can be made.
	public bool Build()
	{
		mBuilt = mBuilder.Build();
		return mBuilt;
	}

	/// A drawable for a named region, or null when the atlas is unbuilt or has no such
	/// region. The caller OWNS the result.
	public AtlasImageDrawable CreateImageDrawable(StringView name, Color tint = Color.White)
	{
		if (!TryGetRegion(name, let region))
			return null;
		return new AtlasImageDrawable(mBuilder.Atlas, region, tint);
	}

	/// A nine slice drawable for a named region, or null on the same terms. The caller OWNS
	/// the result.
	public AtlasNineSliceDrawable CreateNineSliceDrawable(StringView name, NineSlice slices,
		Color tint = Color.White, Thickness expand = .())
	{
		if (!TryGetRegion(name, let region))
			return null;
		return new AtlasNineSliceDrawable(mBuilder.Atlas, region, slices, tint, expand);
	}

	/// A state list whose entries are atlas backed. A state whose region is missing is simply
	/// absent from the list, which the state list's own fallback then covers.
	///
	/// The caller OWNS the result.
	public StateListDrawable CreateStateDrawable(Span<StateImageEntry> stateImages,
		NineSlice slices = .(), Color tint = Color.White, Thickness expand = .())
	{
		let stateList = new StateListDrawable();

		for (let entry in stateImages)
		{
			// Written out rather than as a conditional: the two branches are different
			// drawable types and Beef will not pick a common base for them on its own.
			Drawable drawable = null;
			if (slices.IsValid)
				drawable = CreateNineSliceDrawable(entry.Name, slices, tint, expand);
			else
				drawable = CreateImageDrawable(entry.Name, tint);

			if (drawable != null)
				stateList.Set(entry.State, drawable);
		}

		return stateList;
	}

	/// The region's rectangle in the atlas, as the float rectangle a drawable wants.
	private bool TryGetRegion(StringView name, out Rectangle region)
	{
		region = .();
		if (!mBuilt || (mBuilder.Atlas == null))
			return false;
		if (!mBuilder.GetRegion(name, let packed))
			return false;

		region = .((float)packed.X, (float)packed.Y, (float)packed.Width, (float)packed.Height);
		return true;
	}
}
