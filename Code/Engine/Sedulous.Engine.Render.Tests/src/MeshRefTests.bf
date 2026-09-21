using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Render.Tests;

/// A mesh component's resource references: they round trip by id and resolve through the
/// manager's PROXY handles, so a reload swaps the product behind every holder at once.
class MeshRefTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	private static MeshComponent* SoleMesh(Scene scene)
	{
		MeshComponent* found = null;
		scene.GetSystem<MeshComponentManager>().ForEach(scope [&] (component, entity) =>
			{
				found = component;
			});
		return found;
	}

	[Test]
	public static void ASceneRoundTripResolvesMeshRefsThroughProxyHandles()
	{
		let fixture = scope RenderResourceFixture("scratch_render_resref_db");

		// A cooked product: a unit cube baked into a mesh source.
		Guid meshId;
		{
			let cube = Primitives.Cube(1.0f);
			defer delete cube;
			meshId = fixture.CookStatic("Cube", cube);
		}

		// Author a scene whose component references the mesh BY ID only.
		let blob = scope MemoryStream();
		{
			let scene = scope Scene();
			let meshes = scene.AddSystem<MeshComponentManager>();
			let entity = scene.CreateEntity("Box");
			let component = meshes.Add(entity);
			component.Mesh.SetId(meshId);
			component.Color = .(0.5f, 0.25f, 0.125f, 1.0f);

			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, scene);
			Test.Assert(writer.IsOk);
		}

		// Load into a FRESH scene, then run the post load resolve.
		let loaded = scope Scene();
		loaded.AddSystem<MeshComponentManager>();
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(loaded.GetSystem<MeshComponentManager>().ComponentCount == 1);
		let component = SoleMesh(loaded);
		Test.Assert(component != null);

		// The identity survived, and the product is not bound until the resolve runs.
		Test.Assert(component.Mesh.Id == meshId);
		Test.Assert(component.Mesh.Get == null);
		Test.Assert(Near(component.Color.R, 0.5f));

		SceneResolve.ResolveSceneResources(loaded, fixture.Manager);
		let live = component.Mesh.Get;
		Test.Assert(live != null);
		Test.Assert(!live.Vertices.IsEmpty);
		Test.Assert(Near(live.Bounds.Max.X - live.Bounds.Min.X, 1.0f));

		// PROXY semantics: rewrite the cooked source as a bigger cube, reload, and the SAME
		// reference sees the new product through its handle with no second resolve. Reference
		// equality is not a valid signal here: the allocator may hand back the freed block.
		{
			let bigger = Primitives.Cube(2.0f);
			defer delete bigger;
			fixture.Recook(meshId, bigger);
		}
		fixture.Manager.Reload(meshId);

		let reloaded = component.Mesh.Get;
		Test.Assert(reloaded != null);
		Test.Assert(Near(reloaded.Bounds.Max.X - reloaded.Bounds.Min.X, 2.0f));
	}

	/// A DIRECT object is the procedural path, and it wins over anything the id would
	/// resolve to. It is runtime only and never serialized.
	[Test]
	public static void DirectObjectsWinOverProxiesAndSkipSerialization()
	{
		let procedural = Primitives.Cube(2.0f);
		defer delete procedural;

		var component = MeshComponent();
		component.Mesh.SetDirect(procedural);
		Test.Assert(component.Mesh.Get == procedural);
		// Nothing to serialize.
		Test.Assert(component.Mesh.Id == Guid());

		// An id ALONGSIDE a direct object: the object still wins.
		component.Mesh.SetId(Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11));
		Test.Assert(component.Mesh.Get == procedural);
	}

	/// The editor's mesh picker offers SKINNED products for a static mesh reference, a skinned
	/// mesh being one. The factory has to build the real skinned product: building it as a
	/// plain one silently drops the skinning stream and the mesh can never animate.
	[Test]
	public static void AReferenceBoundToASkinnedProductKeepsTheSkinStream()
	{
		let fixture = scope RenderResourceFixture("scratch_render_skinref_db");

		Guid meshId;
		{
			// A skinned cube: the static cube's streams with one skinning entry per vertex.
			let cube = Primitives.Cube(1.0f);
			defer delete cube;
			let skinned = scope SkinnedMesh();
			skinned.Vertices.AddRange(cube.Vertices);
			skinned.Indices.Resize(cube.Indices.Count);
			for (uint32 i < cube.Indices.Count)
				skinned.Indices.Set(i, cube.Indices.Get(i));
			skinned.SubMeshes.AddRange(cube.SubMeshes);
			skinned.Bounds = cube.Bounds;
			for (int i < skinned.Vertices.Count)
				skinned.Skinning.Add(VertexSkinning());
			skinned.SkeletonIndex = 0;

			meshId = fixture.CookSkinned("SkinnedCube", skinned);
		}

		var component = MeshComponent();
		component.Mesh.SetId(meshId);
		component.Mesh.Bind(fixture.Manager);

		let live = component.Mesh.Get;
		Test.Assert(live != null);
		Test.Assert(live.IsSkinned);
		Test.Assert(live.Vertices.Count == 24);
		let skinnedLive = live as SkinnedMesh;
		Test.Assert(skinnedLive != null);
		Test.Assert(skinnedLive.SkinningStream.Length == 24);
	}

	/// The SHAPE of the per submesh material references: the ids round trip and the list
	/// survives the resolve. Binding itself is the mesh path above; real material products
	/// would drag the whole shader stack in, so the manager here has no material factory.
	[Test]
	public static void PerSubmeshMaterialRefsRoundTripAndSurviveTheResolve()
	{
		let fixture = scope RenderResourceFixture("scratch_render_submesh_ref_db");

		let matA = Guid(0xA1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		let matB = Guid(0xB2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0);

		let blob = scope MemoryStream();
		{
			let scene = scope Scene();
			let meshes = scene.AddSystem<MeshComponentManager>();
			let entity = scene.CreateEntity("Multi");
			let component = meshes.Add(entity);

			var a = Ref<Material>(Guid());
			a.SetId(matA);
			component.Materials.Add(a);
			var b = Ref<Material>(Guid());
			b.SetId(matB);
			component.Materials.Add(b);

			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, scene);
			Test.Assert(writer.IsOk);
		}

		let loaded = scope Scene();
		loaded.AddSystem<MeshComponentManager>();
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		let component = SoleMesh(loaded);
		Test.Assert(component != null);
		Test.Assert(component.Materials.Count == 2);
		Test.Assert(component.Materials[0].Id == matA);
		Test.Assert(component.Materials[1].Id == matB);

		// Attaches the bindings; the cache itself fills at extract.
		SceneResolve.ResolveSceneResources(loaded, fixture.Manager);
		Test.Assert(component.Materials.Count == 2);
	}

	/// The manager's live swap pair. With no resource manager the id is set and nothing is
	/// bound, which is what a bare tool gets.
	[Test]
	public static void TheManagerSwapsAMeshAndAMaterialSlotById()
	{
		let scene = scope Scene();
		let meshes = scene.AddSystem<MeshComponentManager>();
		let entity = scene.CreateEntity("Box");
		meshes.Add(entity);

		let meshId = Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		let redId = Guid(2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		let blueId = Guid(3, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);

		Test.Assert(meshes.SetMesh(entity, meshId));
		Test.Assert(meshes.SetMaterial(entity, redId));

		let component = meshes.Get(entity);
		Test.Assert(component.Mesh.Id == meshId);
		Test.Assert(component.Mesh.Get == null, "no manager, so nothing bound");
		// Slot 0 is the whole mesh slot, and the list was empty until the set.
		Test.Assert(component.Materials.Count == 1);
		Test.Assert(component.Materials[0].Id == redId);

		// A higher slot grows the list rather than failing: a mesh may be bound before its
		// materials are.
		Test.Assert(meshes.SetMaterial(entity, blueId, 2));
		Test.Assert(component.Materials.Count == 3);
		Test.Assert(component.Materials[2].Id == blueId);
		Test.Assert(component.Materials[0].Id == redId, "the slot that was already set held");

		// An entity with no component, and a nonsense slot, are clean misses.
		Test.Assert(!meshes.SetMaterial(scene.CreateEntity("Bare"), redId));
		Test.Assert(!meshes.SetMaterial(entity, redId, -1));
	}
}
