using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Editor.Scene;

/// Wireframes for the physics shapes: what every collider bearing component draws.
static class ColliderShapeGizmo
{
	/// Two cap spheres and four side lines, in `frame`.
	public static void DrawWireCapsule(DebugDraw dd, Float4x4 frame, float radius,
		float halfHeight, Color color)
	{
		let top = TransformPoint(Float3(0, halfHeight, 0), frame);
		let bottom = TransformPoint(Float3(0, -halfHeight, 0), frame);
		dd.DrawWireSphere(top, radius, color);
		dd.DrawWireSphere(bottom, radius, color);
		for (let o in scope Float3[](.(radius, 0, 0), .(-radius, 0, 0), .(0, 0, radius), .(0, 0, -radius)))
		{
			dd.DrawLine(TransformPoint(Float3(o.X, -halfHeight, o.Z), frame),
				TransformPoint(Float3(o.X, halfHeight, o.Z), frame), color);
		}
	}

	/// Draws the shape in the RIGID part of `world`: a primitive ignores the entity's scale,
	/// as the simulation does; a cooked outline takes it.
	public static void DrawColliderShape(in ColliderShapeDraw s, Float4x4 world, Color color,
		DebugDraw dd)
	{
		Float3 position = ?, scale = ?;
		Quaternion rotation = ?;
		if (!Decompose(world, out position, out rotation, out scale))
			return;
		let rigid = Transform(position, rotation, .(1, 1, 1)).ToMatrix();
		switch (s.Shape)
		{
		case .Box:
			dd.DrawTransformedBox(Float3.Zero - s.HalfExtents, s.HalfExtents, rigid, color);
		case .Sphere:
			dd.DrawWireSphere(position, s.Radius, color);
		case .Capsule:
			DrawWireCapsule(dd, rigid, s.Radius, s.HalfHeight, color);
		case .Plane:
			let extent = (s.PlaneHalfExtent < 25.0f) ? s.PlaneHalfExtent : 25.0f;
			const int32 cCells = 10;
			for (int32 g = -cCells; g <= cCells; g++)
			{
				let off = extent * (float)g / cCells;
				dd.DrawLine(TransformPoint(Float3(off, 0, -extent), rigid),
					TransformPoint(Float3(off, 0, extent), rigid), color);
				dd.DrawLine(TransformPoint(Float3(-extent, 0, off), rigid),
					TransformPoint(Float3(extent, 0, off), rigid), color);
			}
		case .Heightfield:
			if (s.Heightfield != null)
			{
				let ws = s.Heightfield.WorldSize;
				dd.DrawTransformedBox(.(-ws.X * 0.5f, s.Heightfield.MinY, -ws.Y * 0.5f),
					.(ws.X * 0.5f, s.Heightfield.MaxY, ws.Y * 0.5f), rigid, color);
			}
		case .Cooked:
			if (s.Cooked != null)
			{
				let shapeMatrix = Transform(position, rotation, scale).ToMatrix();
				let outline = s.Cooked.Outline;
				for (int t = 0; t + 2 < outline.Count; t += 3)
				{
					let a = TransformPoint(outline[t + 0], shapeMatrix);
					let b = TransformPoint(outline[t + 1], shapeMatrix);
					let d = TransformPoint(outline[t + 2], shapeMatrix);
					dd.DrawLine(a, b, color);
					dd.DrawLine(b, d, color);
					dd.DrawLine(d, a, color);
				}
			}
		}
	}
}
