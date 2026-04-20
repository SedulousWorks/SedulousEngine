namespace Sedulous.Engine.UI;

using Sedulous.RHI;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.Fonts;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;

/// Screen-space UI view. Single instance owned by EngineUISubsystem.
/// Called by EngineUISubsystem.RenderOverlay to composite UI onto the swapchain.
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

	/// IRenderOverlay — called by RenderSubsystem after blit, before present.
	public void RenderOverlay(ICommandEncoder encoder, ITextureView targetView,
		uint32 width, uint32 height, int32 frameIndex)
	{
		if (Root == null || mUIContext == null) return;

		Root.ViewportSize = .((float)width, (float)height);

		// Build geometry.
		mVGContext.Clear();
		mUIContext.DrawRootView(Root, mVGContext);
		let batch = mVGContext.GetBatch();
		if (batch == null || batch.Commands.Count == 0)
			return;

		// Upload to GPU.
		mVGRenderer.UpdateProjection(width, height, frameIndex);
		mVGRenderer.Prepare(batch, frameIndex);

		// Create overlay render pass (Load preserves blitted 3D scene).
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
