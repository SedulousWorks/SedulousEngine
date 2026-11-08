using Sedulous.Audio;

namespace Sedulous.Engine.Audio;

/// Where a removed audio source's voice goes (its entity destroyed, or the component taken off):
/// the scene's audio system, which stops it. Set while the scene plays; unset, nothing plays.
interface IAudioReleaser
{
	void ReleaseVoice(VoiceHandle voice);
}
