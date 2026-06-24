namespace Sedulous.Editor;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Viewport;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.RHI;
using Sedulous.VG.Renderer;

/// Picture-in-picture preview of a CameraComponent selected in the scene
/// hierarchy. The panel anchors in the viewport corner; when pinned it
/// keeps showing its current camera even after the selection changes,
/// otherwise it tracks selection (camera-component entities only) and
/// hides when nothing relevant is selected.
///
/// Renders through a secondary Pipeline acquired from ISceneRenderer keyed
/// on `this`, so it has its own SceneDepth and pass state and doesn't
/// thrash the main viewport's pipeline when their RT sizes differ.
class CameraPreviewPanel : Panel
{
	private IDevice mDevice;
	private VGRenderer mVGRenderer;
	private ISceneRenderer mSceneRenderer;
	private Scene mScene;

	private Label mTitleLabel;
	private ToggleButton mPinBtn;
	private ViewportView mViewport;

	private EntityHandle mCameraEntity = .Invalid;
	private CameraComponent mCamera;

	public Event<delegate void()> OnRequestClose ~ _.Dispose();

	public bool Pinned => mPinBtn != null ? mPinBtn.IsChecked.Value : false;
	public EntityHandle CameraEntity => mCameraEntity;

	/// Stable, per-panel viewport key for ISceneRenderer.AcquirePipeline.
	private void* PipelineKey => Internal.UnsafeCastToPtr(this);

	public this(IDevice device, VGRenderer vgRenderer, ISceneRenderer sceneRenderer, Scene scene)
	{
		mDevice = device;
		mVGRenderer = vgRenderer;
		mSceneRenderer = sceneRenderer;
		mScene = scene;

		SetStyle(.Background, new ColorDrawable(.(20, 22, 28, 235)));

		// Bring up a dedicated Pipeline for this preview so the per-scene
		// SceneDepth and per-pipeline pass state stay independent of the
		// main viewport's RT dimensions.
		if (mSceneRenderer != null)
			mSceneRenderer.AcquirePipeline(mScene, PipelineKey);

		Build();
		Visibility = .Gone;
	}

	public ~this()
	{
		if (mSceneRenderer != null)
			mSceneRenderer.ReleasePipeline(mScene, PipelineKey);
	}

	private void Build()
	{
		let root = new FlexLayout();
		root.Direction = .Vertical;
		this.AddView(root);

		// Header strip - dark Panel background with an inner FlexLayout for
		// title + Pin toggle + Close button.
		let headerBg = new Panel();
		headerBg.SetStyle(.Background, new ColorDrawable(.(35, 38, 48, 255)));
		root.AddView(headerBg, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(24))
		});

		let header = new FlexLayout();
		header.Direction = .Horizontal;
		header.Spacing = 4;
		header.Padding = .(6, 2, 4, 2);
		headerBg.AddView(header);

		mTitleLabel = new Label();
		mTitleLabel.SetText("Camera");
		mTitleLabel.FontSize.Value = 11;
		mTitleLabel.VAlign.Value = .Middle;
		mTitleLabel.TextColor.Value = .(220, 220, 230, 255);
		header.AddView(mTitleLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		mPinBtn = new ToggleButton("Pin");
		mPinBtn.OnCheckedChanged.Add(new (btn, val) => { UpdateTitle(); });
		header.AddView(mPinBtn, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(40)), Height = .Fixed(.Px(20))
		});

		let closeBtn = new Button("X");
		closeBtn.OnClick.Add(new (btn) => { OnRequestClose(); });
		header.AddView(closeBtn, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(20)), Height = .Fixed(.Px(20))
		});

		// Body: a small ViewportView that renders the scene from the selected
		// camera, into its own color/depth RTs.
		mViewport = new ViewportView();
		mViewport.Initialize(mDevice, mVGRenderer);
		mViewport.OnRender.Add(new (vp, encoder, frameIndex) => { RenderPreview(vp, encoder, frameIndex); });
		root.AddView(mViewport, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });
	}

	/// Bind the panel to a camera-bearing entity. Pass `.Invalid` + null to clear.
	public void SetCamera(EntityHandle entity, CameraComponent comp)
	{
		mCameraEntity = entity;
		mCamera = comp;

		if (entity == .Invalid || comp == null)
		{
			Visibility = .Gone;
			return;
		}

		UpdateTitle();
		Visibility = .Visible;
	}

	/// Called by the host on selection changes. Routes to SetCamera unless
	/// the panel is pinned, in which case the cached camera stays put.
	public void HandleSelectionChanged(EntityHandle entity, CameraComponent comp)
	{
		if (Pinned)
		{
			// Hide only if the pinned camera entity got destroyed.
			if (mCameraEntity != .Invalid && !mScene.IsValid(mCameraEntity))
				SetCamera(.Invalid, null);
			return;
		}
		SetCamera(entity, comp);
	}

	private void UpdateTitle()
	{
		if (mCameraEntity == .Invalid)
		{
			mTitleLabel.SetText("Camera");
			return;
		}

		let name = mScene.GetEntityName(mCameraEntity);
		let title = scope String();
		title.AppendF("Camera: {}", name.IsEmpty ? "unnamed" : name);
		if (Pinned) title.Append(" (pinned)");
		mTitleLabel.SetText(title);
	}

	private void RenderPreview(ViewportView vp, ICommandEncoder encoder, int32 frameIndex)
	{
		if (!vp.IsReady) return;
		if (mSceneRenderer == null) return;
		if (mCameraEntity == .Invalid || !mScene.IsValid(mCameraEntity) || mCamera == null)
			return;

		encoder.TransitionTexture(vp.ColorTexture, .Undefined, .RenderTarget);

		// Clear so the preview doesn't show last frame's contents on the RT.
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

		// Build a CameraOverride from the selected CameraComponent rather than
		// using the scene's active camera, so the preview shows that specific
		// camera's view even when another camera is the active one.
		let aspect = (vp.RenderHeight > 0) ? (float)vp.RenderWidth / (float)vp.RenderHeight : 1.0f;
		let viewMatrix = mCamera.GetViewMatrix(mScene);
		let projMatrix = mCamera.GetProjectionMatrix(aspect);
		let worldMatrix = mScene.GetWorldMatrix(mCameraEntity);
		let cameraOverride = CameraOverride()
		{
			ViewMatrix = viewMatrix,
			ProjectionMatrix = projMatrix,
			CameraPosition = worldMatrix.Translation,
			NearPlane = mCamera.NearPlane,
			FarPlane = mCamera.FarPlane,
		};

		// Route the render through our secondary pipeline (keyed on `this`)
		// so it doesn't thrash the main viewport's SceneDepth.
		mSceneRenderer.RenderScene(mScene, encoder, vp.ColorTexture, vp.ColorTargetView,
			vp.RenderWidth, vp.RenderHeight, frameIndex, cameraOverride, PipelineKey);
	}
}
