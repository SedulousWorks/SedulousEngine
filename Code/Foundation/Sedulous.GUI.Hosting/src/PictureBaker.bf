using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.VG.SVG;

namespace Sedulous.GUI;

// GpuPictureBaker: the GUI's IPictureBaker on the GPU.
//
// A picture the GUI asks for (an SVG at a size in device pixels) is queued; the host's frame
// records the queue (Record, on the frame's own command encoder, before the passes that sample
// it): each picture drawn through a VG renderer of its own into a texture of its own, which every
// window's renderer (its targets) is told to sample under the picture's key
// (RegisterExternalTexture), so a picture baked once shows in any window. Nothing is read back, so
// nothing waits: the frame that asked draws the picture as paths, and the next one draws it from the
// texture. The texture holds premultiplied colour in the canvas's blend space, as a layer's target
// does, so the GUI draws it with VGContext.DrawImagePremultiplied.
//
// A bake no draw has asked for in cKeepFrames frames goes (the GUI's renderer forgets it first):
// that long unasked, no frame still in flight samples it. A window that goes takes its renderer out
// of the targets first (RemoveTarget), which forgets every bake. Bakes draw without stencil fills
// (the bake targets have no depth-stencil), as a context without a stencil-capable renderer does.
//
// Small pictures (icons) go into an atlas instead (AtlasRegion): pages of cAtlasPageSize pixels,
// each picture in a place of its own with a transparent gutter round it, so pictures drawn one
// after another from a page are one draw. The pictures asked for since the last frame are drawn
// into their pages, one pass a page, each clipped to its place; a mask picture is drawn white, to
// take its tint when it is drawn. A page only fills: when no page has room, the atlas is packed
// anew from the pictures asked for in the last cRecentFrames frames, its pages cleared and those
// pictures drawn again (meanwhile drawn as paths), and one more page is added while there are
// fewer than cMostAtlasPages.

/// What a baker's renderer draws with: the VG shaders the GUI's renderer has (gradients and boxes
/// as it draws them; none of them but the first two required), the format and blend space of the
/// GUI's target (a bake holds colour as that target's layers do), and the frames in flight. The
/// modules are borrowed.
struct PictureBakerSetup
{
	public IShaderModule VertexShader = null;
	public IShaderModule FragmentShader = null;
	public IShaderModule GradientRadialShader = null;
	public IShaderModule GradientConicShader = null;
	public IShaderModule DistanceFieldShader = null;
	public TextureFormat Format = .RGBA8UnormSrgb;
	public VGBlendSpace BlendSpace = .Linear;
	public int32 FrameCount = 2;

	public this() {}
}

class GpuPictureBaker : IPictureBaker
{
	/// Frames a bake stays after a draw last asked for it.
	public const uint64 cKeepFrames = 600;
	/// An atlas page's side, the gutter round each picture on it, and the most pages.
	public const uint32 cAtlasPageSize = 1024;
	public const uint32 cAtlasGutter = 1;
	public const int cMostAtlasPages = 4;
	/// Packing a full atlas anew keeps the pictures asked for in this many frames.
	public const uint64 cRecentFrames = 60;

	private class Entry
	{
		public SVGDocument Document = null; // the key, with the size; borrowed
		public uint32 Width = 0;
		public uint32 Height = 0;
		public uint64 LastAsked = 0;
		public ImageDataRef Key = null ~ delete _; // what the GUI's renderer knows the texture by
		public ITexture Texture = null;
		public ITextureView View = null; // set once drawn
	}

	private class AtlasPage
	{
		public ShelfPacker Packer = new .(cAtlasPageSize, cAtlasPageSize) ~ delete _;
		public ImageDataRef Key = new .(cAtlasPageSize, cAtlasPageSize) ~ delete _; // what the GUI's renderer knows the page by
		public ITexture Texture = null;
		public ITextureView View = null;
		public bool Clear = true; // drawn into next with the page cleared first (new, or packed anew)
	}

	private class AtlasEntry
	{
		public SVGDocument Document = null; // the key, with the size and mask; borrowed
		public uint32 Width = 0;
		public uint32 Height = 0;
		public bool Mask = false;
		public uint64 LastAsked = 0;
		public int Page = 0;
		public uint32 X = 0; // its place on the page, inside its gutter
		public uint32 Y = 0;
		public bool Baked = false;
	}

	private IDevice mDevice; // borrowed
	private VGRenderer mRenderer = new .() ~ delete _; // the bakes' own: its frame buffers are not the GUI's
	private VGContext mCanvas ~ delete _;
	private TextureFormat mFormat = .RGBA8UnormSrgb;
	private List<VGRenderer> mTargets = new .() ~ delete _; // the windows' renderers, which sample the bakes; borrowed
	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	private List<AtlasPage> mPages = new .() ~ DeleteContainerAndItems!(_);
	private List<AtlasEntry> mAtlas = new .() ~ DeleteContainerAndItems!(_);
	private bool mPackedThisFrame = false;
	private uint64 mFrame = 0;
	private uint64 mGeneration = 0;

	/// `fonts` draws an SVG's text. The renderers that sample the bakes are its targets. Both
	/// borrowed.
	public this(IDevice device, IFontService fonts)
	{
		mDevice = device;
		mCanvas = new .(fonts);
	}

	public ~this()
	{
		Dispose();
	}

	public Result<void, ErrorCode> Initialize(PictureBakerSetup setup)
	{
		if ((setup.VertexShader == null) || (setup.FragmentShader == null))
			return .Err(.InvalidArgument);
		mFormat = setup.Format;
		var config = VGTargetConfig();
		config.BlendSpace = setup.BlendSpace;
		if (mRenderer.Initialize(mDevice, setup.VertexShader, setup.FragmentShader, setup.Format, setup.FrameCount,
			setup.DistanceFieldShader, setup.GradientRadialShader, setup.GradientConicShader, config) case .Err(let error))
			return .Err(error);
		mCanvas.SetPerPixelGradients((setup.GradientRadialShader != null) && (setup.GradientConicShader != null));
		return .Ok;
	}

	/// Forgets every bake (its targets first) and releases the renderer. The GPU must be done with
	/// them (a host disposes after its device is idle).
	public void Dispose()
	{
		for (let entry in mEntries)
			Release(entry);
		ClearAndDeleteItems!(mEntries);
		for (let page in mPages)
			Release(page);
		ClearAndDeleteItems!(mPages);
		ClearAndDeleteItems!(mAtlas);
		mTargets.Clear();
		if (mRenderer.IsInitialized)
			mRenderer.Dispose();
	}

	/// The fonts an SVG's text draws with from now on (the host's changed: a project's own).
	/// Borrowed.
	public void SetFontService(IFontService fonts)
	{
		mCanvas.SetFontService(fonts);
	}

	/// A renderer that samples the bakes (a window's): every bake drawn is registered with it,
	/// those drawn before too. Borrowed: RemoveTarget before it goes.
	public void AddTarget(VGRenderer target)
	{
		for (let known in mTargets)
		{
			if (known == target)
				return;
		}
		mTargets.Add(target);
		for (let entry in mEntries)
		{
			if (entry.View != null)
				target.RegisterExternalTexture(entry.Key, entry.View);
		}
		for (let page in mPages)
		{
			if (page.View != null)
				target.RegisterExternalTexture(page.Key, page.View);
		}
	}

	/// A renderer that goes (its window's): it forgets every bake, and is told of no more.
	public void RemoveTarget(VGRenderer target)
	{
		for (int i < mTargets.Count)
		{
			if (mTargets[i] != target)
				continue;
			for (let entry in mEntries)
			{
				if (entry.View != null)
					target.UnregisterExternalTexture(entry.Key);
			}
			for (let page in mPages)
			{
				if (page.View != null)
					target.UnregisterExternalTexture(page.Key);
			}
			mTargets.RemoveAt(i);
			return;
		}
	}

	public ImageData Baked(SVGDocument document, uint32 width, uint32 height)
	{
		for (let entry in mEntries)
		{
			if ((entry.Document == document) && (entry.Width == width) && (entry.Height == height))
			{
				entry.LastAsked = mFrame;
				return (entry.View != null) ? entry.Key : null;
			}
		}
		let entry = new Entry();
		entry.Document = document;
		entry.Width = width;
		entry.Height = height;
		entry.LastAsked = mFrame;
		entry.Key = new ImageDataRef(width, height);
		mEntries.Add(entry);
		return null;
	}

	public PictureRegion? AtlasRegion(SVGDocument document, uint32 width, uint32 height, bool mask)
	{
		if ((width == 0) || (height == 0) || (width > PictureRegion.cLargestAtlasPicture)
			|| (height > PictureRegion.cLargestAtlasPicture))
			return null;
		for (let entry in mAtlas)
		{
			if ((entry.Document == document) && (entry.Width == width) && (entry.Height == height) && (entry.Mask == mask))
			{
				entry.LastAsked = mFrame;
				if (!entry.Baked)
					return null;
				return PictureRegion(mPages[entry.Page].Key, .((float)entry.X, (float)entry.Y, (float)width, (float)height));
			}
		}
		let entry = new AtlasEntry();
		entry.Document = document;
		entry.Width = width;
		entry.Height = height;
		entry.Mask = mask;
		entry.LastAsked = mFrame;
		if (!Place(entry) && !(PackAnew() && Place(entry)))
		{
			delete entry;
			return null; // no room even packed anew: drawn as paths
		}
		mAtlas.Add(entry);
		return null;
	}

	public uint64 Generation => mGeneration;

	/// Draws the pictures asked for since the last frame into textures, on `encoder` before the
	/// frame's passes that sample them, after the host waited for `frameIndex`'s last use (as it
	/// does before its own renderer's BeginFrame); and lets the bakes go that no draw has asked for
	/// in cKeepFrames frames. True when any baked: the GUI redraws (Generation).
	public bool Record(ICommandEncoder encoder, int32 frameIndex)
	{
		mFrame++;
		for (int i = mEntries.Count; i > 0; i--)
		{
			let entry = mEntries[i - 1];
			if (mFrame - entry.LastAsked > cKeepFrames)
			{
				Release(entry);
				delete entry;
				mEntries.RemoveAt(i - 1);
			}
		}
		for (int i = mAtlas.Count; i > 0; i--)
		{
			if (mFrame - mAtlas[i - 1].LastAsked > cKeepFrames)
			{
				// Its place stays empty until the atlas is packed anew.
				delete mAtlas[i - 1];
				mAtlas.RemoveAt(i - 1);
			}
		}
		mPackedThisFrame = false;
		bool begun = false;
		bool baked = false;
		for (let entry in mEntries)
		{
			if ((entry.View != null) || !mRenderer.IsInitialized)
				continue;
			Begin(frameIndex, ref begun);
			baked = Bake(encoder, frameIndex, entry) || baked;
		}
		for (int page = 0; (page < mPages.Count) && mRenderer.IsInitialized; page++)
		{
			bool waiting = false;
			for (let entry in mAtlas)
				waiting = waiting || ((entry.Page == page) && !entry.Baked);
			if (!waiting)
				continue;
			Begin(frameIndex, ref begun);
			baked = BakePage(encoder, frameIndex, page) || baked;
		}
		if (baked)
			mGeneration++;
		return baked;
	}

	/// The bakes kept (drawn or waiting).
	public int BakeCount => mEntries.Count;
	/// The atlas's pictures kept (drawn or waiting) and its pages.
	public int AtlasPictureCount => mAtlas.Count;
	public int AtlasPageCount => mPages.Count;

	// The bakes' renderer's frame, begun once for the first bake the frame draws.
	private void Begin(int32 frameIndex, ref bool begun)
	{
		if (begun)
			return;
		mRenderer.BeginFrame(frameIndex);
		begun = true;
	}

	// A place on a page for `entry`, a page added when none has room and the atlas may grow.
	private bool Place(AtlasEntry entry)
	{
		let width = entry.Width + 2 * cAtlasGutter;
		let height = entry.Height + 2 * cAtlasGutter;
		for (int i = 0; i <= mPages.Count; i++)
		{
			if (i == mPages.Count)
			{
				if (mPages.Count >= cMostAtlasPages)
					return false;
				mPages.Add(new AtlasPage());
			}
			let at = mPages[i].Packer.Place(width, height);
			if (at.HasValue)
			{
				entry.Page = i;
				entry.X = at.Value.X + cAtlasGutter;
				entry.Y = at.Value.Y + cAtlasGutter;
				entry.Baked = false;
				return true;
			}
		}
		return false;
	}

	// The atlas full: its pages emptied, the pictures asked for lately placed again (to be drawn
	// again), the rest forgotten. Once a frame at most; false when it already was.
	private bool PackAnew()
	{
		if (mPackedThisFrame)
			return false;
		mPackedThisFrame = true;
		for (let page in mPages)
		{
			page.Packer.Reset();
			page.Clear = true;
		}
		for (int i = mAtlas.Count; i > 0; i--)
		{
			let entry = mAtlas[i - 1];
			if ((mFrame - entry.LastAsked > cRecentFrames) || !Place(entry))
			{
				delete entry;
				mAtlas.RemoveAt(i - 1);
			}
		}
		return true;
	}

	// The pictures waiting on page `index`, drawn into it in one pass, each clipped to its place.
	private bool BakePage(ICommandEncoder encoder, int32 frameIndex, int index)
	{
		let page = mPages[index];
		let fresh = page.Texture == null;
		if (fresh)
		{
			var desc = TextureDesc();
			desc.Dimension = .Texture2D;
			desc.Format = mFormat;
			desc.Width = cAtlasPageSize;
			desc.Height = cAtlasPageSize;
			desc.Depth = 1;
			desc.Usage = .RenderTarget | .Sampled;
			desc.Label = "picture atlas";
			if (mDevice.CreateTexture(desc) case .Ok(let texture))
				page.Texture = texture;
			if ((page.Texture != null) && (mDevice.CreateTextureView(page.Texture, .()) case .Ok(let view)))
				page.View = view;
			if (page.View == null)
			{
				Release(page);
				return false;
			}
		}
		mCanvas.Clear();
		for (let entry in mAtlas)
		{
			if ((entry.Page != index) || entry.Baked)
				continue;
			let place = Rectangle((float)entry.X, (float)entry.Y, (float)entry.Width, (float)entry.Height);
			mCanvas.PushClipRect(place);
			Color? tint = null;
			if (entry.Mask)
				tint = Color.White;
			SVGRenderer.Render(mCanvas, entry.Document, place, tint);
			mCanvas.PopClip();
		}
		let slice = mRenderer.Prepare(mCanvas.GetBatch(), frameIndex, cAtlasPageSize, cAtlasPageSize);
		encoder.TransitionTexture(page.Texture, fresh ? ResourceState.Undefined : ResourceState.ShaderRead, .RenderTarget);
		var color = ColorAttachment();
		color.View = page.View;
		color.LoadOp = page.Clear ? LoadOp.Clear : LoadOp.Load;
		color.StoreOp = .Store;
		color.ClearValue = .(0.0f, 0.0f, 0.0f, 0.0f);
		var pass = RenderPassDesc();
		pass.ColorAttachments.Add(color);
		pass.Label = "picture atlas";
		if (let encoderPass = encoder.BeginRenderPass(pass))
		{
			if (slice.IsValid)
				mRenderer.Render(encoderPass, cAtlasPageSize, cAtlasPageSize, frameIndex, slice);
			encoderPass.End();
		}
		encoder.TransitionTexture(page.Texture, .RenderTarget, .ShaderRead);
		page.Clear = false;
		if (fresh)
		{
			for (let target in mTargets)
				target.RegisterExternalTexture(page.Key, page.View);
		}
		for (let entry in mAtlas)
		{
			if (entry.Page == index)
				entry.Baked = true;
		}
		return true;
	}

	private void Release(AtlasPage page)
	{
		if (page.View != null)
		{
			for (let target in mTargets)
				target.UnregisterExternalTexture(page.Key);
			mDevice.DestroyTextureView(ref page.View);
			page.View = null;
		}
		if (page.Texture != null)
		{
			mDevice.DestroyTexture(ref page.Texture);
			page.Texture = null;
		}
	}

	private bool Bake(ICommandEncoder encoder, int32 frameIndex, Entry entry)
	{
		var desc = TextureDesc();
		desc.Dimension = .Texture2D;
		desc.Format = mFormat;
		desc.Width = entry.Width;
		desc.Height = entry.Height;
		desc.Depth = 1;
		desc.Usage = .RenderTarget | .Sampled;
		desc.Label = "picture bake";
		if (mDevice.CreateTexture(desc) case .Ok(let texture))
			entry.Texture = texture;
		if ((entry.Texture != null) && (mDevice.CreateTextureView(entry.Texture, .()) case .Ok(let view)))
			entry.View = view;
		if (entry.View == null)
		{
			Release(entry);
			return false;
		}
		mCanvas.Clear();
		SVGRenderer.Render(mCanvas, entry.Document, .(0.0f, 0.0f, (float)entry.Width, (float)entry.Height));
		let slice = mRenderer.Prepare(mCanvas.GetBatch(), frameIndex, entry.Width, entry.Height);
		encoder.TransitionTexture(entry.Texture, .Undefined, .RenderTarget);
		var color = ColorAttachment();
		color.View = entry.View;
		color.LoadOp = .Clear;
		color.StoreOp = .Store;
		color.ClearValue = .(0.0f, 0.0f, 0.0f, 0.0f);
		var pass = RenderPassDesc();
		pass.ColorAttachments.Add(color);
		pass.Label = "picture bake";
		if (let encoderPass = encoder.BeginRenderPass(pass))
		{
			if (slice.IsValid)
				mRenderer.Render(encoderPass, entry.Width, entry.Height, frameIndex, slice);
			encoderPass.End();
		}
		encoder.TransitionTexture(entry.Texture, .RenderTarget, .ShaderRead);
		for (let target in mTargets)
			target.RegisterExternalTexture(entry.Key, entry.View);
		return true;
	}

	private void Release(Entry entry)
	{
		if (entry.View != null)
		{
			for (let target in mTargets)
				target.UnregisterExternalTexture(entry.Key);
			mDevice.DestroyTextureView(ref entry.View);
			entry.View = null;
		}
		if (entry.Texture != null)
		{
			mDevice.DestroyTexture(ref entry.Texture);
			entry.Texture = null;
		}
	}
}
