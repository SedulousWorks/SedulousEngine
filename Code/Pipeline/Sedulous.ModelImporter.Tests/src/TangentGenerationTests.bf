using System;
using Sedulous.Core;
using Sedulous.Geometry;

namespace Sedulous.ModelImporter.Tests;

/// Tangents for a mesh whose format supplied none.
///
/// A model without a tangent stream is common, and leaving the default behind gives every
/// vertex a tangent along +X whatever its texture coordinates say, which lights normal mapped
/// surfaces wrongly everywhere.
class TangentGenerationTests
{
	private static bool Near(float a, float b, float tolerance = 0.01f) => Abs(a - b) <= tolerance;

	/// The fixture's U runs along +Y, so a GENERATED tangent points along +Y, and the mapping
	/// being mirrored means its handedness is negative, which also proves the sign is not
	/// stuck at the default.
	[Test]
	public static void AMissingStreamIsGeneratedFromTheTextureCoordinates()
	{
		let mesh = MeshFixture.MirroredQuad(false);
		defer delete mesh;

		let source = scope StaticMeshSource();
		MeshConvert.StaticFromModel(mesh, source);
		Test.Assert(source.VertexBlob.Count == 4 * sizeof(StaticMeshVertex));

		let vertices = (StaticMeshVertex*)source.VertexBlob.Ptr;
		for (int i < 4)
		{
			let tangent = vertices[i].Tangent;
			Test.Assert(Near(Abs(tangent.Y), 1.0f), scope $"tangent y was {tangent.Y}");
			Test.Assert(Near(tangent.X, 0.0f));
			Test.Assert(Near(tangent.Z, 0.0f));
			Test.Assert(Near(tangent.W, -1.0f), scope $"handedness was {tangent.W}");
			let axis = Float3(tangent.X, tangent.Y, tangent.Z);
			Test.Assert(Near(Dot(axis, vertices[i].Normal), 0.0f));
		}
	}

	/// An AUTHORED stream passes through untouched: the author's tangents are the ones the
	/// normal maps were baked against.
	[Test]
	public static void AnAuthoredStreamIsLeftAlone()
	{
		let mesh = MeshFixture.MirroredQuad(true, .(0, 0, 1, -1));
		defer delete mesh;

		let source = scope StaticMeshSource();
		MeshConvert.StaticFromModel(mesh, source);

		let vertices = (StaticMeshVertex*)source.VertexBlob.Ptr;
		for (int i < 4)
		{
			Test.Assert(Near(vertices[i].Tangent.Z, 1.0f));
			Test.Assert(Near(vertices[i].Tangent.W, -1.0f));
		}
	}
}
