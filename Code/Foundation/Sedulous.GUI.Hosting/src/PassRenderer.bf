using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.GUI;

// GuiPassRenderer: a root drawn into a render pass its caller owns (E4 of
// Specs/gui-lab-evolution-3.md, in Raptor).
//
// The window host owns its windows' backbuffers and opens its own passes; an engine owns its frame
// and hands its overlays a pass that is already open, on a target of its own format, maybe with a
// depth-stencil attachment, maybe a region of it (a split screen's view). This draws a root there:
// on a device the caller gives (no window, no shell), with the VG shaders and a picture baker of
// its own. A renderer per kind of pass it is asked to draw into (format, depth-stencil, samples,
// blend space), each rewound once a frame however many roots draw through it, so a frame's
// overlays never overwrite each other's slices.
//
// A frame: BeginFrame; RecordBakes on the frame's encoder before any pass that samples them; then
// per root, Prepare (its offscreen layers recorded on the encoder when one is given, else drawn in
// place) before the pass opens, and Draw inside it; or DrawInPass where only the pass is at hand.
// The root is styled and laid out at the view's size by its owner first: this only draws.
//
// The bakes hold colour in one blend space (the constructor's), as a window host's do: a pass in
// the other space shows them a little off at their soft edges.

/// The pass a root draws into, and where in it.
struct GuiPassView
{
	/// The region's corner in the pass's target, in pixels.
	public int32 X = 0;
	public int32 Y = 0;
	/// The region's size: the root's content maps to it.
	public uint32 Width = 0;
	public uint32 Height = 0;
	public TextureFormat Format = .BGRA8Unorm;
	/// The pass's depth-stencil attachment (Undefined: colour only); with one, fills that need it
	/// use the stencil.
	public TextureFormat DepthStencilFormat = .Undefined;
	public uint32 SampleCount = 1;
	/// The pass draws through a UNORM view of an sRGB target, colours kept encoded (VG's Encoded
	/// blend space); false: linear light.
	public bool Encoded = false;
	public uint32 FrameIndex = 0;
	/// The root's pixels onto the region's: identity, or a quarter turn when the content is
	/// presented turned (a landscape game on a portrait target).
	public Float4x4 Transform = Float4x4.Identity();

	public this() {}
}

class GuiPassRenderer
{
	/// A root's batch uploaded for one pass, drawn into it by Draw (this frame only). The renderer
	/// is the pass renderer's.
	public struct Prepared
	{
		/// Null: nothing to draw.
		public VGRenderer Renderer = null;
		public VGRenderSlice Slice = .();
		public GuiPassView View = .();

		public this() {}
	}

	private class Entry
	{
		public VGRenderer Renderer = new .() ~ delete _;
		public TextureFormat Format = .Undefined;
		public TextureFormat DepthStencilFormat = .Undefined;
		public uint32 SampleCount = 1;
		public bool Encoded = false;
		public uint64 BegunFrame = uint64.MaxValue; // the frame its ring last rewound in
	}

	private struct Texture
	{
		public ImageData Key;
		public ITextureView View;

		public this(ImageData key, ITextureView view)
		{
			Key = key;
			View = view;
		}
	}

	private IDevice mDevice; // borrowed
	private uint32 mFramesInFlight;
	private VgShaderSet mShaders; // borrowed modules
	private VGContext mCanvas ~ delete _;
	private GpuPictureBaker mBaker = null ~ delete _;
	private List<Entry> mRenderers = new .() ~ DeleteContainerAndItems!(_);
	private List<Texture> mTextures = new .() ~ delete _;
	private uint64 mFrame = 0;
	private bool mBakesRecorded = false;

	/// Draws on `device` with `framesInFlight` frame slots, `fonts` the GUI's text and an SVG's,
	/// `shaders` (borrowed, outliving this); bakes in `bakeFormat` and `bakeSpace`. The device and
	/// fonts are borrowed.
	public this(IDevice device, uint32 framesInFlight, IFontService fonts, VgShaderSet shaders,
		TextureFormat bakeFormat = .RGBA8UnormSrgb, VGBlendSpace bakeSpace = .Linear)
	{
		mDevice = device;
		mFramesInFlight = (framesInFlight == 0) ? 1 : framesInFlight;
		mShaders = shaders;
		mCanvas = new .(fonts);
		if (!mShaders.IsUsable)
			return;
		mCanvas.SetPerPixelGradients((mShaders.GradientRadial != null) && (mShaders.GradientConic != null));
		mCanvas.SetAnalyticBoxes((mShaders.BoxVertex != null) && (mShaders.BoxFragment != null));
		mBaker = new GpuPictureBaker(device, fonts);
		var setup = PictureBakerSetup();
		setup.VertexShader = mShaders.Vertex;
		setup.FragmentShader = mShaders.Fragment;
		setup.GradientRadialShader = mShaders.GradientRadial;
		setup.GradientConicShader = mShaders.GradientConic;
		setup.DistanceFieldShader = mShaders.DistanceField;
		setup.Format = bakeFormat;
		setup.BlendSpace = bakeSpace;
		setup.FrameCount = (int32)mFramesInFlight;
		if (mBaker.Initialize(setup) case .Err)
			DeleteAndNullify!(mBaker);
	}

	public ~this()
	{
		// No early return: it would skip the fields' own deletes after this body.
		if (!mRenderers.IsEmpty || (mBaker != null))
			Release();
	}

	private void Release()
	{
		mDevice.WaitIdle(); // frames in flight sample the bakes and read the renderers' rings
		for (let entry in mRenderers)
		{
			if (mBaker != null)
				mBaker.RemoveTarget(entry.Renderer);
			entry.Renderer.Dispose();
		}
		ClearAndDeleteItems!(mRenderers);
		if (mBaker != null)
			mBaker.Dispose();
	}

	/// Whether anything can be drawn: the shaders every draw needs are there.
	public bool IsUsable => mShaders.IsUsable;
	/// The baker its roots' SVG skins draw from (the GUI's, GUIContext.PictureBaker); null without
	/// shaders. The pass renderer's.
	public GpuPictureBaker Baker => mBaker;

	/// The fonts its roots' text and an SVG's draw with from now on (the GUI's changed: a
	/// project's own): what made a text's glyphs is what draws them. Borrowed.
	public void SetFontService(IFontService fonts)
	{
		mCanvas.SetFontService(fonts);
		if (mBaker != null)
			mBaker.SetFontService(fonts);
	}

	/// A frame begins: each renderer rewinds at its first use in it, and the bakes may record.
	public void BeginFrame()
	{
		mFrame++;
		mBakesRecorded = false;
	}

	/// The bakes queued since the last frame, recorded on `encoder` before any pass that samples
	/// them; once a frame (false after the first, or with nothing recorded).
	public bool RecordBakes(ICommandEncoder encoder, uint32 frameIndex)
	{
		if ((mBaker == null) || mBakesRecorded)
			return false;
		mBakesRecorded = true;
		return mBaker.Record(encoder, (int32)frameIndex);
	}

	/// `root` drawn for `view` and uploaded, before the pass opens: its offscreen layers recorded
	/// on `layers` when given (passes do not nest), else drawn in place.
	public Prepared Prepare(SceneRoot root, GuiPassView view, ICommandEncoder layers = null)
	{
		var prepared = Prepared();
		prepared.View = view;
		if (!mShaders.IsUsable || (view.Width == 0) || (view.Height == 0))
			return prepared;
		let renderer = RendererFor(view);
		if (renderer == null)
			return prepared;
		let stencil = (view.DepthStencilFormat != .Undefined) && renderer.StencilFillsSupported;
		let layered = (layers != null) && (mShaders.Layer != null);
		mCanvas.SetStencilFills(stencil); // what the batch emits matches the pass it draws into
		mCanvas.SetLayers(layered);
		mCanvas.Clear();
		mCanvas.SetTransform(view.Transform);
		{
			let context = scope DrawContext(mCanvas);
			root.DrawFrame(context);
		}
		let batch = mCanvas.GetBatch();
		if (batch.Commands.IsEmpty)
			return prepared;
		let slot = (int32)(view.FrameIndex % mFramesInFlight);
		prepared.Slice = renderer.Prepare(batch, slot, view.Width, view.Height);
		prepared.Renderer = renderer;
		if (layered)
			renderer.RenderLayers(layers, slot, prepared.Slice);
		return prepared;
	}

	/// What Prepare uploaded, drawn into the open pass at its view's region.
	public void Draw(IRenderPassEncoder pass, Prepared prepared)
	{
		if (prepared.Renderer == null)
			return;
		let view = prepared.View;
		prepared.Renderer.Render(pass, view.X, view.Y, view.Width, view.Height, (int32)(view.FrameIndex % mFramesInFlight),
			prepared.Slice);
	}

	/// Prepare and Draw where only the open pass is at hand: its layers drawn in place.
	public void DrawInPass(SceneRoot root, IRenderPassEncoder pass, GuiPassView view)
	{
		Draw(pass, Prepare(root, view));
	}

	/// An image the GUI draws by `key` (an image source the caller's resource provider answers)
	/// sampled from `view`: told to every renderer, those made later too. Both borrowed:
	/// UnregisterTexture before either goes.
	public void RegisterTexture(ImageData key, ITextureView view)
	{
		if ((key == null) || (view == null))
			return;
		UnregisterTexture(key);
		mTextures.Add(.(key, view));
		for (let entry in mRenderers)
			entry.Renderer.RegisterExternalTexture(key, view);
	}

	public void UnregisterTexture(ImageData key)
	{
		for (int i < mTextures.Count)
		{
			if (mTextures[i].Key != key)
				continue;
			for (let entry in mRenderers)
				entry.Renderer.UnregisterExternalTexture(key);
			mTextures.RemoveAt(i);
			return;
		}
	}

	/// The renderers made so far, one per kind of pass drawn into.
	public int RendererCount => mRenderers.Count;

	/// The renderer drawing into passes like `view`'s; null before one was drawn into. The pass
	/// renderer's.
	public VGRenderer FindRenderer(GuiPassView view)
	{
		let entry = Find(view);
		return (entry != null) ? entry.Renderer : null;
	}

	private Entry Find(GuiPassView view)
	{
		for (let entry in mRenderers)
		{
			if ((entry.Format == view.Format) && (entry.DepthStencilFormat == view.DepthStencilFormat) &&
				(entry.SampleCount == view.SampleCount) && (entry.Encoded == view.Encoded))
				return entry;
		}
		return null;
	}

	// The renderer for passes like `view`'s, made at its first use, rewound once a frame (a rewind
	// clears what the frame's earlier roots uploaded).
	private VGRenderer RendererFor(GuiPassView view)
	{
		var entry = Find(view);
		if (entry == null)
		{
			let made = new Entry();
			var config = VGTargetConfig();
			config.SampleCount = (view.SampleCount == 0) ? 1 : view.SampleCount;
			config.DepthStencilFormat = view.DepthStencilFormat;
			config.BlendSpace = view.Encoded ? .Encoded : .Linear;
			if (made.Renderer.Initialize(mDevice, mShaders.Vertex, mShaders.Fragment, view.Format, (int32)mFramesInFlight,
				mShaders.DistanceField, mShaders.GradientRadial, mShaders.GradientConic, config, mShaders.BoxShadow,
				mShaders.BoxVertex, mShaders.BoxFragment, mShaders.Layer, mShaders.BlurVertex, mShaders.BlurFragment) case .Err)
			{
				delete made;
				return null;
			}
			made.Format = view.Format;
			made.DepthStencilFormat = view.DepthStencilFormat;
			made.SampleCount = view.SampleCount;
			made.Encoded = view.Encoded;
			if (mBaker != null)
				mBaker.AddTarget(made.Renderer);
			for (let texture in mTextures)
				made.Renderer.RegisterExternalTexture(texture.Key, texture.View);
			entry = made;
			mRenderers.Add(made);
		}
		if (entry.BegunFrame != mFrame)
		{
			entry.Renderer.BeginFrame((int32)(view.FrameIndex % mFramesInFlight));
			entry.BegunFrame = mFrame;
		}
		return entry.Renderer;
	}
}
