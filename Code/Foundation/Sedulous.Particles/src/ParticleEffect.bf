namespace Sedulous.Particles;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

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
	/// User-facing effect name. Free-form label shown as the tree root in
	/// the editor and serialized with the asset; intentionally independent
	/// of the file name.
	[Property]
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

	/// Removes the system at the given index, deleting it. The effect owns
	/// all systems and must free the removed entry.
	public bool RemoveSystem(int32 index)
	{
		if (index < 0 || index >= mSystems.Count) return false;
		delete mSystems[index];
		mSystems.RemoveAt(index);
		return true;
	}

	/// Inserts a system at the given index. The effect takes ownership.
	public bool InsertSystem(int32 index, ParticleSystem system)
	{
		if (system == null) return false;
		if (index < 0 || index > mSystems.Count) return false;
		mSystems.Insert(index, system);
		return true;
	}

	/// Moves a system from one index to another. Used for reordering in the editor.
	public bool MoveSystem(int32 fromIndex, int32 toIndex)
	{
		if (fromIndex < 0 || fromIndex >= mSystems.Count) return false;
		if (toIndex < 0 || toIndex >= mSystems.Count) return false;
		if (fromIndex == toIndex) return true;
		let system = mSystems[fromIndex];
		mSystems.RemoveAt(fromIndex);
		mSystems.Insert(toIndex, system);
		return true;
	}
}
