namespace Sedulous.Editor;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Shell.Input;
using Sedulous.UI.Viewport;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Renderer;
using Sedulous.Renderer.Passes;

/// Composable host for a single-resource preview viewport.
///
/// Owns a private scene (created via SceneSubsystem so all ISceneAware subsystems
/// install their per-scene modules + Pipeline), a ViewportView, an EditorCamera,
/// and a default directional light. Resource pages compose this as a member and
/// spawn whatever entity represents their resource into PreviewScene.
///
/// Each frame OnRender drives the editor's ISceneRenderer against this scene.
/// Hidden viewports are skipped by RenderActiveViewports, so background tabs
/// spend no GPU.
public class PreviewSceneHost
{
	/// Hook fired each frame before RenderScene is invoked. Subclasses can
	/// inject debug-draw geometry into the per-scene Pipeline.DebugDraw here.
	public delegate void PreRenderDelegate(PreviewSceneHost host, ICommandEncoder encoder, int32 frameIndex);

	private SceneSubsystem mSceneSubsystem;
	private ISceneRenderer mSceneRenderer;
	private Scene mScene;
	private EditorCamera mCamera ~ delete _;
	private ViewportView mViewport; // Ownership transfers to the caller's view tree.
	private ViewportCameraController mCameraController ~ delete _;
	private EntityHandle mKeyLight;

	public Scene PreviewScene => mScene;
	public ViewportView Viewport => mViewport;
	public EditorCamera Camera => mCamera;
	public ViewportCameraController CameraController => mCameraController;
	public ISceneRenderer SceneRenderer => mSceneRenderer;

	/// Fires before each RenderScene call so subclasses can queue debug-draw.
	public Event<PreRenderDelegate> OnPreRender ~ _.Dispose();

	public this(IDevice device, VGRenderer vgRenderer, IKeyboard keyboard,
		SceneSubsystem sceneSubsystem, ISceneRenderer sceneRenderer, StringView sceneName)
	{
		mSceneSubsystem = sceneSubsystem;
		mSceneRenderer = sceneRenderer;

		// CreateScene fires ISceneAware.OnSceneCreated on every subsystem, so
		// MeshComponentManager / LightComponentManager / ParticleComponentManager
		// and the per-scene render Pipeline are installed automatically.
		mScene = sceneSubsystem.CreateScene(scope String(sceneName));
		mScene.SimulationEnabled = true;

		mViewport = new ViewportView();
		mViewport.Initialize(device, vgRenderer);

		mCamera = new EditorCamera();
		mCameraController = new ViewportCameraController(mCamera, keyboard);
		mViewport.AddInputHandler(mCameraController);

		SetupDefaultLight();

		let capturedScene = mScene;
		let capturedRenderer = sceneRenderer;
		let capturedCamera = mCamera;
		let capturedController = mCameraController;

		let capturedHost = this;
		mViewport.OnRender.Add(new (vp, encoder, frameIndex) =>
		{
			if (!vp.IsReady) return;

			// Drive WASD fly while RMB held.
			capturedController.Update(1.0f / 60.0f);

			// Subclasses get a chance to queue debug-draw before RenderScene runs.
			capturedHost.OnPreRender(capturedHost, encoder, frameIndex);

			encoder.TransitionTexture(vp.ColorTexture, .Undefined, .RenderTarget);

			if (capturedRenderer == null)
			{
				// No scene renderer available - just clear so the viewport isn't garbage.
				ColorAttachment[1] colorAttachments = .(.()
				{
					View = vp.ColorTargetView,
					LoadOp = .Clear,
					StoreOp = .Store,
					ClearValue = .(0.15f, 0.15f, 0.18f, 1)
				});
				RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
				let pass = encoder.BeginRenderPass(passDesc);
				pass?.End();
				encoder.TransitionTexture(vp.ColorTexture, .RenderTarget, .ShaderRead);
				return;
			}

			// Clear pass first so RenderScene's LoadOp.Load picks up our clear color.
			ColorAttachment[1] clearAttachments = .(.()
			{
				View = vp.ColorTargetView,
				LoadOp = .Clear,
				StoreOp = .Store,
				ClearValue = .(0, 0, 0, 1)
			});
			RenderPassDesc clearDesc = .() { ColorAttachments = .(clearAttachments) };
			let clearPass = encoder.BeginRenderPass(clearDesc);
			clearPass?.End();

			let aspect = (vp.RenderHeight > 0) ? (float)vp.RenderWidth / (float)vp.RenderHeight : 1.0f;
			let cameraOverride = capturedCamera.GetCameraOverride(aspect);

			capturedRenderer.RenderScene(capturedScene, encoder, vp.ColorTexture, vp.ColorTargetView,
				vp.RenderWidth, vp.RenderHeight, frameIndex, cameraOverride);
		});
	}

	/// Frames the camera so the given bounds fill the view, then a bit more headroom.
	public void FitToBounds(BoundingBox bounds)
	{
		let center = (bounds.Min + bounds.Max) * 0.5f;
		let halfExtents = (bounds.Max - bounds.Min) * 0.5f;
		let radius = Math.Max(halfExtents.Length(), 0.1f);
		let distance = radius * 2.5f;

		mCamera.Target = center;
		mCamera.Distance = Math.Clamp(distance, mCamera.MinDistance, mCamera.MaxDistance);
		mCamera.FarPlane = Math.Max(mCamera.FarPlane, distance * 4.0f);
	}

	private void SetupDefaultLight()
	{
		// Key directional light - rotated to a typical 3/4 angle so meshes get
		// readable shading instead of rendering pitch-black.
		mKeyLight = mScene.CreateEntity("PreviewKeyLight");
		mScene.SetLocalTransform(mKeyLight, Transform.CreateLookAt(.(8, 12, 6), .Zero));

		let lightMgr = mScene.GetModule<LightComponentManager>();
		if (lightMgr != null)
		{
			let handle = lightMgr.CreateComponent(mKeyLight);
			if (let light = lightMgr.Get(handle))
			{
				light.Type = .Directional;
				light.Color = .(1, 1, 1);
				light.Intensity = 1.5f;
			}
		}
	}

	public void Dispose()
	{
		// DestroyScene is deferred (handled in SceneSubsystem.Update); the actual
		// per-scene Pipeline teardown lands next frame. The page is gone from
		// OpenPages by then so no orphan render is queued. ~ViewportView WaitIdles
		// before freeing textures, so destroying the viewport synchronously is safe.
		if (mScene != null && mSceneSubsystem != null)
		{
			mSceneSubsystem.DestroyScene(mScene);
			mScene = null;
		}
	}

	public ~this()
	{
		Dispose();
	}
}
