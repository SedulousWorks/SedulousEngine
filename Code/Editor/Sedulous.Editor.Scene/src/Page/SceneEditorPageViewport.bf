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
		mCamera.RayThrough(ndcX, ndcY, (float)w / (float)h, out outRay.Origin, out outRay.Direction);
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
		input.CameraUp = mCamera.Up;
		input.FovY = mCamera.FovY;
		input.OrthoHeight = mCamera.Orthographic ? mCamera.OrthoHeight : 0.0f;
		input.EditingLocked = mIsSimulating;
		GizmoRay ray = ?;
		input.PointerValid = viewportActive && MakeMouseRay(out ray);
		input.Ray.Origin = ray.Origin;
		input.Ray.Direction = ray.Direction;
		input.PointerOver = mViewport.IsHovered();
		if (!input.PointerValid)
		{
			mCameraOwnsInput = mCamera.MouseCaptured;
			return mViewportTools.Update(input);
		}

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
		mCameraOwnsInput = cameraOwnsMouse;
		// The pointer's view pixel and the view's size: the GPU pick's input, in the space of
		// the RenderScene viewport rect, which is the full render target.
		input.PointerX = (int32)mouse.X;
		input.PointerY = (int32)mouse.Y;
		input.ViewportWidth = mViewport.RenderWidth;
		input.ViewportHeight = mViewport.RenderHeight;
		// The orientation gizmo takes a click on one of its knobs before any tool sees it, and
		// the rest of that press, so the select tool neither picks nor box-selects under it. A
		// press reaches here only when the camera does not own the mouse: Alt+drag still orbits.
		if (input.LeftPressed && mViewport.IsHovered())
		{
			let gizmo = ViewGizmo.LayoutFor(mCamera.Right, mCamera.Up, mCamera.Forward, (float)input.ViewportWidth);
			let px = (float)input.PointerX;
			let py = (float)input.PointerY;
			let hit = ViewGizmo.Hit(gizmo, px, py);
			if (hit >= 0)
			{
				ViewGizmo.SnapAngles(gizmo.Poles[hit].Axis, mCamera.Yaw, let yaw, let pitch);
				mCamera.AutoOrthographic = EditorUiSettings.AutoOrthographicViews(mContext.UserEditorSettings);
				mCamera.SnapToAxis(yaw, pitch);
				mViewGizmoPressed = true;
			}
			else if (ViewGizmo.HitCentre(gizmo, px, py))
			{
				mCamera.SetOrthographic(!mCamera.Orthographic);
				mViewGizmoPressed = true;
			}
		}
		if (mViewGizmoPressed)
		{
			let released = input.LeftReleased;
			input.LeftPressed = false;
			input.LeftDown = false;
			input.LeftReleased = false;
			mViewGizmoPressed = !released;
		}
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
		gizmoCamera.Projection = mCamera.Projection(gizmoAspect);
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

	/// The frame rate in the viewport's top right corner, clear of the tool status text in
	/// the top left. Sampled over half second windows of THIS page's update dt, which is the
	/// rate the person editing sees rather than the application's.
	private void DrawFrameRate(DebugDraw dd, float dt)
	{
		if (!mView.ShowFps)
		{
			mFpsWindowSeconds = 0.0;
			mFpsWindowFrames = 0;
			mFpsText.Clear();
			return;
		}
		mFpsWindowSeconds += (double)dt;
		mFpsWindowFrames++;
		if ((mFpsWindowSeconds >= 0.5) || mFpsText.IsEmpty)
		{
			FrameRateOverlay.Text(mFpsWindowSeconds, mFpsWindowFrames, mFpsText);
			mFpsWindowSeconds = 0.0;
			mFpsWindowFrames = 0;
		}
		dd.DrawScreenTextRight(12.0f, 12.0f, mFpsText, .(0.85f, 0.85f, 0.85f, 1.0f));
	}

	/// How high the camera is over the grid's plane, for its spacing: the eye's height in
	/// perspective; under orthographic, the pivot's distance (what the view spans), since an
	/// orthographic eye may stand level with the plane and still see across it.
	private float GridViewHeight()
	{
		if (mCamera.Orthographic)
			return mCamera.FocusDistance;
		return Math.Abs(Dot(mCamera.Position, SceneGrid.AxesOf(mView.GridPlane).Normal));
	}

	/// The grid's spacing where the camera is now (by its distance from the grid's plane): what
	/// the grid draws and the zoom readout reports.
	private GridSpacing CurrentGridSpacing() => SceneGrid.SpacingFor(GridViewHeight());

	/// The grid on the chosen plane: the shader grid, or debug lines when GridLines.
	private void DrawSceneGrid(DebugDraw dd)
	{
		let axes = SceneGrid.AxesOf(mView.GridPlane);
		let along = Dot(mCamera.Position, axes.Normal);
		let height = GridViewHeight();
		let step = SceneGrid.SpacingFor(height);
		// The camera's foot on the plane: the grid is centred under it, wherever it flies.
		let foot = mCamera.Position - axes.Normal * along;
		if (!mView.GridLines)
		{
			var grid = GridPlaneDesc();
			grid.Origin = foot;
			grid.FadeDistance = SceneGrid.FadeDistance(height);
			grid.Extent = grid.FadeDistance;
			grid.AxisU = axes.U;
			grid.AxisV = axes.V;
			grid.Spacing = step.Spacing;
			grid.Blend = step.Blend;
			grid.CameraPosition = mCamera.Position;
			dd.DrawGridPlane(grid);
			return;
		}
		// The line grid, to compare: the same spacing, every tenth line brighter, a square a
		// hundred cells each way snapped to the coarse spacing under the camera (so it does not
		// swim), no fade and no blend between decades.
		const int32 cHalfCells = 100;
		let coarse = step.Spacing * 10.0f;
		let cu = Math.Floor(Dot(foot, axes.U) / coarse) * coarse;
		let cv = Math.Floor(Dot(foot, axes.V) / coarse) * coarse;
		let half = step.Spacing * (float)cHalfCells;
		// sRGB, like every colour: a light grey that stays clear of the backdrop.
		let minor = Color(0.63f, 0.63f, 0.65f, 0.35f);
		let major = Color(0.63f, 0.63f, 0.65f, 1.0f);
		for (int32 i = -cHalfCells; i <= cHalfCells; i++)
		{
			let t = (float)i * step.Spacing;
			let color = (i % 10 == 0) ? major : minor;
			let alongV = axes.U * (cu + t);
			let alongU = axes.V * (cv + t);
			dd.DrawLine(alongV + axes.V * (cv - half), alongV + axes.V * (cv + half), color);
			dd.DrawLine(alongU + axes.U * (cu - half), alongU + axes.U * (cu + half), color);
		}
	}

	/// The orientation gizmo: the axis tripod turning with the camera, back to front so a knob
	/// pointing at the viewer covers the arms and knobs behind it, the knob under the pointer
	/// lit. The positive axes have an arm from the centre, the negative ones a dimmer knob alone.
	private void DrawViewGizmo(DebugDraw dd)
	{
		if (!mViewport.IsReady || (mViewport.RenderWidth == 0))
			return;
		let gizmo = ViewGizmo.LayoutFor(mCamera.Right, mCamera.Up, mCamera.Forward, (float)mViewport.RenderWidth);
		var hovered = (int32)-1;
		if (mViewport.IsHovered() && (mViewport.Mouse != null))
			hovered = ViewGizmo.Hit(gizmo, mViewport.Mouse.X, mViewport.Mouse.Y);
		const float cGlyph = (float)DebugFont.cCharWidth;
		const float cGlyphHeight = (float)DebugFont.cCharHeight;
		let half = 0.5f * ViewGizmo.cKnob;
		for (int32 i < 6)
		{
			let pole = gizmo.Poles[i];
			let color = ViewGizmo.ColorOf(pole, i == hovered);
			if (pole.Positive)
				dd.DrawScreenLine(gizmo.Center.X, gizmo.Center.Y, pole.Screen.X, pole.Screen.Y, color, 2.0f);
			dd.DrawScreenRect(pole.Screen.X - half, pole.Screen.Y - half, ViewGizmo.cKnob, ViewGizmo.cKnob, color);
			let label = ViewGizmo.Label(pole);
			let ink = pole.Positive ? Color(0.08f, 0.08f, 0.08f, 1.0f) : Color(0.9f, 0.9f, 0.9f, 1.0f);
			dd.DrawScreenText(pole.Screen.X - 0.5f * cGlyph * (float)label.Length, pole.Screen.Y - 0.5f * cGlyphHeight, label, ink);
		}
		// The centre: a click switches the projection; under the tripod, which one is on.
		let overCentre = mViewport.IsHovered() && (mViewport.Mouse != null)
			&& ViewGizmo.HitCentre(gizmo, mViewport.Mouse.X, mViewport.Mouse.Y);
		let c = 0.5f * ViewGizmo.cCentre;
		let centre = overCentre ? Color(1.0f, 1.0f, 1.0f, 1.0f) : Color(0.75f, 0.75f, 0.75f, 1.0f);
		dd.DrawScreenRect(gizmo.Center.X - c, gizmo.Center.Y - c, ViewGizmo.cCentre, ViewGizmo.cCentre, centre);
		let projection = ViewGizmo.ProjectionLabel(mCamera.Orthographic);
		dd.DrawScreenText(gizmo.Center.X - 0.5f * cGlyph * (float)projection.Length,
			gizmo.Center.Y + ViewGizmo.cArm + ViewGizmo.cKnob, projection, .(0.85f, 0.85f, 0.85f, 1.0f));
	}

	/// The measurement overlay while zooming, bottom left, at `opacity`: the focus distance and
	/// the grid cell over a scale bar of a round length at the focus. Clear of the tool status
	/// (top left) and the frame rate (top right).
	private void DrawZoomReadout(DebugDraw dd, float opacity)
	{
		if (!mViewport.IsReady || (mViewport.RenderHeight == 0))
			return;
		let height = (float)mViewport.RenderHeight;
		let bar = ZoomReadout.ScaleBarAt(mCamera.FocusDistance, mCamera.FovY, height);
		let focusText = scope String();
		ZoomReadout.FormatMetres(mCamera.FocusDistance, focusText);
		focusText.Append(" to focus");
		// The cell of the grid as drawn; whether the grid shows is the page's toggle.
		let cellText = scope String("grid cell ");
		ZoomReadout.FormatMetres(CurrentGridSpacing().Spacing, cellText);
		let barText = ZoomReadout.FormatMetres(bar.Metres, .. scope String());

		const float cMargin = 12.0f;
		const float cPad = 6.0f;
		const float cLine = (float)DebugFont.cCharHeight + 6.0f;
		const float cGlyph = (float)DebugFont.cCharWidth;
		let textWidth = cGlyph * (float)Math.Max(focusText.Length, cellText.Length);
		let barWidth = bar.Pixels + 6.0f + cGlyph * (float)barText.Length;
		let width = Math.Max(textWidth, barWidth) + 2.0f * cPad;
		let boxHeight = 2.0f * cLine + 10.0f + 2.0f * cPad;
		let left = cMargin;
		let top = height - cMargin - boxHeight;
		dd.DrawScreenRect(left, top, width, boxHeight, .(0.0f, 0.0f, 0.0f, 0.45f * opacity));

		let ink = Color(0.85f, 0.85f, 0.85f, opacity);
		let x = left + cPad;
		dd.DrawScreenText(x, top + cPad, focusText, ink);
		dd.DrawScreenText(x, top + cPad + cLine, cellText, ink);
		// The bar: a line the length of its round measure, with end ticks, its length beside it.
		let barY = top + cPad + 2.0f * cLine + 4.0f;
		dd.DrawScreenRect(x, barY, bar.Pixels, 2.0f, ink);
		dd.DrawScreenRect(x, barY - 3.0f, 1.0f, 8.0f, ink);
		dd.DrawScreenRect(x + bar.Pixels - 1.0f, barY - 3.0f, 1.0f, 8.0f, ink);
		dd.DrawScreenText(x + bar.Pixels + 6.0f, barY - 3.0f, barText, ink);
	}

	/// Frames entities in the viewport: the camera stands back along its view so the box
	/// holding them all, each with everything under it, fits, and pivots its orbit on its centre.
	/// The span is what the scene's systems measure (ISceneEntityBounds: meshes, colliders), or a
	/// small one at an entity's position when none does. Eases there when `ease`. False when no
	/// entity resolves or the page has no viewport.
	public bool FrameEntities(Span<Guid> entities, bool ease)
	{
		if ((mScene == null) || (mViewport == null))
			return false;
		let scene = mScene;
		var merged = AABB.Empty();
		var any = false;
		let pending = scope List<EntityHandle>();
		for (let id in entities)
		{
			let e = scene.FindEntity(id);
			if (!scene.IsValid(e))
				continue;
			// The entity and everything under it, as the hierarchy shows it: a gameplay root's
			// model hangs below it.
			var span = AABB.Empty();
			var measured = false;
			pending.Clear();
			pending.Add(e);
			while (!pending.IsEmpty)
			{
				let current = pending.PopBack();
				if (scene.EntityWorldBounds(current, let part))
				{
					span = measured ? Merge(span, part) : part;
					measured = true;
				}
				for (var child = scene.GetFirstChild(current); scene.IsValid(child); child = scene.GetNextSibling(child))
					pending.Add(child);
			}
			if (!measured)
			{
				// Nothing in it measures (an empty, a light): its place, the marker's size.
				let world = scene.GetWorldMatrix(e);
				span = AABB.FromCenterExtents(.(world.M[3][0], world.M[3][1], world.M[3][2]), .(0.35f, 0.35f, 0.35f));
			}
			merged = any ? Merge(merged, span) : span;
			any = true;
		}
		if (!any)
			return false;
		mCamera.FrameSphere(merged.Center(), Length(merged.Extents()), mCamera.FovY, ease);
		return true;
	}

	/// A small cross at every entity, and the selection's bounds.
	private void DrawEntityMarkers(DebugDraw dd)
	{
		if (mEditContext == null)
			return;
		let selection = mEditContext.EntitySelection;
		let scene = mScene;
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
			// What the scene's systems measure the entity as (meshes, colliders), so the box
			// drawn is the one F frames; a small span at the origin when none does.
			if (scene.EntityWorldBounds(e, let bounds))
			{
				dd.DrawWireBoxCenter(bounds.Center(), bounds.Extents(), color);
				return;
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

	/// Places a tool's panel: over the viewport, in the floating panel, or as its domain's tab
	/// in the bottom dock.
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
			// A docked panel is a tab of its own, named for the tool's domain (its category,
			// "Terrain"), else the tool; it goes when the panel does.
			if (mBottomDock == null)
				return;
			if (!mDockedToolTab.IsEmpty)
			{
				mBottomDock.RemoveTab(mDockedToolTab);
				mDockedToolTab.Clear();
			}
			if (view != null)
			{
				let tool = mViewportTools.ActiveTool;
				let label = (tool == null) ? StringView("Tool") : (tool.Category.IsEmpty ? tool.DisplayName : tool.Category);
				mDockedToolTab.Set("tool:");
				mDockedToolTab.Append(label);
				mBottomDock.AddTab(mDockedToolTab, label, view); // the dock takes its own reference
				mBottomDock.ActivateTab(mDockedToolTab);
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
