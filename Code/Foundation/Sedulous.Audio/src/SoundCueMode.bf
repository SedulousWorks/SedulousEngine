namespace Sedulous.Audio;

/// How a cue picks among its variants.
enum SoundCueMode : uint8
{
	/// Weighted random, but NEVER the same variant twice running: a footstep that repeats
	/// itself is the one thing an ear picks out immediately.
	case RandomNoRepeat = 0;
	/// Weighted random, repeats allowed.
	case Random = 1;
	/// Round robin, in slot order.
	case Sequential = 2;
}
