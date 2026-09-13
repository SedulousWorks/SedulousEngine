using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// The scene to renderer bridge: entities with meshes and a camera go in, an ExtractedScene
/// the scene agnostic renderer can consume comes out.
class ExtractSceneTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// Builds a scene of `count` quads at world x of nought through count minus one. The mesh
	/// and material are the caller's to delete.
	private static void BuildBigScene(Scene scene, int32 count, out StaticMesh mesh,
		out Material material)
	{
		let meshes = scene.AddSystem<MeshComponentManager>();
		mesh = Primitives.Quad();
		let builder = scope MaterialBuilder("lit");
		material = builder..Shader("forward").Build();

		for (int32 i < count)
		{
			let entity = scene.CreateEntity();
			scene.SetLocalPosition(entity, .((float)i, 0, 0));
			let component = meshes.Add(entity);
			component.Mesh.SetDirect(mesh);
			component.SetMaterial(material);
		}
		scene.UpdateTransforms();
	}

	/// The world x sum is a drop and duplicate proof invariant: every entity contributes its
	/// index exactly once.
	private static double SumWorldX(ExtractedScene snapshot)
	{
		double sum = 0;
		for (let item in snapshot.Items)
			sum += ((MeshRenderData)item).World.M[3][0];
		return sum;
	}

	[Test]
	public static void ExtractBuildsTheDrawListAndReadsTheCamera()
	{
		let scene = scope Scene("world");
		let meshes = scene.AddSystem<MeshComponentManager>();
		let cameras = scene.AddSystem<CameraComponentManager>();

		let camEntity = scene.CreateEntity("camera");
		scene.SetLocalPosition(camEntity, .(0, 0, 5));
		let camera = cameras.Add(camEntity);
		camera.Aspect = 1.0f;

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let builder = scope MaterialBuilder("lit");
		let material = builder..Shader("forward").Build();
		defer delete material;

		let a = scene.CreateEntity("a");
		scene.SetLocalPosition(a, .(-2, 0, 0));
		{
			let component = meshes.Add(a);
			component.Mesh.SetDirect(cube);
			component.SetMaterial(material);
			component.Color = .(0.2f, 0.4f, 0.8f, 1.0f);
		}

		let b = scene.CreateEntity("b");
		scene.SetLocalPosition(b, .(3, 0, 0));
		{
			let component = meshes.Add(b);
			component.Mesh.SetDirect(cube);
			component.SetMaterial(material);
		}

		scene.UpdateTransforms();

		var view = ViewCamera();
		Test.Assert(RenderExtract.ExtractPrimaryCamera(scene, ref view));
		// The view is the INVERSE of the camera's world matrix.
		Test.Assert(Near(view.View.M[3][2], -5.0f));
		// A real perspective projection.
		Test.Assert(!Near(view.Projection.M[2][3], 0.0f));

		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractSceneInto(scene, snapshot);
		Test.Assert(snapshot.Size == 2);

		float sumX = 0.0f;
		bool sawBlue = false;
		for (let item in snapshot.Items)
		{
			let data = (MeshRenderData)item;
			// An opaque material lands in the opaque category.
			Test.Assert(data.Category == RenderCategories.Opaque);
			Test.Assert(data.Mesh == cube);
			Test.Assert(data.Material == material);
			// Tagged with a packed entity handle.
			Test.Assert(data.EntityId != 0);
			sumX += data.World.M[3][0];
			// The per instance tint carries through.
			if (Near(data.Color.B, 0.8f))
				sawBlue = true;
		}
		Test.Assert(Near(sumX, 1.0f));
		Test.Assert(sawBlue);
	}

	[Test]
	public static void ExtractSkipsInvisibleAndMeshlessComponents()
	{
		let scene = scope Scene();
		let meshes = scene.AddSystem<MeshComponentManager>();
		let cameras = scene.AddSystem<CameraComponentManager>();

		let mesh = Primitives.Quad();
		defer delete mesh;

		let visible = scene.CreateEntity();
		meshes.Add(visible).Mesh.SetDirect(mesh);

		let hidden = scene.CreateEntity();
		{
			let component = meshes.Add(hidden);
			component.Mesh.SetDirect(mesh);
			component.Visible = false;
		}

		// No mesh assigned at all.
		meshes.Add(scene.CreateEntity());

		let secondary = scene.CreateEntity();
		cameras.Add(secondary).Primary = false;

		scene.UpdateTransforms();

		var view = ViewCamera();
		// No primary camera.
		Test.Assert(!RenderExtract.ExtractPrimaryCamera(scene, ref view));

		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractSceneInto(scene, snapshot);
		// Only the visible, meshed one.
		Test.Assert(snapshot.Size == 1);
	}

	[Test]
	public static void ExtractOnASceneWithoutRenderManagersIsEmpty()
	{
		let scene = scope Scene();
		scene.CreateEntity();
		scene.UpdateTransforms();

		var view = ViewCamera();
		Test.Assert(!RenderExtract.ExtractPrimaryCamera(scene, ref view));

		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractSceneInto(scene, snapshot);
		Test.Assert(snapshot.Size == 0);
	}

	/// Past the threshold the extraction fans out. Every renderable has to land exactly once.
	[Test]
	public static void ParallelExtractionTakesEveryRenderableExactlyOnce()
	{
		InitGlobalJobSystem(4);
		defer ShutdownGlobalJobSystem();

		const int32 cCount = 2000;
		let scene = scope Scene();
		BuildBigScene(scene, cCount, var mesh, var material);
		defer delete mesh;
		defer delete material;

		let context = scope RenderContext();
		context.BeginFrame((uint32)GlobalJobs().SlotCount);

		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractSceneInto(scene, snapshot, context);

		// No drops and no duplicates.
		Test.Assert(snapshot.Size == cCount);
		Test.Assert(SumWorldX(snapshot) == (double)cCount * (cCount - 1) / 2.0);
	}

	[Test]
	public static void ContextExtractionFallsBackToSerialWithoutAJobSystem()
	{
		// None started in this test binary.
		Test.Assert(!HasGlobalJobSystem());

		let scene = scope Scene();
		BuildBigScene(scene, 50, var mesh, var material);
		defer delete mesh;
		defer delete material;

		let context = scope RenderContext();
		context.BeginFrame(1);

		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractSceneInto(scene, snapshot, context);

		Test.Assert(snapshot.Size == 50);
		Test.Assert(SumWorldX(snapshot) == (double)50 * 49 / 2.0);
	}

	[Test]
	public static void ATransparentMaterialLandsInTheTransparentCategory()
	{
		let scene = scope Scene();
		let meshes = scene.AddSystem<MeshComponentManager>();

		let mesh = Primitives.Quad();
		defer delete mesh;
		let builder = scope MaterialBuilder("glass");
		let glass = builder..Shader("forward")..Transparent().Build();
		defer delete glass;

		let entity = scene.CreateEntity();
		{
			let component = meshes.Add(entity);
			component.Mesh.SetDirect(mesh);
			component.SetMaterial(glass);
		}
		scene.UpdateTransforms();

		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractSceneInto(scene, snapshot);
		Test.Assert(snapshot.Size == 1);
		Test.Assert(snapshot.Items[0].Category == RenderCategories.Transparent);
	}
}
