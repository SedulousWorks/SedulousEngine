using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.Shaders;
using Sedulous.Fonts;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.Engine.UI;

/// Everything the UI subsystem needs a GPU for: the shaders, a vector renderer per target
/// configuration, and the offscreen targets the render texture canvases draw into.
///
/// Held apart from the subsystem because it only exists once somebody has brought graphics
/// up, and a headless consumer never does.
class UIRenderState
{
	/// The multisampling a canvas's offscreen target uses. Four is universally available for
	/// eight bit colour, so this is a safe default rather than a negotiated one.
	private const uint32 cCanvasMsaaSamples = 4;

	/// OWNED: the shader system and the vector modules under it.
	public ShaderSystemHost ShaderHost = new .() ~ delete _;
	/// BORROWED: the device whoever owns graphics brought up.
	public IDevice Device = null;

	// BORROWED from the shader host, which owns them and frees them with itself.
	public IShaderModule VertexShader = null;
	public IShaderModule FragmentShader = null;
	public IShaderModule DistanceFieldShader = null;
	public IShaderModule GradRadialShader = null;
	public IShaderModule GradConicShader = null;
	public IShaderModule BoxShadowShader = null;

	public VGContext Context = null ~ delete _;

	private List<UIFormatRenderer> mRenderers = new .() ~ DeleteContainerAndItems!(_);
	private List<UICanvasTarget> mCanvasTargets = new .() ~ DeleteContainerAndItems!(_);

	public int32 FrameCount = 2;

	/// Probed once when graphics come up. Undefined means the device offers no stencil
	/// format at all, and the fills fall back to tessellation.
	public TextureFormat CanvasStencilFormat = .Undefined;

	public List<UICanvasTarget> CanvasTargets => mCanvasTargets;

	public this(IFontService fonts)
	{
		Context = new VGContext(fonts);
	}

	public ~this()
	{
		if (!mCanvasTargets.IsEmpty && (Device != null))
			Device.WaitIdle();

		for (int i = mCanvasTargets.Count - 1; i >= 0; i--)
			DestroyCanvasTarget(i, false);
	}

	/// The renderer for a target configuration, made on first sight.
	///
	/// Its per frame rings are rewound EXACTLY once per UI frame. Rewinding before every
	/// draw would clobber the slices recorded earlier in the same frame, and the scene
	/// overlay, the screen overlay and any preview all share one renderer per configuration.
	public VGRenderer RendererFor(TextureFormat format, uint64 frameSerial, int32 frameIndex,
		bool stencil = false, uint32 sampleCount = 1)
	{
		UIFormatRenderer found = null;
		for (let entry in mRenderers)
		{
			if ((entry.Format == format) && (entry.Stencil == stencil)
				&& (entry.SampleCount == sampleCount))
			{
				found = entry;
				break;
			}
		}

		if (found == null)
		{
			if ((VertexShader == null) || (FragmentShader == null))
				return null;

			var targetConfig = VGTargetConfig();
			targetConfig.SampleCount = sampleCount;
			if (stencil)
				targetConfig.DepthStencilFormat = CanvasStencilFormat;

			let renderer = new VGRenderer();
			if (renderer.Initialize(Device, VertexShader, FragmentShader, format, FrameCount,
				DistanceFieldShader, GradRadialShader, GradConicShader, targetConfig,
				BoxShadowShader) case .Err)
			{
				delete renderer;
				return null;
			}

			found = new UIFormatRenderer();
			found.Format = format;
			found.Stencil = stencil;
			found.SampleCount = sampleCount;
			found.Renderer = renderer;
			mRenderers.Add(found);
		}

		if (found.BegunSerial != frameSerial)
		{
			found.Renderer.BeginFrame(frameIndex);
			found.BegunSerial = frameSerial;
		}

		return found.Renderer;
	}

	/// The offscreen target for one render texture canvas, made on demand and rebuilt on a
	/// resize. Null only when the texture could not be created.
	public UICanvasTarget EnsureCanvasTarget(Scene scene, EntityHandle entity, uint32 width,
		uint32 height, TextureFormat format)
	{
		UICanvasTarget found = null;
		for (let target in mCanvasTargets)
		{
			if ((target.Scene === scene) && (target.Entity == entity))
			{
				found = target;
				break;
			}
		}

		if ((found != null) && ((found.Width != width) || (found.Height != height)))
		{
			// A resize: the scene may still be sampling the old target, so the device is
			// idled before any of it is freed. Resizes are author driven and rare.
			Device.WaitIdle();
			ReleaseTargetTextures(found);
		}

		if (found == null)
		{
			found = new UICanvasTarget();
			found.Scene = scene;
			found.Entity = entity;
			mCanvasTargets.Add(found);
		}

		if (found.Texture == null)
		{
			let desc = TextureDesc.RenderTarget(format, width, height, 1, "UICanvasTexture");
			if (!(Device.CreateTexture(desc) case .Ok(let texture)))
				return null;
			found.Texture = texture;

			var viewDesc = TextureViewDesc();
			viewDesc.Format = format;
			if (!(Device.CreateTextureView(found.Texture, viewDesc) case .Ok(let view)))
			{
				Device.DestroyTexture(ref found.Texture);
				found.Texture = null;
				return null;
			}
			found.View = view;

			// The multisampled colour: rendered into at four samples and resolved into the
			// sampled texture. BEST EFFORT, because any failure simply means rendering
			// single sampled straight into it, which is worse looking rather than broken.
			found.SampleCount = 1;
			found.MsaaState = .Undefined;
			{
				var msaaDesc = TextureDesc.RenderTarget(format, width, height,
					cCanvasMsaaSamples, "UICanvasMsaa");
				// Never sampled: only resolved from.
				msaaDesc.Usage = .RenderTarget;

				if (Device.CreateTexture(msaaDesc) case .Ok(let msaa))
				{
					found.Msaa = msaa;
					if (Device.CreateTextureView(found.Msaa, .()) case .Ok(let msaaView))
					{
						found.MsaaView = msaaView;
						found.SampleCount = cCanvasMsaaSamples;
					}
					else
					{
						Device.DestroyTexture(ref found.Msaa);
						found.Msaa = null;
						found.MsaaView = null;
					}
				}
			}

			// The stencil twin, at the same size AND sample count as the pass's colour
			// attachment, since a pass's attachments have to agree.
			if (CanvasStencilFormat != .Undefined)
			{
				var stencilDesc = TextureDesc();
				stencilDesc.Dimension = .Texture2D;
				stencilDesc.Format = CanvasStencilFormat;
				stencilDesc.Width = width;
				stencilDesc.Height = height;
				stencilDesc.Depth = 1;
				stencilDesc.Usage = .DepthStencil;
				stencilDesc.SampleCount = found.SampleCount;
				stencilDesc.Label = "UICanvasStencil";

				if (Device.CreateTexture(stencilDesc) case .Ok(let depthStencil))
				{
					found.DepthStencil = depthStencil;
					if (Device.CreateTextureView(found.DepthStencil, .())
						case .Ok(let depthStencilView))
					{
						found.DepthStencilView = depthStencilView;
					}
					else
					{
						Device.DestroyTexture(ref found.DepthStencil);
						found.DepthStencil = null;
						found.DepthStencilView = null;
					}
				}
			}

			found.Width = width;
			found.Height = height;
			found.State = .Undefined;
		}

		return found;
	}

	public void DestroyCanvasTarget(int index, bool waitIdle = true)
	{
		let target = mCanvasTargets[index];

		if (Device != null)
		{
			// The scene may still be sampling it.
			if (waitIdle && ((target.Texture != null) || (target.View != null)))
				Device.WaitIdle();

			ReleaseTargetTextures(target);
		}

		mCanvasTargets.RemoveAt(index);
		delete target;
	}

	private void ReleaseTargetTextures(UICanvasTarget target)
	{
		if (target.View != null)
			Device.DestroyTextureView(ref target.View);
		if (target.Texture != null)
			Device.DestroyTexture(ref target.Texture);
		if (target.DepthStencilView != null)
			Device.DestroyTextureView(ref target.DepthStencilView);
		if (target.DepthStencil != null)
			Device.DestroyTexture(ref target.DepthStencil);
		if (target.MsaaView != null)
			Device.DestroyTextureView(ref target.MsaaView);
		if (target.Msaa != null)
			Device.DestroyTexture(ref target.Msaa);

		target.Texture = null;
		target.View = null;
		target.DepthStencil = null;
		target.DepthStencilView = null;
		target.Msaa = null;
		target.MsaaView = null;
		target.SampleCount = 1;
		target.MsaaState = .Undefined;
	}
}
