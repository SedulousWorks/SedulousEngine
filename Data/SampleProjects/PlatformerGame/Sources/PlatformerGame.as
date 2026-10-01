// PlatformerGame - the run's orchestrator (the reserved class Game): the title screen, the
// levels in order with an intro and a clear banner each, the pause menu, the fades between
// them, and the HUD.
//
// The flow is one state machine on the run's REAL clock (Run.RealDeltaTime), because the
// game sits at TimeScale 0 on every screen but play: the title, an intro, a pause, a clear.
//
// A level's coins announce themselves ("CoinRegistered") and report pickups
// ("CoinCollected"), the player reports falls ("PlayerDied"), and the goal flag ends the level
// ("GoalReached"). In a run the scene bus IS the run bus, so all of them reach this class.

Guid kHudDoc = Guid::FromString("b8fe2b54-f4d3-7646-bab4-dd6f4583065b");     // UI/Hud
Guid kTitleDoc = Guid::FromString("7e57a0b4-cb4c-a048-8a90-9bbdaac084bf");   // UI/Title
Guid kIntroDoc = Guid::FromString("7d9ecf53-9d4a-934b-85d8-579d68267f46");   // UI/Intro
Guid kPauseDoc = Guid::FromString("6515a579-9cb8-b348-9434-826c90022af2");   // UI/Pause
Guid kClearDoc = Guid::FromString("7421e5ab-e8ca-5c46-9312-e24ad88a4b30");   // UI/LevelClear
Guid kVictoryDoc = Guid::FromString("91aaa0a4-e496-994d-a0df-4e0c0759503e"); // UI/Victory
Guid kFadeDoc = Guid::FromString("6b9fdabc-5904-d541-a066-5cce39d30cef");    // UI/Fade
Guid kSettingsDoc = Guid::FromString("a4bb594a-8f56-ab40-ac66-ee4142b28bde"); // UI/Settings

Guid kLevel1 = Guid::FromString("d54b3804-21ff-724a-a076-4e971ef6b238");     // Scenes/Level1
Guid kLevel2 = Guid::FromString("d56e307e-8751-4241-a1ff-565b483b2cf1");     // Scenes/Level2
Guid kLevel3 = Guid::FromString("e8094435-4425-034d-b972-6bca7668b14d");     // Scenes/Level3

// Music: CodeManu's Platformer Game Music Pack (CC-BY 3.0) and Juhani Junkala's Chiptune
// Adventures (CC0); see CREDITS.md.
Guid kMenuMusic = Guid::FromString("3d2725e8-4b25-6a40-944d-57f5060a741d");    // Audio/Music-IntroTheme
Guid kLevel1Music = Guid::FromString("220216e9-ce96-e34d-9ff3-d6f2644ff9a4");  // Audio/Music-GrasslandsTheme
Guid kLevel2Music = Guid::FromString("b90d9d25-b608-4643-9ce2-19bd3e5a9ded");  // Audio/Music-Stage1
Guid kLevel3Music = Guid::FromString("852aeb40-1328-374e-9bb8-76663e55f695");  // Audio/Music-Stage2
Guid kButtonSound = Guid::FromString("d85b7392-aa68-0144-a40a-830d4e32079b"); // Audio/button-maximize_007
Guid kClearJingle = Guid::FromString("26864262-5533-b442-8d38-b77aeaa1ce30"); // Audio/jingles_NES13
Guid kVictoryJingle = Guid::FromString("a8c66ad5-4705-ae4e-af1e-ca70bb89e446"); // Audio/jingles_NES00
const float kMusicVolume = 0.55f;

const int kLevelCount = 3;
const float kFadeSeconds = 0.45f;
const float kClearSeconds = 3.0f;

Guid levelScene(int index)
{
	if (index == 1)
	{
		return kLevel2;
	}
	if (index == 2)
	{
		return kLevel3;
	}
	return kLevel1;
}

Guid levelMusic(int index)
{
	if (index == 1)
	{
		return kLevel2Music;
	}
	if (index == 2)
	{
		return kLevel3Music;
	}
	return kLevel1Music;
}

string levelName(int index)
{
	if (index == 1)
	{
		return "Crab Crossing";
	}
	if (index == 2)
	{
		return "Sky Climb";
	}
	return "Grassy Hills";
}

enum Phase
{
	Title,
	Settings,
	FadingOut,
	FadingIn,
	Intro,
	Playing,
	Paused,
	Cleared,
	Victory
}

class Game
{
	private Phase m_phase = Phase::Title;
	/// Real seconds in the current phase.
	private float m_timer = 0.0f;
	/// Where a fade out lands: the title, or level m_nextLevel.
	private bool m_toTitle = false;
	private int m_nextLevel = 0;
	/// The phase a fade in reveals.
	private Phase m_afterFade = Phase::Intro;
	private View m_fade;
	/// The track playing: 0 none, 1 the menu's, 2 + n level n's. A track asked for again keeps
	/// playing rather than restarting.
	private int m_track = 0;

	// ---- this level ----
	private int m_level = 0;
	private int m_coins = 0;
	private int m_coinTotal = 0;
	private int m_falls = 0;
	private float m_time = 0.0f;

	// ---- the whole game, levels cleared so far ----
	private int m_allCoins = 0;
	private int m_allCoinTotal = 0;
	private int m_allFalls = 0;
	private float m_allTime = 0.0f;

	void launch()
	{
		// The default scene is the title's backdrop, frozen behind the menu.
		Run.TimeScale = 0.0f;
		showTitle();
	}

	void update(float dt)
	{
		float real = Run.RealDeltaTime;
		m_timer += real;
		switch (m_phase)
		{
		case Phase::FadingOut:
			if (m_timer >= kFadeSeconds)
			{
				arrive();
			}
			break;
		case Phase::FadingIn:
			if (m_timer >= kFadeSeconds)
			{
				Ui.Pop(); // the fade layer, on top since the fade began
				enter(m_afterFade);
			}
			break;
		case Phase::Intro:
			// On the RELEASE: the press lands while the level is still frozen, so the player
			// never sees it and does not jump the moment play starts.
			if (Input.WasReleased("Jump"))
			{
				Ui.Pop(); // the intro banner
				Run.TimeScale = 1.0f;
				enter(Phase::Playing);
			}
			break;
		case Phase::Playing:
			m_time += dt;
			Ui.FindLabel("hud-time").SetText(clock(m_time));
			if (Input.WasPressed("Pause"))
			{
				pause();
			}
			break;
		case Phase::Settings:
			if (Input.WasPressed("Pause"))
			{
				onSettingsBack();
			}
			break;
		case Phase::Paused:
			if (Input.WasPressed("Pause"))
			{
				onResume();
			}
			break;
		case Phase::Cleared:
			{
				int left = int(kClearSeconds - m_timer + 0.999f); // whole seconds left, rounded up
				string next = (m_level + 1 < kLevelCount) ? "Next level in " : "Results in ";
				Ui.FindLabel("clear-next").SetText(next + left);
				if (m_timer >= kClearSeconds)
				{
					if (m_level + 1 < kLevelCount)
					{
						fadeToLevel(m_level + 1);
					}
					else
					{
						showVictory();
					}
				}
			}
			break;
		default:
			break;
		}
	}

	void exit()
	{
		Ui.Clear();
	}

	// ---- run events ----
	void onCoinRegistered(int count)
	{
		m_coinTotal += count;
		refreshHud();
	}

	void onCoinCollected(int value)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		m_coins += value;
		refreshHud();
	}

	void onPlayerDied(int deaths)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		m_falls += 1;
		refreshHud();
	}

	void onGoalReached(int unused)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		// Time runs on under the banner: the confetti flies and the player stands and watches.
		m_allCoins += m_coins;
		m_allCoinTotal += m_coinTotal;
		m_allFalls += m_falls;
		m_allTime += m_time;
		Audio.PlayOneShot(kClearJingle);
		Screen s = Ui.Push(kClearDoc);
		s.FindLabel("clear-summary").SetText("Coins " + m_coins + " / " + m_coinTotal + "    Falls " + m_falls
			+ "    Time " + clock(m_time));
		enter(Phase::Cleared);
	}

	// ---- buttons ----
	void onPlay()
	{
		click();
		m_allCoins = 0;
		m_allCoinTotal = 0;
		m_allFalls = 0;
		m_allTime = 0.0f;
		fadeToLevel(0);
	}

	/// The volumes, on the audio buses the player saves when it exits, so a change made
	/// here is there next time without the game storing anything itself.
	void onSettings()
	{
		click();
		Screen s = Ui.Push(kSettingsDoc);
		bindVolume(s, "master", AudioBus::Master, ScriptCallback(this.onMasterChanged));
		bindVolume(s, "music", AudioBus::Music, ScriptCallback(this.onMusicChanged));
		bindVolume(s, "effects", AudioBus::Effects, ScriptCallback(this.onEffectsChanged));
		s.FindButton("settings-back-btn").OnClick(ScriptCallback(this.onSettingsBack));
		enter(Phase::Settings);
	}

	void onSettingsBack()
	{
		click();
		Ui.Pop(); // the settings screen; the title is under it
		enter(Phase::Title);
	}

	void onMasterChanged()
	{
		volumeChanged("master", AudioBus::Master);
	}

	void onMusicChanged()
	{
		volumeChanged("music", AudioBus::Music);
	}

	void onEffectsChanged()
	{
		volumeChanged("effects", AudioBus::Effects);
		click(); // hear the level being set; the music is heard anyway
	}

	void onQuit()
	{
		click();
		Run.RequestExit(0);
	}

	void onResume()
	{
		click();
		Ui.Pop(); // the pause menu
		Run.TimeScale = 1.0f;
		enter(Phase::Playing);
	}

	void onRestart()
	{
		click();
		fadeToLevel(m_level);
	}

	void onQuitToTitle()
	{
		click();
		fadeToTitle();
	}

	// ---- the flow ----
	private void enter(Phase phase)
	{
		m_phase = phase;
		m_timer = 0.0f;
	}

	/// A volume row: its slider at the bus's level, its readout, and the handler.
	private void bindVolume(Screen s, string row, AudioBus bus, ScriptCallback@ handler)
	{
		Slider slider = s.FindSlider(row + "-slider");
		slider.SetValue(Audio.BusVolume(bus));
		showVolume(row, slider.Value);
		slider.OnChanged(handler);
	}

	private void volumeChanged(string row, AudioBus bus)
	{
		float level = Ui.FindSlider(row + "-slider").Value;
		Audio.SetBusVolume(bus, level);
		showVolume(row, level);
	}

	private void showVolume(string row, float level)
	{
		Ui.FindLabel(row + "-value").SetText("" + int(level * 100.0f + 0.5f) + "%");
	}

	private void showTitle()
	{
		music(1);
		Ui.Clear();
		Screen s = Ui.Push(kTitleDoc);
		s.FindButton("play-btn").OnClick(ScriptCallback(this.onPlay));
		s.FindButton("settings-btn").OnClick(ScriptCallback(this.onSettings));
		s.FindButton("quit-btn").OnClick(ScriptCallback(this.onQuit));
		enter(Phase::Title);
	}

	private void pause()
	{
		Run.TimeScale = 0.0f;
		Screen s = Ui.Push(kPauseDoc);
		s.FindButton("resume-btn").OnClick(ScriptCallback(this.onResume));
		s.FindButton("restart-btn").OnClick(ScriptCallback(this.onRestart));
		s.FindButton("title-btn").OnClick(ScriptCallback(this.onQuitToTitle));
		enter(Phase::Paused);
	}

	private void showVictory()
	{
		Ui.Pop(); // the clear banner
		Audio.PlayOneShot(kVictoryJingle);
		Screen s = Ui.Push(kVictoryDoc);
		s.FindLabel("victory-summary").SetText("Coins " + m_allCoins + " / " + m_allCoinTotal + "    Falls " + m_allFalls
			+ "    Time " + clock(m_allTime));
		s.FindButton("victory-title-btn").OnClick(ScriptCallback(this.onQuitToTitle));
		enter(Phase::Victory);
	}

	private void fadeToLevel(int index)
	{
		m_toTitle = false;
		m_nextLevel = index;
		fadeOut();
	}

	private void fadeToTitle()
	{
		m_toTitle = true;
		fadeOut();
	}

	/// Black over everything, then arrive() swaps what is under it.
	private void fadeOut()
	{
		if (m_phase == Phase::FadingOut || m_phase == Phase::FadingIn)
		{
			return;
		}
		Screen s = Ui.Push(kFadeDoc);
		m_fade = s.Find("fade");
		m_fade.FadeTo(1.0f, kFadeSeconds);
		enter(Phase::FadingOut);
	}

	/// Under the black: the new scene and its screens, then the black fades away.
	private void arrive()
	{
		Ui.Clear();
		Run.TimeScale = 0.0f;
		if (m_toTitle)
		{
			Run.LoadScene(kLevel1);
			showTitle();
			m_afterFade = Phase::Title;
		}
		else
		{
			m_level = m_nextLevel;
			m_coins = 0;
			m_coinTotal = 0; // the new level's coins register again
			m_falls = 0;
			m_time = 0.0f;
			Run.LoadScene(levelScene(m_level));
			music(2 + m_level);
			Ui.Push(kHudDoc);
			refreshHud();
			Screen intro = Ui.Push(kIntroDoc);
			intro.FindLabel("intro-number").SetText("Level " + (m_level + 1));
			intro.FindLabel("intro-name").SetText(levelName(m_level));
			m_afterFade = Phase::Intro;
		}
		Screen s = Ui.Push(kFadeDoc);
		m_fade = s.Find("fade");
		m_fade.SetOpacity(1.0f);
		m_fade.FadeTo(0.0f, kFadeSeconds);
		enter(Phase::FadingIn);
	}

	private void music(int track)
	{
		if (track == m_track)
		{
			return;
		}
		m_track = track;
		Audio.PlayMusic((track == 1) ? kMenuMusic : levelMusic(track - 2), 1.0f, kMusicVolume);
	}

	private void click()
	{
		Audio.PlayOneShot(kButtonSound);
	}

	private void refreshHud()
	{
		Ui.FindLabel("hud-coins").SetText("Coins " + m_coins + " / " + m_coinTotal);
		Ui.FindLabel("hud-falls").SetText("Falls " + m_falls);
		Ui.FindLabel("hud-time").SetText(clock(m_time));
		Ui.FindLabel("hud-level").SetText("Level " + (m_level + 1) + "  " + levelName(m_level));
	}

	private string clock(float seconds)
	{
		int whole = int(seconds);
		int s = whole % 60;
		return "" + (whole / 60) + ":" + (s < 10 ? "0" : "") + s;
	}
}
