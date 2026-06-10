namespace Sedulous.Engine.LegacyUI;

using Sedulous.RHI;
using Sedulous.LegacyUI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.Fonts;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;

/// Screen-space UI view. Single instance owned by EngineLegacyUISubsystem.
/// Called by EngineLegacyUISubsystem.Render (forwarded from
/// IScreenRenderer's shared overlay render pass) to composite UI onto
/// the swapchain. The render pass is bound by the screen renderer; this
/// view only records draw commands.
public class ScreenUIView
{
	public RootView Root { get; private set; }

	private UIContext mUIContext;
	private VGContext mVGContext;
	private VGRenderer mVGRenderer;

	public this(UIContext uiContext, IDevice device, TextureFormat targetFormat,
		int32 frameCount, IFontService fontService, ShaderSystem shaderSystem)
	{
		mUIContext = uiContext;

		Root = new RootView();
		uiContext.AddRootView(Root);

		mVGContext = new VGContext(fontService);

		mVGRenderer = new VGRenderer();
		mVGRenderer.Initialize(device, targetFormat, frameCount, shaderSystem);
	}

	public ~this()
	{
		if (mUIContext != null && Root != null)
			mUIContext.RemoveRootView(Root);

		if (mVGRenderer != null)
		{
			mVGRenderer.Dispose();
			delete mVGRenderer;
		}

		delete mVGContext;
		delete Root;
	}

	/// Record screen-space UI draws into the active screen-overlay
	/// render pass. The pass and color target are bound by
	/// `IScreenRenderer.RenderOverlays` before this is called.
	public void Render(IRenderPassEncoder encoder, uint32 width, uint32 height, int32 frameIndex)
	{
		if (Root == null || mUIContext == null) return;

		Root.ViewportSize = .((float)width, (float)height);

		// Build geometry.
		mVGContext.Clear();
		mUIContext.DrawRootView(Root, mVGContext);
		let batch = mVGContext.GetBatch();
		if (batch == null || batch.Commands.Count == 0)
			return;

		// Upload to GPU and emit draws into the already-active render pass.
		mVGRenderer.BeginFrame(frameIndex);
		let slice = mVGRenderer.Prepare(batch, frameIndex, width, height);
		mVGRenderer.Render(encoder, width, height, frameIndex, slice);
	}
}
