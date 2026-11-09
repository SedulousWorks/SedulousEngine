using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
using Sedulous.Net.Replication;
using Sedulous.Engine.Gameplay;

namespace Masquerade;

/// On the dais: plays the evening's cues in turn, each for its while, and tells the ball
/// (CueChanged: stroll, gather, dance). Guests follow the cue (Guest); a player who does not
/// stands out (Ball). The cue is replicated, so a joining player hears the same music: each peer
/// plays the cue's piece (Tools/sounds.py: a waltz, an air, a dance), crossfading from the last.
[Behaviour("masquerade.orchestra")]
[DisplayName("Orchestra"), Category("Masquerade")]
[Description("Plays the evening's cues in turn (stroll, gather, dance) and their music, the cue replicated to every peer.")]
class Orchestra : Behaviour
{
	private const float cMusicVolume = 0.55f;
	private const float cCrossfade = 2.0f;

	[Description("Seconds of strolling")]
	public float StrollSeconds = 40.0f;
	[Description("Seconds of gathering to talk")]
	public float GatherSeconds = 20.0f;
	[Description("Seconds of dancing")]
	public float DanceSeconds = 25.0f;
	[Description("The cue playing now (0 stroll, 1 gather, 2 dance)"), Replicated]
	public int32 Cue = 0;

	private float mLeft = 0.0f;
	/// The cue last told, -1 before the first.
	private int32 mTold = -1;
	private int32 mStep = 0;

	protected override void OnStart()
	{
		mLeft = StrollSeconds;
	}

	protected override void OnUpdate(float dt)
	{
		if (!Pieces.IsClient(Run))
		{
			mLeft -= dt;
			if (mLeft <= 0.0f)
			{
				// The evening's order: stroll, gather, stroll, dance, round again.
				mStep = (mStep + 1) % 4;
				Cue = (mStep == 1) ? Cues.Gather : ((mStep == 3) ? Cues.Dance : Cues.Stroll);
				mLeft = (Cue == Cues.Gather) ? GatherSeconds : ((Cue == Cues.Dance) ? DanceSeconds : StrollSeconds);
			}
		}
		// Every peer tells its own ball when the (replicated) cue changes.
		if (Cue != mTold)
		{
			mTold = Cue;
			Post(CueChanged(Cue));
			if (let audio = RunServices.Get<AudioFacade>(Run))
				audio.PlayMusic((Cue == Cues.Gather) ? Assets.Air : ((Cue == Cues.Dance) ? Assets.DanceMusic : Assets.Waltz), cCrossfade, cMusicVolume);
		}
	}
}
