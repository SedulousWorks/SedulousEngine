using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.RHI;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The per scene shadow composition, which is what a frame rendering SEVERAL SCENES side by
/// side depends on.
///
/// Every shadow input comes from the view's OWN scene: sourcing them from one primary scene
/// bleeds one scene's shadows into another and never renders the other's at all.
class RenderShadowCompositionTests
{
	private static void AddCube(ExtractedScene scene, StaticMesh mesh, Material material)
	{
		let data = scene.Add<MeshRenderData>();
		data.World = Float4x4.Identity();
		data.Mesh = mesh;
		data.Material = material;
		data.Category = RenderCategories.Opaque;
		data.WorldRadius = 1.0f;
	}

	private static void AddSpotCaster(ExtractedScene scene, Float3 position)
	{
		var caster = LocalShadowCaster();
		caster.Type = 2;
		caster.PositionWS = position;
		caster.DirectionWS = .(0, -1, 0);
		caster.Range = 10.0f;
		caster.OuterAngle = 0.8f;
		scene.AddLocalShadowCaster(caster);
	}

	private static Material MakeLitMaterial()
	{
		let builder = scope MaterialBuilder("lit");
		return builder..Shader("forward")..VertexLayout(.Mesh).Build();
	}

	/// Each scene's lights go up once a frame, into a ring sized for every scene. The upload ran
	/// per renderer run in every pass of every view, into a ring of 256 a frame: a scene with many
	/// lights, or two scenes, ran it out, and a view whose upload failed read the lights of
	/// whichever scene went first.
	[Test]
	public static void EachScenesLightsGoUpOnceAFrame()
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

		let lights = (uint32)200;
		let first = scope ExtractedScene();
		let second = scope ExtractedScene();
		ExtractedScene[2] both = .(first, second);
		for (let scene in both)
		{
			AddCube(scene, cube, material);
			for (uint32 i < lights)
			{
				var light = GpuLight();
				light.Type = 1.0f;
				light.PositionWS = .((float)i, 2, 0);
				light.Range = 3.0f;
				scene.AddLight(light);
			}
		}
		let camera = RenderFrameFixture.LookingAtTheOrigin();

		// Each scene drawn through two views: each scene's lights go up once, and the ring holds
		// both scenes' in the first frame.
		frame.Begin(fixture.Encoder, 0);
		for (let scene in both)
		{
			frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
			frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		}
		frame.End();
		Test.Assert(meshRenderer.LightSlotsPerFrame >= 2 * lights);
		Test.Assert(meshRenderer.LightSlotsUsed == 2 * lights);

		// One scene alone takes its lights once.
		frame.Begin(fixture.Encoder, 1);
		frame.AddView(first, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.AddView(first, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();
		Test.Assert(meshRenderer.LightSlotsUsed == lights);
	}

	/// Two scenes in ONE frame: only the one with a directional caster gets cascades, both
	/// bind the map, and both scenes' local casters get entries in the concatenated buffer at
	/// their own bases.
	[Test]
	public static void EachViewSourcesItsOwnScene()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let shadows = scope ShadowSystem(fixture.Device, 2);
		Test.Assert(shadows.Initialize() case .Ok);

		let frame = scope RenderFrame(fixture.Device, registry, 2, null, null, shadows);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;

		// One scene has a spot caster alone; the other has a directional caster too.
		let sceneA = scope ExtractedScene();
		AddCube(sceneA, cube, material);
		AddSpotCaster(sceneA, .(0, 5, 0));

		let sceneB = scope ExtractedScene();
		AddCube(sceneB, cube, material);
		AddSpotCaster(sceneB, .(7, 3, 2));
		var directional = DirectionalShadow();
		directional.Direction = Normalized(Float3(0.3f, -1.0f, 0.2f));
		directional.Valid = true;
		sceneB.SetDirectionalShadow(directional);

		let camera = RenderFrameFixture.LookingAtTheOrigin();

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(sceneA, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.AddView(sceneB, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();

		let info = frame.ViewShadowInfo;
		Test.Assert(info.Length == 2);

		// ONLY the scene with a caster of its own gets cascades.
		Test.Assert(!info[0].Directional);
		Test.Assert(info[1].Directional);

		// But BOTH views bind and declare the map. The caster-less view's own group holds the
		// real map, frame globally, and its shading samples it whether or not its scene casts,
		// so an undeclared read would run against layers still held as attachments.
		Test.Assert(info[0].MapBound);
		Test.Assert(info[1].MapBound);

		// Both scenes' spot casters got entries, and each view offsets by its scene's base.
		let entries = frame.LocalShadowEntries;
		Test.Assert(entries.Length == 2);
		Test.Assert(info[0].LocalEntryBase == 0);
		Test.Assert(info[1].LocalEntryBase == 1);

		// Distinct tiles, from the global counters, and neither entry is degenerate.
		Test.Assert(entries[0].AtlasScaleBias.Z != entries[1].AtlasScaleBias.Z);
		Test.Assert(entries[0].AtlasScaleBias.X > 0.0f);
		Test.Assert(entries[1].AtlasScaleBias.X > 0.0f);
	}

	/// TWO VIEWS OF ONE SCENE share its context, so its casters are laid out once and both
	/// views read the same base.
	[Test]
	public static void TwoViewsOfOneSceneShareItsContext()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let shadows = scope ShadowSystem(fixture.Device, 2);
		Test.Assert(shadows.Initialize() case .Ok);

		let frame = scope RenderFrame(fixture.Device, registry, 2, null, null, shadows);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;

		let scene = scope ExtractedScene();
		AddCube(scene, cube, material);
		AddSpotCaster(scene, .(7, 3, 2));
		var directional = DirectionalShadow();
		directional.Direction = Normalized(Float3(0.3f, -1.0f, 0.2f));
		directional.Valid = true;
		scene.SetDirectionalShadow(directional);

		let camera = RenderFrameFixture.LookingAtTheOrigin();

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();

		let info = frame.ViewShadowInfo;
		Test.Assert(info.Length == 2);
		Test.Assert(info[0].Directional);
		Test.Assert(info[1].Directional);
		// The SAME scene, so the same context and the same base.
		Test.Assert(info[0].LocalEntryBase == 0);
		Test.Assert(info[1].LocalEntryBase == 0);
		// One caster, laid out once rather than once per view.
		Test.Assert(frame.LocalShadowEntries.Length == 1);
	}

	/// A scene with no caster at all leaves every view unshadowed and the map unbound, rather
	/// than binding a map that was never made.
	[Test]
	public static void ASceneWithNoCasterBindsNoMap()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let shadows = scope ShadowSystem(fixture.Device, 2);
		Test.Assert(shadows.Initialize() case .Ok);

		let frame = scope RenderFrame(fixture.Device, registry, 2, null, null, shadows);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;

		let scene = scope ExtractedScene();
		AddCube(scene, cube, material);

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, RenderFrameFixture.LookingAtTheOrigin(), .(), fixture.ColorView,
			.BGRA8Unorm, 128, 128);
		frame.End();

		let info = frame.ViewShadowInfo;
		Test.Assert(info.Length == 1);
		Test.Assert(!info[0].Directional);
		Test.Assert(!info[0].MapBound);
		Test.Assert(frame.LocalShadowEntries.IsEmpty);
	}

	/// A view's cascades draw only the casters whose shadow can reach it; the scene's caster list
	/// keeps them all, since another view or a local light may need them.
	[Test]
	public static void AViewsCascadesDrawOnlyTheCastersWhoseShadowCanReachIt()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let shadows = scope ShadowSystem(fixture.Device, 2);
		Test.Assert(shadows.Initialize() case .Ok);
		let frame = scope RenderFrame(fixture.Device, registry, 2, null, null, shadows);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;

		// The sun straight down over three casters: one in front of the camera, one 55 m behind
		// it (its shadow falls behind it too) and one far above anything a cascade carries a
		// shadow from.
		let scene = scope ExtractedScene();
		Float3[3] places = .(.(0, 0, 0), .(0, 0, 60), .(0, 5000, 0));
		for (let place in places)
		{
			let data = scene.Add<MeshRenderData>();
			data.World = Float4x4.Translation(place);
			data.Mesh = cube;
			data.Material = material;
			data.Category = RenderCategories.Opaque;
			data.WorldCenter = place;
			data.WorldRadius = 1.0f;
		}
		var directional = DirectionalShadow();
		directional.Direction = .(0, -1, 0);
		directional.Valid = true;
		scene.SetDirectionalShadow(directional);

		var camera = RenderFrameFixture.LookingAtTheOrigin();
		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();

		Test.Assert(frame.ShadowCasterCount(scene) == 3);
		var info = frame.ViewShadowInfo;
		Test.Assert(info.Length == 1);
		Test.Assert(info[0].Directional);
		Test.Assert(info[0].DirectionalCasters == 1, "only the caster whose shadow it can see");
		// The scene lies within a few metres of the camera along its view: the nearer cascades
		// hold it, the furthest slices are past it and draw nothing.
		Test.Assert(info[0].CascadesWithReceivers >= 1);
		Test.Assert(info[0].CascadesWithReceivers < (uint32)ShadowCascades.Count);

		// Turned to the sky from just above them, the view keeps none of the casters below it.
		camera.View = Float4x4.LookAtRH(.(0, 3, 0), .(0, 4, 0), .(0, 0, -1));
		camera.Position = .(0, 3, 0);
		frame.Begin(fixture.Encoder, 1);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();
		info = frame.ViewShadowInfo;
		Test.Assert(info.Length == 1);
		Test.Assert(info[0].DirectionalCasters == 0, "a view turned to the sky keeps none");
	}
}
