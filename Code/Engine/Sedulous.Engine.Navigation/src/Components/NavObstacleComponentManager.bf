namespace Sedulous.Engine.Navigation;

using System;
using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;

/// Manages navigation obstacle components: creates/removes obstacles in the
/// NavWorld's TileCache, updates positions from entity transforms.
class NavObstacleComponentManager : ComponentManager<NavObstacleComponent>
{
	/// The navigation world for this scene (set by NavigationSubsystem).
	public NavWorld NavWorld { get; set; }

	public override StringView SerializationTypeId => "Sedulous.NavObstacleComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.Update, new => UpdateObstacles);
	}

	private void UpdateObstacles(float deltaTime)
	{
		if (NavWorld == null) return;
		let scene = Scene;
		if (scene == null) return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;

			// Create obstacle if needed
			if (comp.NeedsCreation)
			{
				let worldMatrix = scene.GetWorldMatrix(comp.Owner);
				let position = worldMatrix.Translation;

				let obstacleId = NavWorld.AddObstacle(
					.(position.X, position.Y, position.Z),
					comp.Radius, comp.Height);

				if (obstacleId >= 0)
				{
					comp.ObstacleId = obstacleId;
					comp.NeedsCreation = false;
				}
			}
		}
	}

	protected override void OnComponentDestroyed(NavObstacleComponent comp)
	{
		if (comp.ObstacleId >= 0 && NavWorld != null)
		{
			NavWorld.RemoveObstacle(comp.ObstacleId);
			comp.ObstacleId = -1;
		}
	}
}
