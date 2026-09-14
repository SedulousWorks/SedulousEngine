namespace Samples.TerrainPlayground;

/// The shapes the playground can generate.
///
/// Four DIFFERENT shapes rather than one with knobs, because what they exercise differs: rolling
/// hills stress the level of detail transitions, a dome shows the silhouette, a ripple shows the
/// height texture's resolution, and a plateau shows a hard edge.
enum TerrainType : int32
{
	case Hills;
	case Dome;
	case Ripple;
	case Plateau;
}
