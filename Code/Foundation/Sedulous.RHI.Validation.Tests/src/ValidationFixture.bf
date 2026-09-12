using System;
using System.Collections;
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

	// Everything handed out by the helpers below, plus whatever a test hands over with Own.
	// The null backend does not track what it creates, so an undestroyed resource is a leak;
	// the validation layer only REPORTS live ones, which is a diagnostic rather than a sweep.
	private List<IBuffer> mBuffers = new .() ~ delete _;
	private List<ITexture> mTextures = new .() ~ delete _;
	private List<ITextureView> mViews = new .() ~ delete _;
	private List<ICommandPool> mPools = new .() ~ delete _;
	private List<IShaderModule> mModules = new .() ~ delete _;
	private List<IRenderPipeline> mRenderPipelines = new .() ~ delete _;
	private List<IComputePipeline> mComputePipelines = new .() ~ delete _;

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

	/// Frees what the tests left live, in dependency order, then the device.
	///
	/// A test that wants to observe the layer's own "destroyed with N live" warning destroys
	/// nothing and still leaks nothing, which is the point of putting this here rather than in
	/// each test body.
	public ~this()
	{
		if (Device == null)
			return;

		// Views before their textures, and pipelines before the modules they were built from.
		for (var view in ref mViews)
			Device.DestroyTextureView(ref view);
		for (var texture in ref mTextures)
			Device.DestroyTexture(ref texture);
		for (var pipeline in ref mRenderPipelines)
			Device.DestroyRenderPipeline(ref pipeline);
		for (var pipeline in ref mComputePipelines)
			Device.DestroyComputePipeline(ref pipeline);
		for (var module in ref mModules)
			Device.DestroyShaderModule(ref module);
		for (var buffer in ref mBuffers)
			Device.DestroyBuffer(ref buffer);
		for (var pool in ref mPools)
			Device.DestroyCommandPool(ref pool);

		Device.Destroy();
		Device = null;
	}

	// ---- Handing a resource over, for what a test creates itself ----

	public IBuffer Own(IBuffer x) { if (x != null) mBuffers.Add(x); return x; }
	public ITexture Own(ITexture x) { if (x != null) mTextures.Add(x); return x; }
	public ITextureView Own(ITextureView x) { if (x != null) mViews.Add(x); return x; }
	public ICommandPool Own(ICommandPool x) { if (x != null) mPools.Add(x); return x; }
	public IShaderModule Own(IShaderModule x) { if (x != null) mModules.Add(x); return x; }
	public IRenderPipeline Own(IRenderPipeline x) { if (x != null) mRenderPipelines.Add(x); return x; }
	public IComputePipeline Own(IComputePipeline x) { if (x != null) mComputePipelines.Add(x); return x; }

	/// A buffer that passes validation, for tests that need a valid argument.
	public IBuffer MakeBuffer(uint64 size = 256)
	{
		var desc = BufferDesc();
		desc.Size = size;
		if (Device.CreateBuffer(desc) case .Ok(let buffer))
			return Own(buffer);
		return null;
	}

	public ITexture MakeTexture()
	{
		if (Device.CreateTexture(TextureDesc.RenderTarget(.RGBA8Unorm, 64, 64)) case .Ok(let t))
			return Own(t);
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
		pool = Own(createdPool);
		if (!(pool.CreateEncoder() case .Ok(let createdEncoder)))
			return null;
		encoder = createdEncoder;

		let texture = MakeTexture();
		if (!(Device.CreateTextureView(texture, .()) case .Ok(let view)))
			return null;

		Own(view);

		var desc = RenderPassDesc();
		var attachment = ColorAttachment();
		attachment.View = view;
		desc.ColorAttachments.Add(attachment);

		let pass = encoder.BeginRenderPass(desc);
		Messages.Clear();
		return pass;
	}
}
