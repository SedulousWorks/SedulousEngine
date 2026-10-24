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

	private IDevice mDevice; // borrowed
	private VGRenderer mRenderer = new .() ~ delete _; // the bakes' own: its frame buffers are not the GUI's
	private VGContext mCanvas ~ delete _;
	private TextureFormat mFormat = .RGBA8UnormSrgb;
	private List<VGRenderer> mTargets = new .() ~ delete _; // the windows' renderers, which sample the bakes; borrowed
	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
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
		bool begun = false;
		bool baked = false;
		for (let entry in mEntries)
		{
			if ((entry.View != null) || !mRenderer.IsInitialized)
				continue;
			if (!begun)
			{
				mRenderer.BeginFrame(frameIndex);
				begun = true;
			}
			baked = Bake(encoder, frameIndex, entry) || baked;
		}
		if (baked)
			mGeneration++;
		return baked;
	}

	/// The bakes kept (drawn or waiting).
	public int BakeCount => mEntries.Count;

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
