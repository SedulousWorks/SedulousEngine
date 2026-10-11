using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Drives a TransformGizmo over the primary selected entity and turns its drags into
/// transform commands. A drag session is ONE undo entry: the sets merge inside a locked
/// group, so undo returns to where the drag started.
///
/// The edit context is borrowed: the page owns it, and the controller dies with the page.
class GizmoController
{
	private SceneEditContext mEdit;
	private TransformGizmo mGizmo = new .() ~ delete _;
	private GizmoMode mMode = .Translate;
	private GizmoSpace mSpace = .World;
	/// False while nothing is selected or the selection is behind the camera.
	private bool mActive = false;
	private bool mInGroup = false;

	private Guid mDragEntity = .();
	private Transform mDragStartLocal = .();
	private Float4x4 mParentInverseWorld = .Identity();
	private Quaternion mParentRotation = .Identity;
	private bool mVertexSnapMode = false;
	/// The vertex the pivot is snapped to (vertex snap), world space.
	private Float3? mSnapTarget = null;
	/// How far along the ray a snap target may be.
	private const float cSnapReach = 10000.0f;

	public this(SceneEditContext edit)
	{
		mEdit = edit;
	}

	public GizmoMode Mode => mMode;
	public GizmoSpace Space => mSpace;
	public TransformGizmo Gizmo => mGizmo;
	public bool IsActive => mActive;

	/// Vertex snap for every translate drag while on (the toolbar's toggle), as holding V
	/// does for one.
	public bool VertexSnapMode
	{
		get => mVertexSnapMode;
		set => mVertexSnapMode = value;
	}

	/// The vertex a vertex snapping drag holds the pivot on this frame (world); none when not
	/// snapping, or when the cursor is over no surface.
	public Float3? SnapTarget => mSnapTarget;

	/// Mode and space changes wait for a drag to finish, so the frame it measures against
	/// never changes under it.
	public void SetMode(GizmoMode mode)
	{
		if (!mGizmo.IsDragging)
			mMode = mode;
	}

	public void SetSpace(GizmoSpace space)
	{
		if (!mGizmo.IsDragging)
			mSpace = space;
	}

	/// Syncs the pose to the selection, hovers, and runs a drag. True when the pointer was
	/// consumed: hovering a handle, dragging, or closing a drag out.
	public bool Update(in GizmoFrameInput input)
	{
		if (!mGizmo.IsDragging && input.PointerValid)
		{
			if (input.KeyTranslate)
				mMode = .Translate;
			if (input.KeyRotate)
				mMode = .Rotate;
			if (input.KeyScale)
				mMode = .Scale;
			if (input.KeyToggleSpace)
				mSpace = (mSpace == .World) ? .Local : .World;
		}

		let selection = mEdit.EntitySelection;
		let primary = selection.IsEmpty ? Guid() : selection.Primary;
		let entity = selection.IsEmpty ? EntityHandle.Invalid : mEdit.Resolve(primary);
		if (!entity.IsAssigned)
		{
			AbortDrag();
			mActive = false;
			return false;
		}

		let scene = mEdit.Scene;
		mGizmo.SetCamera(input.CameraPosition, input.CameraForward);

		let world = scene.ComposeWorldMatrix(entity);
		mGizmo.Position = .(world.M[3][0], world.M[3][1], world.M[3][2]);
		// The rotation frame is captured at BeginDrag; the handles must not drift mid drag.
		if (!mGizmo.IsDragging)
		{
			mGizmo.Orientation = .Identity;
			if ((mSpace == .Local) || (mMode == .Scale))
			{
				Float3 t = ?, s = ?;
				Quaternion r = ?;
				if (Decompose(world, out t, out r, out s))
					mGizmo.Orientation = r;
			}
		}

		let scale = TransformGizmo.ScreenScale(input.CameraPosition, input.CameraForward,
			input.FovY, mGizmo.Position);
		if (scale <= 0.0001f) // at or behind the camera plane
		{
			AbortDrag();
			mActive = false;
			return false;
		}
		mGizmo.Size = scale;
		mActive = true;

		if (mGizmo.IsDragging)
		{
			if (!input.PointerValid)
			{
				FinishDrag(); // pointer lost mid drag
				return true;
			}
			if (input.LeftDown)
				UpdateDrag(input);
			if (input.LeftReleased || !input.LeftDown)
				FinishDrag();
			return true;
		}

		if (!input.PointerValid)
		{
			mGizmo.ClearHover();
			return false;
		}

		mGizmo.UpdateHover(input.Ray, mMode);
		if (input.LeftPressed && (mGizmo.Hovered != .None) && mGizmo.BeginDrag(input.Ray, mMode))
		{
			mDragEntity = primary;
			mDragStartLocal = scene.GetLocalTransform(entity);

			let parent = scene.GetParent(entity);
			mParentInverseWorld = .Identity();
			mParentRotation = .Identity;
			if (parent.IsAssigned)
			{
				let parentWorld = scene.ComposeWorldMatrix(parent);
				mParentInverseWorld = Inverse(parentWorld);
				Float3 t = ?, s = ?;
				Quaternion r = ?;
				if (Decompose(parentWorld, out t, out r, out s))
					mParentRotation = r;
			}

			mEdit.Commands.BeginGroup("gizmo_drag");
			mInGroup = true;
			return true;
		}
		return mGizmo.Hovered != .None;
	}

	public void Draw(DebugDraw dd)
	{
		if (!mActive)
			return;
		mGizmo.Draw(dd, mMode);
		if (mSnapTarget.HasValue)
		{
			// The vertex the pivot sits on, seen through whatever is in front of it.
			let mark = Color(1.0f, 0.85f, 0.2f, 1.0f);
			dd.DrawWireSphereOverlay(mSnapTarget.Value, mGizmo.Size * 0.05f, mark, 16);
			dd.DrawCross(mSnapTarget.Value, mGizmo.Size * 0.08f, mark, true);
		}
	}

	/// The vertex under `ray` to snap the dragged entity onto: on any drawn surface but the
	/// dragged entity's own and its descendants'.
	private Float3? FindSnapVertex(GizmoRay ray, EntityHandle dragged)
	{
		let scene = mEdit.Scene;
		// Never onto itself: the dragged entity and everything under it move with the drag.
		delegate bool(EntityHandle entity) accept = scope [&] (candidate) =>
			{
				for (var e = candidate; e.IsAssigned; e = scene.GetParent(e))
				{
					if (e == dragged)
						return false;
				}
				return true;
			};
		if (!scene.RaycastSurface(ray.Origin, Normalized(ray.Direction), cSnapReach, accept, let hit))
			return null;
		return hit.Vertex;
	}

	public StringView StatusText
	{
		get
		{
			switch (mMode)
			{
			case .Translate:
				return (mSpace == .World)
					? "Move [World]  (W/E/R mode, X space, Ctrl snap, V vertex snap)"
					: "Move [Local]  (W/E/R mode, X space, Ctrl snap, V vertex snap)";
			case .Rotate:
				return (mSpace == .World)
					? "Rotate [World]  (W/E/R mode, X space, Ctrl snap)"
					: "Rotate [Local]  (W/E/R mode, X space, Ctrl snap)";
			default:
				return "Scale [Local]  (W/E/R mode, X space, Ctrl snap)";
			}
		}
	}

	/// Applies the drag so far as a local transform against the START: world deltas are
	/// brought into the parent's space, so a child of a rotated parent moves where the
	/// handle points.
	private void UpdateDrag(in GizmoFrameInput input)
	{
		let entity = mEdit.Resolve(mDragEntity);
		if (!entity.IsAssigned)
		{
			AbortDrag();
			return;
		}

		var t = mDragStartLocal;
		switch (mMode)
		{
		case .Translate:
			let worldDelta = mGizmo.UpdateTranslateDrag(input.Ray, input.Snap);
			t.Position = mDragStartLocal.Position
				+ TransformDirection(worldDelta, mParentInverseWorld);
			// Vertex snap: the pivot ON the vertex under the cursor, whichever handle is held;
			// over no surface, the drag as it is.
			mSnapTarget = (input.VertexSnap || mVertexSnapMode) ? FindSnapVertex(input.Ray, entity) : null;
			if (mSnapTarget.HasValue)
				t.Position = TransformPoint(mSnapTarget.Value, mParentInverseWorld);
		case .Rotate:
			let d = mGizmo.UpdateRotateDrag(input.Ray, input.Snap);
			let worldDelta = Quaternion.FromAxisAngle(d.Axis, d.Angle);
			t.Rotation = Normalized(Inverse(mParentRotation) * worldDelta * mParentRotation
				* mDragStartLocal.Rotation);
		case .Scale:
			let d = mGizmo.UpdateScaleDrag(input.Ray, input.Snap);
			t.Scale.X = Max(mDragStartLocal.Scale.X + d.X, 0.001f);
			t.Scale.Y = Max(mDragStartLocal.Scale.Y + d.Y, 0.001f);
			t.Scale.Z = Max(mDragStartLocal.Scale.Z + d.Z, 0.001f);
		}
		mEdit.SetLocalTransform(mDragEntity, t);
	}

	private void FinishDrag()
	{
		mGizmo.EndDrag();
		mSnapTarget = null;
		if (mInGroup)
		{
			mEdit.Commands.EndGroup();
			mEdit.Commands.LockGroup(); // the next drag is its own undo entry
			mInGroup = false;
		}
		mDragEntity = .();
	}

	private void AbortDrag()
	{
		if (mGizmo.IsDragging)
			FinishDrag();
	}
}
