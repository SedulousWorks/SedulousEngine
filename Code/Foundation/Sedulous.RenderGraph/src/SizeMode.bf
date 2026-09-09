namespace Sedulous.RenderGraph;

/// How a transient resource's dimensions follow the graph's output.
///
/// Relative rather than absolute, so a half resolution bloom chain resizes with the window
/// instead of needing every declaration rewritten.
enum SizeMode : uint8
{
	case FullSize;
	case HalfSize;
	case QuarterSize;
	case Custom;
}
