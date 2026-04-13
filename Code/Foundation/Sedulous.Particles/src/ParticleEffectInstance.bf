using Sedulous.Core.Mathematics;
namespace Sedulous.Particles;

/// A runtime instance of a ParticleEffect.
/// Multiple instances can reference the same effect definition.
public class ParticleEffectInstance
{
	/// The effect definition.
	public ParticleEffect Effect { get; private set; }

	/// World-space position.
	public Vector3 Position;

	/// Whether the effect is currently active.
	public bool IsActive = true;

	/// Whether all systems have finished (no alive particles and not emitting).
	public bool IsFinished
	{
		get
		{
			for (let system in Effect.Systems)
			{
				if (system.AliveCount > 0 || system.Emitter.IsEmitting)
					return false;
			}
			return true;
		}
	}

	public this(ParticleEffect effect)
	{
		Effect = effect;
	}

	/// Updates all systems in this effect instance.
	/// cameraPos is used for LOD distance culling.
	public void Update(float deltaTime, Vector3 cameraPos = .Zero)
	{
		if (!IsActive)
			return;

		// Update all systems
		for (let system in Effect.Systems)
		{
			system.Position = Position;
			system.Update(deltaTime, cameraPos);
		}

		// Route sub-emitter events between systems
		RouteSubEmitterEvents();
	}

	/// Routes birth/death events from parent systems to child systems
	/// according to the effect's SubEmitterLinks.
	private void RouteSubEmitterEvents()
	{
		let links = Effect.SubEmitterLinks;
		if (links.Length == 0) return;

		for (let link in links)
		{
			if (link.ChildSystemIndex < 0 || link.ChildSystemIndex >= Effect.SystemCount)
				continue;

			let childSystem = Effect.GetSystem(link.ChildSystemIndex);

			// Check all parent systems for matching events
			for (int32 parentIdx = 0; parentIdx < Effect.SystemCount; parentIdx++)
			{
				if (parentIdx == link.ChildSystemIndex)
					continue;

				let parentSystem = Effect.GetSystem(parentIdx);
				let events = (link.Trigger == .OnDeath) ? parentSystem.DeathEvents : parentSystem.BirthEvents;

				for (let evt in events)
				{
					// Probability check
					if (link.Probability < 1.0f)
					{
						let hash = (uint32)(evt.Position.X * 73856093f) ^ (uint32)(evt.Position.Y * 19349663f);
						if ((float)(hash % 1000) / 1000.0f > link.Probability)
							continue;
					}

					if (link.InheritPosition)
					{
						// Spawn at the parent particle's death/birth position
						childSystem.SpawnAt(link.SpawnCount, evt.Position,
							link.InheritVelocity ? evt.Velocity * link.VelocityInheritFactor : .Zero,
							link.InheritColor ? evt.Color : .(1, 1, 1, 1));
					}
					else
					{
						childSystem.SpawnImmediate(link.SpawnCount);
					}
				}
			}
		}
	}

	/// Stops all systems from spawning new particles.
	public void Stop()
	{
		for (let system in Effect.Systems)
			system.Emitter.IsEmitting = false;
	}

	/// Resets all systems.
	public void Reset()
	{
		for (let system in Effect.Systems)
			system.Reset();
	}
}