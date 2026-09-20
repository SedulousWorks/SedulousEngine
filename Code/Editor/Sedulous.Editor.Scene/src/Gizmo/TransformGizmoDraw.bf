using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Editor.Scene;

/// The gizmo's handles as debug draw: arrows and plane quads for translate, rings for rotate,
/// boxed axes for scale, plus the drag time span line and angle guide.
extension TransformGizmo
{
	public void Draw(DebugDraw dd, GizmoMode mode)
	{
		switch (mode)
		{
		case .Translate: DrawTranslate(dd);
		case .Rotate: DrawRotate(dd);
		case .Scale: DrawScale(dd);
		}
	}

	/// Selected is yellow; a disabled handle fades; a hovered one lerps toward white.
	private Color AxisColor(GizmoAxis axis, GizmoMode mode)
	{
		if (mSelected == axis)
			return .(1.0f, 1.0f, 0.4f, 1.0f);

		Color baseColor;
		switch (axis)
		{
		case .X, .PlaneX: baseColor = .(0.86f, 0.20f, 0.20f, 1.0f);
		case .Y, .PlaneY: baseColor = .(0.20f, 0.86f, 0.20f, 1.0f);
		case .Z, .PlaneZ: baseColor = .(0.20f, 0.40f, 0.86f, 1.0f);
		default: baseColor = .(0.8f, 0.8f, 0.8f, 1.0f);
		}
		if (!IsAxisEnabled(axis, mode)) // grazing fade
			return .(baseColor.R * 0.5f, baseColor.G * 0.5f, baseColor.B * 0.5f, 0.35f);
		if (mHovered == axis) // 75% toward white
			return .(baseColor.R + (1.0f - baseColor.R) * 0.75f,
				baseColor.G + (1.0f - baseColor.G) * 0.75f,
				baseColor.B + (1.0f - baseColor.B) * 0.75f, 1.0f);
		return baseColor;
	}

	/// A camera facing quad of `thickness`, so a handle has width at any distance.
	private void DrawThickLine(DebugDraw dd, Float3 from, Float3 to, Color color,
		float thickness)
	{
		let lineDir = to - from;
		if (Dot(lineDir, lineDir) < 0.0001f)
			return;
		let mid = (from + to) * 0.5f;
		var side = Cross(lineDir, mid - mCameraPos);
		let lenSq = Dot(side, side);
		if (lenSq < 0.0001f)
			return; // pointing at the camera: zero apparent width
		side = side * (thickness * 0.5f / Sqrt(lenSq));
		dd.DrawQuad(from - side, from + side, to + side, to - side, color, true);
	}

	private void DrawAxisArrow(DebugDraw dd, GizmoAxis axis, GizmoMode mode)
	{
		let dir = AxisDirection(axis);
		let color = AxisColor(axis, mode);
		let thickness = Size * 0.02f;
		let end = Position + dir * Size;
		DrawThickLine(dd, Position, end, color, thickness);

		let viewDir = Normalized(end - mCameraPos);
		var side = Cross(dir, viewDir);
		let lenSq = Dot(side, side);
		if (lenSq > 0.0001f)
		{
			side = side / Sqrt(lenSq);
			let h = Size * 0.1f;
			DrawThickLine(dd, end, end - dir * h + side * h, color, thickness);
			DrawThickLine(dd, end, end - dir * h - side * h, color, thickness);
		}
	}

	/// The infinite line an axis drag runs along.
	private void DrawSpanLine(DebugDraw dd)
	{
		if ((mSelected != .X) && (mSelected != .Y) && (mSelected != .Z))
			return;
		let dir = AxisDirection(mSelected);
		let c = AxisColor(mSelected, .Translate);
		let span = Size * 1000.0f;
		dd.DrawLine(Position - dir * span, Position + dir * span, c, false);
		dd.DrawLine(Position - dir * span, Position + dir * span, .(c.R, c.G, c.B, 0.25f), true);
	}

	private void DrawTranslate(DebugDraw dd)
	{
		for (let a in scope GizmoAxis[](.X, .Y, .Z))
			DrawAxisArrow(dd, a, .Translate);

		for (let p in scope GizmoAxis[](.PlaneX, .PlaneY, .PlaneZ))
		{
			if (!IsAxisEnabled(p, .Translate))
				continue;
			Float3 u = ?, v = ?;
			float su = ?, sv = ?;
			PlaneBasis(p, out u, out v);
			PlaneQuadSigns(p, out su, out sv);
			let a = Position + u * (su * Size * 0.25f) + v * (sv * Size * 0.25f);
			let b = Position + u * (su * Size * 0.55f) + v * (sv * Size * 0.25f);
			let c = Position + u * (su * Size * 0.55f) + v * (sv * Size * 0.55f);
			let d = Position + u * (su * Size * 0.25f) + v * (sv * Size * 0.55f);
			var color = AxisColor(p, .Translate);
			color.A *= ((mHovered == p) || (mSelected == p)) ? 0.6f : 0.35f;
			dd.DrawQuad(a, b, c, d, color, true);
		}

		let center = AxisColor(.View, .Translate);
		dd.DrawWireSphereOverlay(Position, Size * 0.1f, center, 16);
		if (mDragging)
			DrawSpanLine(dd);
	}

	private void DrawScale(DebugDraw dd)
	{
		let thickness = Size * 0.02f;
		for (let a in scope GizmoAxis[](.X, .Y, .Z))
		{
			let dir = AxisDirection(a);
			let color = AxisColor(a, .Scale);
			DrawThickLine(dd, Position, Position + dir * Size, color, thickness);
			dd.DrawFilledBoxCenter(Position + dir * Size, .(Size * 0.05f, Size * 0.05f, Size * 0.05f),
				color, true);
		}
		let center = AxisColor(.View, .Scale);
		dd.DrawFilledBoxCenter(Position, .(Size * 0.07f, Size * 0.07f, Size * 0.07f), center, true);
		if (mDragging)
			DrawSpanLine(dd);
	}

	private void DrawRotate(DebugDraw dd)
	{
		let radius = Size * 0.8f;
		let thickness = Size * 0.02f;
		const int32 cSegments = 48;

		for (let a in scope GizmoAxis[](.X, .Y, .Z))
		{
			Float3 u, v;
			switch (a)
			{
			case .X:
				u = AxisDirection(.Y);
				v = AxisDirection(.Z);
			case .Y:
				u = AxisDirection(.X);
				v = AxisDirection(.Z);
			default:
				u = AxisDirection(.X);
				v = AxisDirection(.Y);
			}
			let color = AxisColor(a, .Rotate);
			let fullRing = mDragging && (mSelected == a); // the active axis shows the whole ring
			DrawRing(dd, u, v, radius, color, thickness, cSegments, !fullRing);
		}

		let r = CameraRight;
		let up = Cross(r, mCameraForward);
		DrawRing(dd, r, up, Size * 1.0f, AxisColor(.View, .Rotate), thickness, cSegments, false);

		if (mDragging)
			DrawAngleGuide(dd, radius);
	}

	private void DrawRing(DebugDraw dd, Float3 u, Float3 v, float radius, Color color,
		float thickness, int32 segments, bool cullBackHalf)
	{
		let uN = Normalized(u);
		let vN = Normalized(v);
		let viewDir = ViewDir;
		var prev = Position + uN * radius;
		for (int32 i = 1; i <= segments; i++)
		{
			let t = (float)i / (float)segments * TwoPi;
			let point = Position + uN * (radius * Cos(t)) + vN * (radius * Sin(t));
			let mid = (prev + point) * 0.5f;
			if (!cullBackHalf || (Dot(mid - Position, viewDir) <= 0.0f))
				DrawThickLine(dd, prev, point, color, thickness);
			prev = point;
		}
	}

	/// The start and current spokes of a rotate drag, with the angle in degrees beside it.
	private void DrawAngleGuide(DebugDraw dd, float radius)
	{
		let startDir = mDragRotationU * Cos(mDragStartAngle) + mDragRotationV * Sin(mDragStartAngle);
		let current = mDragStartAngle + mCurrentAngleDelta;
		let currentDir = mDragRotationU * Cos(current) + mDragRotationV * Sin(current);
		let solid = Color(1.0f, 1.0f, 0.4f, 1.0f);
		dd.DrawLine(Position, Position + startDir * radius, .(1.0f, 1.0f, 0.4f, 0.35f), true);
		dd.DrawLine(Position, Position + currentDir * radius, solid, true);

		let degrees = (int32)(RadiansToDegrees(mCurrentAngleDelta)
			+ ((mCurrentAngleDelta >= 0) ? 0.5f : -0.5f));
		let text = scope String();
		text.AppendF("{}\u{B0}", degrees);
		dd.DrawText3D(Position + currentDir * (radius * 1.15f), text, solid);
	}
}
