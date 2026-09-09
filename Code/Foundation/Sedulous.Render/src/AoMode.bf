namespace Sedulous.Render;

/// Which ambient occlusion estimator a view uses.
enum AoMode : uint32
{
	case Off = 0;
	/// The ground truth estimator: a horizon search that integrates visibility, which is
	/// closer to the real thing and costs more.
	case GTAO = 1;
	/// The screen space one: hemisphere samples compared against the depth buffer.
	case SSAO = 2;
}
