namespace Sedulous.Engine.UI;

using System;
using Sedulous.Scenes;
using Sedulous.RHI;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.Fonts;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;

/// Per-scene manager for world-space UI components.
/// WIP: Render-to-texture for world UI views requires access to a command
/// encoder during the render phase. Current engine infrastructure doesn't
/// provide this to component managers. Screen UI (ScreenUIView) works via
/// IRenderOverlay. World UI needs infrastructure changes to VGRenderer
/// or the render pipeline before it can render to textures.
class UIComponentManager : ComponentManager<UIComponent>
{
	// Injected by EngineUISubsystem.
	public IDevice Device;
	public UIContext UIContext;
	public IFontService FontService;
	public ShaderSystem ShaderSystem;

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostUpdate, new => RenderDirtyViews);
	}

	protected override void OnComponentInitialized(UIComponent comp)
	{
		if (Device == null || UIContext == null) return;

		// Create RootView in shared UIContext.
		comp.Root = new RootView();
		comp.Root.ViewportSize = .((float)comp.PixelWidth, (float)comp.PixelHeight);
		UIContext.AddRootView(comp.Root);

		// Per-view VG rendering.
		comp.VG = new VGContext(FontService);

		comp.Renderer = new VGRenderer();
		if (comp.Renderer.Initialize(Device, .RGBA8Unorm, 2, ShaderSystem) case .Err)
		{
			Console.WriteLine("UIComponentManager: failed to initialize VGRenderer");
			return;
		}

		// Create render target texture.
		TextureDesc texDesc = .()
		{
			Width = comp.PixelWidth,
			Height = comp.PixelHeight,
			Format = .RGBA8Unorm,
			Usage = .RenderTarget | .Sampled,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1,
			Label = "WorldUI"
		};

		if (Device.CreateTexture(texDesc) case .Ok(let tex))
		{
			comp.Texture = tex;

			TextureViewDesc viewDesc = .()
			{
				Format = .RGBA8Unorm,
				Dimension = .Texture2D,
				BaseMipLevel = 0,
				MipLevelCount = 1,
				BaseArrayLayer = 0,
				ArrayLayerCount = 1,
				Label = "WorldUIView"
			};

			if (Device.CreateTextureView(tex, viewDesc) case .Ok(let view))
				comp.TextureView = view;
		}

		comp.IsDirty = true;
	}

	protected override void OnComponentDestroyed(UIComponent comp)
	{
		if (comp.Root != null && UIContext != null)
			UIContext.RemoveRootView(comp.Root);

		if (comp.Renderer != null)
		{
			comp.Renderer.Dispose();
			delete comp.Renderer;
			comp.Renderer = null;
		}

		delete comp.VG;
		comp.VG = null;

		if (comp.TextureView != null)
			Device?.DestroyTextureView(ref comp.TextureView);
		if (comp.Texture != null)
			Device?.DestroyTexture(ref comp.Texture);

		delete comp.Root;
		comp.Root = null;
	}

	/// Render all dirty world UI views to their textures.
	private void RenderDirtyViews(float deltaTime)
	{
		if (UIContext == null || Device == null) return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.IsVisible || !comp.IsDirty) continue;
			if (comp.Root == null || comp.VG == null || comp.Renderer == null) continue;
			if (comp.Texture == null || comp.TextureView == null) continue;

			// Layout.
			UIContext.UpdateRootView(comp.Root);

			// Build geometry.
			comp.VG.Clear();
			UIContext.DrawRootView(comp.Root, comp.VG);
			let batch = comp.VG.GetBatch();
			if (batch == null || batch.Commands.Count == 0)
			{
				comp.IsDirty = false;
				continue;
			}

			// Upload + render to texture.
			// Use frameIndex 0 for world views (they render on-demand, not double-buffered).
			comp.Renderer.UpdateProjection(comp.PixelWidth, comp.PixelHeight, 0);
			comp.Renderer.Prepare(batch, 0);

			// TODO: Need a command encoder to create a render pass.
			// World UI render-to-texture needs to happen during the render phase,
			// not during PostUpdate. For now, mark clean and defer actual rendering
			// to a render pass or overlay mechanism.
			//
			// Option: UIComponentManager could implement IRenderDataProvider and
			// render dirty views during ExtractRenderData (has access to RenderContext).
			// Or: Register a PipelinePass that renders world UI textures.

			comp.IsDirty = false;
		}
	}
}
