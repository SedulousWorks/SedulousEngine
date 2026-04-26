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
	public float Size = 1.0f;
	public GizmoAxis HoveredAxis = .None;
	public GizmoAxis SelectedAxis = .None;
	public bool IsDragging = false;

	// Drag state
	private Vector3 mDragStartPosition;
	private Vector3 mDragStartHitPoint;

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

	/// Updates hover state from a pick ray.
	public GizmoAxis UpdateHover(Ray pickRay, float pickThreshold = 0.15f)
	{
		if (IsDragging)
			return HoveredAxis;

		HoveredAxis = .None;
		float closestDist = float.MaxValue;

		float distX = RayAxisDistance(pickRay, Position, .(1, 0, 0), Size);
		if (distX < pickThreshold && distX < closestDist) { closestDist = distX; HoveredAxis = .X; }

		float distY = RayAxisDistance(pickRay, Position, .(0, 1, 0), Size);
		if (distY < pickThreshold && distY < closestDist) { closestDist = distY; HoveredAxis = .Y; }

		float distZ = RayAxisDistance(pickRay, Position, .(0, 0, 1), Size);
		if (distZ < pickThreshold && distZ < closestDist) { closestDist = distZ; HoveredAxis = .Z; }

		return HoveredAxis;
	}

	/// Begins dragging on the hovered axis.
	public bool BeginDrag(Ray pickRay)
	{
		if (HoveredAxis == .None)
			return false;

		SelectedAxis = HoveredAxis;
		IsDragging = true;
		mDragStartPosition = Position;
		mDragStartHitPoint = GetDragHitPoint(pickRay, SelectedAxis, mDragStartPosition);
		return true;
	}

	/// Updates drag and returns position delta.
	public Vector3 UpdateDrag(Ray pickRay)
	{
		if (!IsDragging || SelectedAxis == .None)
			return .Zero;

		let currentHitPoint = GetDragHitPoint(pickRay, SelectedAxis, mDragStartPosition);
		let delta = currentHitPoint - mDragStartHitPoint;

		Vector3 constrainedDelta = .Zero;
		switch (SelectedAxis)
		{
		case .X: constrainedDelta.X = delta.X;
		case .Y: constrainedDelta.Y = delta.Y;
		case .Z: constrainedDelta.Z = delta.Z;
		default:
		}

		return constrainedDelta;
	}

	/// Ends the drag.
	public void EndDrag()
	{
		IsDragging = false;
		SelectedAxis = .None;
	}

	/// Draws the translate gizmo using DebugDraw overlay lines.
	public void DrawTranslate(DebugDraw debugDraw)
	{
		let axisLen = Size;

		// X axis
		debugDraw.DrawLineOverlay(Position, Position + .(axisLen, 0, 0), GetAxisColor(.X));
		// Y axis
		debugDraw.DrawLineOverlay(Position, Position + .(0, axisLen, 0), GetAxisColor(.Y));
		// Z axis
		debugDraw.DrawLineOverlay(Position, Position + .(0, 0, axisLen), GetAxisColor(.Z));

		// Arrowheads (small lines)
		let headSize = Size * 0.1f;

		// X arrowhead
		let xEnd = Position + .(axisLen, 0, 0);
		let xColor = GetAxisColor(.X);
		debugDraw.DrawLineOverlay(xEnd, xEnd + .(-headSize, headSize, 0), xColor);
		debugDraw.DrawLineOverlay(xEnd, xEnd + .(-headSize, -headSize, 0), xColor);

		// Y arrowhead
		let yEnd = Position + .(0, axisLen, 0);
		let yColor = GetAxisColor(.Y);
		debugDraw.DrawLineOverlay(yEnd, yEnd + .(headSize, -headSize, 0), yColor);
		debugDraw.DrawLineOverlay(yEnd, yEnd + .(-headSize, -headSize, 0), yColor);

		// Z arrowhead
		let zEnd = Position + .(0, 0, axisLen);
		let zColor = GetAxisColor(.Z);
		debugDraw.DrawLineOverlay(zEnd, zEnd + .(0, headSize, -headSize), zColor);
		debugDraw.DrawLineOverlay(zEnd, zEnd + .(0, -headSize, -headSize), zColor);
	}

	/// Draws the scale gizmo using DebugDraw overlay lines.
	public void DrawScale(DebugDraw debugDraw)
	{
		let axisLen = Size;
		let boxSize = Size * 0.08f;

		// Axes
		debugDraw.DrawLineOverlay(Position, Position + .(axisLen, 0, 0), GetAxisColor(.X));
		debugDraw.DrawLineOverlay(Position, Position + .(0, axisLen, 0), GetAxisColor(.Y));
		debugDraw.DrawLineOverlay(Position, Position + .(0, 0, axisLen), GetAxisColor(.Z));

		// Box endpoints (small squares)
		DrawBoxOverlay(debugDraw, Position + .(axisLen, 0, 0), boxSize, GetAxisColor(.X));
		DrawBoxOverlay(debugDraw, Position + .(0, axisLen, 0), boxSize, GetAxisColor(.Y));
		DrawBoxOverlay(debugDraw, Position + .(0, 0, axisLen), boxSize, GetAxisColor(.Z));
	}

	/// Draws the rotate gizmo (three rings) using DebugDraw overlay lines.
	public void DrawRotate(DebugDraw debugDraw)
	{
		let radius = Size * 0.8f;
		let segments = 32;

		// YZ plane ring (X rotation) - red
		debugDraw.DrawCircleOverlay(Position, .(0, 1, 0), .(0, 0, 1), radius, GetAxisColor(.X), segments);
		// XZ plane ring (Y rotation) - green
		debugDraw.DrawCircleOverlay(Position, .(1, 0, 0), .(0, 0, 1), radius, GetAxisColor(.Y), segments);
		// XY plane ring (Z rotation) - blue
		debugDraw.DrawCircleOverlay(Position, .(1, 0, 0), .(0, 1, 0), radius, GetAxisColor(.Z), segments);
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

	// === Helpers ===

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
		// Bottom face
		debugDraw.DrawLineOverlay(.(min.X, min.Y, min.Z), .(max.X, min.Y, min.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, min.Y, min.Z), .(max.X, min.Y, max.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, min.Y, max.Z), .(min.X, min.Y, max.Z), color);
		debugDraw.DrawLineOverlay(.(min.X, min.Y, max.Z), .(min.X, min.Y, min.Z), color);
		// Top face
		debugDraw.DrawLineOverlay(.(min.X, max.Y, min.Z), .(max.X, max.Y, min.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, max.Y, min.Z), .(max.X, max.Y, max.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, max.Y, max.Z), .(min.X, max.Y, max.Z), color);
		debugDraw.DrawLineOverlay(.(min.X, max.Y, max.Z), .(min.X, max.Y, min.Z), color);
		// Verticals
		debugDraw.DrawLineOverlay(.(min.X, min.Y, min.Z), .(min.X, max.Y, min.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, min.Y, min.Z), .(max.X, max.Y, min.Z), color);
		debugDraw.DrawLineOverlay(.(max.X, min.Y, max.Z), .(max.X, max.Y, max.Z), color);
		debugDraw.DrawLineOverlay(.(min.X, min.Y, max.Z), .(min.X, max.Y, max.Z), color);
	}

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

	/// Gets the hit point on a drag plane.
	public static Vector3 GetDragHitPoint(Ray ray, GizmoAxis axis, Vector3 planeOrigin)
	{
		Vector3 planeNormal;
		switch (axis)
		{
		case .X:
			planeNormal = (Math.Abs(ray.Direction.Y) > Math.Abs(ray.Direction.Z)) ? .(0, 1, 0) : .(0, 0, 1);
		case .Y:
			planeNormal = (Math.Abs(ray.Direction.X) > Math.Abs(ray.Direction.Z)) ? .(1, 0, 0) : .(0, 0, 1);
		case .Z:
			planeNormal = (Math.Abs(ray.Direction.X) > Math.Abs(ray.Direction.Y)) ? .(1, 0, 0) : .(0, 1, 0);
		default:
			return planeOrigin;
		}

		let denom = Vector3.Dot(planeNormal, ray.Direction);
		if (Math.Abs(denom) < 0.0001f)
			return planeOrigin;

		let t = Vector3.Dot(planeNormal, planeOrigin - ray.Position) / denom;
		return ray.Position + ray.Direction * t;
	}
}
