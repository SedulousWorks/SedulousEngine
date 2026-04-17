namespace Sedulous.UI.Runtime;

using System;
using Sedulous.Runtime;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;

/// Foundation-layer subsystem for screen-space UI.
/// Owns UIContext, VGContext, VGRenderer, FontService, and ShaderSystem.
/// Register with Context to get automatic Update() calls.
/// Call Render() explicitly after 3D scene rendering, before present.
public class UISubsystem : Subsystem
{
	public override int32 UpdateOrder => 400;

	// Core UI
	private UIContext mUIContext;
	private VGContext mVGContext;
	private VGRenderer mVGRenderer;
	private ShaderSystem mShaderSystem;
	private FontService mFontService;

	// Platform (not owned)
	private IDevice mDevice;

	// State
	private bool mRenderingInitialized;
	private int32 mFrameCount;
	private float mTotalTime;

	/// The global UIContext for screen-space UI.
	public UIContext UIContext => mUIContext;

	/// The font service for loading/caching fonts.
	public FontService FontService => mFontService;

	/// The shader system.
	public ShaderSystem ShaderSystem => mShaderSystem;

	/// Whether rendering has been initialized.
	public bool IsRenderingInitialized => mRenderingInitialized;

	public this()
	{
	}

	/// Initialize rendering resources. Call after the device is ready.
	public Result<void> InitializeRendering(
		IDevice device,
		TextureFormat targetFormat,
		int32 frameCount,
		Span<StringView> shaderPaths)
	{
		mDevice = device;
		mFrameCount = frameCount;

		// Font service
		mFontService = new FontService();

		// Shader system
		mShaderSystem = new ShaderSystem();
		if (mShaderSystem.Initialize(device, shaderPaths) case .Err)
			return .Err;

		// UIContext
		mUIContext = new UIContext();

		// VGContext (with font service so DrawText convenience overloads work)
		mVGContext = new VGContext(mFontService);

		// VGRenderer
		mVGRenderer = new VGRenderer();
		if (mVGRenderer.Initialize(device, targetFormat, frameCount, mShaderSystem) case .Err)
			return .Err;

		mRenderingInitialized = true;
		return .Ok;
	}

	/// Load a font into the font service.
	public Result<void> LoadFont(StringView familyName, StringView filePath, FontLoadOptions options = .ExtendedLatin)
	{
		return mFontService.LoadFont(familyName, filePath, options);
	}

	/// Called each frame by the Context. Routes input, runs mutation queue, layout.
	public override void Update(float deltaTime)
	{
		if (!mRenderingInitialized || mUIContext == null)
			return;

		using (SProfiler.Begin("UISubsystem.Update"))
		{
			mTotalTime += deltaTime;

			// Drain deferred mutations, then run layout.
			mUIContext.BeginFrame(deltaTime);
			mUIContext.DoLayout();
		}
	}

	/// Render UI overlay. Call after 3D scene rendering, before present.
	/// Creates a render pass with LoadOp=Load to preserve existing content.
	public void Render(ICommandEncoder encoder, ITextureView targetView,
		uint32 width, uint32 height, int32 frameIndex)
	{
		if (!mRenderingInitialized || mUIContext == null)
			return;

		using (SProfiler.Begin("UISubsystem.Render"))
		{
			mUIContext.SetViewportSize((float)width, (float)height);

			// Build geometry
			mVGContext.Clear();
			mUIContext.Draw(mVGContext, mUIContext.DpiScale);
			let batch = mVGContext.GetBatch();
			if (batch == null || batch.Commands.Count == 0)
				return;

			// Upload to GPU
			mVGRenderer.UpdateProjection(width, height, frameIndex);
			mVGRenderer.Prepare(batch, frameIndex);

			// Create overlay render pass (Load = preserve 3D scene)
			ColorAttachment[1] colorAttachments = .(.()
			{
				View = targetView,
				ResolveTarget = null,
				LoadOp = .Load,
				StoreOp = .Store,
				ClearValue = .(0, 0, 0, 1)
			});
			RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };

			let renderPass = encoder.BeginRenderPass(passDesc);
			if (renderPass != null)
			{
				mVGRenderer.Render(renderPass, width, height, frameIndex);
				renderPass.End();
			}
		}
	}

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
		if (mVGRenderer != null)
		{
			mVGRenderer.Dispose();
			delete mVGRenderer;
			mVGRenderer = null;
		}

		if (mVGContext != null)
		{
			delete mVGContext;
			mVGContext = null;
		}

		if (mShaderSystem != null)
		{
			mShaderSystem.Dispose();
			delete mShaderSystem;
			mShaderSystem = null;
		}

		if (mFontService != null)
		{
			delete mFontService;
			mFontService = null;
		}

		if (mUIContext != null)
		{
			delete mUIContext;
			mUIContext = null;
		}

		mRenderingInitialized = false;
	}
}
