namespace Sedulous.Audio;

/// What one link of a bus's effect chain is.
enum AudioBusEffectKind : uint8
{
	case None = 0;
	case Lowpass = 1;
	case Highpass = 2;
	case Delay = 3;
	case Reverb = 4;
}
