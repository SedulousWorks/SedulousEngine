namespace Sedulous.Renderer.Debug;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.DebugFont;

/// Screen-space 2D command kind.
public enum Debug2DCommandKind : uint8
{
	Text,
	Rect
}

/// One 2D overlay command (text or solid rectangle).
public struct Debug2DCommand
{
	public Debug2DCommandKind Kind;
	public Vector2 Position;   // pixels (top-left origin)
	public Vector2 Size;       // pixels (for rects; text uses char metrics)
	public Color32 Color;
	public int32 TextStart;    // index into mTextChars, for Text kind
	public int32 TextLength;
	public float Scale;        // text scale (1.0 = default)
}

/// One 3D text command (text anchored at a world position, rendered screen-space).
public struct Debug3DTextCommand
{
	public Vector3 WorldPos;
	public Color32 Color;
	public int32 TextStart;
	public int32 TextLength;
}

/// Instance-based immediate-mode debug drawing.
///
/// Owned by RenderContext (see RenderContext.DebugDraw). Game code accumulates
/// lines, triangles, wireframes, and text over the course of a frame via the Draw*
/// methods, and DebugGeometryPass / DebugScreenPass flush the accumulated commands each frame.
///
/// All 3D shape methods accept an `overlay` parameter:
///   false (default) = depth-tested, integrates with scene geometry
///   true = always rendered on top, ignores depth
public class DebugDraw
{
	// World-space line vertices (pairs). Drawn with line-list topology.
	private List<DebugVertex> mLineVerts = new .() ~ delete _;
	private List<DebugVertex> mOverlayLineVerts = new .() ~ delete _;

	// World-space triangle vertices (triples). Drawn with triangle-list topology.
	private List<DebugVertex> mTriVerts = new .() ~ delete _;
	private List<DebugVertex> mOverlayTriVerts = new .() ~ delete _;

	// 2D overlay commands (pixel coordinates).
	private List<Debug2DCommand> m2DCommands = new .() ~ delete _;

	// 3D-positioned text commands.
	private List<Debug3DTextCommand> m3DTextCommands = new .() ~ delete _;

	// Backing char storage for text commands.
	private List<char8> mTextChars = new .() ~ delete _;

	// --- Read-only spans for passes ---

	public Span<DebugVertex> LineVertices => mLineVerts;
	public Span<DebugVertex> OverlayLineVertices => mOverlayLineVerts;
	public Span<DebugVertex> TriVertices => mTriVerts;
	public Span<DebugVertex> OverlayTriVertices => mOverlayTriVerts;
	public Span<Debug2DCommand> Commands2D => m2DCommands;
	public Span<Debug3DTextCommand> TextCommands3D => m3DTextCommands;
	public Span<char8> TextChars => mTextChars;

	public int32 LineVertexCount => (int32)mLineVerts.Count;
	public int32 OverlayLineVertexCount => (int32)mOverlayLineVerts.Count;
	public int32 TriVertexCount => (int32)mTriVerts.Count;
	public int32 OverlayTriVertexCount => (int32)mOverlayTriVerts.Count;

	public bool HasAnyDraws =>
		mLineVerts.Count > 0 || mOverlayLineVerts.Count > 0 ||
		mTriVerts.Count > 0 || mOverlayTriVerts.Count > 0 ||
		m2DCommands.Count > 0 || m3DTextCommands.Count > 0;

	/// Clears all accumulated draws. Called by the renderer at the end of each frame.
	public void Clear()
	{
		mLineVerts.Clear();
		mOverlayLineVerts.Clear();
		mTriVerts.Clear();
		mOverlayTriVerts.Clear();
		m2DCommands.Clear();
		m3DTextCommands.Clear();
		mTextChars.Clear();
	}

	// ==================== Lines ====================

	/// Draws a single line segment.
	public void DrawLine(Vector3 from, Vector3 to, Color32 color, bool overlay = false)
	{
		let list = overlay ? mOverlayLineVerts : mLineVerts;
		list.Add(.(from, color));
		list.Add(.(to, color));
	}

	/// Draws a line segment without depth testing (rendered on top of all geometry).
	public void DrawLineOverlay(Vector3 from, Vector3 to, Color32 color)
	{
		mOverlayLineVerts.Add(.(from, color));
		mOverlayLineVerts.Add(.(to, color));
	}

	/// Draws a ray from origin along direction.
	public void DrawRay(Vector3 origin, Vector3 direction, Color32 color, bool overlay = false)
	{
		DrawLine(origin, origin + direction, color, overlay);
	}

	// ==================== Filled Primitives ====================

	/// Draws a single filled triangle.
	public void DrawTriangle(Vector3 v0, Vector3 v1, Vector3 v2, Color32 color, bool overlay = false)
	{
		let list = overlay ? mOverlayTriVerts : mTriVerts;
		list.Add(.(v0, color));
		list.Add(.(v1, color));
		list.Add(.(v2, color));
	}

	/// Draws a filled quad (two triangles).
	public void DrawQuad(Vector3 v0, Vector3 v1, Vector3 v2, Vector3 v3, Color32 color, bool overlay = false)
	{
		DrawTriangle(v0, v1, v2, color, overlay);
		DrawTriangle(v0, v2, v3, color, overlay);
	}

	/// Draws a filled axis-aligned box.
	public void DrawFilledBox(BoundingBox bounds, Color32 color, bool overlay = false)
	{
		let mn = bounds.Min;
		let mx = bounds.Max;

		Vector3 v0 = .(mn.X, mn.Y, mn.Z);
		Vector3 v1 = .(mx.X, mn.Y, mn.Z);
		Vector3 v2 = .(mx.X, mn.Y, mx.Z);
		Vector3 v3 = .(mn.X, mn.Y, mx.Z);
		Vector3 v4 = .(mn.X, mx.Y, mn.Z);
		Vector3 v5 = .(mx.X, mx.Y, mn.Z);
		Vector3 v6 = .(mx.X, mx.Y, mx.Z);
		Vector3 v7 = .(mn.X, mx.Y, mx.Z);

		// Bottom (Y = min)
		DrawQuad(v0, v1, v2, v3, color, overlay);
		// Top (Y = max)
		DrawQuad(v4, v7, v6, v5, color, overlay);
		// Front (Z = min)
		DrawQuad(v0, v4, v5, v1, color, overlay);
		// Back (Z = max)
		DrawQuad(v2, v6, v7, v3, color, overlay);
		// Left (X = min)
		DrawQuad(v0, v3, v7, v4, color, overlay);
		// Right (X = max)
		DrawQuad(v1, v5, v6, v2, color, overlay);
	}

	/// Draws a filled box from center and half-extents.
	public void DrawFilledBox(Vector3 center, Vector3 halfExtents, Color32 color, bool overlay = false)
	{
		DrawFilledBox(BoundingBox(center - halfExtents, center + halfExtents), color, overlay);
	}

	// ==================== Wireframe Shapes ====================

	/// Draws an axis-aligned wire bounding box.
	public void DrawWireBox(BoundingBox bounds, Color32 color, bool overlay = false)
	{
		let mn = bounds.Min;
		let mx = bounds.Max;
		let c000 = Vector3(mn.X, mn.Y, mn.Z);
		let c100 = Vector3(mx.X, mn.Y, mn.Z);
		let c010 = Vector3(mn.X, mx.Y, mn.Z);
		let c110 = Vector3(mx.X, mx.Y, mn.Z);
		let c001 = Vector3(mn.X, mn.Y, mx.Z);
		let c101 = Vector3(mx.X, mn.Y, mx.Z);
		let c011 = Vector3(mn.X, mx.Y, mx.Z);
		let c111 = Vector3(mx.X, mx.Y, mx.Z);

		DrawLine(c000, c100, color, overlay);
		DrawLine(c100, c101, color, overlay);
		DrawLine(c101, c001, color, overlay);
		DrawLine(c001, c000, color, overlay);
		DrawLine(c010, c110, color, overlay);
		DrawLine(c110, c111, color, overlay);
		DrawLine(c111, c011, color, overlay);
		DrawLine(c011, c010, color, overlay);
		DrawLine(c000, c010, color, overlay);
		DrawLine(c100, c110, color, overlay);
		DrawLine(c101, c111, color, overlay);
		DrawLine(c001, c011, color, overlay);
	}

	/// Draws a wireframe oriented bounding box (local AABB transformed by world matrix).
	public void DrawTransformedBox(BoundingBox localBounds, Matrix worldMatrix, Color32 color, bool overlay = false)
	{
		let mn = localBounds.Min;
		let mx = localBounds.Max;

		Vector3[8] c = ?;
		c[0] = Vector3.Transform(.(mn.X, mn.Y, mn.Z), worldMatrix);
		c[1] = Vector3.Transform(.(mx.X, mn.Y, mn.Z), worldMatrix);
		c[2] = Vector3.Transform(.(mn.X, mx.Y, mn.Z), worldMatrix);
		c[3] = Vector3.Transform(.(mx.X, mx.Y, mn.Z), worldMatrix);
		c[4] = Vector3.Transform(.(mn.X, mn.Y, mx.Z), worldMatrix);
		c[5] = Vector3.Transform(.(mx.X, mn.Y, mx.Z), worldMatrix);
		c[6] = Vector3.Transform(.(mn.X, mx.Y, mx.Z), worldMatrix);
		c[7] = Vector3.Transform(.(mx.X, mx.Y, mx.Z), worldMatrix);

		// Bottom
		DrawLine(c[0], c[1], color, overlay); DrawLine(c[1], c[5], color, overlay);
		DrawLine(c[5], c[4], color, overlay); DrawLine(c[4], c[0], color, overlay);
		// Top
		DrawLine(c[2], c[3], color, overlay); DrawLine(c[3], c[7], color, overlay);
		DrawLine(c[7], c[6], color, overlay); DrawLine(c[6], c[2], color, overlay);
		// Verticals
		DrawLine(c[0], c[2], color, overlay); DrawLine(c[1], c[3], color, overlay);
		DrawLine(c[5], c[7], color, overlay); DrawLine(c[4], c[6], color, overlay);
	}

	/// Draws a wire sphere made of three orthogonal circles.
	public void DrawWireSphere(Vector3 center, float radius, Color32 color, int32 segments = 24, bool overlay = false)
	{
		DrawCircle(center, .(1, 0, 0), .(0, 1, 0), radius, color, segments, overlay);
		DrawCircle(center, .(0, 1, 0), .(0, 0, 1), radius, color, segments, overlay);
		DrawCircle(center, .(1, 0, 0), .(0, 0, 1), radius, color, segments, overlay);
	}

	/// Draws a wire sphere without depth testing.
	public void DrawWireSphereOverlay(Vector3 center, float radius, Color32 color, int32 segments = 24)
	{
		DrawWireSphere(center, radius, color, segments, true);
	}

	/// Draws a wire circle in the plane spanned by u and v.
	public void DrawCircle(Vector3 center, Vector3 u, Vector3 v, float radius, Color32 color, int32 segments = 32, bool overlay = false)
	{
		let uN = Vector3.Normalize(u);
		let vN = Vector3.Normalize(v);
		Vector3 prev = center + uN * radius;
		for (int32 i = 1; i <= segments; i++)
		{
			let t = (float)i / (float)segments * Math.PI_f * 2.0f;
			let point = center + uN * (radius * Math.Cos(t)) + vN * (radius * Math.Sin(t));
			DrawLine(prev, point, color, overlay);
			prev = point;
		}
	}

	/// Draws a circle in the plane spanned by u and v, without depth testing.
	public void DrawCircleOverlay(Vector3 center, Vector3 u, Vector3 v, float radius, Color32 color, int32 segments = 32)
	{
		DrawCircle(center, u, v, radius, color, segments, true);
	}

	/// Draws a circle on the specified plane (by normal).
	public void DrawCircle(Vector3 center, float radius, Vector3 normal, Color32 color, int32 segments = 32, bool overlay = false)
	{
		Vector3 up = Math.Abs(normal.Y) < 0.99f ? Vector3.UnitY : Vector3.UnitX;
		Vector3 right = Vector3.Normalize(Vector3.Cross(up, normal));
		Vector3 forward = Vector3.Cross(normal, right);
		DrawCircle(center, right, forward, radius, color, segments, overlay);
	}

	/// Draws the three basis axes of a transform (red=X, green=Y, blue=Z).
	public void DrawAxis(Matrix transform, float size = 1.0f, bool overlay = false)
	{
		let o = transform.Translation;
		let x = Vector3(transform.M11, transform.M12, transform.M13);
		let y = Vector3(transform.M21, transform.M22, transform.M23);
		let z = Vector3(transform.M31, transform.M32, transform.M33);
		DrawLine(o, o + x * size, Color32.Red, overlay);
		DrawLine(o, o + y * size, Color32.Green, overlay);
		DrawLine(o, o + z * size, Color32.Blue, overlay);
	}

	/// Draws a 3D cross at a position.
	public void DrawCross(Vector3 center, float size, Color32 color, bool overlay = false)
	{
		let h = size * 0.5f;
		DrawLine(center - .(h, 0, 0), center + .(h, 0, 0), color, overlay);
		DrawLine(center - .(0, h, 0), center + .(0, h, 0), color, overlay);
		DrawLine(center - .(0, 0, h), center + .(0, 0, h), color, overlay);
	}

	/// Draws an arrow from start to end with a small arrowhead.
	public void DrawArrow(Vector3 start, Vector3 end, Color32 color, float headSize = 0.1f, bool overlay = false)
	{
		DrawLine(start, end, color, overlay);

		let dir = Vector3.Normalize(end - start);
		Vector3 perp1;
		if (Math.Abs(dir.Y) < 0.99f)
			perp1 = Vector3.Normalize(Vector3.Cross(dir, .(0, 1, 0)));
		else
			perp1 = Vector3.Normalize(Vector3.Cross(dir, .(1, 0, 0)));
		let perp2 = Vector3.Cross(dir, perp1);

		let headBase = end - dir * headSize;
		let headRadius = headSize * 0.5f;

		DrawLine(end, headBase + perp1 * headRadius, color, overlay);
		DrawLine(end, headBase - perp1 * headRadius, color, overlay);
		DrawLine(end, headBase + perp2 * headRadius, color, overlay);
		DrawLine(end, headBase - perp2 * headRadius, color, overlay);
	}

	/// Draws a grid on the XZ plane.
	public void DrawGrid(Vector3 center, float size, int divisions, Color32 color, bool overlay = false)
	{
		let halfSize = size * 0.5f;
		let step = size / (float)divisions;

		for (int i = 0; i <= divisions; i++)
		{
			let t = (float)i * step - halfSize;
			DrawLine(center + .(-halfSize, 0, t), center + .(halfSize, 0, t), color, overlay);
			DrawLine(center + .(t, 0, -halfSize), center + .(t, 0, halfSize), color, overlay);
		}
	}

	/// Draws a wireframe capsule (cylinder with hemisphere caps).
	public void DrawCapsule(Vector3 center, float radius, float height, Color32 color, int32 segments = 16, bool overlay = false)
	{
		let halfHeight = height * 0.5f - radius;
		let top = center + .(0, halfHeight, 0);
		let bottom = center - .(0, halfHeight, 0);
		let step = Math.PI_f * 2.0f / segments;

		// Vertical lines + circles
		for (int i = 0; i < segments; i++)
		{
			let a0 = (float)i * step;
			let a1 = (float)(i + 1) * step;
			let x0 = Math.Cos(a0) * radius;
			let z0 = Math.Sin(a0) * radius;
			let x1 = Math.Cos(a1) * radius;
			let z1 = Math.Sin(a1) * radius;

			DrawLine(top + .(x0, 0, z0), bottom + .(x0, 0, z0), color, overlay);
			DrawLine(top + .(x0, 0, z0), top + .(x1, 0, z1), color, overlay);
			DrawLine(bottom + .(x0, 0, z0), bottom + .(x1, 0, z1), color, overlay);
		}

		// Hemisphere arcs
		let halfStep = Math.PI_f / (segments / 2);
		for (int i = 0; i < segments / 2; i++)
		{
			let a0 = (float)i * halfStep;
			let a1 = (float)(i + 1) * halfStep;

			// Top cap (XY + ZY arcs)
			DrawLine(top + .(Math.Sin(a0) * radius, Math.Cos(a0) * radius, 0),
				     top + .(Math.Sin(a1) * radius, Math.Cos(a1) * radius, 0), color, overlay);
			DrawLine(top + .(0, Math.Cos(a0) * radius, Math.Sin(a0) * radius),
				     top + .(0, Math.Cos(a1) * radius, Math.Sin(a1) * radius), color, overlay);

			// Bottom cap (inverted)
			DrawLine(bottom + .(Math.Sin(a0) * radius, -Math.Cos(a0) * radius, 0),
				     bottom + .(Math.Sin(a1) * radius, -Math.Cos(a1) * radius, 0), color, overlay);
			DrawLine(bottom + .(0, -Math.Cos(a0) * radius, Math.Sin(a0) * radius),
				     bottom + .(0, -Math.Cos(a1) * radius, Math.Sin(a1) * radius), color, overlay);
		}
	}

	/// Draws a wireframe cylinder.
	public void DrawCylinder(Vector3 center, float radius, float height, Color32 color, int32 segments = 16, bool overlay = false)
	{
		let halfHeight = height * 0.5f;
		let top = center + .(0, halfHeight, 0);
		let bottom = center - .(0, halfHeight, 0);
		let step = Math.PI_f * 2.0f / segments;

		for (int i = 0; i < segments; i++)
		{
			let a0 = (float)i * step;
			let a1 = (float)(i + 1) * step;

			DrawLine(top + .(Math.Cos(a0) * radius, 0, Math.Sin(a0) * radius),
				     bottom + .(Math.Cos(a0) * radius, 0, Math.Sin(a0) * radius), color, overlay);
			DrawLine(top + .(Math.Cos(a0) * radius, 0, Math.Sin(a0) * radius),
				     top + .(Math.Cos(a1) * radius, 0, Math.Sin(a1) * radius), color, overlay);
			DrawLine(bottom + .(Math.Cos(a0) * radius, 0, Math.Sin(a0) * radius),
				     bottom + .(Math.Cos(a1) * radius, 0, Math.Sin(a1) * radius), color, overlay);
		}
	}

	/// Draws a wireframe cone.
	public void DrawCone(Vector3 apex, Vector3 direction, float length, float angle, Color32 color, int32 segments = 16, bool overlay = false)
	{
		let dirNorm = Vector3.Normalize(direction);
		let baseCenter = apex + dirNorm * length;
		let radius = length * Math.Tan(angle);

		Vector3 up = Math.Abs(dirNorm.Y) < 0.99f ? Vector3.UnitY : Vector3.UnitX;
		Vector3 right = Vector3.Normalize(Vector3.Cross(up, dirNorm));
		Vector3 forward = Vector3.Cross(dirNorm, right);

		let step = Math.PI_f * 2.0f / segments;
		for (int i = 0; i < segments; i++)
		{
			let a0 = (float)i * step;
			let a1 = (float)(i + 1) * step;

			let p0 = baseCenter + (right * Math.Cos(a0) + forward * Math.Sin(a0)) * radius;
			let p1 = baseCenter + (right * Math.Cos(a1) + forward * Math.Sin(a1)) * radius;

			DrawLine(p0, p1, color, overlay);
			DrawLine(apex, p0, color, overlay);
		}
	}

	/// Draws the edges of a camera frustum from an inverse-view-projection matrix.
	public void DrawFrustum(Matrix invViewProj, Color32 color, bool overlay = false)
	{
		Vector3[8] corners = ?;
		int idx = 0;
		for (int32 z = 0; z < 2; z++)
		for (int32 y = 0; y < 2; y++)
		for (int32 x = 0; x < 2; x++)
		{
			let ndc = Vector4(x == 0 ? -1 : 1, y == 0 ? -1 : 1, (float)z, 1);
			let w = Vector4.Transform(ndc, invViewProj);
			corners[idx++] = .(w.X / w.W, w.Y / w.W, w.Z / w.W);
		}
		// Near
		DrawLine(corners[0], corners[1], color, overlay);
		DrawLine(corners[1], corners[3], color, overlay);
		DrawLine(corners[3], corners[2], color, overlay);
		DrawLine(corners[2], corners[0], color, overlay);
		// Far
		DrawLine(corners[4], corners[5], color, overlay);
		DrawLine(corners[5], corners[7], color, overlay);
		DrawLine(corners[7], corners[6], color, overlay);
		DrawLine(corners[6], corners[4], color, overlay);
		// Connecting
		DrawLine(corners[0], corners[4], color, overlay);
		DrawLine(corners[1], corners[5], color, overlay);
		DrawLine(corners[2], corners[6], color, overlay);
		DrawLine(corners[3], corners[7], color, overlay);
	}

	/// Draws a wireframe sphere from BoundingSphere.
	public void DrawWireSphere(BoundingSphere sphere, Color32 color, int32 segments = 24, bool overlay = false)
	{
		DrawWireSphere(sphere.Center, sphere.Radius, color, segments, overlay);
	}

	// ==================== Text + 2D ====================

	/// Appends 3D-anchored text (projected to screen for rendering).
	public void DrawText3D(Vector3 worldPos, StringView text, Color32 color)
	{
		if (text.IsEmpty) return;
		let start = (int32)mTextChars.Count;
		for (let c in text.RawChars)
			mTextChars.Add(c);
		m3DTextCommands.Add(.()
		{
			WorldPos = worldPos,
			Color = color,
			TextStart = start,
			TextLength = (int32)text.Length
		});
	}

	/// Appends pixel-space text.
	public void DrawScreenText(float x, float y, StringView text, Color32 color, float scale = 1.0f)
	{
		if (text.IsEmpty) return;
		let start = (int32)mTextChars.Count;
		for (let c in text.RawChars)
			mTextChars.Add(c);
		m2DCommands.Add(.()
		{
			Kind = .Text,
			Position = .(x, y),
			Size = .(0, 0),
			Color = color,
			TextStart = start,
			TextLength = (int32)text.Length,
			Scale = scale
		});
	}

	/// Appends pixel-space text right-aligned from the right edge.
	public void DrawScreenTextRight(float rightMargin, float y, StringView text, Color32 color, float scale = 1.0f)
	{
		if (text.IsEmpty) return;
		let start = (int32)mTextChars.Count;
		for (let c in text.RawChars)
			mTextChars.Add(c);
		m2DCommands.Add(.()
		{
			Kind = .Text,
			Position = .(-(rightMargin + 1), y), // negative X signals right-aligned
			Size = .(0, 0),
			Color = color,
			TextStart = start,
			TextLength = (int32)text.Length,
			Scale = scale
		});
	}

	/// Appends a filled pixel-space rectangle.
	public void DrawScreenRect(float x, float y, float width, float height, Color32 color)
	{
		m2DCommands.Add(.()
		{
			Kind = .Rect,
			Position = .(x, y),
			Size = .(width, height),
			Color = color,
			TextStart = 0,
			TextLength = 0,
			Scale = 1.0f
		});
	}
}
