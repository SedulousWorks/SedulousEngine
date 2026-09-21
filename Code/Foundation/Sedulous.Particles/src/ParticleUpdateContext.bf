using Sedulous.Core;

namespace Sedulous.Particles;

/// What every module is handed: an initializer once per spawned particle, a behaviour once
/// per frame.
///
/// The generator is BORROWED from the system, so every module in one update draws from one
/// sequence: a system with a seed replays exactly.
///
/// The emitter's own position and velocity ride here rather than being pushed onto the
/// modules before a burst. A module that reads the emitter then holds no state of its own,
/// so nothing transient ends up in its stored record.
struct ParticleUpdateContext
{
	public float TotalTime = 0.0f;
	public float DeltaTime = 0.0f;
	public Float3 EmitterPosition = .(0, 0, 0);
	public Float3 EmitterVelocity = .(0, 0, 0);
	public Random* Rng = null;

	public this() {}
}
