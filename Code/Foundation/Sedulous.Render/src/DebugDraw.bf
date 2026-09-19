using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Render;

/// Immediate mode debug drawing.
///
/// Game code accumulates world space lines, triangles and wireframes, and screen or world
/// anchored text, over a frame; the debug passes then flush the lot. ONE ACCUMULATOR per
/// source: a global one drawn in every view, and one per scene drawn only when that scene
/// renders, which is what keeps two scenes side by side from bleeding into each other.
///
/// Every three dimensional method takes an overlay flag: false is depth tested, true is drawn
/// over everything. Immediate mode, so it is cleared once per frame.
[Scriptable]
class DebugDraw
{
	private List<DebugVertex> mLines = new .() ~ delete _;
	private List<DebugVertex> mOverlayLines = new .() ~ delete _;
	private List<DebugVertex> mTriangles = new .() ~ delete _;
	private List<DebugVertex> mOverlayTriangles = new .() ~ delete _;
	private List<Debug2DCommand> mCommands2D = new .() ~ delete _;
	private List<Debug3DTextCommand> mTextCommands3D = new .() ~ delete _;
	private List<uint8> mTextChars = new .() ~ delete _;

	public Span<DebugVertex> LineVertices => mLines;
	public Span<DebugVertex> OverlayLineVertices => mOverlayLines;
	public Span<DebugVertex> TriangleVertices => mTriangles;
	public Span<DebugVertex> OverlayTriangleVertices => mOverlayTriangles;
	public Span<Debug2DCommand> Commands2D => mCommands2D;
	public Span<Debug3DTextCommand> TextCommands3D => mTextCommands3D;
	public Span<uint8> TextChars => mTextChars;

	public bool HasAnyDraws => !mLines.IsEmpty || !mOverlayLines.IsEmpty || !mTriangles.IsEmpty
		|| !mOverlayTriangles.IsEmpty || !mCommands2D.IsEmpty || !mTextCommands3D.IsEmpty;

	/// Drops everything accumulated. Once per frame, by the renderer.
	public void Clear()
	{
		mLines.Clear();
		mOverlayLines.Clear();
		mTriangles.Clear();
		mOverlayTriangles.Clear();
		mCommands2D.Clear();
		mTextCommands3D.Clear();
		mTextChars.Clear();
	}

	/// Packs a colour with RED in the LOW byte, which is what a normalised byte vertex
	/// attribute reads as the first component. NOT the same order as the colour's own packing,
	/// which puts red highest.
	public static uint32 PackColor(Color color)
	{
		uint32 ByteOf(float x) => (uint32)(Clamp(x, 0.0f, 1.0f) * 255.0f + 0.5f);
		return ByteOf(color.R) | (ByteOf(color.G) << 8) | (ByteOf(color.B) << 16)
			| (ByteOf(color.A) << 24);
	}

	/// Transforms a point and DIVIDES BY W, which the affine transform in Core does not: a
	/// frustum's corners come from an inverse view projection, where the divide is the whole
	/// point.
	public static Float3 ProjectPoint(Float4x4 m, Float3 p)
	{
		let x = p.X * m.M[0][0] + p.Y * m.M[1][0] + p.Z * m.M[2][0] + m.M[3][0];
		let y = p.X * m.M[0][1] + p.Y * m.M[1][1] + p.Z * m.M[2][1] + m.M[3][1];
		let z = p.X * m.M[0][2] + p.Y * m.M[1][2] + p.Z * m.M[2][2] + m.M[3][2];
		let w = p.X * m.M[0][3] + p.Y * m.M[1][3] + p.Z * m.M[2][3] + m.M[3][3];
		let inverseW = (w != 0.0f) ? 1.0f / w : 1.0f;
		return .(x * inverseW, y * inverseW, z * inverseW);
	}

	// ==================== Lines ====================

	[Scriptable]
	public void DrawLine(Float3 from, Float3 to, Color color, bool overlay = false)
	{
		let list = overlay ? mOverlayLines : mLines;
		let packed = PackColor(color);
		list.Add(.(from, packed));
		list.Add(.(to, packed));
	}

	public void DrawLineOverlay(Float3 from, Float3 to, Color color)
	{
		DrawLine(from, to, color, true);
	}

	[Scriptable]
	public void DrawRay(Float3 origin, Float3 direction, Color color, bool overlay = false)
	{
		DrawLine(origin, origin + direction, color, overlay);
	}

	// ==================== Filled ====================

	public void DrawTriangle(Float3 v0, Float3 v1, Float3 v2, Color color, bool overlay = false)
	{
		let list = overlay ? mOverlayTriangles : mTriangles;
		let packed = PackColor(color);
		list.Add(.(v0, packed));
		list.Add(.(v1, packed));
		list.Add(.(v2, packed));
	}

	public void DrawQuad(Float3 v0, Float3 v1, Float3 v2, Float3 v3, Color color,
		bool overlay = false)
	{
		DrawTriangle(v0, v1, v2, color, overlay);
		DrawTriangle(v0, v2, v3, color, overlay);
	}

	public void DrawFilledBox(Float3 min, Float3 max, Color color, bool overlay = false)
	{
		let v0 = Float3(min.X, min.Y, min.Z);
		let v1 = Float3(max.X, min.Y, min.Z);
		let v2 = Float3(max.X, min.Y, max.Z);
		let v3 = Float3(min.X, min.Y, max.Z);
		let v4 = Float3(min.X, max.Y, min.Z);
		let v5 = Float3(max.X, max.Y, min.Z);
		let v6 = Float3(max.X, max.Y, max.Z);
		let v7 = Float3(min.X, max.Y, max.Z);

		DrawQuad(v0, v1, v2, v3, color, overlay);
		DrawQuad(v4, v7, v6, v5, color, overlay);
		DrawQuad(v0, v4, v5, v1, color, overlay);
		DrawQuad(v2, v6, v7, v3, color, overlay);
		DrawQuad(v0, v3, v7, v4, color, overlay);
		DrawQuad(v1, v5, v6, v2, color, overlay);
	}

	public void DrawFilledBoxCenter(Float3 center, Float3 halfExtents, Color color,
		bool overlay = false)
	{
		DrawFilledBox(center - halfExtents, center + halfExtents, color, overlay);
	}

	// ==================== Wireframe ====================

	[Scriptable]
	public void DrawWireBox(Float3 min, Float3 max, Color color, bool overlay = false)
	{
		let c000 = Float3(min.X, min.Y, min.Z);
		let c100 = Float3(max.X, min.Y, min.Z);
		let c010 = Float3(min.X, max.Y, min.Z);
		let c110 = Float3(max.X, max.Y, min.Z);
		let c001 = Float3(min.X, min.Y, max.Z);
		let c101 = Float3(max.X, min.Y, max.Z);
		let c011 = Float3(min.X, max.Y, max.Z);
		let c111 = Float3(max.X, max.Y, max.Z);

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

	public void DrawWireBoxCenter(Float3 center, Float3 halfExtents, Color color,
		bool overlay = false)
	{
		DrawWireBox(center - halfExtents, center + halfExtents, color, overlay);
	}

	/// A local box carried through a world transform, which is to say an oriented one.
	public void DrawTransformedBox(Float3 min, Float3 max, Float4x4 world, Color color,
		bool overlay = false)
	{
		var corners = Float3[8](
			ProjectPoint(world, .(min.X, min.Y, min.Z)),
			ProjectPoint(world, .(max.X, min.Y, min.Z)),
			ProjectPoint(world, .(min.X, max.Y, min.Z)),
			ProjectPoint(world, .(max.X, max.Y, min.Z)),
			ProjectPoint(world, .(min.X, min.Y, max.Z)),
			ProjectPoint(world, .(max.X, min.Y, max.Z)),
			ProjectPoint(world, .(min.X, max.Y, max.Z)),
			ProjectPoint(world, .(max.X, max.Y, max.Z)));

		DrawLine(corners[0], corners[1], color, overlay);
		DrawLine(corners[1], corners[5], color, overlay);
		DrawLine(corners[5], corners[4], color, overlay);
		DrawLine(corners[4], corners[0], color, overlay);
		DrawLine(corners[2], corners[3], color, overlay);
		DrawLine(corners[3], corners[7], color, overlay);
		DrawLine(corners[7], corners[6], color, overlay);
		DrawLine(corners[6], corners[2], color, overlay);
		DrawLine(corners[0], corners[2], color, overlay);
		DrawLine(corners[1], corners[3], color, overlay);
		DrawLine(corners[5], corners[7], color, overlay);
		DrawLine(corners[4], corners[6], color, overlay);
	}

	public void DrawCircle(Float3 center, Float3 u, Float3 v, float radius, Color color,
		int32 segments = 32, bool overlay = false)
	{
		let uAxis = Normalized(u);
		let vAxis = Normalized(v);
		var previous = center + uAxis * radius;

		for (int32 i = 1; i <= segments; i++)
		{
			let t = (float)i / (float)segments * Pi * 2.0f;
			let point = center + uAxis * (radius * Cos(t)) + vAxis * (radius * Sin(t));
			DrawLine(previous, point, color, overlay);
			previous = point;
		}
	}

	public void DrawCircleNormal(Float3 center, float radius, Float3 normal, Color color,
		int32 segments = 32, bool overlay = false)
	{
		let up = (Abs(normal.Y) < 0.99f) ? Float3(0, 1, 0) : Float3(1, 0, 0);
		let right = Normalized(Cross(up, normal));
		let forward = Cross(normal, right);
		DrawCircle(center, right, forward, radius, color, segments, overlay);
	}

	[Scriptable]
	public void DrawWireSphere(Float3 center, float radius, Color color, int32 segments = 24,
		bool overlay = false)
	{
		DrawCircle(center, .(1, 0, 0), .(0, 1, 0), radius, color, segments, overlay);
		DrawCircle(center, .(0, 1, 0), .(0, 0, 1), radius, color, segments, overlay);
		DrawCircle(center, .(1, 0, 0), .(0, 0, 1), radius, color, segments, overlay);
	}

	public void DrawWireSphere(BoundingSphere sphere, Color color, int32 segments = 24,
		bool overlay = false)
	{
		DrawWireSphere(sphere.Center, sphere.Radius, color, segments, overlay);
	}

	public void DrawWireSphereOverlay(Float3 center, float radius, Color color,
		int32 segments = 24)
	{
		DrawWireSphere(center, radius, color, segments, true);
	}

	public void DrawCircleOverlay(Float3 center, Float3 u, Float3 v, float radius, Color color,
		int32 segments = 32)
	{
		DrawCircle(center, u, v, radius, color, segments, true);
	}

	/// A cylinder body between two hemisphere caps.
	public void DrawCapsule(Float3 center, float radius, float height, Color color,
		int32 segments = 16, bool overlay = false)
	{
		let halfHeight = height * 0.5f - radius;
		let top = center + Float3(0, halfHeight, 0);
		let bottom = center - Float3(0, halfHeight, 0);
		let step = Pi * 2.0f / (float)segments;

		// The vertical lines, and the two end circles.
		for (int32 i = 0; i < segments; i++)
		{
			let a0 = (float)i * step;
			let a1 = (float)(i + 1) * step;
			let o0 = Float3(Cos(a0) * radius, 0, Sin(a0) * radius);
			let o1 = Float3(Cos(a1) * radius, 0, Sin(a1) * radius);
			DrawLine(top + o0, bottom + o0, color, overlay);
			DrawLine(top + o0, top + o1, color, overlay);
			DrawLine(bottom + o0, bottom + o1, color, overlay);
		}

		// The caps' arcs, in both vertical planes at each end.
		let halfSegments = segments / 2;
		let halfStep = Pi / (float)halfSegments;
		for (int32 i = 0; i < halfSegments; i++)
		{
			let a0 = (float)i * halfStep;
			let a1 = (float)(i + 1) * halfStep;
			DrawLine(top + .(Sin(a0) * radius, Cos(a0) * radius, 0),
				top + .(Sin(a1) * radius, Cos(a1) * radius, 0), color, overlay);
			DrawLine(top + .(0, Cos(a0) * radius, Sin(a0) * radius),
				top + .(0, Cos(a1) * radius, Sin(a1) * radius), color, overlay);
			DrawLine(bottom + .(Sin(a0) * radius, -Cos(a0) * radius, 0),
				bottom + .(Sin(a1) * radius, -Cos(a1) * radius, 0), color, overlay);
			DrawLine(bottom + .(0, -Cos(a0) * radius, Sin(a0) * radius),
				bottom + .(0, -Cos(a1) * radius, Sin(a1) * radius), color, overlay);
		}
	}

	/// A transform's world axes, red, green then blue. The ROWS are the basis, this being the
	/// row vector convention.
	public void DrawAxis(Float4x4 transform, float size = 1.0f, bool overlay = false)
	{
		let origin = Float3(transform.M[3][0], transform.M[3][1], transform.M[3][2]);
		let x = Float3(transform.M[0][0], transform.M[0][1], transform.M[0][2]);
		let y = Float3(transform.M[1][0], transform.M[1][1], transform.M[1][2]);
		let z = Float3(transform.M[2][0], transform.M[2][1], transform.M[2][2]);

		DrawLine(origin, origin + x * size, .(1, 0, 0, 1), overlay);
		DrawLine(origin, origin + y * size, .(0, 1, 0, 1), overlay);
		DrawLine(origin, origin + z * size, .(0, 0, 1, 1), overlay);
	}

	[Scriptable]
	public void DrawCross(Float3 center, float size, Color color, bool overlay = false)
	{
		let half = size * 0.5f;
		DrawLine(center - .(half, 0, 0), center + .(half, 0, 0), color, overlay);
		DrawLine(center - .(0, half, 0), center + .(0, half, 0), color, overlay);
		DrawLine(center - .(0, 0, half), center + .(0, 0, half), color, overlay);
	}

	[Scriptable]
	public void DrawArrow(Float3 start, Float3 end, Color color, float headSize = 0.1f,
		bool overlay = false)
	{
		DrawLine(start, end, color, overlay);

		let direction = Normalized(end - start);
		let perpendicular1 = Normalized(Cross(direction,
			(Abs(direction.Y) < 0.99f) ? Float3(0, 1, 0) : Float3(1, 0, 0)));
		let perpendicular2 = Cross(direction, perpendicular1);
		let headBase = end - direction * headSize;
		let halfHead = headSize * 0.5f;

		DrawLine(end, headBase + perpendicular1 * halfHead, color, overlay);
		DrawLine(end, headBase - perpendicular1 * halfHead, color, overlay);
		DrawLine(end, headBase + perpendicular2 * halfHead, color, overlay);
		DrawLine(end, headBase - perpendicular2 * halfHead, color, overlay);
	}

	public void DrawGrid(Float3 center, float size, int32 divisions, Color color,
		bool overlay = false)
	{
		let half = size * 0.5f;
		let step = size / (float)divisions;

		for (int32 i = 0; i <= divisions; i++)
		{
			let t = (float)i * step - half;
			DrawLine(center + .(-half, 0, t), center + .(half, 0, t), color, overlay);
			DrawLine(center + .(t, 0, -half), center + .(t, 0, half), color, overlay);
		}
	}

	public void DrawCylinder(Float3 center, float radius, float height, Color color,
		int32 segments = 16, bool overlay = false)
	{
		let halfHeight = height * 0.5f;
		let step = Pi * 2.0f / (float)segments;
		let top = center + Float3(0, halfHeight, 0);
		let bottom = center - Float3(0, halfHeight, 0);

		for (int32 i = 0; i < segments; i++)
		{
			let a0 = (float)i * step;
			let a1 = (float)(i + 1) * step;
			let o0 = Float3(Cos(a0) * radius, 0, Sin(a0) * radius);
			let o1 = Float3(Cos(a1) * radius, 0, Sin(a1) * radius);
			DrawLine(top + o0, bottom + o0, color, overlay);
			DrawLine(top + o0, top + o1, color, overlay);
			DrawLine(bottom + o0, bottom + o1, color, overlay);
		}
	}

	public void DrawCone(Float3 apex, Float3 direction, float length, float angle, Color color,
		int32 segments = 16, bool overlay = false)
	{
		let axis = Normalized(direction);
		let baseCenter = apex + axis * length;
		let radius = length * (Sin(angle) / Cos(angle));
		let up = (Abs(axis.Y) < 0.99f) ? Float3(0, 1, 0) : Float3(1, 0, 0);
		let right = Normalized(Cross(up, axis));
		let forward = Cross(axis, right);
		let step = Pi * 2.0f / (float)segments;

		for (int32 i = 0; i < segments; i++)
		{
			let a0 = (float)i * step;
			let a1 = (float)(i + 1) * step;
			let p0 = baseCenter + (right * Cos(a0) + forward * Sin(a0)) * radius;
			let p1 = baseCenter + (right * Cos(a1) + forward * Sin(a1)) * radius;
			DrawLine(p0, p1, color, overlay);
			DrawLine(apex, p0, color, overlay);
		}
	}

	/// A camera's frustum edges, from the inverse of its view projection. The near plane sits
	/// at depth nought.
	public void DrawFrustum(Float4x4 invViewProj, Color color, bool overlay = false)
	{
		var corners = Float3[8]();
		var index = 0;
		for (int32 z = 0; z < 2; z++)
		{
			for (int32 y = 0; y < 2; y++)
			{
				for (int32 x = 0; x < 2; x++)
				{
					corners[index++] = ProjectPoint(invViewProj,
						.((x == 0) ? -1.0f : 1.0f, (y == 0) ? -1.0f : 1.0f, (float)z));
				}
			}
		}

		DrawLine(corners[0], corners[1], color, overlay);
		DrawLine(corners[1], corners[3], color, overlay);
		DrawLine(corners[3], corners[2], color, overlay);
		DrawLine(corners[2], corners[0], color, overlay);
		DrawLine(corners[4], corners[5], color, overlay);
		DrawLine(corners[5], corners[7], color, overlay);
		DrawLine(corners[7], corners[6], color, overlay);
		DrawLine(corners[6], corners[4], color, overlay);
		DrawLine(corners[0], corners[4], color, overlay);
		DrawLine(corners[1], corners[5], color, overlay);
		DrawLine(corners[2], corners[6], color, overlay);
		DrawLine(corners[3], corners[7], color, overlay);
	}

	// ==================== Text and screen space ====================

	[Scriptable]
	public void DrawText3D(Float3 worldPosition, StringView text, Color color)
	{
		if (text.IsEmpty)
			return;

		let start = (int32)mTextChars.Count;
		AppendChars(text);

		mTextCommands3D.Add(.()
			{
				WorldPosition = worldPosition, Color = color, TextStart = start,
				TextLength = (int32)text.Length
			});
	}

	[Scriptable]
	public void DrawScreenText(float x, float y, StringView text, Color color, float scale = 1.0f)
	{
		if (text.IsEmpty)
			return;

		let start = (int32)mTextChars.Count;
		AppendChars(text);

		mCommands2D.Add(.()
			{
				Kind = .Text, Position = .(x, y), Size = .(0, 0), Color = color, TextStart = start,
				TextLength = (int32)text.Length, Scale = scale
			});
	}

	public void DrawScreenTextRight(float rightMargin, float y, StringView text, Color color,
		float scale = 1.0f)
	{
		if (text.IsEmpty)
			return;

		let start = (int32)mTextChars.Count;
		AppendChars(text);

		// A NEGATIVE horizontal position is what tells the screen pass to right align. The one
		// added keeps a margin of nought from reading as a left aligned position of nought.
		mCommands2D.Add(.()
			{
				Kind = .Text, Position = .(-(rightMargin + 1.0f), y), Size = .(0, 0),
				Color = color, TextStart = start, TextLength = (int32)text.Length, Scale = scale
			});
	}

	public void DrawScreenRect(float x, float y, float width, float height, Color color)
	{
		mCommands2D.Add(.()
			{
				Kind = .Rectangle, Position = .(x, y), Size = .(width, height), Color = color,
				TextStart = 0, TextLength = 0, Scale = 1.0f
			});
	}

	private void AppendChars(StringView text)
	{
		for (int i < text.Length)
			mTextChars.Add((uint8)text[i]);
	}
}
