namespace Sedulous.RHI;

/// What a build should optimise for, and what it must leave possible afterwards.
///
/// The two Prefer flags pull against each other; naming both leaves the choice to the
/// driver, which is rarely what a caller wants.
enum AccelStructBuildFlags : uint32
{
	case None = 0;
	/// The structure may be refitted later rather than rebuilt. Costs memory and some
	/// traversal speed.
	case AllowUpdate = 1;
	case AllowCompaction = 2;
	case PreferFastTrace = 4;
	case PreferFastBuild = 8;
}
