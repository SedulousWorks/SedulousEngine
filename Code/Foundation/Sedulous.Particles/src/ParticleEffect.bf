namespace Sedulous.Particles;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// A particle effect - top-level container grouping multiple particle systems
/// into a single logical effect (e.g., "campfire" = flame + smoke + sparks).
///
///   ParticleEffect
///     └── ParticleSystem[]
///           ├── Emitter        - spawn rules
///           ├── Behaviors[]    - per-frame update rules
///           ├── Initializers[] - per-spawn setup
///           ├── Streams        - SoA data channels
///           └── Simulator      - CPU or GPU backend
///
/// This is the "asset definition" - runtime instances are ParticleEffectInstance.
public class ParticleEffect
{
	/// Display name for debugging.
	public String Name ~ delete _;

	/// Particle systems that compose this effect.
	private List<ParticleSystem> mSystems = new .() ~ DeleteContainerAndItems!(_);

	/// Sub-emitter links (cross-system event routing).
	private List<SubEmitterLink> mSubEmitterLinks = new .() ~ delete _;

	public this(StringView name = "Effect")
	{
		Name = new .(name);
	}

	/// Adds a particle system. The effect takes ownership.
	/// Returns the system's index within the effect.
	public int32 AddSystem(ParticleSystem system)
	{
		let index = (int32)mSystems.Count;
		mSystems.Add(system);
		return index;
	}

	/// Adds a sub-emitter link between systems.
	public void AddSubEmitterLink(SubEmitterLink link)
	{
		mSubEmitterLinks.Add(link);
	}

	/// Gets all systems.
	public Span<ParticleSystem> Systems => mSystems;

	/// Gets all sub-emitter links.
	public Span<SubEmitterLink> SubEmitterLinks => mSubEmitterLinks;

	/// Gets the number of systems.
	public int32 SystemCount => (int32)mSystems.Count;

	/// Gets a system by index.
	public ParticleSystem GetSystem(int32 index) => mSystems[index];
}
