using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Geometry;

/// The engine's runtime mesh: a static vertex stream, an index buffer, submeshes, bounds,
/// and the geometry operations that work purely on that stream.
///
/// Distinct from an imported model, which is a loaded FILE's representation. This is the
/// canonical, upload ready form the renderer and scene components consume.
class StaticMesh
{
	private static int64 sNextUid;

	/// Unique per OBJECT, and the key a renderer cache must use.
	///
	/// Never key such a cache on the pointer: a reloaded mesh can be reallocated at an
	/// address that has just been freed, and the new mesh then silently inherits the dead
	/// one's GPU geometry.
	public readonly uint64 Uid = (uint64)Interlocked.Increment(ref sNextUid);

	public String Name = new .() ~ delete _;
	public List<StaticMeshVertex> Vertices = new .() ~ delete _;
	public IndexBuffer Indices = new .(.U32) ~ delete _;
	public List<SubMesh> SubMeshes = new .() ~ delete _;
	public AABB Bounds = AABB.Empty();

	/// The LOD chain. Level 0 IS SubMeshes, so every consumer written before LOD existed
	/// keeps working untouched. Coarser levels share the ONE vertex buffer and store their
	/// own index ranges inside the ONE index buffer, concatenated after level 0's.
	///
	/// LodSubMeshes holds levels 1..LodCount-1 flattened as
	/// (lod - 1) * SubMeshes.Count + submesh. LodCoverage[l] is the normalised screen
	/// coverage threshold: level l is eligible while projected coverage is at least
	/// LodCoverage[l]. Index 0 is 1.0 by convention and unused by selection, since level 0
	/// is the fallback when everything else is too coarse. A one level mesh has LodCount 1
	/// and both lists empty.
	public uint32 LodCount = 1;
	public List<SubMesh> LodSubMeshes = new .() ~ delete _;
	public List<float> LodCoverage = new .() ~ delete _;

	public uint32 VertexCount => (uint32)Vertices.Count;
	public uint32 IndexCount => Indices.Count;
	public static uint32 VertexStride => (uint32)sizeof(StaticMeshVertex);

	/// The raw static stream for upload, or null when empty.
	public uint8* VertexData => Vertices.IsEmpty ? null : (uint8*)Vertices.Ptr;
	public uint32 VertexDataSize => VertexCount * VertexStride;

	/// Whether this is really a skinned mesh, and its parallel stream if so.
	///
	/// These exist so a consumer holding a StaticMesh can discover and bind the skinning
	/// stream without asking what type it is.
	public virtual bool IsSkinned => false;
	public virtual Span<VertexSkinning> SkinningStream => .();

	/// The submesh table for one LOD level: 0 is SubMeshes, anything else the flattened
	/// slice. Out of range or malformed tables fall back to level 0, because bad data
	/// should render coarsely rather than crash selection.
	public Span<SubMesh> SubMeshesForLod(uint32 lod)
	{
		if ((lod == 0) || (LodCount <= 1) || SubMeshes.IsEmpty)
			return .(SubMeshes.Ptr, SubMeshes.Count);

		let level = (lod < LodCount) ? lod : (LodCount - 1);
		let per = SubMeshes.Count;
		let offset = (int)(level - 1) * per;
		if (offset + per > LodSubMeshes.Count)
			return .(SubMeshes.Ptr, SubMeshes.Count);

		return .(LodSubMeshes.Ptr + offset, per);
	}

	/// Resets to empty IN PLACE, so a hot reload repopulates this same instance and
	/// outside references to it, GPU caches included, stay valid.
	public virtual void ClearForReload()
	{
		Name.Clear();
		Vertices.Clear();
		Indices.Clear();
		SubMeshes.Clear();
		Bounds = AABB.Empty();
		LodCount = 1;
		LodSubMeshes.Clear();
		LodCoverage.Clear();
	}

	/// Recomputes Bounds from the static stream.
	public ref AABB CalculateBounds()
	{
		if (Vertices.IsEmpty)
		{
			Bounds = .(Float3.Zero, Float3.Zero);
			return ref Bounds;
		}

		Bounds = AABB.Empty();
		for (let vertex in Vertices)
			Bounds.Expand(vertex.Position);

		return ref Bounds;
	}

	/// Smooth normals: accumulate each triangle's face normal into the vertices it shares.
	public void GenerateNormals()
	{
		let triangles = TriangleCount;
		if (triangles == 0)
			return;

		for (var vertex in ref Vertices)
			vertex.Normal = Float3.Zero;

		for (uint32 t < triangles)
		{
			let i0 = Corner(t, 0);
			let i1 = Corner(t, 1);
			let i2 = Corner(t, 2);
			let e1 = Vertices[(int)i1].Position - Vertices[(int)i0].Position;
			let e2 = Vertices[(int)i2].Position - Vertices[(int)i0].Position;
			let faceNormal = Cross(e1, e2);
			Vertices[(int)i0].Normal += faceNormal;
			Vertices[(int)i1].Normal += faceNormal;
			Vertices[(int)i2].Normal += faceNormal;
		}

		for (var vertex in ref Vertices)
		{
			vertex.Normal = (LengthSquared(vertex.Normal) > 0.0001f)
				? Normalized(vertex.Normal)
				: Float3.UnitY;
		}
	}

	/// Tangents for normal mapping.
	///
	/// Per triangle, UV delta weighted accumulation of BOTH tangent and bitangent, then
	/// Gram Schmidt orthogonalisation against the normal. The bitangent is what determines
	/// each vertex's handedness in Tangent.W: a mirrored UV triangle produces a bitangent
	/// opposing cross(N, T), so the sign flips to -1 there.
	public void GenerateTangents()
	{
		GenerateTangentsImpl(.(Vertices.Ptr, Vertices.Count), TriangleCount,
			scope (t, c) => Corner(t, c));
	}

	/// The same maths over raw storage, for an importer holding vertex and index blobs
	/// before any mesh exists.
	public static void GenerateTangents(Span<StaticMeshVertex> vertices, Span<uint32> indices)
	{
		GenerateTangentsImpl(vertices, (uint32)(indices.Length / 3),
			scope (t, c) => indices[(int)(t * 3 + c)]);
	}

	private static void GenerateTangentsImpl(Span<StaticMeshVertex> vertices, uint32 triangles,
		delegate uint32(uint32 triangle, uint32 corner) corner)
	{
		if (triangles == 0)
			return;

		let tangents = scope List<Float3>();
		let bitangents = scope List<Float3>();
		tangents.Resize(vertices.Length);
		bitangents.Resize(vertices.Length);
		for (int i < vertices.Length)
		{
			tangents[i] = Float3.Zero;
			bitangents[i] = Float3.Zero;
		}

		for (uint32 t < triangles)
		{
			let i0 = (int)corner(t, 0);
			let i1 = (int)corner(t, 1);
			let i2 = (int)corner(t, 2);
			let dp1 = vertices[i1].Position - vertices[i0].Position;
			let dp2 = vertices[i2].Position - vertices[i0].Position;
			let du1 = vertices[i1].TexCoord - vertices[i0].TexCoord;
			let du2 = vertices[i2].TexCoord - vertices[i0].TexCoord;
			let denom = du1.X * du2.Y - du2.X * du1.Y;

			var tangent = Float3.Zero;
			var bitangent = Float3.Zero;
			// A degenerate UV triangle has no tangent frame to derive; leaving it at zero
			// lets the per vertex fallback below pick something usable.
			if (Abs(denom) > 0.0001f)
			{
				let r = 1.0f / denom;
				tangent = (dp1 * du2.Y - dp2 * du1.Y) * r;
				bitangent = (dp2 * du1.X - dp1 * du2.X) * r;
			}

			tangents[i0] += tangent;
			tangents[i1] += tangent;
			tangents[i2] += tangent;
			bitangents[i0] += bitangent;
			bitangents[i1] += bitangent;
			bitangents[i2] += bitangent;
		}

		for (int i < vertices.Length)
		{
			var t = tangents[i];
			let normal = vertices[i].Normal;
			if (LengthSquared(t) > 0.0001f)
			{
				t = t - normal * Dot(normal, t);
				t = (LengthSquared(t) > 0.0001f) ? Normalized(t) : DefaultTangent(normal);
			}
			else
			{
				t = DefaultTangent(normal);
			}

			let handedness = (Dot(Cross(normal, t), bitangents[i]) < 0.0f) ? -1.0f : 1.0f;
			vertices[i].Tangent = .(t.X, t.Y, t.Z, handedness);
		}
	}

	/// Packs a 0..1 colour to RGBA8 with R in the low byte, matching Unorm8x4.
	public static uint32 PackColor(Float4 c)
	{
		let r = (uint32)(Clamp(c.X, 0.0f, 1.0f) * 255.0f);
		let g = (uint32)(Clamp(c.Y, 0.0f, 1.0f) * 255.0f);
		let b = (uint32)(Clamp(c.Z, 0.0f, 1.0f) * 255.0f);
		let a = (uint32)(Clamp(c.W, 0.0f, 1.0f) * 255.0f);
		return r | (g << 8) | (b << 16) | (a << 24);
	}

	public static uint32 PackColor(Color32 c)
	{
		return (uint32)c.R | ((uint32)c.G << 8) | ((uint32)c.B << 16) | ((uint32)c.A << 24);
	}

	protected uint32 TriangleCount => (Indices.Count > 0) ? (Indices.Count / 3) : (VertexCount / 3);

	/// The vertex index of corner c of triangle t, indexed or sequential.
	protected uint32 Corner(uint32 t, uint32 c)
	{
		return (Indices.Count > 0) ? Indices.Get(t * 3 + c) : (t * 3 + c);
	}

	protected static Float3 DefaultTangent(Float3 normal)
	{
		let t = (Abs(normal.Y) < 0.9f)
			? Cross(normal, Float3.UnitY)
			: Cross(normal, Float3.UnitX);
		return (LengthSquared(t) > 0.0001f) ? Normalized(t) : Float3.UnitX;
	}
}
