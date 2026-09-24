using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shell;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Viewport;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Scene;

/// The viewport's frame: the mouse ray, the tools' input, the gizmo and marker drawing, the
/// tool panel placements, the camera preview, and the window binding.
extension SceneEditorPage
{
	private bool MakeMouseRay(out GizmoRay outRay)
	{
		outRay = .();
		let mouse = mViewport.Mouse;
		let w = mViewport.RenderWidth;
		let h = mViewport.RenderHeight;
		if ((mouse == null) || (w == 0) || (h == 0))
			return false;
		let ndcX = 2.0f * (mouse.X / (float)w) - 1.0f;
		let ndcY = 1.0f - 2.0f * (mouse.Y / (float)h);
		let tanY = Tan(cFovY * 0.5f);
		let tanX = tanY * ((float)w / (float)h);
		outRay.Origin = mCamera.Position;
		outRay.Direction = Normalized(mCamera.Forward + mCamera.Right * (ndcX * tanX) + mCamera.Up * (ndcY * tanY));
		return true;
	}

	/// Feeds the active tool; the camera keeps the mouse while Alt or the right button is
	/// held, or while it is in captured fly mode.
	private bool UpdateViewportTools(bool viewportActive, float deltaSeconds)
	{
		if (mSelectTool == null)
			return false;
		var input = ViewportToolInput();
		input.DeltaSeconds = deltaSeconds;
		input.CameraPosition = mCamera.Position;
		input.CameraForward = mCamera.Forward;
		input.FovY = cFovY;
		input.EditingLocked = mIsSimulating;
		GizmoRay ray = ?;
		input.PointerValid = viewportActive && MakeMouseRay(out ray);
		input.Ray.Origin = ray.Origin;
		input.Ray.Direction = ray.Direction;
		input.PointerOver = mViewport.IsHovered();
		if (!input.PointerValid)
			return mViewportTools.Update(input);

		let mouse = mViewport.Mouse;
		let kb = mViewport.Keyboard;
		let cameraOwnsMouse = ((kb != null) && (kb.IsKeyDown(.LeftAlt) || kb.IsKeyDown(.RightAlt)))
			|| mouse.IsButtonDown(.Right) || mCamera.MouseCaptured;
		if (!cameraOwnsMouse)
		{
			input.LeftPressed = mouse.IsButtonPressed(.Left);
			input.LeftDown = mouse.IsButtonDown(.Left);
		}
		input.LeftReleased = mouse.IsButtonReleased(.Left) || !mouse.IsButtonDown(.Left);
		if (kb != null)
		{
			input.Ctrl = kb.IsKeyDown(.LeftCtrl) || kb.IsKeyDown(.RightCtrl);
			input.Shift = kb.IsKeyDown(.LeftShift) || kb.IsKeyDown(.RightShift);
		}
		input.WheelDelta = mouse.ScrollY;
		input.Keyboard = cameraOwnsMouse ? null : kb;
		// The pointer's view pixel and the view's size: the GPU pick's input, in the space of
		// the RenderScene viewport rect, which is the full render target.
		input.PointerX = (int32)mouse.X;
		input.PointerY = (int32)mouse.Y;
		input.ViewportWidth = mViewport.RenderWidth;
		input.ViewportHeight = mViewport.RenderHeight;
		return mViewportTools.Update(input);
	}

	private void DrawGizmos(DebugDraw dd)
	{
		mViewportTools.Draw(dd);
		if (let active = mViewportTools.ActiveTool)
		{
			let status = active.StatusText;
			if (!status.IsEmpty)
				dd.DrawScreenText(12.0f, 12.0f, status, .(0.85f, 0.85f, 0.85f, 1.0f));
		}
		if (mEditContext == null)
			return;

		let ctx = scope GizmoContext();
		ctx.Debug = dd;
		ctx.Scene = mScene;
		ctx.CameraPosition = mCamera.Position;
		var gizmoCamera = ViewCamera();
		gizmoCamera.View = Float4x4.LookAtRH(mCamera.Position, mCamera.Position + mCamera.Forward, mCamera.Up);
		let gizmoAspect = ((mViewport != null) && mViewport.IsReady && (mViewport.RenderHeight > 0))
			? (float)mViewport.RenderWidth / (float)mViewport.RenderHeight : 16.0f / 9.0f;
		gizmoCamera.Projection = Float4x4.PerspectiveFovRH(cFovY, gizmoAspect, 0.1f, 1000.0f);
		gizmoCamera.Position = mCamera.Position;
		ctx.ViewCamera = &gizmoCamera;
		ctx.LodOverlay = mView.ShowLodOverlay;
		ctx.ShowColliders = mView.ShowColliders;
		let selection = mEditContext.EntitySelection;
		mScene.ForEachEntity(scope [&](e) =>
		{
			mComponentGizmos.DrawEntity(e, selection.Contains(mScene.GetEntityId(e)), ctx);
		});
	}

	/// A small cross at every entity, and the selection's bounds.
	private void DrawEntityMarkers(DebugDraw dd)
	{
		if (mEditContext == null)
			return;
		let selection = mEditContext.EntitySelection;
		let scene = mScene;
		let meshes = scene.GetSystem<MeshComponentManager>();
		let instanced = scene.GetSystem<InstancedMeshComponentManager>();
		scene.ForEachEntity(scope [&](e) =>
		{
			let world = scene.GetWorldMatrix(e);
			let p = Float3(world.M[3][0], world.M[3][1], world.M[3][2]);
			let selected = selection.Contains(scene.GetEntityId(e));
			if (!selected && !mView.ShowMarkers)
				return; // the Markers toggle: an unselected origin draws nothing
			let s = 0.25f;
			let color = selected ? Color(1.0f, 0.85f, 0.25f, 1.0f) : Color(0.75f, 0.75f, 0.80f, 1.0f);
			dd.DrawLine(p - Float3(s, 0, 0), p + Float3(s, 0, 0), color);
			dd.DrawLine(p - Float3(0, s, 0), p + Float3(0, s, 0), color);
			dd.DrawLine(p - Float3(0, 0, s), p + Float3(0, 0, s), color);
			if (!selected)
				return;
			if (meshes != null)
			{
				if (let mc = meshes.Get(e))
				{
					if (let mesh = mc.Mesh.Get)
					{
						dd.DrawTransformedBox(mesh.Bounds.Min, mesh.Bounds.Max, world, color);
						return;
					}
				}
			}
			if (instanced != null)
			{
				if (let imc = instanced.Get(e))
				{
					if ((imc.Mesh.Get != null) && (imc.Count > 0) && (imc.CachedRadius > 0.0f))
					{
						let r = imc.CachedRadius;
						dd.DrawWireBoxCenter(imc.CachedCenter, .(r, r, r), color);
						return;
					}
				}
			}
			dd.DrawWireBoxCenter(p, .(0.35f, 0.35f, 0.35f), color);
		});
	}

	// ---- tool panels ----

	private void BuildToolFloat()
	{
		mToolFloat = new FloatingPanel("Brush");
		mToolFloat.Visibility = .Gone;
		mToolFloat.OnClose.Add(new [=this]() => { mViewportTools.ActivateDefault(); });
	}

	/// Places a tool's panel: over the viewport, in the floating panel, or in the dock's tab.
	/// The view is BORROWED; the containers take their own reference.
	private void MountToolPanel(View view, ToolPanelPlacement placement)
	{
		switch (placement)
		{
		case .ViewportOverlay:
			if (mToolOverlay == null)
				return;
			mToolOverlay.RemoveAllViews();
			if (view != null)
			{
				view.AddRef();
				mToolOverlay.AddView(view);
				mToolOverlay.Visibility = .Visible;
			}
			else
			{
				mToolOverlay.Visibility = .Gone;
			}
		case .Float:
			if (mToolFloat == null)
				return;
			if (view != null)
				view.AddRef();
			mToolFloat.SetContent(view);
			if (view != null)
			{
				if (let tool = mViewportTools.ActiveTool)
					mToolFloat.SetTitle(tool.DisplayName);
				mToolFloat.SetCollapsed(false);
			}
			mToolFloat.Visibility = (view != null) ? .Visible : .Gone;
		default:
			if (mToolPanelSlot == null)
				return;
			mToolPanelSlot.RemoveAllViews();
			if (view != null)
			{
				view.AddRef();
				mToolPanelSlot.AddView(view);
				mBottomDock.ActivateTab("tool"); // reveal the brush settings
			}
		}
	}

	// ---- the camera preview ----

	private void BuildCameraPreview()
	{
		mPreviewViewport = new ViewportView();
		mPreviewViewport.ClearColor = .(0.0f, 0.0f, 0.0f, 1.0f);
		mPreviewViewport.SetFixedResolution(320, cPreviewHeight);

		mPreviewPin = new Button("Pin");
		mPreviewPin.OnClick.Add(new [=this](b) => { ToggleCameraPin(); });

		let container = new FlexLayout();
		container.Direction = .Vertical;
		container.Visibility = .Gone; // idle until a camera is previewed
		var pinStyle = LayoutStyle();
		pinStyle.Width = SizeSpec.Match();
		pinStyle.Height = SizeSpec.Fixed(Unit.Dp(24.0f));
		container.AddView(mPreviewPin, pinStyle);
		var viewStyle = LayoutStyle();
		viewStyle.Width = SizeSpec.Fixed(Unit.Dp(320.0f));
		viewStyle.Height = SizeSpec.Fixed(Unit.Dp((float)cPreviewHeight));
		container.AddView(mPreviewViewport, viewStyle);
		mPreviewContainer = container;
	}

	private EntityHandle SelectedCameraEntity
	{
		get
		{
			if ((mEditContext == null) || (mScene == null) || mEditContext.EntitySelection.IsEmpty)
				return .Invalid;
			let e = mEditContext.Resolve(mEditContext.EntitySelection.Primary);
			return IsLiveCamera(e) ? e : .Invalid;
		}
	}

	private bool IsLiveCamera(EntityHandle entity)
	{
		if ((mScene == null) || !entity.IsAssigned || !mScene.IsValid(entity))
			return false;
		let cameras = mScene.GetSystem<CameraComponentManager>();
		return (cameras != null) && (cameras.Get(entity) != null);
	}

	private void UpdateCameraPreview()
	{
		if (mPreviewContainer == null)
			return;
		let selection = SelectedCameraEntity;
		let res = CameraPreview.Resolve(selection, selection.IsAssigned, mPinnedCamera, IsLiveCamera(mPinnedCamera));
		if (res.Unpin)
			mPinnedCamera = .Invalid; // a stale pin clears itself
		mPreviewTarget = res.Target;

		let vis = res.Visible ? Visibility.Visible : Visibility.Gone;
		if (mPreviewContainer.Visibility != vis)
		{
			mPreviewContainer.Visibility = vis;
			mPreviewContainer.Invalidate(); // a visibility flip only, no view churn
		}
		if (mPreviewPin != null)
		{
			let pinned = mPinnedCamera.IsAssigned && (mPreviewTarget == mPinnedCamera);
			mPreviewPin.SetText(pinned ? "Unpin" : "Pin");
		}
	}

	private void ToggleCameraPin()
	{
		if (mPinnedCamera.IsAssigned && (mPinnedCamera == mPreviewTarget))
			mPinnedCamera = .Invalid;
		else if (mPreviewTarget.IsAssigned)
			mPinnedCamera = mPreviewTarget;
		UpdateCameraPreview();
	}

	private void RenderCameraPreview()
	{
		if ((mPreviewViewport == null) || !mPreviewTarget.IsAssigned)
			return;
		if (!mPreviewViewport.IsReady || (mRender == null) || !mRender.IsReady || (mScene == null)
			|| !mPreviewViewport.IsEffectivelyVisible())
			return;
		let w = mPreviewViewport.RenderWidth;
		let h = mPreviewViewport.RenderHeight;
		if ((w == 0) || (h == 0))
			return;
		let cameras = mScene.GetSystem<CameraComponentManager>();
		if (cameras == null)
			return;
		let cam = cameras.Get(mPreviewTarget);
		if (cam == null)
			return;

		let world = mScene.GetWorldMatrix(mPreviewTarget);
		var camOverride = CameraPreview.BuildOverride(*cam, world);
		let targetState = TargetState(mPreviewViewport.ColorTexture, mPreviewViewport.ColorState, .ShaderRead);
		mRender.RenderScene(mScene, mPreviewViewport.ColorTargetView, mPreviewViewport.ColorFormat, w, h,
			.(0, 0, w, h), &camOverride, targetState, null, Internal.UnsafeCastToPtr(mPreviewViewport));
		mPreviewViewport.ColorState = .ShaderRead;
	}

	/// Binds on the first frame the view has a window, and re-binds when its panel moves to
	/// another window, once that window's renderer exists.
	private void EnsureViewportBound()
	{
		let root = mViewport.Root();
		if (root == null)
			return;
		let window = mUiHost.WindowForRoot(root);
		if ((window == null) || (window == mHostWindow))
			return;
		let renderer = mUiHost.RendererFor(window);
		if (renderer == null)
			return; // the float's AttachWindow has not run yet
		if (mHostWindow == null)
		{
			mViewport.Initialize(mHost.Graphics.Raw, renderer, mHost.Shell.Input, window.Window.Id);
			if (mViewport.Surface != null)
				mRouter.AddSurface(mViewport.Surface);
			if (mPreviewViewport != null)
				mPreviewViewport.Initialize(mHost.Graphics.Raw, renderer, null, window.Window.Id);
		}
		else
		{
			mViewport.AttachToWindow(renderer, window.Window.Id);
			if (mPreviewViewport != null)
				mPreviewViewport.AttachToWindow(renderer, window.Window.Id);
		}
		mHostWindow = window;
	}
}
