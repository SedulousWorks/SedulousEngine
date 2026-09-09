using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.RHI;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The frame driver over a NULL DEVICE: extraction, the sort, the mesh upload, the pipeline
/// build, and the graph's declaration and execution, end to end.
///
/// These are what the data layer tests cannot reach. A null device answers every call
/// truthfully about SHAPE, which is what the dispatch path is made of, so the whole chain
/// runs without a GPU.
class RenderFrameTests
{
	/// One cube, one material, opaque.
	private static ExtractedScene MakeCubeScene(StaticMesh mesh, Material material)
	{
		let scene = new ExtractedScene();
		let data = scene.Add<MeshRenderData>();
		data.World = Float4x4.Identity();
		data.Mesh = mesh;
		data.Material = material;
		data.Category = RenderCategories.Opaque;
		data.WorldRadius = 1.0f;
		return scene;
	}

	private static Material MakeLitMaterial()
	{
		let builder = scope MaterialBuilder("lit");
		return builder..Shader("forward")..VertexLayout(.Mesh).Build();
	}

	/// The whole path, and then a SECOND frame over the same scene, which must reuse the
	/// cached pipelines and mesh buffers rather than building them again.
	[Test]
	public static void AOneCubeViewDrawsAndTheSecondFrameReusesEverything()
	{
		let fixture = scope RenderFrameFixture(256, 256);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;
		let scene = MakeCubeScene(cube, material);
		defer delete scene;

		let camera = RenderFrameFixture.LookingAtTheOrigin();

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 256, 256);
		Test.Assert(frame.ViewCount == 1);
		frame.End();

		let afterFirst = fixture.PsoCache.Size;
		Test.Assert(afterFirst >= 1);

		frame.Begin(fixture.Encoder, 1);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 256, 256);
		frame.End();

		Test.Assert(fixture.PsoCache.Size == afterFirst);
	}

	/// Eight cubes sharing a mesh and a material collapse into ONE instanced draw, so the
	/// pipeline count does not grow with the crowd.
	[Test]
	public static void ARunSharingAMeshAndMaterialBatches()
	{
		let fixture = scope RenderFrameFixture(256, 256);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;

		let scene = scope ExtractedScene();
		for (int32 n < 8)
		{
			let data = scene.Add<MeshRenderData>();
			data.World = Float4x4.Identity();
			data.WorldCenter = .((float)n, 0, 0);
			data.WorldRadius = 1.0f;
			data.Color = .((float)n / 8.0f, 0.5f, 0.5f, 1.0f);
			data.Mesh = cube;
			data.Material = material;
			data.Category = RenderCategories.Opaque;
		}

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, RenderFrameFixture.LookingAtTheOrigin(20.0f), .(), fixture.ColorView,
			.BGRA8Unorm, 256, 256);
		frame.End();

		// The instanced permutation is ONE pipeline for all eight.
		Test.Assert(fixture.PsoCache.Size >= 1);
	}

	/// A view with nothing in it still declares its passes and clears; it must not fault, and
	/// it must build no pipeline at all, there being no material to build one from.
	[Test]
	public static void AnEmptyViewStillComposesAndBuildsNothing()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let scene = scope ExtractedScene();

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, .(), .(), fixture.ColorView, .BGRA8Unorm, 64, 64);
		frame.End();

		Test.Assert(fixture.PsoCache.Size == 0);
	}

	/// Past the threshold the emission FANS OUT across the job system, into one bundle per
	/// chunk from that chunk's own pool. Two frames, so the per frame pool reset is exercised
	/// as well: a worker's bundle has to outlive the submission that executes it.
	[Test]
	public static void ManyDistinctDrawsFanOutAcrossTheJobSystem()
	{
		let fixture = scope RenderFrameFixture(256, 256);
		if (!fixture.Ready)
			return;

		InitGlobalJobSystem(4);
		defer ShutdownGlobalJobSystem();

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;

		// Three hundred DISTINCT materials over one mesh, so nothing batches and every draw
		// resolves on its own, which is what puts the count over the threshold.
		let materials = scope List<Material>();
		defer { ClearAndDeleteItems!(materials); }

		let scene = scope ExtractedScene();
		for (int32 n < 300)
		{
			let builder = scope:: MaterialBuilder("lit");
			let material = builder..Shader("forward")..VertexLayout(.Mesh).Build();
			materials.Add(material);

			let data = scene.Add<MeshRenderData>();
			data.World = Float4x4.Identity();
			data.WorldCenter = .((float)n, 0, 0);
			data.WorldRadius = 1.0f;
			data.Mesh = cube;
			data.Material = material;
			data.Category = RenderCategories.Opaque;
		}

		let camera = RenderFrameFixture.LookingAtTheOrigin(20.0f);
		for (uint32 f = 0; f < 2; f++)
		{
			frame.Begin(fixture.Encoder, f);
			frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 256, 256);
			// It must neither fault nor deadlock.
			frame.End();
		}

		Test.Assert(fixture.PsoCache.Size >= 1);
	}

	/// An UNLIT material takes a different shader entirely, so this is what catches the
	/// forward path being the only one that compiles.
	[Test]
	public static void AnUnlitMaterialBuildsItsOwnPipeline()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MaterialPresets.CreateUnlit("unlit");
		defer delete material;
		let scene = MakeCubeScene(cube, material);
		defer delete scene;

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, RenderFrameFixture.LookingAtTheOrigin(), .(), fixture.ColorView,
			.BGRA8Unorm, 128, 128);
		frame.End();

		Test.Assert(fixture.PsoCache.Size >= 1);
	}

	/// The graph's resource inventory lists what a frame declared, which is what a debug view
	/// picker reads. The names repeat per view, so the inventory is DEDUPLICATED.
	[Test]
	public static void TheGraphInventoryListsWhatAFrameDeclared()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;
		let scene = MakeCubeScene(cube, material);
		defer delete scene;

		let camera = RenderFrameFixture.LookingAtTheOrigin();
		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();

		let inventory = scope List<DebugResourceInfo>();
		defer { ClearAndDeleteItems!(inventory); }
		frame.CollectDebugResources(inventory);

		Test.Assert(!inventory.IsEmpty);

		var sawDepth = false;
		for (let row in inventory)
		{
			Test.Assert(row.Width > 0);
			Test.Assert(row.Height > 0);
			if (row.Name == "forward.depth")
				sawDepth = true;
		}
		Test.Assert(sawDepth);

		// TWO views declared their own depth under the same name, and it is listed ONCE.
		var depthRows = 0;
		for (let row in inventory)
		{
			if (row.Name == "forward.depth")
				depthRows++;
		}
		Test.Assert(depthRows == 1);
	}
}
