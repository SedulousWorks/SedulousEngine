using System;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.Shell;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.UI.Runtime;

/// One window's UI payload, carried on the render window itself.
///
/// The graphics host reserves a slot on each render window for exactly this, so the UI's
/// per-window state travels with the window rather than being tracked in a parallel map that
/// could fall out of step with it.
///
/// It OWNS the window's vector context, renderer, input surface and quality targets, and SHARES
/// its root view with the UI context.
class UIWindowData : IRenderWindowData
{
	/// Four samples: enough for edge antialiasing on fills and strokes without the bandwidth
	/// of more.
	public const uint32 MsaaSamples = 4;

	public RootView Root = null ~ _?.ReleaseRef();
	public VGContext VG = new .() ~ delete _;
	public VGRenderer Renderer = new .() ~ delete _;
	public InputSurface Surface = null ~ delete _;

	/// BORROWED, and kept only so the targets can be destroyed.
	public IDevice Device = null;

	// The quality targets. A four sample colour target resolved into the backbuffer, and a
	// stencil attachment for the fill pipelines: stencil-then-cover is what makes holes,
	// self-intersection and even-odd fills come out right. Null means the plain single
	// sampled pass.
	public ITexture MsaaColor = null;
	public ITextureView MsaaColorView = null;
	public ITexture DepthStencil = null;
	public ITextureView DepthStencilView = null;
	public TextureFormat DepthStencilFormat = .Undefined;
	public uint32 TargetWidth = 0;
	public uint32 TargetHeight = 0;

	public ~this()
	{
		DestroyTargets();
	}

	/// Builds the quality targets at a size.
	///
	/// ANY failure tears down everything: the window falls back to the plain pass as a unit,
	/// because a stencil pipeline without its attachment would be an invalid pass rather than
	/// a slightly worse one.
	public bool CreateTargets(TextureFormat colorFormat, uint32 width, uint32 height)
	{
		DestroyTargets();

		if ((Device == null) || (width == 0) || (height == 0) || (DepthStencilFormat == .Undefined))
			return false;

		var colorDesc = TextureDesc.RenderTarget(colorFormat, width, height);
		colorDesc.SampleCount = MsaaSamples;
		colorDesc.Label = "UI MSAA color";

		if (Device.CreateTexture(colorDesc) case .Ok(let color))
			MsaaColor = color;
		else
			return false;

		var depthDesc = TextureDesc();
		depthDesc.Dimension = .Texture2D;
		depthDesc.Format = DepthStencilFormat;
		depthDesc.Width = width;
		depthDesc.Height = height;
		depthDesc.Depth = 1;
		depthDesc.Usage = .DepthStencil;
		depthDesc.SampleCount = MsaaSamples;
		depthDesc.Label = "UI stencil";

		if (Device.CreateTexture(depthDesc) case .Ok(let depth))
			DepthStencil = depth;
		else
		{
			DestroyTargets();
			return false;
		}

		if (Device.CreateTextureView(MsaaColor, .()) case .Ok(let colorView))
			MsaaColorView = colorView;
		else
		{
			DestroyTargets();
			return false;
		}

		if (Device.CreateTextureView(DepthStencil, .()) case .Ok(let depthView))
			DepthStencilView = depthView;
		else
		{
			DestroyTargets();
			return false;
		}

		TargetWidth = width;
		TargetHeight = height;
		return true;
	}

	public void DestroyTargets()
	{
		if (Device == null)
			return;

		if (MsaaColorView != null)
			Device.DestroyTextureView(ref MsaaColorView);
		if (MsaaColor != null)
			Device.DestroyTexture(ref MsaaColor);
		if (DepthStencilView != null)
			Device.DestroyTextureView(ref DepthStencilView);
		if (DepthStencil != null)
			Device.DestroyTexture(ref DepthStencil);

		TargetWidth = 0;
		TargetHeight = 0;
	}

	/// Whether the targets are present and sized for this frame. A resize recreates them in
	/// Update, outside any open frame, so a frame arriving mid-resize falls back rather than
	/// drawing into a stale target.
	public bool TargetsMatch(uint32 width, uint32 height) =>
		(MsaaColorView != null) && (TargetWidth == width) && (TargetHeight == height);
}
