namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Images;

/// Builds a packed image atlas for theme drawables. Wraps ImageAtlasBuilder
/// and creates AtlasImageDrawable/AtlasNineSliceDrawable from packed regions.
/// Single atlas texture = zero texture switches during UI rendering.
public class ThemeAtlas
{
	private ImageAtlasBuilder mBuilder ~ delete _;
	private bool mBuilt;

	public IImageData Atlas => mBuilder?.Atlas;

	public this(uint32 minSize = 256, uint32 maxSize = 4096, uint32 padding = 1)
	{
		mBuilder = new ImageAtlasBuilder(minSize, maxSize, padding);
	}

	/// Add an image to be packed into the atlas.
	public void AddImage(StringView name, IImageData image)
	{
		mBuilder.AddImage(name, image);
	}

	/// Pack all added images. Must be called before creating drawables.
	public bool Build()
	{
		mBuilt = mBuilder.Build();
		return mBuilt;
	}

	/// Create an AtlasImageDrawable for a named region.
	public AtlasImageDrawable CreateImageDrawable(StringView name, Color tint = .White)
	{
		if (!mBuilt || mBuilder.Atlas == null) return null;
		let region = mBuilder.GetRegion(name);
		if (!region.HasValue) return null;

		let r = region.Value;
		return new AtlasImageDrawable(mBuilder.Atlas,
			.((float)r.X, (float)r.Y, (float)r.Width, (float)r.Height), tint);
	}

	/// Create an AtlasNineSliceDrawable for a named region.
	public AtlasNineSliceDrawable CreateNineSliceDrawable(StringView name,
		NineSlice slices, Color tint = .White, Thickness expand = default)
	{
		if (!mBuilt || mBuilder.Atlas == null) return null;
		let region = mBuilder.GetRegion(name);
		if (!region.HasValue) return null;

		let r = region.Value;
		return new AtlasNineSliceDrawable(mBuilder.Atlas,
			.((float)r.X, (float)r.Y, (float)r.Width, (float)r.Height),
			slices, tint, expand);
	}

	/// Create a StateListDrawable with atlas-backed entries for multiple states.
	/// stateImages is an array of (ControlState, imageName) pairs.
	public StateListDrawable CreateStateDrawable(Span<(ControlState, StringView)> stateImages,
		NineSlice slices = default, Color tint = .White, Thickness expand = default)
	{
		let stateList = new StateListDrawable(true);

		for (let (state, name) in stateImages)
		{
			Drawable drawable;
			if (slices.IsValid)
				drawable = CreateNineSliceDrawable(name, slices, tint, expand);
			else
				drawable = CreateImageDrawable(name, tint);

			if (drawable != null)
				stateList.Set(state, drawable);
		}

		return stateList;
	}
}
