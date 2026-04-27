namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.UI;
using Sedulous.UI.Viewport;
using Sedulous.Engine.Core;
using Sedulous.Editor.Core;

/// Viewport input handler for gizmo interaction and entity picking.
/// Handles plain LMB: gizmo drag if hovering an axis, entity pick otherwise.
/// Registered before CameraInputHandler so gizmo gets first priority on LMB.
class GizmoInputHandler : IViewportInputHandler
{
	private EditorCamera mCamera;
	private TransformGizmo mGizmo;
	private SceneEditorPage mPage;
	private Scene mScene;

	// Drag state
	private bool mIsDragging;
	private GizmoMode mDragMode;
	private Transform mDragStartTransform;
	private EntityHandle mDragEntity;

	public this(EditorCamera camera, TransformGizmo gizmo, SceneEditorPage page, Scene scene)
	{
		mCamera = camera;
		mGizmo = gizmo;
		mPage = page;
		mScene = scene;
	}

	// === Pick ray ===

	private Ray CreatePickRay(float localX, float localY, ViewportView viewport)
	{
		let w = viewport.RenderWidth;
		let h = viewport.RenderHeight;
		if (w == 0 || h == 0) return .(.Zero, .(0, 0, -1));

		let aspect = (float)w / (float)h;
		return TransformGizmo.CreatePickRay(localX, localY, w, h,
			mCamera.GetViewMatrix(), mCamera.GetProjectionMatrix(aspect));
	}

	// === IViewportInputHandler ===

	public void OnMouseDown(MouseEventArgs e, ViewportView viewport)
	{
		// Only handle plain LMB (no modifiers)
		if (e.Button != .Left || e.Modifiers.HasFlag(.Alt))
			return;

		let selected = mPage.PrimarySelection;
		let mode = mPage.GizmoMode;

		// Check gizmo first
		if (selected != .Invalid && mScene.IsValid(selected) && mGizmo.HoveredAxis != .None)
		{
			let ray = CreatePickRay(e.X, e.Y, viewport);
			if (mGizmo.BeginDrag(ray, mode))
			{
				mIsDragging = true;
				mDragMode = mode;
				mDragEntity = selected;
				mDragStartTransform = mScene.GetLocalTransform(selected);
				viewport.Context?.FocusManager.SetCapture(viewport);
				e.Handled = true;
				return;
			}
		}

		// TODO: Entity picking via ray-AABB intersection
		e.Handled = true;
	}

	public void OnMouseUp(MouseEventArgs e, ViewportView viewport)
	{
		if (e.Button == .Left && mIsDragging)
		{
			// End drag — push undo command
			if (mDragEntity != .Invalid && mScene.IsValid(mDragEntity))
			{
				let newTransform = mScene.GetLocalTransform(mDragEntity);
				let cmd = new SetTransformCommand(mScene, mDragEntity, mDragStartTransform, newTransform);
				mPage.CommandStack.Execute(cmd);
				mPage.MarkDirty();
			}

			mGizmo.EndDrag();
			mIsDragging = false;
			mDragEntity = .Invalid;
			viewport.Context?.FocusManager.ReleaseCapture();
			e.Handled = true;
		}
	}

	public void OnMouseMove(MouseEventArgs e, ViewportView viewport)
	{
		if (mIsDragging)
		{
			let ray = CreatePickRay(e.X, e.Y, viewport);

			if (mDragEntity != .Invalid && mScene.IsValid(mDragEntity))
			{
				var transform = mDragStartTransform;

				switch (mDragMode)
				{
				case .Translate:
					let delta = mGizmo.UpdateTranslateDrag(ray);
					transform.Position = transform.Position + delta;

				case .Rotate:
					let (rotAxis, angleDelta) = mGizmo.UpdateRotateDrag(ray);
					let dragRotation = Quaternion.CreateFromAxisAngle(rotAxis, angleDelta);
					transform.Rotation = dragRotation * mDragStartTransform.Rotation;

				case .Scale:
					let scaleDelta = mGizmo.UpdateScaleDrag(ray);
					transform.Scale = mDragStartTransform.Scale + scaleDelta;
					// Clamp to prevent negative/zero scale
					transform.Scale.X = Math.Max(transform.Scale.X, 0.001f);
					transform.Scale.Y = Math.Max(transform.Scale.Y, 0.001f);
					transform.Scale.Z = Math.Max(transform.Scale.Z, 0.001f);
				}

				mScene.SetLocalTransform(mDragEntity, transform);
				mGizmo.Position = mScene.GetWorldMatrix(mDragEntity).Translation;
			}
			e.Handled = true;
			return;
		}

		// Update gizmo hover (don't set e.Handled — let camera track mouse too)
		let selected = mPage.PrimarySelection;
		if (selected != .Invalid && mScene.IsValid(selected))
		{
			let ray = CreatePickRay(e.X, e.Y, viewport);
			mGizmo.UpdateHover(ray, mPage.GizmoMode);
		}
	}

	public void OnMouseWheel(MouseWheelEventArgs e, ViewportView viewport)
	{
		// Gizmo doesn't handle scroll — let camera handle it
	}
}
