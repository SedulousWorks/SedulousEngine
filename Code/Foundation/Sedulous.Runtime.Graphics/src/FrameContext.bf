using System;
using Sedulous.RHI;

namespace Sedulous.RuntimeGraphics;

/// Per-window, per-frame hand-off. Returned by RenderWindow.BeginFrame() and
/// passed to consumers. The host owns acquire/fence sync/submit/present and
/// the backbuffer state transitions; the consumer records content (or calls
/// BeginBackbufferPass for the common clear+pass case).
struct FrameContext
{
	/// False when the window is minimized or acquire failed -- skip rendering.
	public bool Valid = false;
	/// Which window this frame targets.
	public RenderWindow Window = null;
	/// Device ring index (0..framesInFlight-1).
	public uint32 FrameIndex = 0;
	/// Current backbuffer width in pixels.
	public uint32 Width = 0;
	/// Current backbuffer height in pixels.
	public uint32 Height = 0;
	/// Primary command encoder, host-created.
	public ICommandEncoder Encoder = null;
	/// This frame's command pool (for creating extra encoders).
	public ICommandPool Pool = null;
	/// The current swapchain backbuffer texture.
	public ITexture Backbuffer = null;
	/// View of the current swapchain backbuffer.
	public ITextureView BackbufferView = null;

	private IRenderPassEncoder mPass = null;

	/// Convenience for the common 2D/UI case: open a render pass that clears
	/// and targets the backbuffer (the Undefined->RenderTarget transition was
	/// already done by the host in BeginFrame). A RenderGraph-driven renderer
	/// ignores this and records on `Encoder` directly.
	public IRenderPassEncoder BeginBackbufferPass(ClearColor clear) mut
	{
		ColorAttachment ca = .()
		{
			View = BackbufferView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = clear
		};

		RenderPassDesc rpd = .();
		rpd.ColorAttachments.Add(ca);
		mPass = (Encoder != null) ? Encoder.BeginRenderPass(rpd) : null;
		return mPass;
	}

	/// Ends the backbuffer render pass started by BeginBackbufferPass.
	public void EndBackbufferPass() mut
	{
		if (mPass != null)
		{
			mPass.End();
			mPass = null;
		}
	}

	/// One-call clear of the backbuffer (open a clear pass, close it). For
	/// minimal apps that just want a visible, cleared window without touching
	/// RHI types.
	public void Clear(float r, float g, float b, float a = 1.0f) mut
	{
		BeginBackbufferPass(ClearColor(r, g, b, a));
		EndBackbufferPass();
	}
}
