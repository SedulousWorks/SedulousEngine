namespace Sedulous.Shaders;

/// Which pipeline stage a shader is compiled for.
///
/// DELIBERATELY not Sedulous.RHI's ShaderStage, which is a bit field naming a SET of stages
/// for a binding's visibility. This one names exactly one stage, because a compile targets
/// one profile, and a set has no profile. The two are converted at the seam rather than
/// merged, which is also what keeps this module free of the RHI.
enum ShaderStage : uint32
{
	Vertex,
	Fragment,
	Compute,
	Mesh,
	Task,
	RayGen,
	ClosestHit,
	AnyHit,
	Miss,
	Intersection,
	Callable
}
