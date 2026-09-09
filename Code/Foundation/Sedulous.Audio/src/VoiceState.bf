namespace Sedulous.Audio;

/// Where one pool slot stands.
enum VoiceState : uint8
{
	case Free = 0;
	case Playing = 1;
	case Paused = 2;
	/// A fade to stop is in flight; the slot is reaped when the fade lands.
	case Stopping = 3;
}
