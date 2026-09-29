namespace Sedulous.Editor.Core;

/// A page that plays something back: a clip, a cue, an effect, a graph preview. The
/// playback actions (playback.play, playback.stop, playback.restart) drive any page that
/// implements this, so every page's transport is the same three toolbar buttons with the
/// same meaning:
/// - Play is a toggle, checked while playing: it starts, pauses and resumes;
/// - Stop stops and rewinds to the start;
/// - Restart plays from the start.
interface IPlaybackPage
{
	/// Whether there is anything to play: a clip loaded, an effect built.
	bool CanPlay { get; }
	bool IsPlaying { get; }
	/// Starts from the start when stopped, or resumes where it paused.
	void Play();
	void Pause();
	/// Stops and rewinds to the start.
	void Stop();
	/// Plays from the start.
	void Restart();
}
