using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// The GUI's GPU side: the VG shaders from the data mount, the pass renderer that draws both
/// tiers, what PrepareOverlay recorded for the screen tier and for which view, and the textures
/// canvases and world panels draw into.
class GuiRenderState
{
	/// sRGB, as the window's: the shaders write linear light, the texture encodes it, the scene
	/// samples linear light back.
	public const TextureFormat cTextureFormat = .RGBA8UnormSrgb;

	/// BORROWED: whoever owns graphics outlives the subsystem's render state.
	public IDevice Device = null;
	/// Owns the shader modules the renderer draws with: it goes after the renderer.
	public VgShaderLibrary Shaders = new .();
	/// Null when the shaders did not resolve.
	public GuiPassRenderer Renderer = null;
	/// What PrepareOverlay recorded: the shared tier, and the drawn run's under it.
	public GuiPassRenderer.Prepared Screen = .();
	public GuiPassRenderer.Prepared RunScreen = .();
	public bool HasRunScreen = false;
	public ScreenOverlayView ScreenView = .();
	public bool ScreenPrepared = false;
	/// The textures canvases and world panels draw into, one per texture root.
	public List<GuiTextureTarget> Targets = new .() ~ DeleteContainerAndItems!(_);

	public ~this()
	{
		// The textures first (the GPU waited for: the scene may still sample them), then the
		// renderer (it waits for the GPU and lets its renderers go), then the modules it drew
		// with. No early return: the fields' own cleanups would be skipped.
		if ((Device != null) && !Targets.IsEmpty)
		{
			Device.WaitIdle();
			for (let target in Targets)
				Release(target);
		}
		delete Renderer;
		delete Shaders;
	}

	/// `target`'s GPU objects let go; it stays, to be made again or deleted.
	public void Release(GuiTextureTarget target)
	{
		target.Pass.Destroy();
		if (target.View != null)
			Device.DestroyTextureView(ref target.View);
		if (target.Texture != null)
			Device.DestroyTexture(ref target.Texture);
		target.View = null;
		target.Texture = null;
	}

	/// `root`'s texture at `width` x `height`, made or made again at that size (the GPU waited
	/// for: the scene may still sample the old one); null when the device makes none.
	public GuiTextureTarget EnsureTarget(SceneRoot root, Scene scene, EntityHandle entity, uint32 width, uint32 height)
	{
		GuiTextureTarget found = null;
		for (let target in Targets)
		{
			if (target.Root === root)
				found = target;
		}
		if (found == null)
		{
			found = new GuiTextureTarget();
			found.Root = root;
			found.Scene = scene;
			found.Entity = entity;
			Targets.Add(found);
		}
		found.Seen = true;
		if ((found.Texture != null) && (found.Width == width) && (found.Height == height))
			return found;
		if (found.Texture != null)
		{
			Device.WaitIdle();
			Release(found);
		}
		if (!(Device.CreateTexture(TextureDesc.RenderTarget(cTextureFormat, width, height, 1, "GUI texture")) case .Ok(let texture)))
		{
			found.Texture = null;
			return null;
		}
		found.Texture = texture;
		var viewDesc = TextureViewDesc();
		viewDesc.Format = cTextureFormat;
		if (!(Device.CreateTextureView(found.Texture, viewDesc) case .Ok(let view)))
		{
			Device.DestroyTexture(ref found.Texture);
			found.Texture = null;
			found.View = null;
			return null;
		}
		found.View = view;
		found.Pass.Configure(Device);
		found.Multisampled = found.Pass.Create(cTextureFormat, width, height);
		found.Width = width;
		found.Height = height;
		found.State = .Undefined;
		return found;
	}
}
