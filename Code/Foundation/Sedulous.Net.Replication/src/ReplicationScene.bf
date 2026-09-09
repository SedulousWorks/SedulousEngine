using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Net.Replication;

/// Wiring the replication components into a scene, and the transform bridge between them and
/// the entity system.
static class ReplicationScene
{
	/// THE net manager set for a scene, injected by the network subsystem at runtime and by
	/// headless scene consumers alike.
	public static void AddNetworkSceneManagers(Scene scene)
	{
		scene.AddSystem<NetworkComponentManager>();
		scene.AddSystem<NetworkedTransformComponentManager>();
	}

	/// Server: copy each entity's live LOCAL transform INTO its NetworkedTransform, so the
	/// capture that follows sends the authoritative pose. Call before CaptureDelta or
	/// CaptureSnapshot.
	public static void CaptureEntityTransforms(Scene scene)
	{
		let manager = scene.GetSystem<NetworkedTransformComponentManager>();
		if (manager == null)
			return;

		manager.ForEach(scope (component, entity) =>
			{
				// An effectively inactive entity's replicated state FREEZES. It stays in
				// snapshots, because existence and identity are not simulation, and the flag
				// itself is not replicated.
				if (!scene.IsEffectivelyActive(entity))
					return;

				let transform = scene.GetLocalTransform(entity);
				component.Position = transform.Position;
				component.Rotation = transform.Rotation;
				component.Scale = transform.Scale;
			});
	}

	/// Client: write each NetworkedTransform, already interpolated by SampleInterpolation,
	/// BACK onto its entity's LOCAL transform, so the visual follows the replicated pose.
	public static void ApplyEntityTransforms(Scene scene)
	{
		let manager = scene.GetSystem<NetworkedTransformComponentManager>();
		if (manager == null)
			return;

		manager.ForEach(scope (component, entity) =>
			{
				// Frozen locally too: the flag is scene data on both sides.
				if (!scene.IsEffectivelyActive(entity))
					return;

				scene.SetLocalTransform(entity,
					Transform(component.Position, component.Rotation, component.Scale));
			});
	}
}
