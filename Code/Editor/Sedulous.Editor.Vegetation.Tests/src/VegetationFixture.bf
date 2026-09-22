using System;
using Sedulous.Core;
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
		let layer = new VegetationLayer();
		layer.Name.Set("Grass");
		layer.Placement = .Mask;
		layer.MaskPlane = 0;
		vegetation.Layers.Add(layer);

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
