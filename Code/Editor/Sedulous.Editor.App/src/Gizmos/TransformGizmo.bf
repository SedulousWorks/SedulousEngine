namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Renderer.Debug;
using Sedulous.Editor.Core;

/// Axis or plane selection for the gizmo.
enum GizmoAxis
{
	None,
	X, Y, Z
}

/// 3D transform gizmo for moving/rotating/scaling entities.
/// Renders via DebugDraw overlay (no depth test).
class TransformGizmo
{
	// State
	public Vector3 Position = .Zero;
	public Quaternion Orientation = .Identity;
	public float Size = 1.0f;
	public GizmoAxis HoveredAxis = .None;
	public GizmoAxis SelectedAxis = .None;
	public bool IsDragging = false;

	// Drag state
	private Vector3 mDragStartPosition;
	private Vector3 mDragStartHitPoint;
	private float mDragStartAngle;  // for rotate
	private float mDragStartScale;  // for scale

	// Colors
	private static readonly Color sColorX = .(220, 50, 50, 255);
	private static readonly Color sColorY = .(50, 220, 50, 255);
	private static readonly Color sColorZ = .(50, 100, 220, 255);
	private static readonly Color sColorXHover = .(255, 150, 150, 255);
	private static readonly Color sColorYHover = .(150, 255, 150, 255);
	private static readonly Color sColorZHover = .(150, 180, 255, 255);
	private static readonly Color sColorSelected = .(255, 255, 100, 255);

	/// Creates a pick ray from screen coordinates through the camera.
	public static Ray CreatePickRay(float screenX, float screenY, uint32 width, uint32 height,
		Matrix viewMatrix, Matrix projMatrix)
	{
		float ndcX = (2.0f * screenX / (float)width) - 1.0f;
		float ndcY = 1.0f - (2.0f * screenY / (float)height);

		Vector4 nearPoint = .(ndcX, ndcY, 0.0f, 1.0f);
		Vector4 farPoint = .(ndcX, ndcY, 1.0f, 1.0f);

		Matrix invViewProj;
		if (!Matrix.TryInvert(viewMatrix * projMatrix, out invViewProj))
			return .(.(0, 0, 0), .(0, 0, -1));

		var nearWorld = Vector4.Transform(nearPoint, invViewProj);
		var farWorld = Vector4.Transform(farPoint, invViewProj);

		if (Math.Abs(nearWorld.W) < 0.0001f || Math.Abs(farWorld.W) < 0.0001f)
			return .(.(0, 0, 0), .(0, 0, -1));

		nearWorld /= nearWorld.W;
		farWorld /= farWorld.W;

		let position = Vector3(nearWorld.X, nearWorld.Y, nearWorld.Z);
		let dir = Vector3(farWorld.X, farWorld.Y, farWorld.Z) - position;

		let lenSq = dir.LengthSquared();
		if (lenSq < 0.0001f)
			return .(position, .(0, 0, -1));

		return .(position, dir / Math.Sqrt(lenSq));
	}

	// ==================== Oriented Axes ====================

	/// Gets the X/Y/Z axis direction based on current orientation.
	public Vector3 GetAxisDirection(GizmoAxis axis)
	{
		switch (axis)
		{
		case .X: return Vector3.Transform(.(1, 0, 0), Orientation);
		case .Y: return Vector3.Transform(.(0, 1, 0), Orientation);
		case .Z: return Vector3.Transform(.(0, 0, 1), Orientation);
		default: return .Zero;
		}
	}

	private Vector3 AxisX => Vector3.Transform(.(1, 0, 0), Orientation);
	private Vector3 AxisY => Vector3.Transform(.(0, 1, 0), Orientation);
	private Vector3 AxisZ => Vector3.Transform(.(0, 0, 1), Orientation);

	// ==================== Hover Detection ====================

	/// Updates hover state based on gizmo mode.
	public GizmoAxis UpdateHover(Ray pickRay, GizmoMode mode, float pickThreshold = 0.15f)
	{
		if (IsDragging)
			return HoveredAxis;

		HoveredAxis = .None;

		switch (mode)
		{
		case .Translate, .Scale:
			// Both use axis lines for hover detection
			HoveredAxis = HoverAxisLines(pickRay, pickThreshold);
		case .Rotate:
			// Test ring proximity
			HoveredAxis = HoverRings(pickRay, pickThreshold);
		}

		return HoveredAxis;
	}

	/// Hover test against axis line segments (for translate/scale).
	private GizmoAxis HoverAxisLines(Ray pickRay, float threshold)
	{
		GizmoAxis best = .None;
		float closestDist = float.MaxValue;

		float distX = RayAxisDistance(pickRay, Position, AxisX, Size);
		if (distX < threshold && distX < closestDist) { closestDist = distX; best = .X; }

		float distY = RayAxisDistance(pickRay, Position, AxisY, Size);
		if (distY < threshold && distY < closestDist) { closestDist = distY; best = .Y; }

		float distZ = RayAxisDistance(pickRay, Position, AxisZ, Size);
		if (distZ < threshold && distZ < closestDist) { closestDist = distZ; best = .Z; }

		return best;
	}

	/// Hover test against rotation rings.
	private GizmoAxis HoverRings(Ray pickRay, float threshold)
	{
		let radius = Size * 0.8f;
		GizmoAxis best = .None;
		float closestDist = float.MaxValue;

		// X ring: plane normal = oriented X axis
		float distX = RayRingDistance(pickRay, Position, AxisX, radius);
		if (distX < threshold && distX < closestDist) { closestDist = distX; best = .X; }

		// Y ring: plane normal = oriented Y axis
		float distY = RayRingDistance(pickRay, Position, AxisY, radius);
		if (distY < threshold && distY < closestDist) { closestDist = distY; best = .Y; }

		// Z ring: plane normal = oriented Z axis
		float distZ = RayRingDistance(pickRay, Position, AxisZ, radius);
		if (distZ < threshold && distZ < closestDist) { closestDist = distZ; best = .Z; }

		return best;
	}

	// ==================== Drag ====================

	/// Begins dragging on the hovered axis.
	public bool BeginDrag(Ray pickRay, GizmoMode mode)
	{
		if (HoveredAxis == .None)
			return false;

		SelectedAxis = HoveredAxis;
		IsDragging = true;
		mDragStartPosition = Position;
		mDragStartHitPoint = GetOrientedDragHitPoint(pickRay, SelectedAxis, mDragStartPosition);

		if (mode == .Rotate)
			mDragStartAngle = GetOrientedRotateAngle(pickRay, SelectedAxis, mDragStartPosition);

		return true;
	}

	/// Updates translate drag and returns position delta.
	public Vector3 UpdateTranslateDrag(Ray pickRay)
	{
		if (!IsDragging || SelectedAxis == .None)
			return .Zero;

		let currentHitPoint = GetOrientedDragHitPoint(pickRay, SelectedAxis, mDragStartPosition);
		let delta = currentHitPoint - mDragStartHitPoint;

		// Project delta onto the oriented axis direction
		let axisDir = GetAxisDirection(SelectedAxis);
		return axisDir * Vector3.Dot(delta, axisDir);
	}

	/// Updates rotate drag and returns the rotation axis and angle delta.
	public (Vector3 axis, float angle) UpdateRotateDrag(Ray pickRay)
	{
		if (!IsDragging || SelectedAxis == .None)
			return (.Zero, 0);

		let currentAngle = GetOrientedRotateAngle(pickRay, SelectedAxis, mDragStartPosition);
		let axisDir = GetAxisDirection(SelectedAxis);
		return (axisDir, currentAngle - mDragStartAngle);
	}

	/// Updates scale drag and returns scale delta along the selected local axis.
	/// Returns a Vector3 where only the selected axis component is non-zero.
	public Vector3 UpdateScaleDrag(Ray pickRay)
	{
		if (!IsDragging || SelectedAxis == .None)
			return .Zero;

		let currentHitPoint = GetOrientedDragHitPoint(pickRay, SelectedAxis, mDragStartPosition);
		let delta = currentHitPoint - mDragStartHitPoint;

		// Project delta onto the oriented axis, scale relative to gizmo size
		let axisDir = GetAxisDirection(SelectedAxis);
		let axisDelta = Vector3.Dot(delta, axisDir) / Size;

		// Return in local axis space (X/Y/Z component only)
		Vector3 scaleDelta = .Zero;
		switch (SelectedAxis)
		{
		case .X: scaleDelta.X = axisDelta;
		case .Y: scaleDelta.Y = axisDelta;
		case .Z: scaleDelta.Z = axisDelta;
		default:
		}
		return scaleDelta;
	}

	/// Ends the drag.
	public void EndDrag()
	{
		IsDragging = false;
		SelectedAxis = .None;
	}

	// ==================== Drawing ====================

	/// Draws the translate gizmo using DebugDraw overlay lines.
	public void DrawTranslate(DebugDraw debugDraw)
	{
		let axisLen = Size;
		let headSize = Size * 0.1f;
		let ax = AxisX;
		let ay = AxisY;
		let az = AxisZ;

		// X axis (red)
		let xColor = GetAxisColor(.X);
		let xEnd = Position + ax * axisLen;
		debugDraw.DrawLineOverlay(Position, xEnd, xColor);
		debugDraw.DrawLineOverlay(xEnd, xEnd - ax * headSize + ay * headSize, xColor);
		debugDraw.DrawLineOverlay(xEnd, xEnd - ax * headSize - ay * headSize, xColor);

		// Y axis (green)
		let yColor = GetAxisColor(.Y);
		let yEnd = Position + ay * axisLen;
		debugDraw.DrawLineOverlay(Position, yEnd, yColor);
		debugDraw.DrawLineOverlay(yEnd, yEnd + ax * headSize - ay * headSize, yColor);
		debugDraw.DrawLineOverlay(yEnd, yEnd - ax * headSize - ay * headSize, yColor);

		// Z axis (blue)
		let zColor = GetAxisColor(.Z);
		let zEnd = Position + az * axisLen;
		debugDraw.DrawLineOverlay(Position, zEnd, zColor);
		debugDraw.DrawLineOverlay(zEnd, zEnd + ay * headSize - az * headSize, zColor);
		debugDraw.DrawLineOverlay(zEnd, zEnd - ay * headSize - az * headSize, zColor);
	}

	/// Draws the scale gizmo using DebugDraw overlay lines.
	public void DrawScale(DebugDraw debugDraw)
	{
		let axisLen = Size;
		let boxSize = Size * 0.08f;

		debugDraw.DrawLineOverlay(Position, Position + AxisX * axisLen, GetAxisColor(.X));
		debugDraw.DrawLineOverlay(Position, Position + AxisY * axisLen, GetAxisColor(.Y));
		debugDraw.DrawLineOverlay(Position, Position + AxisZ * axisLen, GetAxisColor(.Z));

		DrawBoxOverlay(debugDraw, Position + AxisX * axisLen, boxSize, GetAxisColor(.X));
		DrawBoxOverlay(debugDraw, Position + AxisY * axisLen, boxSize, GetAxisColor(.Y));
		DrawBoxOverlay(debugDraw, Position + AxisZ * axisLen, boxSize, GetAxisColor(.Z));
	}

	/// Draws the rotate gizmo (three rings) using DebugDraw overlay lines.
	public void DrawRotate(DebugDraw debugDraw)
	{
		let radius = Size * 0.8f;
		let segments = 32;

		// X rotation ring (plane perpendicular to oriented X)
		debugDraw.DrawCircleOverlay(Position, AxisY, AxisZ, radius, GetAxisColor(.X), segments);
		// Y rotation ring (plane perpendicular to oriented Y)
		debugDraw.DrawCircleOverlay(Position, AxisX, AxisZ, radius, GetAxisColor(.Y), segments);
		// Z rotation ring (plane perpendicular to oriented Z)
		debugDraw.DrawCircleOverlay(Position, AxisX, AxisY, radius, GetAxisColor(.Z), segments);
	}

	/// Draws the gizmo based on the current mode.
	public void Draw(DebugDraw debugDraw, GizmoMode mode)
	{
		switch (mode)
		{
		case .Translate: DrawTranslate(debugDraw);
		case .Rotate: DrawRotate(debugDraw);
		case .Scale: DrawScale(debugDraw);
		}
	}

	// ==================== Helpers ====================

	private Color GetAxisColor(GizmoAxis axis)
	{
		if (SelectedAxis == axis) return sColorSelected;
		if (HoveredAxis == axis)
		{
			switch (axis)
			{
			case .X: return sColorXHover;
			case .Y: return sColorYHover;
			case .Z: return sColorZHover;
			default: return .White;
			}
		}
		switch (axis)
		{
		case .X: return sColorX;
		case .Y: return sColorY;
		case .Z: return sColorZ;
		default: return .White;
		}
	}

	private void DrawBoxOverlay(DebugDraw debugDraw, Vector3 center, float halfSize, Color color)
	{
		let min = center - .(halfSize, halfSize, halfSize);
		let max = center + .(halfSize, halfSize, halfSize);
		debugDraw.DrawLineOverlay(.(min.X, min.Y, min.Z), .(max.X, min.Y, min.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, min.Y, min.Z), .(max.X, min.Y, max.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, min.Y, max.Z), .(min.X, min.Y, max.Z), color);
		debugDraw.DrawLineOverlay(.(min.X, min.Y, max.Z), .(min.X, min.Y, min.Z), color);
		debugDraw.DrawLineOverlay(.(min.X, max.Y, min.Z), .(max.X, max.Y, min.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, max.Y, min.Z), .(max.X, max.Y, max.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, max.Y, max.Z), .(min.X, max.Y, max.Z), color);
		debugDraw.DrawLineOverlay(.(min.X, max.Y, max.Z), .(min.X, max.Y, min.Z), color);
		debugDraw.DrawLineOverlay(.(min.X, min.Y, min.Z), .(min.X, max.Y, min.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, min.Y, min.Z), .(max.X, max.Y, min.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, min.Y, max.Z), .(max.X, max.Y, max.Z), color);
		debugDraw.DrawLineOverlay(.(min.X, min.Y, max.Z), .(min.X, max.Y, max.Z), color);
	}

	// ==================== Math Utilities ====================

	/// Closest distance from a ray to an axis line segment.
	public static float RayAxisDistance(Ray ray, Vector3 axisOrigin, Vector3 axisDir, float axisLength)
	{
		let d1 = ray.Direction;
		let d2 = axisDir;
		let r = ray.Position - axisOrigin;

		let a = Vector3.Dot(d1, d1);
		let b = Vector3.Dot(d1, d2);
		let c = Vector3.Dot(d2, d2);
		let d = Vector3.Dot(d1, r);
		let e = Vector3.Dot(d2, r);

		let denom = a * c - b * b;

		float t1, t2;
		if (Math.Abs(denom) < 0.0001f)
		{
			t1 = 0;
			t2 = e / c;
		}
		else
		{
			t1 = (b * e - c * d) / denom;
			t2 = (a * e - b * d) / denom;
		}

		t2 = Math.Clamp(t2 / axisLength, 0.0f, 1.0f) * axisLength;
		t1 = Math.Max(t1, 0.0f);

		let p1 = ray.Position + d1 * t1;
		let p2 = axisOrigin + d2 * t2;

		return Vector3.Distance(p1, p2);
	}

	/// Distance from a ray to a ring (circle in 3D).
	/// Returns the closest distance from the ray to the ring circumference.
	public static float RayRingDistance(Ray ray, Vector3 center, Vector3 normal, float radius)
	{
		// Intersect ray with the ring's plane
		let denom = Vector3.Dot(normal, ray.Direction);
		if (Math.Abs(denom) < 0.0001f)
		{
			// Ray parallel to plane — check distance from ray to nearest ring point
			// Approximate: distance from ray origin to plane, projected
			let distToPlane = Math.Abs(Vector3.Dot(normal, ray.Position - center));
			return distToPlane; // rough approximation
		}

		let t = Vector3.Dot(normal, center - ray.Position) / denom;
		if (t < 0) return float.MaxValue; // ring behind camera

		let hitPoint = ray.Position + ray.Direction * t;
		let offset = hitPoint - center;
		let distFromCenter = offset.Length();

		// Distance from hit point to ring circumference
		return Math.Abs(distFromCenter - radius);
	}

	/// Gets the hit point on a drag plane using oriented axes.
	private Vector3 GetOrientedDragHitPoint(Ray ray, GizmoAxis axis, Vector3 planeOrigin)
	{
		let axisDir = GetAxisDirection(axis);

		// Pick a plane that contains the axis and is most perpendicular to the view
		// Use the two other oriented axes as candidates for the plane normal
		Vector3 otherA, otherB;
		switch (axis)
		{
		case .X: otherA = AxisY; otherB = AxisZ;
		case .Y: otherA = AxisX; otherB = AxisZ;
		case .Z: otherA = AxisX; otherB = AxisY;
		default: return planeOrigin;
		}

		// Choose the candidate more perpendicular to the view direction
		let planeNormal = (Math.Abs(Vector3.Dot(ray.Direction, otherA)) > Math.Abs(Vector3.Dot(ray.Direction, otherB)))
			? otherA : otherB;

		let denom = Vector3.Dot(planeNormal, ray.Direction);
		if (Math.Abs(denom) < 0.0001f)
			return planeOrigin;

		let t = Vector3.Dot(planeNormal, planeOrigin - ray.Position) / denom;
		return ray.Position + ray.Direction * t;
	}

	/// Gets the rotation angle around an oriented axis from a pick ray.
	private float GetOrientedRotateAngle(Ray ray, GizmoAxis axis, Vector3 center)
	{
		let normal = GetAxisDirection(axis);

		// Intersect ray with the rotation plane
		let denom = Vector3.Dot(normal, ray.Direction);
		if (Math.Abs(denom) < 0.0001f)
			return 0;

		let t = Vector3.Dot(normal, center - ray.Position) / denom;
		let hitPoint = ray.Position + ray.Direction * t;
		let offset = hitPoint - center;

		// Get two perpendicular axes in the plane for atan2
		Vector3 u, v;
		switch (axis)
		{
		case .X: u = AxisY; v = AxisZ;
		case .Y: u = AxisZ; v = AxisX;
		case .Z: u = AxisX; v = AxisY;
		default: return 0;
		}

		return (float)Math.Atan2(Vector3.Dot(offset, v), Vector3.Dot(offset, u));
	}
}
