using System.Collections;

namespace Sedulous.Particles;

/// Where the per frame work runs. The CPU one walks the behaviours in order; a GPU one would
/// dispatch the same modules behind the same interface, which is what BehaviorSupport exists
/// to decide.
abstract class ParticleSimulator
{
	public abstract void Simulate(ParticleStreamContainer streams,
		List<ParticleBehavior> behaviors, ref ParticleUpdateContext context);

	public abstract int32 CompactDead(ParticleStreamContainer streams);
}
