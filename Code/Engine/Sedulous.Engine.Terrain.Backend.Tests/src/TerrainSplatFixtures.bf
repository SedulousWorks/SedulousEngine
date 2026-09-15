using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Terrain.Resource;

using Sedulous.RHI;

namespace Sedulous.Engine.Terrain.Backend.Tests;

/// The splat rasters and palette blobs the material probes paint with. The CALLER owns what
/// comes back.
static class TerrainSplatFixtures
{
	/// The raster side the probes paint at. Large enough that a stripe lands on several
	/// texels and small enough to stay cheap.
	public const int32 cRasterSide = 32;

	/// Vertical stripes, one hot: stripe i is PALETTE LAYER i at full weight, so the base
	/// contributes nothing anywhere.
	///
	/// With more than four bands this is a raster the retired fixed four layer model could
	/// not represent at all, which is the whole point of the six layer case.
	public static SplatWeights MakeStripeWeights(uint32 bands)
	{
		let weights = new SplatWeights(cRasterSide, cRasterSide);
		let indices = weights.Indices;
		let amounts = weights.Weights;

		for (int32 y = 0; y < cRasterSide; y++)
		{
			for (int32 x = 0; x < cRasterSide; x++)
			{
				let at = weights.TexelOffset(x, y);
				let layer = Math.Min((uint32)x * bands / (uint32)cRasterSide, bands - 1);
				indices[at] = (uint8)layer;
				amounts[at] = 255;
			}
		}

		weights.BumpVersion();
		return weights;
	}

	/// Two active slots everywhere: palette layer 0 at w0 and layer 1 at w1, the base owning
	/// whatever is left. Equal weights are the tie a height map has to break.
	public static SplatWeights MakeTwoLayerWeights(uint8 w0, uint8 w1)
	{
		let weights = new SplatWeights(cRasterSide, cRasterSide);
		let indices = weights.Indices;
		let amounts = weights.Weights;

		for (int32 y = 0; y < cRasterSide; y++)
		{
			for (int32 x = 0; x < cRasterSide; x++)
			{
				let at = weights.TexelOffset(x, y);
				indices[at + 0] = 0;
				indices[at + 1] = 1;
				amounts[at + 0] = w0;
				amounts[at + 1] = w1;
			}
		}

		weights.BumpVersion();
		return weights;
	}

	/// A cook shaped palette: one solid colour slice per entry, four by four with no mip
	/// chain, which is all a solid colour needs.
	public static TerrainPaletteData MakePaletteData(Span<Float3> colors)
	{
		let data = new TerrainPaletteData();
		data.SliceSize = 4;
		data.MipCount = 1;
		data.SliceCount = (uint32)colors.Length;

		FillSlices(data.Texels, colors, data);
		return data;
	}

	/// Fills one of a palette's optional arrays with a solid value per slice, matching the
	/// albedo's geometry. Empty means absent, so a caller only fills what its case is about.
	public static void FillSliceArray(List<uint8> texels, Span<Float3> values,
		TerrainPaletteData geometry)
	{
		FillSlices(texels, values, geometry);
	}

	private static void FillSlices(List<uint8> texels, Span<Float3> values,
		TerrainPaletteData geometry)
	{
		let sliceBytes = TerrainPaletteData.SliceBytes(geometry.SliceSize, geometry.MipCount);
		texels.Resize(sliceBytes * values.Length);

		for (int s = 0; s < values.Length; s++)
		{
			for (int t = 0; t < sliceBytes / 4; t++)
			{
				let at = s * sliceBytes + t * 4;
				texels[at + 0] = (uint8)(Math.Clamp(values[s].X, 0.0f, 1.0f) * 255.0f);
				texels[at + 1] = (uint8)(Math.Clamp(values[s].Y, 0.0f, 1.0f) * 255.0f);
				texels[at + 2] = (uint8)(Math.Clamp(values[s].Z, 0.0f, 1.0f) * 255.0f);
				texels[at + 3] = 255;
			}
		}
	}

	/// A solid one by one RGBA texture, for a base map a case wants a known colour from.
	public static ITextureView MakeSolid(ProbeTextures owner, IDevice device, uint8 r, uint8 g,
		uint8 b)
	{
		let pixel = scope uint8[](r, g, b, 255);
		return owner.MakeRGBA(device, 1, 1, pixel);
	}
}

/// The textures a case creates by hand, freed together when it ends.
///
/// The production caches own what they build; these are the odd base maps a case paints
/// itself, and nothing else would free them.
class ProbeTextures
{
	private List<ITexture> mTextures = new .() ~ delete _;
	private List<ITextureView> mViews = new .() ~ delete _;
	private IDevice mDevice = null;

	public ~this()
	{
		if (mDevice == null)
			return;

		for (var view in ref mViews)
			mDevice.DestroyTextureView(ref view);
		for (var texture in ref mTextures)
			mDevice.DestroyTexture(ref texture);
	}

	/// An RGBA8 texture uploaded from `pixels`, which must be width times height times four
	/// bytes. Null when the device refuses any part of it.
	public ITextureView MakeRGBA(IDevice device, uint32 width, uint32 height, Span<uint8> pixels)
	{
		mDevice = device;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = width;
		textureDesc.Height = height;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "terrain.probe.map";
		if (!(device.CreateTexture(textureDesc) case .Ok(let texture)))
			return null;
		mTextures.Add(texture);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		viewDesc.Dimension = .Texture2D;
		if (!(device.CreateTextureView(texture, viewDesc) case .Ok(let view)))
			return null;
		mViews.Add(view);

		if (let queue = device.GetQueue(.Graphics))
		{
			if (queue.CreateTransferBatch() case .Ok(var batch))
			{
				var layout = TextureDataLayout();
				layout.BytesPerRow = width * 4;
				layout.RowsPerImage = height;
				batch.WriteTexture(texture, pixels, layout, .(width, height, 1));
				batch.Submit().IgnoreError();
				queue.DestroyTransferBatch(ref batch);
			}
		}

		return view;
	}
}
