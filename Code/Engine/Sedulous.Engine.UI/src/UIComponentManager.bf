namespace Sedulous.Engine.UI;

using System;
using Sedulous.Engine.Core;
using Sedulous.RHI;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.Fonts;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Render;
using Sedulous.Materials;
using Sedulous.Renderer;

/// Per-scene manager for world-space UI components.
/// Creates GPU resources (texture, VGRenderer) per component.
/// Collects dirty views each frame for WorldUIPass to render
/// during the pipeline's render graph execution.
class UIComponentManager : ComponentManager<UIComponent>
{
	// Injected by EngineUISubsystem.
	public IDevice Device;
	public StyleSheet SharedStyleSheet;
	public IFontService FontService;
	public ShaderSystem ShaderSystem;
	public RenderContext RenderContext;

	/// WorldUIPass reads this list each frame to render dirty textures.
	public WorldUIPass RenderPass;

	// Shared VG resources lazy-initialized on first component init. Replace
	// the per-component VG/Renderer fields (currently still allocated in
	// parallel - see sub-phase D/E).
	private VGContext mSharedVG;
	private VGRenderer mSharedVGRenderer;

	/// Shared VGContext used by all components in this scene. Cleared
	/// once per frame in `WorldUIPass`, then reused across each dirty
	/// component's draw.
	public VGContext SharedVG => mSharedVG;

	/// Shared `VGRenderer` used by all components in this scene. One
	/// `BeginFrame` per frame; each dirty component calls `Prepare` to
	/// get its slice and `Render` with the slice into its own texture
	/// render pass.
	public VGRenderer SharedVGRenderer => mSharedVGRenderer;

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostUpdate, new => CollectDirtyViews);
	}

	/// Allocate the per-scene shared VG resources on first component
	/// init. Idempotent. Format matches every UIComponent's render
	/// texture (`.RGBA8UnormSrgb`); the shared renderer's frame count
	/// matches the per-component fields' (`2`).
	private void EnsureSharedResources()
	{
		if (mSharedVGRenderer != null || Device == null || FontService == null || ShaderSystem == null)
			return;

		mSharedVG = new VGContext(FontService);

		mSharedVGRenderer = new VGRenderer();
		if (mSharedVGRenderer.Initialize(Device, .RGBA8UnormSrgb, 2, ShaderSystem) case .Err)
		{
			Console.WriteLine("UIComponentManager: failed to initialize shared VGRenderer");
			delete mSharedVGRenderer;
			mSharedVGRenderer = null;
			delete mSharedVG;
			mSharedVG = null;
		}
	}

	protected override void OnComponentInitialized(UIComponent comp)
	{
		if (Device == null) return;

		// Lazy-init shared VG once we have the injected resources.
		EnsureSharedResources();

		// Create per-component UIContext with shared stylesheet and font service.
		comp.UIContext = new UIContext();
		comp.UIContext.FontService = FontService;
		if (SharedStyleSheet != null)
			comp.UIContext.StyleSheet = SharedStyleSheet;

		// Create RootView in per-component UIContext.
		comp.Root = new RootView();
		comp.Root.ViewportSize = .((float)comp.PixelWidth, (float)comp.PixelHeight);
		comp.UIContext.AddRootView(comp.Root);

		// VG context + renderer are shared across all components in this
		// scene via SharedVG / SharedVGRenderer (Track 3).

		// Create render target texture.
		TextureDesc texDesc = .()
		{
			Width = comp.PixelWidth,
			Height = comp.PixelHeight,
			Format = .RGBA8UnormSrgb,
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
				Format = .RGBA8UnormSrgb,
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

		// Create a SpriteComponent to display the UI texture in the 3D scene.
		// Bypass ResourceRef - create MaterialInstance directly from the texture view.
		let spriteMgr = Scene.GetModule<SpriteComponentManager>();
		if (spriteMgr != null && comp.TextureView != null && RenderContext != null)
		{
			let spriteSystem = RenderContext.SpriteSystem;
			let materialSystem = RenderContext.MaterialSystem;
			if (spriteSystem?.SpriteMaterial != null && materialSystem != null)
			{
				let spriteHandle = spriteMgr.CreateComponent(comp.Owner);
				if (let sprite = spriteMgr.Get(spriteHandle))
				{
					sprite.Size = .(comp.WorldWidth, comp.WorldHeight);
					sprite.Orientation = comp.Orientation;
					sprite.IsVisible = true;

					// Create material instance with the UI render texture.
					let matInstance = new MaterialInstance(spriteSystem.SpriteMaterial);
					matInstance.SetTexture("SpriteTexture", comp.TextureView);
					materialSystem.PrepareInstance(matInstance);
					sprite.SetMaterial(matInstance);
					// Transfer ownership to sprite (SetMaterial called AddRef).
					matInstance.ReleaseRef();
				}
			}
		}
	}

	protected override void OnComponentDestroyed(UIComponent comp)
	{
		if (comp.TextureView != null)
			Device?.DestroyTextureView(ref comp.TextureView);
		if (comp.Texture != null)
			Device?.DestroyTexture(ref comp.Texture);

		// UIContext owns the RootView via AddRootView - remove before deleting.
		if (comp.UIContext != null && comp.Root != null)
			comp.UIContext.RemoveRootView(comp.Root);

		delete comp.Root;
		comp.Root = null;

		delete comp.UIContext;
		comp.UIContext = null;
	}

	/// Collect dirty views for WorldUIPass to render during the pipeline phase.
	private void CollectDirtyViews(float deltaTime)
	{
		if (RenderPass == null) return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.IsVisible || !comp.IsDirty) continue;
			if (comp.Root == null) continue;
			if (comp.Texture == null || comp.TextureView == null) continue;

			RenderPass.DirtyViews.Add(comp);
			comp.IsDirty = false;
		}
	}

	public override void Dispose()
	{
		base.Dispose();

		if (mSharedVGRenderer != null)
		{
			mSharedVGRenderer.Dispose();
			delete mSharedVGRenderer;
			mSharedVGRenderer = null;
		}

		if (mSharedVG != null)
		{
			delete mSharedVG;
			mSharedVG = null;
		}
	}
}
