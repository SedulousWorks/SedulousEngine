namespace Sedulous.Particles;

/// The space a system simulates in.
enum ParticleSpace : uint8
{
	/// Particles are independent of the emitter once spawned, so moving it leaves a trail
	/// behind: smoke, sparks, anything that stays where it was made.
	case World;
	/// Particles follow the emitter, so the whole effect moves with it: a torch flame.
	case Local;
}
