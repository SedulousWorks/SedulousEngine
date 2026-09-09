using System.Collections;

namespace Sedulous.Particles;

/// Behaviours in declaration order, on this thread. ORDER MATTERS: drag applied before a
/// force is not the same as after it.
class CPUSimulator : ParticleSimulator
{
	public override void Simulate(ParticleStreamContainer streams,
		List<ParticleBehavior> behaviors, ref ParticleUpdateContext context)
	{
		for (let behavior in behaviors)
			behavior.Update(streams, ref context);
	}

	public override int32 CompactDead(ParticleStreamContainer streams) => streams.CompactDead();
}
