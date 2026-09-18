using Sedulous.Core;

namespace Sedulous.Particles;

/// How an emitter releases particles.
[Scriptable(.AllPublic)]
enum EmissionMode : uint8
{
	case Continuous;
	case Burst;
	case ContinuousAndBurst;
}
