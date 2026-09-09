namespace Sedulous.Render;

/// How a reflection probe's captured cubemap refreshes.
enum ProbeUpdateMode : uint32
{
	/// Captured once and fully prefiltered, then cached until the probe moves or is
	/// invalidated.
	case Static = 0;
	/// Recaptured on a round robin, with a cheaper prefilter.
	case Realtime = 1;
	/// Only when asked.
	case Manual = 2;
}
