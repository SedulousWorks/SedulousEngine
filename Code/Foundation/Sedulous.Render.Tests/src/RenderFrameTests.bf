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

	/// A skinned triangle: one joint per vertex, which is all the pool cares about.
	private static SkinnedMesh MakeSkinnedTriangle()
	{
		let mesh = new SkinnedMesh();
		for (uint32 i < 3)
		{
			mesh.Vertices.Add(StaticMeshVertex(.((float)i, 0.0f, 0.0f), .(0.0f, 1.0f, 0.0f),
				.(0.0f, 0.0f), 0xFFFFFFFF, Float3(1.0f, 0.0f, 0.0f)));

			var skin = VertexSkinning();
			skin.Joints = .((uint16)i, 0, 0, 0);
			skin.Weights = .(1.0f, 0.0f, 0.0f, 0.0f);
			mesh.Skinning.Add(skin);
		}
		mesh.Indices.Resize(3);
		mesh.Indices.AddTriangle(0, 1, 2);
		return mesh;
	}

	/// The bone pool starts SMALL and grows the frame that needs more.
	///
	/// It used to reserve its 1M slot cap up front: 128 MB of staging plus a 128 MB device
	/// mirror, in a pool that is empty in any scene without skinning. Growth happens before
	/// the frame's block is allocated, so the frame that grows still skins everything.
	[Test]
	public static void TheBonePoolStartsSmallAndGrowsTheFrameThatNeedsMore()
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

		let skinned = MakeSkinnedTriangle();
		defer delete skinned;
		let material = MakeLitMaterial();
		defer delete material;

		// Casters dedupe by their bone matrix POINTER, so each needs its own palette.
		// Forty of sixty four bones, current and previous slab, is 5120: over the initial 4096.
		const int cBones = 64;
		const int cCasters = 40;
		let palettes = scope List<Float4x4[cBones]>();
		palettes.Resize(cCasters);

		let scene = scope ExtractedScene();
		for (int c < cCasters)
		{
			for (int b < cBones)
				palettes[c][b] = Float4x4.Identity();

			let data = scene.Add<MeshRenderData>();
			data.World = Float4x4.Identity();
			data.Mesh = skinned;
			data.Material = material;
			data.Category = RenderCategories.Opaque;
			data.WorldRadius = 1.0f;
			data.BoneMatrices = &palettes[c][0];
			data.BoneCount = cBones;
		}

		let camera = RenderFrameFixture.LookingAtTheOrigin();

		// Nothing is reserved before the first frame: PrepareFrame is what sizes the rings.
		Test.Assert(meshRenderer.BonePoolSlotsPerFrame == 0, "nothing reserved up front");

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 256, 256);
		frame.End();
		Test.Assert(meshRenderer.BonePoolSlotsPerFrame == 8192,
			scope $"grew to the next power of two, not {meshRenderer.BonePoolSlotsPerFrame}");

		frame.Begin(fixture.Encoder, 1);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 256, 256);
		frame.End();
		Test.Assert(meshRenderer.BonePoolSlotsPerFrame == 8192, "and the next frame keeps it");

		// A scene that FITS never grows it.
		let small = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(small.Initialize() case .Ok);

		let smallRegistry = scope RendererRegistry();
		smallRegistry.Register(small);
		let smallFrame = scope RenderFrame(fixture.Device, smallRegistry, 2);

		let one = scope ExtractedScene();
		let data = one.Add<MeshRenderData>();
		data.World = Float4x4.Identity();
		data.Mesh = skinned;
		data.Material = material;
		data.Category = RenderCategories.Opaque;
		data.WorldRadius = 1.0f;
		data.BoneMatrices = &palettes[0][0];
		data.BoneCount = cBones;

		smallFrame.Begin(fixture.Encoder, 0);
		smallFrame.AddView(one, camera, .(), fixture.ColorView, .BGRA8Unorm, 256, 256);
		smallFrame.End();
		Test.Assert(small.BonePoolSlotsPerFrame == MeshRenderer.InitialBonePoolSlots,
			"a scene that fits left it alone");
	}

	/// The caster list asks the DATA what it is, never the renderer id.
	///
	/// With an external renderer registered FIRST it holds id nought, which is the terrain
	/// probe's shape and any embedding that adds its own renderer before the built in one. The
	/// old id gate then narrowed junk data to mesh data: it counted the two junk items as
	/// animated casters and missed the real skinned one.
	[Test]
	public static void TheCasterListAsksTheDataWhatItIsNotTheRendererId()
	{
		// The stamp: the base is Generic, mesh data and everything derived from it is Mesh.
		let generic = scope RenderData();
		let mesh = scope MeshRenderData();
		let multi = scope MultiMeshRenderData();
		let junkStamp = scope JunkRenderData();
		Test.Assert(generic.Kind == .Generic);
		Test.Assert(mesh.Kind == .Mesh);
		Test.Assert(multi.Kind == .Mesh, "a subclass inherits the stamp");
		Test.Assert(junkStamp.Kind == .Generic, "an external renderer's data is Generic");

		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);

		// The EXTERNAL one registers first, so it holds nought and the mesh renderer does not.
		let external = scope InertOpaqueRenderer();
		let registry = scope RendererRegistry();
		registry.Register(external);
		registry.Register(meshRenderer);
		Test.Assert(external.RendererId == 0);
		Test.Assert(meshRenderer.RendererId == 1);

		let shadows = scope ShadowSystem(fixture.Device, 2);
		Test.Assert(shadows.Initialize() case .Ok);

		let frame = scope RenderFrame(fixture.Device, registry, 2, null, null, shadows);

		let skinned = MakeSkinnedTriangle();
		defer delete skinned;
		let material = MakeLitMaterial();
		defer delete material;
		Float4x4[8] palette = .();
		for (int b < 8)
			palette[b] = Float4x4.Identity();

		// Two junk casters from the external renderer, and one skinned mesh caster.
		let scene = scope ExtractedScene();
		for (int i < 2)
		{
			let junk = scene.Add<JunkRenderData>();
			junk.Category = RenderCategories.Opaque;
			junk.RendererId = external.RendererId;
			junk.WorldCenter = .((float)i, 0.0f, 0.0f);
			junk.WorldRadius = 1.0f;
		}

		let data = scene.Add<MeshRenderData>();
		data.World = Float4x4.Identity();
		data.Mesh = skinned;
		data.Material = material;
		data.Category = RenderCategories.Opaque;
		data.RendererId = meshRenderer.RendererId;
		data.BoneMatrices = &palette[0];
		data.BoneCount = 8;
		data.WorldRadius = 1.0f;

		var shadow = DirectionalShadow();
		shadow.Direction = Normalized(Float3(0.3f, -1.0f, 0.2f));
		shadow.Valid = true;
		scene.SetDirectionalShadow(shadow);

		let camera = RenderFrameFixture.LookingAtTheOrigin();
		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();

		// All three are casters, on the base fields alone; exactly the skinned MESH is animated.
		Test.Assert(frame.ShadowCasterCount(scene) == 3, "every opaque item casts");
		Test.Assert(frame.AnimatedShadowCasterCount(scene) == 1,
			scope $"one animated caster, not {frame.AnimatedShadowCasterCount(scene)}");
	}

	/// The shadow passes draw the scene's caster list, which the camera does not cull, so the
	/// rings must be sized for the casters and not only the view's draws. Each view draws its own
	/// cascades from its scene's casters: two views of one scene with three casters is six.
	[Test]
	public static void TheRenderersAreToldEveryViewsShadowCasters()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let capture = scope CapturingRenderer();
		let registry = scope RendererRegistry();
		registry.Register(capture);
		let shadows = scope ShadowSystem(fixture.Device, 2);
		Test.Assert(shadows.Initialize() case .Ok);
		let frame = scope RenderFrame(fixture.Device, registry, 2, null, null, shadows);

		let scene = scope ExtractedScene();
		for (int i < 3)
		{
			let junk = scene.Add<JunkRenderData>();
			junk.Category = RenderCategories.Opaque;
			junk.RendererId = capture.RendererId;
			junk.WorldCenter = .((float)i * 4.0f, 0.0f, 0.0f);
			junk.WorldRadius = 1.0f;
		}
		var shadow = DirectionalShadow();
		shadow.Direction = Normalized(Float3(0.3f, -1.0f, 0.2f));
		shadow.Valid = true;
		scene.SetDirectionalShadow(shadow);

		let camera = RenderFrameFixture.LookingAtTheOrigin();
		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();

		Test.Assert(frame.ShadowCasterCount(scene) == 3);
		Test.Assert(capture.ShadowCasterDraws == 6, scope $"told {capture.ShadowCasterDraws}");
	}

	/// The rings hold the larger of the views' draws and the casters, in every pass.
	[Test]
	public static void TheInstanceRingsHoldTheLargerOfDrawsAndCasters()
	{
		// 150 draws in view, 330 casters, 4 cascades and 2 local tiles, a probe face and a pick.
		Test.Assert(MeshRenderer.InstanceSlotsPerFrame(150, 330, 6, 2) == 330 * (2 + 6 + 2));
		Test.Assert(MeshRenderer.InstanceSlotsPerFrame(400, 10, 4, 0) == 400 * (2 + 4));
		Test.Assert(MeshRenderer.InstanceSlotsPerFrame(0, 0, 4, 0) == 0);
	}

	/// A view's between frame state follows its history key, not its place in the frame's
	/// list: a render texture drawn on alternate frames before the main view (PaperKid's
	/// minimap) moved the main view between places 0 and 1 every frame, so it read the other
	/// view's camera and TAA history.
	[Test]
	public static void AViewKeepsItsHistorySlotByItsKeyWhereverItFallsInTheFrame()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let registry = scope RendererRegistry();
		let frame = scope RenderFrame(fixture.Device, registry, 2);

		frame.Begin(fixture.Encoder, 0);
		let main = frame.HistorySlotFor(1001, 0, var fresh); // the main view, alone
		Test.Assert(fresh);
		frame.End();

		frame.Begin(fixture.Encoder, 1);
		let side = frame.HistorySlotFor(2002, 0, out fresh); // a render texture, drawn first
		Test.Assert(fresh);
		Test.Assert(side != main);
		Test.Assert(frame.HistorySlotFor(1001, 1, out fresh) == main); // now second: the same slot
		Test.Assert(!fresh);
		frame.End();

		frame.Begin(fixture.Encoder, 0);
		Test.Assert(frame.HistorySlotFor(1001, 0, out fresh) == main); // first again, still the same
		Test.Assert(!fresh);
		frame.End();

		// Every slot taken: a new key takes the one seen longest ago (the side view's), never
		// one in use this frame, and is told it is fresh.
		for (uint32 f = 0; f < RenderFrame.cHistorySlots; f++)
		{
			frame.Begin(fixture.Encoder, f % 2);
			frame.HistorySlotFor(1001, 0, out fresh);
			for (uint64 k = 0; k < RenderFrame.cHistorySlots - 2; k++)
				frame.HistorySlotFor(5000 + k, (uint32)(k + 1), out fresh);
			frame.End();
		}
		frame.Begin(fixture.Encoder, 0);
		frame.HistorySlotFor(1001, 0, out fresh);
		let newcomer = frame.HistorySlotFor(9009, 1, out fresh);
		Test.Assert(fresh);
		Test.Assert(newcomer == side);
		frame.End();
	}
}
