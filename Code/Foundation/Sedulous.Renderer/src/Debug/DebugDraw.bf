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
	public Color Color;
	public int32 TextStart;    // index into mTextChars, for Text kind
	public int32 TextLength;
}

/// One 3D text command (text anchored at a world position, rendered screen-space).
public struct Debug3DTextCommand
{
	public Vector3 WorldPos;
	public Color Color;
	public int32 TextStart;
	public int32 TextLength;
}

/// Instance-based immediate-mode debug drawing.
///
/// Owned by RenderContext (see RenderContext.DebugDraw). Game code accumulates
/// lines, wireframes, and text over the course of a frame via the Draw* methods,
/// and DebugPass / OverlayPass flush the accumulated commands each frame.
///
/// Thread model: single-threaded. Expand to per-thread buffers + merge on flush
/// if component updates are parallelized in the future.
public class DebugDraw
{
	// World-space line vertices (pairs). Drawn with line-list topology + depth test.
	private List<DebugVertex> mLineVerts = new .() ~ delete _;

	// World-space line vertices drawn WITHOUT depth test (overlay on top of geometry).
	private List<DebugVertex> mOverlayLineVerts = new .() ~ delete _;

	// 2D overlay commands (pixel coordinates).
	private List<Debug2DCommand> m2DCommands = new .() ~ delete _;

	// 3D-positioned text commands.
	private List<Debug3DTextCommand> m3DTextCommands = new .() ~ delete _;

	// Backing char storage for text commands.
	private List<char8> mTextChars = new .() ~ delete _;

	public Span<DebugVertex> LineVertices => mLineVerts;
	public Span<DebugVertex> OverlayLineVertices => mOverlayLineVerts;
	public Span<Debug2DCommand> Commands2D => m2DCommands;
	public Span<Debug3DTextCommand> TextCommands3D => m3DTextCommands;
	public Span<char8> TextChars => mTextChars;

	/// Number of line vertices (always a multiple of 2 - pairs form line segments).
	public int32 LineVertexCount => (int32)mLineVerts.Count;

	/// Number of overlay line vertices (no depth test).
	public int32 OverlayLineVertexCount => (int32)mOverlayLineVerts.Count;

	public bool HasAnyDraws => mLineVerts.Count > 0 || mOverlayLineVerts.Count > 0 || m2DCommands.Count > 0 || m3DTextCommands.Count > 0;

	/// Clears all accumulated draws. Called by the renderer at the end of each frame
	/// after the debug passes have consumed the data.
	public void Clear()
	{
		mLineVerts.Clear();
		mOverlayLineVerts.Clear();
		m2DCommands.Clear();
		m3DTextCommands.Clear();
		mTextChars.Clear();
	}

	// ==================== World-space primitives ====================

	/// Draws a single line segment.
	public void DrawLine(Vector3 from, Vector3 to, Color color)
	{
		mLineVerts.Add(.(from, color));
		mLineVerts.Add(.(to, color));
	}

	/// Draws a line segment without depth testing (rendered on top of all geometry).
	public void DrawLineOverlay(Vector3 from, Vector3 to, Color color)
	{
		mOverlayLineVerts.Add(.(from, color));
		mOverlayLineVerts.Add(.(to, color));
	}

	/// Draws a wire sphere without depth testing.
	public void DrawWireSphereOverlay(Vector3 center, float radius, Color color, int32 segments = 24)
	{
		// XY circle
		DrawCircleOverlay(center, .(1, 0, 0), .(0, 1, 0), radius, color, segments);
		// XZ circle
		DrawCircleOverlay(center, .(1, 0, 0), .(0, 0, 1), radius, color, segments);
		// YZ circle
		DrawCircleOverlay(center, .(0, 1, 0), .(0, 0, 1), radius, color, segments);
	}

	/// Draws a circle in the plane spanned by u and v, without depth testing.
	public void DrawCircleOverlay(Vector3 center, Vector3 u, Vector3 v, float radius, Color color, int32 segments = 32)
	{
		Vector3 prev = center + u * radius;
		for (int32 i = 1; i <= segments; i++)
		{
			let angle = (float)i / (float)segments * Math.PI_f * 2.0f;
			let point = center + u * (Math.Cos(angle) * radius) + v * (Math.Sin(angle) * radius);
			DrawLineOverlay(prev, point, color);
			prev = point;
		}
	}

	/// Draws an axis-aligned wire bounding box.
	public void DrawWireBox(BoundingBox bounds, Color color)
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

		// 4 bottom edges
		DrawLine(c000, c100, color);
		DrawLine(c100, c101, color);
		DrawLine(c101, c001, color);
		DrawLine(c001, c000, color);
		// 4 top edges
		DrawLine(c010, c110, color);
		DrawLine(c110, c111, color);
		DrawLine(c111, c011, color);
		DrawLine(c011, c010, color);
		// 4 vertical edges
		DrawLine(c000, c010, color);
		DrawLine(c100, c110, color);
		DrawLine(c101, c111, color);
		DrawLine(c001, c011, color);
	}

	/// Draws a wire sphere made of three orthogonal circles.
	public void DrawWireSphere(Vector3 center, float radius, Color color, int32 segments = 24)
	{
		DrawCircle(center, .(1, 0, 0), .(0, 1, 0), radius, color, segments);
		DrawCircle(center, .(0, 1, 0), .(0, 0, 1), radius, color, segments);
		DrawCircle(center, .(1, 0, 0), .(0, 0, 1), radius, color, segments);
	}

	/// Draws a wire circle in the plane spanned by u and v.
	public void DrawCircle(Vector3 center, Vector3 u, Vector3 v, float radius, Color color, int32 segments = 32)
	{
		let uN = Vector3.Normalize(u);
		let vN = Vector3.Normalize(v);
		Vector3 prev = center + uN * radius;
		for (int32 i = 1; i <= segments; i++)
		{
			let t = (float)i / (float)segments * 6.2831853f;
			let c = Math.Cos(t);
			let s = Math.Sin(t);
			let point = center + uN * (radius * c) + vN * (radius * s);
			DrawLine(prev, point, color);
			prev = point;
		}
	}

	/// Draws the three basis axes of a transform (red=X, green=Y, blue=Z).
	public void DrawAxis(Matrix transform, float size = 1.0f)
	{
		let o = transform.Translation;
		let x = Vector3(transform.M11, transform.M12, transform.M13);
		let y = Vector3(transform.M21, transform.M22, transform.M23);
		let z = Vector3(transform.M31, transform.M32, transform.M33);
		DrawLine(o, o + x * size, Color.Red);
		DrawLine(o, o + y * size, Color.Green);
		DrawLine(o, o + z * size, Color.Blue);
	}

	/// Draws the edges of a camera frustum from an inverse-view-projection matrix.
	/// The 8 NDC corners (-1..1 xy, 0..1 z) are transformed by the inverse and divided.
	public void DrawFrustum(Matrix invViewProj, Color color)
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
		// Near face (z=0)
		DrawLine(corners[0], corners[1], color);
		DrawLine(corners[1], corners[3], color);
		DrawLine(corners[3], corners[2], color);
		DrawLine(corners[2], corners[0], color);
		// Far face (z=1)
		DrawLine(corners[4], corners[5], color);
		DrawLine(corners[5], corners[7], color);
		DrawLine(corners[7], corners[6], color);
		DrawLine(corners[6], corners[4], color);
		// Connecting edges
		DrawLine(corners[0], corners[4], color);
		DrawLine(corners[1], corners[5], color);
		DrawLine(corners[2], corners[6], color);
		DrawLine(corners[3], corners[7], color);
	}

	// ==================== Text + 2D ====================

	/// Appends 3D-anchored text (projected to screen for rendering).
	public void DrawText3D(Vector3 worldPos, StringView text, Color color)
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
	public void DrawScreenText(float x, float y, StringView text, Color color)
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
			TextLength = (int32)text.Length
		});
	}

	/// Appends a filled pixel-space rectangle.
	public void DrawScreenRect(float x, float y, float width, float height, Color color)
	{
		m2DCommands.Add(.()
		{
			Kind = .Rect,
			Position = .(x, y),
			Size = .(width, height),
			Color = color,
			TextStart = 0,
			TextLength = 0
		});
	}
}
