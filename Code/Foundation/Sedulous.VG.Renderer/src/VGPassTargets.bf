using System;
using Sedulous.RHI;
using Sedulous.VG;

namespace Sedulous.VG.Renderer;

/// The targets VG's quality pass draws into, which the host provides: a multisampled colour
/// target resolved into the backbuffer, for edge antialiasing, and a stencil attachment, for
/// complex fills and clip paths.
///
/// Every host drawing VG with those features needs the same pair at its window's size, so they
/// live here once. A renderer meant for this pass is initialised with ConfigFor's sample count
/// and stencil format.
class VGPassTargets
{
	/// Four samples: enough for edge antialiasing on fills and strokes without the bandwidth
	/// of more.
	public const uint32 DefaultSamples = 4;

	/// BORROWED.
	private IDevice mDevice = null;
	private ITexture mColor = null;
	private ITextureView mColorView = null;
	private ITexture mStencil = null;
	private ITextureView mStencilView = null;
	private TextureFormat mColorFormat = .Undefined;
	private TextureFormat mStencilFormat = .Undefined;
	private uint32 mSamples = DefaultSamples;
	private uint32 mWidth = 0;
	private uint32 mHeight = 0;

	public ~this()
	{
		Destroy();
	}

	public uint32 Samples => mSamples;
	public TextureFormat StencilFormat => mStencilFormat;

	/// Whether a stencil format was found (the renderer is to be configured for the pass).
	public bool IsValid => (mDevice != null) && (mStencilFormat != .Undefined);

	/// Picks the stencil format the device takes at that sample count. None leaves the targets
	/// off, and the host draws the plain pass. Call once, before the renderer is initialised.
	public void Configure(IDevice device, uint32 samples = DefaultSamples)
	{
		Destroy();
		mDevice = device;
		mSamples = samples;
		mStencilFormat = VGRenderer.PickStencilCapableFormat(device, samples);
	}

	/// The renderer's target config for this pass: the sample count and stencil format when the
	/// targets are configured, a plain pass's otherwise.
	public VGTargetConfig ConfigFor(VGBlendSpace blendSpace = .Linear)
	{
		var config = VGTargetConfig();
		if (IsValid)
		{
			config.SampleCount = mSamples;
			config.DepthStencilFormat = mStencilFormat;
		}
		config.BlendSpace = blendSpace;
		return config;
	}

	/// (Re)creates both targets at a size, for a colour target of that format.
	///
	/// ANY failure releases both: a stencil pipeline without its attachment would be an invalid
	/// pass rather than a slightly worse one, so the host falls back to the plain pass as a unit.
	public bool Create(TextureFormat colorFormat, uint32 width, uint32 height)
	{
		ReleaseTargets();

		if ((mDevice == null) || (width == 0) || (height == 0) || (mStencilFormat == .Undefined))
			return false;

		var colorDesc = TextureDesc.RenderTarget(colorFormat, width, height);
		colorDesc.SampleCount = mSamples;
		colorDesc.Label = "VG MSAA color";

		var stencilDesc = TextureDesc();
		stencilDesc.Dimension = .Texture2D;
		stencilDesc.Format = mStencilFormat;
		stencilDesc.Width = width;
		stencilDesc.Height = height;
		stencilDesc.Depth = 1;
		stencilDesc.Usage = .DepthStencil;
		stencilDesc.SampleCount = mSamples;
		stencilDesc.Label = "VG stencil";

		if (mDevice.CreateTexture(colorDesc) case .Ok(let color))
			mColor = color;
		if ((mColor != null) && (mDevice.CreateTexture(stencilDesc) case .Ok(let stencil)))
			mStencil = stencil;
		if ((mStencil != null) && (mDevice.CreateTextureView(mColor, .()) case .Ok(let colorView)))
			mColorView = colorView;
		if ((mColorView != null) && (mDevice.CreateTextureView(mStencil, .()) case .Ok(let stencilView)))
			mStencilView = stencilView;

		if (mStencilView == null)
		{
			ReleaseTargets();
			return false;
		}

		mColorFormat = colorFormat;
		mWidth = width;
		mHeight = height;
		return true;
	}

	/// Whether the targets exist at another size (a resize is due; the host waits for the GPU
	/// to finish with them first). A zero size, a minimised window, keeps them.
	public bool NeedsResize(uint32 width, uint32 height) =>
		(mColorView != null) && (width != 0) && (height != 0) && ((width != mWidth) || (height != mHeight));

	/// Recreates the targets when the size changed. Call outside an open frame, after the GPU
	/// is done with the old ones. False when the targets are off: a window whose first
	/// creation failed has a renderer configured for the plain pass, and stays on it.
	public bool Resize(uint32 width, uint32 height)
	{
		if (mColorView == null)
			return false;
		if ((width == mWidth) && (height == mHeight))
			return true;
		return Create(mColorFormat, width, height);
	}

	public void Destroy()
	{
		ReleaseTargets();
		mStencilFormat = .Undefined;
	}

	/// Whether the targets exist at this size, so this frame can take the quality pass. A
	/// resize recreates them outside any open frame, so a frame arriving mid-resize falls back
	/// rather than drawing into a stale target.
	public bool Matches(uint32 width, uint32 height) =>
		(mColorView != null) && (mWidth == width) && (mHeight == height);

	/// Transitions both targets for a fresh pass and describes it: the multisampled colour
	/// cleared and resolved into the resolve target, the stencil cleared to nought as
	/// stencil-then-cover expects.
	///
	/// From Undefined every frame: both are fully cleared, so their old contents are
	/// discardable.
	public RenderPassDesc BeginPass(ICommandEncoder encoder, ITextureView resolveTarget, ClearColor clear,
		StringView label = "VG (msaa+stencil)")
	{
		encoder.TransitionTexture(mColor, .Undefined, .RenderTarget);
		encoder.TransitionTexture(mStencil, .Undefined, .DepthStencilWrite);

		var color = ColorAttachment();
		color.View = mColorView;
		color.ResolveTarget = resolveTarget;
		color.LoadOp = .Clear;
		// Resolved, so the multisampled texels can be dropped.
		color.StoreOp = .DontCare;
		color.ClearValue = clear;

		var depthStencil = DepthStencilAttachment();
		depthStencil.View = mStencilView;
		depthStencil.DepthLoadOp = .Clear;
		depthStencil.DepthStoreOp = .DontCare;
		depthStencil.StencilLoadOp = .Clear;
		depthStencil.StencilStoreOp = .DontCare;
		depthStencil.StencilClearValue = 0;

		var pass = RenderPassDesc();
		pass.ColorAttachments.Add(color);
		pass.DepthStencilAttachment = depthStencil;
		pass.Label = label;
		return pass;
	}

	private void ReleaseTargets()
	{
		if (mDevice != null)
		{
			if (mColorView != null)
				mDevice.DestroyTextureView(ref mColorView);
			if (mColor != null)
				mDevice.DestroyTexture(ref mColor);
			if (mStencilView != null)
				mDevice.DestroyTextureView(ref mStencilView);
			if (mStencil != null)
				mDevice.DestroyTexture(ref mStencil);
		}
		mColorView = null;
		mColor = null;
		mStencilView = null;
		mStencil = null;
		mWidth = 0;
		mHeight = 0;
	}
}
