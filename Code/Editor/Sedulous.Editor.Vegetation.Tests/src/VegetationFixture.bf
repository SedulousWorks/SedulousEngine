using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Heightfield;
using Sedulous.Scene;
using Sedulous.Terrain.Resource;
using Sedulous.Vegetation.Resource;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.Vegetation;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation.Tests;

/// A headless scene with one terrain carrying a vegetation component and a mask.
class VegetationFixture
{
	public static readonly Guid HeightfieldId = .(7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 99);
	public static readonly Guid MaskId = .(6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66);

	public Scene Scene = new .() ~ delete _;
	public Heightfield Grid = new .(65, .(64.0f, 64.0f), 0.0f, 10.0f) ~ delete _;
	public VegetationMask Mask = new .(32, 32, 2) ~ delete _;
	public TerrainResource Resource = new .() ~ delete _;
	public EntityHandle Terrain = .();

	public this(bool withMask = true)
	{
		TerrainScene.AddTerrainSceneManagers(Scene);
		VegetationScene.AddVegetationSceneManagers(Scene);
		Resource.Heightfield.SetDirect(Grid);
		Resource.Heightfield.SetId(HeightfieldId);

		Terrain = Scene.CreateEntity("terrain");
		Scene.GetSystem<TerrainComponentManager>().Add(Terrain).Terrain.SetDirect(Resource);

		let vegetation = Scene.GetSystem<TerrainVegetationComponentManager>().Add(Terrain);
		if (withMask)
		{
			vegetation.Mask.SetDirect(Mask);
			vegetation.Mask.SetId(MaskId);
		}
		let layer = new ProceduralVegetationLayer();
		layer.Name.Set("Grass");
		layer.Placement = .Mask;
		layer.MaskPlane = 0;
		vegetation.ProceduralLayers.Add(layer);

		Scene.Start();
	}

	/// A ray straight down onto the terrain at world (x, z).
	public static ViewportToolInput RayAt(float x, float z, float deltaSeconds = 1.0f / 60.0f)
	{
		var input = ViewportToolInput();
		input.Ray.Origin = .(x, 100.0f, (z != 0.0f) ? z : 0.001f);
		input.Ray.Direction = .(0.0f, -1.0f, 0.0f);
		input.PointerValid = true;
		input.PointerOver = true;
		input.DeltaSeconds = deltaSeconds;
		return input;
	}

	public static ViewportToolInput Press(float x = 0.0f, float z = 0.0f,
		float deltaSeconds = 1.0f / 60.0f)
	{
		var input = RayAt(x, z, deltaSeconds);
		input.LeftPressed = true;
		input.LeftDown = true;
		return input;
	}

	public static ViewportToolInput Drag(float x = 0.0f, float z = 0.0f,
		float deltaSeconds = 1.0f / 60.0f)
	{
		var input = RayAt(x, z, deltaSeconds);
		input.LeftDown = true;
		return input;
	}

	public static ViewportToolInput Release(float x = 0.0f, float z = 0.0f,
		float deltaSeconds = 1.0f / 60.0f)
	{
		var input = RayAt(x, z, deltaSeconds);
		input.LeftReleased = true;
		return input;
	}
}

/// A headless scene with a 128 metre terrain, two by two chunks, carrying a vegetation
/// component with a Uniform grass layer and, optionally, a rock PROP layer.
///
/// `rise` above nought makes the terrain a ramp climbing with x, which is how the slope rule
/// is put under test.
class ScatterFixture
{
	private const int32 cGrid = 129;

	public Scene Scene = new .() ~ delete _;
	public Heightfield Grid = new .(cGrid, .(128.0f, 128.0f), 0.0f, 64.0f) ~ delete _;
	public TerrainResource Resource = new .() ~ delete _;
	public StaticMesh Mesh ~ delete _;
	public EntityHandle Terrain = .();
	public TerrainVegetationComponentManager Vegetation = null;

	public this(bool withPropLayer = true, float rise = 0.0f)
	{
		TerrainScene.AddTerrainSceneManagers(Scene);
		VegetationScene.AddVegetationSceneManagers(Scene);
		Vegetation = Scene.GetSystem<TerrainVegetationComponentManager>();
		Vegetation.SetBuildBudget(100);

		for (int32 z = 0; z < cGrid; z++)
		{
			for (int32 x = 0; x < cGrid; x++)
			{
				let t = (float)x / (float)(cGrid - 1);
				Grid.SetSample(x, z, Grid.WorldYToSample(2.0f + rise * t));
			}
		}
		Resource.Heightfield.SetDirect(Grid);

		Terrain = Scene.CreateEntity("terrain");
		Scene.GetSystem<TerrainComponentManager>().Add(Terrain).Terrain.SetDirect(Resource);

		Mesh = Primitives.Cube(1.0f);
		let component = Vegetation.Add(Terrain);
		let grass = new ProceduralVegetationLayer();
		grass.Name.Set("Grass");
		grass.Mesh.SetDirect(Mesh);
		grass.Placement = .Uniform;
		component.ProceduralLayers.Add(grass);
		if (withPropLayer)
		{
			let rocks = new PropVegetationLayer();
			rocks.Name.Set("Rocks");
			rocks.Mesh.SetDirect(Mesh);
			rocks.ScaleRange = .(1.0f, 1.0f);
			rocks.MaxSlopeDegrees = 35.0f;
			component.PropLayers.Add(rocks);
		}
		Scene.Start();
	}

	/// The prop layer's placed instances.
	public List<Float4x4> Rocks => Vegetation.Get(Terrain).PropLayers[0].Instances;

	/// Drives a press, some drags and a release along a terrain local line.
	public void Stroke(VegetationScatterTool tool, float x0, float z0, float x1, float z1,
		int32 steps = 8)
	{
		tool.Update(VegetationFixture.Press(x0, z0));
		for (int32 i = 1; i <= steps; i++)
		{
			let t = (float)i / (float)steps;
			tool.Update(VegetationFixture.Drag(x0 + (x1 - x0) * t, z0 + (z1 - z0) * t));
		}
		tool.Update(VegetationFixture.Release(x1, z1));
	}

	public static bool SameInstances(List<Float4x4> a, List<Float4x4> b)
	{
		if (a.Count != b.Count)
			return false;
		if (a.IsEmpty)
			return true;
		return Internal.MemCmp(a.Ptr, b.Ptr, a.Count * strideof(Float4x4)) == 0;
	}
}

/// Records what a brush registers, keeping the last closure so a test can run it.
class FakeAssetEditSink : IAssetEditSink
{
	public int32 Count = 0;
	public Guid LastId = .();
	public AssetEditPersist LastPersist = null ~ delete _;

	public bool HasPersist => LastPersist != null;

	public void RegisterAssetEdit(Guid assetId, AssetEditPersist persist)
	{
		Count++;
		LastId = assetId;
		delete LastPersist;
		LastPersist = persist;
	}
}
