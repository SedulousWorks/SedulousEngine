using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.RHI.Validation;

namespace Sedulous.RHI.Validation.Tests;

/// A validated backend over the null one, plus a capture of what it reports.
///
/// The null backend is the right thing under it: the layer must be TRANSPARENT, so what is
/// under it should do nothing interesting, and every message then comes from the layer.
class ValidationFixture
{
	public CapturedMessages Messages = new .() ~ delete _;
	private IBackend mInner ~ delete _;
	public IBackend Backend ~ delete _;
	public IDevice Device;

	public this(bool createDevice = true)
	{
		mInner = NullRhi.CreateBackend();
		Backend = ValidationRhi.Wrap(mInner);

		if (createDevice)
		{
			if (Backend.EnumerateAdapters()[0].CreateDevice(.()) case .Ok(let device))
				Device = device;
			// Whatever enumerating and creating reported is not what a test is asking
			// about, so the capture starts clean.
			Messages.Clear();
		}
	}

	/// A buffer that passes validation, for tests that need a valid argument.
	public IBuffer MakeBuffer(uint64 size = 256)
	{
		var desc = BufferDesc();
		desc.Size = size;
		if (Device.CreateBuffer(desc) case .Ok(let buffer))
			return buffer;
		return null;
	}

	public ITexture MakeTexture()
	{
		if (Device.CreateTexture(TextureDesc.RenderTarget(.RGBA8Unorm, 64, 64)) case .Ok(let t))
			return t;
		return null;
	}

	/// An open render pass with one valid colour attachment, which is what most of the
	/// encoder rules need before they can be reached.
	public IRenderPassEncoder BeginPass(out ICommandPool pool, out ICommandEncoder encoder)
	{
		pool = null;
		encoder = null;
		if (!(Device.CreateCommandPool(.Graphics) case .Ok(let createdPool)))
			return null;
		pool = createdPool;
		if (!(pool.CreateEncoder() case .Ok(let createdEncoder)))
			return null;
		encoder = createdEncoder;

		let texture = MakeTexture();
		if (!(Device.CreateTextureView(texture, .()) case .Ok(let view)))
			return null;

		var desc = RenderPassDesc();
		var attachment = ColorAttachment();
		attachment.View = view;
		desc.ColorAttachments.Add(attachment);

		let pass = encoder.BeginRenderPass(desc);
		Messages.Clear();
		return pass;
	}
}
