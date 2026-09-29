using System;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The playback actions over any IPlaybackPage: playback.play (a toggle, checked while
/// playing: start, pause, resume), playback.stop (stop and rewind) and playback.restart. A
/// page shows them through PageToolbar.AddPlayback.
static class PlaybackActions
{
	public static void Register(EditorActionRegistry actions)
	{
		{
			let d = new EditorActionDeclaration("playback.play", "Play", "Play, pause or resume the page's preview");
			d.Kind = .Toggle;
			d.Enabled = new (page) => (page is IPlaybackPage) && ((IPlaybackPage)page).CanPlay;
			d.Checked = new (page) => (page is IPlaybackPage) && ((IPlaybackPage)page).IsPlaying;
			d.Execute = new (page) =>
				{
					if (let playback = page as IPlaybackPage)
					{
						if (playback.IsPlaying)
							playback.Pause();
						else
							playback.Play();
					}
				};
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("playback.stop", "Stop", "Stop the page's preview and rewind it");
			d.Enabled = new (page) => (page is IPlaybackPage) && ((IPlaybackPage)page).CanPlay;
			d.Execute = new (page) => { if (let playback = page as IPlaybackPage) playback.Stop(); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("playback.restart", "Restart", "Play the page's preview from the start");
			d.Enabled = new (page) => (page is IPlaybackPage) && ((IPlaybackPage)page).CanPlay;
			d.Execute = new (page) => { if (let playback = page as IPlaybackPage) playback.Restart(); };
			actions.Register(d);
		}
	}
}
