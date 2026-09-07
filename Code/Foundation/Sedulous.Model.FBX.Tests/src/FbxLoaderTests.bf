using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Model;
using Sedulous.Model.IO;
using Sedulous.Model.FBX;

namespace Sedulous.Model.FBX.Tests;

/// The ufbx backed loader, driven with OBJ fixtures.
///
/// Raptor has no tests for this loader at all, so these are not a port of anything: they
/// cover the parts that are this loader's own work rather than ufbx's, which is the
/// triangulation, the deduplication, the vertex layout and the material mapping.
class FbxLoaderTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	/// A single quad: four positions, one face.
	private const String cQuad = """
o quad
v 0 0 0
v 1 0 0
v 1 1 0
v 0 1 0
vn 0 0 1
vt 0 0
vt 1 0
vt 1 1
vt 0 1
f 1/1/1 2/2/1 3/3/1 4/4/1
""";

	[Test]
	public static void OnlyFbxAndObjAreClaimed()
	{
		let loader = scope FbxLoader();
		Test.Assert(loader.SupportsExtension(".fbx"));
		Test.Assert(loader.SupportsExtension(".obj"));
		Test.Assert(loader.SupportsExtension(".FBX"), "extensions arrive in any case");
		Test.Assert(!loader.SupportsExtension(".gltf"));
		Test.Assert(!loader.SupportsExtension(""));
	}

	[Test]
	public static void AMissingFileIsReportedRatherThanCrashing()
	{
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load("no-such-model.obj", model) == .FileNotFound);
	}

	/// A quad is FOUR corners and a GPU wants triangles, so the loader triangulates it into
	/// two, sharing the vertices along the split.
	[Test]
	public static void AQuadIsTriangulated()
	{
		let fixture = scope ObjFixture("quad", cQuad);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);

		Test.Assert(model.Meshes.Length == 1);
		let mesh = model.Meshes[0];
		Test.Assert(mesh.Topology == .Triangles);
		Test.Assert(mesh.IndexCount == 6, scope $"two triangles, got {mesh.IndexCount} indices");
		Test.Assert(mesh.VertexCount == 4, scope $"and four corners, got {mesh.VertexCount}");
	}

	/// Every index has to land inside the vertex buffer. A deduplication that returned a
	/// stale index would break exactly here and nowhere else.
	[Test]
	public static void EveryIndexIsInsideTheVertexBuffer()
	{
		let fixture = scope ObjFixture("range", cQuad);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);

		let mesh = model.Meshes[0];
		Test.Assert(!mesh.Use32BitIndices, "far under the short limit");
		let indices = (uint16*)mesh.IndexData;
		for (int32 i = 0; i < mesh.IndexCount; i++)
			Test.Assert(indices[i] < (uint16)mesh.VertexCount, scope $"index {i} out of range");
	}

	/// Corners that agree in every attribute are ONE vertex; corners that differ in any of
	/// them are not. Two quads sharing an edge with the same normal collapse along it.
	[Test]
	public static void IdenticalCornersAreWelded()
	{
		let shared = """
o strip
v 0 0 0
v 1 0 0
v 1 1 0
v 0 1 0
v 2 0 0
v 2 1 0
vn 0 0 1
f 1//1 2//1 3//1 4//1
f 2//1 5//1 6//1 3//1
""";
		let fixture = scope ObjFixture("weld", shared);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);

		let mesh = model.Meshes[0];
		// Six positions, one normal, no UVs: eight corners across the two quads, of which
		// two pairs are identical, so six vertices survive.
		Test.Assert(mesh.VertexCount == 6, scope $"got {mesh.VertexCount} vertices");
		Test.Assert(mesh.IndexCount == 12, "four triangles");
	}

	/// The same position with DIFFERENT normals is two vertices, which is why a cube has
	/// twenty four and not eight.
	[Test]
	public static void CornersThatDifferAreNotWelded()
	{
		let creased = """
o crease
v 0 0 0
v 1 0 0
v 1 1 0
v 0 1 0
v 1 0 1
v 1 1 1
vn 0 0 1
vn 1 0 0
f 1//1 2//1 3//1 4//1
f 2//2 5//2 6//2 3//2
""";
		let fixture = scope ObjFixture("crease", creased);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);

		let mesh = model.Meshes[0];
		// The shared edge carries two different normals, so nothing welds across it: four
		// corners per quad, eight in all.
		Test.Assert(mesh.VertexCount == 8, scope $"got {mesh.VertexCount} vertices");
	}

	/// Every vertex carries a full slot set whether the file supplies it or not, so one
	/// shader serves every model. The defaults are neutral, not zero.
	[Test]
	public static void AbsentAttributesGetNeutralDefaults()
	{
		let bare = """
o bare
v 0 0 0
v 1 0 0
v 0 1 0
f 1 2 3
""";
		let fixture = scope ObjFixture("bare", bare);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);

		let mesh = model.Meshes[0];
		let colorOffset = mesh.OffsetOf(.Color);
		let tangentOffset = mesh.OffsetOf(.Tangent);
		Test.Assert((colorOffset >= 0) && (tangentOffset >= 0), "the slots exist unsupplied");

		let color = *(uint32*)(mesh.VertexData + colorOffset);
		Test.Assert(color == 0xFFFFFFFF, "opaque white multiplies to a no-op");

		let tangent = *(Float4*)(mesh.VertexData + tangentOffset);
		Test.Assert(Near(tangent.W, 1.0f) || Near(tangent.W, -1.0f), "the handedness is a sign");

		// Nothing here is skinned, so there are no skinning slots to pay for.
		Test.Assert(mesh.VertexStride
			== (int32)(sizeof(Float3) * 2 + sizeof(Float2) + sizeof(uint32) + sizeof(Float4)));
	}

	/// FBX and OBJ put V zero at the BOTTOM; the renderer puts it at the top. Not flipping
	/// shows as every texture upside down, which is the kind of thing that gets "fixed" in
	/// the shader and then breaks glTF.
	[Test]
	public static void TextureCoordinatesAreFlippedToTheRendererConvention()
	{
		// ASYMMETRIC on purpose: a V set of 0 and 1 is its own mirror, so a fixture built
		// from those passes whether the flip happens or not. A quarter does not.
		let asymmetric = """
o uv
v 0 0 0
v 1 0 0
v 0 1 0
vn 0 0 1
vt 0 0.25
vt 1 0.25
vt 0 0.25
f 1/1/1 2/2/1 3/3/1
""";
		let fixture = scope ObjFixture("uv", asymmetric);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);

		let mesh = model.Meshes[0];
		let uvOffset = mesh.OffsetOf(.TexCoord);
		Test.Assert(mesh.VertexCount > 0);

		for (int32 i = 0; i < mesh.VertexCount; i++)
		{
			let uv = *(Float2*)(mesh.VertexData + i * mesh.VertexStride + uvOffset);
			Test.Assert(Near(uv.Y, 0.75f), scope $"V is {uv.Y}, so it was not flipped from 0.25");
		}
	}

	/// A node carries the mesh it draws, which is what a renderer walks.
	[Test]
	public static void NodesReferenceTheirMesh()
	{
		let fixture = scope ObjFixture("nodes", cQuad);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);

		Test.Assert(model.Bones.Length > 0);
		bool sawMesh = false;
		for (let bone in model.Bones)
		{
			if (bone.MeshIndex == 0)
				sawMesh = true;
			Test.Assert(bone.Index >= 0, "every bone knows its own index");
		}
		Test.Assert(sawMesh, "some node draws the mesh");
	}

	/// ufbx converts to Y up on the way in, so there is nothing left to detect.
	[Test]
	public static void TheUpAxisIsAlreadyConverted()
	{
		let fixture = scope ObjFixture("axis", cQuad);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);
		Test.Assert(model.OriginalUpAxis == .PositiveY);
	}

	/// Loading twice through one loader has to free the first scene, and the second load
	/// must not read through the freed one.
	[Test]
	public static void ALoaderCanBeReused()
	{
		let fixture = scope ObjFixture("reuse", cQuad);
		let loader = scope FbxLoader();

		let first = scope ModelData();
		Test.Assert(loader.Load(fixture.Path, first) == .Ok);
		let second = scope ModelData();
		Test.Assert(loader.Load(fixture.Path, second) == .Ok);

		Test.Assert(second.Meshes.Length == first.Meshes.Length);
		Test.Assert(second.Meshes[0].VertexCount == first.Meshes[0].VertexCount);
	}

	/// Nonsense is a parse error rather than an empty model, so a caller can tell a broken
	/// file from an empty one.
	[Test]
	public static void NonsenseDoesNotProduceAModel()
	{
		let path = scope String("scratch_fbx_garbage.fbx");
		File.WriteAllText(path, "this is not a model at all").IgnoreError();
		defer { File.Delete(path).IgnoreError(); }

		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(path, model) != .Ok);
	}
}
