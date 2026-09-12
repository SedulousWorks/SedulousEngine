using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Shaders;

namespace Sedulous.Engine.Render;

/// The Context level renderer: it owns the frame, the renderer registry and the per scene
/// snapshots, and draws what extraction produced.
///
/// It renders rather than ticks, which is why it sorts LATE: everything that moves has
/// already moved by the time it runs.
class RenderSubsystem : Subsystem, ISceneObserver
{
	/// BORROWED: the owner outlives the subsystem.
	private IDevice mDevice;
	private uint32 mFramesInFlight;

	private ShaderSystemHost mShaderHost = new .() ~ delete _;
	/// BORROWED from the host above.
	private ShaderSystem mShaders = null;

	private RendererRegistry mRegistry = new .() ~ delete _;
	/// Per scene contributors, BORROWED, and cleared when their scene is destroyed.
	private List<SceneProvider> mProviders = new .() ~ delete _;

	private OverlayRegistry<ISceneOverlay> mSceneOverlays = new .() ~ delete _;
	private OverlayRegistry<IScreenOverlay> mScreenOverlays = new .() ~ delete _;

	private RenderFrame mFrame = null ~ delete _;

	public this(IDevice device, uint32 framesInFlight)
	{
		mDevice = device;
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;
	}

	/// Renders rather than ticks, so it runs after everything that moves has moved.
	public override int32 UpdateOrder => 1000;

	/// Ready once the frame exists. Everything below it is inert until then, which is what a
	/// machine with no shaders gets rather than a crash.
	public bool IsReady => mFrame != null;

	public IDevice Device => mDevice;
	public ShaderSystem Shaders => mShaders;
	public uint32 FramesInFlight => mFramesInFlight;

	// ---- extension seam --------------------------------------------------------------------

	/// Registers an external renderer, BORROWED, and hands back the dispatch id to stamp on
	/// its render data. The pipeline drives the whole registry per frame.
	public uint16 RegisterRenderer(Renderer renderer)
	{
		mRegistry.Register(renderer);
		return renderer.RendererId;
	}

	/// Registers a render data provider FOR a scene, BORROWED. It is invoked during that
	/// scene's extraction and dropped when the scene is destroyed.
	public void RegisterProvider(Scene scene, IRenderDataProvider provider)
	{
		mProviders.Add(SceneProvider(scene, provider));
	}

	// ---- frame -----------------------------------------------------------------------------

	/// The frame delta reaches the pipeline, where the auto exposure eases against it.
	public override void Update(float deltaTime)
	{
		if (mFrame != null)
			mFrame.SetDeltaSeconds(deltaTime);
	}

	/// Drops the providers registered for a scene that is going away, since they are borrowed
	/// and about to dangle.
	public void OnDestroying(Scene scene)
	{
		for (int i = mProviders.Count - 1; i >= 0; i--)
		{
			if (mProviders[i].Scene === scene)
				mProviders.RemoveAt(i);
		}
	}
}
