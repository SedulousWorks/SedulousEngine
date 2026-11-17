using System;
using System.Collections;
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

	/// A drag's target: a selection root as it was when the drag began, with its parent's frame, so
	/// world deltas convert into its parent's space.
	private struct DragTarget
	{
		public Guid Entity;
		public Transform StartLocal;
		public Float4x4 ParentInverseWorld = .Identity();
		public Quaternion ParentRotation = .Identity;

		public this(Guid entity, Transform startLocal)
		{
			Entity = entity;
			StartLocal = startLocal;
		}
	}
	/// Every selection root (the primary first) the drag moves.
	private List<DragTarget> mDragTargets = new .() ~ delete _;
	private bool mVertexSnapMode = false;
	private bool mHandlesShown = true;
	private bool mSnapMode = false;
	private bool mMoveSnapsToGrid = false;
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

	/// Whether the handles show (off: Select, where a click only picks; the mode stays for when
	/// they show again).
	public bool HandlesShown => mHandlesShown;

	public void SetHandlesShown(bool shown)
	{
		if (!mGizmo.IsDragging)
			mHandlesShown = shown;
	}

	/// Every drag snaps to the increments while on (the bar's Snap), as holding Ctrl does for one.
	public bool SnapMode
	{
		get => mSnapMode;
		set => mSnapMode = value;
	}

	/// A move snaps by the grid's cell where the camera is (the page sets the gizmo's
	/// TranslateSnap to it each frame) rather than by its own increment.
	public bool MoveSnapsToGrid
	{
		get => mMoveSnapsToGrid;
		set => mMoveSnapsToGrid = value;
	}

	/// The vertex a vertex snapping drag holds the pivot on this frame (world); none when not
	/// snapping, or when the cursor is over no surface.
	public Float3? SnapTarget => mSnapTarget;

	/// Mode and space changes wait for a drag to finish, so the frame it measures against
	/// never changes under it. A mode is chosen to transform with it: its handles show.
	public void SetMode(GizmoMode mode)
	{
		if (!mGizmo.IsDragging)
		{
			mMode = mode;
			mHandlesShown = true;
		}
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
			if (input.KeySelect)
				SetHandlesShown(false);
			if (input.KeyTranslate)
				SetMode(.Translate);
			if (input.KeyRotate)
				SetMode(.Rotate);
			if (input.KeyScale)
				SetMode(.Scale);
			if (input.KeyToggleSpace)
				mSpace = (mSpace == .World) ? .Local : .World;
		}

		let selection = mEdit.EntitySelection;
		let primary = selection.IsEmpty ? Guid() : selection.Primary;
		let entity = (selection.IsEmpty || !mHandlesShown) ? EntityHandle.Invalid : mEdit.Resolve(primary);
		if (!entity.IsAssigned)
		{
			AbortDrag();
			mActive = false;
			return false;
		}

		let scene = mEdit.Scene;
		mGizmo.SetCamera(input.CameraPosition, input.CameraForward, input.OrthoHeight > 0.0f);

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
			input.FovY, mGizmo.Position, 0.3f, input.OrthoHeight);
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
			// Every selection root moves (an entity under a selected one moves with it); parent
			// frames captured once, so world deltas convert into each parent's space.
			mDragTargets.Clear();
			let roots = scope List<Guid>();
			mEdit.SelectionRoots(roots);
			for (let id in roots)
			{
				let e = mEdit.Resolve(id);
				var target = DragTarget(id, scene.GetLocalTransform(e));
				let parent = scene.GetParent(e);
				if (parent.IsAssigned)
				{
					let parentWorld = scene.ComposeWorldMatrix(parent);
					target.ParentInverseWorld = Inverse(parentWorld);
					Float3 t = ?, s = ?;
					Quaternion r = ?;
					if (Decompose(parentWorld, out t, out r, out s))
						target.ParentRotation = r;
				}
				mDragTargets.Add(target);
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

	/// The vertex under `ray` to snap the dragged entities onto: on any drawn surface but theirs and
	/// their descendants'.
	private Float3? FindSnapVertex(GizmoRay ray)
	{
		let scene = mEdit.Scene;
		// Never onto what moves: the dragged entities and everything under them.
		delegate bool(EntityHandle entity) accept = scope [&] (candidate) =>
			{
				for (var e = candidate; e.IsAssigned; e = scene.GetParent(e))
				{
					let id = scene.GetEntityId(e);
					for (let target in mDragTargets)
					{
						if (target.Entity == id)
							return false;
					}
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
			if (!mHandlesShown)
				return "Select  (Q select, W/E/R transform, Ctrl+click toggle, drag to box select)";
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

	/// Applies the drag so far to every target as a local transform against its START: world deltas
	/// are brought into each parent's space, so a child of a rotated parent moves where the handle
	/// points, and each rotates and scales about its own pivot.
	private void UpdateDrag(in GizmoFrameInput input)
	{
		if (mDragTargets.IsEmpty || !mEdit.Resolve(mDragTargets[0].Entity).IsAssigned)
		{
			AbortDrag();
			return;
		}

		let snap = input.Snap || mSnapMode;
		// The handle's delta, once per frame, applied to every target.
		var worldDelta = Float3(0.0f, 0.0f, 0.0f);
		var worldRotation = Quaternion.Identity;
		var scaleDelta = Float3(0.0f, 0.0f, 0.0f);
		switch (mMode)
		{
		case .Translate:
			worldDelta = mGizmo.UpdateTranslateDrag(input.Ray, snap);
			// Vertex snap: the primary's pivot ON the vertex under the cursor, whichever handle is
			// held, the others keeping their offsets; over no surface, the drag as it is.
			mSnapTarget = (input.VertexSnap || mVertexSnapMode) ? FindSnapVertex(input.Ray) : null;
			if (mSnapTarget.HasValue)
			{
				let primary = mDragTargets[0];
				let parentWorld = Inverse(primary.ParentInverseWorld);
				worldDelta = mSnapTarget.Value - TransformPoint(primary.StartLocal.Position, parentWorld);
			}
		case .Rotate:
			let d = mGizmo.UpdateRotateDrag(input.Ray, snap);
			worldRotation = Quaternion.FromAxisAngle(d.Axis, d.Angle);
		case .Scale:
			scaleDelta = mGizmo.UpdateScaleDrag(input.Ray, snap);
		}

		for (let target in mDragTargets)
		{
			if (!mEdit.Resolve(target.Entity).IsAssigned)
				continue;
			var t = target.StartLocal;
			switch (mMode)
			{
			case .Translate:
				t.Position = target.StartLocal.Position + TransformDirection(worldDelta, target.ParentInverseWorld);
			case .Rotate:
				// Each about its own pivot: the world delta conjugated into its parent's space.
				t.Rotation = Normalized(Inverse(target.ParentRotation) * worldRotation * target.ParentRotation
					* target.StartLocal.Rotation);
			case .Scale:
				t.Scale = .(Scaled(target.StartLocal.Scale.X, scaleDelta.X), Scaled(target.StartLocal.Scale.Y, scaleDelta.Y),
					Scaled(target.StartLocal.Scale.Z, scaleDelta.Z));
			}
			mEdit.SetLocalTransform(target.Entity, t);
		}
	}

	/// A scale grown or shrunk in magnitude, its sign kept: a mirrored entity stays mirrored (clamping
	/// the value itself to 0.001 flipped it on the first frame of a drag).
	private static float Scaled(float start, float delta)
	{
		let sign = (start < 0.0f) ? -1.0f : 1.0f;
		return sign * Max(Math.Abs(start) + delta, 0.001f);
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
		mDragTargets.Clear();
	}

	private void AbortDrag()
	{
		if (mGizmo.IsDragging)
			FinishDrag();
	}
}
