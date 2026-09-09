namespace Sedulous.Particles;

/// How an emitter releases particles.
enum EmissionMode : uint8
{
	case Continuous;
	case Burst;
	case ContinuousAndBurst;
}
