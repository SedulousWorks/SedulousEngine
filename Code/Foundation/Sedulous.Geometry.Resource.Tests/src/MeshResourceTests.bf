using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Resource;

namespace Sedulous.Geometry.Resource.Tests;

/// Meshes as resources: cook a mesh into the content database, then build it back through
/// the ResourceManager and check the runtime mesh is the one that went in.
///
/// This is the first thing in the engine to consume Content and Resource for real, so it
/// is as much a test of that stack as of the mesh format.
class MeshResourceTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// Every part of the mesh that was stored comes back, and the part that was NOT stored
	/// is recomputed. Bounds are derived rather than serialized precisely so they cannot
	/// disagree with the vertices they describe.
	[Test]
	public static void ACubeRoundTripsThroughTheResourceManager()
	{
		let fixture = scope MeshFixture("scratch_mesh_static");
		let cube = Primitives.Cube(2.0f);
		defer delete cube;

		let id = fixture.CookStatic("cube", cube);
		let proxy = fixture.Manager.Bind<StaticMesh>(id);

		Test.Assert(proxy.State == .Ready);
		let built = proxy.Get;
		Test.Assert(built != null);

		Test.Assert(built.VertexCount == cube.VertexCount);
		Test.Assert(built.IndexCount == cube.IndexCount);
		Test.Assert(built.SubMeshes.Count == cube.SubMeshes.Count);
		Test.Assert(built.Name == cube.Name);

		for (int i < (int)cube.VertexCount)
		{
			Test.Assert(built.Vertices[i].Position == cube.Vertices[i].Position, scope $"vertex {i}");
			Test.Assert(built.Vertices[i].Normal == cube.Vertices[i].Normal);
			Test.Assert(built.Vertices[i].Tangent == cube.Vertices[i].Tangent, "handedness survived");
			Test.Assert(built.Vertices[i].Color == cube.Vertices[i].Color);
		}

		for (uint32 i < cube.IndexCount)
			Test.Assert(built.Indices.Get(i) == cube.Indices.Get(i), scope $"index {i}");

		Test.Assert(built.SubMeshes[0].StartIndex == cube.SubMeshes[0].StartIndex);
		Test.Assert(built.SubMeshes[0].IndexCount == cube.SubMeshes[0].IndexCount);
		Test.Assert(built.SubMeshes[0].Primitive == cube.SubMeshes[0].Primitive);

		// Recomputed on build rather than stored.
		Test.Assert(Near(built.Bounds.Min.X, -1.0f));
		Test.Assert(Near(built.Bounds.Max.Z, 1.0f));
	}

	/// The identity a cooked mesh gets is its own, and a mesh built twice from one identity
	/// is the same product rather than two copies.
	[Test]
	public static void OneIdentityBuildsOneSharedProduct()
	{
		let fixture = scope MeshFixture("scratch_mesh_shared");
		let sphere = Primitives.Sphere(1.0f, 8, 4);
		defer delete sphere;

		let id = fixture.CookStatic("sphere", sphere);
		let first = fixture.Manager.Bind<StaticMesh>(id);
		let second = fixture.Manager.Bind<StaticMesh>(id);

		Test.Assert(first.Get != null);
		Test.Assert(first.Get === second.Get, "the cache handed back the same mesh");
		Test.Assert(first.Get.Uid == second.Get.Uid);
	}

	/// The whole point of the two stage path for a mesh: the product is pure CPU, so the
	/// entire build runs on a worker and the result is identical to the synchronous one.
	[Test]
	public static void AnAsyncLoadMatchesTheSynchronousProduct()
	{
		let jobs = scope JobSystem(2);
		let fixture = scope MeshFixture("scratch_mesh_async", jobs);
		let source = Primitives.Cylinder(0.5f, 2.0f, 12);
		defer delete source;

		let id = fixture.CookStatic("cylinder", source);

		let async = fixture.Manager.BindAsync<StaticMesh>(id);
		Test.Assert(async.State == .Pending, "it did not build on the calling thread");

		fixture.Manager.WaitAll();
		Test.Assert(async.State == .Ready);

		let built = async.Get;
		Test.Assert(built.VertexCount == source.VertexCount);
		Test.Assert(built.IndexCount == source.IndexCount);
		for (int i < (int)source.VertexCount)
			Test.Assert(built.Vertices[i].Position == source.Vertices[i].Position, scope $"vertex {i}");
		Test.Assert(Near(built.Bounds.Max.Y, 1.0f));
	}

	/// Many decodes at once. Each one reads its own stream and touches nothing shared,
	/// which is the claim the async path rests on; a race here would show up as a mesh
	/// with another mesh's contents.
	[Test]
	public static void ManyConcurrentDecodesEachProduceTheirOwnMesh()
	{
		let jobs = scope JobSystem(4);
		let fixture = scope MeshFixture("scratch_mesh_many", jobs);

		const int kCount = 12;
		let ids = scope List<Guid>();
		let expectedVertices = scope List<uint32>();

		for (int i < kCount)
		{
			// Deliberately different sizes, so a mesh holding another's contents is
			// visible as a count rather than only as different bytes.
			let mesh = Primitives.Sphere(1.0f, (uint32)(6 + i), 4);
			defer delete mesh;
			ids.Add(fixture.CookStatic(scope $"sphere{i}", mesh));
			expectedVertices.Add(mesh.VertexCount);
		}

		let proxies = scope List<Proxy<StaticMesh>>();
		for (let id in ids)
			proxies.Add(fixture.Manager.BindAsync<StaticMesh>(id));

		fixture.Manager.WaitAll();

		for (int i < kCount)
		{
			Test.Assert(proxies[i].State == .Ready, scope $"mesh {i}");
			Test.Assert(proxies[i].Get.VertexCount == expectedVertices[i],
				scope $"mesh {i} has {proxies[i].Get.VertexCount} vertices, expected {expectedVertices[i]}");
		}

		Test.Assert(fixture.Manager.PendingCount == 0);
	}

	/// The submesh table carries more than its ranges. Every primitive built here is a
	/// triangle list with material 0, so a build that dropped the material or the topology
	/// would look perfectly correct in every other test; this one uses values that differ
	/// from the defaults on purpose.
	[Test]
	public static void TheSubmeshTableKeepsItsMaterialsAndTopology()
	{
		let fixture = scope MeshFixture("scratch_mesh_submeshes");

		let mesh = scope StaticMesh();
		for (int i < 6)
			mesh.Vertices.Add(.(Float3(i, 0, 0), Float3(0, 1, 0), Float2(0, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Indices.Resize(6);
		for (uint32 i < 6)
			mesh.Indices.Add(i);

		mesh.SubMeshes.Add(.(0, 3, 7, .Triangles));
		mesh.SubMeshes.Add(.(3, 2, 2, .LineStrip));
		mesh.SubMeshes.Add(.(5, 1, 4, .Points));

		let id = fixture.CookStatic("multi", mesh);
		let built = fixture.Manager.Bind<StaticMesh>(id).Get;
		Test.Assert(built != null);
		Test.Assert(built.SubMeshes.Count == 3);

		for (int i < 3)
		{
			Test.Assert(built.SubMeshes[i].StartIndex == mesh.SubMeshes[i].StartIndex, scope $"submesh {i} start");
			Test.Assert(built.SubMeshes[i].IndexCount == mesh.SubMeshes[i].IndexCount, scope $"submesh {i} count");
			Test.Assert(built.SubMeshes[i].MaterialIndex == mesh.SubMeshes[i].MaterialIndex,
				scope $"submesh {i} material: got {built.SubMeshes[i].MaterialIndex}, expected {mesh.SubMeshes[i].MaterialIndex}");
			Test.Assert(built.SubMeshes[i].Primitive == mesh.SubMeshes[i].Primitive,
				scope $"submesh {i} topology: got {built.SubMeshes[i].Primitive}");
		}
	}

	[Test]
	public static void ASkinnedMeshRoundTripsBothStreams()
	{
		let fixture = scope MeshFixture("scratch_mesh_skinned");
		let source = scope SkinnedMesh();
		source.Name.Set("arm");
		source.SkeletonIndex = 4;
		for (int i < 3)
		{
			source.Vertices.Add(.(Float3(i, 0, 0), Float3(0, 1, 0), Float2(i, 0), 0xFF00FF00, Float3(1, 0, 0)));
			var influence = VertexSkinning();
			influence.Joints[0] = (uint16)i;
			influence.Joints[1] = (uint16)(i + 1);
			influence.Weights = .(0.75f, 0.25f, 0, 0);
			source.Skinning.Add(influence);
		}
		source.Indices.Resize(3);
		source.Indices.AddTriangle(0, 1, 2);
		source.SubMeshes.Add(.(0, 3, 0, .Triangles));

		let id = fixture.CookSkinned("arm", source);
		let proxy = fixture.Manager.Bind<SkinnedMesh>(id);

		Test.Assert(proxy.State == .Ready);
		let built = proxy.Get;
		Test.Assert(built.SkeletonIndex == 4);
		Test.Assert(built.Name == "arm");
		Test.Assert(built.VertexCount == 3, "the inherited static stream came back");
		Test.Assert(built.Skinning.Count == 3, "and so did the parallel one");

		for (int i < 3)
		{
			Test.Assert(built.Vertices[i].Position == source.Vertices[i].Position);
			Test.Assert(built.Skinning[i].Joints[0] == (uint16)i, scope $"joint {i}");
			Test.Assert(built.Skinning[i].Joints[1] == (uint16)(i + 1));
			Test.Assert(built.Skinning[i].Weights == source.Skinning[i].Weights);
		}
	}

	/// A reference typed as a StaticMesh can legitimately name a SKINNED asset, because a
	/// skinned source is a static source. Building only the static half would drop the skin
	/// stream, and the mesh would then never animate while every status said it loaded.
	[Test]
	public static void ASkinnedAssetBoundAsStaticStillBuildsSkinned()
	{
		let fixture = scope MeshFixture("scratch_mesh_polymorphic");
		let source = scope SkinnedMesh();
		source.SkeletonIndex = 2;
		source.Vertices.Add(.(Float3(0, 0, 0), Float3(0, 1, 0), Float2(0, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		source.Skinning.Add(.());

		let id = fixture.CookSkinned("skinned", source);

		// Bound as the BASE product type, which is what a Ref<StaticMesh> does.
		let proxy = fixture.Manager.Bind<StaticMesh>(id);
		Test.Assert(proxy.State == .Ready);

		let built = proxy.Get;
		Test.Assert(built.IsSkinned, "it built the real skinned mesh, not just the static half");
		Test.Assert(built.SkinningStream.Length == 1);

		let skinned = built as SkinnedMesh;
		Test.Assert(skinned != null);
		Test.Assert(skinned.SkeletonIndex == 2);
	}

	/// A skinning stream that is not parallel to the vertices means the payload was read
	/// at the wrong offset. The build FAILS rather than producing a mesh that animates
	/// into garbage while reporting success.
	[Test]
	public static void ASkinningStreamThatIsNotParallelFailsTheBuild()
	{
		let fixture = scope MeshFixture("scratch_mesh_mismatched");

		let source = scope SkinnedMeshSource();
		// Two vertices worth of static stream, one influence: a cook could not produce
		// this, but a misaligned read can.
		source.VertexBlob.Resize(2 * sizeof(StaticMeshVertex));
		source.SkinningBlob.Resize(1 * sizeof(VertexSkinning));
		Test.Assert(!source.HasParallelSkinningStream);

		let id = fixture.Store("broken", "Sedulous.Geometry.SkinnedMeshSource", source);

		let proxy = fixture.Manager.Bind<SkinnedMesh>(id);
		Test.Assert(proxy.Get == null);
		Test.Assert(proxy.State == .Failed, "tried and failed, which is not the same as never tried");

		// And through the static entry point too, which is the path that would otherwise
		// quietly fill only half the mesh.
		let asStatic = fixture.Manager.Bind<StaticMesh>(fixture.Store("broken2",
			"Sedulous.Geometry.SkinnedMeshSource", source));
		Test.Assert(asStatic.State == .Failed);
	}

	/// Reloading rebuilds in place, so a proxy taken before the change sees the new mesh.
	/// This is what makes an asset edit visible without restarting.
	[Test]
	public static void ReloadingRebuildsWhatTheProxyPointsAt()
	{
		let fixture = scope MeshFixture("scratch_mesh_reload");
		let first = Primitives.Cube(2.0f);
		defer delete first;

		let id = fixture.CookStatic("shape", first);
		let proxy = fixture.Manager.Bind<StaticMesh>(id);
		Test.Assert(proxy.Get.VertexCount == 24);

		// Re-cook the same identity as something else entirely.
		let second = Primitives.Sphere(1.0f, 8, 4);
		defer delete second;
		let instance = fixture.Database.GetInstance(id);
		Test.Assert(instance != null);
		let source = scope StaticMeshSource();
		StaticMeshSource.FromMesh(second, source);
		instance.WriteObject(source).IgnoreError();

		fixture.Manager.Reload(id);

		Test.Assert(proxy.Get.VertexCount == second.VertexCount, "the proxy sees the new mesh");
		Test.Assert(Near(proxy.Get.Bounds.Max.X, 1.0f), "and its bounds were recomputed");
	}
}
