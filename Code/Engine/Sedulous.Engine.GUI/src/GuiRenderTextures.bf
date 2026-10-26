using System;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.GUI;
using Sedulous.RHI;
using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// The textures: a canvas in RenderTexture mode and a world panel each draw into a texture of
/// their own once a frame, before the scene, after the frame's bakes; their entity's sprite (or
/// decal) shows it, and a world panel drives its entity's sprite outright.
extension GuiSubsystem
{
	/// The transparent edge a world panel's texture keeps on each side: the quad's own edge
	/// falls in clear texels, smoothed by sampling, and the quad grows by the same share so the
	/// content keeps its authored size.
	private const uint32 cPanelEdge = 2;

	/// How many textures canvases and panels draw into now.
	public int TextureCount => (mRenderState != null) ? mRenderState.Targets.Count : 0;

	/// The textures: the frame's bakes, then every render-texture canvas and world panel drawn
	/// into its texture, made or resized as it asks and left ready to sample; their entities'
	/// sprites (and a canvas's decal) shown them. By the host on its encoder before the scene
	/// draws, so the scene samples this frame's. Once a frame: a second call does nothing.
	public void RenderTextures(ICommandEncoder encoder, uint32 frameIndex)
	{
		if (!IsRenderReady || (mTexturesSerial == mFrameSerial))
			return;
		mTexturesSerial = mFrameSerial; // several pages of an editor share one GUI: once a frame
		let renderer = mRenderState.Renderer;
		renderer.RecordBakes(encoder, frameIndex); // before any pass samples them
		for (let target in mRenderState.Targets)
			target.Seen = false;
		for (let tier in mSceneTiers)
		{
			let sprites = tier.Scene.GetSystem<SpriteComponentManager>();
			let decals = tier.Scene.GetSystem<DecalComponentManager>();
			if (let canvases = tier.Scene.GetSystem<GuiCanvasComponentManager>())
			{
				canvases.ForEach(scope [&] (c, entity) =>
					{
						if ((c.RenderMode != .RenderTexture) || (c.RenderRoot == null))
							return;
						let was = c.RenderTextureView;
						let target = mRenderState.EnsureTarget(c.RenderRoot, tier.Scene, entity, Math.Max(c.RenderTextureWidth, 1),
							Math.Max(c.RenderTextureHeight, 1));
						c.RenderTexture = (target != null) ? target.Texture : null;
						c.RenderTextureView = (target != null) ? target.View : null;
						ShowTexture(sprites, decals, entity, was, c.RenderTextureView);
						if ((target == null) || !c.Visible || !tier.Scene.IsEffectivelyActive(entity))
							return; // the texture kept, not drawn
						StyleAndLayOut(c.RenderRoot, .((float)target.Width, (float)target.Height));
						DrawTexture(renderer, encoder, target, c.RenderRoot, 0, frameIndex);
					});
			}
			// A world panel's sprite is driven outright: the quad in its entity's plane, a little
			// larger than the panel for the transparent edge its texture keeps, drawn after the
			// tone mapping so the panel keeps its authored colours, as the screen's GUI does.
			if (let panels = tier.Scene.GetSystem<GuiWorldPanelComponentManager>())
			{
				panels.ForEach(scope [&] (c, entity) =>
					{
						if (c.RenderRoot == null)
							return;
						let pixels = GuiWorldMath.WorldPanelPixels(*c);
						let width = (uint32)pixels.X + 2 * cPanelEdge;
						let height = (uint32)pixels.Y + 2 * cPanelEdge;
						let target = mRenderState.EnsureTarget(c.RenderRoot, tier.Scene, entity, width, height);
						c.RenderTexture = (target != null) ? target.Texture : null;
						c.RenderTextureView = (target != null) ? target.View : null;
						let shown = c.Visible && tier.Scene.IsEffectivelyActive(entity);
						if (sprites != null)
						{
							var sprite = sprites.Get(entity);
							if (sprite == null)
								sprite = sprites.Add(entity);
							sprite.Orientation = .EntityOriented;
							sprite.Size = .(c.SizeMeters.X * (float)width / pixels.X, c.SizeMeters.Y * (float)height / pixels.Y);
							sprite.Texture = c.RenderTextureView;
							sprite.Visible = shown && (target != null);
							sprite.PostTonemap = true;
						}
						if ((target == null) || !shown)
							return;
						StyleAndLayOut(c.RenderRoot, pixels);
						DrawTexture(renderer, encoder, target, c.RenderRoot, cPanelEdge, frameIndex);
					});
			}
		}
		// The textures whose canvas or panel went: a sprite or decal of a scene still here that
		// shows one lets it go, then it goes (the GPU waited for).
		for (int i = mRenderState.Targets.Count - 1; i >= 0; i--)
		{
			let target = mRenderState.Targets[i];
			if (target.Seen)
				continue;
			bool sceneHere = false;
			for (let tier in mSceneTiers)
				sceneHere = sceneHere || (tier.Scene === target.Scene);
			if (sceneHere && (target.View != null))
			{
				if (let sprites = target.Scene.GetSystem<SpriteComponentManager>())
				{
					let sprite = sprites.Get(target.Entity);
					if ((sprite != null) && (sprite.Texture === target.View))
						sprite.Texture = null;
				}
				if (let decals = target.Scene.GetSystem<DecalComponentManager>())
				{
					let decal = decals.Get(target.Entity);
					if ((decal != null) && (decal.Texture === target.View))
						decal.Texture = null;
				}
			}
			mRenderState.Device.WaitIdle();
			mRenderState.Release(target);
			mRenderState.Targets.RemoveAt(i);
			delete target;
		}
	}

	/// A render-texture canvas's entity's own sprite and decal shown its texture (the same
	/// override a script would set); one that showed the old one lets it go.
	private static void ShowTexture(SpriteComponentManager sprites, DecalComponentManager decals, EntityHandle entity,
		ITextureView was, ITextureView now)
	{
		if (sprites != null)
		{
			let sprite = sprites.Get(entity);
			if ((sprite != null) && ((now != null) || (sprite.Texture === was)))
				sprite.Texture = now;
		}
		if (decals != null)
		{
			let decal = decals.Get(entity);
			if ((decal != null) && ((now != null) || (decal.Texture === was)))
				decal.Texture = now;
		}
	}

	/// A texture's content drawn into it: laid out at its size already (inset by `padding` on
	/// each side, left clear), offscreen layers first, then its pass, the texture left ready to
	/// sample.
	private static void DrawTexture(GuiPassRenderer renderer, ICommandEncoder encoder, GuiTextureTarget target, SceneRoot root,
		uint32 padding, uint32 frameIndex)
	{
		var view = GuiPassView();
		view.X = (int32)padding;
		view.Y = (int32)padding;
		view.Width = target.Width - 2 * padding;
		view.Height = target.Height - 2 * padding;
		view.Format = GuiRenderState.cTextureFormat;
		if (target.Multisampled)
		{
			let config = target.Pass.ConfigFor();
			view.SampleCount = config.SampleCount;
			view.DepthStencilFormat = config.DepthStencilFormat;
		}
		view.FrameIndex = frameIndex;
		let prepared = renderer.Prepare(root, view, encoder);
		encoder.TransitionTexture(target.Texture, target.State, .RenderTarget);
		let clear = ClearColor(0.0f, 0.0f, 0.0f, 0.0f);
		var pass = RenderPassDesc();
		if (target.Multisampled)
			pass = target.Pass.BeginPass(encoder, target.View, clear, "GUI texture");
		else
		{
			var color = ColorAttachment();
			color.View = target.View;
			color.LoadOp = .Clear;
			color.StoreOp = .Store;
			color.ClearValue = clear;
			pass.ColorAttachments.Add(color);
		}
		if (let passEncoder = encoder.BeginRenderPass(pass))
		{
			renderer.Draw(passEncoder, prepared);
			passEncoder.End();
		}
		encoder.TransitionTexture(target.Texture, .RenderTarget, .ShaderRead);
		target.State = .ShaderRead;
	}
}
