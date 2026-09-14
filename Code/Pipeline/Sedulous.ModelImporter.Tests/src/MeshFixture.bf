using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Model;

namespace Sedulous.ModelImporter.Tests;

/// Model meshes built by hand.
///
/// Hand built rather than loaded from a file: what the import cases measure is the CONVERSION,
/// and a fixture that states its own vertex count, its own submesh table and its own names is
/// one whose expectations can be read off the case itself.
static class MeshFixture
{
	/// Position, normal and texture coordinate, which is the layout a format without tangents
	/// hands over.
	public const int32 cPlainStride = 12 + 12 + 8;
	/// The same with an authored tangent on the end.
	public const int32 cTangentStride = cPlainStride + 16;
	/// The plain layout plus the skinning pair.
	public const int32 cSkinnedStride = cPlainStride + 8 + 16;

	private static void AddPlainElements(ModelMesh mesh)
	{
		mesh.AddVertexElement(.(.Position, .Float3, 0));
		mesh.AddVertexElement(.(.Normal, .Float3, 12));
		mesh.AddVertexElement(.(.TexCoord, .Float2, 24));
	}

	private static void SetIndices(ModelMesh mesh, Span<uint32> indices)
	{
		mesh.AllocateIndices((int32)indices.Length, true);
		Test.Assert(mesh.SetIndexData(indices));
	}

	/// A row of vertices along X, shifted so a level's own vertices are recognisable in the
	/// blob after it was appended to a base.
	public static ModelMesh Row(StringView name, float xShift, int32 vertexCount,
		Span<uint32> indices)
	{
		let mesh = new ModelMesh();
		mesh.Name.Set(name);
		AddPlainElements(mesh);

		let bytes = scope List<uint8>();
		for (int32 i < vertexCount)
		{
			VertexBytes.Append(bytes, Float3(xShift + i, 0, 0));
			VertexBytes.Append(bytes, Float3(0, 0, 1));
			VertexBytes.Append(bytes, Float2(0, 0));
		}
		mesh.AllocateVertices(vertexCount, cPlainStride);
		Test.Assert(mesh.SetVertexData(bytes));
		SetIndices(mesh, indices);
		return mesh;
	}

	/// A quad in the XY plane whose normal is +Z and whose U runs along +Y.
	///
	/// The mapping is deliberately MIRRORED, so a generated tangent cannot be confused with
	/// the default one a missing stream would leave behind: it must point along +Y, and its
	/// handedness must come out negative.
	public static ModelMesh MirroredQuad(bool withAuthoredTangent, Float4 authoredTangent = .())
	{
		let mesh = new ModelMesh();
		mesh.Name.Set("quad");
		AddPlainElements(mesh);
		if (withAuthoredTangent)
			mesh.AddVertexElement(.(.Tangent, .Float4, 32));

		let positions = scope Float3[](.(0, 0, 0), .(1, 0, 0), .(1, 1, 0), .(0, 1, 0));
		let uvs = scope Float2[](.(0, 0), .(0, 1), .(1, 1), .(1, 0));

		let bytes = scope List<uint8>();
		for (int i < 4)
		{
			VertexBytes.Append(bytes, positions[i]);
			VertexBytes.Append(bytes, Float3(0, 0, 1));
			VertexBytes.Append(bytes, uvs[i]);
			if (withAuthoredTangent)
				VertexBytes.Append(bytes, authoredTangent);
		}
		mesh.AllocateVertices(4, withAuthoredTangent ? cTangentStride : cPlainStride);
		Test.Assert(mesh.SetVertexData(bytes));
		SetIndices(mesh, scope uint32[](0, 1, 2, 0, 2, 3));
		return mesh;
	}

	/// A triangle bound entirely to one joint, so the skinning stream's contents identify
	/// which mesh each entry came from.
	public static ModelMesh SkinnedTriangle(StringView name, float xShift, uint16 joint)
	{
		let mesh = new ModelMesh();
		mesh.Name.Set(name);
		AddPlainElements(mesh);
		mesh.AddVertexElement(.(.Joints, .UShort4, 32));
		mesh.AddVertexElement(.(.Weights, .Float4, 40));

		let bytes = scope List<uint8>();
		for (int32 i < 3)
		{
			VertexBytes.Append(bytes, Float3(xShift + i, 0, 0));
			VertexBytes.Append(bytes, Float3(0, 0, 1));
			VertexBytes.Append(bytes, Float2(0, 0));
			VertexBytes.AppendJoints(bytes, joint);
			VertexBytes.Append(bytes, Float4(1, 0, 0, 0));
		}
		mesh.AllocateVertices(3, cSkinnedStride);
		Test.Assert(mesh.SetVertexData(bytes));
		SetIndices(mesh, scope uint32[](0, 1, 2));
		return mesh;
	}

	/// A flat image of one value, which is what a format supplying metalness and roughness
	/// separately hands over.
	public static ModelTexture Gray(uint8 value, StringView name = default,
		StringView uri = default)
	{
		let texture = new ModelTexture();
		texture.Name.Set(name);
		texture.Uri.Set(uri);
		texture.Width = 2;
		texture.Height = 2;

		let pixels = scope List<uint8>();
		for (int i < 4)
		{
			pixels.Add(value);
			pixels.Add(value);
			pixels.Add(value);
			pixels.Add(255);
		}
		texture.SetData(pixels);
		return texture;
	}
}
