using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Navigation;

namespace Sedulous.Navigation.Tests;

/// The geometry every navigation test bakes.
static class NavigationFixture
{
	/// A ground quad on the horizontal plane, wound so BOTH triangles face up: Recast marks
	/// only an upward facing triangle walkable, so winding is the difference between a floor
	/// and nothing at all.
	public static void AddGround(List<Float3> verts, List<uint32> indices, float minX,
		float maxX, float minZ, float maxZ)
	{
		let from = (uint32)verts.Count;
		verts.Add(.(minX, 0.0f, minZ));
		verts.Add(.(maxX, 0.0f, minZ));
		verts.Add(.(maxX, 0.0f, maxZ));
		verts.Add(.(minX, 0.0f, maxZ));

		indices.Add(from + 0);
		indices.Add(from + 3);
		indices.Add(from + 2);
		indices.Add(from + 0);
		indices.Add(from + 2);
		indices.Add(from + 1);
	}

	/// A solid box: a top and four walls.
	///
	/// The WINDING does not matter here. The box only has to rasterise as something tall, so
	/// the ground under its footprint stops being walkable and becomes a hole to route around.
	public static void AddBox(List<Float3> verts, List<uint32> indices, float minX, float maxX,
		float minZ, float maxZ, float height)
	{
		Quad(verts, indices, .(minX, height, minZ), .(maxX, height, minZ),
			.(maxX, height, maxZ), .(minX, height, maxZ));
		Quad(verts, indices, .(minX, 0, minZ), .(maxX, 0, minZ), .(maxX, height, minZ),
			.(minX, height, minZ));
		Quad(verts, indices, .(maxX, 0, maxZ), .(minX, 0, maxZ), .(minX, height, maxZ),
			.(maxX, height, maxZ));
		Quad(verts, indices, .(minX, 0, maxZ), .(minX, 0, minZ), .(minX, height, minZ),
			.(minX, height, maxZ));
		Quad(verts, indices, .(maxX, 0, minZ), .(maxX, 0, maxZ), .(maxX, height, maxZ),
			.(maxX, height, minZ));
	}

	private static void Quad(List<Float3> verts, List<uint32> indices, Float3 a, Float3 b,
		Float3 c, Float3 d)
	{
		let from = (uint32)verts.Count;
		verts.Add(a);
		verts.Add(b);
		verts.Add(c);
		verts.Add(d);
		indices.Add(from + 0);
		indices.Add(from + 1);
		indices.Add(from + 2);
		indices.Add(from + 0);
		indices.Add(from + 2);
		indices.Add(from + 3);
	}

	public static bool BytesEqual(List<uint8> a, List<uint8> b)
	{
		if (a.Count != b.Count)
			return false;
		if (a.IsEmpty)
			return true;
		return RawMemory.Equal(a.Ptr, b.Ptr, a.Count);
	}

	public static bool Finite(Float3 v) =>
		!v.X.IsNaN && !v.Y.IsNaN && !v.Z.IsNaN
		&& !v.X.IsInfinity && !v.Y.IsInfinity && !v.Z.IsInfinity;

	/// The distance ignoring height, which is the one that matters for two agents passing.
	public static float DistXZ(Float3 a, Float3 b)
	{
		let dx = a.X - b.X;
		let dz = a.Z - b.Z;
		return Sqrt(dx * dx + dz * dz);
	}

	/// Bakes a ground, with an optional box in the middle of it.
	public static Result<void, ErrorCode> BakeGround(List<uint8> outBlob, float extent = 10.0f,
		bool withBox = false, NavigationBakeStages outStages = null)
	{
		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		AddGround(verts, indices, -extent, extent, -extent, extent);
		if (withBox)
			AddBox(verts, indices, -2, 2, -2, 2, 3.0f);

		return NavigationMeshBuilder.BuildTiled(verts, indices, .(), outBlob, outStages);
	}
}
