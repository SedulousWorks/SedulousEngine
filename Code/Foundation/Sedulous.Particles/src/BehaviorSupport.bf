namespace Sedulous.Particles;

/// Where a behaviour CAN run, which is what an automatic choice is resolved against.
enum BehaviorSupport : uint8
{
	case CPUOnly;
	case GPUOnly;
	case Both;
}
