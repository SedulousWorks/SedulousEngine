namespace Sedulous.Particles;

using System;

/// CPU simulation backend - iterates behaviors on SoA arrays in system memory.
/// This is the default and most flexible backend.
public class CPUSimulator : ParticleSimulator
{
	public override void Simulate(
		ParticleStreamContainer streams,
		Span<ParticleBehavior> behaviors,
		ref ParticleUpdateContext ctx)
	{
		for (let behavior in behaviors)
			behavior.Update(streams, ref ctx);
	}

	public override int32 CompactDead(ParticleStreamContainer streams)
	{
		return streams.CompactDead();
	}
}
