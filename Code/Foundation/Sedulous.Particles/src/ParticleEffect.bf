using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Particles;

/// The asset: a set of systems and the links between them.
///
/// An effect holds the DEFINITION and, today, the running state too, since a system carries
/// its own streams. An instance drives one effect.
/// On the script surface as an opaque handle: a script holds one and hands it back.
[Scriptable]
class ParticleEffect
{
	public String Name = new .() ~ delete _;

	private List<ParticleSystem> mSystems = new .() ~ DeleteContainerAndItems!(_);
	private List<SubEmitterLink> mLinks = new .() ~ delete _;

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

	public void AddSubEmitterLink(SubEmitterLink link) => mLinks.Add(link);

	public void RemoveSystem(int32 index)
	{
		if ((index >= 0) && (index < SystemCount))
		{
			let system = mSystems[index];
			mSystems.RemoveAt(index);
			delete system;
		}
	}

	/// Drops everything, which is what a reload rebuilds onto.
	public void Clear()
	{
		ClearAndDeleteItems!(mSystems);
		mLinks.Clear();
	}

	public int32 SystemCount => (int32)mSystems.Count;

	public ParticleSystem GetSystem(int32 index) =>
		((index >= 0) && (index < SystemCount)) ? mSystems[index] : null;

	public Span<SubEmitterLink> SubEmitterLinks => mLinks;
}
