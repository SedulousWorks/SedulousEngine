using Sedulous.RHI;

namespace Sedulous.Graphics;

/// One window's hand off for one frame.
///
/// The HOST owns acquire, fence synchronisation, submit, present and the back buffer's
/// state transitions; a consumer records content into `Encoder` and nothing else. That
/// split is what lets a UI, a sample and a renderer share one presentation path.
struct FrameContext
{
	/// False means SKIP this window this frame: it is minimised, zero sized, the device
	/// is lost, or the acquire failed. Everything else here is meaningless when it is.
	public bool Valid = false;

	public RenderWindow Window = null;

	/// The device's ring index, 0 to FramesInFlight - 1. A consumer keys its own per
	/// frame resources on this.
	public uint32 FrameIndex = 0;

	/// The BACK BUFFER's size, not the live window's.
	///
	/// The two differ for a frame after a resize the host has not synced yet, and every
	/// viewport and scissor downstream has to agree with the attachment actually being
	/// rendered into: a viewport outside it is rejected, and on WebGPU that drops the
	/// whole command buffer rather than the one call.
	public uint32 Width = 0;
	public uint32 Height = 0;

	/// The primary encoder, created by the host and already open.
	public ICommandEncoder Encoder = null;

	/// This frame's pool, for a consumer that wants a second encoder.
	public ICommandPool Pool = null;

	public ITexture Backbuffer = null;
	public ITextureView BackbufferView = null;

	private IRenderPassEncoder mPass = null;

	public this() {}

	/// Opens a pass that clears and targets the back buffer.
	///
	/// The common 2D and UI case. The Undefined to RenderTarget transition already
	/// happened in BeginFrame, so this is only the pass. A render graph driven renderer
	/// ignores it and records on Encoder directly.
	public IRenderPassEncoder BeginBackbufferPass(ClearColor clear) mut
	{
		if (Encoder == null)
		{
			mPass = null;
			return null;
		}

		var colorAttachment = ColorAttachment();
		colorAttachment.View = BackbufferView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = clear;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		mPass = Encoder.BeginRenderPass(passDesc);
		return mPass;
	}

	public void EndBackbufferPass() mut
	{
		if (mPass != null)
		{
			mPass.End();
			mPass = null;
		}
	}

	/// Clears the back buffer and nothing else, for an app that wants a visible window
	/// without touching an RHI type.
	public void Clear(float r, float g, float b, float a = 1.0f) mut
	{
		BeginBackbufferPass(.(r, g, b, a));
		EndBackbufferPass();
	}
}
