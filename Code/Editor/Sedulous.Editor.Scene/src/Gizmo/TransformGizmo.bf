using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Editor.Scene;

/// The transform gizmo's geometry and interaction: hover picking, drags along an axis, on a
/// plane, about a ring or in the view plane, and the debug drawn handles.
///
/// Pure over a ray and a camera: it knows nothing of scenes or commands. The controller
/// drives it and turns its deltas into transform edits. Drawing lives in the extension
/// file alongside.
class TransformGizmo
{
	public Float3 Position = .Zero;
	public Quaternion Orientation = .Identity;
	public float Size = 1.0f;

	public float TranslateSnap = 1.0f;
	public float RotateSnapDegrees = 15.0f;
	public float ScaleSnap = 0.25f;

	protected Float3 mCameraPos = .Zero;
	protected Float3 mCameraForward = .(0, 0, -1);

	protected GizmoAxis mHovered = .None;
	protected GizmoAxis mSelected = .None;
	protected bool mDragging = false;

	protected Float3 mDragStartPosition = .Zero;
	protected Float3 mDragStartHitPoint = .Zero;
	protected float mDragStartAngle = 0.0f;
	protected float mCurrentAngleDelta = 0.0f;
	protected Float3 mDragRotationAxis = .Zero;
	protected Float3 mDragRotationU = .Zero;
	protected Float3 mDragRotationV = .Zero;

	public GizmoAxis Hovered => mHovered;
	public GizmoAxis Selected => mSelected;
	public bool IsDragging => mDragging;

	public void SetCamera(Float3 cameraPosition, Float3 cameraForward)
	{
		mCameraPos = cameraPosition;
		mCameraForward = Normalized(cameraForward);
	}

	/// The world size that keeps the gizmo a constant fraction of the view at `point`'s
	/// depth; zero or negative at or behind the camera plane.
	public static float ScreenScale(Float3 cameraPos, Float3 cameraForward, float fovY,
		Float3 point, float ratio = 0.3f)
	{
		let depth = Dot(point - cameraPos, Normalized(cameraForward));
		return Tan(fovY * 0.5f) * depth * ratio;
	}

	/// The world direction of an axis, or of a plane's normal, in the gizmo's orientation.
	public Float3 AxisDirection(GizmoAxis axis)
	{
		switch (axis)
		{
		case .X, .PlaneX: return RotateVector(Orientation, Float3(1, 0, 0));
		case .Y, .PlaneY: return RotateVector(Orientation, Float3(0, 1, 0));
		case .Z, .PlaneZ: return RotateVector(Orientation, Float3(0, 0, 1));
		default: return .Zero;
		}
	}

	/// An axis seen end-on, or a plane seen edge-on, cannot be dragged and is faded.
	public bool IsAxisEnabled(GizmoAxis axis, GizmoMode mode)
	{
		let viewDir = ViewDir;
		switch (axis)
		{
		case .X, .Y, .Z:
			if (mode == .Rotate)
				return true; // rings stay pickable
			return 1.0f - Abs(Dot(AxisDirection(axis), viewDir)) > 0.01f;
		case .PlaneX, .PlaneY, .PlaneZ:
			return Abs(Dot(AxisDirection(axis), viewDir)) > 0.05f;
		default:
			return true;
		}
	}

	/// Picks the handle under the ray: planes beat axes, the centre beats both, and among
	/// equals the nearest wins. Unchanged during a drag.
	public GizmoAxis UpdateHover(GizmoRay ray, GizmoMode mode)
	{
		if (mDragging)
			return mHovered;
		mHovered = .None;

		var best = HoverCandidate();

		let axisThreshold = Size * 0.12f; // inflated against the drawn ribbon
		if (mode == .Rotate)
		{
			let radius = Size * 0.8f;
			for (let a in scope GizmoAxis[](.X, .Y, .Z))
			{
				Float3 hit = ?;
				let d = RayRingDistance(ray, Position, AxisDirection(a), radius, out hit);
				// The back half of a ring is culled from drawing, so it is not pickable.
				if ((d < FloatMax) && (Dot(hit - Position, ViewDir) > 0.0f))
					continue;
				Consider(ref best, a, 0, d, axisThreshold);
			}
			Float3 unused = ?;
			let dv = RayRingDistance(ray, Position, mCameraForward, Size * 1.0f, out unused);
			Consider(ref best, .View, 1, dv, axisThreshold);
			return mHovered;
		}

		for (let a in scope GizmoAxis[](.X, .Y, .Z))
		{
			if (!IsAxisEnabled(a, mode))
				continue;
			let dist = RayAxisDistance(ray, Position, AxisDirection(a), Size);
			let penalty = Abs(Dot(ray.Direction, AxisDirection(a))) * axisThreshold * 0.5f;
			Consider(ref best, a, 0, dist + penalty, axisThreshold);
		}
		if (mode == .Translate)
		{
			for (let p in scope GizmoAxis[](.PlaneX, .PlaneY, .PlaneZ))
			{
				if (!IsAxisEnabled(p, mode))
					continue;
				Float3 unused = ?;
				if (PlaneQuadHit(ray, p, out unused))
					Consider(ref best, p, 1, 0.0f, 1.0f);
			}
		}
		let dc = RayPointDistance(ray, Position);
		Consider(ref best, .View, 2, dc, Size * 0.15f);
		return mHovered;
	}

	/// The best hover so far: a higher priority wins, then the nearer distance.
	private struct HoverCandidate
	{
		public int Priority = -1;
		public float Distance = FloatMax;
		public this() {}
	}

	private void Consider(ref HoverCandidate best, GizmoAxis axis, int priority, float dist,
		float threshold)
	{
		if (dist >= threshold)
			return;
		if ((priority > best.Priority) || ((priority == best.Priority) && (dist < best.Distance)))
		{
			best.Priority = priority;
			best.Distance = dist;
			mHovered = axis;
		}
	}

	/// Starts a drag on the hovered handle, capturing the frame the drag measures against.
	public bool BeginDrag(GizmoRay ray, GizmoMode mode)
	{
		if (mHovered == .None)
			return false;
		mSelected = mHovered;
		mDragging = true;
		mDragStartPosition = Position;

		if (mode == .Rotate)
		{
			if (mSelected == .View)
			{
				mDragRotationAxis = mCameraForward;
				mDragRotationU = CameraRight;
				mDragRotationV = Cross(CameraRight, mCameraForward);
			}
			else
			{
				mDragRotationAxis = AxisDirection(mSelected);
				switch (mSelected)
				{
				case .X:
					mDragRotationU = AxisDirection(.Y);
					mDragRotationV = AxisDirection(.Z);
				case .Y:
					mDragRotationU = AxisDirection(.Z);
					mDragRotationV = AxisDirection(.X);
				default:
					mDragRotationU = AxisDirection(.X);
					mDragRotationV = AxisDirection(.Y);
				}
			}
			mDragStartAngle = ComputeRotateAngle(ray, mDragStartPosition, mDragRotationAxis,
				mDragRotationU, mDragRotationV);
			mCurrentAngleDelta = 0.0f;
		}
		else
		{
			mDragStartHitPoint = DragHitPoint(ray, mSelected, mDragStartPosition);
		}
		return true;
	}

	/// The world translation since the drag began, constrained to the handle.
	public Float3 UpdateTranslateDrag(GizmoRay ray, bool snap = false)
	{
		if (!mDragging || (mSelected == .None))
			return .Zero;
		let delta = DragHitPoint(ray, mSelected, mDragStartPosition) - mDragStartHitPoint;
		let increment = snap ? TranslateSnap : 0.0f;

		switch (mSelected)
		{
		case .X, .Y, .Z:
			let axis = AxisDirection(mSelected);
			return axis * Snap(Dot(delta, axis), increment);
		case .PlaneX, .PlaneY, .PlaneZ:
			Float3 u = ?, v = ?;
			PlaneBasis(mSelected, out u, out v);
			return u * Snap(Dot(delta, u), increment) + v * Snap(Dot(delta, v), increment);
		case .View:
			let r = CameraRight;
			let up = Cross(r, mCameraForward);
			return r * Snap(Dot(delta, r), increment) + up * Snap(Dot(delta, up), increment);
		default:
			return .Zero;
		}
	}

	/// The angle turned since the drag began, unwrapped across the seam so a ring drag is
	/// continuous through 180 degrees.
	public RotateDelta UpdateRotateDrag(GizmoRay ray, bool snap = false)
	{
		if (!mDragging || (mSelected == .None))
			return .();
		let current = ComputeRotateAngle(ray, mDragStartPosition, mDragRotationAxis,
			mDragRotationU, mDragRotationV);
		var delta = current - mDragStartAngle;
		if (delta > Pi)
			delta -= TwoPi;
		if (delta < -Pi)
			delta += TwoPi;
		delta = Snap(delta, snap ? DegreesToRadians(RotateSnapDegrees) : 0.0f);
		mCurrentAngleDelta = delta; // the angle guide's readout
		return .(mDragRotationAxis, delta);
	}

	/// The per axis scale change since the drag began, in units of the gizmo's size; the
	/// centre handle scales uniformly.
	public Float3 UpdateScaleDrag(GizmoRay ray, bool snap = false)
	{
		if (!mDragging || (mSelected == .None))
			return .Zero;
		let delta = DragHitPoint(ray, mSelected, mDragStartPosition) - mDragStartHitPoint;
		let increment = snap ? ScaleSnap : 0.0f;

		if (mSelected == .View)
		{
			let r = CameraRight;
			let up = Cross(r, mCameraForward);
			let s = Snap(Dot(delta, Normalized(r + up)) / Size, increment);
			return .(s, s, s);
		}

		let axis = AxisDirection(mSelected);
		let s = Snap(Dot(delta, axis) / Size, increment);
		switch (mSelected)
		{
		case .X: return .(s, 0, 0);
		case .Y: return .(0, s, 0);
		case .Z: return .(0, 0, s);
		default: return .Zero;
		}
	}

	public void EndDrag()
	{
		mDragging = false;
		mSelected = .None;
	}

	public void ClearHover()
	{
		if (!mDragging)
			mHovered = .None;
	}

	// ---- ray geometry ----

	/// The closest distance between a ray and an axis segment of `axisLength` from its origin.
	public static float RayAxisDistance(GizmoRay ray, Float3 axisOrigin, Float3 axisDir,
		float axisLength)
	{
		let d1 = ray.Direction;
		let d2 = axisDir;
		let r = ray.Origin - axisOrigin;
		let a = Dot(d1, d1);
		let b = Dot(d1, d2);
		let c = Dot(d2, d2);
		let d = Dot(d1, r);
		let e = Dot(d2, r);
		let denom = a * c - b * b;

		float t1, t2;
		if (Abs(denom) < 0.0001f)
		{
			t1 = 0.0f;
			t2 = e / c;
		}
		else
		{
			t1 = (b * e - c * d) / denom;
			t2 = (a * e - b * d) / denom;
		}
		t2 = Clamp(t2 / axisLength, 0.0f, 1.0f) * axisLength;
		t1 = Max(t1, 0.0f);
		return Distance(ray.Origin + d1 * t1, axisOrigin + d2 * t2);
	}

	/// The distance from where the ray crosses a ring's plane to the ring itself, with the
	/// crossing point in `outHit`; FloatMax when the plane is behind the ray.
	public static float RayRingDistance(GizmoRay ray, Float3 center, Float3 normal,
		float radius, out Float3 outHit)
	{
		outHit = center;
		let denom = Dot(normal, ray.Direction);
		if (Abs(denom) < 0.0001f)
		{
			// Edge on: measure from the ray's closest approach to the centre.
			let t = Max(Dot(center - ray.Origin, ray.Direction), 0.0f);
			let offset = ray.Origin + ray.Direction * t - center;
			let h = Dot(offset, normal);
			let inPlane = offset - normal * h;
			let dr = Length(inPlane) - radius;
			return Sqrt(h * h + dr * dr);
		}
		let t = Dot(normal, center - ray.Origin) / denom;
		if (t < 0.0f)
			return FloatMax;
		let hit = ray.Origin + ray.Direction * t;
		outHit = hit;
		return Abs(Length(hit - center) - radius);
	}

	public static float RayPointDistance(GizmoRay ray, Float3 point)
	{
		let t = Max(Dot(point - ray.Origin, ray.Direction), 0.0f);
		return Distance(ray.Origin + ray.Direction * t, point);
	}

	// ---- frames ----

	protected Float3 ViewDir => Normalized(Position - mCameraPos);

	protected Float3 CameraRight
	{
		get
		{
			let worldUp = (Abs(mCameraForward.Y) < 0.99f) ? Float3(0, 1, 0) : Float3(1, 0, 0);
			return Normalized(Cross(mCameraForward, worldUp));
		}
	}

	protected static float Snap(float value, float increment)
	{
		if (increment <= 0.0f)
			return value;
		return Round(value / increment) * increment;
	}

	protected void PlaneBasis(GizmoAxis plane, out Float3 u, out Float3 v)
	{
		switch (plane)
		{
		case .PlaneX:
			u = AxisDirection(.Y);
			v = AxisDirection(.Z);
		case .PlaneY:
			u = AxisDirection(.X);
			v = AxisDirection(.Z);
		default:
			u = AxisDirection(.X);
			v = AxisDirection(.Y);
		}
	}

	/// Which quadrant a plane's quad sits in: the one facing the camera.
	protected void PlaneQuadSigns(GizmoAxis plane, out float su, out float sv)
	{
		Float3 u = ?, v = ?;
		PlaneBasis(plane, out u, out v);
		let toCam = mCameraPos - Position;
		su = (Dot(u, toCam) >= 0.0f) ? 1.0f : -1.0f;
		sv = (Dot(v, toCam) >= 0.0f) ? 1.0f : -1.0f;
	}

	protected bool PlaneQuadHit(GizmoRay ray, GizmoAxis plane, out Float3 outHit)
	{
		outHit = Position;
		let normal = AxisDirection(plane);
		let denom = Dot(normal, ray.Direction);
		if (Abs(denom) < 0.0001f)
			return false;
		let t = Dot(normal, Position - ray.Origin) / denom;
		if (t < 0.0f)
			return false;
		let hit = ray.Origin + ray.Direction * t;
		outHit = hit;

		Float3 u = ?, v = ?;
		float su = ?, sv = ?;
		PlaneBasis(plane, out u, out v);
		PlaneQuadSigns(plane, out su, out sv);
		let offset = hit - Position;
		let cu = Dot(offset, u) * su;
		let cv = Dot(offset, v) * sv;
		return (cu >= Size * 0.25f) && (cu <= Size * 0.55f) && (cv >= Size * 0.25f)
			&& (cv <= Size * 0.55f);
	}

	/// Where the ray meets the drag plane for a handle: for an axis, whichever of the two
	/// planes containing it faces the ray more squarely.
	protected Float3 DragHitPoint(GizmoRay ray, GizmoAxis axis, Float3 planeOrigin)
	{
		Float3 planeNormal;
		switch (axis)
		{
		case .X, .Y, .Z:
			Float3 otherA, otherB;
			switch (axis)
			{
			case .X:
				otherA = AxisDirection(.Y);
				otherB = AxisDirection(.Z);
			case .Y:
				otherA = AxisDirection(.X);
				otherB = AxisDirection(.Z);
			default:
				otherA = AxisDirection(.X);
				otherB = AxisDirection(.Y);
			}
			planeNormal = (Abs(Dot(ray.Direction, otherA)) > Abs(Dot(ray.Direction, otherB)))
				? otherA : otherB;
		case .PlaneX, .PlaneY, .PlaneZ:
			planeNormal = AxisDirection(axis);
		default:
			planeNormal = mCameraForward;
		}

		let denom = Dot(planeNormal, ray.Direction);
		if (Abs(denom) < 0.0001f)
			return planeOrigin;
		let t = Dot(planeNormal, planeOrigin - ray.Origin) / denom;
		return ray.Origin + ray.Direction * t;
	}

	protected static float ComputeRotateAngle(GizmoRay ray, Float3 center, Float3 normal,
		Float3 u, Float3 v)
	{
		let denom = Dot(normal, ray.Direction);
		if (Abs(denom) < 0.0001f)
			return 0.0f;
		var t = Dot(normal, center - ray.Origin) / denom;
		if (t < 0.0f)
			t = -t; // reversed ray retry
		let offset = ray.Origin + ray.Direction * t - center;
		return Atan2(Dot(offset, v), Dot(offset, u));
	}
}
