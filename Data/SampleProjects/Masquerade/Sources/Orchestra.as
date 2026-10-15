// Orchestra - on the dais: plays the evening's cues in turn, each for its while, and tells the
// ball (the "Cue" event: 0 stroll, 1 gather, 2 dance). Guests follow the cue (Guest.as); a
// player who does not stands out. The cue is replicated, so a joining player hears the same music:
// each peer plays the cue's piece (sounds.py: a waltz, an air, a dance), crossfading from the last.
//
// Its globals carry its name: every behaviour compiles into one module here, and Guest.as and
// Ball.as name the cues too.
const int kOrchestraStroll = 0;
const int kOrchestraGather = 1;
const int kOrchestraDance = 2;
const float kOrchestraMusicVolume = 0.55f;
const float kOrchestraCrossfade = 2.0f;
Guid kWaltz = Guid::FromString("2c804143-d88d-d746-9673-b9f637c7eb6a");
Guid kAir = Guid::FromString("6440802e-0569-0848-bdc0-b92d789247af");
Guid kDanceMusic = Guid::FromString("15d760b2-38be-4d42-bd04-23b49ae59ba7");

class Orchestra
{
	Entity self;
	Scene@ scene;

	[40.0, "Seconds of strolling"] float strollSeconds;
	[20.0, "Seconds of gathering to talk"] float gatherSeconds;
	[25.0, "Seconds of dancing"] float danceSeconds;
	[0, "The cue playing now (0 stroll, 1 gather, 2 dance)", replicated] int cue;

	private float m_left = 0.0f;
	private int m_told = -1;
	private int m_step = 0;

	void onStart()
	{
		m_left = strollSeconds;
	}

	void onUpdate(float dt)
	{
		if (!Net.IsClient)
		{
			m_left -= dt;
			if (m_left <= 0.0f)
			{
				// The evening's order: stroll, gather, stroll, dance, round again.
				m_step = (m_step + 1) % 4;
				cue = (m_step == 1) ? kOrchestraGather : ((m_step == 3) ? kOrchestraDance : kOrchestraStroll);
				m_left = (cue == kOrchestraGather) ? gatherSeconds : ((cue == kOrchestraDance) ? danceSeconds : strollSeconds);
			}
		}
		if (cue != m_told) // every peer tells its own ball when the (replicated) cue changes
		{
			m_told = cue;
			scene.Scripts.Emit("Cue", cue);
			Audio.PlayMusic(cue == kOrchestraGather ? kAir : (cue == kOrchestraDance ? kDanceMusic : kWaltz),
			                kOrchestraCrossfade, kOrchestraMusicVolume);
		}
	}
}
