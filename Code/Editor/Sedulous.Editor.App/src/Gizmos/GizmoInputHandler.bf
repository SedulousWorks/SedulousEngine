namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.UI;
using Sedulous.UI.Viewport;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
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

		// Entity picking via ray-AABB intersection
		{
			let ray = CreatePickRay(e.X, e.Y, viewport);
			let hit = PickEntity(ray);
			if (hit != .Invalid)
				mPage.SelectEntity(hit);
			else
				mPage.ClearSelection();
			e.Handled = true;
		}
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

	// === Entity Picking ===

	/// Picks the closest entity under the ray by testing against mesh bounding boxes.
	private EntityHandle PickEntity(Ray ray)
	{
		let meshMgr = mScene.GetModule<MeshComponentManager>();
		let skinnedMgr = mScene.GetModule<SkinnedMeshComponentManager>();

		EntityHandle closestEntity = .Invalid;
		float closestDist = float.MaxValue;

		// Test static meshes
		if (meshMgr != null)
		{
			for (let comp in meshMgr.ActiveComponents)
			{
				if (!comp.IsActive || !comp.MeshHandle.IsValid) continue;
				let dist = TestEntityBounds(ray, comp.Owner, comp.LocalBounds);
				if (dist.HasValue && dist.Value < closestDist)
				{
					closestDist = dist.Value;
					closestEntity = comp.Owner;
				}
			}
		}

		// Test skinned meshes
		if (skinnedMgr != null)
		{
			for (let comp in skinnedMgr.ActiveComponents)
			{
				if (!comp.IsActive || !comp.MeshHandle.IsValid) continue;
				let dist = TestEntityBounds(ray, comp.Owner, comp.LocalBounds);
				if (dist.HasValue && dist.Value < closestDist)
				{
					closestDist = dist.Value;
					closestEntity = comp.Owner;
				}
			}
		}

		// For entities without meshes (lights, cameras), use a small proxy sphere
		for (let entity in mScene.Entities)
		{
			if (!mScene.IsValid(entity)) continue;

			// Skip entities that have mesh components (already tested)
			if (meshMgr != null && meshMgr.GetForEntity(entity) != null) continue;
			if (skinnedMgr != null && skinnedMgr.GetForEntity(entity) != null) continue;

			let worldPos = mScene.GetWorldMatrix(entity).Translation;
			let proxyRadius = 0.5f;
			let sphere = BoundingSphere(worldPos, proxyRadius);

			let dist = ray.Intersects(sphere);
			if (dist.HasValue && dist.Value < closestDist)
			{
				closestDist = dist.Value;
				closestEntity = entity;
			}
		}

		return closestEntity;
	}

	/// Tests a ray against an entity's local bounding box transformed to world space.
	private float? TestEntityBounds(Ray ray, EntityHandle entity, BoundingBox localBounds)
	{
		// Transform ray into entity's local space
		let worldMatrix = mScene.GetWorldMatrix(entity);
		Matrix invWorld;
		if (!Matrix.TryInvert(worldMatrix, out invWorld))
			return null;

		let localRayPos = Vector3.Transform(ray.Position, invWorld);
		let localRayDir = Vector3.TransformNormal(ray.Direction, invWorld);
		let localRayDirLen = localRayDir.Length();
		if (localRayDirLen < 0.0001f) return null;

		let localRay = Ray(localRayPos, localRayDir / localRayDirLen);
		let dist = localRay.Intersects(localBounds);

		if (dist.HasValue)
		{
			// Scale distance back to world space
			return dist.Value / localRayDirLen;
		}
		return null;
	}
}
