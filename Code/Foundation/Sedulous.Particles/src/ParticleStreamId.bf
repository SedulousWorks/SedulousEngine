namespace Sedulous.Particles;

/// The attribute channels a particle can carry.
///
/// Position, Age and Lifetime are always allocated; the rest appear only when a module asks
/// for them, so a system that never rotates pays nothing for a rotation stream. Custom up to
/// MaxStreams is reserved for callers.
enum ParticleStreamId : uint8
{
	case Position = 0;
	case Velocity = 1;
	case StartVelocity = 2;
	case Color = 3;
	case Size = 4;
	case Age = 5;
	case Lifetime = 6;
	case Rotation = 7;
	case RotationSpeed = 8;
	case Axis = 9;
	case Custom = 32;
	case MaxStreams = 64;
}
