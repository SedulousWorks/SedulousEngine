using System;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Resource;

namespace Sedulous.Engine.UI;

/// Drawing the render texture canvases and the world panels into their own offscreen
/// targets, and the editor's preview seam.
extension UISubsystem
{
	/// sRGB, so what is STORED matches the swapchain path: the vector shader emits linear,
	/// the hardware encodes on write and decodes on sample, and a panel's sprite therefore
	/// feeds the scene the same linear values a heads up display feeds the window.
	///
	/// A world panel still tone maps WITH the scene afterwards, being in the world; that
	/// residual difference against the post tone map display is intended.
	private const TextureFormat cCanvasTextureFormat = .RGBA8UnormSrgb;

	/// The transparent border a panel's content is drawn inside.
	///
	/// The sprite quad's silhouette then falls in fully transparent texels, so the panel's
	/// outer edge is texture content smoothed by the sampler and the target's own
	/// multisampling, rather than the quad's geometric edge, which the scene pass cannot
	/// smooth. The quad inflates by the same border, so the on screen scale and the ray
	/// mapping against the authored size are both unchanged: a ray over the skirt misses
	/// the authored quad, and nothing lives there.
	private const uint32 cEdgePadding = 2;

	/// Draws every render texture canvas and world panel into its target.
	///
	/// The HOST calls this on its encoder BEFORE the scene renders, so a material sampling
	/// one of these textures sees THIS frame's interface. Targets are made and resized on
	/// demand, swept when their canvas goes away, and left readable.
	public void RenderCanvasTextures(ICommandEncoder encoder, int32 frameIndex)
	{
		if ((mRenderState == null) || (mRenderState.Device == null))
			return;

		// At most ONCE per UI frame. Several hosts can share one runtime context, and one
		// call already renders EVERY scene's canvases, so a repeat would draw the same
		// targets again onto the same encoder.
		if (mCanvasTexturesSerial == mFrameSerial)
			return;
		mCanvasTexturesSerial = mFrameSerial;

		for (let target in mRenderState.CanvasTargets)
			target.Seen = false;

		for (let sceneUI in mSceneUIs)
		{
			let sprites = sceneUI.Scene.GetSystem<SpriteComponentManager>();
			let decals = sceneUI.Scene.GetSystem<DecalComponentManager>();

			if (let canvases = sceneUI.Scene.GetSystem<UICanvasComponentManager>())
				RenderTextureCanvases(encoder, frameIndex, sceneUI, canvases, sprites, decals);

			if (let panels = sceneUI.Scene.GetSystem<UIWorldPanelComponentManager>())
				RenderWorldPanels(encoder, frameIndex, sceneUI, panels, sprites);
		}

		SweepCanvasTargets();
	}

	/// The declarative binding from a canvas to a material: the canvas ENTITY's own sprite
	/// or decal texture override tracks the canvas's CURRENT view, which changes on a
	/// resize.
	///
	/// Deliberately written from the UI side, using the SAME override a manual assignment
	/// would, so the render subsystem stays unaware of the UI: no new render fields and no
	/// inspector surface. Binding across entities stays manual.
	private static void BindEntityMaterials(SpriteComponentManager sprites,
		DecalComponentManager decals, EntityHandle entity, ITextureView oldView,
		ITextureView newView)
	{
		if (sprites != null)
		{
			if (let sprite = sprites.Get(entity))
			{
				if ((newView != null) || (sprite.Texture === oldView))
					sprite.Texture = newView;
			}
		}

		if (decals != null)
		{
			if (let decal = decals.Get(entity))
			{
				if ((newView != null) || (decal.Texture === oldView))
					decal.Texture = newView;
			}
		}
	}

	private void RenderTextureCanvases(ICommandEncoder encoder, int32 frameIndex,
		UISceneUI sceneUI, UICanvasComponentManager canvases, SpriteComponentManager sprites,
		DecalComponentManager decals)
	{
		canvases.ForEach(scope [&] (component, entity) =>
			{
				if (component.RenderMode != .RenderTexture)
					return;
				// No document instantiated.
				if (component.RenderRoot == null)
					return;

				let width = Math.Max(component.RenderTextureWidth, 1);
				let height = Math.Max(component.RenderTextureHeight, 1);
				let previousView = component.RenderTextureView;

				let target = mRenderState.EnsureCanvasTarget(sceneUI.Scene, entity, width, height,
					cCanvasTextureFormat);
				if (target == null)
				{
					component.RenderTexture = null;
					component.RenderTextureView = null;
					// Never leave a freed view bound.
					BindEntityMaterials(sprites, decals, entity, previousView, null);
					return;
				}

				target.Seen = true;
				component.RenderTexture = target.Texture;
				component.RenderTextureView = target.View;
				BindEntityMaterials(sprites, decals, entity, previousView, target.View);

				// Keep the texture, skip the draw.
				if (!component.Visible)
					return;

				DrawCanvasTarget(encoder, frameIndex, target, component.RenderRoot, 0, 0, width,
					height, target.DepthStencilView != null);
			});
	}

	/// The world tier: the same machinery, sized by PIXELS PER METRE, and the sibling sprite
	/// driven outright, because the panel IS the authoring surface and the sprite is only
	/// its vehicle into the scene.
	///
	/// ONE consumer per entity: a panel and a texture canvas on the same entity would
	/// collide on the target key, and the panel wins.
	private void RenderWorldPanels(ICommandEncoder encoder, int32 frameIndex, UISceneUI sceneUI,
		UIWorldPanelComponentManager panels, SpriteComponentManager sprites)
	{
		panels.ForEach(scope [&] (component, entity) =>
			{
				if (component.RenderRoot == null)
					return;

				let ppm = Math.Max(component.PixelsPerMeter, 1.0f);
				let width = Math.Clamp((uint32)(component.SizeMeters.X * ppm + 0.5f), 16, 2044);
				let height = Math.Clamp((uint32)(component.SizeMeters.Y * ppm + 0.5f), 16, 2044);
				let paddedWidth = width + 2 * cEdgePadding;
				let paddedHeight = height + 2 * cEdgePadding;

				let target = mRenderState.EnsureCanvasTarget(sceneUI.Scene, entity, paddedWidth,
					paddedHeight, cCanvasTextureFormat);
				if (target == null)
				{
					component.RenderTexture = null;
					component.RenderTextureView = null;
					return;
				}

				target.Seen = true;
				component.RenderTexture = target.Texture;
				component.RenderTextureView = target.View;

				// The panel's quad in the world, added if it is not already there.
				if (sprites != null)
				{
					var sprite = sprites.Get(entity);
					if (sprite == null)
						sprite = sprites.Add(entity);

					sprite.Orientation = .EntityOriented;
					// Inflated by the transparent border, so the CONTENT keeps the size it
					// was authored at: the texture maps across the whole quad.
					sprite.Size = .(
						component.SizeMeters.X * ((float)paddedWidth / (float)width),
						component.SizeMeters.Y * ((float)paddedHeight / (float)height));
					sprite.Texture = target.View;
					sprite.Visible = component.Visible
						&& sceneUI.Scene.IsEffectivelyActive(entity);
					// After the tone map, so the panel keeps its AUTHORED colours, matching
					// the screen tier, while still depth testing into the scene.
					sprite.PostTonemap = true;
				}

				// Keep the texture, skip the draw.
				if (!component.Visible || !sceneUI.Scene.IsEffectivelyActive(entity))
					return;

				DrawCanvasTarget(encoder, frameIndex, target, component.RenderRoot,
					(int32)cEdgePadding, (int32)cEdgePadding, width, height, false);
			});
	}

	/// Opens the target's own pass, records the root into it, and leaves the texture
	/// readable.
	private void DrawCanvasTarget(ICommandEncoder encoder, int32 frameIndex, UICanvasTarget target,
		RootView root, int32 viewportX, int32 viewportY, uint32 width, uint32 height,
		bool withStencil)
	{
		encoder.TransitionTexture(target.Texture, target.State, .RenderTarget);

		let multisampled = target.MsaaView != null;
		if (multisampled && (target.MsaaState == .Undefined))
		{
			encoder.TransitionTexture(target.Msaa, .Undefined, .RenderTarget);
			target.MsaaState = .RenderTarget;
		}

		var color = ColorAttachment();
		// Rendered into the multisampled target and resolved into the sampled one, whose
		// samples die with the pass.
		color.View = multisampled ? target.MsaaView : target.View;
		color.ResolveTarget = multisampled ? target.View : null;
		// A fresh transparent background every frame.
		color.LoadOp = .Clear;
		color.StoreOp = multisampled ? .DontCare : .Store;
		color.ClearValue = .(0.0f, 0.0f, 0.0f, 0.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(color);

		if (withStencil)
		{
			encoder.TransitionTexture(target.DepthStencil, .Undefined, .DepthStencilWrite);

			var depthStencil = DepthStencilAttachment();
			depthStencil.View = target.DepthStencilView;
			depthStencil.DepthLoadOp = .Clear;
			depthStencil.DepthStoreOp = .DontCare;
			// Stencil then cover expects to start from nothing.
			depthStencil.StencilLoadOp = .Clear;
			depthStencil.StencilStoreOp = .DontCare;
			depthStencil.StencilClearValue = 0;
			passDesc.DepthStencilAttachment = depthStencil;
		}

		if (let pass = encoder.BeginRenderPass(passDesc))
		{
			DrawRootInPass(root, pass, cCanvasTextureFormat, viewportX, viewportY, width, height,
				frameIndex, withStencil, target.SampleCount);
			pass.End();
		}

		encoder.TransitionTexture(target.Texture, .RenderTarget, .ShaderRead);
		target.State = .ShaderRead;
	}

	/// Sweeps the targets whose canvas has gone, and unbinds any override still pointing at
	/// the dying view, but only while the scene itself is alive: a destroyed scene took its
	/// components with it.
	private void SweepCanvasTargets()
	{
		for (int i = mRenderState.CanvasTargets.Count - 1; i >= 0; i--)
		{
			let target = mRenderState.CanvasTargets[i];
			if (target.Seen)
				continue;

			// Compared by identity ONLY: the scene may already be freed.
			var sceneAlive = false;
			for (let ui in mSceneUIs)
			{
				if (ui.Scene === target.Scene)
				{
					sceneAlive = true;
					break;
				}
			}

			if ((target.View != null) && sceneAlive)
			{
				if (let sprites = target.Scene.GetSystem<SpriteComponentManager>())
				{
					if (let sprite = sprites.Get(target.Entity))
					{
						if (sprite.Texture === target.View)
							sprite.Texture = null;
					}
				}

				if (let decals = target.Scene.GetSystem<DecalComponentManager>())
				{
					if (let decal = decals.Get(target.Entity))
					{
						if (decal.Texture === target.View)
							decal.Texture = null;
					}
				}
			}

			mRenderState.DestroyCanvasTarget(i);
		}
	}

	/// The offscreen view of an entity's render texture canvas, or null when there is none,
	/// it is not in that mode, or it has not rendered yet. Mirrored on the component too.
	public ITextureView CanvasRenderTextureView(Scene scene, EntityHandle entity)
	{
		let canvases = scene.GetSystem<UICanvasComponentManager>();
		let component = (canvases != null) ? canvases.Get(entity) : null;
		return (component != null) ? component.RenderTextureView : null;
	}

	// ==================== the editor preview seam ====================
	// A preview renders through THIS context, so it gets the game's fonts, theme, style
	// resolution and vector path, into a DEDICATED root that is never attached to the screen
	// root or a scene's. It therefore cannot leak into a game target, and it receives no
	// input, the active root staying where it was.

	/// Instantiates a document into a fresh preview root. Null when the markup fails.
	public RootView CreatePreview(UIDocument document)
	{
		if (document.Markup.IsEmpty)
			return null;

		let tree = MarkupLoader.LoadFromString(document.Markup, mContext);
		if (tree == null)
			return null;

		let root = new RootView();
		root.AddView(tree);
		// Registered on the GAME context, where the styles, fonts and identifiers resolve,
		// but NEVER on the screen root or a scene's: the overlay roles draw only those.
		mContext.AddRootView(root);
		return root;
	}

	public void DestroyPreview(RootView root)
	{
		if (root != null)
			mContext.RemoveRootView(root);
	}

	/// Draws a preview root into a target through a pass of its own on the caller's encoder.
	/// The target arrives as a render target and is left that way.
	public void RenderPreview(RootView root, ICommandEncoder encoder, ITextureView target,
		TextureFormat format, uint32 width, uint32 height, int32 frameIndex)
	{
		if ((target == null) || (width == 0) || (height == 0))
			return;
		if ((mRenderState == null) || (mRenderState.Device == null))
			return;

		DrawRootInto(root, encoder, target, format, width, height, frameIndex);
	}

	/// The pass owning draw: opens a LOAD op pass on the caller's encoder and records
	/// through the shared path.
	private void DrawRootInto(RootView root, ICommandEncoder encoder, ITextureView target,
		TextureFormat format, uint32 width, uint32 height, int32 frameIndex)
	{
		var color = ColorAttachment();
		color.View = target;
		color.LoadOp = .Load;
		color.StoreOp = .Store;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(color);

		if (let pass = encoder.BeginRenderPass(passDesc))
		{
			DrawRootInPass(root, pass, format, 0, 0, width, height, frameIndex);
			pass.End();
		}
	}
}
