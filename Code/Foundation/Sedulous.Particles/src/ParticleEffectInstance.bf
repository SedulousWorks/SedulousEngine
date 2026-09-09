using Sedulous.Core;

namespace Sedulous.Particles;

/// One playing effect: it drives every system and routes the sub emitter events between
/// them.
///
/// The effect is BORROWED, not owned.
class ParticleEffectInstance
{
	public Float3 Position = .(0, 0, 0);
	public bool IsActive = true;

	private ParticleEffect mEffect;

	public this(ParticleEffect effect)
	{
		mEffect = effect;
	}

	public ParticleEffect Effect => mEffect;

	public void Update(float deltaTime, Float3 cameraPosition = .(0, 0, 0))
	{
		if (!IsActive || (mEffect == null))
			return;

		let count = mEffect.SystemCount;
		for (int32 i = 0; i < count; i++)
		{
			let system = mEffect.GetSystem(i);
			system.Position = Position;
			system.Update(deltaTime, cameraPosition);
		}

		// After every system has stepped, so a link sees this frame's events from all of
		// them rather than a mixture of this frame's and last.
		RouteSubEmitterEvents();
	}

	/// True once every system has stopped emitting AND drained, which is when a one shot
	/// effect can be thrown away.
	public bool IsFinished
	{
		get
		{
			if (mEffect == null)
				return true;

			let count = mEffect.SystemCount;
			for (int32 i = 0; i < count; i++)
			{
				let system = mEffect.GetSystem(i);
				if ((system.AliveCount > 0) || system.Emitter.IsEmitting)
					return false;
			}
			return true;
		}
	}

	/// Stops emission. Live particles still finish their lives, which is what makes a smoke
	/// plume trail off rather than vanish.
	public void Stop()
	{
		if (mEffect == null)
			return;
		for (int32 i = 0; i < mEffect.SystemCount; i++)
			mEffect.GetSystem(i).Emitter.IsEmitting = false;
	}

	/// Resumes emission and un-pauses the instance. A fresh instance already emits; this is
	/// the counterpart to Stop.
	public void Play()
	{
		IsActive = true;
		if (mEffect == null)
			return;
		for (int32 i = 0; i < mEffect.SystemCount; i++)
			mEffect.GetSystem(i).Emitter.IsEmitting = true;
	}

	public void Reset()
	{
		if (mEffect == null)
			return;
		for (int32 i = 0; i < mEffect.SystemCount; i++)
			mEffect.GetSystem(i).Reset();
	}

	private void RouteSubEmitterEvents()
	{
		let links = mEffect.SubEmitterLinks;
		let systemCount = mEffect.SystemCount;

		for (let link in links)
		{
			if ((link.ChildSystemIndex < 0) || (link.ChildSystemIndex >= systemCount))
				continue;

			let child = mEffect.GetSystem(link.ChildSystemIndex);
			for (int32 s = 0; s < systemCount; s++)
			{
				// A system spawning into itself would feed its own events back and run away.
				if (s == link.ChildSystemIndex)
					continue;

				let parent = mEffect.GetSystem(s);
				let events = (link.Trigger == .OnDeath) ? parent.DeathEvents
					: parent.BirthEvents;

				for (let event in events)
				{
					if (link.Probability < 1.0f)
					{
						// A spatial hash rather than the generator: the gate has to be
						// DETERMINISTIC per event, and drawing here would couple the child's
						// spawns to however many events the parent happened to produce.
						let hash = (uint32)(event.Position.X * 73856093.0f)
							^ (uint32)(event.Position.Y * 19349663.0f);
						if ((float)(hash % 1000) / 1000.0f > link.Probability)
							continue;
					}

					if (link.InheritPosition)
					{
						let velocity = link.InheritVelocity
							? (event.Velocity * link.VelocityInheritFactor) : Float3.Zero;
						let color = link.InheritColor ? event.Color : Float4(1, 1, 1, 1);
						child.SpawnAt(link.SpawnCount, event.Position, velocity, color);
					}
					else
					{
						child.SpawnImmediate(link.SpawnCount);
					}
				}
			}
		}
	}
}
