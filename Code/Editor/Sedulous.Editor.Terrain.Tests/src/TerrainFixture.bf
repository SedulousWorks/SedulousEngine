using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Heightfield;
using Sedulous.Terrain.Resource;
using Sedulous.Engine.Terrain;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain.Tests;

/// A started scene with one terrain entity: a flat 65 grid over a 64 by 64 world with a Y
/// range of zero to ten, and a 32 by 32 pure base splat raster. The resources carry the
/// source guids the brushes persist back to.
class TerrainFixture
{
	public static readonly Guid HeightfieldId = .(7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 99);
	public static readonly Guid WeightsId = .(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 55);

	public Scene Scene = new .() ~ delete _;
	public Heightfield Grid = new .(65, .(64.0f, 64.0f), 0.0f, 10.0f) ~ delete _;
	public SplatWeights Weights = new .(32, 32) ~ delete _;
	public TerrainResource Resource = new .() ~ delete _;

	public this(bool withWeights = true)
	{
		TerrainScene.AddTerrainSceneManagers(Scene);
		Resource.Heightfield.SetDirect(Grid);
		Resource.Heightfield.SetId(HeightfieldId);
		if (withWeights)
		{
			Resource.Weights.SetDirect(Weights);
			Resource.Weights.SetId(WeightsId);
		}
		let entity = Scene.CreateEntity("terrain");
		let component = Scene.GetSystem<TerrainComponentManager>().Add(entity);
		component.Terrain.SetDirect(Resource);
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

	public static ViewportToolInput CenterRay(float deltaSeconds = 1.0f / 60.0f) => RayAt(0.0f, 0.0f, deltaSeconds);

	public static ViewportToolInput Press(float x = 0.0f, float z = 0.0f, float deltaSeconds = 1.0f / 60.0f)
	{
		var input = RayAt(x, z, deltaSeconds);
		input.LeftPressed = true;
		input.LeftDown = true;
		return input;
	}

	public static ViewportToolInput Drag(float x = 0.0f, float z = 0.0f, float deltaSeconds = 1.0f / 60.0f)
	{
		var input = RayAt(x, z, deltaSeconds);
		input.LeftDown = true;
		return input;
	}

	public static ViewportToolInput Release(float x = 0.0f, float z = 0.0f, float deltaSeconds = 1.0f / 60.0f)
	{
		var input = RayAt(x, z, deltaSeconds);
		input.LeftReleased = true;
		return input;
	}
}
