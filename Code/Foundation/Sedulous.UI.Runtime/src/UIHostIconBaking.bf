using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.VG.SVG;

namespace Sedulous.UI.Runtime;

/// Baking vector icons into a bitmap atlas.
///
/// Each icon at each size is rendered SUPERSAMPLED into an offscreen target, read back, and box
/// filtered on the CPU. The antialiasing is baked into the texels once, and every instance of
/// an icon then samples identical texels from a pixel-snapped quad - which is what stops the
/// same glyph shimmering differently in two places.
///
/// Synchronous, and one small GPU round trip: for startup and theme load, never per frame.
extension UIHost
{
	/// Render at four times the final size. Enough for the box filter to resolve clean edges;
	/// more costs bake time for no visible gain.
	private const uint32 Supersample = 4;
	private const uint32 AtlasPad = 1;
	private const uint32 AtlasWidth = 512;
	/// The sizes the shared chrome is baked at, before the UI scale is applied.
	private const uint32[7] ChromeSizes = .(10, 12, 14, 16, 20, 24, 32);

	/// Bakes the shared theme chrome - the close button, the chevrons, the checkmark - at a UI
	/// scale. Called again after a scale or DPI change: the old variants are detached first, so
	/// the drawables fall back to live vector until the new bake lands rather than showing
	/// wrongly sized texels.
	public bool BakeThemeIcons(float scale = 1.0f)
	{
		let icons = ThemeIconSet.Get();
		icons.Initialize();
		icons.ClearBakedVariants();

		let bakeable = scope List<BakedSVGDrawable>();
		icons.CollectBakeable(bakeable);

		// Rounded, and DE-DUPLICATED: at some scales two base sizes land on the same pixel
		// size, and baking it twice would just waste atlas space.
		let sizes = scope List<uint32>();
		for (let baseSize in ChromeSizes)
		{
			let scaled = (uint32)(baseSize * scale + 0.5f);
			if (sizes.IsEmpty || (sizes.Back != scaled))
				sizes.Add(scaled);
		}

		mThemeIconsBaked = BakeSvgDrawables(bakeable, sizes);
		return mThemeIconsBaked;
	}

	/// Bakes a set of drawables at a set of sizes into one shared atlas.
	///
	/// Answers false and changes NOTHING on any failure, so the drawables keep their live
	/// vector fallback: a bake that half worked would be worse than one that did not run.
	public bool BakeSvgDrawables(List<BakedSVGDrawable> drawables, List<uint32> sizes)
	{
		let device = mDevice.Raw;
		if ((device == null) || (mVertexShader == null) || (mFragmentShader == null))
			return false;

		let cells = scope List<IconBakeCell>();
		let atlasHeight = LayOutCells(drawables, sizes, cells);
		if (cells.IsEmpty)
			return false;

		let atlas = RenderAndReadBack(device, cells, atlasHeight);
		if (atlas == null)
			return false;

		AssignVariants(drawables, cells, atlas);
		mBakedIconAtlases.Add(atlas);
		return true;
	}

	/// Shelf packing, in final atlas coordinates. Answers the atlas height.
	private uint32 LayOutCells(List<BakedSVGDrawable> drawables, List<uint32> sizes,
		List<IconBakeCell> outCells)
	{
		uint32 cursorX = AtlasPad;
		uint32 cursorY = AtlasPad;
		uint32 rowHeight = 0;

		// By SIZE first, so a row holds one size and the shelf stays tight.
		for (let size in sizes)
		{
			for (let drawable in drawables)
			{
				if (drawable == null)
					continue;

				if (cursorX + size + AtlasPad > AtlasWidth)
				{
					cursorX = AtlasPad;
					cursorY += rowHeight + AtlasPad;
					rowHeight = 0;
				}

				outCells.Add(.(drawable, size, cursorX, cursorY));
				rowHeight = Max(rowHeight, size);
				cursorX += size + AtlasPad;
			}
		}

		return cursorY + rowHeight + AtlasPad;
	}

	/// Renders every cell supersampled, reads the target back, and downsamples it.
	private OwnedImageData RenderAndReadBack(IDevice device, List<IconBakeCell> cells,
		uint32 atlasHeight)
	{
		let targetWidth = AtlasWidth * Supersample;
		let targetHeight = atlasHeight * Supersample;

		var targetDesc = TextureDesc();
		targetDesc.Dimension = .Texture2D;
		targetDesc.Format = .RGBA8UnormSrgb;
		targetDesc.Width = targetWidth;
		targetDesc.Height = targetHeight;
		targetDesc.Depth = 1;
		targetDesc.Usage = .RenderTarget | .CopySrc;
		targetDesc.Label = "icon bake";

		ITexture target = null;
		ITextureView targetView = null;
		defer
		{
			if (targetView != null)
				device.DestroyTextureView(ref targetView);
			if (target != null)
				device.DestroyTexture(ref target);
		}

		if (device.CreateTexture(targetDesc) case .Ok(let created))
			target = created;
		else
			return null;

		if (device.CreateTextureView(target, .()) case .Ok(let createdView))
			targetView = createdView;
		else
			return null;

		// A THROWAWAY vector stack: this is not a window, and nothing here outlives the bake.
		let bakeVG = scope VGContext();
		for (let cell in cells)
		{
			let rect = Rectangle(cell.X * Supersample, cell.Y * Supersample,
				cell.Size * Supersample, cell.Size * Supersample);
			SVGRenderer.Render(bakeVG, cell.Drawable.Document, rect);
		}

		let bakeRenderer = scope VGRenderer();
		if (bakeRenderer.Initialize(device, mVertexShader, mFragmentShader, .RGBA8UnormSrgb, 1) case .Err)
			return null;

		defer bakeRenderer.Dispose();

		bakeRenderer.BeginFrame(0);
		let slice = bakeRenderer.Prepare(bakeVG.GetBatch(), 0, targetWidth, targetHeight);

		// Rows are 256 aligned, which is what the backends' copy rules require.
		let rowPitch = ((targetWidth * 4) + 255) & ~255U;
		return ExecuteBake(device, target, targetView, bakeRenderer, slice, rowPitch,
			targetWidth, targetHeight, atlasHeight);
	}

	private OwnedImageData ExecuteBake(IDevice device, ITexture target, ITextureView targetView,
		VGRenderer renderer, VGRenderSlice slice, uint32 rowPitch, uint32 targetWidth,
		uint32 targetHeight, uint32 atlasHeight)
	{
		var readDesc = BufferDesc();
		readDesc.Size = (uint64)rowPitch * targetHeight;
		readDesc.Usage = .CopyDst;
		readDesc.Memory = .GpuToCpu;

		IBuffer readBuffer = null;
		ICommandPool pool = null;
		IFence fence = null;
		defer
		{
			if (fence != null)
				device.DestroyFence(ref fence);
			if (pool != null)
				device.DestroyCommandPool(ref pool);
			if (readBuffer != null)
				device.DestroyBuffer(ref readBuffer);
		}

		if (device.CreateBuffer(readDesc) case .Ok(let buffer))
			readBuffer = buffer;
		else
			return null;

		if (device.CreateCommandPool(.Graphics) case .Ok(let createdPool))
			pool = createdPool;
		else
			return null;

		if (device.CreateFence(0) case .Ok(let createdFence))
			fence = createdFence;
		else
			return null;

		if (!(pool.CreateEncoder() case .Ok(let encoder)))
			return null;

		encoder.TransitionTexture(target, .Undefined, .RenderTarget);

		var color = ColorAttachment();
		color.View = targetView;
		color.LoadOp = .Clear;
		color.StoreOp = .Store;
		// TRANSPARENT: the atlas is icons on nothing, and a coloured clear would bleed into
		// every antialiased edge.
		color.ClearValue = .(0, 0, 0, 0);

		var pass = RenderPassDesc();
		pass.ColorAttachments.Add(color);

		if (let renderPass = encoder.BeginRenderPass(pass))
		{
			renderer.Render(renderPass, targetWidth, targetHeight, 0, slice);
			renderPass.End();
		}

		encoder.TransitionTexture(target, .RenderTarget, .CopySrc);

		var region = BufferTextureCopyRegion();
		region.BytesPerRow = rowPitch;
		region.RowsPerImage = targetHeight;
		region.TextureExtent = .(targetWidth, targetHeight, 1);
		encoder.CopyTextureToBuffer(target, readBuffer, region);

		var commands = encoder.Finish();
		device.GetQueue(.Graphics).Submit(.(&commands, 1), fence, 1);
		// SYNCHRONOUS by design: a bake is a startup or theme-load cost, not a frame one.
		fence.Wait(1);

		let mapped = readBuffer.Map();
		if (mapped == null)
			return null;

		defer readBuffer.Unmap();
		return Downsample((uint8*)mapped, rowPitch, AtlasWidth, atlasHeight);
	}

	/// The CPU half: decode from sRGB, average the supersampled premultiplied box, UN-premultiply,
	/// encode back to sRGB.
	///
	/// The un-premultiply matters: the vector shader premultiplies its output, but DrawImage
	/// expects straight alpha and premultiplies again at draw time. Leaving it premultiplied
	/// darkens every partially transparent edge.
	private OwnedImageData Downsample(uint8* pixels, uint32 rowPitch, uint32 width, uint32 height)
	{
		// A 256 entry decode table. The box filter touches sixteen texels per output pixel, and
		// a pow per texel would put the whole bake into the hundreds of milliseconds.
		float[256] decode = .();
		for (int i < 256)
			decode[i] = SrgbToLinear(i / 255.0f);

		let output = scope List<uint8>();
		output.Resize((int)width * (int)height * 4);

		let inverseCount = 1.0f / (Supersample * Supersample);

		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				var r = 0.0f;
				var g = 0.0f;
				var b = 0.0f;
				var a = 0.0f;

				for (uint32 sy < Supersample)
				{
					let row = pixels + (int)(y * Supersample + sy) * (int)rowPitch + (int)x * Supersample * 4;
					for (uint32 sx < Supersample)
					{
						let texel = row + (int)sx * 4;
						r += decode[texel[0]];
						g += decode[texel[1]];
						b += decode[texel[2]];
						a += texel[3] / 255.0f;
					}
				}

				r *= inverseCount;
				g *= inverseCount;
				b *= inverseCount;
				a *= inverseCount;

				// Guarded: dividing a fully transparent texel by its own alpha is meaningless
				// and would produce a colour out of nothing.
				if (a > 0.0001f)
				{
					r /= a;
					g /= a;
					b /= a;
				}

				let destination = ((int)y * (int)width + (int)x) * 4;
				output[destination + 0] = Encode(r);
				output[destination + 1] = Encode(g);
				output[destination + 2] = Encode(b);
				output[destination + 3] = (uint8)Clamp(a * 255.0f + 0.5f, 0, 255);
			}
		}

		return new OwnedImageData(width, height, .RGBA8, Span<uint8>(output.Ptr, output.Count),
			.Srgb);
	}

	private static uint8 Encode(float linear) =>
		(uint8)Clamp(LinearToSrgb(linear) * 255.0f + 0.5f, 0, 255);

	/// Points each drawable at the cells that are its own.
	private void AssignVariants(List<BakedSVGDrawable> drawables, List<IconBakeCell> cells,
		ImageData atlas)
	{
		let variants = scope List<BakedSVGVariant>();

		for (let drawable in drawables)
		{
			if (drawable == null)
				continue;

			variants.Clear();
			for (let cell in cells)
			{
				if (cell.Drawable != drawable)
					continue;

				variants.Add(.(atlas, .(cell.X, cell.Y, cell.Size, cell.Size), cell.Size));
			}

			drawable.SetBakedVariants(variants);
		}
	}
}
