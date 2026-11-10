using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Particles;

/// The asset: a set of systems, each with its sub-emitter links into the others.
///
/// An effect holds the DEFINITION and, today, the running state too, since a system carries
/// its own streams. An instance drives one effect.
[Reflect(.Type | .NonStaticFields)]
class ParticleEffect
{
	public String Name = new .() ~ delete _;

	private List<ParticleSystem> mSystems = new .() ~ DeleteContainerAndItems!(_);

	public this(StringView name = "Effect")
	{
		Name.Set(name);
	}

	/// Creates and OWNS a system. The caller gets a borrowed reference to configure.
	public ParticleSystem AddSystem(int32 maxParticles, uint64 seed = 0x9E3779B97F4A7C15UL)
	{
		let system = new ParticleSystem(maxParticles, seed);
		mSystems.Add(system);
		return system;
	}

	/// The systems' sub-emitters follow: one into the removed system does nothing (-1), one into a
	/// system after it names that system's new place.
	public void RemoveSystem(int32 index)
	{
		if ((index >= 0) && (index < SystemCount))
		{
			let system = mSystems[index];
			mSystems.RemoveAt(index);
			delete system;
			for (let other in mSystems)
			{
				for (var link in ref other.SubEmitters)
				{
					if (link.ChildSystemIndex == index)
						link.ChildSystemIndex = -1;
					else if (link.ChildSystemIndex > index)
						link.ChildSystemIndex--;
				}
			}
		}
	}

	/// Drops everything, which is what a reload rebuilds onto.
	public void Clear()
	{
		ClearAndDeleteItems!(mSystems);
	}

	public int32 SystemCount => (int32)mSystems.Count;

	public ParticleSystem GetSystem(int32 index) =>
		((index >= 0) && (index < SystemCount)) ? mSystems[index] : null;

}
